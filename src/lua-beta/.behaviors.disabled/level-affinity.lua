
require("movement")

LevelAffinity = {}

package.loaded["behaviors/level-affinity"] = LevelAffinity

MAX_LEVEL             = 80
LEVEL_CHECK_INTERVAL  = 5000
AFFINITY_RADIUS       = 100
PROXIMITY_THRESHOLD   = 0.50
OPPOSITE_SPECTRUM     = 0.75
FRESH_LOGIN_WINDOW    = 300
LEVEL_COST_WEIGHT     = 2.0
PROXIMITY_COST_WEIGHT = 1.0

local bot_affinities = {}
local player_login_times = {}

function LevelAffinity.getLevelRange(bot_level)
    local range = MAX_LEVEL * PROXIMITY_THRESHOLD
    local half_range = range / 2

    local min_peer = math.max(1, bot_level - half_range)
    local max_peer = math.min(MAX_LEVEL, bot_level + half_range)

    return min_peer, max_peer
end

function LevelAffinity.isWithinPeerRange(bot_level, target_level)
    local min_peer, max_peer = LevelAffinity.getLevelRange(bot_level)
    return target_level >= min_peer and target_level <= max_peer
end

function LevelAffinity.getLevelCost(bot_level, target_level)
    local diff = math.abs(bot_level - target_level)
    return (diff * diff) * LEVEL_COST_WEIGHT
end

function LevelAffinity.getProximityCost(bot, target)
    local bx, by = bot:GetLocation()
    local tx, ty = target:GetLocation()
    local distSq = Movement.squaredDistance(bx, by, tx, ty)
    return math.sqrt(distSq) * PROXIMITY_COST_WEIGHT
end

function LevelAffinity.isMaxLevel(unit)
    return unit:GetLevel() >= MAX_LEVEL
end

function LevelAffinity.isNewPlayer(unit)
    if unit:GetLevel() == 1 then return true end

    local guid = unit:GetGUID()
    local login_time = player_login_times[guid]

    if login_time then
        local elapsed = os.time() - login_time
        if elapsed < FRESH_LOGIN_WINDOW then
            return true
        end
    end

    return false
end

function LevelAffinity.getOppositeSpectrumTarget(bot_level)
    local midpoint = MAX_LEVEL / 2

    if bot_level <= midpoint then
        local distance_to_max = MAX_LEVEL - bot_level
        return bot_level + (distance_to_max * OPPOSITE_SPECTRUM)
    else
        local distance_to_min = bot_level - 1
        return bot_level - (distance_to_min * OPPOSITE_SPECTRUM)
    end
end

function LevelAffinity.calculateAffinityScore(bot, target, has_peers)
    local bot_level = bot:GetLevel()
    local target_level = target:GetLevel()

    local level_cost = LevelAffinity.getLevelCost(bot_level, target_level)
    local proximity_cost = LevelAffinity.getProximityCost(bot, target)

    if LevelAffinity.isWithinPeerRange(bot_level, target_level) then
        return proximity_cost + (level_cost * 0.1)
    end

    if not has_peers then
        local ideal_target = LevelAffinity.getOppositeSpectrumTarget(bot_level)
        local spectrum_diff = math.abs(target_level - ideal_target)
        return (spectrum_diff * spectrum_diff) + (proximity_cost * 0.5)
    end

    return level_cost + (proximity_cost * 0.1)
end

function LevelAffinity.applySpecialRules(bot, target, base_score)
    local bot_level = bot:GetLevel()
    local target_level = target:GetLevel()
    local score = base_score

    if LevelAffinity.isMaxLevel(target) then
        if bot_level < MAX_LEVEL / 2 then
            score = score * 0.5
        end
        if bot:IsInCombat() then
            score = score * 0.3
        end
    end

    if bot_level == 1 then
        if LevelAffinity.isNewPlayer(target) then
            score = score * 0.2
        elseif target_level == 1 then
            score = score * 0.4
        elseif LevelAffinity.isMaxLevel(target) then
            score = score * 0.6
        end
    end

    return score
end

function LevelAffinity.hasPeersInRange(bot, players)
    local bot_level = bot:GetLevel()

    for _, player in ipairs(players) do
        if player and player:IsAlive() then
            if LevelAffinity.isWithinPeerRange(bot_level, player:GetLevel()) then
                return true
            end
        end
    end

    return false
end

function LevelAffinity.findBestTarget(bot)
    local nearby = bot:GetPlayersInRange(AFFINITY_RADIUS)
    if not nearby or #nearby == 0 then return nil end

    local has_peers = LevelAffinity.hasPeersInRange(bot, nearby)
    local best_target = nil
    local best_score = math.huge

    for _, player in ipairs(nearby) do
        if player and player:IsAlive() and not player:IsBot() then
            local score = LevelAffinity.calculateAffinityScore(bot, player, has_peers)
            score = LevelAffinity.applySpecialRules(bot, player, score)

            if score < best_score then
                best_score = score
                best_target = player
            end
        end
    end

    return best_target, best_score
end

function LevelAffinity.updateAffinity(bot)
    if not bot or not bot:IsBot() then return nil end
    if not bot:IsAlive() then return nil end

    local target, score = LevelAffinity.findBestTarget(bot)
    local bot_guid = bot:GetGUID()

    if target then
        bot_affinities[bot_guid] = {
            target_guid = target:GetGUID(),
            score = score,
            last_update = os.time()
        }
    else
        bot_affinities[bot_guid] = nil
    end

    return target
end

function LevelAffinity.getAffinityTarget(bot)
    local bot_guid = bot:GetGUID()
    local affinity = bot_affinities[bot_guid]

    if not affinity then return nil end

    local target = GetPlayerByGUID(affinity.target_guid)
    if target and target:IsAlive() then
        return target
    end

    return nil
end

function LevelAffinity.getIdleDestination(bot)
    local target = LevelAffinity.getAffinityTarget(bot)
    if not target then return nil, nil, nil end

    local tx, ty, tz = target:GetLocation()

    local bot_guid = bot:GetGUID()
    local angle = (bot_guid % 360) * (math.pi / 180)
    local offset = 5 + (bot_guid % 10)

    local dest_x = tx + math.cos(angle) * offset
    local dest_y = ty + math.sin(angle) * offset

    local map = bot:GetMap()
    local dest_z = tz
    if map then
        dest_z = map:GetHeight(dest_x, dest_y) or tz
    end

    return dest_x, dest_y, dest_z
end

function LevelAffinity.driftToAffinity(bot)
    if not bot or not bot:IsBot() then return false end
    if bot:IsInCombat() then return false end

    local isResting = bot:GetData("resting")
    if isResting then return false end

    local dest_x, dest_y, dest_z = LevelAffinity.getIdleDestination(bot)
    if not dest_x then return false end

    local bx, by = bot:GetLocation()
    local distSq = Movement.squaredDistance(bx, by, dest_x, dest_y)

    if distSq < 25 then
        return false
    end

    bot:MoveTo(0, dest_x, dest_y, dest_z, false)
    return true
end

function LevelAffinity.trackLogin(player)
    if player then
        player_login_times[player:GetGUID()] = os.time()
    end
end

function LevelAffinity.trackLogout(player)
    if player then
        player_login_times[player:GetGUID()] = nil
    end
end

function LevelAffinity.periodicUpdate(bot)
    LevelAffinity.updateAffinity(bot)
    LevelAffinity.driftToAffinity(bot)
end

function LevelAffinity.getExpShare(base_exp, killer_level, helper_level)
    if helper_level <= 0 then return 0 end

    local ratio = killer_level / helper_level
    return math.floor(base_exp / ratio)
end

print("[LevelAffinity] Behavior loaded - periodic registration via periodic_events.lua")
