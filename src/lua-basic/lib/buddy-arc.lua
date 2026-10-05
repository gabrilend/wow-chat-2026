--------------------------------------------------------------------------------
-- lib/buddy-arc.lua (issue 617e; the game master's buddy commands)
--
-- Where a partner's buddies stand when they are put somewhere at once
-- (brought to the partner, brought to a game master, revived): places on a
-- circle round an anchor (the partner, the game master, a graveyard). Plain
-- geometry, no game calls, so scripts/test-buddy-arc can check it offline.
--
-- The owner, 2026-10-04: "they should be placed with an arc around a circle
-- with a certain radius. The arc should be modified depending on how many
-- buddy-bots are registered to the player. The player's should often count
-- as one, but sometimes the player-partner is the center." Two shapes:
--
--   ring    the anchor stands on the circle as one of its places: n buddies
--           and the anchor make n + 1 places spaced evenly round a circle
--           whose centre is in front of the anchor; everyone faces the
--           centre (a circle of friends, the anchor included).
--   centre  the anchor stands at the centre; the buddies stand on an arc in
--           front of it, SPACING apart along the circle, the arc growing
--           with n until it closes into a full ring; they face the anchor.
--
-- n is how many buddies are registered to the partner (roster rows with a
-- buddy), and a buddy's place is its index among them (by roster slot), so
-- each buddy has the same place whether or not the others are present.
-- "often ... sometimes": with no shape asked for, ring three times in four.
--------------------------------------------------------------------------------

local SPACING     = 2.5     -- yards between neighbouring places along the circle
local MIN_RADIUS  = 3       -- yards: the smallest circle
local RING_ODDS   = 0.75    -- chance of "ring" when no shape is asked for

local Arc = {}

-- {{{ function Arc.pick_shape
-- `asked`: "ring", "centre" or nil; `roll`: a number in [0, 1) (math.random()).
function Arc.pick_shape(asked, roll)
    if asked == "ring" or asked == "centre" then return asked end
    return roll < RING_ODDS and "ring" or "centre"
end
-- }}}

-- {{{ function Arc.places
-- Places for n registered buddies round an anchor at (ax, ay) facing ao
-- (radians). Returns a list, index 1..n, of { x, y, o } (o: the facing).
function Arc.places(ax, ay, ao, n, shape)
    local out = {}
    if n < 1 then return out end
    if shape == "ring" then
        -- n + 1 places on a circle long enough to space them SPACING apart
        local count  = n + 1
        local radius = math.max(MIN_RADIUS, SPACING * count / (2 * math.pi))
        local cx     = ax + math.cos(ao) * radius          -- the centre, in front of the anchor
        local cy     = ay + math.sin(ao) * radius
        local back   = ao + math.pi                        -- the anchor's own angle seen from the centre
        for k = 1, n do
            local a = back + k * 2 * math.pi / count
            local x = cx + math.cos(a) * radius
            local y = cy + math.sin(a) * radius
            out[k] = { x = x, y = y, o = math.atan2(cy - y, cx - x) % (2 * math.pi) }
        end
    else
        -- an arc centred on the anchor's facing; the angle between places is
        -- SPACING along the circle, never more than a full ring's share
        local radius = MIN_RADIUS
        local step   = math.min(SPACING / radius, 2 * math.pi / n)
        for k = 1, n do
            local a = ao + (k - (n + 1) / 2) * step
            local x = ax + math.cos(a) * radius
            local y = ay + math.sin(a) * radius
            out[k] = { x = x, y = y, o = math.atan2(ay - y, ax - x) % (2 * math.pi) }
        end
    end
    return out
end
-- }}}

return Arc
