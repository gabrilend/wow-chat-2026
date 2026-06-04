-- {{{ Everland Ghostsong - Avoid Monsters Behavior
-- Provides danger awareness and flee logic for bots and NPCs
-- Called by find-monsters for engagement decisions
-- Used by travel.lua wanderers to avoid combat zones
--
-- Config values at top. Git greps are cheap.
-- Vertical alignment connects related values.
-- Dense math, few functions.
-- }}}

require("movement")

AvoidMonsters = {}

-- Register in package.loaded so require() is a no-op after ALE loads this
-- Must be AFTER AvoidMonsters table is created so require() returns the module
package.loaded["behaviors/avoid-monsters"] = AvoidMonsters

-- {{{ Configuration
DANGER_RADIUS       =  40   -- yards to check for threats
FLEE_HEALTH_PCT     =  20   -- health % to trigger flee
OUTNUMBER_THRESHOLD =   3   -- enemy count triggering flee
LEVEL_DANGER_WEIGHT =   5   -- points per level above us
COMBAT_DANGER_BONUS =  10   -- extra points if creature in combat
FLEE_DISTANCE       =  30   -- yards to flee from danger
ELITE_DANGER_MULT   =   2   -- multiplier for elite creatures
BOSS_DANGER_MULT    =   5   -- multiplier for boss creatures
-- }}}

-- {{{ AvoidMonsters.getDangerScore
-- Calculate danger score for a single creature relative to unit
-- Higher score = more dangerous
function AvoidMonsters.getDangerScore(unit, creature)
    if not creature or not creature:IsAlive() then return 0 end
    -- IsHostileTo provided by ElunaCompat.ext
    if not creature:IsHostileTo(unit) then return 0 end

    local score      = 0
    local unitLevel  = unit:GetLevel()
    local mobLevel   = creature:GetLevel()
    local levelDiff  = mobLevel - unitLevel

    -- base danger from level difference
    if levelDiff > 0 then
        score = score + (levelDiff * LEVEL_DANGER_WEIGHT)
    end

    -- creature in combat is more dangerous
    if creature:IsInCombat() then
        score = score + COMBAT_DANGER_BONUS
    end

    -- elite and boss multipliers
    local rank = creature:GetCreatureType() -- TODO: verify API
    if rank == 1 then score = score * ELITE_DANGER_MULT end  -- elite
    if rank == 3 then score = score * BOSS_DANGER_MULT  end  -- boss

    -- minimum danger of 1 for any hostile
    if score < 1 then score = 1 end

    return score
end -- }}}

-- {{{ AvoidMonsters.getTotalDanger
-- Sum danger scores from all nearby hostile creatures
-- Returns total danger and table of threat positions
function AvoidMonsters.getTotalDanger(unit)
    local ux, uy     = unit:GetLocation()
    -- GetCreaturesInRange(range, entryId, hostile) - hostile: 0=both, 1=hostile, 2=friendly
    local nearby     = unit:GetCreaturesInRange(DANGER_RADIUS, 0, 1)  -- hostile only
    local totalScore = 0
    local threats    = {}

    if not nearby then return 0, threats end

    for _, creature in pairs(nearby) do
        -- IsHostileTo provided by ElunaCompat.ext
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
end -- }}}

-- {{{ AvoidMonsters.getEscapeVector
-- Calculate direction to flee from threats
-- Returns normalized dx, dy pointing away from danger centroid
function AvoidMonsters.getEscapeVector(unit, threats)
    if #threats == 0 then return 0, 0 end

    local ux, uy      = unit:GetLocation()
    local sumX, sumY  = 0, 0
    local totalWeight = 0

    -- weighted centroid of threats (higher danger = more pull)
    for _, threat in ipairs(threats) do
        sumX        = sumX + (threat.x * threat.score)
        sumY        = sumY + (threat.y * threat.score)
        totalWeight = totalWeight + threat.score
    end

    if totalWeight == 0 then return 0, 0 end

    local centroidX = sumX / totalWeight
    local centroidY = sumY / totalWeight

    -- direction away from centroid
    local dx = ux - centroidX
    local dy = uy - centroidY

    -- normalize
    return Movement.normalize(dx, dy)
end -- }}}

-- {{{ AvoidMonsters.shouldFlee
-- Determine if unit should flee based on danger and health
-- Returns true/false and reason string
function AvoidMonsters.shouldFlee(unit)
    if not unit or not unit:IsAlive() then return false, "dead" end

    local healthPct = unit:GetHealthPct()
    local danger, threats = AvoidMonsters.getTotalDanger(unit)

    -- low health flee
    if healthPct <= FLEE_HEALTH_PCT and danger > 0 then
        return true, "low_health"
    end

    -- outnumbered flee
    if #threats >= OUTNUMBER_THRESHOLD then
        return true, "outnumbered"
    end

    -- extreme danger flee (very high level creature)
    if danger >= 50 then
        return true, "extreme_danger"
    end

    return false, "safe"
end -- }}}

-- {{{ AvoidMonsters.getFleePosition
-- Calculate position to flee to
-- Returns x, y, z for safe escape position
function AvoidMonsters.getFleePosition(unit)
    local ux, uy, uz = unit:GetLocation()
    local danger, threats = AvoidMonsters.getTotalDanger(unit)

    if #threats == 0 then return ux, uy, uz end

    local dx, dy = AvoidMonsters.getEscapeVector(unit, threats)

    if dx == 0 and dy == 0 then
        -- no clear escape, pick random direction
        local theta = math.random(0, 628) / 100
        dx = math.cos(theta)
        dy = math.sin(theta)
    end

    -- calculate flee destination
    local fleeX = ux + (dx * FLEE_DISTANCE)
    local fleeY = uy + (dy * FLEE_DISTANCE)
    local fleeZ = uz

    -- get actual ground height at destination
    local map = unit:GetMap()
    if map then
        fleeZ = map:GetHeight(fleeX, fleeY) or uz
    end

    return fleeX, fleeY, fleeZ
end -- }}}

-- {{{ AvoidMonsters.flee
-- Execute flee behavior for unit
-- Returns true if fleeing, false if no need
function AvoidMonsters.flee(unit)
    local shouldRun, reason = AvoidMonsters.shouldFlee(unit)

    if not shouldRun then return false end

    local fx, fy, fz = AvoidMonsters.getFleePosition(unit)

    -- move to flee position
    unit:MoveTo(0, fx, fy, fz, true)

    -- debug output
    local name = unit:GetName()
    print("[AvoidMonsters] " .. name .. " fleeing (" .. reason .. ")")

    return true
end -- }}}

-- {{{ AvoidMonsters.isAreaDangerous
-- Check if a position is near active combat or hostiles
-- Used by travel.lua wanderers to pick safe paths
function AvoidMonsters.isAreaDangerous(unit, checkX, checkY)
    local ux, uy = unit:GetLocation()
    -- GetCreaturesInRange(range, entryId, hostile) - hostile: 0=both, 1=hostile, 2=friendly
    local nearby = unit:GetCreaturesInRange(DANGER_RADIUS, 0, 1)  -- hostile only

    if not nearby then return false end

    for _, creature in pairs(nearby) do
        -- IsHostileTo provided by ElunaCompat.ext
        if creature and creature:IsAlive() and creature:IsHostileTo(unit) then
            local cx, cy = creature:GetLocation()

            -- check if creature is near the point we're checking
            local distToPoint = Movement.squaredDistance(cx, cy, checkX, checkY)
            if distToPoint < (DANGER_RADIUS * DANGER_RADIUS / 4) then
                return true
            end

            -- check if creature is in combat
            if creature:IsInCombat() then
                return true
            end
        end
    end

    return false
end -- }}}

-- {{{ AvoidMonsters.getSafeDirection
-- Find a direction that avoids danger
-- Returns angle in radians, or nil if no safe direction
function AvoidMonsters.getSafeDirection(unit, preferredAngle)
    local ux, uy     = unit:GetLocation()
    local checkDist  = DANGER_RADIUS / 2
    local angleStep  = 0.785  -- 45 degrees

    -- try preferred direction first
    local testX = ux + math.cos(preferredAngle) * checkDist
    local testY = uy + math.sin(preferredAngle) * checkDist
    if not AvoidMonsters.isAreaDangerous(unit, testX, testY) then
        return preferredAngle
    end

    -- try alternating directions
    for i = 1, 4 do
        local offset = angleStep * i

        -- try clockwise
        local cwAngle = preferredAngle + offset
        testX = ux + math.cos(cwAngle) * checkDist
        testY = uy + math.sin(cwAngle) * checkDist
        if not AvoidMonsters.isAreaDangerous(unit, testX, testY) then
            return cwAngle
        end

        -- try counter-clockwise
        local ccwAngle = preferredAngle - offset
        testX = ux + math.cos(ccwAngle) * checkDist
        testY = uy + math.sin(ccwAngle) * checkDist
        if not AvoidMonsters.isAreaDangerous(unit, testX, testY) then
            return ccwAngle
        end
    end

    return nil  -- no safe direction found
end -- }}}

print("[AvoidMonsters] Behavior loaded")
-- }}}
