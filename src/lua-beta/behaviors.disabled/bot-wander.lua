-- {{{ Everland Ghostsong - Bot Wandering Behavior
-- Bots wander like traveller NPCs using generateNewWanderPosition()
-- Fallback to zone consensus after wall-hits, then seek nearest player
-- Water handling: reactive check after movement, reverse theta if wet
--
-- Issue: 161-bot-wandering-traveller-style.md
-- Concept Catalog: 111-115 (traveller movement), 301-330 (zone consensus)
-- }}}

require("movement")

BotWander = {}

-- Register in package.loaded so require() is a no-op after ALE loads this
-- Must be AFTER BotWander table is created so require() returns the module
package.loaded["behaviors/bot-wander"] = BotWander

-- {{{ Configuration
WANDER_DISTANCE       = 10    -- yards per movement (same as travellers)
WANDER_THETA_DRIFT    = 0.39  -- max radians drift per step (~22 degrees)
WANDER_HEIGHT_LIMIT   = 5     -- yards vertical tolerance
WALL_HIT_THRESHOLD    = 3     -- failures before reorientation
REORIENT_THRESHOLD    = 3     -- failures after reorient before seeking
LEVEL_RANGE           = 3     -- +/- levels for "valid" player
ANTI_CLUMP_RADIUS     = 2     -- yards - disperse if bot within this
RING_MIN_RADIUS       = 8     -- yards - min ring distance from target
RING_MAX_RADIUS       = 15    -- yards - max ring distance from target
-- }}}

-- {{{ State machine states
STATE_WANDERING       = 1     -- normal traveller-style wandering
STATE_REORIENTING     = 2     -- just reoriented to consensus, resuming wander
STATE_SEEKING_PLAYER  = 3     -- moving toward nearest valid player
-- }}}

-- {{{ BotWander.getState
-- Get bot's current wandering state
function BotWander.getState(bot)
    return bot:GetData("wander_state") or STATE_WANDERING
end -- }}}

-- {{{ BotWander.setState
-- Set bot's wandering state
function BotWander.setState(bot, state)
    bot:SetData("wander_state", state)
end -- }}}

-- {{{ BotWander.getTheta
-- Get persistent movement direction
-- GetO() returns orientation (facing angle in radians)
function BotWander.getTheta(bot)
    local theta = bot:GetData("theta")
    if not theta then
        theta = bot:GetO()
        bot:SetData("theta", theta)
    end
    return theta
end -- }}}

-- {{{ BotWander.setTheta
-- Set persistent movement direction
function BotWander.setTheta(bot, theta)
    theta = Movement.normalizeAngle(theta)
    bot:SetData("theta", theta)
end -- }}}

-- {{{ BotWander.getWallHits
-- Get wall hit counter
function BotWander.getWallHits(bot)
    return bot:GetData("wall_hits") or 0
end -- }}}

-- {{{ BotWander.setWallHits
-- Set wall hit counter
function BotWander.setWallHits(bot, count)
    bot:SetData("wall_hits", count)
end -- }}}

-- {{{ BotWander.getReorientCount
-- Get count of reorientations (for escalation to seeking)
function BotWander.getReorientCount(bot)
    return bot:GetData("reorient_count") or 0
end -- }}}

-- {{{ BotWander.setReorientCount
-- Set reorientation count
function BotWander.setReorientCount(bot, count)
    bot:SetData("reorient_count", count)
end -- }}}

-- {{{ BotWander.shouldSkip
-- Check if bot should skip wandering this tick
-- Returns true if should skip, reason string
function BotWander.shouldSkip(bot)
    -- Not a bot
    if not bot:IsBot() then
        return true, "not a bot"
    end

    -- Dead
    if not bot:IsAlive() then
        return true, "dead"
    end

    -- In combat
    if bot:IsInCombat() then
        return true, "in combat"
    end

    -- Resting (sitting)
    if not bot:IsStandState() then
        return true, "resting"
    end

    -- In party - defer to playerbots
    local group = bot:GetGroup()
    if group then
        return true, "in party"
    end

    return false, nil
end -- }}}

-- {{{ BotWander.handleWater
-- Called after movement - if wet, reverse direction and back out
-- Returns true if handled water (counts as wall-hit)
function BotWander.handleWater(bot)
    if not bot:IsInWater() then return false end

    -- Stepped in water - reverse direction
    local theta = BotWander.getTheta(bot)
    theta = theta + 3.14  -- reverse (~180 degrees)
    theta = Movement.normalizeAngle(theta)
    BotWander.setTheta(bot, theta)

    -- Count as wall-hit
    local wall_hits = BotWander.getWallHits(bot) + 1
    BotWander.setWallHits(bot, wall_hits)

    -- Move back out immediately (5 yards in reversed direction)
    local x, y, z = bot:GetLocation()
    local bx = x + math.cos(theta) * 5
    local by = y + math.sin(theta) * 5
    local bz = bot:GetMap():GetHeight(bx, by) or z
    bot:MoveTo(0, bx, by, bz, false)

    print("[BotWander] " .. bot:GetName() .. " backed out of water")
    return true
end -- }}}

-- {{{ BotWander.tryWanderPosition
-- Try to find a valid wander position using traveller-style algorithm
-- Returns x, y, z, newTheta on success, nil on failure
function BotWander.tryWanderPosition(bot)
    local x, y, z, o = bot:GetLocation()
    local theta      = BotWander.getTheta(bot)
    local mapID      = bot:GetMapId()

    -- Use same algorithm as travellers
    local targetX, targetY, targetZ, newO = Movement.generateNewWanderPosition(
        x, y, z, o, theta, mapID
    )

    -- Validate height
    if not targetZ then
        return nil
    end

    if math.abs(targetZ - z) > WANDER_HEIGHT_LIMIT then
        return nil
    end

    return targetX, targetY, targetZ, newO
end -- }}}

-- {{{ BotWander.reorientToConsensus
-- Reorient theta to zone consensus direction
function BotWander.reorientToConsensus(bot)
    local consensus = Movement.getConsensusDirection(bot, 200)

    if consensus then
        BotWander.setTheta(bot, consensus)
        print("[BotWander] " .. bot:GetName() .. " reoriented to consensus")
    else
        -- No consensus available - pick random direction
        local randomTheta = math.random() * 6.28
        BotWander.setTheta(bot, randomTheta)
        print("[BotWander] " .. bot:GetName() .. " reoriented to random (no consensus)")
    end

    BotWander.setWallHits(bot, 0)
    BotWander.setState(bot, STATE_REORIENTING)
end -- }}}

-- {{{ BotWander.findNearestValidPlayer
-- Find nearest player/bot within level range
-- Returns player, distance or nil, nil
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
end -- }}}

-- {{{ BotWander.getRingPosition
-- Get random position on ring around target
function BotWander.getRingPosition(bot, target)
    local tx, ty, tz = target:GetLocation()

    -- Random angle
    local angle  = math.random() * 6.28
    local radius = RING_MIN_RADIUS + math.random() * (RING_MAX_RADIUS - RING_MIN_RADIUS)

    local destX = tx + math.cos(angle) * radius
    local destY = ty + math.sin(angle) * radius

    -- Get ground height
    local map   = bot:GetMap()
    local destZ = tz
    if map then
        destZ = map:GetHeight(destX, destY) or tz
    end

    return destX, destY, destZ, angle
end -- }}}

-- {{{ BotWander.seekNearestPlayer
-- Move toward nearest valid player's ring position
-- Returns true if seeking, false if no valid player found
function BotWander.seekNearestPlayer(bot)
    local target, dist = BotWander.findNearestValidPlayer(bot)

    if not target then
        print("[BotWander] " .. bot:GetName() .. " no valid players to seek")
        return false
    end

    local destX, destY, destZ, angle = BotWander.getRingPosition(bot, target)

    bot:MoveTo(0, destX, destY, destZ, false)
    BotWander.setState(bot, STATE_SEEKING_PLAYER)

    -- Set theta toward destination for smooth resume
    BotWander.setTheta(bot, angle)

    print("[BotWander] " .. bot:GetName() .. " seeking " .. target:GetName())
    return true
end -- }}}

-- {{{ BotWander.checkAntiClump
-- Check if too close to another bot and disperse
-- Returns true if dispersed
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
                    -- Too close - move to a position without another bot nearby
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
end -- }}}

-- {{{ BotWander.doWander
-- Execute one wander step with traveller-style movement
function BotWander.doWander(bot)
    -- Try to find valid position
    local targetX, targetY, targetZ, newO = BotWander.tryWanderPosition(bot)

    if targetX then
        -- Success - move and reset counters
        -- SetWalk provided by ElunaCompat.ext for Players
        bot:SetWalk(true)
        bot:MoveTo(0, targetX, targetY, targetZ, false)

        -- Update theta toward chosen direction
        BotWander.setTheta(bot, newO)
        BotWander.setWallHits(bot, 0)
        BotWander.setReorientCount(bot, 0)
        BotWander.setState(bot, STATE_WANDERING)
        return true
    end

    -- Failed - increment wall hits
    local wallHits = BotWander.getWallHits(bot) + 1
    BotWander.setWallHits(bot, wallHits)

    local state = BotWander.getState(bot)

    -- Check escalation
    if wallHits >= WALL_HIT_THRESHOLD then
        if state == STATE_REORIENTING then
            -- Already reoriented once - escalate to seeking
            local reorientCount = BotWander.getReorientCount(bot) + 1
            BotWander.setReorientCount(bot, reorientCount)

            if reorientCount >= 2 then
                -- Too many reorients - seek player
                BotWander.seekNearestPlayer(bot)
                BotWander.setReorientCount(bot, 0)
                return true
            end
        end

        -- Reorient to consensus
        BotWander.reorientToConsensus(bot)
        return true
    end

    return false
end -- }}}

-- {{{ BotWander.update
-- Main update function - called by periodic_events.lua
-- Returns true if action taken
function BotWander.update(bot)
    -- Check skip conditions
    local shouldSkip, reason = BotWander.shouldSkip(bot)
    if shouldSkip then
        return false
    end

    -- Check if in dungeon - defer to DungeonRails
    if DungeonRails and DungeonRails.isInDungeon and DungeonRails.isInDungeon(bot) then
        if DungeonRails.update then
            DungeonRails.update(bot)
        end
        return true
    end

    -- Check if in DUNGEON_DELVE mode but not in dungeon - seek entrance (issue 614)
    if BotOrchestrator and BotOrchestrator.getMode then
        local mode = BotOrchestrator.getMode(bot)
        if mode == BotOrchestrator.MODE.DUNGEON_DELVE then
            -- Not in dungeon yet - seek entrance
            if DungeonRails and DungeonRails.seekEntrance then
                if DungeonRails.seekEntrance(bot) then
                    return true
                end
            end
            -- Fallthrough to normal wandering if no entrance found/seeking
        end
    end

    -- Handle water (reactive check from previous movement)
    if BotWander.handleWater(bot) then
        return true
    end

    -- Check anti-clump
    if BotWander.checkAntiClump(bot) then
        return true
    end

    -- Check state
    local state = BotWander.getState(bot)

    if state == STATE_SEEKING_PLAYER then
        -- Check if we've arrived at destination (within 5 yards of any valid player)
        local nearest, dist = BotWander.findNearestValidPlayer(bot)
        if nearest and dist and dist < RING_MAX_RADIUS then
            -- Arrived - resume wandering
            BotWander.setState(bot, STATE_WANDERING)
            BotWander.setWallHits(bot, 0)
            print("[BotWander] " .. bot:GetName() .. " arrived, resuming wander")
        end
        -- Still seeking - movement in progress
        return true
    end

    -- Normal wandering or reorienting
    return BotWander.doWander(bot)
end -- }}}

-- {{{ BotWander.lonelinessCheck
-- Separate check run at longer interval (30s)
-- If no valid players within 100 yards, seek nearest
function BotWander.lonelinessCheck(bot)
    -- Check skip conditions
    local shouldSkip, reason = BotWander.shouldSkip(bot)
    if shouldSkip then
        return false
    end

    -- Don't interrupt dungeon navigation
    if DungeonRails and DungeonRails.isInDungeon and DungeonRails.isInDungeon(bot) then
        return false
    end

    -- Don't interrupt if already seeking
    if BotWander.getState(bot) == STATE_SEEKING_PLAYER then
        return false
    end

    local bx, by   = bot:GetLocation()
    local botLevel = bot:GetLevel()
    local mapId    = bot:GetMapId()
    local botGuid  = bot:GetGUID()

    local LONELY_RADIUS = 100  -- yards

    local allPlayers = GetPlayersInWorld()
    if not allPlayers then
        return BotWander.seekNearestPlayer(bot)
    end

    -- Check if any valid players within loneliness radius
    for _, player in pairs(allPlayers) do
        if player and player:GetGUID() ~= botGuid and player:IsAlive() then
            if player:GetMapId() == mapId then
                local levelDiff = math.abs(player:GetLevel() - botLevel)
                if levelDiff <= LEVEL_RANGE then
                    local px, py = player:GetLocation()
                    local distSq = Movement.squaredDistance(bx, by, px, py)

                    if distSq < LONELY_RADIUS * LONELY_RADIUS then
                        -- Not lonely
                        return false
                    end
                end
            end
        end
    end

    -- Lonely - seek nearest valid player
    print("[BotWander] " .. bot:GetName() .. " is lonely, seeking others")
    return BotWander.seekNearestPlayer(bot)
end -- }}}

-- {{{ Module initialization
print("[BotWander] Behavior loaded - periodic registration via periodic_events.lua")
-- }}}
