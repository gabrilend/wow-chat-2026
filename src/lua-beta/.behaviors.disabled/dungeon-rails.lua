
require("movement")

DungeonRails = {}

package.loaded["behaviors/dungeon-rails"] = DungeonRails

DUNGEON_SAMPLE_DIST       = 10
DUNGEON_HEIGHT_LIMIT      = 5
DUNGEON_MOVEMENT_DIST     = 10
DUNGEON_MEANDER_RANGE     = 1.0
DUNGEON_MEANDER_BIAS      = 0.3
DUNGEON_FAILURE_LIMIT     = 10
DUNGEON_COOLDOWN          = 120
DUNGEON_DEAD_END_BASE     = 35

local CAVE_KEYWORDS = {
    "cave", "cavern", "mine", "tunnel", "den", "lair", "depths",
    "hollow", "burrow", "pit", "grotto", "crypt", "tomb", "catacomb"
}

local KNOWN_DUNGEONS = {
}

function DungeonRails.isInDungeon(bot)
    local instanceId = bot:GetInstanceId()
    if instanceId and instanceId > 0 then
        return true
    end

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

    if KNOWN_DUNGEONS[subzoneId] then
        return true
    end

    return false
end

function DungeonRails.canEnterDungeon(bot)
    local lastExit = bot:GetData("last_dungeon_exit") or 0
    return (os.time() - lastExit) >= DUNGEON_COOLDOWN
end

function DungeonRails.exitDungeon(bot)
    bot:SetData("last_dungeon_exit", os.time())
    bot:SetData("dungeon_entrance", nil)
    bot:SetData("came_from_angle", nil)
    bot:SetData("visited_intersections", nil)
    bot:SetData("dungeon_failures", nil)

    if PeriodicDungeonCooldownCleanup then
        bot:RegisterEvent(PeriodicDungeonCooldownCleanup, DUNGEON_COOLDOWN * 1000, 1)
    end

    print("[DungeonRails] " .. bot:GetName() .. " exited dungeon, cooldown started")
end

function DungeonRails.cleanupExpiredCooldowns(bot)
    bot:SetData("last_dungeon_exit", nil)
end

function DungeonRails.countWalkableDirections(bot, sampleDist)
    sampleDist = sampleDist or DUNGEON_SAMPLE_DIST
    local bx, by, bz = bot:GetLocation()
    local map = bot:GetMap()
    local walkable = {}

    for i = 0, 7 do
        local angle = i * 0.785
        local testX = bx + math.cos(angle) * sampleDist
        local testY = by + math.sin(angle) * sampleDist
        local testZ = map:GetHeight(testX, testY)

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
end

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
end

function DungeonRails.recordIntersection(bot, x, y, z)
    local visited = bot:GetData("visited_intersections") or {}
    table.insert(visited, { x = x, y = y, z = z, time = os.time() })

    while #visited > 10 do
        table.remove(visited, 1)
    end

    bot:SetData("visited_intersections", visited)
end

function DungeonRails.isRecentlyVisited(bot, x, y)
    local visited = bot:GetData("visited_intersections") or {}
    local now = os.time()

    for _, intersection in ipairs(visited) do
        if now - intersection.time < 120 then
            local distSq = (x - intersection.x)^2 + (y - intersection.y)^2
            if distSq < 400 then
                return true
            end
        end
    end

    return false
end

function DungeonRails.handleIntersection(bot, directions)
    local cameFrom = bot:GetData("came_from_angle")
    local validChoices = {}

    for _, dir in ipairs(directions) do
        if not cameFrom or math.abs(dir.angle - cameFrom) > 0.5 then
            if not DungeonRails.isRecentlyVisited(bot, dir.x, dir.y) then
                table.insert(validChoices, dir)
            end
        end
    end

    if #validChoices == 0 then
        for _, dir in ipairs(directions) do
            if not cameFrom or math.abs(dir.angle - cameFrom) > 0.5 then
                table.insert(validChoices, dir)
            end
        end
    end

    if #validChoices == 0 then
        validChoices = directions
    end

    local choice = validChoices[math.random(#validChoices)]

    local oppositeAngle = choice.angle + 3.14
    if oppositeAngle > 6.28 then oppositeAngle = oppositeAngle - 6.28 end
    bot:SetData("came_from_angle", oppositeAngle)

    local bx, by, bz = bot:GetLocation()
    DungeonRails.recordIntersection(bot, bx, by, bz)

    bot:SetData("theta", choice.angle)

    print("[DungeonRails] " .. bot:GetName() .. " at intersection, chose angle " ..
          string.format("%.2f", choice.angle))

    return choice.x, choice.y, choice.z
end

function DungeonRails.checkDeadEnd(bot)
    local bx, by, bz = bot:GetLocation()
    local facing = bot:GetData("theta") or bot:GetO()
    local map = bot:GetMap()

    local deadEndDist = nil
    for dist = 5, 30, 5 do
        local testX = bx + math.cos(facing) * dist
        local testY = by + math.sin(facing) * dist
        local testZ = map:GetHeight(testX, testY)

        if not testZ or math.abs(testZ - bz) > DUNGEON_HEIGHT_LIMIT then
            deadEndDist = dist
            break
        end
    end

    if not deadEndDist then
        return 0
    end

    local probability = 1.0 - (deadEndDist / DUNGEON_DEAD_END_BASE)
    probability = math.max(0, math.min(1, probability))

    return probability
end

function DungeonRails.handleDeadEnd(bot)
    local theta = bot:GetData("theta") or bot:GetO()
    theta = theta + 3.14
    if theta > 6.28 then theta = theta - 6.28 end
    bot:SetData("theta", theta)

    bot:SetData("came_from_angle", nil)

    print("[DungeonRails] " .. bot:GetName() .. " turning around at dead-end")
    return true
end

function DungeonRails.selectWanderTarget(bot)
    local bx, by, bz = bot:GetLocation()
    local theta = bot:GetData("theta") or bot:GetO()
    local map = bot:GetMap()

    local failures = bot:GetData("dungeon_failures") or 0

    for attempt = 1, 10 do
        local angleOffset = (math.random() - 0.5) * DUNGEON_MEANDER_RANGE
        local targetAngle = theta + angleOffset

        local targetX = bx + math.cos(targetAngle) * DUNGEON_MOVEMENT_DIST
        local targetY = by + math.sin(targetAngle) * DUNGEON_MOVEMENT_DIST
        local targetZ = map:GetHeight(targetX, targetY)

        if targetZ and math.abs(targetZ - bz) <= DUNGEON_HEIGHT_LIMIT then
            bot:SetData("dungeon_failures", 0)

            local newTheta = theta + (angleOffset * DUNGEON_MEANDER_BIAS)
            bot:SetData("theta", newTheta)

            return targetX, targetY, targetZ, "ok"
        end
    end

    failures = failures + 1
    bot:SetData("dungeon_failures", failures)

    if failures >= DUNGEON_FAILURE_LIMIT then
        return nil, nil, nil, "exit"
    end

    return nil, nil, nil, "retry"
end

local CAVE_DUNGEON_ENTRANCES = {
    [0] = {
        { x = -8787, y = -2161, z =  136, name = "Deadmines" },
        { x = -5163, y = -819,  z =  495, name = "Gnomeregan" },
        { x = -230,  y = 1570,  z =  76,  name = "Shadowfang Keep" },
    },
    [1] = {
        { x = -739,  y = -2213, z =  18,  name = "Ragefire Chasm" },
        { x = 4246,  y = 746,   z =  -23, name = "Wailing Caverns" },
        { x = -4470, y = -1679, z =  82,  name = "Razorfen Kraul" },
    },
}

function DungeonRails.findNearestEntrance(bot)
    local mapId = bot:GetMapId()
    local entrances = CAVE_DUNGEON_ENTRANCES[mapId]
    if not entrances or #entrances == 0 then
        return nil
    end

    local bx, by = bot:GetLocation()
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

function DungeonRails.seekEntrance(bot)
    if not DungeonRails.canEnterDungeon(bot) then
        return false
    end

    local entrance, dist = DungeonRails.findNearestEntrance(bot)

    if not entrance then
        return false
    end

    if dist < 50 then
        print("[DungeonRails] " .. bot:GetName() .. " near entrance " ..
              entrance.name .. ", letting detection take over")
        return false
    end

    bot:SetWalk(true)
    bot:MoveTo(0, entrance.x, entrance.y, entrance.z, false)

    local bx, by = bot:GetLocation()
    local theta = math.atan2(entrance.y - by, entrance.x - bx)
    bot:SetData("theta", theta)

    print("[DungeonRails] " .. bot:GetName() .. " seeking " .. entrance.name ..
          " (" .. string.format("%.0f", dist) .. " yards)")
    return true
end

function DungeonRails.update(bot)
    if not DungeonRails.canEnterDungeon(bot) then
        return
    end

    if not bot:GetData("dungeon_entrance") then
        local x, y, z = bot:GetLocation()
        bot:SetData("dungeon_entrance", { x = x, y = y, z = z })
        bot:SetData("theta", bot:GetO())
        print("[DungeonRails] " .. bot:GetName() .. " entered dungeon at " ..
              string.format("%.0f, %.0f", x, y))
    end

    local posType, directions = DungeonRails.classifyPosition(bot)

    if posType == "intersection" then
        local tx, ty, tz = DungeonRails.handleIntersection(bot, directions)
        bot:SetWalk(true)
        bot:MoveTo(0, tx, ty, tz, false)
        return

    elseif posType == "dead_end" then
        DungeonRails.handleDeadEnd(bot)

    elseif posType == "stuck" then
        local entrance = bot:GetData("dungeon_entrance")
        if entrance then
            bot:MoveTo(0, entrance.x, entrance.y, entrance.z, false)
        end
        DungeonRails.exitDungeon(bot)
        return
    end

    local turnProb = DungeonRails.checkDeadEnd(bot)
    if math.random() < turnProb then
        DungeonRails.handleDeadEnd(bot)
    end

    local tx, ty, tz, status = DungeonRails.selectWanderTarget(bot)

    if status == "exit" then
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
end

print("[DungeonRails] Behavior loaded - called by BotWander when in dungeon/cave")
