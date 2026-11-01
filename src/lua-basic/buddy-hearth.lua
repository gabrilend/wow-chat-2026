--------------------------------------------------------------------------------
-- buddy-hearth.lua (issue 617e, hearthstones)
--
-- For a general audience: when a partner uses their hearthstone, their
-- buddies come too, whatever happened to the buddies' own hearthstones.
-- The owner, 2026-10-04: "can we ensure that buddy-bots always always get
-- teleported correctly when the player-partner casts hearthstone? Even if
-- their cast didn't complete, or if they were interrupted by combat or
-- dying... we still teleport them manually with lua". And earlier the same
-- day: buddies left behind had used their own hearthstones, which still
-- point at the starting valley (buddies never bind).
--
--   a partner finishes a hearthstone (or a shaman's Astral Recall): a
--     moment later (HEARTH_FOLLOW_MS, once the partner has arrived) every
--     buddy of theirs in the world has any spell it is casting stopped and
--     is moved onto an arc round the partner, facing them; alive or dead,
--     near or far, mid-fight or not;
--   a buddy finishes its own hearthstone: it is moved the same way to its
--     partner's bind spot instead of its own (the starting valley).
--
-- The places come from lib/buddy-arc.lua ("centre": the partner in the
-- middle, each buddy at its roster index's place). The stored per-buddy
-- bind spot of 617e's design (a ring round the partner's bind point, kept
-- in the database) replaces this when it is built.
--------------------------------------------------------------------------------

local PLAYER_EVENT_ON_SPELL_CAST = 5      -- fires as a cast completes, before its effect
local HEARTH_SPELLS = { [8690] = true,    -- Hearthstone
                        [556]  = true }   -- Astral Recall (shaman)
local HEARTH_FOLLOW_MS = 1500             -- after the partner's cast: they have arrived by then
local CURRENT_GENERIC_SPELL, CURRENT_CHANNELED_SPELL = 1, 3
local TAG = "[buddy-hearth] "

-- {{{ local function script_dir
local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end
-- }}}

local Arc = dofile(script_dir() .. "lib/buddy-arc.lua")

-- {{{ local function roster_of
-- The partner's registered buddies by slot (character guids, low part).
local function roster_of(partner_low)
    local list = {}
    local q = CharDBQuery("SELECT buddy FROM buddy_roster WHERE owner = " .. partner_low .. " AND buddy <> 0 ORDER BY slot")
    if q then repeat list[#list + 1] = q:GetUInt32(0) until not q:NextRow() end
    return list
end
-- }}}

-- {{{ local function place_round
-- Moves `which` (a buddy guid, or nil for every buddy) of the partner
-- `partner_low` onto the arc round (map, x, y, z), facing o. A buddy's own
-- cast is stopped first, so a hearthstone it had started can't land after
-- the move and carry it off to the starting valley.
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
-- }}}

-- {{{ local function on_spell_cast
local function on_spell_cast(event, player, spell)
    if not HEARTH_SPELLS[spell:GetEntry()] then return end
    local low = player:GetGUIDLow()
    local owner = CharDBQuery("SELECT owner FROM buddy_roster WHERE buddy = " .. low)
    if owner then
        -- a buddy's own hearthstone: to its partner's bind spot instead
        local partner_low = owner:GetUInt32(0)
        player:RegisterEvent(function(_, _, _, b)
            local partner = GetPlayerByGUID(GetPlayerGUID(partner_low))
            if not partner then return end                 -- the partner is offline: it stays where its own stone took it
            local home = partner:GetHomebind()
            place_round(partner_low, low, home.mapId, home.x, home.y, home.z, 0)
        end, HEARTH_FOLLOW_MS, 1)
        return
    end
    if #roster_of(low) == 0 then return end                -- a player without buddies
    -- a partner riding along on someone's group hearth (group-hearth.lua,
    -- 211): their hearthstone ends on that hearth's circle, not at home, so
    -- the buddies go there; asked now, while the ride is still known
    local ride = GroupHearth and GroupHearth.rideTarget and GroupHearth.rideTarget(player:GetGUID())
    -- a partner's hearthstone: everyone follows, round where they arrive
    player:RegisterEvent(function(_, _, _, p)
        local home = p:GetHomebind()
        if ride then home = { mapId = ride.map, x = ride.x, y = ride.y, z = ride.z } end
        local x, y, z, o = p:GetLocation()
        if ride or p:GetMapId() ~= home.mapId then
            -- riding: the circle spot itself (the partner is moved there at
            -- this same moment); not arrived yet (a slow map load): the bind spot
            x, y, z, o = home.x, home.y, home.z, 0
        end
        local moved, total = place_round(p:GetGUIDLow(), nil, home.mapId, x, y, z, o)
        if moved < total then
            print(string.format("%s%s hearthed: %d of %d buddies moved with them (the rest are not in the world)", TAG, p:GetName(), moved, total))
        end
    end, HEARTH_FOLLOW_MS, 1)
end
-- }}}

-- {{{ the city teleports and the way back (issue 723)
-- A mage's city teleport works like a hearthstone for its buddies (they
-- come along, round where the mage arrives), and gains a way back, as
-- Teleport: Moonglade has (the owner, 2026-10-22: "casting it again
-- returns them to where they were before they teleported"; 2026-10-30, on
-- a chain of teleports: "the most recent place they were at"). Each path,
-- at the cast of one of the teleports in data/teleport-destinations.lua
-- (made by scripts/generate-teleport-destinations from the game's files):
--   cast away from its city, in the open world  - where the caster stands
--       is kept as that teleport's way back (one per caster and spell, the
--       latest replacing the last), the spell goes as stock, buddies follow
--   cast away, inside a dungeon, raid or battleground - nothing kept (a way
--       back into an instance is no place to return to), buddies follow
--   cast inside its city, with a way back       - the spell lands as stock,
--       then the caster is sent along the way back (which is then used up),
--       and the buddies follow there
--   cast inside its city, none kept             - stock, and the caster is
--       told there was no way back to take
-- "Inside its city": the caster's zone is the city's (a city is a zone of
-- its own), or, for a town inside a larger zone (Stonard, Theramore
-- Isle), the caster stands in the town's area or within TOWN_NEAR_YARDS of
-- where the spell lands. Party members are not taken along (issue 723's
-- question 1, by the group hearthstone's prompt: not built); Death Gate
-- (its way in is a gate, not a teleport spell) and Teleport: Moonglade
-- (already two-way in the stock game) are not among these.
local TELEPORTS       = dofile(script_dir() .. "data/teleport-destinations.lua")
local TOWN_NEAR_YARDS = 300                  -- a town's teleport: this near its landing spot counts as inside
local TELEPORT_FOLLOW_MS = 1500              -- after the cast: the spell's own move has landed by then

-- where each teleport lands (the world database's spell_target_position)
local LANDING = {}
for spell in pairs(TELEPORTS) do
    local q = WorldDBQuery("SELECT MapID, PositionX, PositionY, PositionZ FROM spell_target_position WHERE ID = " .. spell)
    if q then
        LANDING[spell] = { map = q:GetUInt32(0), x = q:GetFloat(1), y = q:GetFloat(2), z = q:GetFloat(3) }
    else
        print(string.format("%sERROR: teleport %d has no landing spot in spell_target_position; a cast of it inside its town is not recognised", TAG, spell))
    end
end

-- {{{ local function inside_destination
local function inside_destination(player, spell)
    local d = TELEPORTS[spell]
    if player:GetMapId() ~= d.map then return false end
    if d.zone then return player:GetZoneId() == d.area end
    if player:GetAreaId() == d.area then return true end
    local l = LANDING[spell]
    return l ~= nil and (player:GetX() - l.x) ^ 2 + (player:GetY() - l.y) ^ 2 <= TOWN_NEAR_YARDS ^ 2
end
-- }}}

-- {{{ local function buddies_follow
-- The caster's buddies placed round where the caster now stands, or, while
-- the caster is still on another map (a slow load), round where they are
-- going (`to`: { map, x, y, z, o }).
local function buddies_follow(p, to)
    if #roster_of(p:GetGUIDLow()) == 0 then return end
    local x, y, z, o = p:GetLocation()
    if p:GetMapId() ~= to.map then
        x, y, z, o = to.x, to.y, to.z, to.o or 0
    end
    place_round(p:GetGUIDLow(), nil, to.map, x, y, z, o)
end
-- }}}

-- {{{ local function on_teleport_cast
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
-- }}}
-- }}}

RegisterPlayerEvent(PLAYER_EVENT_ON_SPELL_CAST, on_spell_cast)
RegisterPlayerEvent(PLAYER_EVENT_ON_SPELL_CAST, on_teleport_cast)
