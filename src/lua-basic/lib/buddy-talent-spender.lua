
local Spender = {}

local function index_class(cls)
    if cls._index then return cls._index end
    local ix = { by_id = {}, tree_of = {}, opens_one_pointer = {} }
    for t, tree in ipairs(cls.trees) do
        for _, tal in ipairs(tree.talents) do
            ix.by_id[tal.id]   = tal
            ix.tree_of[tal.id] = t
        end
    end
    for _, tal in pairs(ix.by_id) do
        if tal.allowed and tal.ranks == 1 then
            local dep = tal.dep
            while dep ~= 0 do
                ix.opens_one_pointer[dep] = true
                dep = ix.by_id[dep].dep
            end
        end
    end
    cls._index = ix
    return ix
end

function Spender.read_held(cls, has_spell)
    local held = {}
    for _, tree in ipairs(cls.trees) do
        for _, tal in ipairs(tree.talents) do
            for k = tal.ranks, 1, -1 do
                if has_spell(tal.spells[k]) then held[tal.id] = k; break end
            end
        end
    end
    return held
end

local function spent_per_tree(cls, held)
    local ix, spent = index_class(cls), { 0, 0, 0 }
    for id, pts in pairs(held) do
        local t = ix.tree_of[id]
        if t then spent[t] = spent[t] + pts end
    end
    return spent
end

local function legal(cls, tal, held, spent_in_tree, rules)
    local h = held[tal.id] or 0
    if rules and rules.forbid[tal.id] then return false end
    if not (tal.allowed or (rules and rules.past_cap)) or h >= tal.ranks then return false end
    if spent_in_tree < tal.row * 5 then return false end
    if tal.dep ~= 0 and (held[tal.dep] or 0) < tal.dep_points then return false end
    return true
end

local function pick_in_tree(cls, t, held, spent, rand, rules)
    local ix                        = index_class(cls)
    local one_point, chain, open    = {}, {}, {}
    local newest_row, newest_taken  = {}, false
    local deepest                   = math.floor(spent[t] / 5)
    local started
    for _, tal in ipairs(cls.trees[t].talents) do
        if tal.row == deepest and (held[tal.id] or 0) > 0 then newest_taken = true end
        if legal(cls, tal, held, spent[t], rules) then
            if tal.ranks == 1 then
                one_point[#one_point + 1] = tal
            elseif (held[tal.id] or 0) > 0 then
                started = started or tal
            else
                open[#open + 1] = tal
                if ix.opens_one_pointer[tal.id] then chain[#chain + 1] = tal end
                if tal.row == deepest          then newest_row[#newest_row + 1] = tal end
            end
        end
    end
    if #one_point  > 0 then return one_point[rand(#one_point)] end
    if started         then return started                     end
    if #chain      > 0 then return chain[rand(#chain)]         end
    if not newest_taken and #newest_row > 0 then return newest_row[rand(#newest_row)] end
    if #open       > 0 then return open[rand(#open)]           end
    return nil
end

local function has_room(cls, t, held, spent, rules)
    for _, tal in ipairs(cls.trees[t].talents) do
        if legal(cls, tal, held, spent[t], rules) then return true end
    end
    return false
end

local function choose_tree(cls, thirds, held, spent, rand, rules)
    local shared_total = 0
    for t = 1, 3 do if thirds[t] > 0 then shared_total = shared_total + spent[t] end end

    local best, best_deficit
    for t = 1, 3 do
        if thirds[t] > 0 and has_room(cls, t, held, spent, rules) then
            local deficit = thirds[t] * (shared_total + 1) / 3 - spent[t]
            if not best or deficit > best_deficit
               or (deficit == best_deficit and thirds[t] > thirds[best]) then
                best, best_deficit = t, deficit
            end
        end
    end
    if best then return best end

    local fresh = {}
    for t = 1, 3 do
        if thirds[t] == 0 and has_room(cls, t, held, spent, rules) then
            if spent[t] > 0 then return t end
            fresh[#fresh + 1] = t
        end
    end
    if #fresh > 0 then return fresh[rand(#fresh)] end
    return nil
end

local function bottom_row(cls, t)
    local deepest = 0
    for _, tal in ipairs(cls.trees[t].talents) do
        if tal.allowed and tal.row > deepest then deepest = tal.row end
    end
    return deepest
end

local function two_tree_choice(cls, thirds, held, spent, rand, rules)
    local main, side
    for t = 1, 3 do
        if thirds[t] == 2 then main = t elseif thirds[t] == 1 then side = t end
    end
    if not main or not side then return nil end
    local row = bottom_row(cls, main)
    local at_bottom = false
    for _, tal in ipairs(cls.trees[main].talents) do
        if tal.row == row and (held[tal.id] or 0) > 0 then at_bottom = true end
    end
    local side_mark = math.floor((row * 5 + 1) / 2)
    local side_done = spent[side] >= side_mark
    local main_room = has_room(cls, main, held, spent, rules)
    local side_room = has_room(cls, side, held, spent, rules)
    if at_bottom and side_done then return nil end
    local want
    if not at_bottom and not side_done then
        want = (rand(3) <= 2) and main or side
    elseif side_done then
        want = main
    else
        want = side
    end
    if want == main and not main_room then want = side_room and side or nil end
    if want == side and not side_room then want = main_room and main or nil end
    return want
end

local MAX_POINTS = 51
local EACH_GOAL  = math.floor(MAX_POINTS / 3)

local function thirds_choice(cls, thirds, held, spent, rand, rules)
    if not (thirds[1] == 1 and thirds[2] == 1 and thirds[3] == 1) then return nil end
    local short = {}
    for t = 1, 3 do
        if spent[t] < EACH_GOAL and has_room(cls, t, held, spent, rules) then short[#short + 1] = t end
    end
    if #short == 0 then return nil end
    return short[rand(#short)]
end

function Spender.plan(cls, shape_id, held, free, rand)
    local shape = cls.shapes[shape_id]
    if not shape then error("buddy-talent-spender: " .. cls.name .. " has no shape " .. tostring(shape_id)) end

    local h = {}
    for id, pts in pairs(held) do h[id] = pts end
    local spent = spent_per_tree(cls, h)
    local steps = {}

    for _ = 1, free do
        local t = two_tree_choice(cls, shape.thirds, h, spent, rand) or thirds_choice(cls, shape.thirds, h, spent, rand)
            or choose_tree(cls, shape.thirds, h, spent, rand)
        if not t then break end
        local tal = pick_in_tree(cls, t, h, spent, rand)
        h[tal.id] = (h[tal.id] or 0) + 1
        spent[t]  = spent[t] + 1
        steps[#steps + 1] = { id = tal.id, rank = h[tal.id] - 1, tree = t, name = tal.name }
    end
    return steps, free - #steps
end

local function resolve_build(cls, build)
    local ix, by_name = index_class(cls), {}
    for id, tal in pairs(ix.by_id) do by_name[tal.name] = by_name[tal.name] or tal; by_name[tal.name .. "#" .. ix.tree_of[id]] = tal end
    local function find(name)
        local tal = by_name[name]
        if not tal then error(("talent build %q: %s has no talent named %q"):format(build.name, cls.name, name)) end
        return tal
    end
    local rules = { forbid = {}, past_cap = build.past_cap and true or false }
    for _, name in ipairs(build.forbidden or {}) do rules.forbid[find(name).id] = true end
    local need = {}
    for _, name in ipairs(build.required or {}) do
        local tal = find(name)
        if rules.forbid[tal.id] then error(("talent build %q: %q is both required and forbidden"):format(build.name, name)) end
        if not tal.allowed and not rules.past_cap then
            error(("talent build %q: %q (row %d) is shut by basic's talent cap; the build would need past_cap"):format(build.name, name, tal.row + 1))
        end
        need[tal.id] = tal.ranks
        local dep, pts = tal.dep, tal.dep_points
        while dep ~= 0 do
            need[dep] = math.max(need[dep] or 0, pts)
            dep, pts = ix.by_id[dep].dep, ix.by_id[dep].dep_points
        end
    end
    return rules, need
end

function Spender.build_cost(cls, build)
    local ix          = index_class(cls)
    local _, need     = resolve_build(cls, build)
    local per_tree    = { 0, 0, 0 }
    for t = 1, 3 do
        local total, worst = 0, 0
        for id, pts in pairs(need) do if ix.tree_of[id] == t then total = total + pts end end
        for id in pairs(need) do
            if ix.tree_of[id] == t then
                local row, below = ix.by_id[id].row, 0
                for other, pts in pairs(need) do
                    if ix.tree_of[other] == t and ix.by_id[other].row >= row then below = below + pts end
                end
                worst = math.max(worst, row * 5 + below)
            end
        end
        per_tree[t] = math.max(total, worst)
    end
    return per_tree[1] + per_tree[2] + per_tree[3], per_tree
end

function Spender.plan_build(cls, build, held, free, rand)
    local ix          = index_class(cls)
    local rules, need = resolve_build(cls, build)
    local h           = {}
    local have        = free
    for id, pts in pairs(held) do h[id] = pts; have = have + pts end
    local cost = Spender.build_cost(cls, build)
    if cost > have then
        error(("talent build %q needs at least %d points for its required talents; the character has %d (%d short)"):format(
            build.name, cost, have, cost - have))
    end
    local spent = spent_per_tree(cls, h)
    local steps = {}
    for _ = 1, free do
        local now, short
        for id, pts in pairs(need) do
            local tal = ix.by_id[id]
            if (h[id] or 0) < pts then
                if not short or tal.row < short.row then short = tal end
                if legal(cls, tal, h, spent[ix.tree_of[id]], rules) then
                    if not now or ((h[id] or 0) > 0 and (h[now.id] or 0) == 0)
                       or (((h[id] or 0) > 0) == ((h[now.id] or 0) > 0) and (tal.row < now.row or (tal.row == now.row and tal.id < now.id))) then
                        now = tal
                    end
                end
            end
        end
        local t, tal
        if now then
            tal, t = now, ix.tree_of[now.id]
        elseif short then
            t   = ix.tree_of[short.id]
            tal = pick_in_tree(cls, t, h, spent, rand, rules)
        else
            t = two_tree_choice(cls, build.thirds, h, spent, rand, rules) or thirds_choice(cls, build.thirds, h, spent, rand, rules)
                or choose_tree(cls, build.thirds, h, spent, rand, rules)
            tal = t and pick_in_tree(cls, t, h, spent, rand, rules)
        end
        if not tal then break end
        h[tal.id] = (h[tal.id] or 0) + 1
        spent[t]  = spent[t] + 1
        steps[#steps + 1] = { id = tal.id, rank = h[tal.id] - 1, tree = t, name = tal.name }
    end
    local missing = {}
    for _, name in ipairs(build.required or {}) do
        for id, tal in pairs(ix.by_id) do
            if tal.name == name and (h[id] or 0) < tal.ranks then missing[#missing + 1] = name end
        end
    end
    return steps, free - #steps, missing
end

function Spender.draw_shape(cls, taken, need_role, rand)
    local free, fitting = {}, {}
    for id, shape in ipairs(cls.shapes) do
        if not taken[id] then
            free[#free + 1] = id
            if need_role and shape.role == need_role then fitting[#fitting + 1] = id end
        end
    end
    if #fitting > 0 then return fitting[rand(#fitting)], true end
    if #free    > 0 then return free[rand(#free)], false      end
    return nil, cls.name .. ": every talent shape is already held by a clan-mate of this class"
end

function Spender.can_fill(cls, role)
    for _, shape in ipairs(cls.shapes) do
        if shape.role == role then return true end
    end
    return false
end

return Spender
