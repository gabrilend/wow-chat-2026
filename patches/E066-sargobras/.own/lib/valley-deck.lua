--------------------------------------------------------------------------------
-- lib/valley-deck.lua (issue 155d1)
--
-- "Actually, can I go somewhere else?": each character has its own deck of
-- its faction's four starting valleys, shuffled with the character's id as
-- the seed, so the order is the same every time it is worked out and nothing
-- is stored. The character's place in the deck is the valley it stands in;
-- the next deal is the valley after it, wrapping round after the fourth.
-- Three presses visit every other valley once; a fourth returns to the
-- first. Different characters get different orders ("the random chance of
-- destimagic", owner, 2026-10-04), while nobody else's play can change
-- yours.
--
-- Pure: no server calls, so scripts/test-valley-deal loads it as it is.
--------------------------------------------------------------------------------

local Deck = {}

-- {{{ tuning
-- A character farther than this from all four of its faction's valleys is
-- "nowhere in the deck" and is dealt the first card of its order. Starting
-- valleys are a few hundred yards across; arrivals stand at their centres.
local NEAR = 400                    -- yards
-- }}}

-- {{{ local function park_miller
-- The seeded shuffle's random numbers: the Park-Miller "minimal standard"
-- generator (state * 16807 mod 2^31-1). Every product stays below 2^53, so
-- LuaJIT's doubles hold it exactly, with no bit library; and it never
-- touches math.random, which other scripts share.
local MODULUS = 2147483647
local function park_miller(state)
    return (state * 16807) % MODULUS
end
-- }}}

-- {{{ function Deck.order
-- The character's own order of the four valley indices (0-3), as a list.
-- guid: the character's low guid, integer. Fisher-Yates, driven by the
-- generator above seeded from the guid (0 is not a valid state, hence +1).
function Deck.order(guid)
    local state = (guid % (MODULUS - 1)) + 1
    state = park_miller(park_miller(state))     -- two warm-up steps: neighbouring guids start further apart
    local order = { 0, 1, 2, 3 }
    for i = 4, 2, -1 do
        state = park_miller(state)
        local j = (state % i) + 1
        order[i], order[j] = order[j], order[i]
    end
    return order
end
-- }}}

-- {{{ function Deck.standing_in
-- Which of the faction's valleys (index 0-3) the position is in: the
-- nearest on the same map within NEAR yards, or nil when none is.
-- valleys: the faction's [0..3] from data/starting-valleys.lua.
function Deck.standing_in(valleys, map, x, y)
    local best, best_d
    for i = 0, 3 do
        local v = valleys[i]
        if v.map == map then
            local d = math.sqrt((v.x - x) ^ 2 + (v.y - y) ^ 2)
            if d <= NEAR and (not best_d or d < best_d) then best, best_d = i, d end
        end
    end
    return best
end
-- }}}

-- {{{ function Deck.next
-- The valley index (0-3) to deal: the one after `here` in the character's
-- order, wrapping; the order's first when `here` is nil (not in a valley).
function Deck.next(guid, here)
    local order = Deck.order(guid)
    if here == nil then return order[1] end
    for i = 1, 4 do
        if order[i] == here then return order[i % 4 + 1] end
    end
    error("valley index out of range: " .. tostring(here))
end
-- }}}

return Deck
