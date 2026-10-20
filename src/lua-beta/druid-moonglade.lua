
Moonglade = Moonglade or {}

local PLAYER_EVENT_ON_LOGIN       = 3
local PLAYER_EVENT_ON_LOGOUT      = 4
local PLAYER_EVENT_ON_SPELL_CAST  = 5
local PLAYER_EVENT_ON_UPDATE_ZONE = 27
local SPELL_EVENT_ON_PREPARE      = 1
local SPELL_EVENT_ON_CAST_CANCEL  = 3

local CLASS_DRUID     = 11
local SPELL_MOONGLADE = 18960
local ZONE_MOONGLADE  = 493
local MAP_KALIMDOR    = 1
local FOLLOW_MS       = 1500
local ARRIVE_TRIES    = 3

local OPEN_WORLD = { [0] = true, [1] = true, [530] = true, [571] = true }

local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end
Moonglade.ENTRANCES = dofile(script_dir() .. "data/instance-entrances.lua")

local VISIT_KIND = { question = "%s is going to %s. Visit with them?",
                     confirm  = "Visit with %s in %s? You will come back when they leave.",
                     withDead = true }
local GLADE_NAME = "Moonglade"

Moonglade.GLADE = {
    x_min = 7400,  x_max = 8300,
    y_min = -2950, y_max = -1850,
    land_z      = 512.1,
    HEIGHT_BAND = 40,
    STEEP       = 3,
    DRAWS       = 40,
    AREAS       = { [493] = true, [2361] = true, [2362] = true },
}

Moonglade.spots = Moonglade.spots or {}
Moonglade.visiting = Moonglade.visiting or {}
Moonglade.hosting = Moonglade.hosting or {}
Moonglade.trips = Moonglade.trips or {}

local function player_by_low(low) return GetPlayerByGUID(GetPlayerGUID(low)) end
local function in_glade(p) return p:GetMapId() == MAP_KALIMDOR and p:GetZoneId() == ZONE_MOONGLADE end

function Moonglade.drawArrival(map)
    local G = Moonglade.GLADE
    for _ = 1, G.DRAWS do
        local x = G.x_min + math.random() * (G.x_max - G.x_min)
        local y = G.y_min + math.random() * (G.y_max - G.y_min)
        local z = map:GetHeight(x, y)
        if z and math.abs(z - G.land_z) <= G.HEIGHT_BAND then
            local flat = true
            for _, d in ipairs({ { G.STEEP, 0 }, { -G.STEEP, 0 }, { 0, G.STEEP }, { 0, -G.STEEP } }) do
                local zz = map:GetHeight(x + d[1], y + d[2])
                if not zz or math.abs(zz - z) > G.STEEP then flat = false end
            end
            if flat and G.AREAS[map:GetAreaId(x, y, z)] then
                return x, y, z, math.random() * 2 * math.pi
            end
        end
    end
    return nil
end

function Moonglade.wayBack(player)
    local map = player:GetMapId()
    if OPEN_WORLD[map] then
        local x, y, z, o = player:GetLocation()
        return { map = map, x = x, y = y, z = z, o = o }
    end
    local m = player:GetMap()
    if m:IsBattleground() or m:IsArena() then
        player:SaveToDB()
        return { entryOf = player:GetGUIDLow() }
    end
    local e = Moonglade.ENTRANCES[map]
    return e and { map = e.map, x = e.x, y = e.y, z = e.z, o = e.o } or nil
end

function Moonglade.resolveWayBack(back)
    if not back or not back.entryOf then return back end
    local q = CharDBQuery("SELECT joinMapId, joinX, joinY, joinZ, joinO FROM character_entry_point WHERE guid = " .. back.entryOf)
    if not q then return nil end
    return { map = q:GetUInt32(0), x = q:GetFloat(1), y = q:GetFloat(2), z = q:GetFloat(3), o = q:GetFloat(4) }
end

function Moonglade.remember(guidLow, spot)
    if spot then
        Moonglade.spots[guidLow] = spot
        CharDBExecute(string.format(
            "REPLACE INTO beta_211a_moonglade_return (guid, map, x, y, z, o) VALUES (%d, %d, %.3f, %.3f, %.3f, %.4f)",
            guidLow, spot.map, spot.x, spot.y, spot.z, spot.o))
    else
        Moonglade.spots[guidLow] = false
        CharDBExecute("DELETE FROM beta_211a_moonglade_return WHERE guid = " .. guidLow)
    end
end

local function keep_visitor(low, druidLow, back, cameDead)
    Moonglade.visiting[low] = { druid = druidLow, back = back, cameDead = cameDead }
    Moonglade.hosting[druidLow] = true
    CharDBExecute(string.format(
        "REPLACE INTO beta_211a_moonglade_visitors (guid, druid, map, x, y, z, o, came_dead, left_glade) VALUES (%d, %d, %d, %.3f, %.3f, %.3f, %.4f, %d, 0)",
        low, druidLow, back.map, back.x, back.y, back.z, back.o, cameDead and 1 or 0))
end
local function forget_visitor(low)
    Moonglade.visiting[low] = nil
    CharDBExecute("DELETE FROM beta_211a_moonglade_visitors WHERE guid = " .. low)
end

local function send_home(visitor, back, cameDead)
    if in_glade(visitor) then
        if visitor:IsDead() and not cameDead then visitor:ResurrectPlayer(100, false) end
        visitor:SendBroadcastMessage("Your host has left Moonglade; you return to where you came from.")
        visitor:Teleport(back.map, back.x, back.y, back.z, back.o)
    end
    forget_visitor(visitor:GetGUIDLow())
end

function Moonglade.druidLeft(druidLow)
    if not Moonglade.hosting[druidLow] then return end
    Moonglade.hosting[druidLow] = nil
    local q = CharDBQuery("SELECT guid, map, x, y, z, o, came_dead FROM beta_211a_moonglade_visitors WHERE druid = " .. druidLow)
    if not q then return end
    repeat
        local low = q:GetUInt32(0)
        local back = { map = q:GetUInt32(1), x = q:GetFloat(2), y = q:GetFloat(3), z = q:GetFloat(4), o = q:GetFloat(5) }
        local visitor = player_by_low(low)
        if visitor then
            send_home(visitor, back, q:GetUInt32(6) == 1)
        else
            CharDBExecute("UPDATE beta_211a_moonglade_visitors SET left_glade = 1 WHERE guid = " .. low)
        end
    until not q:NextRow()
end

function Moonglade.onLogin(event, player)
    local low = player:GetGUIDLow()
    local v = CharDBQuery("SELECT druid, map, x, y, z, o, left_glade, came_dead FROM beta_211a_moonglade_visitors WHERE guid = " .. low)
    if v then
        local druidLow = v:GetUInt32(0)
        local back = { map = v:GetUInt32(1), x = v:GetFloat(2), y = v:GetFloat(3), z = v:GetFloat(4), o = v:GetFloat(5) }
        local cameDead = v:GetUInt32(7) == 1
        local druid = player_by_low(druidLow)
        if v:GetUInt32(6) == 1 or not druid or not in_glade(druid) then
            send_home(player, back, cameDead)
        else
            Moonglade.visiting[low] = { druid = druidLow, back = back, cameDead = cameDead }
        end
    end
    if player:GetClass() ~= CLASS_DRUID then return end
    if not player:HasSpell(SPELL_MOONGLADE) then player:LearnSpell(SPELL_MOONGLADE) end
    local q = CharDBQuery("SELECT map, x, y, z, o FROM beta_211a_moonglade_return WHERE guid = " .. low)
    if q then
        Moonglade.spots[low] = { map = q:GetUInt32(0), x = q:GetFloat(1), y = q:GetFloat(2), z = q:GetFloat(3), o = q:GetFloat(4) }
    else
        Moonglade.spots[low] = false
    end
    local hosted = CharDBQuery("SELECT COUNT(*) FROM beta_211a_moonglade_visitors WHERE druid = " .. low)
    if hosted and hosted:GetUInt32(0) > 0 then
        Moonglade.hosting[low] = true
        if not in_glade(player) then Moonglade.druidLeft(low) end
    end
end

function Moonglade.onLogout(event, player)
    Moonglade.druidLeft(player:GetGUIDLow())
end

function Moonglade.onZone(event, player, newZone, newArea)
    if newZone == ZONE_MOONGLADE then return end
    local low = player:GetGUIDLow()
    Moonglade.druidLeft(low)
    if Moonglade.visiting[low] then forget_visitor(low) end
end

function Moonglade.arrive(eventId, delay, repeats, player, tries)
    tries = tries or 1
    local low = player:GetGUIDLow()
    if not in_glade(player) then
        if tries < ARRIVE_TRIES then
            player:RegisterEvent(function(e, d, r, p) Moonglade.arrive(e, d, r, p, tries + 1) end, FOLLOW_MS, 1)
        else
            Moonglade.trips[low] = nil
            print("[Moonglade] " .. player:GetName() .. " was not in Moonglade " .. tries * FOLLOW_MS .. " ms after the spell; left where they are, visitors not brought")
        end
        return
    end
    local map = player:GetMap()
    local x, y, z, o = Moonglade.drawArrival(map)
    if x then
        player:Teleport(MAP_KALIMDOR, x, y, z, o)
    else
        x, y, z = player:GetLocation()
        print("[Moonglade] no open ground drawn in " .. Moonglade.GLADE.DRAWS .. " tries for " .. player:GetName() .. "; left in Nighthaven")
    end
    local trip = Moonglade.trips[low]
    Moonglade.trips[low] = nil
    if not trip then return end
    if trip.back and trip.back.entryOf then Moonglade.keepWayBack(player, trip.back) end
    local ring = GroupHearth.circle(x, y, trip.size)
    for _, t in ipairs(trip.list) do
        local visitor = player_by_low(t.low)
        local back = visitor and Moonglade.resolveWayBack(t.back)
        if back then
            local spot = ring[t.place]
            local vz = map:GetHeight(spot.x, spot.y) or z
            local cameDead = visitor:IsDead()
            if cameDead then visitor:ResurrectPlayer(100, false) end
            keep_visitor(t.low, low, back, cameDead)
            visitor:Teleport(MAP_KALIMDOR, spot.x, spot.y, vz, math.random() * 2 * math.pi)
        elseif visitor then
            visitor:SendBroadcastMessage("The way back from where you are is not known, so you stay rather than visit the glade.")
        end
    end
end

function Moonglade.goBack(player, spot)
    player:Teleport(spot.map, spot.x, spot.y, spot.z, spot.o)
    Moonglade.remember(player:GetGUIDLow(), nil)
end

function Moonglade.onPrepare(event, caster, spell)
    if not caster:IsPlayer() then return end
    if in_glade(caster) then return end
    GroupHearth.open(caster, VISIT_KIND, GLADE_NAME)
end

function Moonglade.onCast(event, player, spell)
    if spell:GetEntry() ~= SPELL_MOONGLADE then return end
    local low = player:GetGUIDLow()

    if in_glade(player) then
        local spot = Moonglade.spots[low]
        if spot then
            player:RegisterEvent(function(_, _, _, p) Moonglade.goBack(p, spot) end, FOLLOW_MS, 1)
        else
            player:SendBroadcastMessage("You have nowhere to return to from the glade.")
        end
        return
    end

    local back = Moonglade.wayBack(player)
    if not (back and back.entryOf) then Moonglade.keepWayBack(player, back) end

    local list = {}
    local taken, size = GroupHearth.take(player:GetGUID())
    for _, t in ipairs(taken) do
        local visitor = GetPlayerByGUID(t.guid)
        local vback = visitor and Moonglade.wayBack(visitor)
        if vback then
            list[#list + 1] = { low = visitor:GetGUIDLow(), place = t.place, back = vback }
        elseif visitor then
            visitor:SendBroadcastMessage("The way back from where you are is not known, so you stay rather than visit the glade.")
        end
    end
    Moonglade.trips[low] = { list = list, size = size, back = back }
    player:RegisterEvent(Moonglade.arrive, FOLLOW_MS, 1)
end

function Moonglade.keepWayBack(player, back)
    back = Moonglade.resolveWayBack(back)
    Moonglade.remember(player:GetGUIDLow(), back)
    if not back then
        player:SendBroadcastMessage("The way back from this place is not known; the glade will have no way back for you.")
    end
end

RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN,       Moonglade.onLogin)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT,      Moonglade.onLogout)
RegisterPlayerEvent(PLAYER_EVENT_ON_SPELL_CAST,  Moonglade.onCast)
RegisterPlayerEvent(PLAYER_EVENT_ON_UPDATE_ZONE, Moonglade.onZone)
RegisterSpellEvent(SPELL_MOONGLADE, SPELL_EVENT_ON_PREPARE, Moonglade.onPrepare)
RegisterSpellEvent(SPELL_MOONGLADE, SPELL_EVENT_ON_CAST_CANCEL, function(...) return GroupHearth.onCancel(...) end)
