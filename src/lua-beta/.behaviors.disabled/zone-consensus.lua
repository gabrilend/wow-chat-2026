
require("movement")

ZoneConsensus = {}

package.loaded["behaviors/zone-consensus"] = ZoneConsensus

CONSENSUS_UPDATE_RATE  = 3000
DRIFT_SPEED_FACTOR     = 0.3
CONSENSUS_WEIGHT_DECAY = 0.9
MIN_PLAYERS_FOR_ZONE   = 2
ZONE_RANGE             = 200
MOMENTUM_WEIGHT        = 0.4
CONSENSUS_WEIGHT       = 0.6
IDLE_DRIFT_DISTANCE    = 15

LONELY_RADIUS          = 200
APPROACH_DISTANCE      = 100
CLUMP_RADIUS           = 15
DISPERSE_DISTANCE      = 20

local zone_consensus = {}
local bot_momentum = {}

function ZoneConsensus.findNearestUnit(bot)
    local bx, by, bz = bot:GetLocation()
    local map_id     = bot:GetMapId()
    local bot_guid   = bot:GetGUID()

    local nearest      = nil
    local nearest_dist = math.huge

    local all_players = GetPlayersInWorld()
    if not all_players then return nil, nil end

    for _, player in pairs(all_players) do
        if player and player:GetGUID() ~= bot_guid and player:IsAlive() then
            if player:GetMapId() == map_id then
                local px, py = player:GetLocation()
                local distSq = Movement.squaredDistance(bx, by, px, py)
                local dist   = math.sqrt(distSq)

                if dist < nearest_dist then
                    nearest      = player
                    nearest_dist = dist
                end
            end
        end
    end

    return nearest, nearest_dist
end

function ZoneConsensus.countNearbyUnits(bot, radius)
    local bx, by, bz = bot:GetLocation()
    local map_id     = bot:GetMapId()
    local bot_guid   = bot:GetGUID()
    local count      = 0

    local all_players = GetPlayersInWorld()
    if not all_players then return 0 end

    for _, player in pairs(all_players) do
        if player and player:GetGUID() ~= bot_guid and player:IsAlive() then
            if player:GetMapId() == map_id then
                local px, py = player:GetLocation()
                local distSq = Movement.squaredDistance(bx, by, px, py)

                if distSq <= radius * radius then
                    count = count + 1
                end
            end
        end
    end

    return count
end

function ZoneConsensus.handleDispersion(bot)
    local nearest, dist = ZoneConsensus.findNearestUnit(bot)

    if not nearest then return false end

    if dist > LONELY_RADIUS then
        local bx, by, bz = bot:GetLocation()
        local nx, ny, nz = nearest:GetLocation()

        local angle = math.atan2(ny - by, nx - bx)

        local move_dist = math.min(APPROACH_DISTANCE, dist - 20)
        local dest_x    = bx + math.cos(angle) * move_dist
        local dest_y    = by + math.sin(angle) * move_dist

        local map    = bot:GetMap()
        local dest_z = bz
        if map then
            dest_z = map:GetHeight(dest_x, dest_y) or bz
        end

        bot:MoveTo(0, dest_x, dest_y, dest_z, false)
        print("[ZoneConsensus] " .. bot:GetName() .. " moving toward others (lonely)")
        return true
    end

    local clumped_count = ZoneConsensus.countNearbyUnits(bot, CLUMP_RADIUS)
    if clumped_count > 0 then
        local bx, by, bz = bot:GetLocation()

        local angle  = math.random() * 6.28
        local dest_x = bx + math.cos(angle) * DISPERSE_DISTANCE
        local dest_y = by + math.sin(angle) * DISPERSE_DISTANCE

        local map    = bot:GetMap()
        local dest_z = bz
        if map then
            dest_z = map:GetHeight(dest_x, dest_y) or bz
        end

        bot:MoveTo(0, dest_x, dest_y, dest_z, false)
        print("[ZoneConsensus] " .. bot:GetName() .. " dispersing (clumped)")
        return true
    end

    return false
end

function ZoneConsensus.getZoneId(x, y, map_id)
    local grid_size = 500
    local grid_x = math.floor(x / grid_size)
    local grid_y = math.floor(y / grid_size)
    return string.format("%d_%d_%d", map_id, grid_x, grid_y)
end

function ZoneConsensus.normalizeAngle(angle)
    while angle < 0 do
        angle = angle + (2 * math.pi)
    end
    while angle >= (2 * math.pi) do
        angle = angle - (2 * math.pi)
    end
    return angle
end

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

    local strength = math.sqrt(mean_sin * mean_sin + mean_cos * mean_cos)
    local mean_angle = math.atan2(mean_sin, mean_cos)

    return ZoneConsensus.normalizeAngle(mean_angle), strength
end

function ZoneConsensus.calculateZoneConsensus(zone_id, players)
    local angles = {}

    for _, player in ipairs(players) do
        if player and player:IsAlive() and not player:IsBot() then
            local facing = player:GetO()
            table.insert(angles, facing)
        end
    end

    if #angles < MIN_PLAYERS_FOR_ZONE then
        return nil, 0, #angles
    end

    local mean_angle, strength = ZoneConsensus.averageAngles(angles)

    local existing = zone_consensus[zone_id]
    if existing and existing.angle then
        local blend_angles = {existing.angle, mean_angle}
        mean_angle, _ = ZoneConsensus.averageAngles(blend_angles)
        strength = (existing.strength * CONSENSUS_WEIGHT_DECAY) +
                   (strength * (1 - CONSENSUS_WEIGHT_DECAY))
    end

    return mean_angle, strength, #angles
end

function ZoneConsensus.getPlayersInZone(bot)
    local bx, by, bz = bot:GetLocation()
    local map_id = bot:GetMapId()
    local players = {}

    local all_players = GetPlayersInWorld()
    if not all_players then return players end

    for _, player in pairs(all_players) do
        if player and player:IsAlive() and player:GetMapId() == map_id then
            local px, py = player:GetLocation()
            local distSq = Movement.squaredDistance(bx, by, px, py)

            if distSq <= (ZONE_RANGE * ZONE_RANGE) then
                table.insert(players, player)
            end
        end
    end

    return players
end

function ZoneConsensus.updateZoneConsensus(bot)
    local bx, by = bot:GetLocation()
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

function ZoneConsensus.getConsensusForBot(bot)
    local bx, by = bot:GetLocation()
    local map_id = bot:GetMapId()
    local zone_id = ZoneConsensus.getZoneId(bx, by, map_id)

    return zone_consensus[zone_id]
end

function ZoneConsensus.getBotMomentum(bot)
    local bot_guid = bot:GetGUID()
    local momentum = bot_momentum[bot_guid]

    if momentum then
        return momentum.angle, momentum.speed
    end

    return bot:GetO(), 0
end

function ZoneConsensus.updateBotMomentum(bot, new_angle)
    local bot_guid = bot:GetGUID()
    local current_angle, current_speed = ZoneConsensus.getBotMomentum(bot)

    local blend = {current_angle, new_angle}
    local blended_angle, _ = ZoneConsensus.averageAngles(blend)

    bot_momentum[bot_guid] = {
        angle = blended_angle,
        speed = 1.0
    }

    return blended_angle
end

function ZoneConsensus.calculateDriftDirection(bot)
    local consensus = ZoneConsensus.getConsensusForBot(bot)
    local bot_angle, bot_speed = ZoneConsensus.getBotMomentum(bot)

    if not consensus or consensus.strength < 0.1 then
        return bot_angle
    end

    local angles = {bot_angle, consensus.angle}
    local weights = {MOMENTUM_WEIGHT, CONSENSUS_WEIGHT * consensus.strength}

    local sum_sin = math.sin(bot_angle) * weights[1] +
                    math.sin(consensus.angle) * weights[2]
    local sum_cos = math.cos(bot_angle) * weights[1] +
                    math.cos(consensus.angle) * weights[2]

    local final_angle = math.atan2(sum_sin, sum_cos)
    return ZoneConsensus.normalizeAngle(final_angle)
end

function ZoneConsensus.getDriftDestination(bot)
    local bx, by, bz = bot:GetLocation()
    local drift_angle = ZoneConsensus.calculateDriftDirection(bot)

    local dest_x = bx + math.cos(drift_angle) * IDLE_DRIFT_DISTANCE
    local dest_y = by + math.sin(drift_angle) * IDLE_DRIFT_DISTANCE

    local map = bot:GetMap()
    local dest_z = bz
    if map then
        dest_z = map:GetHeight(dest_x, dest_y) or bz
    end

    return dest_x, dest_y, dest_z, drift_angle
end

function ZoneConsensus.driftWithConsensus(bot)
    if not bot or not bot:IsBot() then return false end
    if not bot:IsAlive() then return false end
    if bot:IsInCombat() then return false end

    local isResting = bot:GetData("resting")
    if isResting then return false end

    ZoneConsensus.updateZoneConsensus(bot)

    local dest_x, dest_y, dest_z, angle = ZoneConsensus.getDriftDestination(bot)

    ZoneConsensus.updateBotMomentum(bot, angle)

    bot:MoveTo(0, dest_x, dest_y, dest_z, false)

    return true
end

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

function ZoneConsensus.cleanupOldZones()
    print("[DEBUG ZoneConsensus.cleanupOldZones] CALLBACK FIRED")
    local current_time = os.time()
    local stale_threshold = 60

    for zone_id, data in pairs(zone_consensus) do
        if current_time - (data.last_update or 0) > stale_threshold then
            zone_consensus[zone_id] = nil
        end
    end
end

function ZoneConsensus.periodicUpdate(bot)
    if ZoneConsensus.handleDispersion(bot) then
        return
    end

    ZoneConsensus.driftWithConsensus(bot)
end

function ZoneConsensus.initialize()
    print("[ZoneConsensus] System initialized (per-player events via periodic_events.lua)")
end

function ZoneConsensus.periodicCleanup(player)
    ZoneConsensus.cleanupOldZones()
end

ZoneConsensus.initialize()
print("[ZoneConsensus] Behavior loaded - periodic registration via periodic_events.lua")
