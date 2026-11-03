
local PLAYER_EVENT_ON_COMMAND = 42
local GM_RANK  = 1
local TAG      = "[lever] "
local LIST_MAX = 20

local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end

local Levers = dofile(script_dir() .. "lib/buddy-levers.lua")
local LIST   = dofile(script_dir() .. "data/buddy-lever-list.lua")
local BY_ID  = Levers.index(LIST)
local map_ok, MAP = pcall(dofile, script_dir() .. "data/buddy-lever-map.lua")
if not map_ok then MAP = nil end

local function context_of(buddy)
    local ctx = { idle = true, buddies = {} }
    local q = CharDBQuery("SELECT owner FROM buddy_roster WHERE buddy = " .. buddy:GetGUIDLow() .. " LIMIT 1")
    if not q then return ctx end
    local owner = q:GetUInt32(0)
    ctx.partner = GetPlayerByGUID(GetPlayerGUID(owner))
    local r = CharDBQuery("SELECT buddy FROM buddy_roster WHERE owner = " .. owner .. " AND buddy <> 0")
    if r then repeat
        local b = GetPlayerByGUID(GetPlayerGUID(r:GetUInt32(0)))
        if b then ctx.buddies[#ctx.buddies + 1] = b end
    until not r:NextRow() end
    return ctx
end

local function matching(word)
    local out = {}
    if not word or word == "" then return LIST end
    if MAP then
        local segs = {}
        for i, s in ipairs(MAP.segments) do if s.label:lower():find(word, 1, true) then segs[i] = true end end
        if next(segs) then
            for id, seg in pairs(MAP.segment_of) do if segs[seg] and BY_ID[id] then out[#out + 1] = BY_ID[id] end end
            table.sort(out, function(a, b) return a.id < b.id end)
            return out
        end
    end
    for _, l in ipairs(LIST) do
        if l.id:find(word, 1, true) or l.say:lower():find(word, 1, true) then out[#out + 1] = l end
    end
    return out
end

local function run(gm, words, say)
    local first, rest = words:match("^(%S+)%s*(.*)$")
    if not first then
        return say(TAG .. "usage: .lever NAME LEVER | .lever NAME random [WORD] | .lever find WORD")
    end
    if first == "find" then
        local found = matching(rest)
        for i = 1, math.min(#found, LIST_MAX) do say(TAG .. found[i].id .. ": " .. found[i].say) end
        return say(TAG .. #found .. " of " .. #LIST .. " levers match \"" .. rest .. "\"")
    end

    local buddy
    if first == "target" then
        buddy = gm and gm:GetSelection()
        buddy = buddy and buddy:ToPlayer()
        if not buddy then return say(TAG .. "\"target\" needs a selected buddy") end
    else
        buddy = GetPlayerByName(first:sub(1, 1):upper() .. first:sub(2):lower())
        if not buddy then return say(TAG .. "no character called " .. first .. " is in the world") end
    end

    local lever
    local verb, word = rest:match("^(%S+)%s*(.*)$")
    if verb == "random" then
        local found = matching(word)
        if #found == 0 then return say(TAG .. "no lever matches \"" .. word .. "\"") end
        lever = found[math.random(#found)]
    else
        lever = BY_ID[rest]
        if not lever then return say(TAG .. "no lever called \"" .. rest .. "\" (.lever find WORD lists them)") end
    end

    local ok, why = Levers.pull(buddy, lever, context_of(buddy))
    say(TAG .. buddy:GetName() .. ": " .. lever.id .. " (" .. lever.say .. ") " .. (ok and "pulled" or ("not pulled: " .. why)))
end

local function on_command(event, player, command, handler)
    local words = command:match("^lever%s*(.*)$")
    if not words then return end
    if player and player:GetGMRank() < GM_RANK then return end
    local say = player and function(text) player:SendBroadcastMessage(text) end
                        or function(text) handler:SendSysMessage(text) end
    run(player, words:lower(), say)
    return false
end

RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, on_command)
