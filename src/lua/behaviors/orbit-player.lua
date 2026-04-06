-- {{{ Everland Ghostsong - Orbit Player Behavior
-- Bots maintain dynamic positions around their leader
-- Creates natural formation and social spacing
--
-- Config values at top. Git greps are cheap.
-- Vertical alignment connects related values.
-- Dense math, few functions.
-- }}}

require("movement")
require("behaviors/avoid-monsters")

OrbitPlayer = {}

-- {{{ Configuration
ORBIT_RADIUS_IDLE    =  8   -- yards from leader when idle
ORBIT_RADIUS_COMBAT  =  5   -- yards from leader in combat
ORBIT_RADIUS_TRAVEL  = 12   -- yards from leader when moving
ORBIT_SPEED          =  1   -- base angular speed multiplier
UPDATE_INTERVAL      = 2000 -- ms between position updates
REPOSITION_THRESHOLD =  3   -- yards difference to trigger movement
CLUMP_AVOID_RADIUS   =  2   -- minimum distance between bots
MAX_PARTY_SLOTS      =  5   -- max bots in orbit calculation
-- }}}

-- {{{ OrbitPlayer.getLeader
-- Find the bot's party leader or master
function OrbitPlayer.getLeader(bot)
    -- try party leader first
    local leader = bot:GetGroup()
    if leader then
        leader = leader:GetLeader()
        if leader and leader ~= bot then
            return leader
        end
    end

    -- fallback: nearest player
    local player = bot:GetNearestPlayer(100)
    if player and not player:IsBot() then
        return player
    end

    return nil
end -- }}}

-- {{{ OrbitPlayer.getOrbitSlot
-- Calculate which orbit slot this bot occupies
-- Based on party position or guid hash
function OrbitPlayer.getOrbitSlot(bot)
    local group = bot:GetGroup()

    if group then
        -- use party position
        local members = group:GetMembers()
        for i, member in ipairs(members) do
            if member and member:GetGUID() == bot:GetGUID() then
                return i
            end
        end
    end

    -- fallback: use guid mod
    local guid = bot:GetGUID()
    return (guid % MAX_PARTY_SLOTS) + 1
end -- }}}

-- {{{ OrbitPlayer.getOrbitAngle
-- Calculate starting angle for this bot's orbit slot
function OrbitPlayer.getOrbitAngle(slot, totalSlots)
    -- distribute evenly around circle
    local angleStep = 6.28 / math.max(totalSlots, 1)
    return angleStep * (slot - 1)
end -- }}}

-- {{{ OrbitPlayer.getOrbitRadius
-- Determine radius based on state
function OrbitPlayer.getOrbitRadius(bot, leader)
    if bot:IsInCombat() or (leader and leader:IsInCombat()) then
        return ORBIT_RADIUS_COMBAT
    end

    -- check if leader is moving
    if leader then
        local isMoving = leader:IsMoving()
        if isMoving then
            return ORBIT_RADIUS_TRAVEL
        end
    end

    return ORBIT_RADIUS_IDLE
end -- }}}

-- {{{ OrbitPlayer.getPartyBotCount
-- Count bots in party for spacing calculation
function OrbitPlayer.getPartyBotCount(bot)
    local group = bot:GetGroup()
    if not group then return 1 end

    local count = 0
    local members = group:GetMembers()
    for _, member in ipairs(members) do
        if member and member:IsBot() then
            count = count + 1
        end
    end

    return math.max(count, 1)
end -- }}}

-- {{{ OrbitPlayer.calculateTargetPosition
-- Calculate where this bot should be
function OrbitPlayer.calculateTargetPosition(bot)
    local leader = OrbitPlayer.getLeader(bot)
    if not leader then return nil, nil, nil end

    local lx, ly, lz = leader:GetPosition()
    local radius     = OrbitPlayer.getOrbitRadius(bot, leader)
    local slot       = OrbitPlayer.getOrbitSlot(bot)
    local totalSlots = OrbitPlayer.getPartyBotCount(bot)
    local baseAngle  = OrbitPlayer.getOrbitAngle(slot, totalSlots)

    -- add time-based drift for natural movement
    local time   = os.time()
    local drift  = math.sin(time * 0.1 + slot) * 0.3
    local angle  = baseAngle + drift

    -- calculate position
    local tx = lx + math.cos(angle) * radius
    local ty = ly + math.sin(angle) * radius

    -- get ground height
    local map = bot:GetMap()
    local tz  = lz
    if map then
        tz = map:GetHeight(tx, ty) or lz
    end

    return tx, ty, tz
end -- }}}

-- {{{ OrbitPlayer.needsRepositioning
-- Check if bot needs to move to target position
function OrbitPlayer.needsRepositioning(bot, tx, ty)
    if not tx or not ty then return false end

    local bx, by = bot:GetPosition()
    local distSq = Movement.squaredDistance(bx, by, tx, ty)

    return distSq > (REPOSITION_THRESHOLD * REPOSITION_THRESHOLD)
end -- }}}

-- {{{ OrbitPlayer.avoidClumping
-- Adjust position to avoid other nearby bots
function OrbitPlayer.avoidClumping(bot, tx, ty)
    local bots = bot:GetUnitsInRange(CLUMP_AVOID_RADIUS * 3, 0)  -- get nearby units

    if not bots then return tx, ty end

    local pushX, pushY = 0, 0

    for _, other in pairs(bots) do
        if other and other:IsBot() and other:GetGUID() ~= bot:GetGUID() then
            local ox, oy = other:GetPosition()
            local distSq = Movement.squaredDistance(tx, ty, ox, oy)

            if distSq < (CLUMP_AVOID_RADIUS * CLUMP_AVOID_RADIUS) then
                -- push away from other bot
                local dx = tx - ox
                local dy = ty - oy
                local dist = math.sqrt(distSq)

                if dist > 0 then
                    pushX = pushX + (dx / dist)
                    pushY = pushY + (dy / dist)
                end
            end
        end
    end

    -- apply push
    if pushX ~= 0 or pushY ~= 0 then
        local pushLen = math.sqrt(pushX * pushX + pushY * pushY)
        if pushLen > 0 then
            tx = tx + (pushX / pushLen) * CLUMP_AVOID_RADIUS
            ty = ty + (pushY / pushLen) * CLUMP_AVOID_RADIUS
        end
    end

    return tx, ty
end -- }}}

-- {{{ OrbitPlayer.updatePosition
-- Main update function - calculate and move to orbit position
function OrbitPlayer.updatePosition(bot)
    if not bot or not bot:IsBot() then return false end
    if not bot:IsAlive()          then return false end
    if bot:IsInCombat()           then return false end  -- let combat AI handle positioning

    -- check for danger first
    local shouldFlee = AvoidMonsters.shouldFlee(bot)
    if shouldFlee then
        AvoidMonsters.flee(bot)
        return true
    end

    -- check if resting
    local isResting = bot:GetData("resting")
    if isResting then return false end

    -- calculate target position
    local tx, ty, tz = OrbitPlayer.calculateTargetPosition(bot)
    if not tx then return false end

    -- avoid clumping with other bots
    tx, ty = OrbitPlayer.avoidClumping(bot, tx, ty)

    -- check if we need to move
    if not OrbitPlayer.needsRepositioning(bot, tx, ty) then
        return false
    end

    -- update ground height after clump adjustment
    local map = bot:GetMap()
    if map then
        tz = map:GetHeight(tx, ty) or tz
    end

    -- move to position
    bot:MoveTo(0, tx, ty, tz, false)

    return true
end -- }}}

-- {{{ Module initialization
-- NOTE: Per-bot registration moved to periodic_events.lua (issue 160)
-- This file exposes: OrbitPlayer.updatePosition(bot)
print("[OrbitPlayer] Behavior loaded - periodic registration via periodic_events.lua")
-- }}}
