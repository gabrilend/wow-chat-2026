# 610 - Behavior System Integration

## Status
- Created: 2026-04-05
- Phase: 2
- Priority: High
- Depends: 202 (Lua engine initialization)

## Current Behavior
- Lua behavior files exist but were deleted from working tree
- Playerbots module controls bot movement via C++ RPG strategies
- Bots stand in place saying "hi" repeatedly (WanderNpc + EnableGreet)
- Player chat commands fully control bots once invited (follow, stay, attack)
- No dispersion - bots clump together

## Intended Behavior
- Lua behaviors control bot movement and dispersion
- Playerbots RPG defers to Lua for idle movement
- Player commands disabled except: party join, gesture-based directions
- Bots disperse naturally, moving toward players if none within 200 yards
- Variety in chatter (eventual ollama integration)

## Investigation Findings

### Behavior Files Restored
Files in `src/lua/behaviors/`:
- `init.lua` - Loader
- `zone-consensus.lua` - Collective movement drift based on player facing
- `level-affinity.lua` - Bots cluster by level similarity
- `orbit-player.lua` - Formation positioning with dispersion
- `gestures.lua` - Player commands through body language (kneel, sit, wave)
- `find-monsters.lua` - Combat targeting
- `avoid-monsters.lua` - Danger awareness
- `sit-and-rest.lua` - Resource recovery
- `convoy.lua` - NPC following behavior

### Movement Conflict
Both systems try to control bot movement:
1. **Playerbots C++ RPG** - WanderRandom, WanderNpc, GoCamp, etc.
2. **Lua behaviors** - ZoneConsensus, LevelAffinity, OrbitPlayer

They will fight - last MoveTo() wins for that tick.

**Solution:** Set playerbots RPG weights to Rest=100, others=0
This makes playerbots "do nothing" while our Lua controls movement.

### Command Blocking Challenge
Playerbots security system:
```cpp
PLAYERBOT_SECURITY_DENY_ALL = 0   // Nothing
PLAYERBOT_SECURITY_TALK = 1       // Chat only
PLAYERBOT_SECURITY_INVITE = 2     // Can invite
PLAYERBOT_SECURITY_ALLOW_ALL = 3  // Full control
```

**Problem:** When player invites bot → becomes "master" → gets ALLOW_ALL

**Unsecured commands** (always allowed): who, wts, sendmail, invite, leave, lfg

**Potential solutions:**
1. **C++ Patch** - Add config `AiPlayerbot.AllowedMasterCommands = "invite,leave"`
2. **Modify HandleCommand()** - Check against whitelist before executing
3. **Lua intercept** - Not possible, C++ processes before Lua hooks

### Recommended C++ Patch Location
File: `source-beta/modules/mod-playerbots/src/Bot/PlayerbotAI.cpp`
Function: `HandleCommand()` (line 560)

Add check after security validation:
```cpp
// Check command whitelist for Everland Ghostsong
if (!IsWhitelistedCommand(filtered))
{
    TellMaster("I don't respond to that command.");
    return;
}
```

## Implementation Steps

### Phase 1: Config Changes (No Rebuild) ✓ COMPLETE
1. Edit `playerbots.conf`:
   ```
   # Defer movement to Lua behaviors
   AiPlayerbot.RpgStatusProbWeight.WanderRandom = 0
   AiPlayerbot.RpgStatusProbWeight.WanderNpc = 0
   AiPlayerbot.RpgStatusProbWeight.GoCamp = 0
   AiPlayerbot.RpgStatusProbWeight.Rest = 100

   # Reduce greeting spam
   AiPlayerbot.EnableGreet = 0
   ```

2. Integrate Lua behaviors:
   - Add `require("load-behaviors")` to `periodic_events.lua`
   - Behaviors load via load-behaviors.lua

### Phase 2: Dispersion Enhancement ✓ COMPLETE
Added to `zone-consensus.lua`:
- `LONELY_RADIUS = 200` - if no one within this, move toward others
- `APPROACH_DISTANCE = 100` - how far to move toward closest
- `CLUMP_RADIUS = 15` - too close, need to disperse
- `DISPERSE_DISTANCE = 20` - how far to disperse when clumped
- New functions: `findNearestUnit()`, `countNearbyUnits()`, `handleDispersion()`

### Phase 2b: Centralized Periodic Event Management ✓ COMPLETE
All bot behaviors now register through `periodic_events.lua` instead of self-registering.

**Rationale:** Each behavior file was calling `RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, ...)`
independently, creating duplicate event chains. Centralizing ensures:
- Single point of control for behavior timing
- Consistent timer intervals (configurable in one place)
- Clear separation: spawn events for players, behavior events for bots

**Changes made:**

`periodic_events.lua` now defines:
```lua
DELAY_BOT_ZONE_CONSENSUS = 3000  -- ms - drift with zone facing direction
DELAY_BOT_LEVEL_AFFINITY = 5000  -- ms - cluster by level similarity
DELAY_BOT_SIT_AND_REST   = 3000  -- ms - check resources, sit if needed
DELAY_BOT_ORBIT_PLAYER   = 2000  -- ms - formation positioning
DELAY_BOT_FIND_MONSTERS  = 5000  -- ms - scan for combat targets
```

Wrapper functions added:
- `PeriodicBotZoneConsensus()` → calls `ZoneConsensus.periodicUpdate(bot)`
- `PeriodicBotLevelAffinity()` → calls `LevelAffinity.periodicUpdate(bot)`
- `PeriodicBotSitAndRest()` → calls `SitAndRest.checkAndRest(bot)`
- `PeriodicBotOrbitPlayer()` → calls `OrbitPlayer.updatePosition(bot)`
- `PeriodicBotFindMonsters()` → calls `FindMonsters.scan(bot)`

`InitialLogin()` now registers:
- For real players: spawn events (ambush, traveller, treasure)
- For bots: behavior events (all five above)

**Behavior files updated** (removed self-registration):
- `zone-consensus.lua` → exposes `periodicUpdate(bot)`
- `level-affinity.lua` → exposes `periodicUpdate(bot)`, `trackLogin()`, `trackLogout()`
- `sit-and-rest.lua` → exposes `checkAndRest(bot)`
- `orbit-player.lua` → exposes `updatePosition(bot)`
- `find-monsters.lua` → exposes `scan(bot)`

### Phase 3: Command Blocking (C++ Patch)
1. Add config: `AiPlayerbot.MasterCommandWhitelist = "invite,leave,who"`
2. Modify `HandleCommand()` to check whitelist
3. Rebuild and test

## Testing
1. Login, verify Lua behaviors print load messages
2. Observe bots - should drift with zone consensus
3. Try commands like "follow" - should be rejected (after patch)
4. Invite bot to party - should join
5. Use gesture commands (kneel near bot) - should respond

## Related Issues
- 114-119: Individual behavior implementations
- 125: Player-bot behavior commands
- 202: Lua engine initialization
- 133: Gesture command system

## Related Files
- src/lua/behaviors/*.lua
- src/lua/periodic_events.lua
- installed-files-beta/etc/modules/playerbots.conf
- source-beta/modules/mod-playerbots/src/Bot/PlayerbotAI.cpp
