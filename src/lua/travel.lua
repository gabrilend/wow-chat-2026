require("movement") -- movement.lua

Travel = { travellers = {} }

-- {{{ Travel.despawn
-- Clean despawn: removes scheduled events and clears data before despawning
-- Ensures creature shell can be fully garbage collected
function Travel.despawn(creature)
    creature:RemoveEvents()
    creature:SetData("theta", nil)
    creature:DespawnOrUnsummon(0)
end -- }}}

function Travel.setupPlayer(_event, player)
    local playerData = { travellers    = {},
                         typeMask      = 0,
                         playerFaction = 0,
                         playerLevel   = player:GetLevel(),
                         playerClass   = player:GetClass()
                        }

    if player:IsHorde() == true then
        playerData.playerFaction = 1
    else
        playerData.playerFaction = 2
    end

    playerData.typeMask = Travel.getTravelerTypeMask(playerData.playerClass)

    player:SetData("travellers", playerData)

    Travel.updatePlayerTravellers(player:GetGUID())
end

-- runs when a player logs in or levels up or runs out of travellers to spawn
function Travel.updatePlayerTravellers(playerID)
    local player     = GetPlayerByGUID(playerID)
    local playerData = player:GetData("travellers") or nil
    if playerData == nil then
        Travel.setupPlayer(nil, player)
        return
    end
    local next = next
    for _, traveller_category in pairs(Travel.travellers) do
        -- bit_and is ALE global (LuaJIT doesn't have bit32)
        if bit_and(traveller_category.typeMask, playerData.typeMask) ~= 0 then
            for _, specific_traveller in pairs(traveller_category.list) do
                if next(specific_traveller) ~= nil then
                    if Travel.isValidFaction(specific_traveller.rel, playerData.playerFaction) and
                       specific_traveller.minLevel <= playerData.playerLevel and
                       specific_traveller.maxLevel >= playerData.playerLevel
                    then
                        if specific_traveller.id < 0 then -- if less than zero, a trainer
                            if (specific_traveller.id * -1) == playerData.playerClass then
                                table.insert( playerData.travellers,
                                              specific_traveller.trainerID )
                                break
                            end
                        else
                           table.insert( playerData.travellers,
                                         specific_traveller.id )
                        end
                    end
                end
            end
        end
    end
    player:SetData("travellers", playerData)
end

function Travel.isValidFaction(f1, f2)
    if ( f1 == f2           ) or
       ( f1 == 1 and f2 == 3) or
       ( f1 == 2 and f2 == 3) or
       ( f1 == 3 and f2 == 1) or
       ( f1 == 3 and f2 == 2) then
        return true
    else
        return false
    end
end

function Travel.getRandomTravellerId(playerID, count)
    local player = GetPlayerByGUID(playerID)
    local playerData = player:GetData("travellers") or nil
    local next = next
    if next(playerData.travellers) ~= nil then
        local randInt     = math.random(1, #playerData.travellers)
        local travellerID = table.remove(playerData.travellers, randInt)
        player:SetData("travellers", playerData)
        return travellerID
    else -- regenerate queue
        print("traveller list empty. Regenerating...")
        if count == nil then
            count = 0
        end
        if count >= 3 then
            print("sucks to suck")
            return 0
        end
        Travel.updatePlayerTravellers(playerID)
        count = count + 1
        return Travel.getRandomTravellerId(playerID, count)
    end
end

-- witches are thieves of youth. how dare they.

function Travel.spawnAndTravel(player)
    print("A traveller appears...")
    player:SendBroadcastMessage("A traveller appears...")
    local travellerId = Travel.getRandomTravellerId(player:GetGUID())
    if travellerId ~= 0 then
        -- Custom class players get trainers from their eligible classes (equal probability)
        -- instead of their base class trainer - uses existing world trainers
        if Travel.isTrainer(travellerId) and CustomClasses then
            local customClassId = CustomClasses.getCustomClass(player)
            if customClassId then
                local eligibleClasses = CustomClasses.getEligibleClasses(player)
                if #eligibleClasses > 0 then
                    -- Equal probability selection
                    local selectedClass = eligibleClasses[math.random(#eligibleClasses)]
                    local playerFaction = player:IsHorde() and 1 or 2
                    local newTrainerId  = Travel.getTrainerForClass(selectedClass, player:GetLevel(), playerFaction)
                    if newTrainerId then
                        print("[Travel] Custom class - spawning class " .. selectedClass .. " trainer")
                        travellerId = newTrainerId
                    else
                        print("[Travel] No trainer found for class " .. selectedClass .. " at level " .. player:GetLevel())
                    end
                else
                    print("[Travel] No eligible classes - using base class trainer")
                end
                -- Fall through to normal spawn with (possibly replaced) travellerId
            end
        end

        local x, y, z, o = player:GetLocation()
              x, y       = Movement.getBoxSpawnPosition(x, y, 30, 45)
                    z    = player:GetMap():GetHeight(x, y)
                       o = math.random(0, 6) + math.random()
        local TEMPSUMMON_DEAD_DESPAWN  = 7          -- despawn when creature disappears
        local TEMPSUMMON_DESPAWN_TIMER = 300 * 1000 -- 5 minutes
        local traveller = player:SpawnCreature(travellerId, x, y, z, o,
                                               TEMPSUMMON_TIMED_OR_DEAD_DESPAWN,
                                               TEMPSUMMON_DESPAWN_TIMER)

        if traveller then
            print("Spawning traveller " .. tostring(travellerId ..
                  " named " .. traveller:GetName()) ..
                  " for " .. player:GetName())
            traveller:SetSpeed(0, 1)
            traveller:SetWalk(true)
            playerX, playerY = player:GetLocation()
            x, y = Movement.getPositionOppositePoint(x, y, playerX, playerY)
            z    = player:GetMap():GetHeight(x, y)
            -- If terrain invalid, despawn traveller instead of crashing
            if z == nil then
                print("[Travel] Invalid terrain at spawn, despawning traveller")
                Travel.despawn(traveller)
                return
            end
            o    = traveller:GetO()
            traveller:MoveTo(math.random(0, 4294967295), x, y, z)
            traveller:SetData("theta", o)
            traveller:RegisterEvent(Travel.continueTravelling, 25000, 1)
        end
    end
end

-- 1.57 radians = 90 degrees
-- 0.78 radians = 45 degrees
-- 0.39 radians = 22.5 degrees
-- 0.19 radians = 11.25 degrees
function Travel.continueTravelling(_eventID, _delay, _repeats, creature )
    local player = creature:GetNearestPlayer(200)
    if player == nil then Travel.despawn(creature)
    else
        local x, y, z, o = creature:GetLocation()
        local theta = creature:GetData("theta")

        local count = 0
        local targetX, targetY, targetZ, newO
        repeat
            targetX, targetY, targetZ, newO = Movement.generateNewWanderPosition(x, y, z, o, theta, creature:GetMapId())
            count = count + 1
            if count > 10 then
                print("[Travel] Count exceeded, despawning creature")
                Travel.despawn(creature)
                return
            end
            if not targetZ then
                print("[Travel] Invalid terrain, despawning creature")
                Travel.despawn(creature)
                return
            end
            if newO > theta then
                theta = theta + 0.39
            elseif newO < theta then
                theta = theta - 0.39
            end
            creature:SetData("theta", theta)
        until targetZ < z + 5 and targetZ > z - 5

        creature:MoveClear()
        if player:IsStandState() then creature:MoveTo(math.random(4294967295),
                                                                  targetX,
                                                                  targetY,
                                                                  targetZ)
        end
        creature:RegisterEvent(Travel.continueTravelling, math.random(2000, 4000), 1)
    end
end

---------------------------------------------------------------------------------------------------

function Travel.handleChat(event, player, message)
    if message == "#travel" then
        Travel.spawnAndTravel(player)
    end
end

---------------------------------------------------------------------------------------------------

-- this function returns a bitmask of all the traveller types that a player can spawn
function Travel.getTravelerTypeMask(class)
    if class == 1 then -- 1 = warrior
        return 0 + 2 + 4 + 8 + 0  + 32 + 64 + 128 + 256 + 512
    end
    if class == 2 then -- 2 = paladin
        return 0 + 2 + 4 + 8 + 0  + 32 + 64 + 0   + 256 + 512
    end
    if class == 3 then -- 3 = hunter
        return 1 + 2 + 4 + 8 + 0  + 32 + 64 + 128 + 256 + 512
    end
    if class == 4 then -- 4 = rogue
        return 0 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256 + 512
    end
    if class == 5 then -- 5 = priest
        return 0 + 2 + 4 + 8 + 0  + 32 + 64 + 0   + 256 + 512
    end
    if class == 6 then -- 6 = death knight
        return 0 + 2 + 4 + 8 + 0  + 32 + 64 + 0   + 256 + 512
    end
    if class == 7 then -- 7 = shaman
        return 0 + 2 + 4 + 8 + 0  + 32 + 64 + 0   + 256 + 512
    end
    if class == 8 then -- 8 = mage
        return 0 + 2 + 4 + 8 + 0  + 32 + 64 + 0   + 256 + 0
    end
    if class == 9 then -- 9 = warlock
        return 0 + 2 + 4 + 8 + 0  + 32 + 64 + 0   + 256 + 512
    end
    if class == 11 then -- 11 = druid
        return 0 + 0 + 4 + 8 + 0  + 32 + 64 + 0   + 256 + 512
    end
end

-- probably not every vendor, but I tried to get as many as I could -- {{{

-- rel is a bitmask of faction relations: 1 = friendly to horde
--                                        2 = friendly to alliance
--                                        3 = friendly to both

local food        = { { id = 32642, minLevel = 65, maxLevel = 80, rel = 1 },

                      { id = 258,   minLevel = 1,  maxLevel = 20, rel = 2 },
                      { id = 3937,  minLevel = 6,  maxLevel = 25, rel = 2 },

                      { id = 6496,  minLevel = 1,  maxLevel = 80, rel = 3 }, -- duplicated x3 >:)
                      { id = 6496,  minLevel = 1,  maxLevel = 80, rel = 3 }, -- duplicate
                      { id = 6496,  minLevel = 1,  maxLevel = 80, rel = 3 }, -- duplicate
                      { id = 2842,  minLevel = 1,  maxLevel = 45, rel = 3 },
                      { id = 23699, minLevel = 65, maxLevel = 70, rel = 3 },
                      { id = 32478, minLevel = 65, maxLevel = 80, rel = 3 },
                      { id = 32631, minLevel = 65, maxLevel = 80, rel = 3 },
                    }
local melee       = { { id = 3539,  minLevel = 17, maxLevel = 27, rel = 1 },
                      { id = 3479,  minLevel = 8,  maxLevel = 12, rel = 1 },
                      { id = 1407,  minLevel = 39, maxLevel = 41, rel = 1 }, -- duplicated in armor
                      { id = 10361, minLevel = 39, maxLevel = 41, rel = 1 },
                      { id = 10379, minLevel = 29, maxLevel = 32, rel = 1 }, -- duplicated here
                      { id = 10379, minLevel = 39, maxLevel = 41, rel = 1 }, -- duplicate
                      { id = 21474, minLevel = 29, maxLevel = 31, rel = 1 }, -- duplicated here
                      { id = 21474, minLevel = 66, maxLevel = 66, rel = 1 }, -- duplicate

                      { id = 2265,  minLevel = 1,  maxLevel = 6,  rel = 2 },
                      { id = 1441,  minLevel = 17, maxLevel = 21, rel = 2 },
                      { id = 225,   minLevel = 14, maxLevel = 21, rel = 2 }, -- duplicated here
                      { id = 225,   minLevel = 26, maxLevel = 27, rel = 2 }, -- duplicate
                      { id = 1471,  minLevel = 29, maxLevel = 31, rel = 2 }, -- duplicated here
                      { id = 1471,  minLevel = 40, maxLevel = 41, rel = 2 }, -- duplicate
                      { id = 1296,  minLevel = 39, maxLevel = 41, rel = 2 },
                      { id = 15315, minLevel = 29, maxLevel = 31, rel = 2 }, -- duplicated here
                      { id = 15315, minLevel = 39, maxLevel = 41, rel = 2 }, -- duplicate

                      { id = 2840,  minLevel = 8,  maxLevel = 15, rel = 3 },
                      { id = 4086,  minLevel = 15, maxLevel = 25, rel = 3 },
                      { id = 3534,  minLevel = 10, maxLevel = 20, rel = 3 },
                      { id = 19238, minLevel = 5,  maxLevel = 20, rel = 3 }, -- duplicated here
                      { id = 19238, minLevel = 31, maxLevel = 40, rel = 3 }, -- duplicate
                      { id = 3658,  minLevel = 8,  maxLevel = 15, rel = 3 },
                      { id = 3491,  minLevel = 13, maxLevel = 17, rel = 3 },
                      { id = 23571, minLevel = 30, maxLevel = 41, rel = 3 }, -- duplicated in armor
                      { id = 2483,  minLevel = 29, maxLevel = 30, rel = 3 }, -- duplicated here
                      { id = 2483,  minLevel = 39, maxLevel = 41, rel = 3 }, -- duplicate
                      { id = 2482,  minLevel = 29, maxLevel = 31, rel = 3 },
                      { id = 2843,  minLevel = 29, maxLevel = 31, rel = 3 }, -- duplicated here
                      { id = 2843,  minLevel = 39, maxLevel = 41, rel = 3 }, -- duplicate
                      { id = 3000,  minLevel = 29, maxLevel = 40, rel = 3 },
                      { id = 11184, minLevel = 39, maxLevel = 41, rel = 3 },
                      { id = 12024, minLevel = 39, maxLevel = 41, rel = 3 },
                      { id = 19536, minLevel = 65, maxLevel = 66, rel = 3 },
                      { id = 19047, minLevel = 10, maxLevel = 30, rel = 3 },
                      { id = 19240, minLevel = 29, maxLevel = 41, rel = 3 },
                      { id = 27185, minLevel = 69, maxLevel = 69, rel = 3 },
                      { id = 27151, minLevel = 70, maxLevel = 70, rel = 3 },
                      { id = 27188, minLevel = 71, maxLevel = 71, rel = 3 },
                      { id = 20112, minLevel = 59, maxLevel = 59, rel = 3 },
                      { id = 20917, minLevel = 60, maxLevel = 60, rel = 3 },
                      { id = 19526, minLevel = 61, maxLevel = 61, rel = 3 },
                      { id = 31027, minLevel = 20, maxLevel = 30, rel = 3 },
                      { id = 19043, minLevel = 31, maxLevel = 32, rel = 3 },
                      { id = 25314, minLevel = 39, maxLevel = 41, rel = 3 },
                      { id = 29497, minLevel = 70, maxLevel = 70, rel = 3 },
                      { id = 28991, minLevel = 70, maxLevel = 70, rel = 3 },
                      { id = 29496, minLevel = 70, maxLevel = 70, rel = 3 },
                      { id = 29494, minLevel = 70, maxLevel = 70, rel = 3 },
                      { id = 30006, minLevel = 75, maxLevel = 80, rel = 3 },
                      { id = 28855, minLevel = 29, maxLevel = 41, rel = 3 },
                      { id = 30067, minLevel = 70, maxLevel = 70, rel = 3 },
                    }
local ranged      = { { id = 3322,  minLevel = 4,  maxLevel = 30, rel = 1 },

                      { id = 1668,  minLevel = 11, maxLevel = 16, rel = 2 },
                      { id = 1461,  minLevel = 16, maxLevel = 21, rel = 2 },
                      { id = 1459,  minLevel = 11, maxLevel = 16, rel = 2 },
                      { id = 3951,  minLevel = 30, maxLevel = 30, rel = 2 },

                      { id = 19236, minLevel = 15, maxLevel = 21, rel = 3 }, -- duplicated here
                      { id = 19236, minLevel = 29, maxLevel = 30, rel = 3 }, -- duplicate
                      { id = 19236, minLevel = 40, maxLevel = 41, rel = 3 }, -- duplicate
                      { id = 3053,  minLevel = 15, maxLevel = 20, rel = 3 },
                      { id = 27139, minLevel = 69, maxLevel = 70, rel = 3 },
                      { id = 28994, minLevel = 71, maxLevel = 71, rel = 3 },
                      { id = 29476, minLevel = 70, maxLevel = 70, rel = 3 },
                      { id = 28989, minLevel = 70, maxLevel = 70, rel = 3 },
                      { id = 27943, minLevel = 15, maxLevel = 20, rel = 3 }, -- duplicated here
                      { id = 27943, minLevel = 29, maxLevel = 30, rel = 3 }, -- duplicate
                      { id = 27943, minLevel = 40, maxLevel = 41, rel = 3 }, -- duplicate
                    }
local armor       = { { id = 1407,  minLevel = 32, maxLevel = 32, rel = 1 }, -- duplicated in melee

                      { id = 3528,  minLevel = 12, maxLevel = 15, rel = 2 },
                      { id = 3532,  minLevel = 5,  maxLevel = 10, rel = 2 },
                      { id = 3530,  minLevel = 5,  maxLevel = 10, rel = 2 },
                      { id = 3529,  minLevel = 12, maxLevel = 15, rel = 2 }, -- verify if hostile
                      { id = 2264,  minLevel = 5,  maxLevel = 10, rel = 2 },
                      { id = 4188,  minLevel = 17, maxLevel = 17, rel = 2 }, -- duplicated here
                      { id = 4188,  minLevel = 22, maxLevel = 22, rel = 2 }, -- duplicate
                      { id = 3543,  minLevel = 17, maxLevel = 20, rel = 2 }, -- duplicated here
                      { id = 3543,  minLevel = 23, maxLevel = 25, rel = 2 }, -- duplicate
                      { id = 1695,  minLevel = 17, maxLevel = 22, rel = 2 },
                      { id = 11703, minLevel = 12, maxLevel = 14, rel = 2 },

                      { id = 3536,  minLevel = 15, maxLevel = 25, rel = 3 },
                      { id = 3134,  minLevel = 20, maxLevel = 25, rel = 3 },
                      { id = 3492,  minLevel = 15, maxLevel = 20, rel = 3 },
                      { id = 3493,  minLevel = 15, maxLevel = 20, rel = 3 },
                      { id = 4085,  minLevel = 20, maxLevel = 25, rel = 3 },
                      { id = 1669,  minLevel = 10, maxLevel = 15, rel = 3 },
                      { id = 3537,  minLevel = 20, maxLevel = 25, rel = 3 },
                      { id = 3683,  minLevel = 10, maxLevel = 15, rel = 3 },
                      { id = 8129,  minLevel = 32, maxLevel = 50, rel = 3 },
                      { id = 2845,  minLevel = 30, maxLevel = 35, rel = 3 },
                      { id = 11874, minLevel = 35, maxLevel = 40, rel = 3 },
                      { id = 2849,  minLevel = 17, maxLevel = 44, rel = 3 },
                      { id = 11183, minLevel = 44, maxLevel = 46, rel = 3 },
                      { id = 11182, minLevel = 44, maxLevel = 46, rel = 3 },
                      { id = 12023, minLevel = 39, maxLevel = 45, rel = 3 },
                      { id = 19517, minLevel = 70, maxLevel = 70, rel = 3 },
                      { id = 23571, minLevel = 32, maxLevel = 45, rel = 3 }, -- duplicated in weapons
                    }
local ammo        = { { id = 734,   minLevel = 20, maxLevel = 40, rel = 2 },
                      { id = 32638, minLevel = 65, maxLevel = 79, rel = 2 },

                      { id = 12246, minLevel = 10, maxLevel = 60, rel = 3 },
                      { id = 2839,  minLevel = 5,  maxLevel = 30, rel = 3 },
                      { id = 3498,  minLevel = 1,  maxLevel = 12, rel = 3 },
                      { id = 8131,  minLevel = 16, maxLevel = 30, rel = 3 },
                      { id = 12029, minLevel = 44, maxLevel = 44, rel = 3 },
                      { id = 14624, minLevel = 10, maxLevel = 60, rel = 3 },
                      { id = 20080, minLevel = 40, maxLevel = 70, rel = 3 },
                      { id = 22491, minLevel = 55, maxLevel = 65, rel = 3 },
                      { id = 28040, minLevel = 60, maxLevel = 80, rel = 3 },
                      { id = 30572, minLevel = 60, maxLevel = 80, rel = 3 },
                    }
local innkeepers  = { { id = 11118, minLevel = 5,  maxLevel = 25, rel = 3 },
                      { id = 16256, minLevel = 26, maxLevel = 45, rel = 3 },
                      { id = 23995, minLevel = 46, maxLevel = 65, rel = 3 },
                      { id = 29963, minLevel = 66, maxLevel = 80, rel = 3 },
                    }
local consumables = { { id = 4581,  minLevel = 1,  maxLevel = 25, rel = 1 },

                      { id = 8305,  minLevel = 3,  maxLevel = 20, rel = 3 },
                      { id = 20989, minLevel = 45, maxLevel = 60, rel = 3 },
                      { id = 12245, minLevel = 22, maxLevel = 27, rel = 3 },
                      { id = 28715, minLevel = 40, maxLevel = 80, rel = 3 },
                    }
local poisons     = { { id = 32641, minLevel = 20, maxLevel = 80, rel = 1 },

                      { id = 5169,  minLevel = 20, maxLevel = 80, rel = 2 },
                      { id = 32639, minLevel = 80, maxLevel = 80, rel = 2 },

                      { id = 2622,  minLevel = 20, maxLevel = 50, rel = 3 },
                      { id = 20986, minLevel = 50, maxLevel = 70, rel = 3 },
                      { id = 30069, minLevel = 60, maxLevel = 80, rel = 3 },
                    }
local others      = { { id = 20980, minLevel = 30, maxLevel = 60, rel = 3 },
                      { id = 6368,  minLevel = 1,  maxLevel = 80, rel = 3 },
                      { id = 29478, minLevel = 70, maxLevel = 80, rel = 3 },
                      { id = 29716, minLevel = 56, maxLevel = 56, rel = 3 },
                      { id = 28993, minLevel = 1,  maxLevel = 30, rel = 3 },
                    }
-- trainers have a negative ID value so that we can break them up into different
-- categories based on their class
-- -1 = warrior     -4 = rogue            -7 = shaman     -10 = druid
-- -2 = paladin     -5 = priest           -8 = mage
-- -3 = hunter      -6 = death knight     -9 = warlock
-- Normalized to level 1-20 cap using ALL available trainers per class/faction
-- Level ranges distributed evenly: 20 levels / N trainers per class
-- More trainers = finer level granularity, more NPC variety
local trainers    = {   -- horde warrior (9 trainers)
                      { trainerID =  3354, minLevel =  1, maxLevel =  2, rel = 1, id =  -1 },
                      { trainerID =  3353, minLevel =  3, maxLevel =  4, rel = 1, id =  -1 },
                      { trainerID =  3041, minLevel =  5, maxLevel =  6, rel = 1, id =  -1 },
                      { trainerID =  3043, minLevel =  7, maxLevel =  8, rel = 1, id =  -1 },
                      { trainerID =  3042, minLevel =  9, maxLevel = 11, rel = 1, id =  -1 },
                      { trainerID =  4594, minLevel = 12, maxLevel = 13, rel = 1, id =  -1 },
                      { trainerID =  3408, minLevel = 14, maxLevel = 15, rel = 1, id =  -1 },
                      { trainerID =  4595, minLevel = 16, maxLevel = 17, rel = 1, id =  -1 },
                      { trainerID =  4593, minLevel = 18, maxLevel = 20, rel = 1, id =  -1 },
                        -- alliance warrior (11 trainers)
                      { trainerID =  5113, minLevel =  1, maxLevel =  1, rel = 2, id =  -1 },
                      { trainerID =  5480, minLevel =  2, maxLevel =  3, rel = 2, id =  -1 },
                      { trainerID =  1901, minLevel =  4, maxLevel =  5, rel = 2, id =  -1 },
                      { trainerID =   914, minLevel =  6, maxLevel =  7, rel = 2, id =  -1 },
                      { trainerID =  5114, minLevel =  8, maxLevel =  9, rel = 2, id =  -1 },
                      { trainerID = 17120, minLevel = 10, maxLevel = 10, rel = 2, id =  -1 },
                      { trainerID =  5479, minLevel = 11, maxLevel = 12, rel = 2, id =  -1 },
                      { trainerID =  4087, minLevel = 13, maxLevel = 14, rel = 2, id =  -1 },
                      { trainerID =  4089, minLevel = 15, maxLevel = 16, rel = 2, id =  -1 },
                      { trainerID = 16771, minLevel = 17, maxLevel = 18, rel = 2, id =  -1 },
                      { trainerID =  7315, minLevel = 19, maxLevel = 20, rel = 2, id =  -1 },
                        -- horde paladin (5 trainers)
                      { trainerID = 16679, minLevel =  1, maxLevel =  4, rel = 1, id =  -2 },
                      { trainerID = 16680, minLevel =  5, maxLevel =  8, rel = 1, id =  -2 },
                      { trainerID = 16681, minLevel =  9, maxLevel = 12, rel = 1, id =  -2 },
                      { trainerID = 20406, minLevel = 13, maxLevel = 16, rel = 1, id =  -2 },
                      { trainerID = 23128, minLevel = 17, maxLevel = 20, rel = 1, id =  -2 },
                        -- alliance paladin (7 trainers)
                      { trainerID =  5149, minLevel =  1, maxLevel =  2, rel = 2, id =  -2 },
                      { trainerID =  5148, minLevel =  3, maxLevel =  5, rel = 2, id =  -2 },
                      { trainerID =  5147, minLevel =  6, maxLevel =  8, rel = 2, id =  -2 },
                      { trainerID = 17509, minLevel =  9, maxLevel = 11, rel = 2, id =  -2 },
                      { trainerID =   928, minLevel = 12, maxLevel = 14, rel = 2, id =  -2 },
                      { trainerID =  5492, minLevel = 15, maxLevel = 17, rel = 2, id =  -2 },
                      { trainerID =  5491, minLevel = 18, maxLevel = 20, rel = 2, id =  -2 },
                        -- horde hunter (7 trainers)
                      { trainerID =  3406, minLevel =  1, maxLevel =  2, rel = 1, id =  -3 },
                      { trainerID =  3040, minLevel =  3, maxLevel =  5, rel = 1, id =  -3 },
                      { trainerID =  3352, minLevel =  6, maxLevel =  8, rel = 1, id =  -3 },
                      { trainerID =  3039, minLevel =  9, maxLevel = 11, rel = 1, id =  -3 },
                      { trainerID =  3038, minLevel = 12, maxLevel = 14, rel = 1, id =  -3 },
                      { trainerID = 16673, minLevel = 15, maxLevel = 17, rel = 1, id =  -3 },
                      { trainerID =  3407, minLevel = 18, maxLevel = 20, rel = 1, id =  -3 },
                        -- alliance hunter (8 trainers)
                      { trainerID =  5117, minLevel =  1, maxLevel =  2, rel = 2, id =  -3 },
                      { trainerID =  4146, minLevel =  3, maxLevel =  5, rel = 2, id =  -3 },
                      { trainerID =  5515, minLevel =  6, maxLevel =  7, rel = 2, id =  -3 },
                      { trainerID = 17505, minLevel =  8, maxLevel = 10, rel = 2, id =  -3 },
                      { trainerID =  5116, minLevel = 11, maxLevel = 12, rel = 2, id =  -3 },
                      { trainerID =  5115, minLevel = 13, maxLevel = 15, rel = 2, id =  -3 },
                      { trainerID =  4205, minLevel = 16, maxLevel = 17, rel = 2, id =  -3 },
                      { trainerID =  5516, minLevel = 18, maxLevel = 20, rel = 2, id =  -3 },
                        -- horde rogue (6 trainers)
                      { trainerID =  3327, minLevel =  1, maxLevel =  3, rel = 1, id =  -4 },
                      { trainerID =  3401, minLevel =  4, maxLevel =  6, rel = 1, id =  -4 },
                      { trainerID =  4582, minLevel =  7, maxLevel = 10, rel = 1, id =  -4 },
                      { trainerID =  4583, minLevel = 11, maxLevel = 13, rel = 1, id =  -4 },
                      { trainerID =  3328, minLevel = 14, maxLevel = 16, rel = 1, id =  -4 },
                      { trainerID =  4584, minLevel = 17, maxLevel = 20, rel = 1, id =  -4 },
                        -- alliance rogue (6 trainers)
                      { trainerID =  5167, minLevel =  1, maxLevel =  3, rel = 2, id =  -4 },
                      { trainerID =  4163, minLevel =  4, maxLevel =  6, rel = 2, id =  -4 },
                      { trainerID =  5166, minLevel =  7, maxLevel = 10, rel = 2, id =  -4 },
                      { trainerID =   918, minLevel = 11, maxLevel = 13, rel = 2, id =  -4 },
                      { trainerID =  5165, minLevel = 14, maxLevel = 16, rel = 2, id =  -4 },
                      { trainerID = 13283, minLevel = 17, maxLevel = 20, rel = 2, id =  -4 },
                        -- horde priest (9 trainers)
                      { trainerID =  4607, minLevel =  1, maxLevel =  2, rel = 1, id =  -5 },
                      { trainerID = 16659, minLevel =  3, maxLevel =  4, rel = 1, id =  -5 },
                      { trainerID =  3044, minLevel =  5, maxLevel =  6, rel = 1, id =  -5 },
                      { trainerID =  6018, minLevel =  7, maxLevel =  8, rel = 1, id =  -5 },
                      { trainerID =  4608, minLevel =  9, maxLevel = 11, rel = 1, id =  -5 },
                      { trainerID =  6014, minLevel = 12, maxLevel = 13, rel = 1, id =  -5 },
                      { trainerID =  3045, minLevel = 14, maxLevel = 15, rel = 1, id =  -5 },
                      { trainerID =  5994, minLevel = 16, maxLevel = 17, rel = 1, id =  -5 },
                      { trainerID =  4906, minLevel = 18, maxLevel = 20, rel = 1, id =  -5 },
                        -- alliance priest (9 trainers)
                      { trainerID =  5143, minLevel =  1, maxLevel =  2, rel = 2, id =  -5 },
                      { trainerID =  5142, minLevel =  3, maxLevel =  4, rel = 2, id =  -5 },
                      { trainerID = 11406, minLevel =  5, maxLevel =  6, rel = 2, id =  -5 },
                      { trainerID =  5489, minLevel =  7, maxLevel =  8, rel = 2, id =  -5 },
                      { trainerID =  5484, minLevel =  9, maxLevel = 11, rel = 2, id =  -5 },
                      { trainerID =   376, minLevel = 12, maxLevel = 13, rel = 2, id =  -5 },
                      { trainerID =  4092, minLevel = 14, maxLevel = 15, rel = 2, id =  -5 },
                      { trainerID =  4091, minLevel = 16, maxLevel = 17, rel = 2, id =  -5 },
                      { trainerID = 11401, minLevel = 18, maxLevel = 20, rel = 2, id =  -5 },
                        -- neutral death knight (3 trainers)
                      { trainerID = 29194, minLevel =  1, maxLevel =  6, rel = 3, id =  -6 },
                      { trainerID = 29195, minLevel =  7, maxLevel = 13, rel = 3, id =  -6 },
                      { trainerID = 29196, minLevel = 14, maxLevel = 20, rel = 3, id =  -6 },
                        -- horde shaman (6 trainers)
                      { trainerID =  3032, minLevel =  1, maxLevel =  3, rel = 1, id =  -7 },
                      { trainerID =  3030, minLevel =  4, maxLevel =  6, rel = 1, id =  -7 },
                      { trainerID = 13417, minLevel =  7, maxLevel = 10, rel = 1, id =  -7 },
                      { trainerID =  3403, minLevel = 11, maxLevel = 13, rel = 1, id =  -7 },
                      { trainerID =  3031, minLevel = 14, maxLevel = 16, rel = 1, id =  -7 },
                      { trainerID =  3344, minLevel = 17, maxLevel = 20, rel = 1, id =  -7 },
                        -- alliance shaman (5 trainers)
                      { trainerID = 17520, minLevel =  1, maxLevel =  4, rel = 2, id =  -7 },
                      { trainerID = 17204, minLevel =  5, maxLevel =  8, rel = 2, id =  -7 },
                      { trainerID = 17219, minLevel =  9, maxLevel = 12, rel = 2, id =  -7 },
                      { trainerID = 23127, minLevel = 13, maxLevel = 16, rel = 2, id =  -7 },
                      { trainerID = 20407, minLevel = 17, maxLevel = 20, rel = 2, id =  -7 },
                        -- horde mage (11 trainers)
                      { trainerID = 16651, minLevel =  1, maxLevel =  1, rel = 1, id =  -8 },
                      { trainerID =  4568, minLevel =  2, maxLevel =  3, rel = 1, id =  -8 },
                      { trainerID =  5885, minLevel =  4, maxLevel =  5, rel = 1, id =  -8 },
                      { trainerID =  7311, minLevel =  6, maxLevel =  7, rel = 1, id =  -8 },
                      { trainerID =  3047, minLevel =  8, maxLevel =  9, rel = 1, id =  -8 },
                      { trainerID =  5883, minLevel = 10, maxLevel = 10, rel = 1, id =  -8 },
                      { trainerID =  4567, minLevel = 11, maxLevel = 12, rel = 1, id =  -8 },
                      { trainerID =  4566, minLevel = 13, maxLevel = 14, rel = 1, id =  -8 },
                      { trainerID =  5882, minLevel = 15, maxLevel = 16, rel = 1, id =  -8 },
                      { trainerID =  3048, minLevel = 17, maxLevel = 18, rel = 1, id =  -8 },
                      { trainerID =  3049, minLevel = 19, maxLevel = 20, rel = 1, id =  -8 },
                        -- alliance mage (7 trainers)
                      { trainerID =  5144, minLevel =  1, maxLevel =  2, rel = 2, id =  -8 },
                      { trainerID =  5497, minLevel =  3, maxLevel =  5, rel = 2, id =  -8 },
                      { trainerID =   331, minLevel =  6, maxLevel =  8, rel = 2, id =  -8 },
                      { trainerID =  7312, minLevel =  9, maxLevel = 11, rel = 2, id =  -8 },
                      { trainerID =  5498, minLevel = 12, maxLevel = 14, rel = 2, id =  -8 },
                      { trainerID = 16749, minLevel = 15, maxLevel = 17, rel = 2, id =  -8 },
                      { trainerID =  5145, minLevel = 18, maxLevel = 20, rel = 2, id =  -8 },
                        -- horde warlock (6 trainers)
                      { trainerID =  3324, minLevel =  1, maxLevel =  3, rel = 1, id =  -9 },
                      { trainerID =  3325, minLevel =  4, maxLevel =  6, rel = 1, id =  -9 },
                      { trainerID =  3326, minLevel =  7, maxLevel = 10, rel = 1, id =  -9 },
                      { trainerID =  4564, minLevel = 11, maxLevel = 13, rel = 1, id =  -9 },
                      { trainerID =  4563, minLevel = 14, maxLevel = 16, rel = 1, id =  -9 },
                      { trainerID =  4565, minLevel = 17, maxLevel = 20, rel = 1, id =  -9 },
                        -- alliance warlock (6 trainers)
                      { trainerID =  5495, minLevel =  1, maxLevel =  3, rel = 2, id =  -9 },
                      { trainerID =  5172, minLevel =  4, maxLevel =  6, rel = 2, id =  -9 },
                      { trainerID =  5496, minLevel =  7, maxLevel = 10, rel = 2, id =  -9 },
                      { trainerID =   461, minLevel = 11, maxLevel = 13, rel = 2, id =  -9 },
                      { trainerID =  5171, minLevel = 14, maxLevel = 16, rel = 2, id =  -9 },
                      { trainerID =  5173, minLevel = 17, maxLevel = 20, rel = 2, id =  -9 },
                        -- horde druid (3 trainers)
                      { trainerID =  3043, minLevel =  1, maxLevel =  6, rel = 1, id = -10 },
                      { trainerID =  3033, minLevel =  7, maxLevel = 13, rel = 1, id = -10 },
                      { trainerID =  3036, minLevel = 14, maxLevel = 20, rel = 1, id = -10 },
                        -- alliance druid (5 trainers)
                      { trainerID =  4218, minLevel =  1, maxLevel =  4, rel = 2, id = -10 },
                      { trainerID =  4219, minLevel =  5, maxLevel =  8, rel = 2, id = -10 },
                      { trainerID =  5505, minLevel =  9, maxLevel = 12, rel = 2, id = -10 },
                      { trainerID =  4217, minLevel = 13, maxLevel = 16, rel = 2, id = -10 },
                      { trainerID =  5504, minLevel = 17, maxLevel = 20, rel = 2, id = -10 },
                    }

-- Weapon trainers (all teach at any level since weapon skills are level-independent)
 local wep_trainers = { { id = 17005, minLevel = 1,  maxLevel = 20,  rel = 1 },
                        { id = 16621, minLevel = 1,  maxLevel = 20,  rel = 1 },
                        { id = 2704,  minLevel = 1,  maxLevel = 20,  rel = 1 },
                        { id = 11868, minLevel = 1,  maxLevel = 20,  rel = 1 },
                        { id = 11869, minLevel = 1,  maxLevel = 20,  rel = 1 },
                        { id = 11870, minLevel = 1,  maxLevel = 20,  rel = 1 },

                        { id = 11865, minLevel = 1,  maxLevel = 20,  rel = 2 },
                        { id = 11866, minLevel = 1,  maxLevel = 20,  rel = 2 },
                        { id = 13084, minLevel = 1,  maxLevel = 20,  rel = 2 },
                        { id = 16773, minLevel = 1,  maxLevel = 20,  rel = 2 },
                        { id = 11867, minLevel = 1,  maxLevel = 20,  rel = 2 },

                        { id = 20124, minLevel = 1,  maxLevel = 20,  rel = 3 },
                     }

--[[ nonfunctional for now
local questgivers = { { id = 15297, minLevel = 4,  maxLevel = 6,  rel = 1 },
                      { id = 361,   minLevel = 8,  maxLevel = 12, rel = 1 },
                      { id = 15398, minLevel = 8,  maxLevel = 11, rel = 1 },
                      { id = 16252, minLevel = 15, maxLevel = 16, rel = 1 },
                      { id = 17355, minLevel = 29, maxLevel = 30, rel = 1 },

                      { id = 2080,  minLevel = 13, maxLevel = 15, rel = 2 },
                      { id = 17303, minLevel = 29, maxLevel = 30, rel = 2 },

                      { id = 9270,  minLevel = 48, maxLevel = 52, rel = 3 },
                    }
--]]
-- }}}

Travel.travellers["Ammo"]        = { name = "Ammo",        list = ammo,        typeMask = 1   }
Travel.travellers["Innkeepers"]  = { name = "Innkeepers",  list = innkeepers,  typeMask = 2   }
Travel.travellers["Trainers"]    = { name = "Trainers",    list = trainers,    typeMask = 4   }
Travel.travellers["Consumables"] = { name = "Consumables", list = consumables, typeMask = 8   }
Travel.travellers["Poisons"]     = { name = "Poisons",     list = poisons,     typeMask = 16  }
Travel.travellers["Others"]      = { name = "Others",      list = others,      typeMask = 32  }
Travel.travellers["Melee"]       = { name = "Melee",       list = melee,       typeMask = 64  }
Travel.travellers["Ranged"]      = { name = "Ranged",      list = ranged,      typeMask = 128 }
Travel.travellers["Armor"]       = { name = "Armor",       list = armor,       typeMask = 256 }
Travel.travellers["Food"]        = { name = "Food",        list = food,        typeMask = 512 }

-- {{{ Build trainer ID lookup table
-- Used to detect if a traveller spawn is a trainer (for custom class redirection)
Travel.trainerIds = {}
for _, trainer in ipairs(trainers) do
    Travel.trainerIds[trainer.trainerID] = true
end
-- }}}

-- {{{ isTrainer
-- Check if a traveller ID is a class trainer
function Travel.isTrainer(travellerId)
    return Travel.trainerIds[travellerId] == true
end
-- }}}

-- {{{ getTrainerForClass
-- Find a trainer for a specific class that covers the player's level
-- classId: positive class ID (1=warrior, 2=paladin, 3=hunter, 4=rogue, 5=priest, 6=dk, 7=shaman, 8=mage, 9=warlock, 11=druid)
-- playerLevel: player's current level
-- playerFaction: 1=horde, 2=alliance
-- Returns trainerID or nil if no matching trainer
function Travel.getTrainerForClass(classId, playerLevel, playerFaction)
    local negClass = -classId  -- trainers use negative class IDs
    for _, trainer in ipairs(trainers) do
        if trainer.id == negClass then
            if playerLevel >= trainer.minLevel and playerLevel <= trainer.maxLevel then
                -- Check faction: 3 = neutral (works for both)
                if trainer.rel == playerFaction or trainer.rel == 3 then
                    return trainer.trainerID
                end
            end
        end
    end
    return nil
end
-- }}}

PLAYER_EVENT_ON_LOGIN = 3
PLAYER_EVENT_ON_CHAT  = 18
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, Travel.setupPlayer)
RegisterPlayerEvent(PLAYER_EVENT_ON_CHAT,  Travel.handleChat)
