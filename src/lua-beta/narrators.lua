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
-- }}}

-- {{{ engine numbers
local PLAYER_EVENT_ON_LOGOUT = 4
local PLAYER_EVENT_ON_CHAT   = 18
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
-- time it listens until, started = true once its reader exists }
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
            local s = Narrators.state[guid]
            if not s then
                s = { parts = {}, next_at = 0, quiet_until = 0 }
                Narrators.state[guid] = s
            end
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

-- {{{ function Narrators.on_chat
-- A real player speaking in /say quiets the narrators who hear them for
-- LISTEN_SECONDS; they go on from the same place afterwards.
function Narrators.on_chat(_event, player, _msg, msg_type, _lang)
    if msg_type ~= CHAT_MSG_SAY or player:IsBot() then return end
    for _, p in ipairs(GetPlayersInWorld() or {}) do
        if Narrators.is_narrator(p) and hears(player, p) then
            local s = Narrators.state[p:GetGUIDLow()]
            if s then s.quiet_until = Narrators.now + LISTEN_SECONDS * 1000 end
        end
    end
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
