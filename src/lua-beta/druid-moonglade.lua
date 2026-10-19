--------------------------------------------------------------------------------
-- druid-moonglade.lua - a druid's hearthstone is Teleport: Moonglade (issue 211a)
--
-- Druids on beta meet no innkeeper among the travellers, so they cannot move
-- their Hearthstone's bind point; their way home is the glade instead. The
-- owner, 2026-10-18: "they're supposed to start with teleport moonglade, and
-- that's their hearthstone. But casting it while in Moonglade will teleport
-- them back to where they were before they teleported to moonglade."; "can
-- we create more than one spawn position for the druid in moonglade? It
-- should be essentially random."; on the group: "they can be visitors. but
-- if the druid is no longer in moonglade, then they are teleported out as
-- well, to the place they teleported in from."; on a cast from an
-- instance: "the spot where they entered the dungeon or battleground or
-- arena."; no cooldown; visitors' ways back kept in the database ("sure");
-- and the dead: "we should ressurect them upon arriving in Moonglade.
-- Nature's magic and all that."
--
--   login: a druid without Teleport: Moonglade learns it, at any level; the
--     druid's way back is read once from the characters database. A
--     visitor whose druid is not hosting them in the glade goes back.
--   the cast begins outside Moonglade: the group is invited, by 211's
--     window (GroupHearth.open), the dead too; a cancelled cast withdraws it
--   the cast completes outside Moonglade: everyone's way back is worked out
--     at that moment (Moonglade.wayBack): where they stand in the open
--     world, or the entrance of the dungeon or raid they are in. The
--     druid's is kept in the database. Once the spell has put the druid in
--     Nighthaven, they are moved to a random spot on the glade's open
--     ground, and the visitors round them, raised if dead
--   the cast completes inside Moonglade: with a way back, the druid is
--     sent there once the spell's own move is done, and it is forgotten;
--     with none, the spell is stock (Nighthaven) and they are told so
--   the druid leaves Moonglade (any way, or logs out): their visitors still
--     in the glade are sent back to their own ways back; one offline is
--     sent back at their next login; one who leaves on their own stops
--     being a visitor. Visitors are kept in the database, so a restart in
--     between changes none of this.
--
-- The spell-cast event fires as a cast completes, before its effect
-- (Spell::_cast calls OnPlayerSpellCast "before the spell is actually
-- executed"), so at that moment everyone still stands where they were.
-- The moves after it wait FOLLOW_MS, as the buddies' hearth does
-- (src/lua-basic/buddy-hearth.lua), for the spell's teleport to land.
--
-- A dungeon's entrance comes from data/instance-entrances.lua, generated
-- from the game's own triggers (scripts/generate-beta-instance-entrances):
-- worked out once, read at the cast. A battleground or arena has no
-- entrance of its own (players join from anywhere); the game keeps each
-- player's join spot (Player::SetEntryPoint), which patch B055 lets Lua
-- read (player:GetEntryPoint). A visitor who dies in the glade is raised
-- before going back, unless they came dead.
--------------------------------------------------------------------------------

Moonglade = Moonglade or {}
-- GroupHearth (hearthstone.lua's invitation) is used only when a spell is
-- cast, by which time every file has loaded; this file loads first (by
-- name) and does not make it, so a missing hearthstone.lua is an error at
-- the first cast rather than a quietly empty table
-- (scripts/test-lua-globals: one global, one file)

local PLAYER_EVENT_ON_LOGIN       = 3
local PLAYER_EVENT_ON_LOGOUT      = 4
local PLAYER_EVENT_ON_SPELL_CAST  = 5    -- fires as a cast completes, before its effect
local PLAYER_EVENT_ON_UPDATE_ZONE = 27   -- (event, player, newZone, newArea)
local SPELL_EVENT_ON_PREPARE      = 1    -- a cast begins
local SPELL_EVENT_ON_CAST_CANCEL  = 3    -- a cast is cancelled or interrupted

local CLASS_DRUID     = 11
local SPELL_MOONGLADE = 18960          -- Teleport: Moonglade
local ZONE_MOONGLADE  = 493
local MAP_KALIMDOR    = 1
local FOLLOW_MS       = 1500           -- after the cast: the spell's teleport has landed by then
local ARRIVE_TRIES    = 3              -- a slow map load: look again this many times

-- the open world, where a way back is where one stands
local OPEN_WORLD = { [0] = true, [1] = true, [530] = true, [571] = true }

-- each dungeon's and raid's way out, by map number: { map, x, y, z, o }
local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end
Moonglade.ENTRANCES = dofile(script_dir() .. "data/instance-entrances.lua")

-- the window's words for this trip (211's window, GroupHearth.open); the
-- dead are asked too, since the glade raises them
local VISIT_KIND = { question = "%s is going to %s. Visit with them?",
                     confirm  = "Visit with %s in %s? You will come back when they leave.",
                     withDead = true }
local GLADE_NAME = "Moonglade"

-- {{{ Moonglade.GLADE
-- Where a druid may arrive: drawn in the valley floor's box, kept when the
-- ground there is within HEIGHT_BAND yards of Nighthaven's (512.1, where
-- the spell lands: spell_target_position 18960), no steeper than the
-- STEEP rule, and in one of AREAS (AreaTable.dbc: Moonglade's open land,
-- Nighthaven, the Shrine of Remulos; not Lake Elune'ara, 656, nor the
-- underground Stormrage Barrow Dens, 2363). The box was measured offline
-- from the game's map files (issue 211a): 1 draw in 5 passes height and
-- steepness in it, so DRAWS misses in a row is about 1 in 7000.
Moonglade.GLADE = {
    x_min = 7400,  x_max = 8300,
    y_min = -2950, y_max = -1850,
    land_z      = 512.1,
    HEIGHT_BAND = 40,
    STEEP       = 3,      -- yards of rise allowed over STEEP yards in each direction (45 degrees)
    DRAWS       = 40,
    AREAS       = { [493] = true, [2361] = true, [2362] = true },
}
-- }}}

-- druids' ways back, by character guid low part: { map, x, y, z, o }, or
-- false for none (read from the database at login)
Moonglade.spots = Moonglade.spots or {}
-- visitors in the glade, by the visitor's guid low part: { druid = guid
-- low part, back = { map, x, y, z, o } }; the database holds the same
Moonglade.visiting = Moonglade.visiting or {}
-- druids hosting visitors, by guid low part (true); read back at a druid's
-- login from the database, so a restart loses no host
Moonglade.hosting = Moonglade.hosting or {}
-- a trip between the cast and the arrival, by the druid's guid low part:
-- the visitors taken, { list = list of { low, place, back }, size = group size }
Moonglade.trips = Moonglade.trips or {}

-- {{{ local function player_by_low
local function player_by_low(low) return GetPlayerByGUID(GetPlayerGUID(low)) end
-- }}}
-- {{{ local function in_glade
local function in_glade(p) return p:GetMapId() == MAP_KALIMDOR and p:GetZoneId() == ZONE_MOONGLADE end
-- }}}

-- {{{ Moonglade.drawArrival
-- A random spot on the glade's open ground: x, y, z, o, or nil when no
-- draw of DRAWS was kept (the caller leaves the druid where they are and
-- says so in the log). map: the Kalimdor map object.
function Moonglade.drawArrival(map)
    local G = Moonglade.GLADE
    for _ = 1, G.DRAWS do
        local x = G.x_min + math.random() * (G.x_max - G.x_min)
        local y = G.y_min + math.random() * (G.y_max - G.y_min)
        local z = map:GetHeight(x, y)
        -- no ground there (nil): next draw
        -- ground off the valley floor's height: next draw
        if z and math.abs(z - G.land_z) <= G.HEIGHT_BAND then
            local flat = true
            for _, d in ipairs({ { G.STEEP, 0 }, { -G.STEEP, 0 }, { 0, G.STEEP }, { 0, -G.STEEP } }) do
                local zz = map:GetHeight(x + d[1], y + d[2])
                if not zz or math.abs(zz - z) > G.STEEP then flat = false end
            end
            -- too steep, or ground missing beside it: next draw
            -- outside the glade's open areas (the lake, the barrow dens): next draw
            if flat and G.AREAS[map:GetAreaId(x, y, z)] then
                return x, y, z, math.random() * 2 * math.pi
            end
        end
    end
    return nil
end
-- }}}

-- {{{ Moonglade.wayBack
-- Where a player goes back to from the glade, worked out at the cast:
--   the open world: where they stand
--   a battleground or an arena: where they joined it, as the game keeps it
--     (player:GetEntryPoint, added to the Lua engine by patch B055); nil
--     when the game kept none
--   a dungeon or raid: its entrance (Moonglade.ENTRANCES); nil for one
--     with no entrance found (all above beta's level cap)
-- A Lua engine built without B055 has no GetEntryPoint: the cast fails
-- loudly in the server log rather than quietly losing the way back.
function Moonglade.wayBack(player)
    local map = player:GetMapId()
    if OPEN_WORLD[map] then
        local x, y, z, o = player:GetLocation()
        return { map = map, x = x, y = y, z = z, o = o }
    end
    local m = player:GetMap()
    if m:IsBattleground() or m:IsArena() then
        local at = player:GetEntryPoint()
        return at and { map = at.mapId, x = at.x, y = at.y, z = at.z, o = at.o } or nil
    end
    local e = Moonglade.ENTRANCES[map]
    return e and { map = e.map, x = e.x, y = e.y, z = e.z, o = e.o } or nil
end
-- }}}

-- {{{ Moonglade.remember
-- Keeps a druid's way back (or forgets it, spot nil), in memory and in the
-- database.
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
-- }}}

-- {{{ local function keep_visitor / forget_visitor
-- A visitor, in memory and in the database; and gone from both. cameDead:
-- they arrived dead (and were raised on arrival), so a second death in the
-- glade is not undone when they go back.
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
-- }}}

-- {{{ local function send_home
-- A visitor goes back and stops being a visitor.
--   in the glade: moved to their way back, raised first if dead, unless
--     they came dead (the owner: "unless they were a ghost when they came,
--     then we leave them as a ghost if they died in moonglade")
--   left it some other way meanwhile: only forgotten
local function send_home(visitor, back, cameDead)
    if in_glade(visitor) then
        if visitor:IsDead() and not cameDead then visitor:ResurrectPlayer(100, false) end
        visitor:SendBroadcastMessage("Your host has left Moonglade; you return to where you came from.")
        visitor:Teleport(back.map, back.x, back.y, back.z, back.o)
    end
    forget_visitor(visitor:GetGUIDLow())
end
-- }}}

-- {{{ Moonglade.druidLeft
-- The druid is no longer in the glade: each of their visitors (from the
-- database, so those from before a restart too) online is sent back; each
-- offline is marked, to be sent back at their next login.
function Moonglade.druidLeft(druidLow)
    if not Moonglade.hosting[druidLow] then return end
    Moonglade.hosting[druidLow] = nil
    local q = CharDBQuery("SELECT guid, map, x, y, z, o, came_dead FROM beta_211a_moonglade_visitors WHERE druid = " .. druidLow)
    if not q then return end
    repeat
        local low = q:GetUInt32(0)
        local back = { map = q:GetUInt32(1), x = q:GetFloat(2), y = q:GetFloat(3), z = q:GetFloat(4), o = q:GetFloat(5) }
        local visitor = player_by_low(low)
        -- online: back now; offline: at their next login
        if visitor then
            send_home(visitor, back, q:GetUInt32(6) == 1)
        else
            CharDBExecute("UPDATE beta_211a_moonglade_visitors SET left_glade = 1 WHERE guid = " .. low)
        end
    until not q:NextRow()
end
-- }}}

-- {{{ Moonglade.onLogin
-- A visitor whose druid has left, is offline or is elsewhere goes back; one
-- still hosted stays. A druid learns the spell if they lack it, has their
-- way back read once, and, if they have visitors (a restart in between)
-- but are not in the glade, has left it.
function Moonglade.onLogin(event, player)
    local low = player:GetGUIDLow()
    local v = CharDBQuery("SELECT druid, map, x, y, z, o, left_glade, came_dead FROM beta_211a_moonglade_visitors WHERE guid = " .. low)
    if v then
        local druidLow = v:GetUInt32(0)
        local back = { map = v:GetUInt32(1), x = v:GetFloat(2), y = v:GetFloat(3), z = v:GetFloat(4), o = v:GetFloat(5) }
        local cameDead = v:GetUInt32(7) == 1
        local druid = player_by_low(druidLow)
        -- the druid left, is offline, or is elsewhere: back; hosting in the glade: stays
        if v:GetUInt32(6) == 1 or not druid or not in_glade(druid) then
            send_home(player, back, cameDead)
        else
            Moonglade.visiting[low] = { druid = druidLow, back = back, cameDead = cameDead }
        end
    end
    if player:GetClass() ~= CLASS_DRUID then return end
    if not player:HasSpell(SPELL_MOONGLADE) then player:LearnSpell(SPELL_MOONGLADE) end
    local q = CharDBQuery("SELECT map, x, y, z, o FROM beta_211a_moonglade_return WHERE guid = " .. low)
    -- a row: the way back; none: nothing to return to
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
-- }}}

-- {{{ Moonglade.onLogout
-- A druid logging out has left the glade.
function Moonglade.onLogout(event, player)
    Moonglade.druidLeft(player:GetGUIDLow())
end
-- }}}

-- {{{ Moonglade.onZone
-- A zone change: a druid leaving the glade sends their visitors back; a
-- visitor leaving it on their own stops being one.
function Moonglade.onZone(event, player, newZone, newArea)
    if newZone == ZONE_MOONGLADE then return end
    local low = player:GetGUIDLow()
    Moonglade.druidLeft(low)
    if Moonglade.visiting[low] then forget_visitor(low) end
end
-- }}}

-- {{{ Moonglade.arrive
-- The booked move into the glade, once the spell has landed: the druid to
-- a random spot on open ground, the visitors round them on 211's circle by
-- group number, each raised first if dead. Not in Moonglade yet (a slow map
-- load): looks again, up to ARRIVE_TRIES times, then leaves everyone where
-- they are.
function Moonglade.arrive(eventId, delay, repeats, player, tries)
    tries = tries or 1
    local low = player:GetGUIDLow()
    if not in_glade(player) then
        -- not arrived: look again, or give up after the last try
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
    -- a spot kept: moved there; none in DRAWS draws: stays in Nighthaven, logged
    if x then
        player:Teleport(MAP_KALIMDOR, x, y, z, o)
    else
        x, y, z = player:GetLocation()
        print("[Moonglade] no open ground drawn in " .. Moonglade.GLADE.DRAWS .. " tries for " .. player:GetName() .. "; left in Nighthaven")
    end
    -- the visitors, round the druid
    local trip = Moonglade.trips[low]
    Moonglade.trips[low] = nil
    if not trip then return end
    local ring = GroupHearth.circle(x, y, trip.size)
    for _, t in ipairs(trip.list) do
        local visitor = player_by_low(t.low)
        -- still in the world: brought (raised if dead), and a visitor; gone meanwhile: skipped
        if visitor then
            local spot = ring[t.place]
            local vz = map:GetHeight(spot.x, spot.y) or z
            local cameDead = visitor:IsDead()
            if cameDead then visitor:ResurrectPlayer(100, false) end
            keep_visitor(t.low, low, t.back, cameDead)
            visitor:Teleport(MAP_KALIMDOR, spot.x, spot.y, vz, math.random() * 2 * math.pi)
        end
    end
end
-- }}}

-- {{{ Moonglade.goBack
-- The booked return: to the way back remembered when the druid set out,
-- which is then forgotten. The spot was taken from memory at the cast, so a
-- logout in between loses nothing (the database row is removed only here).
-- The visitors follow by the zone change this causes (Moonglade.onZone).
function Moonglade.goBack(player, spot)
    player:Teleport(spot.map, spot.x, spot.y, spot.z, spot.o)
    Moonglade.remember(player:GetGUIDLow(), nil)
end
-- }}}

-- {{{ Moonglade.onPrepare
-- The cast begins: outside the glade, the group is invited to visit. In it
-- (the way back), nobody is: visitors follow when the druid leaves.
function Moonglade.onPrepare(event, caster, spell)
    if not caster:IsPlayer() then return end
    if in_glade(caster) then return end
    GroupHearth.open(caster, VISIT_KIND, GLADE_NAME)
end
-- }}}

-- {{{ Moonglade.onCast
-- Teleport: Moonglade completing (other spells: nothing). See the file's
-- header for the cases.
function Moonglade.onCast(event, player, spell)
    if spell:GetEntry() ~= SPELL_MOONGLADE then return end
    local low = player:GetGUIDLow()

    -- inside Moonglade: back to the way back, or stock with a word
    if in_glade(player) then
        local spot = Moonglade.spots[low]
        if spot then
            player:RegisterEvent(function(_, _, _, p) Moonglade.goBack(p, spot) end, FOLLOW_MS, 1)
        else
            player:SendBroadcastMessage("You have nowhere to return to from the glade.")
        end
        return
    end

    -- outside it: the druid's way back (known: kept; not known: forgotten, with a word)
    local back = Moonglade.wayBack(player)
    Moonglade.remember(low, back)
    if not back then
        player:SendBroadcastMessage("The way back from this place is not known; the glade will have no way back for you.")
    end

    -- the visitors who said yes, each with their way back; one whose way
    -- back is not known stays, so nobody is left in the glade with none
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
    Moonglade.trips[low] = { list = list, size = size }
    player:RegisterEvent(Moonglade.arrive, FOLLOW_MS, 1)
end
-- }}}

RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN,       Moonglade.onLogin)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT,      Moonglade.onLogout)
RegisterPlayerEvent(PLAYER_EVENT_ON_SPELL_CAST,  Moonglade.onCast)
RegisterPlayerEvent(PLAYER_EVENT_ON_UPDATE_ZONE, Moonglade.onZone)
RegisterSpellEvent(SPELL_MOONGLADE, SPELL_EVENT_ON_PREPARE, Moonglade.onPrepare)
-- hearthstone.lua's cancel, looked up when called: it loads after this file
RegisterSpellEvent(SPELL_MOONGLADE, SPELL_EVENT_ON_CAST_CANCEL, function(...) return GroupHearth.onCancel(...) end)
