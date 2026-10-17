-- {{{ Everland Ghostsong - Level Affinity System
-- Bots cluster around players of similar level
-- Uses traveling salesman cost based on level difference
-- Implements the 50% threshold and 75% opposite spectrum rules
--
-- Issue: 133-gesture-command-system-kneel-convoy.md
-- Concept Catalog: 201-230
-- }}}

require("movement")

LevelAffinity = {}

-- Register in package.loaded so require() is a no-op after ALE loads this
-- Must be AFTER LevelAffinity table is created so require() returns the module
package.loaded["behaviors/level-affinity"] = LevelAffinity

-- {{{ Configuration
MAX_LEVEL             = 80    -- WotLK max level
LEVEL_CHECK_INTERVAL  = 5000  -- ms between affinity recalculation
AFFINITY_RADIUS       = 100   -- yards to search for players
PROXIMITY_THRESHOLD   = 0.50  -- 50% of level range = prefer proximity
OPPOSITE_SPECTRUM     = 0.75  -- 75% toward opposite when no peers
FRESH_LOGIN_WINDOW    = 300   -- seconds to count as "fresh login"
LEVEL_COST_WEIGHT     = 2.0   -- multiplier for level difference cost
PROXIMITY_COST_WEIGHT = 1.0   -- multiplier for distance cost
-- }}}

-- {{{ State storage
local bot_affinities = {}     -- [bot_guid] = {target_guid, score, last_update}
local player_login_times = {} -- [player_guid] = login_timestamp
-- }}}

-- {{{ LevelAffinity.getLevelRange
-- Calculate the effective level range for affinity decisions
-- Returns min_level, max_level for "peer" consideration
function LevelAffinity.getLevelRange(bot_level)
    local range = MAX_LEVEL * PROXIMITY_THRESHOLD
    local half_range = range / 2

    local min_peer = math.max(1, bot_level - half_range)
    local max_peer = math.min(MAX_LEVEL, bot_level + half_range)

    return min_peer, max_peer
end
-- }}}

-- {{{ LevelAffinity.isWithinPeerRange
-- Check if a level falls within the peer range
function LevelAffinity.isWithinPeerRange(bot_level, target_level)
    local min_peer, max_peer = LevelAffinity.getLevelRange(bot_level)
    return target_level >= min_peer and target_level <= max_peer
end
-- }}}

-- {{{ LevelAffinity.getLevelCost
-- Calculate affinity cost based on level difference
-- Lower cost = higher affinity
function LevelAffinity.getLevelCost(bot_level, target_level)
    local diff = math.abs(bot_level - target_level)
    -- Squared difference penalizes large gaps more severely
    return (diff * diff) * LEVEL_COST_WEIGHT
end
-- }}}

-- {{{ LevelAffinity.getProximityCost
-- Calculate cost based on distance
function LevelAffinity.getProximityCost(bot, target)
    local bx, by = bot:GetLocation()
    local tx, ty = target:GetLocation()
    local distSq = Movement.squaredDistance(bx, by, tx, ty)
    return math.sqrt(distSq) * PROXIMITY_COST_WEIGHT
end
-- }}}

-- {{{ LevelAffinity.isMaxLevel
-- Check if a unit is at max level
function LevelAffinity.isMaxLevel(unit)
    return unit:GetLevel() >= MAX_LEVEL
end
-- }}}

-- {{{ LevelAffinity.isNewPlayer
-- Check if a unit is level 1 or freshly logged in
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
-- }}}

-- {{{ LevelAffinity.getOppositeSpectrumTarget
-- When no peers exist, find 75% toward opposite end of level range
-- Level 1-40: seek higher levels (toward 80)
-- Level 41-80: seek lower levels (toward 1)
function LevelAffinity.getOppositeSpectrumTarget(bot_level)
    local midpoint = MAX_LEVEL / 2

    if bot_level <= midpoint then
        -- Low level: 75% toward max
        local distance_to_max = MAX_LEVEL - bot_level
        return bot_level + (distance_to_max * OPPOSITE_SPECTRUM)
    else
        -- High level: 75% toward min
        local distance_to_min = bot_level - 1
        return bot_level - (distance_to_min * OPPOSITE_SPECTRUM)
    end
end
-- }}}

-- {{{ LevelAffinity.calculateAffinityScore
-- Combined cost function for traveling salesman heuristic
-- Considers level difference, proximity, and special rules
function LevelAffinity.calculateAffinityScore(bot, target, has_peers)
    local bot_level = bot:GetLevel()
    local target_level = target:GetLevel()

    local level_cost = LevelAffinity.getLevelCost(bot_level, target_level)
    local proximity_cost = LevelAffinity.getProximityCost(bot, target)

    -- Within peer range: prefer proximity
    if LevelAffinity.isWithinPeerRange(bot_level, target_level) then
        return proximity_cost + (level_cost * 0.1)
    end

    -- No peers: 75% opposite spectrum rule
    if not has_peers then
        local ideal_target = LevelAffinity.getOppositeSpectrumTarget(bot_level)
        local spectrum_diff = math.abs(target_level - ideal_target)
        return (spectrum_diff * spectrum_diff) + (proximity_cost * 0.5)
    end

    -- Outside peer range with peers available: prefer level match
    return level_cost + (proximity_cost * 0.1)
end
-- }}}

-- {{{ LevelAffinity.applySpecialRules
-- Apply max level and level 1 special rules
-- Returns modified score (lower = better)
function LevelAffinity.applySpecialRules(bot, target, base_score)
    local bot_level = bot:GetLevel()
    local target_level = target:GetLevel()
    local score = base_score

    -- Max level players attract struggling players and noobs
    if LevelAffinity.isMaxLevel(target) then
        -- Max level is helpful to low levels and those in combat
        if bot_level < MAX_LEVEL / 2 then
            score = score * 0.5  -- Strong attraction
        end
        if bot:IsInCombat() then
            score = score * 0.3  -- Very strong attraction when struggling
        end
    end

    -- Level 1 bots follow fresh logins, level 1s, or max levels
    if bot_level == 1 then
        if LevelAffinity.isNewPlayer(target) then
            score = score * 0.2  -- Strongest attraction to fresh players
        elseif target_level == 1 then
            score = score * 0.4  -- Strong peer attraction
        elseif LevelAffinity.isMaxLevel(target) then
            score = score * 0.6  -- Attracted to mentors
        end
    end

    return score
end
-- }}}

-- {{{ LevelAffinity.hasPeersInRange
-- Check if there are any same-level peers available
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
-- }}}

-- {{{ LevelAffinity.findBestTarget
-- Find the player with highest affinity (lowest cost)
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
-- }}}

-- {{{ LevelAffinity.updateAffinity
-- Update bot's current affinity target
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
-- }}}

-- {{{ LevelAffinity.getAffinityTarget
-- Get current affinity target for a bot
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
-- }}}

-- {{{ LevelAffinity.getIdleDestination
-- Calculate where bot should drift when idle
-- Uses affinity target's position with some offset
function LevelAffinity.getIdleDestination(bot)
    local target = LevelAffinity.getAffinityTarget(bot)
    if not target then return nil, nil, nil end

    local tx, ty, tz = target:GetLocation()

    -- Add some random offset to avoid stacking
    local bot_guid = bot:GetGUID()
    local angle = (bot_guid % 360) * (math.pi / 180)
    local offset = 5 + (bot_guid % 10)

    local dest_x = tx + math.cos(angle) * offset
    local dest_y = ty + math.sin(angle) * offset

    -- Get ground height
    local map = bot:GetMap()
    local dest_z = tz
    if map then
        dest_z = map:GetHeight(dest_x, dest_y) or tz
    end

    return dest_x, dest_y, dest_z
end
-- }}}

-- {{{ LevelAffinity.driftToAffinity
-- Move bot toward affinity target position
function LevelAffinity.driftToAffinity(bot)
    if not bot or not bot:IsBot() then return false end
    if bot:IsInCombat() then return false end

    -- Check if resting
    local isResting = bot:GetData("resting")
    if isResting then return false end

    local dest_x, dest_y, dest_z = LevelAffinity.getIdleDestination(bot)
    if not dest_x then return false end

    -- Check if we're already close
    local bx, by = bot:GetLocation()
    local distSq = Movement.squaredDistance(bx, by, dest_x, dest_y)

    if distSq < 25 then  -- Within 5 yards
        return false
    end

    -- Drift toward destination
    bot:MoveTo(0, dest_x, dest_y, dest_z, false)
    return true
end
-- }}}

-- {{{ LevelAffinity.trackLogin
-- Track player login times for "fresh login" detection
-- Called by periodic_events.lua on login
function LevelAffinity.trackLogin(player)
    if player then
        player_login_times[player:GetGUID()] = os.time()
    end
end
-- }}}

-- {{{ LevelAffinity.trackLogout
-- Clean up login tracking on logout
-- Called by periodic_events.lua on logout
function LevelAffinity.trackLogout(player)
    if player then
        player_login_times[player:GetGUID()] = nil
    end
end
-- }}}

-- {{{ LevelAffinity.periodicUpdate
-- Periodic affinity recalculation for bot
-- Called by periodic_events.lua on timer
function LevelAffinity.periodicUpdate(bot)
    LevelAffinity.updateAffinity(bot)
    LevelAffinity.driftToAffinity(bot)
end
-- }}}

-- {{{ LevelAffinity.getExpShare
-- Calculate proportional EXP sharing
-- base_exp / (killer_level / helper_level)
function LevelAffinity.getExpShare(base_exp, killer_level, helper_level)
    if helper_level <= 0 then return 0 end

    local ratio = killer_level / helper_level
    return math.floor(base_exp / ratio)
end
-- }}}

-- {{{ Module initialization
-- NOTE: Per-bot registration moved to periodic_events.lua (issue 610)
-- This file exposes: trackLogin, trackLogout, periodicUpdate
print("[LevelAffinity] Behavior loaded - periodic registration via periodic_events.lua")
-- }}}
