---------------------------------------------------------------------------------------------------
-- storage stuff
--
-- Note: Movement table is defined in movement.lua which ALE loads separately.
-- No require() needed - all scripts in lua_scripts/ are loaded before events fire.
--

            Ambush = {} -- table to hold the functions.
local AmbushQueues = {} -- table to hold monsters that are queued to attack.

-- {{{ Configuration
--
-- Spawn interval uses a random walk algorithm. Each spawn, the interval
-- changes by +/- 2-4 seconds from the PREVIOUS value, not the base.
-- This creates organic, unpredictable pacing that drifts over time.
--
-- The walk has boundaries to prevent extremes:
-- - Floor at 10s prevents overwhelming the player
-- - Soft cap at 100s biases toward decreasing (67% down, 33% up)
-- - Hard cap at 200s strongly biases down (80% down, 20% up)
-- This creates a natural "rubber band" that keeps spawns reasonable.
--
-- Grace period gives players 30 seconds to get bearings after login,
-- but only if they were offline 10+ minutes. Quick relogs resume
-- immediately so disconnect/reconnect doesn't reset progress.
--
AMBUSH_BASE_INTERVAL   =  40000  -- ms starting interval (40 seconds)
AMBUSH_INTERVAL_MIN    =  10000  -- ms floor (10 seconds)
AMBUSH_INTERVAL_SOFT   = 100000  -- ms soft cap - bias toward decreasing
AMBUSH_INTERVAL_HARD   = 200000  -- ms hard cap - strong bias toward decreasing
AMBUSH_JITTER_MIN      =   2000  -- ms minimum jitter (2 seconds)
AMBUSH_JITTER_MAX      =   4000  -- ms maximum jitter (4 seconds)
AMBUSH_JITTER_STEP     =   1000  -- ms jitter step (1 second, so 2/3/4 only)
AMBUSH_MIN_DISTANCE    =    120  -- yards minimum from player
AMBUSH_MAX_DISTANCE    =    160  -- yards maximum from player
AMBUSH_GRACE_PERIOD    =  30000  -- ms grace period on login (30 seconds)
AMBUSH_OFFLINE_RESET   =    600  -- seconds offline to trigger grace (10 minutes)
-- }}}

-- {{{ Ambush.getJitterMagnitude
-- Returns random jitter magnitude: 2000, 3000, or 4000 ms
function Ambush.getJitterMagnitude()
    local steps = (AMBUSH_JITTER_MAX - AMBUSH_JITTER_MIN) / AMBUSH_JITTER_STEP
    return AMBUSH_JITTER_MIN + (math.random(0, steps) * AMBUSH_JITTER_STEP)
end -- }}}

-- {{{ Ambush.getJitterSign
-- Returns +1 or -1 based on current interval and boundary rules
--
-- The probability weighting creates a "rubber band" effect:
-- - At floor: forced positive (can't go lower)
-- - Normal range: 50/50 (true random walk)
-- - Above soft cap: 67% negative (gentle pull back)
-- - Above hard cap: 80% negative (strong pull back)
--
-- This prevents runaway intervals while maintaining unpredictability.
-- Integer ratios (1-in-3, 1-in-5) avoid floating point.
--
function Ambush.getJitterSign(currentInterval)
    -- at or below minimum, force positive
    if currentInterval <= AMBUSH_INTERVAL_MIN then
        return 1
    end

    -- above hard cap: 1 in 5 chance of positive (20%)
    if currentInterval >= AMBUSH_INTERVAL_HARD then
        if math.random(1, 5) == 1 then return 1
                                  else return -1
        end
    end

    -- above soft cap: 1 in 3 chance of positive (33%)
    if currentInterval >= AMBUSH_INTERVAL_SOFT then
        if math.random(1, 3) == 1 then return 1
                                  else return -1
        end
    end

    -- normal range: 50/50
    if math.random(0, 1) == 0 then return -1
                              else return 1
    end
end -- }}}

-- {{{ Ambush.getNextInterval
-- Random walk: applies jitter to PREVIOUS interval, not base.
--
-- Why random walk instead of random around base?
-- - Creates drift over time, feels less mechanical
-- - Player experiences "seasons" of fast/slow spawning
-- - Boundaries prevent it from getting stuck at extremes
-- - More interesting than pure randomness
--
function Ambush.getNextInterval(player)
    local currentInterval = player:GetData("ambush-interval") or AMBUSH_BASE_INTERVAL

    local magnitude = Ambush.getJitterMagnitude()
    local sign      = Ambush.getJitterSign(currentInterval)
    local offset    = sign * magnitude

    local newInterval = currentInterval + offset

    -- enforce floor
    if newInterval < AMBUSH_INTERVAL_MIN then
        newInterval = AMBUSH_INTERVAL_MIN
    end

    -- store for next iteration
    player:SetData("ambush-interval", newInterval)

    print("[Ambush] Interval walk: " .. (currentInterval / 1000) .. "s → " .. (newInterval / 1000) .. "s (offset " .. (offset / 1000) .. "s)")

    return newInterval
end -- }}}

-- add more when you find them
-- 7074 and 7073 are maybes, try fighting them and see if they're too hard
-- 11141 on thin ice
Ambush.BANNED_CREATURE_IDS = { 17887, 19416, 2673,  3569,  16422, 16423, -- {{{
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
                             } -- }}}

Ambush.BANNED_RARE_IDS = { 0, -- {{{
                         } -- }}}

---------------------------------------------------------------------------------------------------
-- periodic event function

-- ranks: 0 = regular mob, 2 = rare elite, 4 = rare
-- this function determines which queue to use when spawning a monster
function Ambush.spawnAndAttackPlayer(_eventID, _delay, _repeats, player) -- {{{
    print("[Ambush] spawnAndAttackPlayer triggered for " .. player:GetName())

    -- if there are no monsters queued for this player, then query the database
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
                Ambush.setupAmbushQueue(playerLevel, 2)
            else
                print("[Ambush] Querying for solo rares (rank 4)")
                Ambush.setupAmbushQueue(playerLevel, 4)
            end
        else
            print("[Ambush] Spawning rare, querying for normals (rank 0)")
            Ambush.setupAmbushQueue(playerLevel, 0)
            Ambush.randomSpawn(player, true)
        end
    else
        print("[Ambush] Spawning normal creature")
        Ambush.randomSpawn(player, false)
    end

    -- re-register with new random interval (random walk)
    local interval = Ambush.getNextInterval(player)
    player:RegisterEvent(Ambush.spawnAndAttackPlayer, interval, 1)
end -- }}}

---------------------------------------------------------------------------------------------------
-- queue construction functions

-- this function generates an async sql query and calls pushToAmbushQueue() when it's done
function Ambush.setupAmbushQueue(playerLevel, rank) -- {{{
    WorldDBQueryAsync("SELECT entry, minlevel, maxlevel, rank FROM creature_template WHERE minlevel <= " .. playerLevel .. " AND maxlevel >= " .. playerLevel .. " AND rank = " .. rank .. " AND npcflag = 0 AND lootid != 0 AND type IN (2, 3, 4, 5, 6, 9, 10);", Ambush.pushToAmbushQueue)
end -- }}}

-- this function builds an Ambush queue based on the results of the sql query
function Ambush.pushToAmbushQueue(query) -- {{{
    print("[Ambush] pushToAmbushQueue callback fired")

    local LEVEL_MAX = 0 -- differential between player level and monster level
    local LEVEL_MIN = 0 -- MAKE SURE YOU ALSO SET IN setup[Solo/Group]RareQueue()
    local isRare = false
    local MaxQueueSize = 8
    local queueType = ""
    local next = next

    local creatures = {}
    if query then
        print("[Ambush] Query returned results")
        -- if creature is rare or rare elite
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

    if #creatures > MaxQueueSize then -- {{{
        print("queue size too large, truncating")
        local tempTable = {}
        local creature
        for i = 1, MaxQueueSize do
            creature = table.remove(creatures, math.random(#creatures))
            table.insert(tempTable, creature)
        end
        creatures = tempTable
    end -- }}}

    if #creatures == 0 then -- {{{
        print("no creatures found")
        queueType = "rare-queue" -- there will always be normal monsters, soooo...
    end -- }}}

    all_players = { alliance = GetPlayersInWorld(0, false),
                    horde    = GetPlayersInWorld(1, false),
                    neutral  = GetPlayersInWorld(2, false)
                  }

    -- for each player currently logged in
    for _, faction in pairs(all_players) do
        for _, player in pairs(faction) do
            if #creatures == 0 -- {{{
                and next(player:GetData(queueType)) == nil then
                player:SetData(queueType, {0})
                player:RegisterEvent(Ambush.spawnAndAttackPlayer, 1000, 1)
                return
            end -- }}}
            local playerLevel = player:GetLevel()
            if playerLevel ~= 0 then
                -- for each creature that we just queried
                for _, creature in ipairs(creatures) do
                    -- if this creature is appropriate for this player
                    if playerLevel >= creature.minLevel - LEVEL_MIN and
                       playerLevel <= creature.maxLevel + LEVEL_MAX then

                          tempTable = player:GetData(queueType)
                          table.insert(tempTable, creature.id)
                          player:SetData(queueType, tempTable)
                    end
                end
            else
                print("player level == 0 which is weird")
            end
        end
    end
end -- }}}

-- slower than regenerating the queue all at once
function Ambush.addCreatureToQueue(player, creatureId, minLevel, maxLevel, isRare) -- {{{
    local queueType
    if isRare then queueType = "rare-queue"
              else queueType = "queue"
    end
    local creature = { id       = creatureId,
                       minLevel = minLevel,
                       maxLevel = maxLevel,
                     }
    local tempTable = {}
    tempTable[1] = creature
    for k, v in player:GetData(queueType) do
        tempTable[k + 1] = v
    end
    player:SetData(queueType, tempTable)

end -- }}}

-- make sure this function is in the async callback function... it might take
-- a while depending on how many banned creatures there are.
function Ambush.isCreatureBanned(creatureId, isRare) -- {{{

    if isRare then
        for _, id in ipairs(Ambush.BANNED_RARE_IDS) do
            if creatureId == id then return true end end

    else -- if not rare
    for _, id in ipairs(Ambush.BANNED_CREATURE_IDS) do
        if creatureId == id then return true end end
    end
    return false -- if not banned
end -- }}}

---------------------------------------------------------------------------------------------------
-- spawning functions

function Ambush.randomSpawn(player, isRare) -- {{{
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
        corpseDespawnTimer = 360 * 1000 -- 6 minutes
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
                    z    = player:GetMap():GetHeight(x, y)
                       o = math.random(0, 6.28)
        local creature = player:SpawnCreature(creatureId, x, y, z, o,
                                              corpseDespawnType,
                                              corpseDespawnTimer)
        if creature then

------ is-in-water check {{{
            -- check and make sure the creature did not spawn in the water
            -- if it did, then try 3 times to find a new spawn location.
            -- if one cannot be found, then just give up and despawn the creature
            local tries = 0
            while creature:IsInWater() and tries < 3 do
                tries = tries + 1
                x, y = spawnFunction(x, y, ambush_min_distance, ambush_max_distance, o)
                z    = player:GetMap():GetHeight(x, y)
                creature:NearTeleport(x, y, z, o)
            end
            if tries == 3 then
                Ambush.despawn(creature)
                return
            end
            --- }}}

------ is-wrong-z check {{{
            -- check if the Z level is weird. if it is, then try 3 times to find
            -- a new spawn location. if one cannot be found, then just give up
            -- and despawn the creature

            local tries = 0 local TRIES_MAX = 5
            local minDist = ambush_min_distance
            local maxDist = ambush_max_distance
            local playerX, playerY = player:GetLocation()
            local creatureMap = creature:GetMap() if creatureMap == nil then print("no creature map")
                                                                             Ambush.despawn(creature)
                                                                                         return end

            while ( creature:GetMap():GetHeight(x,y) > player:GetZ() + 15 or
                    creature:GetMap():GetHeight(x,y) < player:GetZ() - 15 ) and tries < TRIES_MAX do
                tries = tries + 1
                minDist = minDist / 2
                maxDist = maxDist / 2
                print("creature is too high/low, trying again with new distance: " .. minDist .. " - " .. maxDist)
                x, y = spawnFunction(playerX, playerY, minDist, maxDist, o)
                z    = creature:GetMap():GetHeight(x, y)
                creature:NearTeleport(x, y, z, o)
            end
            if tries == TRIES_MAX then
                print("cannot find an acceptable spawn location - creature is too high/low")
                Ambush.despawn(creature)
                return
            end
            --- }}}

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
            creature:RegisterEvent(Ambush.chasePlayer, 1000, 1)
        end
    end
end -- }}}

function Ambush.despawn(creature) -- {{{
    local playerID = creature:GetData("ambush-chase-target")
    if    playerID == nil then creature:DespawnOrUnsummon(0) return end
    Ambush.deregister(creature)
    creature:DespawnOrUnsummon(0)
end -- }}}

function Ambush.deregister(creature) -- {{{
    local playerID = creature:GetData("ambush-chase-target")
    local player   = GetPlayerByGUID(playerID)
    if     creature:GetData("is-rare") == true  then player:SetData("is-in-boss-fight", false)
    elseif creature:GetData("is-rare") == false then player:SetData("num-ambushers", player:GetData("num-ambushers") - 1)
    end
end -- }}}

---------------------------------------------------------------------------------------------------
-- combat functions

function Ambush.chasePlayer(_eventID, _delay, _repeats, creature) -- {{{
    if creature:IsDead() then
        return
    end
    local    ATTACK_DISTANCE    = 30
    local CREATURE_MAX_DISTANCE = creature:GetData("ambush-max-distance") or 60
    local     WANDER_RADIUS     = creature:GetData("wander-radius") or 30
    local WANDER_ROTATION_DELAY = 2000 -------- time between each new waypoint on the circle
    local        playerID       = creature:GetData("ambush-chase-target") -- required
    local        player         = GetPlayerByGUID(playerID)
    local        playerX,
                 playerY        = player:GetLocation()
    local       creatureX,
                creatureY,
                creatureZ,
                creatureO       = creature:GetLocation()
    local       creatureMap     = creature:GetMap() if not creatureMap then print("no creature map")
                                                                           Ambush.despawn(creature)
                                                                                         return end

    if not player:IsStandState() then -- {{{
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
        if creatureMap:GetHeight(x, y) > creatureZ + 14 or
           creatureMap:GetHeight(x, y) < creatureZ - 14 then
            creature:SetData("orbit-direction", dir * -1)
        end
        creature:MoveTo(math.random(0, 4294967295), x, y, creatureMap:GetHeight(x, y))
        creature:RegisterEvent(Ambush.chasePlayer, WANDER_ROTATION_DELAY, 1)
        return
    end -- }}}

    if player:IsDead() then -- {{{
        creature:MoveRandom(30)
        creature:RegisterEvent(Ambush.chasePlayer, 5000, 1)
        return
    end -- }}}

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
   if player:GetMapId() ~= creatureMap:GetMapId() then -- {{{
            -- if the player is on the border between one map and another while
            -- the creatures are chasing them, then the creature will get stuck
            -- on the border and not be able to cross over. This is a problem
            -- because the creature will not be able to attack the player and
            -- the player will not be able to attack the creature. So, if the
            -- player and the creature are on different maps, then just despawn
            -- the creature and attempt to respawn it on the player's map.
            print("player and creature are on different maps, respawning")
            Ambush.addCreatureToQueue(player, creature:GetEntry(), creature:GetLevel(), creature:GetLevel(), false) -- setting isRare to false because it doesn't matter which queue the creature spawns in
            player:RegisterEvent(Ambush.spawnCreature, 1000, 1)
            Ambush.despawn(creature)
        end -- }}}

        if Movement.getLazyDistance(creatureX, creatureY, targetX, targetY) > CREATURE_MAX_DISTANCE then
            print(Movement.getLazyDistance(creatureX, creatureY, targetX, targetY) .." yards is too far away, despawning")
            Ambush.despawn(creature)
        end
        local targetZ = creatureMap:GetHeight(targetX, targetY)

        creature:MoveTo(math.random(0, 4294967295), targetX, targetY, targetZ)
        creature:RegisterEvent(Ambush.chasePlayer, 1000, 1)
    end
end -- }}}

function Ambush.onCreatureDeath(event, killer, creature) -- {{{
    local owning_player_ID = creature:GetData("ambush-chase-target") or nil
    local isRare           = creature:GetData("is-rare") or false
    if owning_player_ID then
        local player = GetPlayerByGUID(owning_player_ID)
        if player then
            if isRare then
                player:SetData("is-in-boss-fight", false)
            else
                local numAmbushers = player:GetData("num-ambushers")
                if    numAmbushers > 0 then
                    player:SetData("num-ambushers", numAmbushers - 1)
                end
            end
        end
    end
end -- }}}

-- this function checks if the nearest player is in combat, not necessarily the target
function Ambush.inCombatCheck(event, delay, repeats, creature) -- {{{
    if not creature then print("oops creature dead") return end
    SELECT_TARGET_NEAREST = 3
    local player = creature:GetAITarget(SELECT_TARGET_NEAREST, true, 0, 30, 0)
    if not player then print("oops no player") return end
    if not player:IsStandState() then -- {{{
        creature:MoveHome()
        creature:RegisterEvent(Ambush.chasePlayer, 2000, 1)
        return
    end -- }}}
    if  creature:IsInCombat() then
        creature:RegisterEvent(Ambush.inCombatCheck, 500, 1)
    else
        Ambush.deregister(creature)
    end
end -- }}}
---------------------------------------------------------------------------------------------------

-- FIXME: make it so that neutral spawning mobs will orbit instead
--        of attacking the player
--
--        then make alternative orbit mechanics that go a little farther out and drift a little bit sorta like the travellers (but still orbiting)
--
-- FIXME: make units spawn at strongholds (like demons and undead from strongholds of undeath and fel energy) or helpful allies and hordes who spawn in their castles and march out to wage war
--
-- could automate it too, by looking at every quest and pulling the target NPC to be spawned in the area where the target NPC is spawned
--
-- and then have them radiate outwards, exploring the world bit-by-bit
--
-- you don't have to make any boundaries
--
-- just make them wander about and spawn at their respective strongholds (AKA wherever the quest tells you to wander)

function Ambush.setupPlayer(event, player) -- {{{
    player:SetData(   "queue",     {} )
    player:SetData( "rare-queue",  {} )
    player:SetData("num-ambushers", 0 )

    -- restore interval from database or use base
    -- TODO: load from db_characters once persistence is added
    local savedInterval = player:GetData("ambush-interval")
    if not savedInterval then
        player:SetData("ambush-interval", AMBUSH_BASE_INTERVAL)
    end

    -- check if player was offline long enough to trigger grace period
    --
    -- Why 10 minute threshold?
    -- - Quick relogs (disconnect, alt-tab crash) shouldn't reset progress
    -- - Long absences mean player needs time to reorient
    -- - 30 second grace lets them check inventory, look around, etc.
    --
    local lastLogout   = player:GetData("ambush-logout-time") or 0
    local currentTime  = os.time()
    local offlineTime  = currentTime - lastLogout
    local useGrace     = (lastLogout == 0) or (offlineTime >= AMBUSH_OFFLINE_RESET)

    local firstInterval
    if useGrace then
        -- long offline or first login: fixed grace period
        firstInterval = AMBUSH_GRACE_PERIOD
        print("[Ambush] Grace period: " .. (AMBUSH_GRACE_PERIOD / 1000) .. "s (offline " .. offlineTime .. "s)")
    else
        -- quick relog: resume normal random walk
        firstInterval = Ambush.getNextInterval(player)
        print("[Ambush] Quick relog, resuming at " .. (firstInterval / 1000) .. "s")
    end

    -- 1 = run once, then re-register with random interval in spawnAndAttackPlayer
    player:RegisterEvent(Ambush.spawnAndAttackPlayer, firstInterval, 1)

    print("[Ambush] Registered spawn cycle for: " .. player:GetName())
end -- }}}

-- {{{ Ambush.onPlayerLogout
-- Track logout time for grace period calculation
function Ambush.onPlayerLogout(event, player)
    player:SetData("ambush-logout-time", os.time())
    print("[Ambush] Logout time saved for: " .. player:GetName())
end -- }}}

PLAYER_EVENT_ON_LOGIN         = 3
PLAYER_EVENT_ON_LOGOUT        = 4
PLAYER_EVENT_ON_KILL_CREATURE = 7

RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN,         Ambush.setupPlayer)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT,        Ambush.onPlayerLogout)
RegisterPlayerEvent(PLAYER_EVENT_ON_KILL_CREATURE, Ambush.onCreatureDeath, 0)

---------------------------------------------------------------------------------------------------
