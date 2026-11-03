
local Whisper = {}

local KEYWORDS = {
    help     = "help",
    commands = "help",
    owed     = "owed",
    flexible = "flexible",
    any      = "flexible",
    anyone   = "flexible",
}

local function normalize(text)
    local t = tostring(text or ""):lower():gsub("[^%a%s]", " "):gsub("%s+", " ")
    return (t:gsub("^ ", ""):gsub(" $", ""))
end

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

local function has_phrase(text, words)
    return (" " .. text .. " "):find(" " .. words .. " ", 1, true) ~= nil
end

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

function Whisper.help_line()
    return "Whisper me a class (\"priest\") or a people (\"troll\"), \"flexible\" if you'll take anyone, "
        .. "or \"owed\" to hear how many are still coming to you."
end

return Whisper
