# 328 - GetPosition Nil Errors

## Status
- Created: 2026-04-08
- **Resolved: 2026-04-08**
- Phase: 2
- Priority: High
- ~~Blocking: Bot behaviors not functioning~~
- **Resolution:** GetPosition() was not an ALE method. Replaced with GetLocation().

## Error Summary

From Server.log (2026-04-08 session):

| Count | File:Line | Error |
|-------|-----------|-------|
| 10422 | bot-wander.lua:275 | attempt to call method 'GetPosition' (a nil value) |
| 6062 | find-monsters.lua:28 | attempt to call method 'GetPosition' (a nil value) |
| 612 | bot-wander.lua:439 | attempt to call method 'GetPosition' (a nil value) |
| 92 | gestures.lua:73 | attempt to call method 'GetPosition' (a nil value) |

**Total: 17,188 errors**

## Root Cause Analysis

### TRUE ROOT CAUSE (2026-04-08 - Final Resolution)

**`GetPosition()` is NOT an exposed ALE Lua method!**

The ALE (AzerothCore Lua Engine) only exposes these position methods:
- `GetX()` - returns x coordinate
- `GetY()` - returns y coordinate
- `GetZ()` - returns z coordinate
- `GetLocation()` - returns x, y, z, o (all four values)

The code was calling `GetPosition()` which doesn't exist as a Lua binding.
When a method doesn't exist, Lua returns nil, causing:
`attempt to call method 'GetPosition' (a nil value)`

**This was NOT a timing issue** - the method simply doesn't exist in ALE.

**Resolution:** Replace all `GetPosition()` calls with `GetLocation()`.
Lua discards extra return values, so `local x, y, z = GetLocation()` works fine
(the 4th value `o` is simply ignored).

**Files Fixed - GetPosition → GetLocation (60+ occurrences):**
- periodic_events.lua (3 calls)
- bot-wander.lua (8 calls)
- zone-consensus.lua (13 calls)
- gestures.lua (6 calls)
- find-monsters.lua (4 calls)
- avoid-monsters.lua (7 calls)
- dungeon-rails.lua (7 calls)
- level-affinity.lua (4 calls)
- orbit-player.lua (3 calls)
- convoy.lua (5 calls)

**Additional Fix - GetFacing → GetO (10 occurrences):**
`GetFacing()` is also not an ALE method. Use `GetO()` for orientation.
- movement.lua (1 call)
- bot-wander.lua (1 call)
- zone-consensus.lua (2 calls)
- gestures.lua (1 call)
- dungeon-rails.lua (4 calls)
- convoy.lua (1 call)

### Previous Analysis (2026-04-08 - Obsolete)

~~The problem is **timing**, not missing guards. Periodic events are registered before the bot has position.~~

Note: The timing analysis below was based on an incorrect assumption that
`GetPosition()` existed. The guards and delays helped but didn't fix the
core issue - using a non-existent method.

**The Login Flow:**

```
PlayerbotMgr.cpp:200
    botSession->HandlePlayerLoginFromDB(holder)
                ↓
    (inside HandlePlayerLoginFromDB, at end: sScriptMgr->OnPlayerLogin)
                ↓
PlayerbotMgr.cpp:226
    auto op = std::make_unique<OnBotLoginOperation>(...)
    PlayerbotWorldThreadProcessor::instance().QueueOperation(std::move(op))
                ↓ (later, when operation executes)
PlayerbotOperations.h:509
    holder->OnBotLogin(bot)
                ↓
PlayerbotMgr.cpp:464
    OnBotLoginInternal(bot)
                ↓
RandomPlayerbotMgr.cpp:2530
    sALE->OnLogin(bot)    ← Lua PLAYER_EVENT_ON_LOGIN fires HERE
                ↓
periodic_events.lua:412
    InitialLogin() runs, registers:
    - periodicEvent(PeriodicBotWander, 2000ms, 1, bot)
    - periodicEvent(PeriodicBotLonelinessCheck, ...)
    - etc.
                ↓ (2000ms later, first tick)
periodic_events.lua:320
    PeriodicBotWander() fires:
    - checks bot:IsBot()     ✓
    - checks bot:IsAlive()   ✓
    - checks isModeValid()   ✓
    - does NOT check IsInWorld() or GetPosition()
                ↓
bot-wander.lua:327
    BotWander.update(bot)
                ↓
bot-wander.lua:275
    bot:GetPosition()  ← CRASH: position not yet set
```

**Why Position Missing:**

The `OnBotLoginOperation` is **queued**, not executed immediately. When it executes:
1. `ObjectAccessor::FindConnectedPlayer(m_botGuid)` finds the bot (proves bot exists)
2. But the bot may not have world position yet (teleport pending, loading state)

The checks in `PeriodicBotWander` (lines 321-323) guard against:
- Wrong object type (IsBot)
- Death state (IsAlive)
- Mode validity (isModeValid)

But NOT world readiness (IsInWorld, GetPosition).

### Error Pattern Explanation

Error: `attempt to call method 'GetPosition' (a nil value)`

This means the method lookup failed, not that GetPosition returned nil.
When player userdata becomes invalid/stale, method lookups return nil.

With ~100 bots × 2-second wander tick = 3000 errors/minute = 15,000+ in 5 minutes.
Matches observed counts.

## Affected Files

### 1. `src/lua/behaviors/bot-wander.lua`

**Line 275** - `BotWander.checkAntiClump()` (10,422 occurrences):
```lua
function BotWander.checkAntiClump(bot)
    local bx, by, bz = bot:GetPosition()  -- <- ERROR: bot may not have position
    local botGuid    = bot:GetGUID()
```

**Line 439** - `BotWander.checkLonely()` (612 occurrences):
```lua
    local bx, by   = bot:GetPosition()  -- <- ERROR: same issue
    local botLevel = bot:GetLevel()
```

### 2. `src/lua/behaviors/find-monsters.lua`

**Line 28** - `FindMonsters.getNearbyCreatures()` (6,062 occurrences):
```lua
function FindMonsters.getNearbyCreatures(bot, range)
    local creatures = {}
    local bx, by, bz = bot:GetPosition()  -- <- ERROR: bot may not have position
```

### 3. `src/lua/behaviors/gestures.lua`

**Line 73** - `Gestures.getNPCsInRange()` (92 occurrences):
```lua
function Gestures.getNPCsInRange(player, range)
    local npcs = {}
    local px, py, pz = player:GetPosition()  -- <- ERROR: player may not have position
```

## Architectural Fix (Preferred)

**Design principle:** Build systems where dangerous states cannot occur, rather than adding guard rails to catch them.

### Option A: Delayed Event Registration

Don't register periodic events until bot has confirmed world position.

```lua
-- {{{ InitialLogin
function InitialLogin(_event, player)
    if player:IsBot() then
        -- Don't register events immediately
        -- Instead, register a single "wait for ready" event
        player:RegisterEvent(WaitForBotReady, 500, 1)  -- Check every 500ms
    else
        -- Real players are ready immediately
        registerPlayerEvents(player)
    end
end
-- }}}

-- {{{ WaitForBotReady
-- Wait until bot has valid world position before registering behaviors
function WaitForBotReady(eventID, delay, repeats, bot)
    local x, y, z = bot:GetPosition()
    if not x then
        -- Not ready yet, check again
        bot:RegisterEvent(WaitForBotReady, 500, 1)
        return
    end

    -- Bot is ready - now register behavior events
    BotOrchestrator.setMode(bot, BotOrchestrator.MODE.WANDERING)
    periodicEvent(PeriodicBotWander, DELAY_BOT_WANDER, 1, bot)
    periodicEvent(PeriodicBotLonelinessCheck, DELAY_BOT_LONELINESS_CHECK, 1, bot)
    -- etc.
    print("[PeriodicEvents] Bot " .. bot:GetName() .. " ready, behaviors registered")
end
-- }}}
```

### Option B: Centralized WorldTick (Issue 329)

Replace N independent timers with single heartbeat that checks `isReady()` once:

```lua
function WorldTick.heartbeat()
    for _, bot in pairs(GetPlayersInWorld()) do
        if bot:IsBot() and WorldTick.isReady(bot) then
            -- Bot is ready, process behaviors
            WorldTick.processBehaviors(bot)
        end
        -- Not ready? Skip this tick. No error, no crash.
    end
end

function WorldTick.isReady(entity)
    if not entity then return false end
    if not entity:IsInWorld() then return false end
    if not entity:GetPosition() then return false end
    return true
end
```

### Option C: Guard Rails (Fallback)

If architectural changes too disruptive, add `IsInWorld()` check to each periodic event:

```lua
function PeriodicBotWander(eventID, delay, repeats, bot)
    if not bot:IsBot() then return end
    if not bot:IsAlive() then return end
    if not bot:IsInWorld() then return end      -- ADD THIS
    if not BotOrchestrator.isModeValid(bot, "wander") then return end
    -- ...
end
```

**Downside:** Every event needs the guard. Easy to miss one. Symptoms hidden, not solved.

## Investigation Steps (Completed)

1. [x] Read bot-wander.lua around line 275 - `checkAntiClump()` calls GetPosition immediately
2. [x] Read find-monsters.lua around line 28 - `getNearbyCreatures()` same issue
3. [x] Read gestures.lua around line 73 - `getNPCsInRange()` same issue
4. [x] Determine if these are timer callbacks - YES, periodic events registered on login
5. [x] Traced full call chain from playerbots C++ to Lua event registration
6. [x] Implemented Option A - delayed event registration (2026-04-08)
7. [x] **RESOLVED:** GetPosition() is not an ALE method - replaced all calls with GetLocation() (2026-04-08)

## Implementation (Option A - Delayed Registration)

**File:** `src/lua/periodic_events.lua`

**Changes Made (2026-04-08):**

1. Added `DELAY_BOT_READY_CHECK = 500` constant (ms between ready checks)

2. Added `registerBotBehaviors(bot)` helper function:
   - Extracted bot event registration logic
   - Called only after position is confirmed

3. Added `WaitForBotReady(eventID, delay, repeats, bot)`:
   - Uses `pcall` to safely check `bot:GetPosition()`
   - If position unavailable, re-registers to check again in 500ms
   - If position available, calls `registerBotBehaviors(bot)`
   - Handles stale userdata gracefully

4. Modified `InitialLogin(_event, player)`:
   - For bots: registers `WaitForBotReady` instead of events directly
   - For real players: unchanged (they're ready immediately)

5. Added clarifying comment to `BotOrchestrator.switchMode`:
   - Notes that switchMode is called during gameplay (not login)
   - Bot guaranteed to have position by that point

**Design Principle:** Make the dangerous state impossible, not just guarded against.
Behavior events are never registered until bot has confirmed world position.

## Related Issues

- Issue 324: Playerbots ALE login hook - Added `sALE->OnLogin(bot)` to fire Lua events for bots
- Issue 325: ALE gameobject wildcard (resolved - no more gameobject errors)
- Issue 329: Algorism priority scheduler (research) - WorldTick architecture solves this elegantly

## Key Files

**C++ (Playerbots login flow):**
- `modules/mod-playerbots/src/Bot/PlayerbotMgr.cpp:191-230` - `HandlePlayerBotLoginCallback`
- `modules/mod-playerbots/src/Bot/PlayerbotMgr.cpp:453-464` - `OnBotLogin`
- `modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp:2525-2551` - `OnBotLoginInternal`
- `modules/mod-playerbots/src/Script/WorldThr/PlayerbotOperations.h:485-522` - `OnBotLoginOperation`

**Lua (Event registration and behaviors):**
- `src/lua/periodic_events.lua:410-470` - `InitialLogin`, event registration
- `src/lua/periodic_events.lua:320-329` - `PeriodicBotWander` callback
- `src/lua/behaviors/bot-wander.lua:274-310` - `checkAntiClump` where crash occurs

## Notes

The high error count (17k+) confirms this is happening on every timer tick for every bot.
With ~100 bots and 2-second wander tick: 3000 errors/minute = 15,000+ in 5 minutes. Matches observations.

**Design principle applied:** "Adding guard rails implies there's a chance you can fall down. Not ideal - build the system to proceed with grace."

The architectural fix (Option A or B) ensures bots never receive behavior events until they're ready. The dangerous state becomes impossible, not just guarded against.
