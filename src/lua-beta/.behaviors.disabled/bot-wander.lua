
require("movement")

BotWander = {}

package.loaded["behaviors/bot-wander"] = BotWander

WANDER_DISTANCE       = 10
WANDER_THETA_DRIFT    = 0.39
WANDER_HEIGHT_LIMIT   = 5
WALL_HIT_THRESHOLD    = 3
REORIENT_THRESHOLD    = 3
LEVEL_RANGE           = 3
ANTI_CLUMP_RADIUS     = 2
RING_MIN_RADIUS       = 8
RING_MAX_RADIUS       = 15

STATE_WANDERING       = 1
STATE_REORIENTING     = 2
STATE_SEEKING_PLAYER  = 3

function BotWander.getState(bot)
    return bot:GetData("wander_state") or STATE_WANDERING
end

function BotWander.setState(bot, state)
    bot:SetData("wander_state", state)
end

function BotWander.getTheta(bot)
    local theta = bot:GetData("theta")
    if not theta then
        theta = bot:GetO()
        bot:SetData("theta", theta)
    end
    return theta
end

function BotWander.setTheta(bot, theta)
    theta = Movement.normalizeAngle(theta)
    bot:SetData("theta", theta)
end

function BotWander.getWallHits(bot)
    return bot:GetData("wall_hits") or 0
end

function BotWander.setWallHits(bot, count)
    bot:SetData("wall_hits", count)
end

function BotWander.getReorientCount(bot)
    return bot:GetData("reorient_count") or 0
end

function BotWander.setReorientCount(bot, count)
    bot:SetData("reorient_count", count)
end

function BotWander.shouldSkip(bot)
    if not bot:IsBot() then
        return true, "not a bot"
    end

    if not bot:IsAlive() then
        return true, "dead"
    end

    if bot:IsInCombat() then
        return true, "in combat"
    end

    if not bot:IsStandState() then
        return true, "resting"
    end

    local group = bot:GetGroup()
    if group then
        return true, "in party"
    end

    return false, nil
end

function BotWander.handleWater(bot)
    if not bot:IsInWater() then return false end

    local theta = BotWander.getTheta(bot)
    theta = theta + 3.14
    theta = Movement.normalizeAngle(theta)
    BotWander.setTheta(bot, theta)

    local wall_hits = BotWander.getWallHits(bot) + 1
    BotWander.setWallHits(bot, wall_hits)

    local x, y, z = bot:GetLocation()
    local bx = x + math.cos(theta) * 5
    local by = y + math.sin(theta) * 5
    local bz = bot:GetMap():GetHeight(bx, by) or z
    bot:MoveTo(0, bx, by, bz, false)

    print("[BotWander] " .. bot:GetName() .. " backed out of water")
    return true
end

function BotWander.tryWanderPosition(bot)
    local x, y, z, o = bot:GetLocation()
    local theta      = BotWander.getTheta(bot)
    local mapID      = bot:GetMapId()

    local targetX, targetY, targetZ, newO = Movement.generateNewWanderPosition(
        x, y, z, o, theta, mapID
    )

    if not targetZ then
        return nil
    end

    if math.abs(targetZ - z) > WANDER_HEIGHT_LIMIT then
        return nil
    end

    return targetX, targetY, targetZ, newO
end

function BotWander.reorientToConsensus(bot)
    local consensus = Movement.getConsensusDirection(bot, 200)

    if consensus then
        BotWander.setTheta(bot, consensus)
        print("[BotWander] " .. bot:GetName() .. " reoriented to consensus")
    else
        local randomTheta = math.random() * 6.28
        BotWander.setTheta(bot, randomTheta)
        print("[BotWander] " .. bot:GetName() .. " reoriented to random (no consensus)")
    end

    BotWander.setWallHits(bot, 0)
    BotWander.setState(bot, STATE_REORIENTING)
end

function BotWander.findNearestValidPlayer(bot)
    local botLevel = bot:GetLevel()
    local bx, by   = bot:GetLocation()
    local mapId    = bot:GetMapId()
    local botGuid  = bot:GetGUID()

    local allPlayers = GetPlayersInWorld()
    if not allPlayers then return nil, nil end

    local nearest     = nil
    local nearestDist = math.huge

    for _, player in pairs(allPlayers) do
        if player and player:GetGUID() ~= botGuid and player:IsAlive() then
            if player:GetMapId() == mapId then
                local levelDiff = math.abs(player:GetLevel() - botLevel)
                if levelDiff <= LEVEL_RANGE then
                    local px, py = player:GetLocation()
                    local distSq = Movement.squaredDistance(bx, by, px, py)
                    local dist   = math.sqrt(distSq)

                    if dist < nearestDist then
                        nearest     = player
                        nearestDist = dist
                    end
                end
            end
        end
    end

    return nearest, nearestDist
end

function BotWander.getRingPosition(bot, target)
    local tx, ty, tz = target:GetLocation()

    local angle  = math.random() * 6.28
    local radius = RING_MIN_RADIUS + math.random() * (RING_MAX_RADIUS - RING_MIN_RADIUS)

    local destX = tx + math.cos(angle) * radius
    local destY = ty + math.sin(angle) * radius

    local map   = bot:GetMap()
    local destZ = tz
    if map then
        destZ = map:GetHeight(destX, destY) or tz
    end

    return destX, destY, destZ, angle
end

function BotWander.seekNearestPlayer(bot)
    local target, dist = BotWander.findNearestValidPlayer(bot)

    if not target then
        print("[BotWander] " .. bot:GetName() .. " no valid players to seek")
        return false
    end

    local destX, destY, destZ, angle = BotWander.getRingPosition(bot, target)

    bot:MoveTo(0, destX, destY, destZ, false)
    BotWander.setState(bot, STATE_SEEKING_PLAYER)

    BotWander.setTheta(bot, angle)

    print("[BotWander] " .. bot:GetName() .. " seeking " .. target:GetName())
    return true
end

function BotWander.checkAntiClump(bot)
    local bx, by, bz = bot:GetLocation()
    local botGuid    = bot:GetGUID()
    local mapId      = bot:GetMapId()

    local allPlayers = GetPlayersInWorld()
    if not allPlayers then return false end

    for _, other in pairs(allPlayers) do
        if other and other:IsBot() and other:GetGUID() ~= botGuid then
            if other:GetMapId() == mapId and other:IsAlive() then
                local ox, oy = other:GetLocation()
                local distSq = Movement.squaredDistance(bx, by, ox, oy)

                if distSq < ANTI_CLUMP_RADIUS * ANTI_CLUMP_RADIUS then
                    local angle  = math.random() * 6.28
                    local destX  = bx + math.cos(angle) * 5
                    local destY  = by + math.sin(angle) * 5
                    local map    = bot:GetMap()
                    local destZ  = bz
                    if map then
                        destZ = map:GetHeight(destX, destY) or bz
                    end

                    bot:MoveTo(0, destX, destY, destZ, false)
                    return true
                end
            end
        end
    end

    return false
end

function BotWander.doWander(bot)
    local targetX, targetY, targetZ, newO = BotWander.tryWanderPosition(bot)

    if targetX then
        bot:SetWalk(true)
        bot:MoveTo(0, targetX, targetY, targetZ, false)

        BotWander.setTheta(bot, newO)
        BotWander.setWallHits(bot, 0)
        BotWander.setReorientCount(bot, 0)
        BotWander.setState(bot, STATE_WANDERING)
        return true
    end

    local wallHits = BotWander.getWallHits(bot) + 1
    BotWander.setWallHits(bot, wallHits)

    local state = BotWander.getState(bot)

    if wallHits >= WALL_HIT_THRESHOLD then
        if state == STATE_REORIENTING then
            local reorientCount = BotWander.getReorientCount(bot) + 1
            BotWander.setReorientCount(bot, reorientCount)

            if reorientCount >= 2 then
                BotWander.seekNearestPlayer(bot)
                BotWander.setReorientCount(bot, 0)
                return true
            end
        end

        BotWander.reorientToConsensus(bot)
        return true
    end

    return false
end

function BotWander.update(bot)
    local shouldSkip, reason = BotWander.shouldSkip(bot)
    if shouldSkip then
        return false
    end

    if DungeonRails and DungeonRails.isInDungeon and DungeonRails.isInDungeon(bot) then
        if DungeonRails.update then
            DungeonRails.update(bot)
        end
        return true
    end

    if BotOrchestrator and BotOrchestrator.getMode then
        local mode = BotOrchestrator.getMode(bot)
        if mode == BotOrchestrator.MODE.DUNGEON_DELVE then
            if DungeonRails and DungeonRails.seekEntrance then
                if DungeonRails.seekEntrance(bot) then
                    return true
                end
            end
        end
    end

    if BotWander.handleWater(bot) then
        return true
    end

    if BotWander.checkAntiClump(bot) then
        return true
    end

    local state = BotWander.getState(bot)

    if state == STATE_SEEKING_PLAYER then
        local nearest, dist = BotWander.findNearestValidPlayer(bot)
        if nearest and dist and dist < RING_MAX_RADIUS then
            BotWander.setState(bot, STATE_WANDERING)
            BotWander.setWallHits(bot, 0)
            print("[BotWander] " .. bot:GetName() .. " arrived, resuming wander")
        end
        return true
    end

    return BotWander.doWander(bot)
end

function BotWander.lonelinessCheck(bot)
    local shouldSkip, reason = BotWander.shouldSkip(bot)
    if shouldSkip then
        return false
    end

    if DungeonRails and DungeonRails.isInDungeon and DungeonRails.isInDungeon(bot) then
        return false
    end

    if BotWander.getState(bot) == STATE_SEEKING_PLAYER then
        return false
    end

    local bx, by   = bot:GetLocation()
    local botLevel = bot:GetLevel()
    local mapId    = bot:GetMapId()
    local botGuid  = bot:GetGUID()

    local LONELY_RADIUS = 100

    local allPlayers = GetPlayersInWorld()
    if not allPlayers then
        return BotWander.seekNearestPlayer(bot)
    end

    for _, player in pairs(allPlayers) do
        if player and player:GetGUID() ~= botGuid and player:IsAlive() then
            if player:GetMapId() == mapId then
                local levelDiff = math.abs(player:GetLevel() - botLevel)
                if levelDiff <= LEVEL_RANGE then
                    local px, py = player:GetLocation()
                    local distSq = Movement.squaredDistance(bx, by, px, py)

                    if distSq < LONELY_RADIUS * LONELY_RADIUS then
                        return false
                    end
                end
            end
        end
    end

    print("[BotWander] " .. bot:GetName() .. " is lonely, seeking others")
    return BotWander.seekNearestPlayer(bot)
end

print("[BotWander] Behavior loaded - periodic registration via periodic_events.lua")
