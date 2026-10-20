
local Squads = {}

Squads.DEPARTURE_EVERY = 12
Squads.WAVE_EVERY      = 30
Squads.DEFAULTS        = { claimed = "assault", tanks = "home only", places = 15 }

local function opt(opts, key)
    local v = (opts or {})[key]
    if v == nil then v = Squads.DEFAULTS[key] end
    return v
end

function Squads.group(units)
    local damage, healers = {}, {}
    for _, u in ipairs(units) do
        if u.role == "damage" then damage[#damage + 1] = u elseif u.role == "healer" then healers[#healers + 1] = u end
    end
    if #healers > 0 and #damage == 2 * #healers then
        local squads = {}
        for k = 1, #healers do squads[k] = { damage[2 * k - 1], damage[2 * k], healers[k] } end
        return squads
    end
    if #units == 0 then return {} end
    local one = {}
    for _, u in ipairs(units) do one[#one + 1] = u end
    return { one }
end

function Squads.merge(a, b)
    local all = {}
    for _, u in ipairs(a) do all[#all + 1] = u end
    for _, u in ipairs(b) do all[#all + 1] = u end
    local d, h, other = 0, 0, 0
    for _, u in ipairs(all) do
        if u.role == "damage" then d = d + 1 elseif u.role == "healer" then h = h + 1 else other = other + 1 end
    end
    if #all == 6 and d == 4 and h == 2 and other == 0 then return Squads.group(all) end
    return { all }
end

function Squads.new_side(home, opts)
    return { home = home, opts = opts or {}, pool = {}, waiting = {}, tanks = {}, players = 0, stand_ins = 0, held_out = 0 }
end

function Squads.died(side, unit)
    if side.held_out < side.players and side.stand_ins + side.players > opt(side.opts, "places") then
        side.held_out = side.held_out + 1
        side.stand_ins = side.stand_ins - 1
        return "held out"
    end
    side.pool[#side.pool + 1] = unit
    return "pool"
end

function Squads.captured(side, tank)
    side.tanks[#side.tanks + 1] = tank
end

function Squads.player_joined(side) side.players = side.players + 1 end
function Squads.player_left(side)
    side.players = math.max(0, side.players - 1)
    if side.held_out > 0 then side.held_out = side.held_out - 1; side.stand_ins = side.stand_ins + 1; return "a stand-in may come back" end
end

function Squads.base_event(side, base, what)
    local trigger = opt(side.opts, "claimed")
    if not ((what == "assaulted" and trigger == "assault") or what == "captured") then return 0 end
    local moved = 0
    for _, w in ipairs(side.waiting) do
        if w.place == base then w.place = side.home; w.moved_home = true; moved = moved + 1 end
    end
    return moved
end

function Squads.choose_place(side, held, draw)
    local taken = {}
    for _, w in ipairs(side.waiting) do taken[w.place] = true end
    local free = {}
    for _, b in ipairs(held or {}) do if not taken[b] then free[#free + 1] = b end end
    table.sort(free)
    local choices = { side.home }
    for _, b in ipairs(free) do choices[#choices + 1] = b end
    local pick = draw and draw(#choices) or 1
    if type(pick) ~= "number" or pick < 1 or pick > #choices then return side.home, "fallback: a bad draw" end
    return choices[pick]
end

function Squads.depart(side, held, draw)
    local placed = {}
    local groups = Squads.group(side.pool)
    side.pool = {}
    for _, g in ipairs(groups) do
        local place = Squads.choose_place(side, held, draw)
        local w = { place = place, units = g }
        side.waiting[#side.waiting + 1] = w
        placed[#placed + 1] = w
    end
    if #side.tanks > 0 then
        local carrier
        for _, w in ipairs(placed) do
            if opt(side.opts, "tanks") == "any group" or w.place == side.home then carrier = w; break end
        end
        if carrier then
            for _, t in ipairs(side.tanks) do carrier.units[#carrier.units + 1] = t end
            side.tanks = {}
        end
    end
    return placed
end

function Squads.wave(side)
    local out = side.waiting
    side.waiting = {}
    return out
end

return Squads
