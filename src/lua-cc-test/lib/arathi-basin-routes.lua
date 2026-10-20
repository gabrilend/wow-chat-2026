
local Routes = {}

function Routes.graph(roads)
    local g = {}
    local function link(a, b, len)
        g[a] = g[a] or {}
        table.insert(g[a], { to = b, length = len })
    end
    for _, r in ipairs(roads) do
        link(r.from, r.to, r.length)
        link(r.to, r.from, r.length)
    end
    for _, list in pairs(g) do table.sort(list, function(x, y) return x.to < y.to end) end
    return g
end

function Routes.distances(g, target)
    local dist, done = { [target] = 0 }, {}
    while true do
        local best, bestd = nil, math.huge
        for place, d in pairs(dist) do
            if not done[place] and d < bestd then best, bestd = place, d end
        end
        if not best then break end
        done[best] = true
        for _, edge in ipairs(g[best] or {}) do
            local nd = bestd + edge.length
            if not dist[edge.to] or nd < dist[edge.to] then dist[edge.to] = nd end
        end
    end
    return dist
end

function Routes.new_match(g, homes, opts)
    opts = opts or {}
    local route_end = opts.route_end or "stop"
    assert(route_end == "stop" or route_end == "walk on", "Routes.new_match: route_end is \"stop\" or \"walk on\"")
    local m = { g = g, homes = homes, pointer = {}, toward = {}, route_end = route_end }
    for side, home in pairs(homes) do
        for other, h in pairs(homes) do if other ~= side then m.toward[side] = h end end
        assert(m.toward[side], "Routes.new_match: two sides with two homes are needed")
        m.pointer[side] = {}
    end
    return m
end

function Routes.choices(m, place, came_from)
    local out = {}
    for _, e in ipairs(m.g[place] or {}) do
        if e.to ~= came_from then out[#out + 1] = e.to end
    end
    if #out == 0 and came_from and came_from ~= "" then out[1] = came_from end
    return out
end

function Routes.next_place(m, side, place, came_from)
    local choices = Routes.choices(m, place, came_from)
    if #choices == 0 then return nil end
    local key = place .. "<" .. (came_from or "")
    local i = m.pointer[side][key] or 1
    m.pointer[side][key] = i % #choices + 1
    return choices[i]
end

function Routes.walk(m, side, start, came_from, steps)
    local at, from = start or m.homes[side], came_from or ""
    local route = { at }
    for _ = 1, steps or 12 do
        if m.route_end == "stop" and at == m.toward[side] and #route > 1 then break end
        local nxt = Routes.next_place(m, side, at, from)
        if not nxt then break end
        route[#route + 1] = nxt
        from, at = at, nxt
    end
    return route
end

return Routes
