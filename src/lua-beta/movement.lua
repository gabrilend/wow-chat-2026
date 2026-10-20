
Movement = {}

package.loaded["movement"] = Movement

function Movement.getCircleSpawnPosition(originX, originY, minDist, maxDist)
    local theta = math.random(0, 6.28)
    local radius = math.random(minDist, maxDist)
    local x = originX + math.cos(theta) * radius
    local y = originY + math.sin(theta) * radius
    return x, y
end

function Movement.getBoxSpawnPosition(originX, originY, minDist, maxDist)
    local x, y
    local randInt = math.random(1, 4)
    if randInt == 1 then
        x = originX + math.random( minDist,  maxDist)
        y = originY + math.random(-maxDist,  maxDist)
    elseif randInt == 2 then
        x = originX + math.random(-maxDist, -minDist)
        y = originY + math.random(-maxDist,  maxDist)
    elseif randInt == 3 then
        x = originX + math.random(-maxDist,  maxDist)
        y = originY + math.random( minDist,  maxDist)
    elseif randInt == 4 then
        x = originX + math.random(-maxDist,  maxDist)
        y = originY + math.random(-maxDist, -minDist)
    end

    return x, y
end

function Movement.getPlusSpawnPosition(originX, originY, minDist, maxDist)
    local x, y
    local randInt = math.random(1, 4)
    if randInt == 1 then
        x = originX + math.random( minDist,  maxDist)
        y = originY + math.random(-minDist,  minDist)
    elseif randInt == 2 then
        x = originX + math.random(-maxDist, -minDist)
        y = originY + math.random(-minDist,  minDist)
    elseif randInt == 3 then
        x = originX + math.random(-minDist,  minDist)
        y = originY + math.random( minDist,  maxDist)
    elseif randInt == 4 then
        x = originX + math.random(-minDist,  minDist)
        y = originY + math.random(-maxDist, -minDist)
    end

    return x, y
end

function Movement.getMathAngle(wowAngle)
    local mathAngle = wowAngle + 6.28
    if mathAngle > 6.28 then
        mathAngle = mathAngle - 6.28
    end
    return mathAngle
end

function Movement.getWoWAngle(mathAngle)
    local wowAngle = mathAngle - 6.28
    if wowAngle < 0 then
        wowAngle = wowAngle + 6.28
    end
    return wowAngle
end

function Movement.getArcSpawnPosition(originX, originY, minDist, maxDist, initialAngle)
    local radius = math.random(minDist, maxDist)
    local isNegative = math.random(0, 1)
    if isNegative == 1 then isNegative =  1
                       else isNegative = -1
    end
    local theta = Movement.getMathAngle(initialAngle + (isNegative * math.random() * 0.785))
    local x = originX + math.cos(theta) * radius
    local y = originY + math.sin(theta) * radius
    return x, y
end

function Movement.getLazyDistance(x1, y1, x2, y2)
    local dist = math.abs(x1 - x2) + math.abs(y1 - y2)
    local dx = math.abs(x1 - x2)
    local dy = math.abs(y1 - y2)
    return dist, dx, dy
end

function Movement.getInitialAngle(originX, originY, monsterX, monsterY)
    local dx = monsterX - originX
    local dy = monsterY - originY

    local angle = math.atan2(dy, dx)

    return angle
end

function Movement.getOrbitPosition(originX, originY, radius, speed, dt, initialAngle, direction)
    local angular_speed = speed / radius

    local new_angle = initialAngle + (angular_speed * dt * direction)

    local x = originX + math.cos(new_angle) * radius
    local y = originY + math.sin(new_angle) * radius

    return x, y
end

function Movement.getPositionOppositePoint(initialX, initialY, pivotX, pivotY)
    local x = initialX + ((pivotX - initialX) * 2)
    local y = initialY + ((pivotY - initialY) * 2)

    return x, y
end

function Movement.getPositionInFrontOfPoint(x, y, o, dist)
    x = x + math.cos(o) * dist
    y = y + math.sin(o) * dist

    return x, y
end

function Movement.getMidpoint(x1, y1, x2, y2)
    local x = (x1 + x2) / 2
    local y = (y1 + y2) / 2

    return x, y
end

function Movement.generateNewWanderPosition(x, y, z, o, theta, mapID)
    local thetaMin = theta - 0.39
    local thetaMax = theta + 0.39
    local dir      = (math.random(-19, 19) / 100) + math.random()
    local map      = GetMapById(mapID)

    if o + dir > thetaMax or o + dir < thetaMin then
        dir = dir * -1
    end
    o = o + dir

    local targetX, targetY = Movement.getPositionInFrontOfPoint(x, y, o, 10)
    local targetZ = map:GetHeight(targetX, targetY)

    return targetX, targetY, targetZ, o
end

function Movement.squaredDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return dx * dx + dy * dy
end

function Movement.normalize(dx, dy)
    local length = math.sqrt(dx * dx + dy * dy)
    return dx / length, dy / length
end

function Movement.nearestPointOnCircle(circleX, circleY, circleRadius, pointX, pointY)
    local dx, dy = pointX - circleX, pointY - circleY

    dx, dy = Movement.normalize(dx, dy)

    dx, dy = dx * circleRadius, dy * circleRadius

    local nearestX, nearestY = circleX + dx, circleY + dy

    return nearestX, nearestY
end

function Movement.isCloseEnough(x1, y1, x2, y2, dist)
    return Movement.squaredDistance(x1, y1, x2, y2) <= dist * dist
end

function Movement.getConsensusDirection(unit, range)
    range = range or 200
    local players = unit:GetPlayersInRange(range)
    if not players or #players < 1 then return nil end

    local sum_sin, sum_cos = 0, 0
    local count = 0

    for _, player in ipairs(players) do
        if player:IsAlive() and not player:IsBot() then
            local facing = player:GetO()
            sum_sin = sum_sin + math.sin(facing)
            sum_cos = sum_cos + math.cos(facing)
            count   = count + 1
        end
    end

    if count == 0 then return nil end
    return math.atan2(sum_sin, sum_cos)
end

function Movement.normalizeAngle(angle)
    while angle < 0 do
        angle = angle + 6.28
    end
    while angle >= 6.28 do
        angle = angle - 6.28
    end
    return angle
end

