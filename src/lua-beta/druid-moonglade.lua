--------------------------------------------------------------------------------
-- druid-moonglade.lua - a druid's hearthstone is Teleport: Moonglade (issue 211a)
--
-- Druids on beta meet no innkeeper among the travellers, so they cannot move
-- their Hearthstone's bind point; their way home is the glade instead. The
-- owner, 2026-10-18: "they're supposed to start with teleport moonglade, and
-- that's their hearthstone. But casting it while in Moonglade will teleport
-- them back to where they were before they teleported to moonglade." and
-- "can we create more than one spawn position for the druid in moonglade?
-- It should be essentially random."
--
--   login: a druid without Teleport: Moonglade learns it, at any level; the
--     druid's remembered spot is read once from the characters database
--   the spell completes outside Moonglade: the spot the druid stood on is
--     remembered (kept in the database, so logouts and restarts keep it);
--     once the spell has put them in Nighthaven, they are moved to a random
--     spot on the glade's open ground
--   the spell completes inside Moonglade: with a spot remembered, once the
--     spell's own move is done they are sent back to it, and it is
--     forgotten; with none, the spell is stock (Nighthaven) and they are
--     told there is nowhere to return to
--   the spell completes in an instance, battleground or arena: nothing is
--     remembered and any earlier spot is forgotten, so a return never goes
--     somewhere older than the druid's last trip
--
-- Open questions answered by default for now (issue 211a): the group does
-- not come along (211's invitation is for Hearthstone and Astral Recall
-- only); an instance cast forgets the earlier spot; no cooldown is added
-- (the stock spell has none, read from Spell.dbc).
--
-- The spell-cast event fires as a cast completes, before its effect
-- (Spell::_cast calls OnPlayerSpellCast "before the spell is actually
-- executed"), so at that moment the druid still stands where they cast it.
-- The moves after it wait FOLLOW_MS, as the buddies' hearth does
-- (src/lua-basic/buddy-hearth.lua), for the spell's teleport to land.
--------------------------------------------------------------------------------

Moonglade = Moonglade or {}

local PLAYER_EVENT_ON_LOGIN      = 3
local PLAYER_EVENT_ON_SPELL_CAST = 5   -- fires as a cast completes, before its effect

local CLASS_DRUID     = 11
local SPELL_MOONGLADE = 18960          -- Teleport: Moonglade
local ZONE_MOONGLADE  = 493
local MAP_KALIMDOR    = 1
local FOLLOW_MS       = 1500           -- after the cast: the spell's teleport has landed by then
local ARRIVE_TRIES    = 3              -- a slow map load: look again this many times

-- the open world, where a spot may be remembered; anything else (an
-- instance, a battleground, an arena) is not returned to
local OPEN_WORLD = { [0] = true, [1] = true, [530] = true, [571] = true }

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

-- remembered spots by character guid low part: { map, x, y, z, o }, or
-- false when the druid has none (read from the database at login)
Moonglade.spots = Moonglade.spots or {}

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
-- Keeps a spot (or forgets it, spot nil), in memory and in the database.
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

-- {{{ Moonglade.onLogin
-- A druid learns the spell if they lack it, and their spot is read once.
-- Other classes: nothing.
function Moonglade.onLogin(event, player)
    if player:GetClass() ~= CLASS_DRUID then return end
    if not player:HasSpell(SPELL_MOONGLADE) then player:LearnSpell(SPELL_MOONGLADE) end
    local low = player:GetGUIDLow()
    local q = CharDBQuery("SELECT map, x, y, z, o FROM beta_211a_moonglade_return WHERE guid = " .. low)
    -- a row: the spot; none: nothing to return to
    if q then
        Moonglade.spots[low] = { map = q:GetUInt32(0), x = q:GetFloat(1), y = q:GetFloat(2), z = q:GetFloat(3), o = q:GetFloat(4) }
    else
        Moonglade.spots[low] = false
    end
end
-- }}}

-- {{{ Moonglade.arrive
-- The booked move into the glade, once the spell has landed: a random spot
-- on open ground. Not in Moonglade yet (a slow map load): looks again, up
-- to ARRIVE_TRIES times, then leaves the druid where the spell put them.
function Moonglade.arrive(eventId, delay, repeats, player, tries)
    tries = tries or 1
    if player:GetMapId() ~= MAP_KALIMDOR or player:GetZoneId() ~= ZONE_MOONGLADE then
        -- not arrived: look again, or give up after the last try
        if tries < ARRIVE_TRIES then
            player:RegisterEvent(function(e, d, r, p) Moonglade.arrive(e, d, r, p, tries + 1) end, FOLLOW_MS, 1)
        else
            print("[Moonglade] " .. player:GetName() .. " was not in Moonglade " .. tries * FOLLOW_MS .. " ms after the spell; left where they are")
        end
        return
    end
    local x, y, z, o = Moonglade.drawArrival(player:GetMap())
    -- a spot kept: moved there; none in DRAWS draws: stays in Nighthaven, logged
    if x then
        player:Teleport(MAP_KALIMDOR, x, y, z, o)
    else
        print("[Moonglade] no open ground drawn in " .. Moonglade.GLADE.DRAWS .. " tries for " .. player:GetName() .. "; left in Nighthaven")
    end
end
-- }}}

-- {{{ Moonglade.goBack
-- The booked return: to the spot remembered when the druid set out, which
-- is then forgotten. The spot was taken from memory at the cast, so a
-- logout in between loses nothing (the database row is removed only here).
function Moonglade.goBack(player, spot)
    player:Teleport(spot.map, spot.x, spot.y, spot.z, spot.o)
    Moonglade.remember(player:GetGUIDLow(), nil)
end
-- }}}

-- {{{ Moonglade.onCast
-- Teleport: Moonglade completing (other spells: nothing). See the file's
-- header for the four cases.
function Moonglade.onCast(event, player, spell)
    if spell:GetEntry() ~= SPELL_MOONGLADE then return end
    local low = player:GetGUIDLow()
    local map = player:GetMapId()

    -- inside Moonglade: back to the remembered spot, or stock with a word
    if map == MAP_KALIMDOR and player:GetZoneId() == ZONE_MOONGLADE then
        local spot = Moonglade.spots[low]
        if spot then
            player:RegisterEvent(function(_, _, _, p) Moonglade.goBack(p, spot) end, FOLLOW_MS, 1)
        else
            player:SendBroadcastMessage("You have nowhere to return to from the glade.")
        end
        return
    end

    -- an instance, battleground or arena: nothing to return to
    if not OPEN_WORLD[map] then
        Moonglade.remember(low, nil)
        return
    end

    -- the open world: remember where they stand, then a random spot in the glade
    local x, y, z, o = player:GetLocation()
    Moonglade.remember(low, { map = map, x = x, y = y, z = z, o = o })
    player:RegisterEvent(Moonglade.arrive, FOLLOW_MS, 1)
end
-- }}}

RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN,      Moonglade.onLogin)
RegisterPlayerEvent(PLAYER_EVENT_ON_SPELL_CAST, Moonglade.onCast)
