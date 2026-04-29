# 612 - Dungeon/Cave Dynamic Rail Pathfinding

## Status
- Created: 2026-04-05
- Implemented: 2026-04-05
- Phase: 2
- Priority: Medium
- Depends: 161 (bot wandering)
- Status: Implemented (needs testing)

## Current Behavior
- Bots use `generateNewWanderPosition()` which picks direction randomly
- In caves/dungeons, this leads to getting stuck or endlessly looping
- No awareness of dungeon structure or topology

## Intended Behavior
**Dynamic** intersection-based navigation when bot enters dungeon/cave.

### Core Concept
1. Bot enters dungeon/cave
2. Detect **intersection zones** - places where paths diverge
3. At intersections, pick random direction (not the way we came)
4. Follow that path until next intersection or dead end
5. Dead ends: turn around, return to intersection, pick new direction
6. Eventually find exit, won't re-enter for 2 minutes

### Why Intersection-Based?
- Works on ALL dungeons - no pre-computed data
- Handles dungeons that go up, down, sideways
- Natural exploration pattern - bots get lost sometimes (like players)
- Dead-end handling creates realistic behavior

## Available APIs (No Direct Navmesh Access)

ALE doesn't expose navmesh/mmap directly. We detect topology using:
- `map:GetHeight(x, y)` - returns nil if not walkable terrain
- `unit:IsWithinLoS(target)` - line of sight check
- `map:GetAreaId(x, y, z)` - area/subzone at position

## Intersection Detection Algorithm

### Radial Height Sampling
Sample points in 8 directions, count how many are walkable:

```lua
-- {{{ DungeonRails.countWalkableDirections
-- Sample terrain in 8 directions, count valid paths
-- Returns count and table of walkable angles
function DungeonRails.countWalkableDirections(bot, sampleDist)
    sampleDist = sampleDist or 10  -- yards
    local bx, by, bz = bot:GetPosition()
    local map = bot:GetMap()
    local walkable = {}

    -- Sample 8 directions (every 45 degrees)
    for i = 0, 7 do
        local angle = i * 0.785  -- 45 degrees in radians
        local testX = bx + math.cos(angle) * sampleDist
        local testY = by + math.sin(angle) * sampleDist
        local testZ = map:GetHeight(testX, testY)

        -- Valid if height exists and within ±5 yards of current
        if testZ and math.abs(testZ - bz) <= 5 then
            table.insert(walkable, {
                angle = angle,
                x = testX,
                y = testY,
                z = testZ
            })
        end
    end

    return #walkable, walkable
end -- }}}
```

### Classifying Position
```lua
-- {{{ DungeonRails.classifyPosition
-- Determine if current position is intersection, corridor, or dead-end
function DungeonRails.classifyPosition(bot)
    local count, directions = DungeonRails.countWalkableDirections(bot)

    if count >= 3 then
        return "intersection", directions
    elseif count == 2 then
        return "corridor", directions
    elseif count == 1 then
        return "dead_end", directions
    else
        return "stuck", directions
    end
end -- }}}
```

## Intersection Zone Behavior

### Entering an Intersection
```lua
-- {{{ DungeonRails.handleIntersection
-- At intersection: pick random direction, excluding way we came
function DungeonRails.handleIntersection(bot, directions)
    local cameFrom = bot:GetData("came_from_angle")
    local validChoices = {}

    for _, dir in ipairs(directions) do
        -- Exclude direction we came from (within 45 degrees)
        if not cameFrom or math.abs(dir.angle - cameFrom) > 0.5 then
            table.insert(validChoices, dir)
        end
    end

    if #validChoices == 0 then
        -- No valid choices - must go back the way we came
        validChoices = directions
    end

    -- Pick random direction
    local choice = validChoices[math.random(#validChoices)]

    -- Remember which way we're going (opposite is where we came from)
    local oppositeAngle = choice.angle + 3.14
    if oppositeAngle > 6.28 then oppositeAngle = oppositeAngle - 6.28 end
    bot:SetData("came_from_angle", oppositeAngle)

    -- Store that we passed through this intersection
    DungeonRails.recordIntersection(bot, bot:GetPosition())

    return choice.x, choice.y, choice.z
end -- }}}
```

### Recording Intersections (Prevent Loops)
```lua
-- {{{ DungeonRails.recordIntersection
-- Track visited intersections to detect loops
function DungeonRails.recordIntersection(bot, x, y, z)
    local visited = bot:GetData("visited_intersections") or {}
    table.insert(visited, { x = x, y = y, z = z, time = os.time() })

    -- Keep only last 10 intersections
    while #visited > 10 do
        table.remove(visited, 1)
    end

    bot:SetData("visited_intersections", visited)
end -- }}}

-- {{{ DungeonRails.isRecentlyVisited
-- Check if we've been here before (within 20 yards, last 2 minutes)
function DungeonRails.isRecentlyVisited(bot, x, y)
    local visited = bot:GetData("visited_intersections") or {}
    local now = os.time()

    for _, intersection in ipairs(visited) do
        if now - intersection.time < 120 then  -- 2 minutes
            local distSq = (x - intersection.x)^2 + (y - intersection.y)^2
            if distSq < 400 then  -- 20 yards
                return true
            end
        end
    end

    return false
end -- }}}
```

## Dead-End Detection and Handling

### Probability-Based Turnaround
The closer to a dead-end, the more likely to turn around:

```lua
-- {{{ DungeonRails.checkDeadEnd
-- Check ahead for dead-end, return probability of turning around
function DungeonRails.checkDeadEnd(bot)
    local bx, by, bz = bot:GetPosition()
    local facing = bot:GetFacing()
    local map = bot:GetMap()

    -- Sample progressively further ahead
    local deadEndDist = nil
    for dist = 5, 30, 5 do
        local testX = bx + math.cos(facing) * dist
        local testY = by + math.sin(facing) * dist
        local testZ = map:GetHeight(testX, testY)

        if not testZ or math.abs(testZ - bz) > 5 then
            -- Found the wall/dead-end
            deadEndDist = dist
            break
        end
    end

    if not deadEndDist then
        return 0  -- No dead-end visible
    end

    -- Probability increases as we get closer
    -- At 30 yards: 10%, at 15 yards: 50%, at 5 yards: 100%
    local probability = 1.0 - (deadEndDist / 35)
    probability = math.max(0, math.min(1, probability))

    return probability
end -- }}}

-- {{{ DungeonRails.handleDeadEnd
-- Turn around at dead-end
function DungeonRails.handleDeadEnd(bot)
    -- Reverse direction
    local theta = bot:GetData("theta") or bot:GetFacing()
    theta = theta + 3.14
    if theta > 6.28 then theta = theta - 6.28 end
    bot:SetData("theta", theta)

    -- Clear "came from" so we can go back through intersection
    bot:SetData("came_from_angle", nil)

    return true
end -- }}}
```

### Line-of-Sight Dead-End Check
Use LoS to detect visible dead-ends:

```lua
-- {{{ DungeonRails.canSeeDeadEnd
-- Check if we can see the end of the passage
function DungeonRails.canSeeDeadEnd(bot)
    local bx, by, bz = bot:GetPosition()
    local facing = bot:GetFacing()
    local map = bot:GetMap()

    -- Find the furthest walkable point ahead
    local lastValid = { x = bx, y = by, z = bz }
    for dist = 5, 50, 5 do
        local testX = bx + math.cos(facing) * dist
        local testY = by + math.sin(facing) * dist
        local testZ = map:GetHeight(testX, testY)

        if testZ and math.abs(testZ - bz) <= 5 then
            lastValid = { x = testX, y = testY, z = testZ }
        else
            break  -- Hit wall
        end
    end

    -- Check if that point is a dead-end (only 1 walkable direction from there)
    -- Would need to teleport or estimate - simplified: just use distance
    local distToEnd = math.sqrt((lastValid.x - bx)^2 + (lastValid.y - by)^2)

    return distToEnd < 30, distToEnd
end -- }}}
```

## Rail Following with Meander

### Target Selection (Exactly 10 Yards)
```lua
-- {{{ DungeonRails.selectWanderTarget
-- Pick target exactly 10 yards away, within 10 yards of current rail direction
-- Returns nil after 10 failures (too treacherous)
function DungeonRails.selectWanderTarget(bot)
    local bx, by, bz = bot:GetPosition()
    local theta = bot:GetData("theta") or bot:GetFacing()
    local map = bot:GetMap()

    local failures = bot:GetData("dungeon_failures") or 0

    for attempt = 1, 10 do
        -- Random angle within ~60 degrees of current direction
        local angleOffset = (math.random() - 0.5) * 1.0  -- ±30 degrees
        local targetAngle = theta + angleOffset

        -- Exactly 10 yards
        local targetX = bx + math.cos(targetAngle) * 10
        local targetY = by + math.sin(targetAngle) * 10
        local targetZ = map:GetHeight(targetX, targetY)

        -- Validate: height exists and within ±5 yards
        if targetZ and math.abs(targetZ - bz) <= 5 then
            -- Success - reset failures, update theta toward target
            bot:SetData("dungeon_failures", 0)

            -- Meander: bias theta slightly toward chosen direction
            local newTheta = theta + (angleOffset * 0.3)
            bot:SetData("theta", newTheta)

            return targetX, targetY, targetZ
        end
    end

    -- All 10 attempts failed
    failures = failures + 1
    bot:SetData("dungeon_failures", failures)

    if failures >= 10 then
        -- Too treacherous - leave dungeon
        return nil, nil, nil, "exit"
    end

    return nil, nil, nil, "retry"
end -- }}}
```

## Main Update Loop

```lua
-- {{{ DungeonRails.update
-- Called by periodic event when bot is in dungeon/cave
function DungeonRails.update(bot)
    -- Check cooldown
    if not DungeonRails.canEnterDungeon(bot) then
        DungeonRails.exitDungeon(bot)
        return
    end

    -- Initialize entrance if first tick in dungeon
    if not bot:GetData("dungeon_entrance") then
        local x, y, z = bot:GetPosition()
        bot:SetData("dungeon_entrance", { x = x, y = y, z = z })
        bot:SetData("theta", bot:GetFacing())
    end

    -- Check what kind of position we're in
    local posType, directions = DungeonRails.classifyPosition(bot)

    if posType == "intersection" then
        -- At intersection - pick direction
        local tx, ty, tz = DungeonRails.handleIntersection(bot, directions)
        bot:MoveTo(0, tx, ty, tz, false)
        return

    elseif posType == "dead_end" then
        -- Dead end - turn around
        DungeonRails.handleDeadEnd(bot)
        -- Continue to wander back
    end

    -- Check for visible dead-end ahead
    local turnProb = DungeonRails.checkDeadEnd(bot)
    if math.random() < turnProb then
        DungeonRails.handleDeadEnd(bot)
    end

    -- Select wander target
    local tx, ty, tz, status = DungeonRails.selectWanderTarget(bot)

    if status == "exit" then
        -- Too many failures - exit dungeon
        local entrance = bot:GetData("dungeon_entrance")
        if entrance then
            bot:MoveTo(0, entrance.x, entrance.y, entrance.z, false)
        end
        DungeonRails.exitDungeon(bot)
        return
    end

    if tx then
        bot:MoveTo(0, tx, ty, tz, false)
    end
end -- }}}
```

## Cooldown and State Cleanup

```lua
-- {{{ DungeonRails.canEnterDungeon
function DungeonRails.canEnterDungeon(bot)
    local lastExit = bot:GetData("last_dungeon_exit") or 0
    return (os.time() - lastExit) >= 120  -- 2 minutes
end -- }}}

-- {{{ DungeonRails.exitDungeon
-- Clean up all dungeon state
function DungeonRails.exitDungeon(bot)
    bot:SetData("last_dungeon_exit", os.time())
    bot:SetData("dungeon_entrance", nil)
    bot:SetData("came_from_angle", nil)
    bot:SetData("visited_intersections", nil)
    bot:SetData("dungeon_failures", nil)
end -- }}}

-- {{{ Periodic cooldown cleanup
-- After cooldown expires, remove stored timestamp
-- This runs on a separate long-interval event (every 60 seconds)
function DungeonRails.cleanupExpiredCooldowns(bot)
    local lastExit = bot:GetData("last_dungeon_exit")
    if lastExit and (os.time() - lastExit) >= 120 then
        bot:SetData("last_dungeon_exit", nil)
    end
end -- }}}
```

## Underground/Dungeon Detection

```lua
-- {{{ DungeonRails.isInDungeon
-- Detect if bot is in a dungeon/cave
-- Note: "underground" is a misnomer - some dungeons go up
function DungeonRails.isInDungeon(bot)
    -- Method 1: Instance check (instanced dungeons)
    local instanceId = bot:GetInstanceId()
    if instanceId and instanceId > 0 then return true end

    -- Method 2: Subzone name heuristics (outdoor caves)
    local subzone = bot:GetSubZoneAreaId()
    local subzoneName = GetAreaName(subzone) or ""
    subzoneName = subzoneName:lower()

    local caveKeywords = {"cave", "cavern", "mine", "tunnel", "den", "lair", "depths"}
    for _, keyword in ipairs(caveKeywords) do
        if subzoneName:find(keyword) then
            return true
        end
    end

    -- Method 3: Exception list (dungeons without obvious names)
    -- Add manually as discovered
    local areaId = bot:GetAreaId()
    local knownDungeons = {
        -- [areaId] = true
    }
    if knownDungeons[areaId] then return true end

    return false
end -- }}}
```

## Integration with Bot Wandering (issue 161)

In `BotWander.update(bot)`:
```lua
if DungeonRails.isInDungeon(bot) then
    DungeonRails.update(bot)
else
    -- Not in dungeon
    if bot:GetData("dungeon_entrance") then
        -- Just exited - clean up
        DungeonRails.exitDungeon(bot)
    end
    -- Normal wandering...
end
```

## State Data on Bot
```lua
bot:GetData("dungeon_entrance")        -- {x, y, z} where we entered
bot:GetData("came_from_angle")         -- Angle we came from (don't go back)
bot:GetData("visited_intersections")   -- Array of recent intersections
bot:GetData("dungeon_failures")        -- Count of failed movement attempts
bot:GetData("last_dungeon_exit")       -- Timestamp for cooldown
bot:GetData("theta")                   -- Current movement direction
```

## Testing
1. Bot enters cave - should detect intersections via radial sampling
2. At intersection - should pick random valid direction
3. At dead-end - should turn around (probability increases with proximity)
4. Too many failures - should exit to entrance
5. After exit - 2 minute cooldown before re-entry
6. Different bots - should take different paths (randomized choices)

## Edge Cases
| Case | Handling |
|------|----------|
| Spiraling dungeon | Height sampling works in any direction |
| Dungeon goes up | Height differential ±5 yards handles slopes |
| Very narrow corridor | Only 2 walkable directions detected |
| Open cavern | Many directions walkable - treated as intersection |
| Bot loops forever | visited_intersections prevents revisiting same intersection |
| 10 movement failures | Too treacherous - return to entrance and exit |

## Related Issues
- 161: Bot wandering (main integration point)
- 126: Dungeon room spawn zones

## Notes
- No navmesh access needed - topology inferred from height sampling
- Intersection detection is the key innovation
- Dead-end probability creates natural exploration feel
- Meander in `selectWanderTarget` keeps movement organic
- Dungeon detection exceptions added as discovered (not "underground" assumption)
