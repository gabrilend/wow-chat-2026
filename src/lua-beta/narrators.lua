
Narrators = {}

local NARRATOR_EVERY  = 20
local TICK_MS         = 2000
local HEAR_YARDS      = 20
local LISTEN_SECONDS  = 20
local PAUSE_MS        = 3000
local PAUSE_PER_CHAR  = 60
local CHAT_LINE_BYTES = 255
local RUMOURS_KEPT    = 20
local WHISPER_EVERY_MS = 1000
local KEYWORD_LETTERS = 5
local RUMOUR_RETELLING = "verbatim"
local READING_TABLE    = "beta_910a_narrator_reading"

local PLAYER_EVENT_ON_LOGOUT = 4
local PLAYER_EVENT_ON_CHAT   = 18
local PLAYER_EVENT_ON_WHISPER = 19
local CHAT_MSG_SAY           = 1
local LANG_UNIVERSAL         = 0

local function here()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end
local Sentences = dofile(here() .. "lib/gutenberg-sentences.lua")
local Library   = dofile(here() .. "lib/narrator-library.lua")

Narrators.state  = {}
Narrators.now    = 0
Narrators.broken = nil
Narrators.library = Library

function Narrators.is_narrator(p)
    return p:IsBot() and p:GetGUIDLow() % NARRATOR_EVERY == 0
end

local function hears(listener, narrator)
    return not listener:IsBot() and listener:GetMapId() == narrator:GetMapId()
       and listener:GetDistance(narrator) <= HEAR_YARDS
end

local function anyone_listening(narrator, players)
    for _, q in ipairs(players) do
        if hears(q, narrator) then return true end
    end
    return false
end

local function reading_table_ready()
    return CharDBQuery("SHOW TABLES LIKE '" .. READING_TABLE .. "'") ~= nil
end

local function restore_place(guid)
    local row = CharDBQuery(string.format("SELECT book, position FROM %s WHERE guid = %d", READING_TABLE, guid))
    if not row then return end
    local book, position = row:GetUInt32(0), row:GetUInt32(1)
    if pcall(Library.setBook, guid, book) then
        if not pcall(Library.setPosition, guid, position) then Library.setPosition(guid, 0) end
    end
end

local function save_place(guid)
    CharDBExecute(string.format("REPLACE INTO %s (guid, book, position) VALUES (%d, %d, %d)",
        READING_TABLE, guid, Library.getCurrentBook(guid).id, Library.getPosition(guid)))
end

local function next_line(guid, s)
    if #s.parts == 0 then
        s.parts = Sentences.speakable_parts(Library.getNextSentence(guid), CHAT_LINE_BYTES)
        save_place(guid)
    end
    return table.remove(s.parts, 1)
end

local function state_of(p)
    local guid = p:GetGUIDLow()
    local s = Narrators.state[guid]
    if not s then
        s = { parts = {}, next_at = 0, quiet_until = 0, rumours = {}, known = {} }
        Narrators.state[guid] = s
    end
    return s
end

function Narrators.tick()
    if Narrators.broken then return end
    Narrators.now = Narrators.now + TICK_MS
    local players = GetPlayersInWorld() or {}
    for _, p in ipairs(players) do
        if Narrators.is_narrator(p) then
            local guid = p:GetGUIDLow()
            local s = state_of(p)
            if anyone_listening(p, players) and Narrators.now >= s.quiet_until and Narrators.now >= s.next_at then
                if not s.started then
                    local ok, err = pcall(Library.start, guid)
                    if ok and not reading_table_ready() then
                        ok, err = false, "the table " .. READING_TABLE .. " is missing (install step E061)"
                        Library.clearInstance(guid)
                    end
                    if not ok then
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

local NEAR = {
    haunted = "cursed", cursed = "haunted", old = "ancient", ancient = "old",
    big = "huge", huge = "big", small = "tiny", tiny = "small",
    night = "dusk", dusk = "night", seen = "spotted", spotted = "seen",
    near = "by", wolves = "bears", bears = "wolves", gold = "silver",
    silver = "gold", dead = "missing", missing = "dead", north = "east",
    east = "north", south = "west", west = "south", three = "four",
    four = "five", five = "three", stranger = "traveller", traveller = "stranger",
}
Narrators.random = math.random
Narrators.next_rumour = 0

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
Narrators.retelling = RUMOUR_RETELLING

function Narrators.retell(text)
    local retell = RETELLINGS[Narrators.retelling]
    if not retell then error("narrators.lua: no way of retelling called " .. tostring(Narrators.retelling)) end
    return retell(text)
end

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
    for _, t in ipairs(told) do overheard(t.teller, t.rumour) end
end

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

function Narrators.on_logout(_event, player)
    if not Narrators.is_narrator(player) then return end
    local guid = player:GetGUIDLow()
    local s = Narrators.state[guid]
    if s and s.started then Library.clearInstance(guid) end
    Narrators.state[guid] = nil
end

CreateLuaEvent(Narrators.tick, TICK_MS, 0)
RegisterPlayerEvent(PLAYER_EVENT_ON_CHAT, Narrators.on_chat)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT, Narrators.on_logout)
RegisterPlayerEvent(PLAYER_EVENT_ON_WHISPER, Narrators.on_whisper)
