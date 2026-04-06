# 165 - Activity Selection and Boredom System

## Status
- Created: 2026-04-05
- Implemented: 2026-04-05
- Phase: 2
- Priority: High
- Depends: 164 (behavior orchestrator modes)
- Status: Implemented (needs testing)

## Current Behavior
- Bots wander indefinitely in WANDERING mode
- Only enter dungeons if they stumble into one while wandering
- No concept of "getting bored" or choosing activities
- Mode transitions not implemented

## Intended Behavior
Bots periodically get "bored" and choose a new activity.

### Boredom Flow
1. **Trigger** (event-driven):
   - Combat ends
   - Random chance while idle (low probability)
   - Future: task completion, long travel time, etc.

2. **Rest Period**:
   - Bot sits down
   - Rests for 1-3 minutes (random)
   - Recovers health/mana

3. **Activity Selection**:
   - After rest completes, randomly pick new activity
   - Current options: WANDERING, DUNGEON_DELVE
   - Future: PROFESSION, SOCIAL, COMBAT_SEEK

4. **Activity Execution**:
   - WANDERING: Normal traveller-style movement
   - DUNGEON_DELVE: Seek out nearest dungeon, enter, explore

### Event-Driven Transitions
| Event | Action |
|-------|--------|
| Combat ends | Chance to trigger boredom |
| Party join | Switch to PARTY_FOLLOW |
| Party leave | Trigger activity selection |
| Rest completes | Pick new activity |
| Near dungeon entrance (while DUNGEON_DELVE) | Enter dungeon |

### Dungeon Seeking
When in DUNGEON_DELVE mode but not in a dungeon:
- Bot should actively travel toward nearest known dungeon entrance
- Use zone data or heuristics to find dungeon areas
- When near entrance, enter dungeon (DungeonRails takes over)

## Implementation

### Step 1: Event Hooks
```lua
-- Combat end hook
local PLAYER_EVENT_ON_KILL_CREATURE = 7  -- or similar
RegisterPlayerEvent(PLAYER_EVENT_ON_KILL_CREATURE, function(event, player, creature)
    if player:IsBot() and not player:IsInCombat() then
        -- Combat just ended (killed last enemy)
        BotOrchestrator.onCombatEnd(player)
    end
end)

-- Party hooks
local PLAYER_EVENT_ON_GROUP_JOIN = ?
local PLAYER_EVENT_ON_GROUP_LEAVE = ?
```

### Step 2: Boredom Check
```lua
-- {{{ BotOrchestrator.onCombatEnd
function BotOrchestrator.onCombatEnd(bot)
    -- 15% chance to get bored after combat
    if math.random() < 0.15 then
        BotOrchestrator.triggerBoredom(bot)
    end
end
-- }}}
```

### Step 3: Rest and Select
```lua
-- {{{ BotOrchestrator.triggerBoredom
function BotOrchestrator.triggerBoredom(bot)
    -- Sit down to rest
    bot:SetStandState(1)  -- UNIT_STAND_STATE_SIT
    bot:SetData("resting_for_activity", true)

    -- Register one-shot event to select activity after rest
    local restTime = (60 + math.random(120)) * 1000  -- 1-3 minutes
    bot:RegisterEvent(BotOrchestrator.selectActivity, restTime, 1)
end
-- }}}

-- {{{ BotOrchestrator.selectActivity
function BotOrchestrator.selectActivity(eventID, delay, repeats, bot)
    bot:SetData("resting_for_activity", nil)
    bot:SetStandState(0)  -- Stand up

    -- Random selection (for now)
    local activities = {
        BotOrchestrator.MODE.WANDERING,
        BotOrchestrator.MODE.DUNGEON_DELVE,
    }
    local choice = activities[math.random(#activities)]

    BotOrchestrator.switchMode(bot, choice)
end
-- }}}
```

### Step 4: Dungeon Seeking Behavior
When in DUNGEON_DELVE mode but `DungeonRails.isInDungeon(bot)` is false:
- Move toward nearest dungeon zone
- For now: wander with bias toward cave/dungeon areas
- Future: use known dungeon entrance positions

```lua
-- In BotWander.update() or separate behavior:
if BotOrchestrator.getMode(bot) == BotOrchestrator.MODE.DUNGEON_DELVE then
    if not DungeonRails.isInDungeon(bot) then
        -- Seeking dungeon - bias movement toward dungeon areas
        DungeonRails.seekEntrance(bot)
        return
    end
end
```

## Bot Data Keys
```lua
bot:GetData("resting_for_activity")  -- true while sitting before activity select
```

## ALE Event Constants
Verified from docs/ale/docs/Global/:
- PLAYER_EVENT_ON_LEAVE_COMBAT = 34 (event, player)
- GROUP_EVENT_ON_MEMBER_ADD = 1 (event, group, guid)
- GROUP_EVENT_ON_MEMBER_REMOVE = 3 (event, group, guid, method, kicker, reason)
- GROUP_EVENT_ON_DISBAND = 5 (event, group)

## Testing
1. Bot finishes combat → 15% chance sits down to rest
2. After 1-3 minutes → stands up, picks activity (80% wander, 20% dungeon)
3. If DUNGEON_DELVE → seeks dungeon entrance
4. Party invite → switches to PARTY_FOLLOW
5. Party leave → triggers activity selection

## Future Activities
- PROFESSION: Seek gathering nodes, craft items
- SOCIAL: Seek other players, emote, hang out
- COMBAT_SEEK: Actively hunt monsters (not wait for ambush)

## Related Issues
- 164: Behavior orchestrator modes
- 161: Bot wandering
- 162: Dungeon pathfinding
- 166: Point/line definition tools (for cave/dungeon entrances)

## Notes
- Activity selection is weighted: 80% wander, 20% dungeon delve
- Cave/dungeon seeking requires manual entrance definitions (see issue 166)
- Boredom chance after combat is 15% - tunable via BOREDOM_CHANCE_AFTER_COMBAT
- Rest period is 1-3 minutes - tunable via BOREDOM_REST_MIN/MAX
