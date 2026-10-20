
require("movement")

AvoidMonsters = {}

package.loaded["behaviors/avoid-monsters"] = AvoidMonsters

DANGER_RADIUS       =  40
FLEE_HEALTH_PCT     =  20
OUTNUMBER_THRESHOLD =   3
LEVEL_DANGER_WEIGHT =   5
COMBAT_DANGER_BONUS =  10
FLEE_DISTANCE       =  30
ELITE_DANGER_MULT   =   2
BOSS_DANGER_MULT    =   5

function AvoidMonsters.getDangerScore(unit, creature)
    if not creature or not creature:IsAlive() then return 0 end
    if not creature:IsHostileTo(unit) then return 0 end

    local score      = 0
    local unitLevel  = unit:GetLevel()
    local mobLevel   = creature:GetLevel()
    local levelDiff  = mobLevel - unitLevel

    if levelDiff > 0 then
        score = score + (levelDiff * LEVEL_DANGER_WEIGHT)
    end

    if creature:IsInCombat() then
        score = score + COMBAT_DANGER_BONUS
    end

    local rank = creature:GetCreatureType()
    if rank == 1 then score = score * ELITE_DANGER_MULT end
    if rank == 3 then score = score * BOSS_DANGER_MULT  end

    if score < 1 then score = 1 end

    return score
end

function AvoidMonsters.getTotalDanger(unit)
    local ux, uy     = unit:GetLocation()
    local nearby     = unit:GetCreaturesInRange(DANGER_RADIUS, 0, 1)
    local totalScore = 0
    local threats    = {}

    if not nearby then return 0, threats end

    for _, creature in pairs(nearby) do
        if creature and creature:IsAlive() and creature:IsHostileTo(unit) then
            local score = AvoidMonsters.getDangerScore(unit, creature)
            if score > 0 then
                local cx, cy = creature:GetLocation()
                totalScore   = totalScore + score
                table.insert(threats, {
                    creature = creature,
                    score    = score,
                    x        = cx,
                    y        = cy
                })
            end
        end
    end

    return totalScore, threats
end

function AvoidMonsters.getEscapeVector(unit, threats)
    if #threats == 0 then return 0, 0 end

    local ux, uy      = unit:GetLocation()
    local sumX, sumY  = 0, 0
    local totalWeight = 0

    for _, threat in ipairs(threats) do
        sumX        = sumX + (threat.x * threat.score)
        sumY        = sumY + (threat.y * threat.score)
        totalWeight = totalWeight + threat.score
    end

    if totalWeight == 0 then return 0, 0 end

    local centroidX = sumX / totalWeight
    local centroidY = sumY / totalWeight

    local dx = ux - centroidX
    local dy = uy - centroidY

    return Movement.normalize(dx, dy)
end

function AvoidMonsters.shouldFlee(unit)
    if not unit or not unit:IsAlive() then return false, "dead" end

    local healthPct = unit:GetHealthPct()
    local danger, threats = AvoidMonsters.getTotalDanger(unit)

    if healthPct <= FLEE_HEALTH_PCT and danger > 0 then
        return true, "low_health"
    end

    if #threats >= OUTNUMBER_THRESHOLD then
        return true, "outnumbered"
    end

    if danger >= 50 then
        return true, "extreme_danger"
    end

    return false, "safe"
end

function AvoidMonsters.getFleePosition(unit)
    local ux, uy, uz = unit:GetLocation()
    local danger, threats = AvoidMonsters.getTotalDanger(unit)

    if #threats == 0 then return ux, uy, uz end

    local dx, dy = AvoidMonsters.getEscapeVector(unit, threats)

    if dx == 0 and dy == 0 then
        local theta = math.random(0, 628) / 100
        dx = math.cos(theta)
        dy = math.sin(theta)
    end

    local fleeX = ux + (dx * FLEE_DISTANCE)
    local fleeY = uy + (dy * FLEE_DISTANCE)
    local fleeZ = uz

    local map = unit:GetMap()
    if map then
        fleeZ = map:GetHeight(fleeX, fleeY) or uz
    end

    return fleeX, fleeY, fleeZ
end

function AvoidMonsters.flee(unit)
    local shouldRun, reason = AvoidMonsters.shouldFlee(unit)

    if not shouldRun then return false end

    local fx, fy, fz = AvoidMonsters.getFleePosition(unit)

    unit:MoveTo(0, fx, fy, fz, true)

    local name = unit:GetName()
    print("[AvoidMonsters] " .. name .. " fleeing (" .. reason .. ")")

    return true
end

function AvoidMonsters.isAreaDangerous(unit, checkX, checkY)
    local ux, uy = unit:GetLocation()
    local nearby = unit:GetCreaturesInRange(DANGER_RADIUS, 0, 1)

    if not nearby then return false end

    for _, creature in pairs(nearby) do
        if creature and creature:IsAlive() and creature:IsHostileTo(unit) then
            local cx, cy = creature:GetLocation()

            local distToPoint = Movement.squaredDistance(cx, cy, checkX, checkY)
            if distToPoint < (DANGER_RADIUS * DANGER_RADIUS / 4) then
                return true
            end

            if creature:IsInCombat() then
                return true
            end
        end
    end

    return false
end

function AvoidMonsters.getSafeDirection(unit, preferredAngle)
    local ux, uy     = unit:GetLocation()
    local checkDist  = DANGER_RADIUS / 2
    local angleStep  = 0.785

    local testX = ux + math.cos(preferredAngle) * checkDist
    local testY = uy + math.sin(preferredAngle) * checkDist
    if not AvoidMonsters.isAreaDangerous(unit, testX, testY) then
        return preferredAngle
    end

    for i = 1, 4 do
        local offset = angleStep * i

        local cwAngle = preferredAngle + offset
        testX = ux + math.cos(cwAngle) * checkDist
        testY = uy + math.sin(cwAngle) * checkDist
        if not AvoidMonsters.isAreaDangerous(unit, testX, testY) then
            return cwAngle
        end

        local ccwAngle = preferredAngle - offset
        testX = ux + math.cos(ccwAngle) * checkDist
        testY = uy + math.sin(ccwAngle) * checkDist
        if not AvoidMonsters.isAreaDangerous(unit, testX, testY) then
            return ccwAngle
        end
    end

    return nil
end

print("[AvoidMonsters] Behavior loaded")
