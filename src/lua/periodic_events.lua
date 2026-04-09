--------------------------------------------------------------------------------
-- requires -- {{{
require("ambush")         -- Import the functions from ambush.lua.
require("travel")         -- Import the functions from travel.lua.
require("treasure")       -- Import the functions from treasure.lua.
require("load-behaviors") -- Load bot behavior system (issue 160)
-- require("tempo")       -- Removed: tempo.lua not yet implemented (see wow-chat-1)
-- }}}
--------------------------------------------------------------------------------
-- ReadyPlayers Registry (Issue 328) -- {{{
-- Architectural fix: Only track players/bots that are confirmed ready (have position).
-- Systems that iterate over players should use this registry, NOT GetPlayersInWorld().
-- This eliminates the dangerous state where code runs against unready entities.
--
-- Usage:
--   ReadyPlayers.add(player)      -- Call when player confirmed ready
--   ReadyPlayers.remove(guid)     -- Call on logout
--   ReadyPlayers.getAll()         -- Returns table of ready players
--   ReadyPlayers.isReady(guid)    -- Check if specific player is ready
--
ReadyPlayers = {
    registry = {},  -- guid -> true (just track GUIDs, look up players fresh)
}

-- {{{ ReadyPlayers.add
function ReadyPlayers.add(player)
    if not player then return end
    local guid = player:GetGUID()
    ReadyPlayers.registry[guid] = true
    print("[ReadyPlayers] Added: " .. player:GetName())
end
-- }}}

-- {{{ ReadyPlayers.remove
function ReadyPlayers.remove(guid)
    if ReadyPlayers.registry[guid] then
        ReadyPlayers.registry[guid] = nil
        print("[ReadyPlayers] Removed: " .. tostring(guid))
    end
end
-- }}}

-- {{{ ReadyPlayers.getAll
-- Returns fresh player objects for all registered GUIDs
-- Automatically cleans up stale entries
-- Issue 328: Also validates GetLocation works (IsInWorld is not enough)
function ReadyPlayers.getAll()
    local result = {}
    for guid, _ in pairs(ReadyPlayers.registry) do
        -- Look up player fresh each time (avoids stale userdata)
        local player = GetPlayerByGUID(guid)
        if player and player:IsInWorld() then
            -- Additional validation: ensure GetLocation actually works
            -- IsInWorld() can return true before position is available
            -- GetLocation returns x,y,z,o - we only need x to verify it works
            local ok, x = pcall(function() return player:GetLocation() end)
            if ok and x then
                table.insert(result, player)
            end
            -- Don't remove from registry - player is in world, just not ready yet
        else
            -- Player no longer exists, clean up
            ReadyPlayers.registry[guid] = nil
        end
    end
    return result
end
-- }}}

-- {{{ ReadyPlayers.isReady
function ReadyPlayers.isReady(guid)
    return ReadyPlayers.registry[guid] ~= nil
end
-- }}}
-- }}}
--------------------------------------------------------------------------------
-- globals - spawn timers -- {{{
DELAY_PERIODIC_SPAWN_CREATURE  = 40  * 1000  -- 40  seconds
DELAY_PERIODIC_SPAWN_TRAVELLER = 130 * 1000  -- 130 seconds
DELAY_PERIODIC_SPAWN_TREASURE  = 100 * 1000  -- 100 seconds
-- }}}
--------------------------------------------------------------------------------
-- globals - bot behavior timers -- {{{
-- All bot behaviors are managed centrally through this file (issue 160)
-- Each behavior module exposes an update(bot) function
-- Issue 161: Replaced zone_consensus/level_affinity with traveller-style wandering
-- Issue 164: Behaviors only re-register if in valid mode
DELAY_BOT_WANDER             = 3000   -- ms - traveller-style wandering (issue 161)
DELAY_BOT_LONELINESS_CHECK   = 30000  -- ms - check if lonely, seek others (issue 161)
DELAY_BOT_SIT_AND_REST       = 3000   -- ms - check resources, sit if needed
DELAY_BOT_ORBIT_PLAYER       = 2000   -- ms - formation positioning (party only)
DELAY_BOT_FIND_MONSTERS      = 5000   -- ms - scan for combat targets
DELAY_ORCHESTRATOR_CHECK     = 10000  -- ms - check mode transitions (issue 164)
-- Note: Dungeon cooldown cleanup uses DUNGEON_COOLDOWN from dungeon-rails.lua as delay

-- Boredom/activity selection configuration (issue 165)
BOREDOM_CHANCE_AFTER_COMBAT  = 0.15   -- 15% chance to get bored after combat
BOREDOM_REST_MIN             = 60000  -- ms - minimum rest time (1 minute)
BOREDOM_REST_MAX             = 180000 -- ms - maximum rest time (3 minutes)
-- }}}
--------------------------------------------------------------------------------
-- BotOrchestrator - Mode-based behavior switching (issue 164) -- {{{
-- Bots operate in discrete modes. Each mode has valid behaviors.
-- Periodic events only re-register if still in valid mode.
BotOrchestrator = {}

-- {{{ Mode constants
BotOrchestrator.MODE = {
    WANDERING      = 1,  -- Default: explore the world freely
    DUNGEON_DELVE  = 2,  -- Actively seeking/exploring dungeons
    PROFESSION     = 3,  -- Gathering nodes, crafting items
    SOCIAL         = 4,  -- Stay near players, emote, rest
    COMBAT_SEEK    = 5,  -- Actively hunting monsters
    PARTY_FOLLOW   = 6,  -- In party, defer to playerbots
}
-- }}}

-- {{{ Behavior-to-modes mapping
-- Which modes allow each behavior to run
-- If behavior not listed, it runs in all modes by default
BotOrchestrator.BEHAVIOR_MODES = {
    wander          = { 1, 3, 5 },       -- WANDERING, PROFESSION, COMBAT_SEEK
    loneliness      = { 1 },             -- WANDERING only
    sit_and_rest    = { 1, 2, 3, 4, 5 }, -- All except PARTY_FOLLOW
    find_monsters   = { 1, 2, 5 },       -- WANDERING, DUNGEON_DELVE, COMBAT_SEEK
    orbit_player    = { 4, 6 },          -- SOCIAL, PARTY_FOLLOW
    dungeon_rails   = { 2 },             -- DUNGEON_DELVE only
}
-- }}}

-- {{{ BotOrchestrator.isModeValid
-- Check if a behavior should run in bot's current mode
-- Returns true if behavior is valid, false if should not re-register
function BotOrchestrator.isModeValid(bot, behaviorName)
    local currentMode = bot:GetData("orchestrator_mode") or 1
    local validModes  = BotOrchestrator.BEHAVIOR_MODES[behaviorName]

    -- Unknown behavior = allow by default
    if not validModes then
        return true
    end

    for _, mode in ipairs(validModes) do
        if mode == currentMode then
            return true
        end
    end

    return false
end
-- }}}

-- {{{ BotOrchestrator.getMode
function BotOrchestrator.getMode(bot)
    return bot:GetData("orchestrator_mode") or 1
end
-- }}}

-- {{{ BotOrchestrator.setMode
-- Internal - just sets the data, use switchMode for full transition
function BotOrchestrator.setMode(bot, mode)
    bot:SetData("orchestrator_mode", mode)
end
-- }}}

-- {{{ BotOrchestrator.switchMode
-- Switch bot to a new mode, registering that mode's events
-- Old mode's events will die naturally (fail mode check, don't re-register)
-- Note: This is called DURING GAMEPLAY, not during login
-- By this point, bot is guaranteed to have valid position (Issue 328)
function BotOrchestrator.switchMode(bot, newMode)
    local oldMode = BotOrchestrator.getMode(bot)
    if oldMode == newMode then return end

    BotOrchestrator.setMode(bot, newMode)

    -- Register events appropriate for new mode
    -- Old mode's events will check mode validity and not re-register
    if newMode == BotOrchestrator.MODE.WANDERING then
        bot:RegisterEvent(PeriodicBotWander, DELAY_BOT_WANDER, 1)
        bot:RegisterEvent(PeriodicBotLonelinessCheck, DELAY_BOT_LONELINESS_CHECK, 1)
        bot:RegisterEvent(PeriodicBotSitAndRest, DELAY_BOT_SIT_AND_REST, 1)
        bot:RegisterEvent(PeriodicBotFindMonsters, DELAY_BOT_FIND_MONSTERS, 1)

    elseif newMode == BotOrchestrator.MODE.DUNGEON_DELVE then
        bot:RegisterEvent(PeriodicBotWander, DELAY_BOT_WANDER, 1)  -- Uses dungeon rails internally
        bot:RegisterEvent(PeriodicBotFindMonsters, 3000, 1)  -- Faster in dungeons
        bot:RegisterEvent(PeriodicBotSitAndRest, DELAY_BOT_SIT_AND_REST, 1)

    elseif newMode == BotOrchestrator.MODE.SOCIAL then
        bot:RegisterEvent(PeriodicBotOrbitPlayer, DELAY_BOT_ORBIT_PLAYER, 1)
        bot:RegisterEvent(PeriodicBotSitAndRest, DELAY_BOT_SIT_AND_REST, 1)

    elseif newMode == BotOrchestrator.MODE.COMBAT_SEEK then
        bot:RegisterEvent(PeriodicBotWander, DELAY_BOT_WANDER, 1)
        bot:RegisterEvent(PeriodicBotFindMonsters, 3000, 1)  -- Faster seeking
        bot:RegisterEvent(PeriodicBotSitAndRest, DELAY_BOT_SIT_AND_REST, 1)

    elseif newMode == BotOrchestrator.MODE.PARTY_FOLLOW then
        -- No custom events - playerbots handles everything
        -- All our events will fail mode check and die
    end

    print("[Orchestrator] " .. bot:GetName() .. " switched from mode " ..
          oldMode .. " to " .. newMode)
end
-- }}}

-- {{{ BotOrchestrator.onCombatEnd
-- Called when bot leaves combat. Chance to trigger boredom (issue 165)
function BotOrchestrator.onCombatEnd(bot)
    -- Don't trigger boredom if in party (playerbots handles that)
    if BotOrchestrator.getMode(bot) == BotOrchestrator.MODE.PARTY_FOLLOW then
        return
    end

    -- Don't trigger boredom if already resting for activity
    if bot:GetData("resting_for_activity") then
        return
    end

    -- 30% chance to get bored after combat
    if math.random() < BOREDOM_CHANCE_AFTER_COMBAT then
        BotOrchestrator.triggerBoredom(bot)
    end
end
-- }}}

-- {{{ BotOrchestrator.triggerBoredom
-- Bot sits down to rest before selecting new activity (issue 165)
function BotOrchestrator.triggerBoredom(bot)
    -- Sit down to rest
    bot:SetStandState(1)  -- UNIT_STAND_STATE_SIT
    bot:SetData("resting_for_activity", true)

    -- Random rest time between 1-2 minutes
    local restTime = BOREDOM_REST_MIN + math.random(BOREDOM_REST_MAX - BOREDOM_REST_MIN)

    -- Register one-shot event to select activity after rest
    bot:RegisterEvent(BotOrchestrator.selectActivityCallback, restTime, 1)

    print("[Orchestrator] " .. bot:GetName() .. " is bored, resting before new activity")
end
-- }}}

-- {{{ BotOrchestrator.selectActivityCallback
-- Callback for one-shot rest timer. Selects new activity (issue 165)
function BotOrchestrator.selectActivityCallback(eventID, delay, repeats, bot)
    if not bot:IsBot() then return end
    if not bot:IsAlive() then return end

    -- Clear resting state
    bot:SetData("resting_for_activity", nil)
    bot:SetStandState(0)  -- UNIT_STAND_STATE_STAND

    -- Select new activity
    BotOrchestrator.selectActivity(bot)
end
-- }}}

-- {{{ BotOrchestrator.selectActivity
-- Pick a random activity for the bot (issue 165)
-- Weighted selection: 80% WANDERING, 20% DUNGEON_DELVE
-- Future: PROFESSION, SOCIAL, COMBAT_SEEK with their own weights
function BotOrchestrator.selectActivity(bot)
    local choice

    -- 20% chance to pick dungeon delve
    if math.random() < 0.20 then
        choice = BotOrchestrator.MODE.DUNGEON_DELVE
    else
        choice = BotOrchestrator.MODE.WANDERING
    end

    BotOrchestrator.switchMode(bot, choice)

    local modeNames = {
        [1] = "WANDERING",
        [2] = "DUNGEON_DELVE",
    }
    print("[Orchestrator] " .. bot:GetName() .. " selected activity: " ..
          (modeNames[choice] or tostring(choice)))
end
-- }}}
-- }}}
--------------------------------------------------------------------------------
-- spirit world tracking -- {{{
-- Players who log in dead are tracked here until they resurrect
local denizens_of_the_spirit_world = {}
-- }}}
--------------------------------------------------------------------------------

-- {{{ spiritHeartbeat
-- Check if dead players have resurrected and re-register their events
local function spiritHeartbeat()
    local next = next
    if next(denizens_of_the_spirit_world) == nil then
        print("no spirits, returning")
        return
    end
    for guid, isDead in pairs(denizens_of_the_spirit_world) do
        local player = GetPlayerByGUID(guid)
        if player ~= nil then -- if player is not logged out
            if not player:IsDead() then
                print("player is no longer dead, removing from spirit world")
                denizens_of_the_spirit_world[guid] = nil
                InitialLogin(nil, player)
            end
        end
    end
    CreateLuaEvent(spiritHeartbeat, 1000, 1)
end
-- }}}

--------------------------------------------------------------------------------

-- {{{ periodicEvent
-- Register a periodic event for a player, handling dead state
-- ALE signature: RegisterEvent(func, delay, repeats) - worldobject passed to callback automatically
local function periodicEvent(eventFunction, delay, repeats, player)
    if player:IsDead() then
        if denizens_of_the_spirit_world[player:GetGUID()] == nil then
            denizens_of_the_spirit_world[player:GetGUID()] = true
        end
        return
    else
        player:RegisterEvent(eventFunction, delay, repeats)
    end
end
-- }}}

--------------------------------------------------------------------------------
-- Player Spawn Events (ambush, travellers, treasure)
--------------------------------------------------------------------------------

-- {{{ PeriodicSpawnAmbush
function PeriodicSpawnAmbush(eventID, delay, repeats, player)
    periodicEvent(PeriodicSpawnAmbush, delay, repeats, player)
    if not player:IsStandState()                then print("no ambush - player is sitting down")
    elseif player:IsDead()                      then print("no ambush - player is dead")
    elseif player:IsInWater()                   then print("no ambush - player is in water")
    elseif player:GetData("num-ambushers") >= 3 then print("no ambush - too many ambushers")
    elseif player:GetData("is-in-boss-fight")   then print("no ambush - in boss fight")
       -- is stealthed ehhhhh whatever FIXME
       -- (will never get fixed RIP T.T
    elseif player:GetData("is-in-boss-fight")   then print("no ambush - in boss fight")
    else
        Ambush.spawnAndAttackPlayer(nil, nil, nil, player)
    end
end
-- }}}

-- {{{ PeriodicSpawnTravellers
function PeriodicSpawnTravellers(eventID, delay, repeats, player)
    periodicEvent(PeriodicSpawnTravellers, delay, repeats, player)
    if player:IsDead() or player:IsInWater() or not player:IsStandState() then
        print("skipping traveller spawn")
        return
    else
        Travel.spawnAndTravel(player)
    end
end
-- }}}

-- {{{ PeriodicSpawnTreasure
function PeriodicSpawnTreasure(eventID, delay, repeats, player)
    periodicEvent(PeriodicSpawnTreasure, delay, repeats, player) -- FIXME add if is stealthed
                                                                 --       and
                                                                 --       for
                                                                 --       ambushes
    if player:IsDead() or player:IsInWater() or not player:IsStandState() then
        print("skipping treasure spawn")
        return
    else
        Treasure.spawnTreasure(player)
    end
end
-- }}}

--------------------------------------------------------------------------------
-- Bot Behavior Events (wandering, loneliness, etc.)
-- These only run for playerbots, not real players
-- Issue 161: Replaced zone_consensus/level_affinity with traveller-style wandering
--------------------------------------------------------------------------------

-- {{{ botHasValidPosition
-- Check if bot has valid position (Issue 328)
-- Returns true if GetLocation works, false otherwise
-- GetLocation returns x,y,z,o - we only check x to verify availability
local function botHasValidPosition(bot)
    local ok, x = pcall(function() return bot:GetLocation() end)
    return ok and x ~= nil
end
-- }}}

-- {{{ PeriodicBotWander
-- Traveller-style wandering with fallbacks (issue 161)
-- Includes dungeon navigation when in caves/dungeons (issue 162)
-- Mode check: only re-registers if in valid mode (issue 164)
function PeriodicBotWander(eventID, delay, repeats, bot)
    if not bot:IsBot() then return end
    if not bot:IsAlive() then return end
    if not botHasValidPosition(bot) then return end  -- Issue 328
    if not BotOrchestrator.isModeValid(bot, "wander") then return end

    periodicEvent(PeriodicBotWander, delay, repeats, bot)
    if BotWander and BotWander.update then
        BotWander.update(bot)
    end
end
-- }}}

-- {{{ PeriodicBotLonelinessCheck
-- Check if bot is lonely (no valid players nearby) every 30s (issue 161)
-- Mode check: only re-registers if in valid mode (issue 164)
function PeriodicBotLonelinessCheck(eventID, delay, repeats, bot)
    if not bot:IsBot() then return end
    if not bot:IsAlive() then return end
    if not botHasValidPosition(bot) then return end  -- Issue 328
    if not BotOrchestrator.isModeValid(bot, "loneliness") then return end

    periodicEvent(PeriodicBotLonelinessCheck, delay, repeats, bot)
    if BotWander and BotWander.lonelinessCheck then
        BotWander.lonelinessCheck(bot)
    end
end
-- }}}

-- {{{ PeriodicDungeonCooldownCleanup
-- One-shot cleanup after dungeon cooldown expires (issue 162)
-- Registered by DungeonRails.exitDungeon() with delay = cooldown time
-- Fires once, cleans up, done. No re-registration.
function PeriodicDungeonCooldownCleanup(eventID, delay, repeats, bot)
    if not bot:IsBot() then return end

    -- Cooldown has expired (delay was the cooldown time)
    bot:SetData("last_dungeon_exit", nil)
    print("[DungeonRails] Cooldown expired for " .. bot:GetName())
    -- No re-registration - one-shot event
end
-- }}}

-- {{{ PeriodicBotSitAndRest
-- Check resources and sit if needed
-- Mode check: only re-registers if in valid mode (issue 164)
function PeriodicBotSitAndRest(eventID, delay, repeats, bot)
    if not bot:IsBot() then return end
    if not bot:IsAlive() then return end
    if not botHasValidPosition(bot) then return end  -- Issue 328
    if not BotOrchestrator.isModeValid(bot, "sit_and_rest") then return end

    periodicEvent(PeriodicBotSitAndRest, delay, repeats, bot)
    if SitAndRest and SitAndRest.checkAndRest then
        SitAndRest.checkAndRest(bot)
    end
end
-- }}}

-- {{{ PeriodicBotOrbitPlayer
-- Formation positioning around party leader
-- Mode check: only re-registers if in valid mode (issue 164)
function PeriodicBotOrbitPlayer(eventID, delay, repeats, bot)
    if not bot:IsBot() then return end
    if not bot:IsAlive() then return end
    if not botHasValidPosition(bot) then return end  -- Issue 328
    if not BotOrchestrator.isModeValid(bot, "orbit_player") then return end

    periodicEvent(PeriodicBotOrbitPlayer, delay, repeats, bot)
    if OrbitPlayer and OrbitPlayer.updatePosition then
        OrbitPlayer.updatePosition(bot)
    end
end
-- }}}

-- {{{ PeriodicBotFindMonsters
-- Scan for combat targets
-- Mode check: only re-registers if in valid mode (issue 164)
function PeriodicBotFindMonsters(eventID, delay, repeats, bot)
    if not bot:IsBot() then return end
    if not bot:IsAlive() then return end
    if not botHasValidPosition(bot) then return end  -- Issue 328
    if not BotOrchestrator.isModeValid(bot, "find_monsters") then return end

    periodicEvent(PeriodicBotFindMonsters, delay, repeats, bot)
    if FindMonsters and FindMonsters.scan then
        FindMonsters.scan(bot)
    end
end
-- }}}

--------------------------------------------------------------------------------
-- Login Event Registration
--------------------------------------------------------------------------------

-- Delay before first "wait for ready" check (ms)
-- Gives playerbots time to finish internal setup
local DELAY_BOT_READY_CHECK = 500

-- {{{ registerBotBehaviors
-- Register all behavior events for a bot that is confirmed ready
-- Called by WaitForBotReady after position is confirmed available
local function registerBotBehaviors(bot)
    -- Bot is confirmed ready - add to registry (Issue 328)
    ReadyPlayers.add(bot)

    -- Initialize orchestrator mode (WANDERING by default)
    BotOrchestrator.setMode(bot, BotOrchestrator.MODE.WANDERING)

    periodicEvent(PeriodicBotWander,
                  DELAY_BOT_WANDER,
                  1,
                  bot)
    periodicEvent(PeriodicBotLonelinessCheck,
                  DELAY_BOT_LONELINESS_CHECK,
                  1,
                  bot)
    periodicEvent(PeriodicBotSitAndRest,
                  DELAY_BOT_SIT_AND_REST,
                  1,
                  bot)
    periodicEvent(PeriodicBotOrbitPlayer,
                  DELAY_BOT_ORBIT_PLAYER,
                  1,
                  bot)
    periodicEvent(PeriodicBotFindMonsters,
                  DELAY_BOT_FIND_MONSTERS,
                  1,
                  bot)
    -- Note: PeriodicDungeonCooldownCleanup is one-shot, registered by exitDungeon()
    print("[PeriodicEvents] Bot " .. bot:GetName() .. " ready, behaviors registered")
end
-- }}}

-- {{{ Pending bot ready checks
-- Store GUIDs of bots waiting to be ready, avoid holding stale references
-- Issue 328: Using GUID lookup prevents segfaults from stale bot pointers
local pending_bot_ready = {}  -- [guid] = { attempts = n }
local MAX_READY_ATTEMPTS = 20  -- Give up after 10 seconds (20 * 500ms)
-- }}}

-- {{{ checkPendingBotReady
-- Global timer callback - checks all pending bots for readiness
-- Uses CreateLuaEvent instead of bot:RegisterEvent to avoid segfaults
local function checkPendingBotReady()
    local still_pending = false

    for guid, data in pairs(pending_bot_ready) do
        -- Look up bot fresh by GUID (never hold stale references)
        local bot = GetPlayerByGUID(guid)

        if not bot then
            -- Bot logged out, remove from pending
            pending_bot_ready[guid] = nil
        else
            -- Check if bot has valid position (GetLocation returns x,y,z,o)
            local ok, x = pcall(function() return bot:GetLocation() end)

            if ok and x then
                -- Bot is ready! Register behaviors
                pending_bot_ready[guid] = nil
                registerBotBehaviors(bot)
            else
                -- Not ready yet, increment attempts
                data.attempts = data.attempts + 1
                if data.attempts >= MAX_READY_ATTEMPTS then
                    -- Give up after too many attempts
                    local name = "unknown"
                    local nameOk, n = pcall(function() return bot:GetName() end)
                    if nameOk and n then name = n end
                    print("[WaitForBotReady] Giving up on " .. name .. " after " .. data.attempts .. " attempts")
                    pending_bot_ready[guid] = nil
                else
                    still_pending = true
                end
            end
        end
    end

    -- Re-register if there are still pending bots
    if still_pending then
        CreateLuaEvent(checkPendingBotReady, DELAY_BOT_READY_CHECK, 1)
    end
end
-- }}}

-- {{{ WaitForBotReady
-- Queue a bot to be checked for readiness
-- Issue 328: Don't access bot object directly, just store GUID
-- Uses global timer to avoid segfaults from stale entity references
function WaitForBotReady(bot)
    if not bot then return end

    local guid = bot:GetGUID()
    if not guid then return end

    -- Add to pending list
    pending_bot_ready[guid] = { attempts = 0 }

    -- Start the checker if this is the first pending bot
    local count = 0
    for _ in pairs(pending_bot_ready) do count = count + 1 end
    if count == 1 then
        CreateLuaEvent(checkPendingBotReady, DELAY_BOT_READY_CHECK, 1)
    end
end
-- }}}

-- {{{ InitialLogin
-- Register all periodic events when a player or bot logs in
function InitialLogin(_event, player)
    -- Debug: Log every login event (Issue 328 investigation)
    local isBot = player:IsBot()
    print("[InitialLogin] " .. player:GetName() .. " (isBot=" .. tostring(isBot) .. ")")

    if player:IsDead() then
        denizens_of_the_spirit_world[player:GetGUID()] = true
        CreateLuaEvent(spiritHeartbeat, 1000, 1)
        return
    end

    -- Track login time for level affinity (fresh login detection)
    if LevelAffinity and LevelAffinity.trackLogin then
        LevelAffinity.trackLogin(player)
    end

    -- Real players: spawn events (players are ready immediately)
    if not player:IsBot() then
        -- Real players are ready immediately - add to registry (Issue 328)
        ReadyPlayers.add(player)

        periodicEvent(PeriodicSpawnAmbush,
                      DELAY_PERIODIC_SPAWN_CREATURE,
                      1,
                      player)
        periodicEvent(PeriodicSpawnTravellers,
                      DELAY_PERIODIC_SPAWN_TRAVELLER,
                      1,
                      player)
        periodicEvent(PeriodicSpawnTreasure,
                      DELAY_PERIODIC_SPAWN_TREASURE,
                      1,
                      player)
        print("[PeriodicEvents] Registered spawn events for player: " .. player:GetName())
    end

    -- Bots: register behavior events with longer initial delay
    -- Issue 328: botHasValidPosition check in each behavior protects against early calls
    -- Issue 161: Traveller-style wandering
    -- Issue 164: Behaviors only re-register if in valid mode
    if player:IsBot() then
        -- Add to ready registry (bot may not have position yet, but behaviors will check)
        ReadyPlayers.add(player)

        -- Initialize orchestrator mode (WANDERING by default)
        BotOrchestrator.setMode(player, BotOrchestrator.MODE.WANDERING)

        -- Register behaviors with longer initial delay (5 seconds)
        -- If bot isn't ready when they fire, botHasValidPosition will skip and re-register
        local INITIAL_BOT_DELAY = 5000  -- 5 seconds - give bot time to initialize
        periodicEvent(PeriodicBotWander,           INITIAL_BOT_DELAY, 1, player)
        periodicEvent(PeriodicBotLonelinessCheck,  INITIAL_BOT_DELAY + 1000, 1, player)
        periodicEvent(PeriodicBotSitAndRest,       INITIAL_BOT_DELAY + 2000, 1, player)
        periodicEvent(PeriodicBotOrbitPlayer,      INITIAL_BOT_DELAY + 3000, 1, player)
        periodicEvent(PeriodicBotFindMonsters,     INITIAL_BOT_DELAY + 4000, 1, player)
        print("[PeriodicEvents] Bot " .. player:GetName() .. " behaviors queued (5s delay)")
    end
end
-- }}}

-- {{{ Logout handler
-- Clean up login tracking on logout
local function OnPlayerLogout(_event, player)
    -- Remove from ready registry (Issue 328)
    ReadyPlayers.remove(player:GetGUID())

    if LevelAffinity and LevelAffinity.trackLogout then
        LevelAffinity.trackLogout(player)
    end

    -- Clean up object variable data to prevent memory leaks (Issue 332)
    if ObjectVariables and ObjectVariables.cleanupPlayer then
        ObjectVariables.cleanupPlayer(player)
    end
end
-- }}}

--------------------------------------------------------------------------------
-- Combat/Group Event Handlers (issue 165)
--------------------------------------------------------------------------------

-- {{{ OnPlayerLeaveCombat
-- Triggers boredom check when bot leaves combat
local function OnPlayerLeaveCombat(_event, player)
    if not player:IsBot() then return end
    if not player:IsAlive() then return end

    BotOrchestrator.onCombatEnd(player)
end
-- }}}

-- {{{ OnGroupMemberAdd
-- Switch bot to PARTY_FOLLOW when joining a group
local function OnGroupMemberAdd(_event, group, guid)
    local player = GetPlayerByGUID(guid)
    if not player then return end
    if not player:IsBot() then return end

    BotOrchestrator.switchMode(player, BotOrchestrator.MODE.PARTY_FOLLOW)
end
-- }}}

-- {{{ OnGroupMemberRemove
-- Trigger activity selection when bot leaves a group
local function OnGroupMemberRemove(_event, group, guid, method, kicker, reason)
    local player = GetPlayerByGUID(guid)
    if not player then return end
    if not player:IsBot() then return end

    -- Small delay before resuming independent activity
    -- Let playerbots settle, then trigger boredom->activity selection
    BotOrchestrator.triggerBoredom(player)
end
-- }}}

-- {{{ OnGroupDisband
-- Trigger activity selection for all bots when group disbands
local function OnGroupDisband(_event, group)
    -- Group object may still have members at this point
    -- Each member will receive OnGroupMemberRemove separately
    -- So we don't need to iterate here
end
-- }}}

--------------------------------------------------------------------------------
-- Event Registration
--------------------------------------------------------------------------------
local PLAYER_EVENT_ON_LOGIN        = 3
local PLAYER_EVENT_ON_LOGOUT       = 4
local PLAYER_EVENT_ON_LEAVE_COMBAT = 34

local GROUP_EVENT_ON_MEMBER_ADD    = 1
local GROUP_EVENT_ON_MEMBER_REMOVE = 3
local GROUP_EVENT_ON_DISBAND       = 5

RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, InitialLogin)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT, OnPlayerLogout)
RegisterPlayerEvent(PLAYER_EVENT_ON_LEAVE_COMBAT, OnPlayerLeaveCombat)

RegisterGroupEvent(GROUP_EVENT_ON_MEMBER_ADD, OnGroupMemberAdd)
RegisterGroupEvent(GROUP_EVENT_ON_MEMBER_REMOVE, OnGroupMemberRemove)
RegisterGroupEvent(GROUP_EVENT_ON_DISBAND, OnGroupDisband)

print("[PeriodicEvents] Centralized event system loaded (with boredom/activity hooks)")
--------------------------------------------------------------------------------
