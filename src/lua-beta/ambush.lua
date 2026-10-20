
            Ambush = {}
local AmbushQueues = {}

local AmbushMemory = {}

AMBUSH_BASE_INTERVAL   =  40000
AMBUSH_INTERVAL_MIN    =  10000
AMBUSH_INTERVAL_SOFT   = 100000
AMBUSH_INTERVAL_HARD   = 200000
AMBUSH_JITTER_MIN      =   2000
AMBUSH_JITTER_MAX      =   4000
AMBUSH_JITTER_STEP     =   1000
AMBUSH_MIN_DISTANCE    =    120
AMBUSH_MAX_DISTANCE    =    160
AMBUSH_GRACE_PERIOD    =  30000
AMBUSH_OFFLINE_RESET   =    600
AMBUSH_MAX_AMBUSHERS   =      3
AMBUSH_RETRY_MIN_DIST  =     30

Ambush.HOLDS = {
    { why = "player is sitting down", holds = function(p) return not p:IsStandState() end },
    { why = "player is dead",         holds = function(p) return p:IsDead() end },
    { why = "player is in water",     holds = function(p) return p:IsInWater() end },
    { why = "too many ambushers",     holds = function(p) return (p:GetData("num-ambushers") or 0) >= AMBUSH_MAX_AMBUSHERS end },
    { why = "in a boss fight",        holds = function(p) return p:GetData("is-in-boss-fight") == true end },
}

function Ambush.getJitterMagnitude()
    local steps = (AMBUSH_JITTER_MAX - AMBUSH_JITTER_MIN) / AMBUSH_JITTER_STEP
    return AMBUSH_JITTER_MIN + (math.random(0, steps) * AMBUSH_JITTER_STEP)
end

function Ambush.getJitterSign(currentInterval)
    if currentInterval <= AMBUSH_INTERVAL_MIN then
        return 1
    end

    if currentInterval >= AMBUSH_INTERVAL_HARD then
        if math.random(1, 5) == 1 then return 1
                                  else return -1
        end
    end

    if currentInterval >= AMBUSH_INTERVAL_SOFT then
        if math.random(1, 3) == 1 then return 1
                                  else return -1
        end
    end

    if math.random(0, 1) == 0 then return -1
                              else return 1
    end
end

function Ambush.memoryOf(player)
    local low = player:GetGUIDLow()
    AmbushMemory[low] = AmbushMemory[low] or {}
    return AmbushMemory[low]
end

function Ambush.getNextInterval(player)
    local memory          = Ambush.memoryOf(player)
    local currentInterval = memory.interval or AMBUSH_BASE_INTERVAL

    local magnitude = Ambush.getJitterMagnitude()
    local sign      = Ambush.getJitterSign(currentInterval)
    local offset    = sign * magnitude

    local newInterval = currentInterval + offset

    if newInterval < AMBUSH_INTERVAL_MIN then
        newInterval = AMBUSH_INTERVAL_MIN
    end

    memory.interval = newInterval

    print("[Ambush] Interval walk: " .. (currentInterval / 1000) .. "s → " .. (newInterval / 1000) .. "s (offset " .. (offset / 1000) .. "s)")

    return newInterval
end

Ambush.BANNED_CREATURE_IDS = { 17887, 19416, 2673,  3569,  16422, 16423,
                               16437, 16438, 17206, 1946,  5893,  4789,
                               5894,  7050,  7067,  7310,  7849,  5723,
                               11876, 17207, 2794,  11560, 11195, 13736,
                               7767,  6388,  14638, 14639, 14603, 14604,
                               14640, 8608,  1800,  1801,  4476,  22408,
                               13022, 13279, 7149,  10940, 10943, 14467,
                               28654, 28768, 10387, 10836, 11076, 18978,
                               10479, 10482, 11078, 19136, 14385, 16141,
                               16298, 16299, 16043, 20145, 20496, 22461,
                               16992, 17399, 17477, 19016, 16939, 20680,
                               21040, 20498, 20918, 21233, 21817, 21820,
                               21821, 19493, 19494, 19757, 19760, 19966,
                               19971, 20480, 20927, 20983, 22025, 25296,
                               19759, 21778, 21779, 25382, 26224, 18605,
                               18606, 19967, 20310, 20311, 20312, 20313,
                               20320, 20321, 20323, 20643, 20655, 21531,
                               21552, 21554, 21555, 21646, 21916, 22009,
                               22201, 22202, 22286, 22289, 23100, 23386,
                               24564, 24597, 24598, 24599, 24600, 24602,
                               24603, 24604, 24621, 24622, 24623, 24624,
                               24625, 24626, 24627, 25766, 30763, 30773,
                               18614, 20309, 20322, 20784, 20789, 22221,
                               22327, 22392, 24029, 24790, 26045, 26225,
                               27513, 25678, 25682, 26490, 26517, 26573,
                               26966, 25712, 25716, 26232, 26518, 26526,
                               26702, 26703, 26811, 26812, 27614, 27821,
                               29117, 29118, 26872, 28750, 28006, 28170,
                               28669, 28320, 28875, 28752, 30633, 26536,
                               30053, 30432, 31812, 33499, 29775, 30055,
                               30791, 30843, 30902, 30921, 30957, 30958,
                               30960, 31042, 31141, 31274, 31321, 31325,
                               31326, 31327, 31468, 31554, 31555, 31671,
                               31681, 31692, 31798, 32161, 32767, 32769,
                               33289, 3617,  6033,  5055,  5781,  314,
                               1160,  6071,
                             }

Ambush.BANNED_RARE_IDS = { 0,
                         }


function Ambush.spawnAndAttackPlayer(_eventID, _delay, _repeats, player)
    print("[Ambush] spawnAndAttackPlayer triggered for " .. player:GetName())

    local interval = Ambush.getNextInterval(player)
    player:RegisterEvent(Ambush.spawnAndAttackPlayer, interval, 1)

    for _, hold in ipairs(Ambush.HOLDS) do
        if hold.holds(player) then
            print("[Ambush] no ambush for " .. player:GetName() .. " - " .. hold.why)
            return
        end
    end

    local next = next
    local queue     = player:GetData("queue")     or {}
    local rareQueue = player:GetData("rare-queue") or {}

    print("[Ambush] Queue size: " .. #queue .. ", Rare queue size: " .. #rareQueue)

    if next(queue) == nil then
        local playerLevel = player:GetLevel()
        print("[Ambush] Queue empty, player level: " .. playerLevel)

        if next(rareQueue) == nil then
            if player:IsInGroup() and player:GetGroup():GetMembersCount() > 2 then
                print("[Ambush] Querying for group rare elites (rank 2)")
                Ambush.setupAmbushQueue(player, 2)
            else
                print("[Ambush] Querying for solo rares (rank 4)")
                Ambush.setupAmbushQueue(player, 4)
            end
        else
            print("[Ambush] Spawning rare, querying for normals (rank 0)")
            Ambush.setupAmbushQueue(player, 0)
            Ambush.randomSpawn(player, true)
        end
    else
        print("[Ambush] Spawning normal creature")
        Ambush.randomSpawn(player, false)
    end
end


function Ambush.setupAmbushQueue(player, rank)
    local playerLevel = player:GetLevel()
    local playerName  = player:GetName()
    WorldDBQueryAsync(
        "SELECT entry, minlevel, maxlevel, `rank` FROM creature_template "
        .. "WHERE minlevel <= " .. playerLevel
        .. " AND maxlevel >= " .. playerLevel
        .. " AND `rank` = " .. rank
        .. " AND npcflag = 0 AND lootid != 0 AND type IN (2, 3, 4, 5, 6, 9, 10);",
        function(query)
            local p = GetPlayerByName(playerName)
            if p then Ambush.pushToAmbushQueue(p, query, rank) end
        end)
end

Ambush.NEXT_RANK_WHEN_NONE = { [2] = 4, [4] = 0 }

function Ambush.pushToAmbushQueue(player, query, rank)

    local LEVEL_MAX = 0
    local LEVEL_MIN = 0
    local isRare = false
    local MaxQueueSize = 8
    local queueType = ""
    local next = next

    local creatures = {}
    if query then
        print("[Ambush] Query returned results")
        if query:GetUInt32(3) == 4 or
           query:GetUInt32(3) == 2 then isRare = true  queueType = "rare-queue"
                                   else isRare = false queueType = "queue"
        end
        repeat
            local creature = {
                  id       = query:GetUInt32(0),
                  minLevel = query:GetUInt32(1),
                  maxLevel = query:GetUInt32(2),
            }
            if not Ambush.isCreatureBanned(creature.id, isRare) then
                table.insert(creatures, creature)
            end
        until not query:NextRow()
    end

    if #creatures > MaxQueueSize then
        print("queue size too large, truncating")
        local tempTable = {}
        local creature
        for i = 1, MaxQueueSize do
            creature = table.remove(creatures, math.random(#creatures))
            table.insert(tempTable, creature)
        end
        creatures = tempTable
    end

    if #creatures == 0 then
        local nextRank = Ambush.NEXT_RANK_WHEN_NONE[rank]
        if nextRank then
            print("[Ambush] no rank " .. tostring(rank) .. " creature for " .. player:GetName()
                  .. " at level " .. player:GetLevel() .. "; asking for rank " .. nextRank)
            Ambush.setupAmbushQueue(player, nextRank)
        else
            print("[Ambush] ERROR: no normal creature fits " .. player:GetName() .. " at level "
                  .. player:GetLevel() .. " (creature types 2-6, 9, 10, with loot, no npc flags, not banned);"
                  .. " no ambush until the next tick asks again. to debug: does the world database"
                  .. " hold creature_template rows for this level? is the ban list (BANNED_CREATURE_IDS) eating them all?")
        end
        return
    end

    local playerLevel = player:GetLevel()
    if playerLevel == 0 then
        print("[Ambush] player level == 0 which is weird")
        return
    end

    local tempTable = player:GetData(queueType)
    local added = 0
    for _, creature in ipairs(creatures) do
        if playerLevel >= creature.minLevel - LEVEL_MIN and
           playerLevel <= creature.maxLevel + LEVEL_MAX then
            table.insert(tempTable, creature.id)
            added = added + 1
        end
    end
    player:SetData(queueType, tempTable)

    if added == 0 and Ambush.NEXT_RANK_WHEN_NONE[rank] then
        Ambush.setupAmbushQueue(player, Ambush.NEXT_RANK_WHEN_NONE[rank])
    end
end

function Ambush.addCreatureToQueue(player, creatureId, minLevel, maxLevel, isRare)
    local queueType
    if isRare then queueType = "rare-queue"
              else queueType = "queue"
    end
    local queue = player:GetData(queueType) or {}
    table.insert(queue, creatureId)
    player:SetData(queueType, queue)
end

function Ambush.isCreatureBanned(creatureId, isRare)

    if isRare then
        for _, id in ipairs(Ambush.BANNED_RARE_IDS) do
            if creatureId == id then return true end end

    else
    for _, id in ipairs(Ambush.BANNED_CREATURE_IDS) do
        if creatureId == id then return true end end
    end
    return false
end


function Ambush.randomSpawn(player, isRare)
    local ambush_min_distance = AMBUSH_MIN_DISTANCE
    local ambush_max_distance = AMBUSH_MAX_DISTANCE
    local queueType
    local corpseDespawnType
    local corpseDespawnTimer

    if isRare then
        queueType = "rare-queue"
        corpseDespawnType  = 8
        corpseDespawnTimer = nil
    else
        queueType = "queue"
        corpseDespawnType  = 6
        corpseDespawnTimer = 360 * 1000
    end

    local  playerID   = player:GetGUID()
    local playerQueue = player:GetData(queueType)
    local   randInt   = math.random(1, #playerQueue)
    local creatureId  = table.remove(playerQueue, randInt)
    player:SetData(queueType, playerQueue)



    if creatureId ~= 0 then
        local spawnFunction
        if player:IsMoving() then spawnFunction = Movement.getArcSpawnPosition
                             else spawnFunction = Movement.getPlusSpawnPosition end
        local x, y, z, o = player:GetLocation()
              x, y       = spawnFunction(x, y, ambush_min_distance, ambush_max_distance, o)
                    z    = player:GetMap():GetHeight(x, y) or player:GetZ()
                       o = math.random(0, 6.28)
        local creature = player:SpawnCreature(creatureId, x, y, z, o,
                                              corpseDespawnType,
                                              corpseDespawnTimer)
        if creature then

            local playerX, playerY = player:GetLocation()
            local tries = 0
            while creature:IsInWater() and tries < 3 do
                tries = tries + 1
                x, y = spawnFunction(playerX, playerY, ambush_min_distance, ambush_max_distance, o)
                z    = player:GetMap():GetHeight(x, y) or player:GetZ()
                creature:NearTeleport(x, y, z, o)
            end
            if creature:IsInWater() then
                Ambush.despawn(creature)
                return
            end


            local TRIES_MAX = 5
            local tries     = 0
            local minDist   = ambush_min_distance
            local maxDist   = ambush_max_distance
            local creatureMap = creature:GetMap() if creatureMap == nil then print("no creature map")
                                                                             Ambush.despawn(creature)
                                                                                         return end
            local function wrongHeight(atX, atY)
                local ground = creatureMap:GetHeight(atX, atY)
                return ground == nil or ground > player:GetZ() + 15 or ground < player:GetZ() - 15
            end

            while wrongHeight(x, y) and tries < TRIES_MAX do
                tries = tries + 1
                minDist = math.max(minDist / 2, AMBUSH_RETRY_MIN_DIST)
                maxDist = math.max(maxDist / 2, minDist + 10)
                print("creature is too high/low, trying again with new distance: " .. minDist .. " - " .. maxDist)
                x, y = spawnFunction(playerX, playerY, minDist, maxDist, o)
                z    = creatureMap:GetHeight(x, y) or player:GetZ()
                creature:NearTeleport(x, y, z, o)
            end
            if wrongHeight(x, y) then
                print("cannot find an acceptable spawn location - creature is too high/low")
                Ambush.despawn(creature)
                return
            end

            if isRare then
                print("Rare creature spawn: " .. creatureId)
                player:SendBroadcastMessage("A dark rustling alerts you to a dangerous presence. Keep a lookout.")
            else
                print("Ambush! Watch out, here comes " .. creatureId .. "!")
                player:SendBroadcastMessage("Ambush! Watch out, here comes " .. creatureId .. "!")
            end

            creature:SetData("ambush-chase-target", playerID)
            creature:SetData("wander-radius", 30)
            creature:SetData("ambush-max-distance", ambush_max_distance)
            if isRare then   player:SetData("is-in-boss-fight", true)
                           creature:SetData("is-rare", true)
                      else   player:SetData("num-ambushers", player:GetData("num-ambushers") + 1)
                           creature:SetData("is-rare", false)
            end
            creature:SetData("ambush-counted", true)
            creature:RegisterEvent(Ambush.chasePlayer, 1000, 1)
        end
    end
end

function Ambush.despawn(creature)
    Ambush.release(creature)
    creature:DespawnOrUnsummon(0)
end

function Ambush.layToRest(creature)
    Ambush.release(creature)
    creature:RemoveEvents()
    creature:MoveClear()
    creature:SetData("ambush-chase-target", nil)
    creature:SetData("wander-radius",       nil)
    creature:SetData("ambush-max-distance", nil)
    creature:SetData("orbit-direction",     nil)
    creature:SetData("is-rare",             nil)
end

function Ambush.release(creature)
    if creature:GetData("ambush-counted") ~= true then return end
    creature:SetData("ambush-counted", false)
    local player = GetPlayerByGUID(creature:GetData("ambush-chase-target"))
    if not player then return end
    if creature:GetData("is-rare") == true then
        player:SetData("is-in-boss-fight", false)
    else
        local count = player:GetData("num-ambushers") or 0
        if count > 0 then player:SetData("num-ambushers", count - 1) end
    end
end


function Ambush.chasePlayer(_eventID, _delay, _repeats, creature)
    if creature:IsDead() then
        Ambush.layToRest(creature)
        return
    end
    local    ATTACK_DISTANCE    = 30
    local CREATURE_MAX_DISTANCE = creature:GetData("ambush-max-distance") or 60
    local     WANDER_RADIUS     = creature:GetData("wander-radius") or 30
    local WANDER_ROTATION_DELAY = 2000
    local        playerID       = creature:GetData("ambush-chase-target")
    local        player         = GetPlayerByGUID(playerID)

    if not player then
        Ambush.despawn(creature)
        return
    end

    local        playerX,
                 playerY        = player:GetLocation()
    local       creatureX,
                creatureY,
                creatureZ,
                creatureO       = creature:GetLocation()
    local       creatureMap     = creature:GetMap() if not creatureMap then print("no creature map")
                                                                           Ambush.despawn(creature)
                                                                                         return end

    if not player:IsStandState() then
        creature:MoveClear()
        creature:AttackStop()
        creature:ClearInCombat()
        creature:SetAggroEnabled(false)
        if creature:CanAggro() then print("can aggro") else print("cannot aggro") end
        creature:SetHomePosition(creatureX, creatureY, creatureZ, creatureO)
        local angle = Movement.getInitialAngle(playerX, playerY, creatureX, creatureY)
        local dir   = creature:GetData("orbit-direction") if not dir then dir = 1 end
        local x, y  = Movement.getOrbitPosition( playerX, playerY,
                                                 WANDER_RADIUS,
                                                 creature:GetSpeed(1),
                                                 WANDER_ROTATION_DELAY,
                                                 angle,
                                                 dir )
        local ground = creatureMap:GetHeight(x, y)
        if ground == nil or ground > creatureZ + 14 or ground < creatureZ - 14 then
            creature:SetData("orbit-direction", dir * -1)
        else
            creature:MoveTo(math.random(0, 4294967295), x, y, ground)
        end
        creature:RegisterEvent(Ambush.chasePlayer, WANDER_ROTATION_DELAY, 1)
        return
    else
        creature:SetAggroEnabled(true)
    end

    if player:IsDead() then
        creature:MoveRandom(30)
        creature:RegisterEvent(Ambush.chasePlayer, 5000, 1)
        return
    end

    if Movement.isCloseEnough(creatureX, creatureY, playerX, playerY, ATTACK_DISTANCE)
    or creature:IsInCombat() then
        creature:SetHomePosition(creatureX, creatureY, creatureZ, creatureO)
        creature:AttackStart(player)
        creature:RegisterEvent(Ambush.inCombatCheck, 500, 1)
    else
        local targetX, targetY = Movement.getMidpoint( creature:GetX(),
                                                       creature:GetY(),
                                                       playerX,
                                                       playerY
                                                     )
        if player:GetMapId() ~= creatureMap:GetMapId() then
            print("player and creature are on different maps, respawning")
            Ambush.addCreatureToQueue(player, creature:GetEntry(), creature:GetLevel(), creature:GetLevel(), false)
            player:RegisterEvent(function(_, _, _, p) Ambush.randomSpawn(p, false) end, 1000, 1)
            Ambush.despawn(creature)
            return
        end

        if Movement.getLazyDistance(creatureX, creatureY, targetX, targetY) > CREATURE_MAX_DISTANCE then
            print(Movement.getLazyDistance(creatureX, creatureY, targetX, targetY) .." yards is too far away, despawning")
            Ambush.despawn(creature)
            return
        end
        local targetZ = creatureMap:GetHeight(targetX, targetY) or creatureZ

        creature:MoveTo(math.random(0, 4294967295), targetX, targetY, targetZ)
        creature:RegisterEvent(Ambush.chasePlayer, 1000, 1)
    end
end

function Ambush.onCreatureDeath(event, killer, creature)
    Ambush.layToRest(creature)
end

function Ambush.inCombatCheck(event, delay, repeats, creature)
    if creature:IsDead() then
        Ambush.layToRest(creature)
        return
    end
    if creature:IsInCombat() then
        creature:RegisterEvent(Ambush.inCombatCheck, 500, 1)
    else
        creature:RegisterEvent(Ambush.chasePlayer, 1000, 1)
    end
end


function Ambush.setupPlayer(event, player)
    player:SetData(   "queue",     {} )
    player:SetData( "rare-queue",  {} )
    player:SetData("num-ambushers", 0 )

    local memory = Ambush.memoryOf(player)
    if not memory.interval then
        memory.interval = AMBUSH_BASE_INTERVAL
    end

    local lastLogout   = memory.logoutTime or 0
    local currentTime  = os.time()
    local offlineTime  = currentTime - lastLogout
    local useGrace     = (lastLogout == 0) or (offlineTime >= AMBUSH_OFFLINE_RESET)

    local firstInterval
    if useGrace then
        firstInterval = AMBUSH_GRACE_PERIOD
    else
        firstInterval = Ambush.getNextInterval(player)
    end

    player:RegisterEvent(Ambush.spawnAndAttackPlayer, firstInterval, 1)
end

function Ambush.onPlayerLogout(event, player)
    Ambush.memoryOf(player).logoutTime = os.time()
    print("[Ambush] Logout time saved for: " .. player:GetName())
end

local PLAYER_EVENT_ON_LOGIN         = 3
local PLAYER_EVENT_ON_LOGOUT        = 4
local PLAYER_EVENT_ON_KILL_CREATURE = 7

RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN,         Ambush.setupPlayer)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT,        Ambush.onPlayerLogout)
RegisterPlayerEvent(PLAYER_EVENT_ON_KILL_CREATURE, Ambush.onCreatureDeath, 0)

