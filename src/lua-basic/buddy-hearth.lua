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
    -- a partner's hearthstone: everyone follows, round where they arrive
    player:RegisterEvent(function(_, _, _, p)
        local home = p:GetHomebind()
        local x, y, z, o = p:GetLocation()
        if p:GetMapId() ~= home.mapId then
            x, y, z, o = home.x, home.y, home.z, 0         -- not arrived yet (a slow map load): the bind spot itself
        end
        local moved, total = place_round(p:GetGUIDLow(), nil, home.mapId, x, y, z, o)
        if moved < total then
            print(string.format("%s%s hearthed: %d of %d buddies moved with them (the rest are not in the world)", TAG, p:GetName(), moved, total))
        end
    end, HEARTH_FOLLOW_MS, 1)
end
-- }}}

RegisterPlayerEvent(PLAYER_EVENT_ON_SPELL_CAST, on_spell_cast)
