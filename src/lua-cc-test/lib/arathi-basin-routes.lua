--------------------------------------------------------------------------------
-- arathi-basin-routes.lua (issue 176a2c) - where the next squad goes
--
-- For a general audience: each road crossing in Arathi Basin keeps, for
-- each side, a pointer naming the road the next squad of that side takes
-- from there toward the enemy's home. A squad takes the road the pointer
-- names, and the pointer turns to the next road, so the next squad goes
-- the other way (the owner, 2026-10-08: "it works like a flow chart where
-- you reverse the path each time you cross it"). Over a match the squads
-- spread evenly over every road toward the enemy, and the same match
-- played twice sends the same squads the same way. This is the
-- rotor-router walk (the Propp machine): a fixed stand-in for choosing a
-- road at random.
--
-- Only roads that bring a squad nearer the enemy's home, by road
-- distance, count as choices, so a squad never turns back. The roads are
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
-- (sides are whatever the caller names them: "alliance", "horde"). Every
-- pointer starts at the first road in name order; each side has its own.
function Routes.new_match(g, homes)
    local m = { g = g, homes = homes, pointer = {}, toward = {}, choices = {} }
    for side, home in pairs(homes) do
        local enemy_home
        for other, h in pairs(homes) do if other ~= side then enemy_home = h end end
        assert(enemy_home, "Routes.new_match: two sides with two homes are needed")
        local dist = Routes.distances(g, enemy_home)
        m.toward[side], m.pointer[side], m.choices[side] = enemy_home, {}, {}
        for place, edges in pairs(g) do
            -- the roads from here that bring the squad nearer the enemy's home
            local forward = {}
            for _, e in ipairs(edges) do
                if dist[e.to] and dist[place] and dist[e.to] < dist[place] then forward[#forward + 1] = e.to end
            end
            m.choices[side][place] = forward
            m.pointer[side][place] = 1
        end
    end
    return m
end
-- }}}

-- {{{ function Routes.next_place
-- The place a squad of `side` standing at `place` goes to next, and the
-- pointer turned for the squad after it. nil at the enemy's home (nowhere
-- nearer to go).
function Routes.next_place(m, side, place)
    local forward = m.choices[side][place]
    if not forward or #forward == 0 then return nil end
    local i = m.pointer[side][place]
    m.pointer[side][place] = i % #forward + 1        -- the next squad takes the next road
    return forward[i]
end
-- }}}

-- {{{ function Routes.walk
-- A whole route for one squad of `side`: its home, then each place it
-- reaches, to the enemy's home. Turns every pointer it passes.
function Routes.walk(m, side)
    local route = { m.homes[side] }
    local at = m.homes[side]
    for _ = 1, 32 do                                  -- a route can't be longer than the places; 32 is far past that
        local nxt = Routes.next_place(m, side, at)
        if not nxt then break end
        route[#route + 1] = nxt
        at = nxt
    end
    return route
end
-- }}}

return Routes
