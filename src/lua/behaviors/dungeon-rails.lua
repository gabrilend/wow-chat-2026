-- {{{ Everland Ghostsong - Dungeon/Cave Dynamic Rail Pathfinding
-- Intersection-based navigation when bot enters dungeon/cave
-- Uses radial height sampling to detect paths - no navmesh access needed
-- Dead-end probability increases with proximity
--
-- Issue: 162-dungeon-rail-pathfinding.md
-- Related: 161 (bot wandering main integration)
-- }}}

require("movement")

DungeonRails = {}

-- {{{ Configuration
DUNGEON_SAMPLE_DIST       = 10    -- yards to sample terrain
DUNGEON_HEIGHT_LIMIT      = 5     -- yards vertical tolerance
DUNGEON_MOVEMENT_DIST     = 10    -- exactly 10 yards per move
DUNGEON_MEANDER_RANGE     = 1.0   -- radians total (±0.5 from theta)
DUNGEON_MEANDER_BIAS      = 0.3   -- how much to bias theta toward chosen angle
DUNGEON_FAILURE_LIMIT     = 10    -- consecutive failures before exit
DUNGEON_COOLDOWN          = 120   -- seconds before re-entry
DUNGEON_DEAD_END_BASE     = 35    -- yards - probability scaling base
-- }}}

-- {{{ Cave/dungeon keyword patterns
local CAVE_KEYWORDS = {
    "cave", "cavern", "mine", "tunnel", "den", "lair", "depths",
    "hollow", "burrow", "pit", "grotto", "crypt", "tomb", "catacomb"
}
-- }}}

-- {{{ Known dungeon area IDs (exceptions without obvious names)
-- Add manually as discovered
local KNOWN_DUNGEONS = {
    -- [areaId] = true
}
-- }}}

-- {{{ DungeonRails.isInDungeon
-- Detect if bot is in a dungeon/cave
-- Method 1: Instance check (instanced dungeons)
-- Method 2: Subzone name heuristics (outdoor caves)
-- Method 3: Exception list
function DungeonRails.isInDungeon(bot)
    -- Method 1: Instance check
    local instanceId = bot:GetInstanceId()
    if instanceId and instanceId > 0 then
        return true
    end

    -- Method 2: Subzone name heuristics
    local subzoneId = bot:GetAreaId()
    local subzoneName = GetAreaName and GetAreaName(subzoneId) or ""
    if subzoneName then
        subzoneName = subzoneName:lower()
        for _, keyword in ipairs(CAVE_KEYWORDS) do
            if subzoneName:find(keyword) then
                return true
            end
        end
    end

    -- Method 3: Exception list
    if KNOWN_DUNGEONS[subzoneId] then
        return true
    end

    return false
end -- }}}

-- {{{ DungeonRails.canEnterDungeon
-- Check if cooldown has expired
function DungeonRails.canEnterDungeon(bot)
    local lastExit = bot:GetData("last_dungeon_exit") or 0
    return (os.time() - lastExit) >= DUNGEON_COOLDOWN
end -- }}}

-- {{{ DungeonRails.exitDungeon
-- Clean up all dungeon state and register one-shot cooldown cleanup
function DungeonRails.exitDungeon(bot)
    bot:SetData("last_dungeon_exit", os.time())
    bot:SetData("dungeon_entrance", nil)
    bot:SetData("came_from_angle", nil)
    bot:SetData("visited_intersections", nil)
    bot:SetData("dungeon_failures", nil)

    -- Register one-shot cleanup event (defined in periodic_events.lua)
    -- Delay IS the cooldown - fires once after 120s, cleans up, done
    if PeriodicDungeonCooldownCleanup then
        bot:RegisterEvent(PeriodicDungeonCooldownCleanup, DUNGEON_COOLDOWN * 1000, 1)
    end

    print("[DungeonRails] " .. bot:GetName() .. " exited dungeon, cooldown started")
end -- }}}

-- {{{ DungeonRails.cleanupExpiredCooldowns
-- DEPRECATED: Cleanup now handled by one-shot PeriodicDungeonCooldownCleanup
-- Kept for backwards compatibility but no longer called
function DungeonRails.cleanupExpiredCooldowns(bot)
    bot:SetData("last_dungeon_exit", nil)
end -- }}}

-- {{{ DungeonRails.countWalkableDirections
-- Sample terrain in 8 directions, count valid paths
-- Returns count and table of walkable directions
function DungeonRails.countWalkableDirections(bot, sampleDist)
    sampleDist = sampleDist or DUNGEON_SAMPLE_DIST
    local bx, by, bz = bot:GetPosition()
    local map = bot:GetMap()
    local walkable = {}

    -- Sample 8 directions (every 45 degrees = 0.785 radians)
    for i = 0, 7 do
        local angle = i * 0.785
        local testX = bx + math.cos(angle) * sampleDist
        local testY = by + math.sin(angle) * sampleDist
        local testZ = map:GetHeight(testX, testY)

        -- Valid if height exists and within tolerance
        if testZ and math.abs(testZ - bz) <= DUNGEON_HEIGHT_LIMIT then
            table.insert(walkable, {
                angle = angle,
                x     = testX,
                y     = testY,
                z     = testZ
            })
        end
    end

    return #walkable, walkable
end -- }}}

-- {{{ DungeonRails.classifyPosition
-- Determine if current position is intersection, corridor, or dead-end
-- Returns type string and directions table
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
-- Check if we've been at this intersection before (within 20 yards, last 2 minutes)
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

-- {{{ DungeonRails.handleIntersection
-- At intersection: pick random direction, excluding way we came
-- Returns destination x, y, z
function DungeonRails.handleIntersection(bot, directions)
    local cameFrom = bot:GetData("came_from_angle")
    local validChoices = {}

    for _, dir in ipairs(directions) do
        -- Exclude direction we came from (within 45 degrees = 0.785 radians)
        if not cameFrom or math.abs(dir.angle - cameFrom) > 0.5 then
            -- Also check if not recently visited
            if not DungeonRails.isRecentlyVisited(bot, dir.x, dir.y) then
                table.insert(validChoices, dir)
            end
        end
    end

    -- If all choices are recently visited, allow any direction except came_from
    if #validChoices == 0 then
        for _, dir in ipairs(directions) do
            if not cameFrom or math.abs(dir.angle - cameFrom) > 0.5 then
                table.insert(validChoices, dir)
            end
        end
    end

    -- Still no valid choices - must go back the way we came
    if #validChoices == 0 then
        validChoices = directions
    end

    -- Pick random direction
    local choice = validChoices[math.random(#validChoices)]

    -- Remember which way we're going (opposite is where we came from)
    local oppositeAngle = choice.angle + 3.14
    if oppositeAngle > 6.28 then oppositeAngle = oppositeAngle - 6.28 end
    bot:SetData("came_from_angle", oppositeAngle)

    -- Store that we passed through this intersection
    local bx, by, bz = bot:GetPosition()
    DungeonRails.recordIntersection(bot, bx, by, bz)

    -- Update theta for rail following
    bot:SetData("theta", choice.angle)

    print("[DungeonRails] " .. bot:GetName() .. " at intersection, chose angle " ..
          string.format("%.2f", choice.angle))

    return choice.x, choice.y, choice.z
end -- }}}

-- {{{ DungeonRails.checkDeadEnd
-- Check ahead for dead-end, return probability of turning around
-- Probability increases as we get closer
function DungeonRails.checkDeadEnd(bot)
    local bx, by, bz = bot:GetPosition()
    local facing = bot:GetData("theta") or bot:GetFacing()
    local map = bot:GetMap()

    -- Sample progressively further ahead
    local deadEndDist = nil
    for dist = 5, 30, 5 do
        local testX = bx + math.cos(facing) * dist
        local testY = by + math.sin(facing) * dist
        local testZ = map:GetHeight(testX, testY)

        if not testZ or math.abs(testZ - bz) > DUNGEON_HEIGHT_LIMIT then
            -- Found the wall/dead-end
            deadEndDist = dist
            break
        end
    end

    if not deadEndDist then
        return 0  -- No dead-end visible
    end

    -- Probability increases as we get closer
    -- At 30 yards: ~14%, at 15 yards: ~57%, at 5 yards: ~86%
    local probability = 1.0 - (deadEndDist / DUNGEON_DEAD_END_BASE)
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

    print("[DungeonRails] " .. bot:GetName() .. " turning around at dead-end")
    return true
end -- }}}

-- {{{ DungeonRails.selectWanderTarget
-- Pick target exactly 10 yards away, within meander range of current theta
-- Returns x, y, z, status on success; nil, nil, nil, "retry"/"exit" on failure
function DungeonRails.selectWanderTarget(bot)
    local bx, by, bz = bot:GetPosition()
    local theta = bot:GetData("theta") or bot:GetFacing()
    local map = bot:GetMap()

    local failures = bot:GetData("dungeon_failures") or 0

    for attempt = 1, 10 do
        -- Random angle within meander range (~60 degrees = ±0.5 radians)
        local angleOffset = (math.random() - 0.5) * DUNGEON_MEANDER_RANGE
        local targetAngle = theta + angleOffset

        -- Exactly 10 yards
        local targetX = bx + math.cos(targetAngle) * DUNGEON_MOVEMENT_DIST
        local targetY = by + math.sin(targetAngle) * DUNGEON_MOVEMENT_DIST
        local targetZ = map:GetHeight(targetX, targetY)

        -- Validate: height exists and within tolerance
        if targetZ and math.abs(targetZ - bz) <= DUNGEON_HEIGHT_LIMIT then
            -- Success - reset failures, update theta toward target
            bot:SetData("dungeon_failures", 0)

            -- Meander: bias theta slightly toward chosen direction
            local newTheta = theta + (angleOffset * DUNGEON_MEANDER_BIAS)
            bot:SetData("theta", newTheta)

            return targetX, targetY, targetZ, "ok"
        end
    end

    -- All 10 attempts failed
    failures = failures + 1
    bot:SetData("dungeon_failures", failures)

    if failures >= DUNGEON_FAILURE_LIMIT then
        -- Too treacherous - leave dungeon
        return nil, nil, nil, "exit"
    end

    return nil, nil, nil, "retry"
end -- }}}

-- {{{ Known cave/dungeon entrance locations (issue 165, 166)
-- Caves and dungeons that bots can seek out when in DUNGEON_DELVE mode
-- These need to be manually defined using point definition tools (issue 166)
-- Format: { mapId = { { x = ..., y = ..., z = ..., name = "..." }, ... } }
-- TODO: Populate via issue 166 point definition tools
local CAVE_DUNGEON_ENTRANCES = {
    -- Eastern Kingdoms (map 0)
    [0] = {
        { x = -8787, y = -2161, z =  136, name = "Deadmines" },
        { x = -5163, y = -819,  z =  495, name = "Gnomeregan" },
        { x = -230,  y = 1570,  z =  76,  name = "Shadowfang Keep" },
        -- TODO: Add caves (Fargodeep Mine, Jasperlode Mine, Echo Ridge Mine, etc.)
    },
    -- Kalimdor (map 1)
    [1] = {
        { x = -739,  y = -2213, z =  18,  name = "Ragefire Chasm" },
        { x = 4246,  y = 746,   z =  -23, name = "Wailing Caverns" },
        { x = -4470, y = -1679, z =  82,  name = "Razorfen Kraul" },
        -- TODO: Add caves (Skull Rock, Dreadmist Den, etc.)
    },
}
-- }}}

-- {{{ DungeonRails.findNearestEntrance
-- Find nearest cave/dungeon entrance on current map
-- Returns entrance table and distance, or nil
function DungeonRails.findNearestEntrance(bot)
    local mapId = bot:GetMapId()
    local entrances = CAVE_DUNGEON_ENTRANCES[mapId]
    if not entrances or #entrances == 0 then
        return nil
    end

    local bx, by = bot:GetPosition()
    local nearest = nil
    local nearestDistSq = math.huge

    for _, entrance in ipairs(entrances) do
        local dx = entrance.x - bx
        local dy = entrance.y - by
        local distSq = dx * dx + dy * dy

        if distSq < nearestDistSq then
            nearest = entrance
            nearestDistSq = distSq
        end
    end

    return nearest, math.sqrt(nearestDistSq)
end
-- }}}

-- {{{ DungeonRails.seekEntrance
-- Seek out nearest dungeon entrance when in DUNGEON_DELVE mode but not in dungeon
-- Returns true if actively seeking, false if no entrance found or arrived
function DungeonRails.seekEntrance(bot)
    -- Check cooldown first
    if not DungeonRails.canEnterDungeon(bot) then
        return false  -- On cooldown, fallback to wandering
    end

    local entrance, dist = DungeonRails.findNearestEntrance(bot)

    if not entrance then
        -- No known entrances on this map
        -- Future: could wander toward "cave" named areas
        return false
    end

    -- If within 50 yards, let normal dungeon detection kick in
    if dist < 50 then
        print("[DungeonRails] " .. bot:GetName() .. " near entrance " ..
              entrance.name .. ", letting detection take over")
        return false
    end

    -- Move toward dungeon entrance
    bot:SetWalk(true)
    bot:MoveTo(0, entrance.x, entrance.y, entrance.z, false)

    -- Update theta toward dungeon for consistent movement
    local bx, by = bot:GetPosition()
    local theta = math.atan2(entrance.y - by, entrance.x - bx)
    bot:SetData("theta", theta)

    print("[DungeonRails] " .. bot:GetName() .. " seeking " .. entrance.name ..
          " (" .. string.format("%.0f", dist) .. " yards)")
    return true
end
-- }}}

-- {{{ DungeonRails.update
-- Called by BotWander when bot is in dungeon/cave
function DungeonRails.update(bot)
    -- Check cooldown
    if not DungeonRails.canEnterDungeon(bot) then
        -- Still on cooldown - exit behavior will handle leaving
        return
    end

    -- Initialize entrance if first tick in dungeon
    if not bot:GetData("dungeon_entrance") then
        local x, y, z = bot:GetPosition()
        bot:SetData("dungeon_entrance", { x = x, y = y, z = z })
        bot:SetData("theta", bot:GetFacing())
        print("[DungeonRails] " .. bot:GetName() .. " entered dungeon at " ..
              string.format("%.0f, %.0f", x, y))
    end

    -- Check what kind of position we're in
    local posType, directions = DungeonRails.classifyPosition(bot)

    if posType == "intersection" then
        -- At intersection - pick direction
        local tx, ty, tz = DungeonRails.handleIntersection(bot, directions)
        bot:SetWalk(true)
        bot:MoveTo(0, tx, ty, tz, false)
        return

    elseif posType == "dead_end" then
        -- Dead end - turn around
        DungeonRails.handleDeadEnd(bot)
        -- Continue to wander back

    elseif posType == "stuck" then
        -- Completely stuck - try to exit
        local entrance = bot:GetData("dungeon_entrance")
        if entrance then
            bot:MoveTo(0, entrance.x, entrance.y, entrance.z, false)
        end
        DungeonRails.exitDungeon(bot)
        return
    end

    -- Check for visible dead-end ahead (probability-based turnaround)
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
            print("[DungeonRails] " .. bot:GetName() .. " exiting - too treacherous")
            bot:MoveTo(0, entrance.x, entrance.y, entrance.z, false)
        end
        DungeonRails.exitDungeon(bot)
        return
    end

    if tx then
        bot:SetWalk(true)
        bot:MoveTo(0, tx, ty, tz, false)
    end
end -- }}}

-- {{{ Module initialization
print("[DungeonRails] Behavior loaded - called by BotWander when in dungeon/cave")
-- }}}
