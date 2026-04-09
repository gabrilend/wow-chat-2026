---------------------------------------------------------------------------------------------------
-- storage stuff

            Ambush = {} -- table to hold the functions.
local AmbushQueues = {} -- table to hold monsters that are queued to attack.

-- Creature cache: populated at startup, keyed by level then rank
-- Structure: CreatureCache[level][rank] = { {id=X, minLevel=Y, maxLevel=Z}, ... }
local CreatureCache = {}

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

    -- if there are no monsters queued for this player, fill the queue from cache
    local next = next
    if next(player:GetData("queue")) == nil then
        if next(player:GetData("rare-queue")) == nil then
            if player:IsInGroup() and player:GetGroup():GetMembersCount() > 2 then
                print("Heh, thought you could escape us? Think again! (group rare mob spawning)")
                Ambush.setupAmbushQueue(player, 2)
            else
                print("Heh, thought you could escape me? Think again! (solo rare mob spawning)")
                Ambush.setupAmbushQueue(player, 4)
            end
        else
            Ambush.setupAmbushQueue(player, 0)
            Ambush.randomSpawn(player, true)
        end
    else
        Ambush.randomSpawn(player, false)
    end
end -- }}}

---------------------------------------------------------------------------------------------------
-- queue construction functions

-- {{{ Ambush.initCreatureCache
-- Loads all creature data into memory at startup to avoid runtime SQL queries
-- which have a buffer corruption bug in ALE's WorldDBQuery implementation.
-- Called once when the script loads via ELUNA_EVENT_ON_LUA_STATE_OPEN.
function Ambush.initCreatureCache() -- {{{
    print("[Ambush] Initializing creature cache...")
    local MAX_LEVEL = 20  -- game's max level
    local ranks = {0, 2, 4}  -- normal, rare elite, rare

    -- Initialize cache structure
    for level = 1, MAX_LEVEL do
        CreatureCache[level] = {}
        for _, rank in ipairs(ranks) do
            CreatureCache[level][rank] = {}
        end
    end

    -- Load creatures with separate short queries per rank to avoid ALE query length bug
    local count = 0

    -- Valid creature types for ambush spawning (matches original wow-chat-1):
    -- 2=Dragonkin, 3=Demon, 4=Elemental, 5=Giant, 6=Undead, 9=Mechanical, 10=Aberration
    -- Notably EXCLUDES: 1=Beast, 7=Humanoid, 8=Critter
    local validTypes = {[2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [9]=true, [10]=true}

    for _, rank in ipairs(ranks) do
        -- Using backticks around `rank` because it's a reserved keyword in MySQL 8.0+
        local sql = "SELECT entry,minlevel,maxlevel,type FROM creature_template WHERE `rank`=" .. rank .. " AND npcflag=0 AND lootid!=0 AND minlevel<=" .. MAX_LEVEL
        print("[Ambush] Loading rank " .. rank .. " creatures...")
        local result = WorldDBQuery(sql)

        if result then
            repeat
                local entry      = result:GetUInt32(0)
                local minLevel   = result:GetUInt32(1)
                local maxLevel   = result:GetUInt32(2)
                local creatureType = result:GetUInt32(3)

                -- Skip creatures with invalid types or banned IDs
                if validTypes[creatureType] and not Ambush.isCreatureBanned(entry, rank == 2 or rank == 4) then
                    -- Add creature to cache for each level it's valid for
                    for level = minLevel, math.min(maxLevel, MAX_LEVEL) do
                        if CreatureCache[level] and CreatureCache[level][rank] then
                            table.insert(CreatureCache[level][rank], {
                                id       = entry,
                                minLevel = minLevel,
                                maxLevel = maxLevel,
                            })
                            count = count + 1
                        end
                    end
                end
            until not result:NextRow()
        else
            print("[Ambush] No creatures found for rank " .. rank)
        end
    end

    -- Debug: show cache stats per rank
    for _, rank in ipairs(ranks) do
        local rankCount = 0
        for level = 1, MAX_LEVEL do
            if CreatureCache[level] and CreatureCache[level][rank] then
                rankCount = rankCount + #CreatureCache[level][rank]
            end
        end
        print("[Ambush] Rank " .. rank .. " total entries: " .. rankCount)
    end
    print("[Ambush] Creature cache loaded: " .. count .. " level/creature entries")
end -- }}}

-- this function uses the cached creature data instead of querying at runtime
function Ambush.setupAmbushQueue(player, rank) -- {{{
    local playerLevel = player:GetLevel()
    local creatures = CreatureCache[playerLevel] and CreatureCache[playerLevel][rank] or {}
    print("[Ambush] setupAmbushQueue: level=" .. playerLevel .. " rank=" .. rank .. " found=" .. #creatures)
    Ambush.fillPlayerQueue(player, creatures, rank)
end -- }}}

-- {{{ Ambush.fillPlayerQueue
-- Fills a single player's ambush queue from cached creature data
function Ambush.fillPlayerQueue(player, creatures, rank) -- {{{
    local MaxQueueSize = 8

    local isRare = (rank == 2 or rank == 4)
    local queueType = isRare and "rare-queue" or "queue"

    -- Handle empty creature list
    if #creatures == 0 then
        print("[Ambush] No creatures found for rank " .. rank)
        player:SetData(queueType, {0})
        player:RegisterEvent(Ambush.spawnAndAttackPlayer, 1000, 1)
        return
    end

    -- Build queue with random selection from cache
    local queue = {}
    local availableCreatures = {}
    for i, c in ipairs(creatures) do
        availableCreatures[i] = c
    end

    local numToAdd = math.min(#availableCreatures, MaxQueueSize)
    for i = 1, numToAdd do
        local creature = table.remove(availableCreatures, math.random(#availableCreatures))
        table.insert(queue, creature.id)
    end

    player:SetData(queueType, queue)
    print("[Ambush] Filled " .. queueType .. " with " .. #queue .. " creatures for player level " .. player:GetLevel())
end -- }}}

-- DEPRECATED: this function builds an Ambush queue based on the results of a sql query
-- Keeping for reference but using pushToAmbushQueueFromCache instead
function Ambush.pushToAmbushQueue(query) -- {{{
    local LEVEL_MAX = 0 -- differential between player level and monster level
    local LEVEL_MIN = 0 -- MAKE SURE YOU ALSO SET IN setup[Solo/Group]RareQueue()
    local isRare = false
    local MaxQueueSize = 8
    local queueType = ""
    local next = next

    local creatures = {}
    if query then
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
    local ambush_min_distance = 120
    local ambush_max_distance = 160
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
        local playerX, playerY, playerZ, playerO = player:GetLocation()
        local playerMap = player:GetMap()

------ find valid spawn position {{{
        local x, y, z, o
        local spawnTries = 0
        local SPAWN_TRIES_MAX = 5
        repeat
            spawnTries = spawnTries + 1
            x, y = spawnFunction(playerX, playerY, ambush_min_distance, ambush_max_distance, playerO)
            z = playerMap:GetHeight(x, y)
        until z ~= nil or spawnTries >= SPAWN_TRIES_MAX

        if z == nil then
            print("[Ambush] Could not find valid terrain for spawn after " .. SPAWN_TRIES_MAX .. " tries")
            return
        end
        o = math.random(0, 6.28)
        --- }}}

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
                x, y = spawnFunction(playerX, playerY, ambush_min_distance, ambush_max_distance, o)
                z = playerMap:GetHeight(x, y)
                if z then
                    creature:NearTeleport(x, y, z, o)
                end
            end
            if tries == 3 or not z then
                Ambush.despawn(creature)
                return
            end
            --- }}}

------ is-wrong-z check {{{
            -- check if the Z level is weird. if it is, then try 5 times to find
            -- a new spawn location. if one cannot be found, then just give up
            -- and despawn the creature
            local tries = 0
            local TRIES_MAX = 5
            local minDist = ambush_min_distance
            local maxDist = ambush_max_distance
            local creatureMap = creature:GetMap()
            if creatureMap == nil then
                print("[Ambush] No creature map")
                Ambush.despawn(creature)
                return
            end

            local currentZ = creatureMap:GetHeight(x, y)
            while currentZ and (currentZ > playerZ + 15 or currentZ < playerZ - 15) and tries < TRIES_MAX do
                tries = tries + 1
                minDist = minDist / 2
                maxDist = maxDist / 2
                print("[Ambush] Creature too high/low, retrying with distance: " .. minDist .. "-" .. maxDist)
                x, y = spawnFunction(playerX, playerY, minDist, maxDist, o)
                z = creatureMap:GetHeight(x, y)
                if z then
                    creature:NearTeleport(x, y, z, o)
                    currentZ = z
                else
                    currentZ = nil  -- force another retry
                end
            end
            if tries == TRIES_MAX or not z then
                print("[Ambush] Cannot find acceptable spawn location")
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

    -- Clean up object variable data before despawn (Issue 332)
    if ObjectVariables and ObjectVariables.cleanupCreature then
        ObjectVariables.cleanupCreature(creature)
    end

    if playerID == nil then creature:DespawnOrUnsummon(0) return end
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
    else
        -- Player is standing - re-enable aggro so creature can target other players
        -- (aggro was disabled during orbit mode when player was sitting)
        creature:SetAggroEnabled(true)
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
            return
        end
        local targetZ = creatureMap:GetHeight(targetX, targetY)
        if not targetZ then
            -- Can't find valid terrain, stay put and retry next tick
            creature:RegisterEvent(Ambush.chasePlayer, 1000, 1)
            return
        end

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

    -- Clear ambush data from corpse - corpse remains as static scenery
    -- like bones or trees, no longer tracked by ambush system
    creature:RemoveEvents()
    creature:MoveClear()  -- Stop any in-progress movement so corpse doesn't slide
    creature:SetData("ambush-chase-target", nil)
    creature:SetData("wander-radius",       nil)
    creature:SetData("ambush-max-distance", nil)
    creature:SetData("orbit-direction",     nil)
    creature:SetData("is-rare",             nil)
end -- }}}

-- this function checks if the nearest player is in combat, not necessarily the target
function Ambush.inCombatCheck(event, delay, repeats, creature) -- {{{
    if not creature then return end

    -- If creature is in combat, let default AI handle it (another player might be fighting it)
    if creature:IsInCombat() then
        creature:SetSpeed(0, 1.0)
        creature:SetSpeed(1, 1.0)
        creature:RegisterEvent(Ambush.inCombatCheck, 500, 1)
        return
    end

    SELECT_TARGET_NEAREST = 3
    local nearbyPlayer = creature:GetAITarget(SELECT_TARGET_NEAREST, true, 0, 40, 0)

    -- No player nearby within 40 yards - chase assigned player with speed boost
    if not nearbyPlayer then
        local playerID = creature:GetData("ambush-chase-target")
        local assignedPlayer = playerID and GetPlayerByGUID(playerID)

        if assignedPlayer and assignedPlayer:GetMapId() == creature:GetMapId() then
            -- Speed boost to catch up (1.5x normal run speed)
            creature:SetSpeed(0, 1.5)  -- 0 = MOVE_WALK
            creature:SetSpeed(1, 1.5)  -- 1 = MOVE_RUN

            -- Move toward assigned player
            local px, py, pz = assignedPlayer:GetLocation()
            creature:MoveTo(math.random(0, 4294967295), px, py, pz)
            creature:RegisterEvent(Ambush.inCombatCheck, 1000, 1)
        else
            -- Assigned player gone (logged out, different map) - despawn
            Ambush.despawn(creature)
        end
        return
    end

    -- Player nearby, reset speed
    creature:SetSpeed(0, 1.0)
    creature:SetSpeed(1, 1.0)

    if not nearbyPlayer:IsStandState() then -- {{{
        creature:MoveHome()
        creature:RegisterEvent(Ambush.chasePlayer, 2000, 1)
        return
    end -- }}}

    -- Not in combat, player nearby but standing - deregister (will re-engage via normal AI)
    Ambush.deregister(creature)
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

function Ambush.setupPlayer(event, player)
    player:SetData(   "queue",     {} )
    player:SetData( "rare-queue",  {} )
    player:SetData("num-ambushers", 0 )
end

PLAYER_EVENT_ON_LOGIN = 3
PLAYER_EVENT_ON_KILL_CREATURE = 7
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, Ambush.setupPlayer)
RegisterPlayerEvent(PLAYER_EVENT_ON_KILL_CREATURE, Ambush.onCreatureDeath, 0)

-- Initialize creature cache at script load time
-- This runs once when the server starts, avoiding runtime SQL queries
Ambush.initCreatureCache()

---------------------------------------------------------------------------------------------------
