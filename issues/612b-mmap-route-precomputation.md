# 612b - MMap Route Precomputation with Relaxation

**Merge-Oriented:** Complements/replaces issue 162 (reactive intersection sampling).
Where 162 samples terrain as the bot moves, this precomputes a full route using mmap data.

## Current Behavior

- Bots use reactive pathfinding (issue 162) - sample walkable directions as they go
- No precomputed route through dungeon
- No awareness of "interesting" areas or coverage
- No mmap-level route optimization

## Intended Behavior

Precompute a dungeon route using A* on mmap tiles, then relax the path into smooth curves
that pass through interesting areas. Bot follows the route until dead-end or loop back to entrance.

### Core Algorithm

1. **Initial A* Path**
   - Chart shortest path from entrance to deepest reachable point
   - Operate on mmap tiles (hex grid ideal, square grid acceptable)
   - Apply randomized avoidance weights to each tile
   - More players nearby = lower avoidance weights (easier navigation)

2. **Path Relaxation**
   - Each line segment directed toward center aperture of local trajectory
   - "Center aperture" = average direction of surrounding path segments
   - Iterate relaxation until changes fall below threshold (convergence)
   - Like quick-and-dirty LLM training with few nodes - gradient descent on path smoothness

3. **Coverage Goal**
   - Route should pass through "interesting" parts of dungeon
   - If multiple paths exist, take one (commit to a direction)
   - Continue until dead-end OR loop back to entrance
   - Dead-end: reverse and follow route back out

### Route Behavior

```
Entrance ──────┐
               │
       ┌───────┴───────┐
       │               │
    Room A          Room B
       │               │
       └───────┬───────┘
               │
          Dead End
               │
          (reverse)
               │
       ┌───────┴───────┐
       │               │
    Room A          Room B   <-- may take different path on return
       │               │
       └───────┬───────┘
               │
            Entrance ──── (done, or loop detected = done)
```

## Player Proximity Effect

```lua
-- {{{ calculateTileAvoidance
-- More players nearby = lower avoidance = easier path
-- Simulates "well-trodden" paths and social navigation
function calculateTileAvoidance(tileX, tileY, playerPositions)
    local baseAvoidance = math.random() * 0.5 + 0.5  -- 0.5 to 1.0

    local nearbyPlayers = 0
    for _, pos in ipairs(playerPositions) do
        local dist = math.sqrt((tileX - pos.x)^2 + (tileY - pos.y)^2)
        if dist < 50 then  -- 50 yard influence radius
            nearbyPlayers = nearbyPlayers + 1
        end
    end

    -- Each nearby player reduces avoidance by 20%
    local reduction = nearbyPlayers * 0.2
    return math.max(0.1, baseAvoidance - reduction)
end -- }}}
```

## A* with Weighted Tiles

```lua
-- {{{ MMapRoute.computeInitialPath
-- A* pathfinding on mmap with randomized tile weights
-- Returns ordered list of waypoints from entrance to target
function MMapRoute.computeInitialPath(mapId, startX, startY, startZ, avoidanceGrid)
    local openSet   = PriorityQueue.new()
    local cameFrom  = {}
    local gScore    = {}  -- cost from start
    local fScore    = {}  -- gScore + heuristic

    local startKey  = tileKey(startX, startY)
    gScore[startKey] = 0
    fScore[startKey] = 0  -- heuristic starts at 0 (explore outward)

    openSet:push(startKey, 0)

    local deepestPoint = { x = startX, y = startY, z = startZ, depth = 0 }

    while not openSet:isEmpty() do
        local currentKey = openSet:pop()
        local cx, cy     = keyToTile(currentKey)
        local cz         = getHeight(mapId, cx, cy)

        -- Track deepest reachable point (furthest from start)
        local distFromStart = math.sqrt((cx - startX)^2 + (cy - startY)^2)
        if distFromStart > deepestPoint.depth then
            deepestPoint = { x = cx, y = cy, z = cz, depth = distFromStart }
        end

        -- Explore neighbors (8 directions for square, 6 for hex)
        for _, neighbor in ipairs(getNeighbors(cx, cy)) do
            local nx, ny = neighbor.x, neighbor.y
            local nz     = getHeight(mapId, nx, ny)

            -- Skip unwalkable tiles
            if not nz or math.abs(nz - cz) > 5 then
                goto continue
            end

            local neighborKey = tileKey(nx, ny)
            local moveCost    = avoidanceGrid[neighborKey] or 1.0
            local tentativeG  = gScore[currentKey] + moveCost

            if not gScore[neighborKey] or tentativeG < gScore[neighborKey] then
                cameFrom[neighborKey]  = currentKey
                gScore[neighborKey]    = tentativeG
                fScore[neighborKey]    = tentativeG  -- no target heuristic - explore all

                if not openSet:contains(neighborKey) then
                    openSet:push(neighborKey, fScore[neighborKey])
                end
            end

            ::continue::
        end
    end

    -- Reconstruct path to deepest point
    return reconstructPath(cameFrom, startKey, tileKey(deepestPoint.x, deepestPoint.y))
end -- }}}
```

## Path Relaxation (Gradient Descent on Smoothness)

```lua
-- {{{ MMapRoute.relaxPath
-- Iteratively adjust each waypoint toward center aperture of local trajectory
-- Converges when max delta falls below threshold
function MMapRoute.relaxPath(path, maxIterations, threshold)
    maxIterations = maxIterations or 20
    threshold     = threshold or 0.5  -- yards

    for iteration = 1, maxIterations do
        local maxDelta = 0

        for i = 2, #path - 1 do  -- don't move endpoints
            local prev = path[i - 1]
            local curr = path[i]
            local next = path[i + 1]

            -- Calculate center aperture: average direction from neighbors
            -- "Aperture" = the opening/direction the path is flowing through
            local inAngle   = math.atan2(curr.y - prev.y, curr.x - prev.x)
            local outAngle  = math.atan2(next.y - curr.y, next.x - curr.x)
            local avgAngle  = (inAngle + outAngle) / 2

            -- Adjust toward the direction of flow
            -- Pull point toward the line between prev and next
            local midX = (prev.x + next.x) / 2
            local midY = (prev.y + next.y) / 2

            -- Blend: 30% toward midpoint, 70% stay
            local newX = curr.x * 0.7 + midX * 0.3
            local newY = curr.y * 0.7 + midY * 0.3

            local delta = math.sqrt((newX - curr.x)^2 + (newY - curr.y)^2)
            maxDelta    = math.max(maxDelta, delta)

            path[i].x = newX
            path[i].y = newY
        end

        -- Converged?
        if maxDelta < threshold then
            return path, iteration
        end
    end

    return path, maxIterations
end -- }}}
```

## Route State Machine

```lua
-- {{{ MMapRoute states
local ROUTE_STATE = {
    COMPUTING     = 1,  -- A* running
    RELAXING      = 2,  -- path smoothing
    FOLLOWING     = 3,  -- bot moving along route
    REVERSING     = 4,  -- hit dead-end, going back
    COMPLETE      = 5,  -- returned to entrance or looped
}
-- }}}

-- {{{ MMapRoute.update
function MMapRoute.update(bot)
    local state = bot:GetData("route_state") or ROUTE_STATE.COMPUTING

    if state == ROUTE_STATE.COMPUTING then
        -- Compute initial A* path (may take multiple ticks for large dungeons)
        local path = MMapRoute.computeOrContinue(bot)
        if path then
            bot:SetData("route_path", path)
            bot:SetData("route_index", 1)
            bot:SetData("route_state", ROUTE_STATE.RELAXING)
        end

    elseif state == ROUTE_STATE.RELAXING then
        -- Relax path (single pass per tick, or all at once for small paths)
        local path = bot:GetData("route_path")
        local relaxed, iterations = MMapRoute.relaxPath(path, 5, 0.5)
        bot:SetData("route_path", relaxed)

        if iterations < 5 then  -- converged early
            bot:SetData("route_state", ROUTE_STATE.FOLLOWING)
        else
            -- Continue relaxing next tick
            -- (or just move to FOLLOWING if good enough)
            bot:SetData("route_state", ROUTE_STATE.FOLLOWING)
        end

    elseif state == ROUTE_STATE.FOLLOWING then
        local path  = bot:GetData("route_path")
        local index = bot:GetData("route_index")

        if index > #path then
            -- Reached end (dead-end or deepest point)
            bot:SetData("route_state", ROUTE_STATE.REVERSING)
            bot:SetData("route_index", #path)
            return
        end

        local waypoint = path[index]
        local bx, by   = bot:GetPosition()
        local dist     = math.sqrt((bx - waypoint.x)^2 + (by - waypoint.y)^2)

        if dist < 3 then
            -- Reached waypoint, advance
            bot:SetData("route_index", index + 1)
        else
            -- Move toward waypoint
            bot:MoveTo(0, waypoint.x, waypoint.y, waypoint.z, false)
        end

    elseif state == ROUTE_STATE.REVERSING then
        local path  = bot:GetData("route_path")
        local index = bot:GetData("route_index")

        if index < 1 then
            -- Back at entrance
            bot:SetData("route_state", ROUTE_STATE.COMPLETE)
            MMapRoute.cleanup(bot)
            return
        end

        local waypoint = path[index]
        local bx, by   = bot:GetPosition()
        local dist     = math.sqrt((bx - waypoint.x)^2 + (by - waypoint.y)^2)

        if dist < 3 then
            -- Reached waypoint, go to previous
            bot:SetData("route_index", index - 1)
        else
            bot:MoveTo(0, waypoint.x, waypoint.y, waypoint.z, false)
        end

    elseif state == ROUTE_STATE.COMPLETE then
        -- Done - can exit or wait for reset
        MMapRoute.cleanup(bot)
    end
end -- }}}
```

## Loop Detection

```lua
-- {{{ MMapRoute.detectLoop
-- If we return to entrance area while following (not reversing), we've looped
-- This is a valid completion state
function MMapRoute.detectLoop(bot)
    local entrance = bot:GetData("route_entrance")
    local state    = bot:GetData("route_state")

    if state ~= ROUTE_STATE.FOLLOWING then
        return false
    end

    local bx, by = bot:GetPosition()
    local dist   = math.sqrt((bx - entrance.x)^2 + (by - entrance.y)^2)

    -- Must have traveled some distance first (not immediate entrance)
    local index = bot:GetData("route_index") or 1
    if index > 5 and dist < 10 then
        return true  -- looped back to entrance
    end

    return false
end -- }}}
```

## Hex Grid (Ideal) vs Square Grid

```lua
-- {{{ Grid neighbor functions
-- Hex grid provides 6 equidistant neighbors - smoother paths
-- Square grid provides 8 neighbors - diagonal movement allowed

function getNeighborsHex(x, y)
    -- Axial coordinates for hex grid
    local directions = {
        { 1,  0}, { 1, -1}, { 0, -1},
        {-1,  0}, {-1,  1}, { 0,  1},
    }
    local neighbors = {}
    for _, d in ipairs(directions) do
        table.insert(neighbors, { x = x + d[1], y = y + d[2] })
    end
    return neighbors
end

function getNeighborsSquare(x, y)
    local directions = {
        {-1, -1}, { 0, -1}, { 1, -1},
        {-1,  0},           { 1,  0},
        {-1,  1}, { 0,  1}, { 1,  1},
    }
    local neighbors = {}
    for _, d in ipairs(directions) do
        table.insert(neighbors, { x = x + d[1], y = y + d[2] })
    end
    return neighbors
end
-- }}}
```

## Merge Strategy with Issue 162

**Option A: Replace entirely**
- Use precomputed routes instead of reactive sampling
- Pro: smoother paths, better coverage
- Con: requires mmap access, upfront computation

**Option B: Hybrid (recommended)**
- Precompute route if mmap available
- Fall back to 162's reactive sampling if not
- Use 162's intersection detection to validate precomputed route

**Option C: Layer on top**
- Precomputed route provides "macro" navigation (which direction overall)
- 162's sampling provides "micro" navigation (actual movement)
- Route says "go toward Room B", sampling figures out how

```lua
-- {{{ Hybrid integration
function DungeonNav.update(bot)
    if MMapRoute.isAvailable() then
        -- Use precomputed route for direction
        local nextWaypoint = MMapRoute.getNextWaypoint(bot)

        -- Use reactive sampling for actual movement toward waypoint
        DungeonRails.setTarget(bot, nextWaypoint.x, nextWaypoint.y, nextWaypoint.z)
        DungeonRails.update(bot)
    else
        -- Fall back to pure reactive
        DungeonRails.update(bot)
    end
end -- }}}
```

## MMap Access Requirement

**BLOCKED:** ALE does not currently expose mmap/navmesh data directly.

Options:
1. **Patch ALE** - Add `map:GetMMapTile(x, y)` API (see docs/patches/)
2. **Pre-export** - Export mmap to Lua tables offline, load at runtime
3. **Height sampling proxy** - Use `map:GetHeight()` as poor-man's mmap
   - Same approach as 162, but precompute the full path upfront
   - Sample in a flood-fill pattern, build graph, then A*

### Height Sampling as MMap Proxy

```lua
-- {{{ buildWalkableGraph
-- Flood-fill from entrance using height sampling
-- Returns graph of walkable tiles for A*
function buildWalkableGraph(mapId, startX, startY, startZ, maxTiles)
    maxTiles = maxTiles or 10000

    local graph   = {}
    local queue   = { { x = startX, y = startY, z = startZ } }
    local visited = {}
    local tileSize = 2  -- sample every 2 yards

    while #queue > 0 and tableSize(graph) < maxTiles do
        local current = table.remove(queue, 1)
        local key     = tileKey(current.x, current.y)

        if visited[key] then
            goto continue
        end
        visited[key] = true

        -- Add to graph
        graph[key] = {
            x = current.x,
            y = current.y,
            z = current.z,
            neighbors = {}
        }

        -- Check neighbors
        for _, offset in ipairs(getNeighborOffsets(tileSize)) do
            local nx = current.x + offset.x
            local ny = current.y + offset.y
            local nz = getHeight(mapId, nx, ny)

            if nz and math.abs(nz - current.z) <= 5 then
                local nkey = tileKey(nx, ny)
                table.insert(graph[key].neighbors, nkey)

                if not visited[nkey] then
                    table.insert(queue, { x = nx, y = ny, z = nz })
                end
            end
        end

        ::continue::
    end

    return graph
end -- }}}
```

## Configuration

```lua
MMAP_ROUTE_TILE_SIZE      = 2       -- yards per tile (sampling resolution)
MMAP_ROUTE_MAX_TILES      = 10000   -- max tiles to sample (memory limit)
MMAP_ROUTE_RELAX_ITER     = 20      -- max relaxation iterations
MMAP_ROUTE_RELAX_THRESH   = 0.5     -- convergence threshold (yards)
MMAP_ROUTE_WAYPOINT_DIST  = 3       -- yards to consider waypoint reached
MMAP_ROUTE_PLAYER_RADIUS  = 50      -- yards for player proximity effect
MMAP_ROUTE_PLAYER_REDUCE  = 0.2     -- avoidance reduction per nearby player
```

## Testing

1. Bot enters dungeon - should compute route via flood-fill sampling
2. Path relaxation - should smooth jagged A* path
3. Following route - bot moves through waypoints in order
4. Dead-end reached - bot reverses, follows path back
5. Loop detected - bot completed route, exits cleanly
6. Multiple players - paths should favor areas near players
7. Compare to 162 - precomputed should be smoother but similar coverage

## Related Issues

- 162: Dungeon rail pathfinding (reactive approach - merge target)
- 126: Dungeon room spawn zones (room detection)
- 161: Bot wandering (integration point)
- 166: Point-line definition tools (visualization)

## Stats

- **Phase:** 3
- **Priority:** Medium
- **Complexity:** High (A*, relaxation, state machine)
- **Dependencies:** mmap access OR height sampling proxy
- **Merge Target:** Issue 162

## Notes

- "Quick-and-dirty LLM training" = gradient descent with few parameters
- Relaxation is like training a spline to fit the data
- Player proximity creates emergent "well-trodden paths"
- Hex grid preferred for smoother 60-degree turns
- If mmap unavailable, height sampling flood-fill achieves similar result
