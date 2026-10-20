
local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end

local DATA    = dofile(script_dir() .. "data/buddy-talent-data.lua")
local Spender = dofile(script_dir() .. "lib/buddy-talent-spender.lua")

local PLAYER_EVENT_ON_LOGIN          =  3
local PLAYER_EVENT_ON_LEVEL_CHANGE   = 13
local PLAYER_EVENT_ON_TALENTS_RESET  = 17

local TAG = "[buddy-talents] "

local function roster_ready()
    if not CharDBQuery("SHOW TABLES LIKE 'buddy_roster'") then
        print(TAG .. "ERROR: characters table buddy_roster is missing (issue 617a's install step not run?); buddy talents are OFF")
        return false
    end
    if not CharDBQuery("SHOW COLUMNS FROM buddy_roster LIKE 'talents_reroll'") then
        print(TAG .. "ERROR: buddy_roster has no talents_reroll column (617a's table predates 617g); buddy talents are OFF")
        return false
    end
    return true
end

local STAND_INS = CharDBQuery("SHOW TABLES LIKE 'buddy_stand_in'") ~= nil
if not STAND_INS then
    print(TAG .. "ERROR: characters table buddy_stand_in is missing (install step E056 not run?); stand-ins' talents are OFF")
end

local function buddy_row(player)
    local q = CharDBQuery(string.format(
        "SELECT profile, talents_reroll FROM buddy_roster WHERE buddy = %d", player:GetGUIDLow()))
    if q then return { shape = q:GetUInt32(0), reroll = q:GetUInt32(1) ~= 0 } end
    if not STAND_INS then return nil end
    q = CharDBQuery(string.format("SELECT profile FROM buddy_stand_in WHERE guid = %d", player:GetGUIDLow()))
    if not q then return nil end
    return { shape = q:GetUInt32(0), reroll = false, stand_in = true }
end

local function spend(player, shape)
    local free = player:GetFreeTalentPoints()
    if free == 0 then return end

    local cls = DATA.classes[player:GetClass()]
    if not cls then
        print(TAG .. "ERROR: " .. player:GetName() .. " has class " .. player:GetClass() .. ", which the talent data lacks"); return
    end
    if not cls.shapes[shape] then
        print(TAG .. "ERROR: " .. player:GetName() .. "'s roster shape " .. tostring(shape) .. " is not one of " .. cls.name .. "'s 1-" .. #cls.shapes .. "; nothing spent"); return
    end

    local spec  = player:GetActiveSpec()
    local has   = function(spell) return player:HasTalent(spell, spec) end
    local held  = Spender.read_held(cls, has)
    local steps, unspent = Spender.plan(cls, shape, held, free, math.random)

    for _, st in ipairs(steps) do player:LearnTalent(st.id, st.rank) end

    local now = Spender.read_held(cls, has)
    for _, st in ipairs(steps) do
        if (now[st.id] or 0) < st.rank + 1 then
            print(string.format("%sERROR: %s: the server refused %s rank %d (shape %d, %s); the spender and the server's talent rules disagree",
                TAG, player:GetName(), st.name, st.rank + 1, shape, cls.shapes[shape].label))
            return
        end
    end
    if unspent > 0 then
        print(string.format("%sWARNING: %s: %d talent point(s) left unspent, no legal talent in shape %d (%s)",
            TAG, player:GetName(), unspent, shape, cls.shapes[shape].label))
    end
end

local function on_login(event, player)
    local row = buddy_row(player)
    if not row then return end
    if row.reroll then
        player:ResetTalents(true)
        CharDBExecute(string.format("UPDATE buddy_roster SET talents_reroll = 0 WHERE buddy = %d", player:GetGUIDLow()))
    end
    spend(player, row.shape)
end

local function on_level_change(event, player, old_level)
    local row = buddy_row(player)
    if row then spend(player, row.shape) end
end

local function after_reset(player, free_before)
    if player:GetFreeTalentPoints() <= free_before then return end

    local row = buddy_row(player)
    if row then spend(player, row.shape); return end

    local owner = player:GetGUIDLow()
    local q = CharDBQuery(string.format(
        "SELECT buddy FROM buddy_roster WHERE owner = %d AND buddy IS NOT NULL AND buddy <> 0", owner))
    if not q then return end
    CharDBExecute(string.format(
        "UPDATE buddy_roster SET talents_reroll = 1 WHERE owner = %d AND buddy IS NOT NULL AND buddy <> 0", owner))
    repeat
        local low   = q:GetUInt32(0)
        local buddy = GetPlayerByGUID(GetPlayerGUID(low))
        if buddy then
            buddy:ResetTalents(true)
            CharDBExecute(string.format("UPDATE buddy_roster SET talents_reroll = 0 WHERE buddy = %d", low))
        end
    until not q:NextRow()
end

local function on_talents_reset(event, player, no_cost)
    local free_before = player:GetFreeTalentPoints()
    player:RegisterEvent(function(_, _, _, p) after_reset(p, free_before) end, 1, 1)
end

if roster_ready() then
    RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN,         on_login)
    RegisterPlayerEvent(PLAYER_EVENT_ON_LEVEL_CHANGE,  on_level_change)
    RegisterPlayerEvent(PLAYER_EVENT_ON_TALENTS_RESET, on_talents_reset)
end
