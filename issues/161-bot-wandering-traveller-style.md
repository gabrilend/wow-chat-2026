# 161 - Bot Wandering: Traveller Style Movement

## Status
- Created: 2026-04-05
- Implemented: 2026-04-05
- Phase: 2
- Priority: High
- Depends: 160 (behavior system integration)
- Status: Implemented (needs testing)

## Current Behavior
- Bots use goal-oriented movement (always moving toward something)
- ZoneConsensus: drifts bots toward average player facing direction every tick
- LevelAffinity: complex scoring with travelling salesman heuristics
- OrbitPlayer: formation positioning around party leader
- No persistent direction state - recalculated each tick
- No height validation like travellers have
- Different intervals, different patterns

## Intended Behavior
Bots should wander like traveller NPCs by default, with fallbacks when stuck.

### Movement Hierarchy

1. **Default: Traveller-style wandering**
   - Use `Movement.generateNewWanderPosition()` with persistent theta
   - Same parameters: 10 yards forward, ±0.39 radian drift
   - Same height validation: ±5 yards elevation limit
   - Walking speed (`SetWalk(true)`)
   - Interval: 2-4 seconds (random, like travellers)

2. **Wall-hit fallback (3 consecutive invalid height checks)**
   - Each check tries slightly different angle
   - After 3 failures: reorient theta to zone consensus
   - Zone consensus = average facing direction of all players in **zone** (not map cell)
   - Resume wandering with new theta

3. **Continued wall-hit (3 more failures after reorientation)**
   - Give up wandering temporarily
   - Move toward nearest level-appropriate player/bot (±3 levels)
   - Pick position on ring around them (one-shot move, not orbit)
   - After arriving, resume normal wandering

4. **Loneliness check (every ~30 seconds)**
   - Separate periodic event, longer interval
   - Check: any players/bots within ±3 levels AND within ~100 yards?
   - If lonely: find nearest valid player/bot (±3 levels, any distance)
   - Move to position on ring around them
   - Resume normal wandering after arrival

### What Gets Removed
- Complex level affinity scoring (50% threshold, 75% opposite spectrum)
- Travelling salesman heuristics (overkill for ±3 level range)
- Constant drift toward consensus direction
- Zone consensus as default behavior

### What Gets Reused
- `Movement.generateNewWanderPosition()` - exact same function as travellers
- `ZoneConsensus.averageAngles()` - for calculating zone consensus direction
- Height validation pattern from travellers
- Periodic event structure from periodic_events.lua

## Implementation Steps

### Step 1: Create BotWander behavior
New file: `src/lua/behaviors/bot-wander.lua`
- Store persistent theta on bot via `bot:SetData("theta", value)`
- Track wall-hit count via `bot:SetData("wall_hits", count)`
- Main function: `BotWander.update(bot)` called by periodic_events.lua

### Step 2: Refactor ZoneConsensus
- Remove `driftWithConsensus()` - no longer default behavior
- Keep `calculateZoneConsensus()` and `averageAngles()` as utilities
- Add `ZoneConsensus.getZoneDirection(bot)` - returns average facing for bot's zone
- Zone = actual WoW zone (GetZoneId), not grid cell

### Step 3: Simplify LevelAffinity
- Remove travelling salesman scoring
- Simple function: `LevelAffinity.findNearestValid(bot, levelRange)`
- Returns nearest player/bot within ±levelRange levels
- Keep `getIdleDestination()` for ring positioning

### Step 4: Update periodic_events.lua
- Replace multiple behavior events with single `PeriodicBotWander`
- Add separate `PeriodicBotLonelinessCheck` at 30 second interval
- Remove: PeriodicBotZoneConsensus, PeriodicBotLevelAffinity (merged into wander)
- Keep: PeriodicBotSitAndRest, PeriodicBotOrbitPlayer, PeriodicBotFindMonsters

### Step 5: Remove orbit-player for bots
- OrbitPlayer was for monster behavior (ambush mobs circling player)
- Bots don't orbit - they pick a ring position and stop
- May keep OrbitPlayer for party formation (different use case)

## Timer Configuration
```lua
DELAY_BOT_WANDER           = 3000   -- ms - main wandering (2-4s random)
DELAY_BOT_LONELINESS_CHECK = 30000  -- ms - lonely check
DELAY_BOT_SIT_AND_REST     = 3000   -- ms - resource check
DELAY_BOT_FIND_MONSTERS    = 5000   -- ms - combat targeting
```

## State Machine
```
┌─────────────────────────────────────────────────────────────┐
│                      WANDERING                               │
│  - generateNewWanderPosition()                               │
│  - height valid? → move, reset wall_hits                     │
│  - height invalid? → wall_hits++                             │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ wall_hits >= 3
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    REORIENTING                               │
│  - theta = ZoneConsensus.getZoneDirection(bot)              │
│  - reset wall_hits                                           │
│  - return to WANDERING                                       │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ wall_hits >= 3 again
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    SEEKING_PLAYER                            │
│  - target = LevelAffinity.findNearestValid(bot, 3)          │
│  - dest = ring position around target                        │
│  - MoveTo(dest)                                              │
│  - on arrival: theta = facing, return to WANDERING           │
└─────────────────────────────────────────────────────────────┘

Separate 30s event:
┌─────────────────────────────────────────────────────────────┐
│                    LONELINESS_CHECK                          │
│  - any valid players within 100 yards and ±3 levels?        │
│  - if no: enter SEEKING_PLAYER state                         │
└─────────────────────────────────────────────────────────────┘
```

## Edge Cases

### Terrain Hazards
| Case | Handling |
|------|----------|
| Water | **Reactive check** - after moving, check `IsInWater()`. If wet, reverse theta and back out. Counts as wall-hit. |
| Cliffs | Height validation (±5 yards) handles most cases. Check height at destination AND midpoint for sheer drops. |
| Caves/Dungeons | **See issue 162** - pre-calculated rail paths through varied dungeon sections. |
| Instance portals | Bots CAN enter dungeons to fight monsters. Level-gated by dungeon requirements. |

### Water Handling Implementation
No `map:IsWaterAt(x,y)` API available - must check reactively after movement.

```lua
-- {{{ BotWander.handleWater
-- Called after movement completes
-- If bot stepped in water, reverse direction and back out
function BotWander.handleWater(bot)
    if not bot:IsInWater() then return false end

    -- Stepped in water - reverse direction
    local theta = bot:GetData("theta") or bot:GetFacing()
    theta = theta + 3.14  -- reverse (~180 degrees)
    if theta > 6.28 then theta = theta - 6.28 end
    bot:SetData("theta", theta)

    -- Count as wall-hit (triggers reorientation after 3)
    local wall_hits = (bot:GetData("wall_hits") or 0) + 1
    bot:SetData("wall_hits", wall_hits)

    -- Move back out immediately (5 yards in reversed direction)
    local x, y, z = bot:GetPosition()
    local bx = x + math.cos(theta) * 5
    local by = y + math.sin(theta) * 5
    local bz = bot:GetMap():GetHeight(bx, by) or z
    bot:MoveTo(0, bx, by, bz, false)

    return true  -- handled water
end -- }}}
```

Travellers use same pattern in `Travel.continueTravelling()`:
```lua
-- After movement, before re-registering event:
if creature:IsInWater() then
    local theta = creature:GetData("theta") or creature:GetO()
    theta = theta + 3.14
    if theta > 6.28 then theta = theta - 6.28 end
    creature:SetData("theta", theta)
    -- Will back out on next tick
end
```

This creates natural "test the water and nope out" behavior.

### Party Behavior
| Case | Handling |
|------|----------|
| In party | **Defer to playerbots party mechanics.** Remove from custom wandering while in party. |
| Party disbanded | Wait ~3 seconds, then resume custom wandering. |
| Leader moves away | If leader >5-10 yards away: pick random spot on ring around leader, move there. Update spot every ~2 seconds while leader is distant. |
| Leader nearby | Stay put. Randomly sit or kneel sometimes. Don't follow small movements. |
| Leader teleports | Leave party if leader in different zone and unreachable by walking/portal. This is bot's new home now. |
| Combat while in party | Fight, don't reposition. Resume ring-following after combat. |

### Anti-Clumping
- Simple rule: "if a bot is within 2 yards, move to a position without a bot within 2 yards"
- Ring positioning: pick random spot, walk there. Don't update unless target player >5 yards away.
- No complex slot assignment needed.

### State Checks (Skip Wandering If...)
| State | Check | Behavior |
|-------|-------|----------|
| In combat | `bot:IsInCombat()` | Skip movement, re-register event to resume after combat |
| Resting | `bot:IsSitting()` or `bot:GetStandState()` | Skip movement. Sitting also prevents monster aggro. |
| Dead | Spirit heartbeat system | Handled by existing spirit world tracking |
| In party | `bot:GetGroup()` | Defer to playerbots, skip custom wandering |

### No Restrictions On
- **Hostile cities**: No such thing - only hostile player packs. Bots can wander anywhere.
- **GM Island / forbidden areas**: All areas fair game if reachable.
- **Cross-continent seeking**: If lonely, bot just wanders locally. No long journeys.

### Generic Direction Function
Add to `movement.lua` for reuse by bots AND travellers:
```lua
-- {{{ Movement.getConsensusDirection
-- Returns average facing direction of nearby players
-- Used when stuck or needing reorientation
-- Returns angle in radians, or nil if no players nearby
function Movement.getConsensusDirection(unit, range)
    range = range or 200
    local players = unit:GetPlayersInRange(range)
    if not players or #players < 1 then return nil end

    local sum_sin, sum_cos = 0, 0
    local count = 0
    for _, player in ipairs(players) do
        if player:IsAlive() and not player:IsBot() then
            local facing = player:GetFacing()
            sum_sin = sum_sin + math.sin(facing)
            sum_cos = sum_cos + math.cos(facing)
            count = count + 1
        end
    end

    if count == 0 then return nil end
    return math.atan2(sum_sin, sum_cos)
end -- }}}
```

Travellers can use this after 10 failed terrain checks instead of despawning.

## Testing
1. Spawn bot, observe wandering pattern (should look like travellers)
2. Corner bot against terrain - should reorient after 3 failures
3. Isolate bot far from players - should seek nearest after 30s
4. Multiple bots - should spread out via 2-yard anti-clump rule
5. Invite bot to party - should stop wandering, follow playerbots mechanics
6. Disband party - bot should resume wandering after ~3 seconds
7. Bot resting - should not wander while sitting
8. Bot in combat - should not wander, resume after combat ends

## Related Issues
- 160: Behavior system integration (centralized periodic events)
- 162: Dungeon/cave rail pathfinding system (NEW)
- 114-119: Original behavior implementations
- 133: Gesture command system

## Related Concepts
- Concept 111-115: Traveller movement patterns
- Concept 201-230: Level affinity (being simplified)
- Concept 301-330: Zone consensus (becoming fallback only)

## Notes
- Travelling salesman was overkill - with ±3 level range, "nearest valid" is sufficient
- Zone consensus still useful as reorientation strategy, just not default
- Bots should feel like wandering NPCs, not goal-seeking agents
- Party mode completely defers to playerbots - no custom movement overlay
- Ring positioning is simple: random spot, walk there, stay until target moves away
