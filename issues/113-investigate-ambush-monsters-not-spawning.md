# 113 - Investigate Ambush Monsters Not Spawning

## Status: In Progress

## Current Behavior
- Ambush monsters do not spawn when player logs in
- No periodic spawn cycle running
- Queues initialize but never trigger spawns

## Intended Behavior
- Monsters spawn periodically around the player (every 40 seconds)
- Creatures appropriate to player level are selected from creature_template
- Spawned creatures chase and attack the player

## Root Cause Found

The `Ambush.setupPlayer` function initialized the spawn queues on login but never registered the periodic spawn event. Line 74 had a commented-out registration:

```lua
-- player:RegisterEvent(Ambush.spawnAndAttackPlayer, 3000, 1)
```

Nothing was starting the spawn cycle.

## Fix Applied

### 2026-03-31 - Spawn Cycle Registration Added

1. Added configuration block at top of ambush.lua:
```lua
-- {{{ Configuration
AMBUSH_SPAWN_INTERVAL = 40000  -- ms between spawn attempts (40 seconds)
AMBUSH_MIN_DISTANCE   =   120  -- yards minimum from player
AMBUSH_MAX_DISTANCE   =   160  -- yards maximum from player
-- }}}
```

2. Modified `Ambush.setupPlayer` to register the periodic spawn event:
```lua
player:RegisterEvent(Ambush.spawnAndAttackPlayer, AMBUSH_SPAWN_INTERVAL, 0)
```

3. Updated `Ambush.randomSpawn` to use config constants instead of hardcoded values.

## Testing Required
- Log in with a character
- Wait 40 seconds
- Verify "[Ambush] Registered spawn cycle for: <name>" appears in log
- Verify monsters spawn and chase player

## Related Files
- src/lua/ambush.lua
- src/lua/movement.lua (used for spawn positioning)
