--------------------------------------------------------------------------------
-- arathi-basin-formations.lua (issue 176a2d) - where each member of a
-- squad walks when no enemy is near
--
-- For a general audience: with nobody around, a squad closes up into a
-- shape and walks its road that way (owner, 2026-10-08: "either two in
-- front with the healer behind, or two to the sides and the tank in front
-- with the healer behind. So, triangle or diamond shape"). This works out
-- each member's spot from the squad's middle and the way its road runs;
-- the bot then steers to that spot. Plain arithmetic, no creature.
--
-- Shapes, in the squad's own frame (forward = the way the road runs):
--   triangle  the two damage ahead, side by side; the healer behind
--   diamond   the tank ahead; the two damage left and right; the healer
--             behind
--   line      one behind another, for narrow ground or a squad of two or
--             one (176a2d questions 2 and 3, one reading)
--
-- Open choices, each built (the report compares them):
--   opts.spacing     yards between members (question 1): 3 or 5
--   opts.calm_range  yards with no enemy before the shape closes up
--                    (question 1): 20 (about the stock aggro range) or 40
--   opts.narrow      "line" | "keep" (question 2): on ground narrower than
--                    the shape, squeeze into a line, or keep the shape
--   opts.small       "line" | "follow" (question 3): a squad of two or one
--                    walks as a line, or just follows its first member
--------------------------------------------------------------------------------

local Formations = {}

Formations.DEFAULTS = { spacing = 3, calm_range = 20, narrow = "line", small = "line" }

local function opt(opts, key)
    local v = (opts or {})[key]
    if v == nil then v = Formations.DEFAULTS[key] end
    return v
end

-- {{{ function Formations.shape_for
-- Which shape a squad takes: diamond with a tank (and four members),
-- triangle for a trio, otherwise a line (or "follow" for two or one).
-- `narrow` true when the ground ahead is narrower than the shape.
function Formations.shape_for(units, narrow, opts)
    local tank, n = false, #units
    for _, u in ipairs(units) do if u.role == "tank" then tank = true end end
    if narrow and opt(opts, "narrow") == "line" then return "line" end
    if n <= 2 then return opt(opts, "small") end
    if tank and n == 4 then return "diamond" end
    if n == 3 then return "triangle" end
    return "line"                                    -- an uneven group of five or more: one behind another
end
-- }}}

-- {{{ function Formations.slots
-- Each member's spot: { [unit.id] = { x, y } } in the world, from the
-- squad's middle (cx, cy) and its heading (radians, the way the road runs:
-- 0 = +x). Members are put in their slots by role: tank ahead, damage at
-- the sides or front, healer behind.
function Formations.slots(units, shape, cx, cy, heading, opts)
    local s = opt(opts, "spacing")
    local local_spots = {}                            -- { right, forward } per member, in order
    local tanks, damage, healers, other = {}, {}, {}, {}
    for _, u in ipairs(units) do
        local bucket = (u.role == "tank" and tanks) or (u.role == "damage" and damage) or (u.role == "healer" and healers) or other
        bucket[#bucket + 1] = u
    end
    local order = {}
    if shape == "triangle" then
        -- two damage ahead (left, right), healer behind in the middle
        order = { { damage[1], -s / 2, s / 2 }, { damage[2], s / 2, s / 2 }, { healers[1], 0, -s / 2 } }
    elseif shape == "diamond" then
        -- tank ahead, damage left and right, healer behind
        order = { { tanks[1], 0, s }, { damage[1], -s, 0 }, { damage[2], s, 0 }, { healers[1], 0, -s } }
    else
        -- a line (or follow): tanks first, then damage, then healers, one behind another
        local seq = {}
        for _, list in ipairs({ tanks, damage, other, healers }) do for _, u in ipairs(list) do seq[#seq + 1] = u end end
        for k, u in ipairs(seq) do order[k] = { u, 0, -(k - 1) * s } end
    end
    local out = {}
    local fx, fy = math.cos(heading), math.sin(heading)          -- forward
    local rx, ry = math.sin(heading), -math.cos(heading)         -- right
    for _, o in ipairs(order) do
        local u, right, fwd = o[1], o[2], o[3]
        if u then out[u.id] = { cx + rx * right + fx * fwd, cy + ry * right + fy * fwd } end
    end
    return out
end
-- }}}

-- {{{ function Formations.calm
-- Whether the squad may close up: no enemy within calm_range of its middle.
-- `enemies` = list of { x, y }.
function Formations.calm(cx, cy, enemies, opts)
    local r = opt(opts, "calm_range")
    for _, e in ipairs(enemies or {}) do
        if (e[1] - cx) ^ 2 + (e[2] - cy) ^ 2 <= r * r then return false end
    end
    return true
end
-- }}}

return Formations
