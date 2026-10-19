--------------------------------------------------------------------------------
-- narrators.lua (issue 910a) - some playerbots read books aloud
--
-- For a general audience: a few of beta's wandering bots are narrators. When
-- a real player comes within hearing, a narrator reads aloud from an old
-- book, one sentence at a time in ordinary /say chat, pausing between lines
-- about as long as it takes to read them, and it falls quiet for a while
-- when a player nearby speaks, then picks up where it left off. Each
-- narrator has its own book and its own place in it (the narrators'
-- library, issue 909). Its book and how many sentences in are saved in the
-- characters database (install step E061), so a narrator that logs out, or a
-- server that restarts, goes on from the same sentence (the owner,
-- 2026-10-18: "if we forget our place, then we won't ever complete a book").
--
-- Narrators are playerbots, not creatures (the owner, 2026-10-18: "players
-- need to be able to whisper to them"), so a player can whisper one a rumour
-- (910b); it tells the rumour when it hears talk of it, and any narrator
-- standing near enough to hear that learns it too and passes it on. To the
-- Lua engine a playerbot is a player: this script finds them among the
-- players in the world (IsBot) and makes them speak with Say.
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
-- How a narrator retells a rumour it overheard another narrator tell (910b,
-- the owner 2026-10-18: "Let's build both behaviors in-case players don't
-- want to deal with robots"):
--   "verbatim"  word for word
--   "changed"   one small change a retelling, by fixed rules (no language
--               model): a word swapped for a near one, as rumours drift
--   "llm"       a language model retells it: not available until a model
--               runner exists (issue 916d); choosing it stops this script
--               with an error rather than quietly telling it word for word
local RUMOUR_RETELLING = "verbatim"
local READING_TABLE    = "beta_910a_narrator_reading"   -- install step E061
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
local Library   = dofile(here() .. "lib/narrator-library.lua")
-- }}}

-- Narrator state, by character number: { parts = lines left of the sentence
-- being read, next_at = tick time it may speak again, quiet_until = tick
-- time it listens until, started = true once its reader exists, rumours =
-- list, oldest first, of { id (integer, the same for every retelling of one
-- whisper), text, from (the whisperer's name), hops (integer, 0 as
-- whispered, +1 for each narrator it passed through), keywords = set of
-- words } (910b), known = set of the rumour ids it has ever held (so a
-- rumour it told and let go is not learned back from the narrator it told:
-- without this two narrators would hand one rumour to each other forever) }.
-- Rumours live in memory only: a logout or restart forgets them.
Narrators.state  = {}
Narrators.now    = 0          -- ms of ticks so far
Narrators.broken = nil        -- the reason, once the library could not start
Narrators.library = Library   -- this script's own copy of the library (a test points it at a test shelf)

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

-- {{{ the saved place (E061)
-- Each narrator's book and how many sentences in, in the characters
-- database, so books get finished across logouts and restarts.
local function reading_table_ready()
    return CharDBQuery("SHOW TABLES LIKE '" .. READING_TABLE .. "'") ~= nil
end

-- Puts a starting narrator back where it was, if it has a saved place and
-- that book is still on the shelf; otherwise it keeps the random book the
-- library gave it.
local function restore_place(guid)
    local row = CharDBQuery(string.format("SELECT book, position FROM %s WHERE guid = %d", READING_TABLE, guid))
    if not row then return end
    local book, position = row:GetUInt32(0), row:GetUInt32(1)
    if pcall(Library.setBook, guid, book) then
        -- a place past the book's end (the book was cut differently since)
        -- starts it over
        if not pcall(Library.setPosition, guid, position) then Library.setPosition(guid, 0) end
    end
end

local function save_place(guid)
    CharDBExecute(string.format("REPLACE INTO %s (guid, book, position) VALUES (%d, %d, %d)",
        READING_TABLE, guid, Library.getCurrentBook(guid).id, Library.getPosition(guid)))
end
-- }}}

-- {{{ local function next_line
-- The next line a narrator says: the rest of its current sentence, or a new
-- sentence from its book cut into chat-sized parts (its place saved).
local function next_line(guid, s)
    if #s.parts == 0 then
        s.parts = Sentences.speakable_parts(Library.getNextSentence(guid), CHAT_LINE_BYTES)
        save_place(guid)
    end
    return table.remove(s.parts, 1)
end
-- }}}

-- {{{ local function state_of
local function state_of(p)
    local guid = p:GetGUIDLow()
    local s = Narrators.state[guid]
    if not s then
        s = { parts = {}, next_at = 0, quiet_until = 0, rumours = {}, known = {} }
        Narrators.state[guid] = s
    end
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
                    if ok and not reading_table_ready() then
                        ok, err = false, "the table " .. READING_TABLE .. " is missing (install step E061)"
                        Library.clearInstance(guid)
                    end
                    if not ok then
                        -- no books (E059 not run), or no library: said once,
                        -- and the narrators stop rather than fail every tick
                        Narrators.broken = tostring(err)
                        print("narrators.lua: the narrators could not start, so no narrator reads (" .. Narrators.broken .. "); the books come from install step E059 (or scripts/gutenberg-scraper), the saved places from E061")
                        return
                    end
                    restore_place(guid)
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

-- {{{ retelling (910b)
-- Near words a rumour drifts to when "changed" retelling is chosen: each
-- retelling swaps one word found here for its neighbour, chosen at random
-- among the words of the rumour that have one.
local NEAR = {
    haunted = "cursed", cursed = "haunted", old = "ancient", ancient = "old",
    big = "huge", huge = "big", small = "tiny", tiny = "small",
    night = "dusk", dusk = "night", seen = "spotted", spotted = "seen",
    near = "by", wolves = "bears", bears = "wolves", gold = "silver",
    silver = "gold", dead = "missing", missing = "dead", north = "east",
    east = "north", south = "west", west = "south", three = "four",
    four = "five", five = "three", stranger = "traveller", traveller = "stranger",
}
Narrators.random = math.random   -- a test may swap in a fixed sequence
Narrators.next_rumour = 0        -- rumour numbers, so a narrator does not learn one twice

-- one way of retelling per RUMOUR_RETELLING value
local RETELLINGS = {}
function RETELLINGS.verbatim(text) return text end
function RETELLINGS.changed(text)
    local words, choices = {}, {}
    for w in text:gmatch("%S+") do
        words[#words + 1] = w
        local bare = w:lower():gsub("%p", "")
        if NEAR[bare] then choices[#choices + 1] = #words end
    end
    if #choices == 0 then return text end
    local k = choices[Narrators.random(#choices)]
    local w = words[k]
    local bare = w:lower():gsub("%p", "")
    local swap = NEAR[bare]
    if w:sub(1, 1):match("%u") then swap = swap:sub(1, 1):upper() .. swap:sub(2) end
    words[k] = (w:gsub("%a+", swap, 1))
    return table.concat(words, " ")
end

if not RETELLINGS[RUMOUR_RETELLING] then
    error("narrators.lua: RUMOUR_RETELLING is " .. tostring(RUMOUR_RETELLING) .. "; only \"verbatim\" and \"changed\" exist (\"llm\" needs the model runner of issue 916d)")
end
Narrators.retelling = RUMOUR_RETELLING   -- a test switches it to check both

-- {{{ function Narrators.retell
-- The rumour as this narrator passes it on, by the chosen way of retelling.
function Narrators.retell(text)
    local retell = RETELLINGS[Narrators.retelling]
    if not retell then error("narrators.lua: no way of retelling called " .. tostring(Narrators.retelling)) end
    return retell(text)
end
-- }}}

-- Every other narrator who hears `teller` tell a rumour learns it, retold,
-- unless it has ever held that rumour (told or not).
local function overheard(teller, r)
    for _, q in ipairs(GetPlayersInWorld() or {}) do
        if q ~= teller and Narrators.is_narrator(q) and q:GetMapId() == teller:GetMapId()
           and q:GetDistance(teller) <= HEAR_YARDS then
            local qs = state_of(q)
            if not qs.known[r.id] then
                qs.known[r.id] = true
                local text = Narrators.retell(r.text)
                table.insert(qs.rumours, { id = r.id, text = text, from = r.from, hops = r.hops + 1,
                                           keywords = Narrators.keywords(text) })
                if #qs.rumours > RUMOURS_KEPT then table.remove(qs.rumours, 1) end
            end
        end
    end
end
-- }}}

-- {{{ function Narrators.on_chat
-- A real player speaking in /say quiets the narrators who hear them for
-- LISTEN_SECONDS; they go on from the same place afterwards. And a narrator
-- who hears a word of a rumour it keeps tells that rumour, once (910b): "<the
-- word>, you say? I heard ..." -- and forgets it.
function Narrators.on_chat(_event, player, msg, msg_type, _lang)
    if msg_type ~= CHAT_MSG_SAY or player:IsBot() then return end
    local said, told = Narrators.keywords(msg), {}
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
                    told[#told + 1] = { teller = p, rumour = r }
                    break
                end
            end
        end
    end
    -- narrators nearby hear what was told, and can pass it on later. After
    -- the loop, not in it: a narrator further down the list would otherwise
    -- learn it and tell it back in the same moment, to the same talk.
    for _, t in ipairs(told) do overheard(t.teller, t.rumour) end
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
    Narrators.next_rumour = Narrators.next_rumour + 1
    s.known[Narrators.next_rumour] = true
    table.insert(s.rumours, { id = Narrators.next_rumour, text = msg, from = player:GetName(), hops = 0,
                              keywords = Narrators.keywords(msg) })
    if #s.rumours > RUMOURS_KEPT then table.remove(s.rumours, 1) end
    receiver:Whisper("I'll remember that, and pass it on.", LANG_UNIVERSAL, player)
    return false
end
-- }}}

-- {{{ function Narrators.on_logout
-- A narrator that logs out lets its reader go from memory; its place stays
-- saved (E061) and it picks up there when it is next heard.
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
