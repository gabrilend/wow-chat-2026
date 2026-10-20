
local Deck = {}

local NEAR = 400

local MODULUS = 2147483647
local function park_miller(state)
    return (state * 16807) % MODULUS
end

function Deck.order(guid)
    local state = (guid % (MODULUS - 1)) + 1
    state = park_miller(park_miller(state))
    local order = { 0, 1, 2, 3 }
    for i = 4, 2, -1 do
        state = park_miller(state)
        local j = (state % i) + 1
        order[i], order[j] = order[j], order[i]
    end
    return order
end

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

function Deck.next(guid, here)
    local order = Deck.order(guid)
    if here == nil then return order[1] end
    for i = 1, 4 do
        if order[i] == here then return order[i % 4 + 1] end
    end
    error("valley index out of range: " .. tostring(here))
end

return Deck
