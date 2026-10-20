
local SPACING     = 2.5
local MIN_RADIUS  = 3
local RING_ODDS   = 0.75

local Arc = {}

function Arc.pick_shape(asked, roll)
    if asked == "ring" or asked == "centre" then return asked end
    return roll < RING_ODDS and "ring" or "centre"
end

function Arc.places(ax, ay, ao, n, shape)
    local out = {}
    if n < 1 then return out end
    if shape == "ring" then
        local count  = n + 1
        local radius = math.max(MIN_RADIUS, SPACING * count / (2 * math.pi))
        local cx     = ax + math.cos(ao) * radius
        local cy     = ay + math.sin(ao) * radius
        local back   = ao + math.pi
        for k = 1, n do
            local a = back + k * 2 * math.pi / count
            local x = cx + math.cos(a) * radius
            local y = cy + math.sin(a) * radius
            out[k] = { x = x, y = y, o = math.atan2(cy - y, cx - x) % (2 * math.pi) }
        end
    else
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

return Arc
