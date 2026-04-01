-- {{{ Everland Ghostsong - Zone Consensus System
-- Calculates average facing direction of all players in zone
-- Bots drift in that direction when idle
-- Creates emergent collective movement patterns
--
-- Issue: 133-gesture-command-system-kneel-convoy.md
-- Concept Catalog: 301-330
-- }}}

require("movement")

ZoneConsensus = {}

-- {{{ Configuration
CONSENSUS_UPDATE_RATE  = 3000   -- ms between consensus recalculation
DRIFT_SPEED_FACTOR     = 0.3   -- how strongly bots follow consensus
CONSENSUS_WEIGHT_DECAY = 0.9   -- smoothing factor for direction changes
MIN_PLAYERS_FOR_ZONE   = 2     -- minimum players to form consensus
ZONE_RANGE             = 200   -- yards to consider "same zone"
MOMENTUM_WEIGHT        = 0.4   -- weight of bot's current direction
CONSENSUS_WEIGHT       = 0.6   -- weight of zone consensus direction
IDLE_DRIFT_DISTANCE    = 15    -- yards to drift when idle
-- }}}

-- {{{ State storage
local zone_consensus = {}    -- [zone_id] = {angle, strength, player_count}
local bot_momentum = {}      -- [bot_guid] = {angle, speed}
-- }}}

-- {{{ ZoneConsensus.getZoneId
-- Generate a zone identifier based on position
-- Divides world into grid cells
function ZoneConsensus.getZoneId(x, y, map_id)
    local grid_size = 500  -- yards per grid cell
    local grid_x = math.floor(x / grid_size)
    local grid_y = math.floor(y / grid_size)
    return string.format("%d_%d_%d", map_id, grid_x, grid_y)
end
-- }}}

-- {{{ ZoneConsensus.normalizeAngle
-- Normalize angle to 0 to 2*pi range
function ZoneConsensus.normalizeAngle(angle)
    while angle < 0 do
        angle = angle + (2 * math.pi)
    end
    while angle >= (2 * math.pi) do
        angle = angle - (2 * math.pi)
    end
    return angle
end
-- }}}

-- {{{ ZoneConsensus.averageAngles
-- Calculate circular mean of angles
-- Handles wrap-around at 0/2pi correctly
function ZoneConsensus.averageAngles(angles)
    if #angles == 0 then return 0, 0 end

    local sum_sin = 0
    local sum_cos = 0

    for _, angle in ipairs(angles) do
        sum_sin = sum_sin + math.sin(angle)
        sum_cos = sum_cos + math.cos(angle)
    end

    local mean_sin = sum_sin / #angles
    local mean_cos = sum_cos / #angles

    -- Strength is the length of the mean vector (0 = no consensus, 1 = perfect)
    local strength = math.sqrt(mean_sin * mean_sin + mean_cos * mean_cos)
    local mean_angle = math.atan2(mean_sin, mean_cos)

    return ZoneConsensus.normalizeAngle(mean_angle), strength
end
-- }}}

-- {{{ ZoneConsensus.calculateZoneConsensus
-- Calculate the consensus direction for a zone
-- Returns angle, strength, player_count
function ZoneConsensus.calculateZoneConsensus(zone_id, players)
    local angles = {}

    for _, player in ipairs(players) do
        if player and player:IsAlive() and not player:IsBot() then
            local facing = player:GetFacing()
            table.insert(angles, facing)
        end
    end

    if #angles < MIN_PLAYERS_FOR_ZONE then
        return nil, 0, #angles
    end

    local mean_angle, strength = ZoneConsensus.averageAngles(angles)

    -- Apply decay for smooth transitions
    local existing = zone_consensus[zone_id]
    if existing and existing.angle then
        -- Blend with previous consensus
        local blend_angles = {existing.angle, mean_angle}
        mean_angle, _ = ZoneConsensus.averageAngles(blend_angles)
        strength = (existing.strength * CONSENSUS_WEIGHT_DECAY) +
                   (strength * (1 - CONSENSUS_WEIGHT_DECAY))
    end

    return mean_angle, strength, #angles
end
-- }}}

-- {{{ ZoneConsensus.getPlayersInZone
-- Get all players in the same zone area
function ZoneConsensus.getPlayersInZone(bot)
    local bx, by, bz = bot:GetPosition()
    local map_id = bot:GetMapId()
    local players = {}

    local all_players = GetPlayersInWorld()
    if not all_players then return players end

    for _, player in pairs(all_players) do
        if player and player:IsAlive() and player:GetMapId() == map_id then
            local px, py = player:GetPosition()
            local distSq = Movement.squaredDistance(bx, by, px, py)

            if distSq <= (ZONE_RANGE * ZONE_RANGE) then
                table.insert(players, player)
            end
        end
    end

    return players
end
-- }}}

-- {{{ ZoneConsensus.updateZoneConsensus
-- Update the consensus for a zone based on current players
function ZoneConsensus.updateZoneConsensus(bot)
    local bx, by = bot:GetPosition()
    local map_id = bot:GetMapId()
    local zone_id = ZoneConsensus.getZoneId(bx, by, map_id)

    local players = ZoneConsensus.getPlayersInZone(bot)
    local angle, strength, count = ZoneConsensus.calculateZoneConsensus(zone_id, players)

    if angle then
        zone_consensus[zone_id] = {
            angle = angle,
            strength = strength,
            player_count = count,
            last_update = os.time()
        }
    end

    return zone_consensus[zone_id]
end
-- }}}

-- {{{ ZoneConsensus.getConsensusForBot
-- Get the zone consensus for a bot's current location
function ZoneConsensus.getConsensusForBot(bot)
    local bx, by = bot:GetPosition()
    local map_id = bot:GetMapId()
    local zone_id = ZoneConsensus.getZoneId(bx, by, map_id)

    return zone_consensus[zone_id]
end
-- }}}

-- {{{ ZoneConsensus.getBotMomentum
-- Get bot's current movement momentum/direction
function ZoneConsensus.getBotMomentum(bot)
    local bot_guid = bot:GetGUID()
    local momentum = bot_momentum[bot_guid]

    if momentum then
        return momentum.angle, momentum.speed
    end

    -- Default to facing direction
    return bot:GetFacing(), 0
end
-- }}}

-- {{{ ZoneConsensus.updateBotMomentum
-- Update bot's movement momentum based on current movement
function ZoneConsensus.updateBotMomentum(bot, new_angle)
    local bot_guid = bot:GetGUID()
    local current_angle, current_speed = ZoneConsensus.getBotMomentum(bot)

    -- Blend old and new direction
    local blend = {current_angle, new_angle}
    local blended_angle, _ = ZoneConsensus.averageAngles(blend)

    bot_momentum[bot_guid] = {
        angle = blended_angle,
        speed = 1.0  -- Assume moving
    }

    return blended_angle
end
-- }}}

-- {{{ ZoneConsensus.calculateDriftDirection
-- Combine zone consensus with bot momentum for final direction
-- Returns angle and destination position
function ZoneConsensus.calculateDriftDirection(bot)
    local consensus = ZoneConsensus.getConsensusForBot(bot)
    local bot_angle, bot_speed = ZoneConsensus.getBotMomentum(bot)

    if not consensus or consensus.strength < 0.1 then
        -- No consensus: drift in current direction
        return bot_angle
    end

    -- Blend momentum with consensus
    local angles = {bot_angle, consensus.angle}
    local weights = {MOMENTUM_WEIGHT, CONSENSUS_WEIGHT * consensus.strength}

    -- Weighted average using trigonometry
    local sum_sin = math.sin(bot_angle) * weights[1] +
                    math.sin(consensus.angle) * weights[2]
    local sum_cos = math.cos(bot_angle) * weights[1] +
                    math.cos(consensus.angle) * weights[2]

    local final_angle = math.atan2(sum_sin, sum_cos)
    return ZoneConsensus.normalizeAngle(final_angle)
end
-- }}}

-- {{{ ZoneConsensus.getDriftDestination
-- Calculate destination position for idle drifting
function ZoneConsensus.getDriftDestination(bot)
    local bx, by, bz = bot:GetPosition()
    local drift_angle = ZoneConsensus.calculateDriftDirection(bot)

    local dest_x = bx + math.cos(drift_angle) * IDLE_DRIFT_DISTANCE
    local dest_y = by + math.sin(drift_angle) * IDLE_DRIFT_DISTANCE

    -- Get ground height
    local map = bot:GetMap()
    local dest_z = bz
    if map then
        dest_z = map:GetHeight(dest_x, dest_y) or bz
    end

    return dest_x, dest_y, dest_z, drift_angle
end
-- }}}

-- {{{ ZoneConsensus.driftWithConsensus
-- Apply consensus-based drifting for idle bot
function ZoneConsensus.driftWithConsensus(bot)
    if not bot or not bot:IsBot() then return false end
    if not bot:IsAlive() then return false end
    if bot:IsInCombat() then return false end

    -- Check if resting
    local isResting = bot:GetData("resting")
    if isResting then return false end

    -- Update zone consensus
    ZoneConsensus.updateZoneConsensus(bot)

    -- Get drift destination
    local dest_x, dest_y, dest_z, angle = ZoneConsensus.getDriftDestination(bot)

    -- Update momentum
    ZoneConsensus.updateBotMomentum(bot, angle)

    -- Move to destination
    bot:MoveTo(0, dest_x, dest_y, dest_z, false)

    return true
end
-- }}}

-- {{{ ZoneConsensus.getZoneStats
-- Get statistics about zone consensus (for debugging/display)
function ZoneConsensus.getZoneStats(bot)
    local consensus = ZoneConsensus.getConsensusForBot(bot)

    if not consensus then
        return {
            has_consensus = false,
            angle = 0,
            strength = 0,
            player_count = 0
        }
    end

    return {
        has_consensus = true,
        angle = consensus.angle,
        angle_degrees = math.deg(consensus.angle),
        strength = consensus.strength,
        player_count = consensus.player_count,
        direction = ZoneConsensus.angleToCompass(consensus.angle)
    }
end
-- }}}

-- {{{ ZoneConsensus.angleToCompass
-- Convert angle to compass direction string
function ZoneConsensus.angleToCompass(angle)
    local deg = math.deg(ZoneConsensus.normalizeAngle(angle))

    if deg >= 337.5 or deg < 22.5 then return "E"
    elseif deg >= 22.5 and deg < 67.5 then return "NE"
    elseif deg >= 67.5 and deg < 112.5 then return "N"
    elseif deg >= 112.5 and deg < 157.5 then return "NW"
    elseif deg >= 157.5 and deg < 202.5 then return "W"
    elseif deg >= 202.5 and deg < 247.5 then return "SW"
    elseif deg >= 247.5 and deg < 292.5 then return "S"
    else return "SE"
    end
end
-- }}}

-- {{{ ZoneConsensus.cleanupOldZones
-- Remove stale zone consensus data
function ZoneConsensus.cleanupOldZones()
    local current_time = os.time()
    local stale_threshold = 60  -- seconds

    for zone_id, data in pairs(zone_consensus) do
        if current_time - (data.last_update or 0) > stale_threshold then
            zone_consensus[zone_id] = nil
        end
    end
end
-- }}}

-- {{{ ZoneConsensus.periodicUpdate
-- Periodic update for a bot
function ZoneConsensus.periodicUpdate(bot)
    ZoneConsensus.driftWithConsensus(bot)
end
-- }}}

-- {{{ ZoneConsensus.registerForBot
-- Register periodic consensus updates for a bot
function ZoneConsensus.registerForBot(bot)
    if not bot:IsBot() then return end

    bot:RegisterEvent(function(_eventID, _delay, _repeats, unit)
        ZoneConsensus.periodicUpdate(unit)
    end, CONSENSUS_UPDATE_RATE, 0)

    print("[ZoneConsensus] Registered for bot: " .. bot:GetName())
end
-- }}}

-- {{{ ZoneConsensus.onBotLogin
-- When a bot logs in, register for consensus updates
function ZoneConsensus.onBotLogin(event, player)
    if player and player:IsBot() then
        ZoneConsensus.registerForBot(player)
    end
end
-- }}}

-- {{{ ZoneConsensus.initialize
-- Initialize the zone consensus system
function ZoneConsensus.initialize()
    -- Periodic cleanup of stale zones
    CreateLuaEvent(ZoneConsensus.cleanupOldZones, 30000, 0)

    print("[ZoneConsensus] System initialized")
end
-- }}}

-- {{{ Event Registration
PLAYER_EVENT_ON_LOGIN = 3

RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, ZoneConsensus.onBotLogin)

ZoneConsensus.initialize()

print("[ZoneConsensus] Behavior loaded - Issue 133")
-- }}}
