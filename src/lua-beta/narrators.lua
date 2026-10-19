--------------------------------------------------------------------------------
-- narrators.lua (issue 910a) - some playerbots read books aloud
--
-- For a general audience: a few of beta's wandering bots are narrators. When
-- a real player comes within hearing, a narrator reads aloud from an old
-- book, one sentence at a time in ordinary /say chat, pausing between lines
-- about as long as it takes to read them, and it falls quiet for a while
-- when a player nearby speaks, then picks up where it left off. Each
-- narrator has its own book and its own place in it (the narrators'
-- library, issue 909); a narrator that logs out forgets its place.
--
-- Narrators are playerbots, not creatures (the owner, 2026-10-18: "players
-- need to be able to whisper to them"), so whispered rumours (910b) can come
-- later. To the Lua engine a playerbot is a player: this script finds them
-- among the players in the world (IsBot) and makes them speak with Say.
--
-- Which bots narrate: those whose character number is a multiple of
-- NARRATOR_EVERY. No table, no database: the same bots after every restart.
--
-- Time here is the script's own count of ticks (TICK_MS each), not the
-- clock, so a test can run it exactly.
--------------------------------------------------------------------------------

Narrators = {}

-- {{{ tuning
local NARRATOR_EVERY  = 20      -- one bot in this many narrates (910a open question 1)
local TICK_MS         = 2000    -- how often the narrators are looked at
local HEAR_YARDS      = 20      -- a real player this near hears the narrator
local LISTEN_SECONDS  = 20      -- quiet after a real player speaks nearby
local PAUSE_MS        = 3000    -- the pause after any line (at 1500 a short line came every tick, too fast to follow)
local PAUSE_PER_CHAR  = 60      -- ...plus this much per character (about reading speed)
local CHAT_LINE_BYTES = 255     -- the most one say line holds
local RUMOURS_KEPT    = 20      -- a narrator keeps this many rumours, the oldest dropped
local WHISPER_EVERY_MS = 1000   -- one whisper a second from one player (910's rate limit)
local KEYWORD_LETTERS = 5       -- words this long or longer are a rumour's keywords
-- }}}

-- {{{ engine numbers
local PLAYER_EVENT_ON_LOGOUT = 4
local PLAYER_EVENT_ON_CHAT   = 18
local PLAYER_EVENT_ON_WHISPER = 19
local CHAT_MSG_SAY           = 1
local LANG_UNIVERSAL         = 0
-- }}}

-- {{{ where the library's text cutter is
local function here()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end
local Sentences = dofile(here() .. "lib/gutenberg-sentences.lua")
-- }}}

-- Narrator state, by character number: { parts = lines left of the sentence
-- being read, next_at = tick time it may speak again, quiet_until = tick
-- time it listens until, started = true once its reader exists, rumours =
-- list of { text, from (a name), keywords = set of words } (910b) }
Narrators.state  = {}
Narrators.now    = 0          -- ms of ticks so far
Narrators.broken = nil        -- the reason, once the library could not start

-- {{{ function Narrators.is_narrator
-- A bot whose character number is a multiple of NARRATOR_EVERY. Real
-- players never narrate.
function Narrators.is_narrator(p)
    return p:IsBot() and p:GetGUIDLow() % NARRATOR_EVERY == 0
end
-- }}}

-- {{{ local function hears
-- A real player on the same map within HEAR_YARDS of the narrator.
local function hears(listener, narrator)
    return not listener:IsBot() and listener:GetMapId() == narrator:GetMapId()
       and listener:GetDistance(narrator) <= HEAR_YARDS
end
-- }}}

-- {{{ local function anyone_listening
local function anyone_listening(narrator, players)
    for _, q in ipairs(players) do
        if hears(q, narrator) then return true end
    end
    return false
end
-- }}}

-- {{{ local function next_line
-- The next line a narrator says: the rest of its current sentence, or a new
-- sentence from its book cut into chat-sized parts.
local function next_line(guid, s)
    if #s.parts == 0 then
        s.parts = Sentences.speakable_parts(Library.getNextSentence(guid), CHAT_LINE_BYTES)
    end
    return table.remove(s.parts, 1)
end
-- }}}

-- {{{ local function state_of
local function state_of(p)
    local guid = p:GetGUIDLow()
    local s = Narrators.state[guid]
    if not s then
        s = { parts = {}, next_at = 0, quiet_until = 0, rumours = {} }
        Narrators.state[guid] = s
    end
    s.rumours = s.rumours or {}
    return s
end
-- }}}

-- {{{ function Narrators.tick
-- One look at every online narrator: one that someone hears, that is not
-- listening and whose pause is over says its next line.
function Narrators.tick()
    if Narrators.broken then return end
    Narrators.now = Narrators.now + TICK_MS
    local players = GetPlayersInWorld() or {}
    for _, p in ipairs(players) do
        if Narrators.is_narrator(p) then
            local guid = p:GetGUIDLow()
            local s = state_of(p)
            -- heard by nobody, listening, or still pausing: silent this tick
            if anyone_listening(p, players) and Narrators.now >= s.quiet_until and Narrators.now >= s.next_at then
                if not s.started then
                    local ok, err = pcall(Library.start, guid)
                    if not ok then
                        -- no books (E059 not run), or no library: said once,
                        -- and the narrators stop rather than fail every tick
                        Narrators.broken = tostring(err)
                        print("narrators.lua: the narrators' library could not start, so no narrator reads (" .. Narrators.broken .. "); build the books with install step E059 or scripts/gutenberg-scraper")
                        return
                    end
                    s.started = true
                end
                local line = next_line(guid, s)
                p:Say(line, LANG_UNIVERSAL)
                s.next_at = Narrators.now + PAUSE_MS + #line * PAUSE_PER_CHAR
            end
        end
    end
end
-- }}}


-- {{{ function Narrators.keywords
-- A rumour's keywords: its words of KEYWORD_LETTERS letters or more, lower
-- case, without the common ones that would match any talk.
local COMMON = {}
local COMMON_WORDS = "about after again before being could every first found heard house "
                  .. "never other place right since still their there these thing think "
                  .. "those three under where which while would yours"
for w in COMMON_WORDS:gmatch("%a+") do COMMON[w] = true end
function Narrators.keywords(text)
    local set = {}
    for w in text:lower():gmatch("%a+") do
        if #w >= KEYWORD_LETTERS and not COMMON[w] then set[w] = true end
    end
    return set
end
-- }}}

-- {{{ function Narrators.on_chat
-- A real player speaking in /say quiets the narrators who hear them for
-- LISTEN_SECONDS; they go on from the same place afterwards. And a narrator
-- who hears a word of a rumour it keeps tells that rumour, once (910b): "<the
-- word>, you say? I heard ..." -- and forgets it.
function Narrators.on_chat(_event, player, msg, msg_type, _lang)
    if msg_type ~= CHAT_MSG_SAY or player:IsBot() then return end
    local said = Narrators.keywords(msg)
    for _, p in ipairs(GetPlayersInWorld() or {}) do
        if Narrators.is_narrator(p) and hears(player, p) then
            local s = state_of(p)
            s.quiet_until = Narrators.now + LISTEN_SECONDS * 1000
            for k, r in ipairs(s.rumours) do
                local word
                for w in pairs(said) do if r.keywords[w] then word = w break end end
                if word then
                    table.remove(s.rumours, k)
                    p:Say(word:sub(1, 1):upper() .. word:sub(2) .. ", you say? I heard someone say: \"" .. r.text .. "\"", LANG_UNIVERSAL)
                    break
                end
            end
        end
    end
end
-- }}}

-- {{{ function Narrators.on_whisper
-- A player whispering a narrator tells it a rumour (910b): kept, with its
-- keywords, and answered in a whisper. One a second from one player. The
-- whisper goes no further (false): the bot module does not also answer it.
-- Whispers between other players, and from bots, are left alone.
Narrators.last_whisper = {}
function Narrators.on_whisper(_event, player, msg, _type, _lang, receiver)
    if not receiver or not Narrators.is_narrator(receiver) or player:IsBot() then return end
    local who = player:GetGUIDLow()
    local last = Narrators.last_whisper[who]
    Narrators.last_whisper[who] = Narrators.now
    if last and Narrators.now - last < WHISPER_EVERY_MS then return false end
    local s = state_of(receiver)
    table.insert(s.rumours, { text = msg, from = player:GetName(), keywords = Narrators.keywords(msg) })
    if #s.rumours > RUMOURS_KEPT then table.remove(s.rumours, 1) end
    receiver:Whisper("I'll remember that, and pass it on.", LANG_UNIVERSAL, player)
    return false
end
-- }}}

-- {{{ function Narrators.on_logout
-- A narrator that logs out forgets its book and its place.
function Narrators.on_logout(_event, player)
    if not Narrators.is_narrator(player) then return end
    local guid = player:GetGUIDLow()
    local s = Narrators.state[guid]
    if s and s.started then Library.clearInstance(guid) end
    Narrators.state[guid] = nil
end
-- }}}

CreateLuaEvent(Narrators.tick, TICK_MS, 0)
RegisterPlayerEvent(PLAYER_EVENT_ON_CHAT, Narrators.on_chat)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT, Narrators.on_logout)
RegisterPlayerEvent(PLAYER_EVENT_ON_WHISPER, Narrators.on_whisper)
