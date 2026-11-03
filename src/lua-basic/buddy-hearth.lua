
local PLAYER_EVENT_ON_SPELL_CAST = 5
local HEARTH_SPELLS = { [8690] = true,
                        [556]  = true }
local HEARTH_FOLLOW_MS = 1500
local CURRENT_GENERIC_SPELL, CURRENT_CHANNELED_SPELL = 1, 3
local TAG = "[buddy-hearth] "

local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end

local Arc = dofile(script_dir() .. "lib/buddy-arc.lua")

local function roster_of(partner_low)
    local list = {}
    local q = CharDBQuery("SELECT buddy FROM buddy_roster WHERE owner = " .. partner_low .. " AND buddy <> 0 ORDER BY slot")
    if q then repeat list[#list + 1] = q:GetUInt32(0) until not q:NextRow() end
    return list
end

local function place_round(partner_low, which, map, x, y, z, o)
    local roster = roster_of(partner_low)
    local spots = Arc.places(x, y, o, #roster, "centre")
    local moved = 0
    for i, guid in ipairs(roster) do
        if not which or which == guid then
            local b = GetPlayerByGUID(GetPlayerGUID(guid))
            if b and b:IsInWorld() then
                b:InterruptSpell(CURRENT_GENERIC_SPELL)
                b:InterruptSpell(CURRENT_CHANNELED_SPELL)
                b:Teleport(map, spots[i].x, spots[i].y, z, spots[i].o)
                moved = moved + 1
            end
        end
    end
    return moved, #roster
end

local function on_spell_cast(event, player, spell)
    if not HEARTH_SPELLS[spell:GetEntry()] then return end
    local low = player:GetGUIDLow()
    local owner = CharDBQuery("SELECT owner FROM buddy_roster WHERE buddy = " .. low)
    if owner then
        local partner_low = owner:GetUInt32(0)
        player:RegisterEvent(function(_, _, _, b)
            local partner = GetPlayerByGUID(GetPlayerGUID(partner_low))
            if not partner then return end
            local home = partner:GetHomebind()
            place_round(partner_low, low, home.mapId, home.x, home.y, home.z, 0)
        end, HEARTH_FOLLOW_MS, 1)
        return
    end
    if #roster_of(low) == 0 then return end
    local ride = GroupHearth and GroupHearth.rideTarget and GroupHearth.rideTarget(player:GetGUID())
    player:RegisterEvent(function(_, _, _, p)
        local home = p:GetHomebind()
        if ride then home = { mapId = ride.map, x = ride.x, y = ride.y, z = ride.z } end
        local x, y, z, o = p:GetLocation()
        if ride or p:GetMapId() ~= home.mapId then
            x, y, z, o = home.x, home.y, home.z, 0
        end
        local moved, total = place_round(p:GetGUIDLow(), nil, home.mapId, x, y, z, o)
        if moved < total then
            print(string.format("%s%s hearthed: %d of %d buddies moved with them (the rest are not in the world)", TAG, p:GetName(), moved, total))
        end
    end, HEARTH_FOLLOW_MS, 1)
end

local TELEPORTS       = dofile(script_dir() .. "data/teleport-destinations.lua")
local TOWN_NEAR_YARDS = 300
local TELEPORT_FOLLOW_MS = 1500

local LANDING = {}
for spell in pairs(TELEPORTS) do
    local q = WorldDBQuery("SELECT MapID, PositionX, PositionY, PositionZ FROM spell_target_position WHERE ID = " .. spell)
    if q then
        LANDING[spell] = { map = q:GetUInt32(0), x = q:GetFloat(1), y = q:GetFloat(2), z = q:GetFloat(3) }
    else
        print(string.format("%sERROR: teleport %d has no landing spot in spell_target_position; a cast of it inside its town is not recognised", TAG, spell))
    end
end

local function inside_destination(player, spell)
    local d = TELEPORTS[spell]
    if player:GetMapId() ~= d.map then return false end
    if d.zone then return player:GetZoneId() == d.area end
    if player:GetAreaId() == d.area then return true end
    local l = LANDING[spell]
    return l ~= nil and (player:GetX() - l.x) ^ 2 + (player:GetY() - l.y) ^ 2 <= TOWN_NEAR_YARDS ^ 2
end

local function buddies_follow(p, to)
    if #roster_of(p:GetGUIDLow()) == 0 then return end
    local x, y, z, o = p:GetLocation()
    if p:GetMapId() ~= to.map then
        x, y, z, o = to.x, to.y, to.z, to.o or 0
    end
    place_round(p:GetGUIDLow(), nil, to.map, x, y, z, o)
end

local function on_teleport_cast(event, player, spell)
    local id = spell:GetEntry()
    if not TELEPORTS[id] then return end
    local low = player:GetGUIDLow()

    if not inside_destination(player, id) then
        local map = player:GetMap()
        if not (map:IsDungeon() or map:IsRaid() or map:IsBattleground() or map:IsArena()) then
            local x, y, z, o = player:GetLocation()
            CharDBExecute(string.format("REPLACE INTO teleport_way_back (guid, spell, map, x, y, z, o) VALUES (%d, %d, %d, %f, %f, %f, %f)",
                low, id, player:GetMapId(), x, y, z, o))
        end
        local to = LANDING[id] or { map = TELEPORTS[id].map, x = player:GetX(), y = player:GetY(), z = player:GetZ() }
        player:RegisterEvent(function(_, _, _, p) buddies_follow(p, to) end, TELEPORT_FOLLOW_MS, 1)
        return
    end

    local q = CharDBQuery(string.format("SELECT map, x, y, z, o FROM teleport_way_back WHERE guid = %d AND spell = %d", low, id))
    if not q then
        player:SendBroadcastMessage("No way back is remembered for this teleport, so it takes you into the city as usual.")
        local here = { map = player:GetMapId(), x = player:GetX(), y = player:GetY(), z = player:GetZ() }
        player:RegisterEvent(function(_, _, _, p) buddies_follow(p, LANDING[id] or here) end, TELEPORT_FOLLOW_MS, 1)
        return
    end
    local map, x, y, z, o = q:GetUInt32(0), q:GetFloat(1), q:GetFloat(2), q:GetFloat(3), q:GetFloat(4)
    CharDBExecute(string.format("DELETE FROM teleport_way_back WHERE guid = %d AND spell = %d", low, id))
    player:RegisterEvent(function(_, _, _, p)
        p:Teleport(map, x, y, z, o)
        p:RegisterEvent(function(_, _, _, pp) buddies_follow(pp, { map = map, x = x, y = y, z = z, o = o }) end, TELEPORT_FOLLOW_MS, 1)
    end, TELEPORT_FOLLOW_MS, 1)
end

RegisterPlayerEvent(PLAYER_EVENT_ON_SPELL_CAST, on_spell_cast)
RegisterPlayerEvent(PLAYER_EVENT_ON_SPELL_CAST, on_teleport_cast)
