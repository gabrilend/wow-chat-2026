
local Formations = {}

Formations.DEFAULTS = { spacing = 3, calm_range = 20, narrow = "line", small = "line" }

local function opt(opts, key)
    local v = (opts or {})[key]
    if v == nil then v = Formations.DEFAULTS[key] end
    return v
end

function Formations.shape_for(units, narrow, opts)
    local tank, n = false, #units
    for _, u in ipairs(units) do if u.role == "tank" then tank = true end end
    if narrow and opt(opts, "narrow") == "line" then return "line" end
    if n <= 2 then return opt(opts, "small") end
    if tank and n == 4 then return "diamond" end
    if n == 3 then return "triangle" end
    return "line"
end

function Formations.slots(units, shape, cx, cy, heading, opts)
    local s = opt(opts, "spacing")
    local local_spots = {}
    local tanks, damage, healers, other = {}, {}, {}, {}
    for _, u in ipairs(units) do
        local bucket = (u.role == "tank" and tanks) or (u.role == "damage" and damage) or (u.role == "healer" and healers) or other
        bucket[#bucket + 1] = u
    end
    local order = {}
    if shape == "triangle" then
        order = { { damage[1], -s / 2, s / 2 }, { damage[2], s / 2, s / 2 }, { healers[1], 0, -s / 2 } }
    elseif shape == "diamond" then
        order = { { tanks[1], 0, s }, { damage[1], -s, 0 }, { damage[2], s, 0 }, { healers[1], 0, -s } }
    else
        local seq = {}
        for _, list in ipairs({ tanks, damage, other, healers }) do for _, u in ipairs(list) do seq[#seq + 1] = u end end
        for k, u in ipairs(seq) do order[k] = { u, 0, -(k - 1) * s } end
    end
    local out = {}
    local fx, fy = math.cos(heading), math.sin(heading)
    local rx, ry = math.sin(heading), -math.cos(heading)
    for _, o in ipairs(order) do
        local u, right, fwd = o[1], o[2], o[3]
        if u then out[u.id] = { cx + rx * right + fx * fwd, cy + ry * right + fy * fwd } end
    end
    return out
end

function Formations.calm(cx, cy, enemies, opts)
    local r = opt(opts, "calm_range")
    for _, e in ipairs(enemies or {}) do
        if (e[1] - cx) ^ 2 + (e[2] - cy) ^ 2 <= r * r then return false end
    end
    return true
end

return Formations
