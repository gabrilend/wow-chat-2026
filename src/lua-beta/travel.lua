--------------------------------------------------------------------------------
-- travel.lua - travellers who wander by: vendors, innkeepers, and the
-- player's class trainers, each of the player's level.
--
-- For a general audience: beta's world is empty, so the people a player
-- would meet in towns come to them instead. Every couple of minutes one
-- traveller appears 30-45 yards from the player and walks past; it sits
-- when the player sits, and leaves when no player is near. Which travellers
-- a player can meet depends on their class (a mage meets no ammunition
-- vendor) and level, from the lists below and data/travel-trainers.lua.
-- Checked offline by scripts/test-travel.
--
-- History: wow-chat-1's scheduler (periodic_events.lua) sent travellers,
-- with the ambush and treasure. It was switched off on 2026-04-10 and its
-- bot half was left mid-investigation, so on 2026-10-17 travellers got a
-- clock of their own here, as the ambush has (ambush.lua), asking the
-- scheduler's questions before each one: not while the player is dead,
-- swimming or sitting. Real players only, as the scheduler had it.
--------------------------------------------------------------------------------

require("movement") -- movement.lua

Travel = { travellers = {} }

-- {{{ Configuration
TRAVEL_INTERVAL        = 130000  -- ms between travellers (periodic_events.lua's, 130 s)
TRAVEL_FIRST_INTERVAL  =  60000  -- ms after login before the first one
TRAVEL_SPAWN_MIN       =     30  -- yards from the player
TRAVEL_SPAWN_MAX       =     45
TRAVEL_DESPAWN_AFTER   = 300000  -- ms a traveller lasts (5 minutes) unless killed sooner
TEMPSUMMON_TIMED_OR_DEAD_DESPAWN = 1  -- the game's summon kind: gone after the time above, or when dead
-- }}}

-- {{{ Travel.HOLDS
-- Reasons not to send a traveller this time; the clock keeps running.
-- wow-chat-1's (libs/wow-chat-1/periodic_events.lua, PeriodicSpawnTravellers).
Travel.HOLDS = {
    { why = "player is dead",         holds = function(p) return p:IsDead() end },
    { why = "player is in water",     holds = function(p) return p:IsInWater() end },
    { why = "player is sitting down", holds = function(p) return not p:IsStandState() end },
}
-- }}}

-- Register in package.loaded so require() is a no-op after ALE loads this
-- Must be AFTER Travel table is created so require() returns the module
package.loaded["travel"] = Travel

-- {{{ Travel.despawn
-- Clean despawn: removes scheduled events and clears data before despawning
-- Ensures creature shell can be fully garbage collected
function Travel.despawn(creature)
    creature:RemoveEvents()
    creature:SetData("theta", nil)

    -- Clean up object variable data before despawn (Issue 332)
    if ObjectVariables and ObjectVariables.cleanupCreature then
        ObjectVariables.cleanupCreature(creature)
    end

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
    -- the lists follow the player's level now, not the level they logged
    -- in at (until 2026-10-17 a player who levelled kept meeting
    -- travellers of their login level until the next login)
    playerData.playerLevel = player:GetLevel()
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
        -- The custom-class framework's helpers, when it runs. The Knight's
        -- file makes an empty class registry even while the framework is
        -- switched off, so the registry existing is not enough: ask for the
        -- helper itself (2026-10-17; calling the missing helper stopped the
        -- traveller with an error).
        if Travel.isTrainer(travellerId) and CustomClasses and CustomClasses.getCustomClass then
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
              x, y       = Movement.getBoxSpawnPosition(x, y, TRAVEL_SPAWN_MIN, TRAVEL_SPAWN_MAX)
                    z    = player:GetMap():GetHeight(x, y)
                       o = math.random(0, 6) + math.random()
        --   no ground height there (past the map's edge, over a void): no
        --     traveller this time
        --   ground: it appears there
        if z == nil then
            print("[Travel] no ground at the spot picked for a traveller, none this time")
            return
        end
        -- Gone after TRAVEL_DESPAWN_AFTER or when killed. Until 2026-10-17
        -- the summon kind named here was a global nobody set, so the game
        -- used its default, and travellers never left on their own.
        local traveller = player:SpawnCreature(travellerId, x, y, z, o,
                                               TEMPSUMMON_TIMED_OR_DEAD_DESPAWN,
                                               TRAVEL_DESPAWN_AFTER)

        if traveller then
            print("Spawning traveller " .. tostring(travellerId ..
                  " named " .. traveller:GetName()) ..
                  " for " .. player:GetName())
            traveller:SetSpeed(0, 1)
            traveller:SetWalk(true)
            local playerX, playerY = player:GetLocation()
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

-- Stand state constants
local STAND_STATE_STAND = 0
local STAND_STATE_SIT   = 1

-- {{{ Travel.continueTravelling
-- Periodic movement for traveler NPCs
-- Mirrors player sit state - sits when player sits, stands when player stands
-- Despawns if no player nearby or terrain becomes invalid
function Travel.continueTravelling(_eventID, _delay, _repeats, creature)
    local player = creature:GetNearestPlayer(200)
    if player == nil then
        Travel.despawn(creature)
        return
    end

    -- Mirror player sit state (issue 320)
    -- If player is sitting, sit with them and wait
    if not player:IsStandState() then
        if creature:GetStandState() ~= STAND_STATE_SIT then
            creature:SetStandState(STAND_STATE_SIT)
        end
        creature:RegisterEvent(Travel.continueTravelling, 2000, 1)
        return
    else
        -- Player standing - ensure we're standing too
        if creature:GetStandState() ~= STAND_STATE_STAND then
            creature:SetStandState(STAND_STATE_STAND)
        end
    end

    -- Normal wandering behavior
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
    creature:MoveTo(math.random(4294967295), targetX, targetY, targetZ)
    creature:RegisterEvent(Travel.continueTravelling, math.random(2000, 4000), 1)
end
-- }}}

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
-- Class trainers who may travel by, and the levels each teaches: kept in
-- data/travel-trainers.lua (its header lists the fields) since 2026-10-17,
-- because install step E014's SQL is generated from the same list
-- (scripts/generate-beta-trainer-tiers-sql) and the two must not disagree.
local function script_dir()
    local src = debug.getinfo(1, "S").source
    return (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
end
local trainers = dofile(script_dir() .. "data/travel-trainers.lua")

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

-- {{{ Travel.tick
-- The traveller clock, per real player. Wound first, so a hold or an error
-- below skips only this traveller, not the rest of the session.
--   a hold applies: no traveller this time
--   none applies: one traveller is sent
function Travel.tick(_eventID, _delay, _repeats, player)
    player:RegisterEvent(Travel.tick, TRAVEL_INTERVAL, 1)
    for _, hold in ipairs(Travel.HOLDS) do
        if hold.holds(player) then
            print("[Travel] no traveller for " .. player:GetName() .. " - " .. hold.why)
            return
        end
    end
    Travel.spawnAndTravel(player)
end -- }}}

-- {{{ Travel.onLogin
-- Every character's traveller lists are made at login (bots' too: cheap,
-- and the chat command below can use them); only real players get the
-- clock, as wow-chat-1's scheduler gave it (open question for the owner:
-- whether bots should meet travellers too, as they meet ambushes).
--   a bot: lists only
--   a player: lists, and the first traveller a minute after login
function Travel.onLogin(_event, player)
    Travel.setupPlayer(nil, player)
    if player:IsBot() then return end
    player:RegisterEvent(Travel.tick, TRAVEL_FIRST_INTERVAL, 1)
end -- }}}

PLAYER_EVENT_ON_LOGIN = 3
PLAYER_EVENT_ON_CHAT  = 18
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, Travel.onLogin)
RegisterPlayerEvent(PLAYER_EVENT_ON_CHAT,  Travel.handleChat)
