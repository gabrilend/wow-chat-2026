--------------------------------------------------------------------------------
-- sargobras-whisper.lua (issue 617b2)
--
-- Reads a whisper to Sargobras and says what it asks for. The whisper works
-- his menus from afar; it does not open them (owner, 2026-10-30: "we can
-- interact with the buddy-making menus, not open them"), so every command
-- here is one of his menu's choices, put in words:
--
--   a class name   ("priest", "night elf priest" reads as the class)
--   a people       ("troll", "blood elf")
--   "flexible"     (his "I'm flexible." line: any class, the even spec)
--   "help"         (the list of commands)
--   "owed"         (how many buddies are still owed)
--
-- Anything else is "unknown": he answers with a joke and the help line.
--
-- Spec words are read past ("shadow priest" is a priest): the spec is drawn
-- by the same rules as at his menus (owner, 2026-10-28: "the spec should be
-- picked in the same way that any other buddy ... It should just create a
-- priest using the same rules we already have."). No name is ever taken
-- from a whisper: buddies' names are drawn, never asked for (owner,
-- 2026-10-30: "we don't get to pick buddy names").
--
-- Pure: no server calls. sargobras.lua answers what it returns; the offline
-- test is scripts/test-sargobras-whisper. Loaded as a script by the Lua
-- engine too (it loads every file in the folder), where it only builds its
-- table.
--------------------------------------------------------------------------------

local Whisper = {}

-- {{{ keywords
-- The words that are commands, each to what it asks. A dispatch table, so
-- a new command is one row here and one handler in sargobras.lua.
local KEYWORDS = {
    help     = "help",
    commands = "help",
    owed     = "owed",
    flexible = "flexible",
    any      = "flexible",
    anyone   = "flexible",
}
-- }}}

-- {{{ local function normalize
-- Lower case, punctuation to spaces, single spaces, no ends:
-- "Night-Elf, please!" becomes "night elf please".
local function normalize(text)
    local t = tostring(text or ""):lower():gsub("[^%a%s]", " "):gsub("%s+", " ")
    return (t:gsub("^ ", ""):gsub(" $", ""))
end
-- }}}

-- {{{ local function phrases
-- Every class and people name as words, longest first, so "blood elf" is
-- found before "elf" could ever match a shorter name. The death knight is
-- left out: no owner picks one at Sargobras (617b).
local DEATH_KNIGHT = 6
local function phrases(RC)
    local list = {}
    for id, c in pairs(RC.classes) do
        if id ~= DEATH_KNIGHT then list[#list + 1] = { words = normalize(c.name), kind = "class", id = id } end
    end
    for id, r in pairs(RC.races) do
        list[#list + 1] = { words = normalize(r.name), kind = "race", id = id }
    end
    table.sort(list, function(a, b) return #a.words > #b.words end)
    return list
end
-- }}}

-- {{{ local function has_phrase
-- Whether the words appear in the text as whole words ("priest" in "shadow
-- priest", not "priest" inside "priestess").
local function has_phrase(text, words)
    return (" " .. text .. " "):find(" " .. words .. " ", 1, true) ~= nil
end
-- }}}

-- {{{ function Whisper.parse
-- Reads a whisper. RC: the race and class table (sargobras-race-class-data).
-- Returns a table with `kind`:
--   "class"    and `id` (a class number)
--   "race"     and `id` (a people number)
--   "flexible", "help", "owed", "unknown"
-- When both a class and a people are named ("troll priest"), the class is
-- taken: his menus offer one or the other, and the class decides more of
-- what the buddy is; the people is then drawn as at the class menu.
function Whisper.parse(RC, text)
    local t = normalize(text)
    if t == "" then return { kind = "unknown" } end

    local class, race
    for _, p in ipairs(phrases(RC)) do
        if has_phrase(t, p.words) then
            if p.kind == "class" and not class then class = p.id end
            if p.kind == "race"  and not race  then race  = p.id end
        end
    end
    if class then return { kind = "class", id = class } end
    if race  then return { kind = "race",  id = race  } end

    for word in t:gmatch("%a+") do
        local k = KEYWORDS[word]
        if k then return { kind = k } end
    end
    return { kind = "unknown" }
end
-- }}}

-- {{{ function Whisper.help_line
-- The help line he whispers back: the commands, in a sentence.
function Whisper.help_line()
    return "Whisper me a class (\"priest\") or a people (\"troll\"), \"flexible\" if you'll take anyone, "
        .. "or \"owed\" to hear how many are still coming to you."
end
-- }}}

return Whisper
