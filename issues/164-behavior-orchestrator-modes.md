# 164 - Behavior Orchestrator: Mode-Based Activity Switching

## Status
- Created: 2026-04-05
- Implemented: 2026-04-05 (foundation)
- Phase: 2
- Priority: High
- Depends: 161 (bot wandering), 162 (dungeon rails)
- Status: Foundation implemented (mode checking, behavior-to-modes mapping)
- Remaining: Mode transition logic (PeriodicOrchestratorCheck)

## Current Behavior
- All bot behaviors registered simultaneously on login
- Behaviors compete for movement control (last MoveTo wins)
- No concept of "what activity is the bot doing"
- Periodic events always re-register themselves
- Dungeon navigation only happens if bot stumbles into cave

## Intended Behavior
Bots operate in discrete **modes** (activity pages). Each mode has:
- A set of valid behaviors that run in that mode
- Transition conditions to switch to other modes
- Periodic events that only re-register if still in valid mode

### Modes
```lua
MODE_WANDERING      = 1  -- Default: explore the world freely
MODE_DUNGEON_DELVE  = 2  -- Actively seeking/exploring dungeons
MODE_PROFESSION     = 3  -- Gathering nodes, crafting items
MODE_SOCIAL         = 4  -- Stay near players, emote, rest
MODE_COMBAT_SEEK    = 5  -- Actively hunting monsters
MODE_PARTY_FOLLOW   = 6  -- In party, defer to playerbots
```

### Mode-Behavior Mapping
| Mode | Behaviors |
|------|-----------|
| WANDERING | Wander, LonelinessCheck, SitAndRest, FindMonsters |
| DUNGEON_DELVE | DungeonRails, FindMonsters, SitAndRest |
| PROFESSION | GatherNodes, Wander (slow), SitAndRest |
| SOCIAL | OrbitPlayer, Gestures, SitAndRest |
| COMBAT_SEEK | FindMonsters (fast), Wander, SitAndRest |
| PARTY_FOLLOW | (defer to playerbots) |

### Periodic Event Pattern
Each periodic event:
1. Checks if current mode is valid for this behavior
2. If not valid: return without re-registering (event dies)
3. If valid: do work, then re-register

```lua
function PeriodicBotWander(eventID, delay, repeats, bot)
    -- Mode check first
    if not BotOrchestrator.isModeValid(bot, "wander") then
        return  -- Don't re-register
    end

    -- Re-register for next tick
    periodicEvent(PeriodicBotWander, delay, repeats, bot)

    -- Do actual work
    BotWander.update(bot)
end
```

### Mode Transitions
Checked by orchestrator periodic event (every 5-10 seconds):

| From | To | Condition |
|------|----|-----------|
| WANDERING | DUNGEON_DELVE | Near dungeon + not on cooldown + random chance |
| WANDERING | PARTY_FOLLOW | Joined a party |
| WANDERING | COMBAT_SEEK | Low nearby monsters, seeking targets |
| DUNGEON_DELVE | WANDERING | Exited dungeon or too hard |
| PARTY_FOLLOW | WANDERING | Party disbanded (after 3s delay) |
| * | SOCIAL | Low health/mana + near players |

## Implementation

### Step 1: Define Mode Constants and Mappings
Add to `periodic_events.lua` or new `orchestrator.lua`:

```lua
BotOrchestrator = {}

-- {{{ Mode constants
BotOrchestrator.MODE = {
    WANDERING      = 1,
    DUNGEON_DELVE  = 2,
    PROFESSION     = 3,
    SOCIAL         = 4,
    COMBAT_SEEK    = 5,
    PARTY_FOLLOW   = 6,
}
-- }}}

-- {{{ Behavior-to-modes mapping
-- Which modes allow each behavior to run
BotOrchestrator.BEHAVIOR_MODES = {
    wander          = { 1, 3, 5 },      -- WANDERING, PROFESSION, COMBAT_SEEK
    loneliness      = { 1 },            -- WANDERING only
    sit_and_rest    = { 1, 2, 3, 4, 5 }, -- All except PARTY_FOLLOW
    find_monsters   = { 1, 2, 5 },      -- WANDERING, DUNGEON_DELVE, COMBAT_SEEK
    orbit_player    = { 4 },            -- SOCIAL only
    dungeon_rails   = { 2 },            -- DUNGEON_DELVE only
    dungeon_cleanup = { 2 },            -- DUNGEON_DELVE only (one-shot after exit)
}
-- }}}
```

### Step 2: Mode Validation Function

```lua
-- {{{ BotOrchestrator.isModeValid
-- Check if a behavior should run in current mode
function BotOrchestrator.isModeValid(bot, behaviorName)
    local currentMode = bot:GetData("orchestrator_mode") or 1
    local validModes = BotOrchestrator.BEHAVIOR_MODES[behaviorName]

    if not validModes then
        return true  -- Unknown behavior, allow by default
    end

    for _, mode in ipairs(validModes) do
        if mode == currentMode then
            return true
        end
    end

    return false
end
-- }}}
```

### Step 3: Update All Periodic Events
Add mode check at top of each function:

```lua
function PeriodicBotWander(eventID, delay, repeats, bot)
    if not bot:IsBot() or not bot:IsAlive() then return end
    if not BotOrchestrator.isModeValid(bot, "wander") then return end

    periodicEvent(PeriodicBotWander, delay, repeats, bot)
    BotWander.update(bot)
end
```

### Step 4: Mode Switching Function

```lua
-- {{{ BotOrchestrator.switchMode
function BotOrchestrator.switchMode(bot, newMode)
    local oldMode = bot:GetData("orchestrator_mode") or 1
    if oldMode == newMode then return end

    bot:SetData("orchestrator_mode", newMode)

    -- Register events for new mode
    BotOrchestrator.registerModeEvents(bot, newMode)

    print("[Orchestrator] " .. bot:GetName() ..
          " switched from mode " .. oldMode .. " to " .. newMode)
end
-- }}}

-- {{{ BotOrchestrator.registerModeEvents
function BotOrchestrator.registerModeEvents(bot, mode)
    -- Each mode registers its relevant events
    -- Old mode's events will die naturally (fail mode check, don't re-register)

    if mode == 1 then  -- WANDERING
        bot:RegisterEvent(PeriodicBotWander, DELAY_BOT_WANDER, 1)
        bot:RegisterEvent(PeriodicBotLonelinessCheck, DELAY_BOT_LONELINESS_CHECK, 1)
        bot:RegisterEvent(PeriodicBotSitAndRest, DELAY_BOT_SIT_AND_REST, 1)
        bot:RegisterEvent(PeriodicBotFindMonsters, DELAY_BOT_FIND_MONSTERS, 1)
    elseif mode == 2 then  -- DUNGEON_DELVE
        bot:RegisterEvent(PeriodicBotDungeonDelve, DELAY_BOT_WANDER, 1)
        bot:RegisterEvent(PeriodicBotFindMonsters, 3000, 1)  -- faster in dungeons
        bot:RegisterEvent(PeriodicBotSitAndRest, DELAY_BOT_SIT_AND_REST, 1)
    -- etc.
    end
end
-- }}}
```

### Step 5: Orchestrator Periodic Check

```lua
-- {{{ PeriodicOrchestratorCheck
-- Runs every 10 seconds, checks if mode should change
function PeriodicOrchestratorCheck(eventID, delay, repeats, bot)
    if not bot:IsBot() or not bot:IsAlive() then return end

    -- Always re-register - orchestrator always runs
    periodicEvent(PeriodicOrchestratorCheck, delay, repeats, bot)

    local currentMode = bot:GetData("orchestrator_mode") or 1

    -- Check transitions based on current mode
    if currentMode == 1 then  -- WANDERING
        -- Check for party
        if bot:GetGroup() then
            BotOrchestrator.switchMode(bot, 6)  -- PARTY_FOLLOW
            return
        end

        -- Check for nearby dungeon (30% chance to delve)
        if DungeonRails.isNearEntrance(bot) and
           DungeonRails.canEnterDungeon(bot) and
           math.random() < 0.30 then
            BotOrchestrator.switchMode(bot, 2)  -- DUNGEON_DELVE
            return
        end

    elseif currentMode == 2 then  -- DUNGEON_DELVE
        -- Check if exited dungeon
        if not DungeonRails.isInDungeon(bot) then
            BotOrchestrator.switchMode(bot, 1)  -- WANDERING
            return
        end

    elseif currentMode == 6 then  -- PARTY_FOLLOW
        -- Check if party disbanded
        if not bot:GetGroup() then
            -- Small delay before resuming wander
            local partyLeft = bot:GetData("party_left_time")
            if not partyLeft then
                bot:SetData("party_left_time", os.time())
            elseif os.time() - partyLeft >= 3 then
                bot:SetData("party_left_time", nil)
                BotOrchestrator.switchMode(bot, 1)  -- WANDERING
            end
        end
    end
end
-- }}}
```

## Bot Data Keys
```lua
bot:GetData("orchestrator_mode")    -- Current mode (1-6)
bot:GetData("party_left_time")      -- Timestamp when party disbanded
```

## Testing
1. Bot spawns in WANDERING mode by default
2. Invite bot to party - switches to PARTY_FOLLOW
3. Disband party - switches back to WANDERING after 3s
4. Bot near cave entrance - 30% chance to switch to DUNGEON_DELVE
5. Bot exits dungeon - switches back to WANDERING
6. Mode-invalid behaviors don't re-register (check logs for absence)

## Future Modes
- PROFESSION: Requires gathering/crafting systems
- SOCIAL: Requires gesture expansion
- COMBAT_SEEK: Requires threat awareness

## Related Issues
- 161: Bot wandering (WANDERING mode default)
- 162: Dungeon rails (DUNGEON_DELVE mode)
- 160: Behavior system integration

## Notes
- Playerbots still handles combat rotations in all modes
- PARTY_FOLLOW defers movement entirely to playerbots
- Mode transitions are probabilistic for variety
- Orchestrator check runs regardless of mode (always re-registers)
