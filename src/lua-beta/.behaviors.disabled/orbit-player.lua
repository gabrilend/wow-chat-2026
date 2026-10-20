
require("movement")
require("behaviors/avoid-monsters")

OrbitPlayer = {}

package.loaded["behaviors/orbit-player"] = OrbitPlayer

ORBIT_RADIUS_IDLE    =  8
ORBIT_RADIUS_COMBAT  =  5
ORBIT_RADIUS_TRAVEL  = 12
ORBIT_SPEED          =  1
UPDATE_INTERVAL      = 2000
REPOSITION_THRESHOLD =  3
CLUMP_AVOID_RADIUS   =  2
MAX_PARTY_SLOTS      =  5

function OrbitPlayer.getLeader(bot)
    local leader = bot:GetGroup()
    if leader then
        leader = leader:GetLeader()
        if leader and leader ~= bot then
            return leader
        end
    end

    local player = bot:GetNearestPlayer(100)
    if player and not player:IsBot() then
        return player
    end

    return nil
end

function OrbitPlayer.getOrbitSlot(bot)
    local group = bot:GetGroup()

    if group then
        local members = group:GetMembers()
        for i, member in ipairs(members) do
            if member and member:GetGUID() == bot:GetGUID() then
                return i
            end
        end
    end

    local guid = bot:GetGUID()
    return (guid % MAX_PARTY_SLOTS) + 1
end

function OrbitPlayer.getOrbitAngle(slot, totalSlots)
    local angleStep = 6.28 / math.max(totalSlots, 1)
    return angleStep * (slot - 1)
end

function OrbitPlayer.getOrbitRadius(bot, leader)
    if bot:IsInCombat() or (leader and leader:IsInCombat()) then
        return ORBIT_RADIUS_COMBAT
    end

    if leader then
        local isMoving = leader:IsMoving()
        if isMoving then
            return ORBIT_RADIUS_TRAVEL
        end
    end

    return ORBIT_RADIUS_IDLE
end

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
end

function OrbitPlayer.calculateTargetPosition(bot)
    local leader = OrbitPlayer.getLeader(bot)
    if not leader then return nil, nil, nil end

    local lx, ly, lz = leader:GetLocation()
    local radius     = OrbitPlayer.getOrbitRadius(bot, leader)
    local slot       = OrbitPlayer.getOrbitSlot(bot)
    local totalSlots = OrbitPlayer.getPartyBotCount(bot)
    local baseAngle  = OrbitPlayer.getOrbitAngle(slot, totalSlots)

    local time   = os.time()
    local drift  = math.sin(time * 0.1 + slot) * 0.3
    local angle  = baseAngle + drift

    local tx = lx + math.cos(angle) * radius
    local ty = ly + math.sin(angle) * radius

    local map = bot:GetMap()
    local tz  = lz
    if map then
        tz = map:GetHeight(tx, ty) or lz
    end

    return tx, ty, tz
end

function OrbitPlayer.needsRepositioning(bot, tx, ty)
    if not tx or not ty then return false end

    local bx, by = bot:GetLocation()
    local distSq = Movement.squaredDistance(bx, by, tx, ty)

    return distSq > (REPOSITION_THRESHOLD * REPOSITION_THRESHOLD)
end

function OrbitPlayer.avoidClumping(bot, tx, ty)
    local bots = bot:GetPlayersInRange(CLUMP_AVOID_RADIUS * 3, 0, 1)

    if not bots then return tx, ty end

    local pushX, pushY = 0, 0

    for _, other in pairs(bots) do
        if other and other:IsBot() and other:GetGUID() ~= bot:GetGUID() then
            local ox, oy = other:GetLocation()
            local distSq = Movement.squaredDistance(tx, ty, ox, oy)

            if distSq < (CLUMP_AVOID_RADIUS * CLUMP_AVOID_RADIUS) then
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

    if pushX ~= 0 or pushY ~= 0 then
        local pushLen = math.sqrt(pushX * pushX + pushY * pushY)
        if pushLen > 0 then
            tx = tx + (pushX / pushLen) * CLUMP_AVOID_RADIUS
            ty = ty + (pushY / pushLen) * CLUMP_AVOID_RADIUS
        end
    end

    return tx, ty
end

function OrbitPlayer.updatePosition(bot)
    if not bot or not bot:IsBot() then return false end
    if not bot:IsAlive()          then return false end
    if bot:IsInCombat()           then return false end

    local shouldFlee = AvoidMonsters.shouldFlee(bot)
    if shouldFlee then
        AvoidMonsters.flee(bot)
        return true
    end

    local isResting = bot:GetData("resting")
    if isResting then return false end

    local tx, ty, tz = OrbitPlayer.calculateTargetPosition(bot)
    if not tx then return false end

    tx, ty = OrbitPlayer.avoidClumping(bot, tx, ty)

    if not OrbitPlayer.needsRepositioning(bot, tx, ty) then
        return false
    end

    local map = bot:GetMap()
    if map then
        tz = map:GetHeight(tx, ty) or tz
    end

    bot:MoveTo(0, tx, ty, tz, false)

    return true
end

print("[OrbitPlayer] Behavior loaded - periodic registration via periodic_events.lua")
