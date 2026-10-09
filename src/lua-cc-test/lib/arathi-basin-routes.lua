--------------------------------------------------------------------------------
-- arathi-basin-routes.lua (issue 176a2c) - where the next squad goes
--
-- For a general audience: each road crossing in Arathi Basin keeps, for
-- each side, a pointer naming the road the next squad of that side takes
-- from there toward the enemy's home. A squad takes the road the pointer
-- names, and the pointer turns to the next road, so the next squad goes
-- the other way (the owner, 2026-10-08: "it works like a flow chart where
-- you reverse the path each time you cross it"). Over a match the squads
-- spread evenly over the roads out of every crossing, and the same match
-- played twice sends the same squads the same way. This is the
-- rotor-router walk (the Propp machine): a fixed stand-in for choosing a
-- road at random.
--
-- A squad's choices at a crossing are every road there but the one it
-- arrived by (owner, 2026-10-08: ""forward" should mean "down the path"
-- and stand-ins should simply route along any of the routes that they did
-- not immediately just come from"), so the pointer is kept per road
-- arrived by. The map is, for now, the bot module's base-to-base roads; it
-- becomes the owner's crossings once those are recorded (176a2c). The roads are
-- the playerbots module's own (data/arathi-basin-roads.lua, written by
-- scripts/generate-arathi-basin-roads); the homes are named by place
-- ("north-west home", "south-east home"), since each match draws which
-- side starts where (176a2a).
--
-- Plain data and arithmetic: no creature, player or map is touched here,
-- so scripts/test-arathi-basin-rules runs it without a server.
--------------------------------------------------------------------------------

local Routes = {}

-- {{{ function Routes.graph
-- The roads as neighbours: graph[place] = list of { to, length }, each road
-- both ways, in a fixed order (by the neighbour's name).
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
-- }}}

-- {{{ function Routes.distances
-- Road distance from every place to `target` (shortest, by road length).
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
-- }}}

-- {{{ function Routes.new_match
-- A match's routing state. `homes` = { [side] = place }, for both sides
-- (sides are whatever the caller names them: "alliance", "horde"). Each
-- side has its own pointers: one per place per road arrived by, each
-- naming, of the roads there other than the one arrived by, the next to
-- take. A squad that appeared at a place arrived by no road ("") and may
-- take any. Every pointer starts at the first road in name order.
--
-- opts.route_end (176a2c question 7, both built):
--   "stop"     (default) a route ends on reaching the enemy's home
--   "walk on"  the enemy's home is one more place: the squad takes the
--              rule on from there, out by another road
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
-- }}}

-- {{{ function Routes.choices
-- The roads a squad at `place` that arrived from `came_from` (nil or "":
-- it appeared there) may take: every neighbour but the one it came from
-- (owner, 2026-10-08: "any of the routes that they did not immediately
-- just come from"). A dead end gives the way back, the only way on.
function Routes.choices(m, place, came_from)
    local out = {}
    for _, e in ipairs(m.g[place] or {}) do
        if e.to ~= came_from then out[#out + 1] = e.to end
    end
    if #out == 0 and came_from and came_from ~= "" then out[1] = came_from end
    return out
end
-- }}}

-- {{{ function Routes.next_place
-- The place a squad of `side` at `place`, arrived from `came_from`, goes
-- to next; the pointer for that arrival is turned for the squad after it.
function Routes.next_place(m, side, place, came_from)
    local choices = Routes.choices(m, place, came_from)
    if #choices == 0 then return nil end
    local key = place .. "<" .. (came_from or "")
    local i = m.pointer[side][key] or 1
    m.pointer[side][key] = i % #choices + 1          -- the next squad arriving this way takes the next road
    return choices[i]
end
-- }}}

-- {{{ function Routes.walk
-- One squad of `side`'s route from `start` (default its home), arrived
-- from `came_from` (default: appeared there), for at most `steps` places,
-- ending early at the enemy's home. Turns every pointer it passes. A real
-- squad stops sooner, at a base to capture or guard (176a2b); this is the
-- road it would follow.
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
-- }}}

return Routes
