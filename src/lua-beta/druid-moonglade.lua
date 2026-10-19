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
-- arena."; and no cooldown ("I don't think a cooldown is necessary").
--
--   login: a druid without Teleport: Moonglade learns it, at any level; the
--     druid's way back is read once from the characters database; every
--     player's open-world note starts (where they stand, every NOTE_MS)
--   the cast begins outside Moonglade: the group is invited, by 211's
--     window (GroupHearth.open); a cancelled cast withdraws it
--   the cast completes outside Moonglade: the druid's way back is
--     remembered (in the database): where they stand, or, in an instance,
--     where they entered it (their last open-world note). The visitors who
--     said yes are taken, each with their own way back. Once the spell has
--     put the druid in Nighthaven, they are moved to a random spot on the
--     glade's open ground, and the visitors round them
--   the cast completes inside Moonglade: with a way back, the druid is
--     sent there once the spell's own move is done, and it is forgotten;
--     with none, the spell is stock (Nighthaven) and they are told so
--   the druid leaves Moonglade (any way, or logs out): their visitors still
--     in the glade are sent back to their own ways back; a visitor who was
--     offline is sent back at their next login; a visitor who leaves on
--     their own stops being one
--
-- The spell-cast event fires as a cast completes, before its effect
-- (Spell::_cast calls OnPlayerSpellCast "before the spell is actually
-- executed"), so at that moment everyone still stands where they were.
-- The moves after it wait FOLLOW_MS, as the buddies' hearth does
-- (src/lua-basic/buddy-hearth.lua), for the spell's teleport to land.
--
-- Why a note every few seconds: the game keeps an entry point only for
-- battlegrounds and the dungeon finder (Player::SetEntryPoint), not for a
-- dungeon walked into, and the Lua engine cannot read it either way. The
-- map-change event fires after the player has arrived, so the only way to
-- know where they stood before is to have looked shortly before.
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
local NOTE_MS         = 5000           -- how often a player's open-world spot is noted

-- the open world, where a way back may be; anything else (a dungeon, a
-- raid, a battleground, an arena) is returned to at its entrance instead
local OPEN_WORLD = { [0] = true, [1] = true, [530] = true, [571] = true }

-- the window's words for this trip (211's window, GroupHearth.open)
local VISIT_KIND = { question = "%s is going to Moonglade. Visit with them?",
                     confirm  = "Visit Moonglade with %s? You will come back when they leave." }

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
-- every player's last open-world spot, by guid: { map, x, y, z, o }
Moonglade.notes = Moonglade.notes or {}
-- visitors, by the visitor's guid: { druid = guid, back = { map, x, y, z, o },
--   left = true once the druid has left the glade }
Moonglade.visiting = Moonglade.visiting or {}
-- a trip between the cast and the arrival, by the druid's guid: the
-- visitors taken, { list = list of { guid, place, back }, size = group size }
Moonglade.trips = Moonglade.trips or {}

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

-- {{{ Moonglade.wayBack
-- Where a player goes back to from the glade: where they stand in the open
-- world, or where they entered the instance they are in (their last note);
-- nil when that is not known (they logged in inside it after a restart).
function Moonglade.wayBack(player)
    local map = player:GetMapId()
    if OPEN_WORLD[map] then
        local x, y, z, o = player:GetLocation()
        return { map = map, x = x, y = y, z = z, o = o }
    end
    return Moonglade.notes[player:GetGUID()]
end
-- }}}

-- {{{ Moonglade.note
-- Every NOTE_MS: the player's spot, while in the open world. On another map
-- the note is left as it was: the last one before they went in, which is
-- where they entered. Rebooks itself (one timer per player, gone at logout).
function Moonglade.note(eventId, delay, repeats, player)
    if OPEN_WORLD[player:GetMapId()] then
        local x, y, z, o = player:GetLocation()
        Moonglade.notes[player:GetGUID()] = { map = player:GetMapId(), x = x, y = y, z = z, o = o }
    end
    player:RegisterEvent(Moonglade.note, NOTE_MS, 1)
end
-- }}}

-- {{{ local function sendHome
-- A visitor goes back to their way back and stops being a visitor.
--   in the glade: moved
--   left the glade some other way meanwhile: only forgotten
local function sendHome(visitor)
    local g = visitor:GetGUID()
    local v = Moonglade.visiting[g]
    Moonglade.visiting[g] = nil
    if v and visitor:GetMapId() == MAP_KALIMDOR and visitor:GetZoneId() == ZONE_MOONGLADE then
        visitor:SendBroadcastMessage("Your host has left Moonglade; you return to where you came from.")
        visitor:Teleport(v.back.map, v.back.x, v.back.y, v.back.z, v.back.o)
    end
end
-- }}}

-- {{{ Moonglade.druidLeft
-- The druid is no longer in the glade: each of their visitors online is sent
-- back; each offline is marked, to be sent back at login.
function Moonglade.druidLeft(druidGuid)
    for g, v in pairs(Moonglade.visiting) do
        if v.druid == druidGuid then
            local visitor = GetPlayerByGUID(g)
            -- online: back now; offline: at their next login
            if visitor then sendHome(visitor) else v.left = true end
        end
    end
end
-- }}}

-- {{{ Moonglade.onLogin
-- Every player: the open-world note starts; a visitor whose druid has left
-- the glade (or is not in it) goes back. A druid also learns the spell if
-- they lack it, and their way back is read once.
function Moonglade.onLogin(event, player)
    player:RegisterEvent(Moonglade.note, NOTE_MS, 1)
    local v = Moonglade.visiting[player:GetGUID()]
    if v then
        local druid = GetPlayerByGUID(v.druid)
        -- the druid left, is offline, or is elsewhere: back; still hosting: stays
        if v.left or not druid or druid:GetZoneId() ~= ZONE_MOONGLADE then sendHome(player) end
    end
    if player:GetClass() ~= CLASS_DRUID then return end
    if not player:HasSpell(SPELL_MOONGLADE) then player:LearnSpell(SPELL_MOONGLADE) end
    local low = player:GetGUIDLow()
    local q = CharDBQuery("SELECT map, x, y, z, o FROM beta_211a_moonglade_return WHERE guid = " .. low)
    -- a row: the way back; none: nothing to return to
    if q then
        Moonglade.spots[low] = { map = q:GetUInt32(0), x = q:GetFloat(1), y = q:GetFloat(2), z = q:GetFloat(3), o = q:GetFloat(4) }
    else
        Moonglade.spots[low] = false
    end
end
-- }}}

-- {{{ Moonglade.onLogout
-- A druid logging out has left the glade; the note's timer ends by itself.
function Moonglade.onLogout(event, player)
    Moonglade.druidLeft(player:GetGUID())
end
-- }}}

-- {{{ Moonglade.onZone
-- A zone change: a druid leaving the glade takes their visitors' stay with
-- them; a visitor leaving it on their own stops being one.
function Moonglade.onZone(event, player, newZone, newArea)
    if newZone == ZONE_MOONGLADE then return end
    Moonglade.druidLeft(player:GetGUID())
    Moonglade.visiting[player:GetGUID()] = nil
end
-- }}}

-- {{{ Moonglade.arrive
-- The booked move into the glade, once the spell has landed: the druid to
-- a random spot on open ground, the visitors round them on 211's circle by
-- group number. Not in Moonglade yet (a slow map load): looks again, up to
-- ARRIVE_TRIES times, then leaves everyone where they are.
function Moonglade.arrive(eventId, delay, repeats, player, tries)
    tries = tries or 1
    local g = player:GetGUID()
    if player:GetMapId() ~= MAP_KALIMDOR or player:GetZoneId() ~= ZONE_MOONGLADE then
        -- not arrived: look again, or give up after the last try
        if tries < ARRIVE_TRIES then
            player:RegisterEvent(function(e, d, r, p) Moonglade.arrive(e, d, r, p, tries + 1) end, FOLLOW_MS, 1)
        else
            Moonglade.trips[g] = nil
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
    local trip = Moonglade.trips[g]
    Moonglade.trips[g] = nil
    if not trip then return end
    local ring = GroupHearth.circle(x, y, trip.size)
    for _, t in ipairs(trip.list) do
        local visitor = GetPlayerByGUID(t.guid)
        -- still in the world: brought, and a visitor; gone meanwhile: skipped
        if visitor then
            local spot = ring[t.place]
            local vz = map:GetHeight(spot.x, spot.y) or z
            Moonglade.visiting[t.guid] = { druid = g, back = t.back }
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
    if caster:GetMapId() == MAP_KALIMDOR and caster:GetZoneId() == ZONE_MOONGLADE then return end
    GroupHearth.open(caster, VISIT_KIND)
end
-- }}}

-- {{{ Moonglade.onCast
-- Teleport: Moonglade completing (other spells: nothing). See the file's
-- header for the cases.
function Moonglade.onCast(event, player, spell)
    if spell:GetEntry() ~= SPELL_MOONGLADE then return end
    local low = player:GetGUIDLow()

    -- inside Moonglade: back to the way back, or stock with a word
    if player:GetMapId() == MAP_KALIMDOR and player:GetZoneId() == ZONE_MOONGLADE then
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
        player:SendBroadcastMessage("Where you entered this place is not known; the glade will have no way back for you.")
    end

    -- the visitors who said yes, each with their way back; one whose way
    -- back is not known stays, so nobody is left in the glade with none
    local list = {}
    local taken, size = GroupHearth.take(player:GetGUID())
    for _, t in ipairs(taken) do
        local visitor = GetPlayerByGUID(t.guid)
        local vback = visitor and Moonglade.wayBack(visitor)
        if vback then
            list[#list + 1] = { guid = t.guid, place = t.place, back = vback }
        elseif visitor then
            visitor:SendBroadcastMessage("Where you entered this place is not known, so you stay rather than visit the glade.")
        end
    end
    Moonglade.trips[player:GetGUID()] = { list = list, size = size }
    player:RegisterEvent(Moonglade.arrive, FOLLOW_MS, 1)
end
-- }}}

RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN,       Moonglade.onLogin)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT,      Moonglade.onLogout)
RegisterPlayerEvent(PLAYER_EVENT_ON_SPELL_CAST,  Moonglade.onCast)
RegisterPlayerEvent(PLAYER_EVENT_ON_UPDATE_ZONE, Moonglade.onZone)
RegisterSpellEvent(SPELL_MOONGLADE, SPELL_EVENT_ON_PREPARE, Moonglade.onPrepare)
-- hearthstone.lua's cancel, looked up when called: it may load after this file
RegisterSpellEvent(SPELL_MOONGLADE, SPELL_EVENT_ON_CAST_CANCEL, function(...) return GroupHearth.onCancel(...) end)
