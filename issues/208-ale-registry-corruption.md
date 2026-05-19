# 208 - ALE Registry Corruption Crash

## Status
- Created: 2026-04-08
- Phase: 2
- Priority: Critical
- **IN PROGRESS**

## Current Behavior

Server crashes with:
```
[ALE]: Cannot execute call: registered value is table: 0x7f..., not a function.
ASSERTION FAILED: ExecuteCall, Condition: false
```

Crash occurs after several successful callback executions. A TABLE is stored in the Lua registry where a FUNCTION should be.

## Investigation Summary

### What We Tried
1. Type checking in periodicEvent - callbacks pass validation
2. Disabled BytecodeCache - crash persists
3. Removed duplicate extensions directory - crash persists
4. Added debug output - FindMonsters fires correctly with right types
5. Disabled background CreateLuaEvent calls - investigating

### Key Observations
- FindMonsters callback fires 3-4 times successfully with correct types: `number, number, number, userdata`
- Crash happens when trying to execute a DIFFERENT callback
- Background callbacks (Gestures, Convoy, ZoneConsensus) never printed debug output
- User hint: "I think we're passing an ID as a table or something"

## Architectural Issues Identified

### Issue 1: CreateLuaEvent vs Player-Attached Events
Global `CreateLuaEvent` timers are floating independently of any entity lifecycle. Should convert to player-attached events via `RegisterEvent`.

**Current (problematic):**
```lua
CreateLuaEvent(Gestures.proximityCheck, 1000, 0)  -- Infinite global timer
```

**Proposed:**
```lua
player:RegisterEvent(PeriodicGestureCheck, 1000, 1)  -- Per-player, re-registers
```
-- what global timers are we using? Are there any that are legitimate? Are there any we could remove? A global timer doesn't make sense to attach to a player.

### Issue 2: Bots ARE Real Players
Code currently distinguishes between bots and players. Bots should be treated identically to players for event registration. The distinction should only matter for behavior selection, not event architecture.

### Issue 3: Global Server Events Need a Singleton
For truly server-global periodic tasks (like zone cleanup), create a dedicated singleton structure:

```lua
-- Proposed: ServerHeartbeat singleton
ServerHeartbeat = {
    tasks = {},  -- { name = { func, interval, lastRun } }
}

function ServerHeartbeat.register(name, func, interval)
    ServerHeartbeat.tasks[name] = { func = func, interval = interval, lastRun = 0 }
end

function ServerHeartbeat.tick(now)
    for name, task in pairs(ServerHeartbeat.tasks) do
        if now - task.lastRun >= task.interval then
            task.func()
            task.lastRun = now
        end
    end
end

-- Attach to ANY logged-in player (first one available)
-- Or use a world update hook if available
```

This keeps all server-global logic centralized and predictable.

-- I'm struggling to see what use-case this has. I can see that it might have something, but I don't see it.
   Zones should clean up on their own when players leave. The travellers, monsters, and treasure chests all keep track of their own
   despawning mechanics. There should be no memory leaks in the first place, so nothing to screw up. The only think I could see would be
   the immortals, counting how many new ones to be made until the Ulduar boss spawns? Can you think of any others?

## Files Modified (So Far)

- `src/lua/periodic_events.lua` - Added type checking, debug output
- `src/lua/behaviors/gestures.lua` - Disabled CreateLuaEvent, added periodicProximityCheck
- `src/lua/behaviors/zone-consensus.lua` - Disabled CreateLuaEvent, added periodicCleanup
- `src/lua/behaviors/convoy.lua` - Disabled CreateLuaEvent, added periodicLostMemberCheck
- `config/beta/mod_ale.conf` - Disabled BytecodeCache

## Investigation Results (2026-04-09)

### Code Analysis Findings

**1. ExecuteCall crash location (LuaEngine.cpp:853-856):**
```cpp
if (!lua_isfunction(L, base))
{
    ALE_LOG_ERROR("[ALE]: Cannot execute call: registered value is {}, not a function.", luaL_tolstring(L, base, NULL));
    ASSERT(false);
}
```
- Retrieved value via `lua_rawgeti(L, LUA_REGISTRYINDEX, funcRef)` is a TABLE, not function
- This is used for ALL Lua calls (timed events AND hook callbacks)

**2. All registration paths have type checking:**
- `periodicEvent()` - Lua type check before RegisterEvent
- `object:RegisterEvent()` - C++ `luaL_checktype(L, 2, LUA_TFUNCTION)`
- `RegisterPlayerEvent()` - C++ `luaL_checktype(L, 2, LUA_TFUNCTION)`
- If a table were passed at registration time, it would ERROR then, not later

**3. Key insight: Corruption happens AFTER registration**
- Functions are valid when registered (type checks pass)
- Crash happens LATER when retrieving from registry
- This means the registry slot is being OVERWRITTEN

**4. Current CreateLuaEvent usage:**
- `spiritHeartbeat` (periodic_events.lua:311) - checks if dead players resurrected
- `checkPendingBotReady` (periodic_events.lua:601) - waits for bots to have valid position

Both are legitimate but could be converted to player-attached events.

**5. All RegisterPlayerEvent calls reviewed - all pass valid functions:**
```
ambush.lua, travel.lua, treasure.lua, periodic_events.lua,
death-knights.lua, levelling.lua, custom-classes.lua,
chest-vulnerability.lua, death-durability.lua, ability-tomes.lua
```

### Root Cause Hypothesis

The crash is NOT from Lua passing a table. The registry is being corrupted at C++ level, possibly:
1. A `funcRef` value collision (two different events using same ref)
2. Race condition in ALEEventProcessor (multiple threads)
3. Use-after-free where a ref is freed but still in the event queue
4. Some C++ code overwriting registry slots directly

### Minimal Reproduction Plan

**Phase A: Absolute minimum test**
1. Comment out ALL RegisterPlayerEvent calls except one (InitialLogin)
2. In InitialLogin, register only ONE event for ONE bot
3. If crash still happens, issue is in core ALE or hook system
4. If crash stops, add components back one at a time

## Fix: Restored Original ObjectVariables Pattern (2026-04-09)

**User insight:** ALE has feature parity with Eluna. Events 31, 32, 17, 18 DO exist in ALE.
We incorrectly removed event registrations thinking they didn't exist.

**Changes made:**
1. Restored event registrations for automatic cleanup:
   - `RegisterPlayerEvent(4, DestroyObjData)` - player logout
   - `RegisterServerEvent(31, DestroyObjData)` - creature delete
   - `RegisterServerEvent(32, DestroyObjData)` - gameobject delete
   - `RegisterServerEvent(17, DestroyMapData)` - map create
   - `RegisterServerEvent(18, DestroyMapData)` - map destroy

2. Kept GetTypeId() with lookup table (ALE returns numbers, not strings)

3. Kept ObjectVariables namespace for backward compatibility

Files updated:
- `src/lua/extensions/ObjectVariables.ext`
- `source-beta/modules/mod-ale/src/LuaEngine/extensions/ObjectVariables.ext`
- `installed-files-beta/bin/lua_scripts/extensions` - Symlinked to src/lua/extensions

**Run the server and test if crash still occurs.**

If crash STOPS: The missing event registrations (or manual cleanup calls) were causing issues
If crash PERSISTS: Issue is elsewhere

## Comprehensive Analysis (2026-04-09)

### Event IDs ARE Valid

Events 17, 18, 31, 32 **DO EXIST** in ALE (Hooks.h:129-153):
- 17 = MAP_EVENT_ON_CREATE - Implemented in ServerHooks.cpp:284
- 18 = MAP_EVENT_ON_DESTROY - Implemented in ServerHooks.cpp:291
- 31 = WORLD_EVENT_ON_DELETE_CREATURE - Implemented in ServerHooks.cpp:331
- 32 = WORLD_EVENT_ON_DELETE_GAMEOBJECT - Implemented in ServerHooks.cpp:324

**The previous documentation stating "only events 1-7 exist" was incorrect.**

### Registration Type Checking Verified

All event registration paths use `luaL_checktype(L, 2, LUA_TFUNCTION)`:
- GlobalMethods.h:612 - RegisterEventHelper checks argument 2 is function
- If a table were passed at registration, it would ERROR immediately, not later

**Conclusion: Corruption happens AFTER successful registration.**

### Current Architecture

1. ObjectVariables.ext loads first (.ext files load before .lua)
2. Creates `ObjectVariables._destroyObjData` and `_destroyMapData`
3. object-variables-events.lua loads later
4. Registers those functions with RegisterServerEvent(31/32/17/18)

### Remaining Hypotheses

1. **Threading issue** - Multiple threads accessing Lua state during event dispatch
2. **Registry slot collision** - luaL_unref freeing slot, then reused with wrong value
3. **C++ memory corruption** - Some code overwriting memory structures
4. **Event handler error cascade** - One handler errors, corrupting state for others

### Minimal Test Plan

**Phase A: Isolate the trigger**
1. Remove object-variables-events.lua entirely (disable automatic cleanup)
2. Run server - if crash STOPS, the issue is with those event registrations
3. If crash persists, issue is elsewhere

**Phase B: Test individual events**
If Phase A shows issue is in event registrations:
1. Test ONLY RegisterServerEvent(31) - creature delete
2. Test ONLY RegisterServerEvent(32) - gameobject delete
3. Test ONLY RegisterServerEvent(17) - map create
4. Test ONLY RegisterServerEvent(18) - map destroy
5. Test ONLY RegisterPlayerEvent(4) - player logout

**Phase C: Verify callback type**
Add assertion before event registration:
```lua
assert(type(ObjectVariables._destroyObjData) == "function",
       "Expected function, got " .. type(ObjectVariables._destroyObjData))
```

## Next Steps

1. [x] Analyzed all registration paths - all have type checking
2. [x] Created minimal ObjectVariables.ext for testing
3. [x] Verified events 17, 18, 31, 32 exist in ALE
4. [x] Traced C++ code - all paths look correct
5. [ ] Run minimal test (Phase A above)
6. [ ] Based on results, narrow down to specific event
7. [ ] ~~Implement ServerHeartbeat~~ (deferred - not needed for core functionality)

## Investigation Update (2026-05-19)

### Missing LOCK_ALE in event-cleanup path

Audited every registry-touching call site in mod-ale source for LOCK_ALE
coverage. Found exactly one unguarded path that matches the corruption
pattern described in the technical report (section 5.6: "what if there's
a path that doesn't use LOCK_ALE?").

**The path:**

`ALE::OnWorldUpdate(diff)` at `hooks/ServerHooks.cpp:254` is the main
world-update entry point. It acquires LOCK_ALE for the reload check, then
**releases it** before calling Update / HttpResponses / QueryCallbacks:

```cpp
void ALE::OnWorldUpdate(uint32 diff)
{
    {
        LOCK_ALE;
        if (ShouldReload())
            _ReloadALE();
    }   // <- lock released

    eventMgr->globalProcessor->Update(diff);   // <- NO LOCK
    httpManager.HandleHttpResponses();         // (acquires lock internally — safe)
    queryProcessor.ProcessReadyCallbacks();
    ...
}
```

Inside `ALEEventProcessor::Update`, the timed-event callback invocation
goes through `OnTimedEvent` which DOES acquire LOCK_ALE briefly. But
after `OnTimedEvent` returns and the lock is released, Update calls
`RemoveEvent(luaEvent)`:

```cpp
void ALEEventProcessor::RemoveEvent(LuaEvent* luaEvent)
{
    if (luaEvent->state != LUAEVENT_STATE_ERASE
        && ALE::IsInitialized()
        && (*E)->HasLuaState())
    {
        // NOT GUARDED BY LOCK_ALE — this is the bug
        luaL_unref((*E)->L, LUA_REGISTRYINDEX, luaEvent->funcRef);
    }
    delete luaEvent;
}
```

`luaL_unref` mutates the Lua registry's free list. If another thread
holds LOCK_ALE and is in the middle of `luaL_ref` (or another
registry-mutating call), the free-list update races and the registry's
slot-management gets corrupted. Subsequent `luaL_ref` calls then return
slot numbers whose contents are inconsistent with what the caller
expected — or whose slot still holds a TABLE from a partially-completed
previous allocation.

This exactly matches the crash signature: "registered value is table:
0x..., not a function." A `funcRef` is allocated for a function, but
the Lua reference system is in an inconsistent state due to the unguarded
unref, so the slot's contents are corrupted.

### Why the destructor pattern was a hint

The technical report noted that `ALEEventProcessor::~ALEEventProcessor()`
explicitly comments "can be called from multiple threads" and wraps its
`RemoveEvents_internal()` call with LOCK_ALE. The destructor authors
knew the threading concern existed. The **Update path has the same
concern but was missed** — likely because Update is "the normal path"
and the lock was reasoned about per-callback rather than per-iteration.

### Proposed Fix

Add LOCK_ALE inside `RemoveEvent` so the unref is always guarded,
regardless of caller:

```cpp
void ALEEventProcessor::RemoveEvent(LuaEvent* luaEvent)
{
    if (luaEvent->state != LUAEVENT_STATE_ERASE
        && ALE::IsInitialized()
        && (*E)->HasLuaState())
    {
        LOCK_ALE;  // <- ADD THIS
        luaL_unref((*E)->L, LUA_REGISTRYINDEX, luaEvent->funcRef);
    }
    delete luaEvent;
}
```

**Safe to add** because `ALE::LockType` is `std::recursive_mutex`
(LuaEngine.h:115). Callers that already hold LOCK_ALE (like the
destructor) re-enter safely. Callers that don't (like Update) finally
get the protection they need.

### Expected behavior change after fix

- The "registered value is table" crash should disappear, OR if it
  doesn't, we've ruled out the most plausible cause and can narrow to
  Hypothesis 4 (extension load order).
- No functional behavior change for callers that already locked.
- Tiny serialization cost: events being cleaned up will briefly
  contend for LOCK_ALE with whoever else is holding it. Acceptable.

### Patch shape

This is a 2-line addition to one C++ function. Fits the project's
patch-system convention as a B-patch:

- ID: B020 (next available after B019)
- Name: `ale-event-removeevent-lock`
- Target: `source-beta/modules/mod-ale/src/LuaEngine/ALEEventMgr.cpp:116-125`
- Profile activation: release + beta (both run ALE)
- Idempotent check: grep for `LOCK_ALE` inside the RemoveEvent body
- Issue: this issue (208)

Recommendation: write the patch script, register it in
`PHASE_BEGIN_PATCHES`, then trigger the rebuild that's been queued.
The verify-build script's "ALE referenced" check will still pass; the
real verification will be whether the registered-value-table crash
stops appearing in tmp/error-release.log after a stress test.

### Open question for additional safety

Should `ALEEventProcessor::Update` itself acquire LOCK_ALE at function
scope, rather than relying on each inner call to lock individually?

**Pros:** atomic per-tick processing; simpler reasoning about state
between events.
**Cons:** holds the lock longer; potentially serializes too aggressively
if there's contention with hook handlers.

For now the minimal fix (RemoveEvent only) is enough. The function-scope
lock can be added later if the minimal fix doesn't fully resolve the
crash.

## First Rebuild Attempt — Blocked Upstream (2026-05-19)

The B020 rebuild was attempted but failed at 12% in mod-ale compilation,
**not because of B020** — because of a separate patch B011 that had been
silently degrading. The build error:

```
ALE_SC.cpp:650: fatal error: non-virtual member function marked 'override'
hides virtual member function — type mismatch at 3rd parameter
('bool &' vs 'bool')
```

B011-ale-resurrect-signature was sed-converting `bool&` to `bool` in
mod-ale's OnPlayerResurrect override. The patch was valid against an
older mod-ale where the signature differed from core, but upstream
mod-ale PR #376 (commit 3eca176, currently pinned in our setup) and
core's current PlayerScript.h:638 now both use `bool&`. B011's
"correction" takes valid code and breaks the override match.

B011 deprecated and removed from PHASE_BEGIN_PATCHES for release and
beta. The script file is kept with a deprecation header in case
upstream ever regresses. Next rebuild attempt should reach further than
12% — B020's actual stress test for 208 still pending.

## Second Rebuild Attempt — Different Blocker, B019 Too Aggressive (2026-05-19)

Second rebuild reached **69%** before failing — significant progress
from the first attempt's 12%. The new error:

```
ReadyCheckAction.cpp:50:16: fatal error: use of undeclared identifier 'context'
return AI_VALUE2(uint8, "health", "self target") > sPlayerbotAIConfig.almostFullHealth;
```

Traced to patch B019-playerbots-unused-parameter. The patch had a sed
line that commented out `AiObjectContext* context)` whenever it
appeared as the last parameter in a function signature:

```bash
sed -i 's/AiObjectContext\* context)/AiObjectContext* \/*context*\/)/' "${FILE}"
```

ReadyCheckAction.cpp has 6 `Check()` overrides with that exact
signature, and at least 4 of them use `context` through the
`AI_VALUE2` macro (which expands to `context->GetValue<type>(name,
param)->Get()`). Commenting out the parameter name broke the macro
expansions at every call site.

Fix landed: removed the `AiObjectContext* context)` sed from B019's
apply block AND the matching un-comment from the unapply block. The
two other seds in the same block (for `PlayerbotAI* botAI)` and
`Event& event)`) only match parameters that are *last* in the
signature, and in ReadyCheckAction.cpp `botAI` is always followed by a
comma — so those don't false-positive.

Pattern emerging from these first two attempts: patches in the
B-range were written against earlier upstream states. As upstream
moves, some patches become invalid in ways that aren't caught at
patch-application time — only at compile time. The fix is reactive:
when a patch breaks, narrow its match pattern or deprecate it. Long
term, the patch-status command (issue 146) plus the validate-build
script (commit `d600bc0`) should let us catch this kind of drift
proactively.

B020's stress test for 208 still pending — next rebuild attempt
should reach further still.

## Third Rebuild Attempt — Strategy InitTriggers Loop (2026-05-19)

Build reached **74%** (from 69% in attempt 2). New error:

```
CombatStrategy.cpp:12:5: fatal error: use of undeclared identifier 'triggers'
  triggers.push_back(...)
```

Same diagnostic pattern as B019/ReadyCheckAction.cpp: a B-patch
comments out a parameter as "unused" but upstream filled in the
function body, so the parameter now IS used.

Audit of the affected files showed the breakage was widespread within
B019's "Strategy files - InitTriggers" loop:

| File                         | Uses `triggers`? |
|------------------------------|------------------|
| NonCombatStrategy.cpp        | Yes              |
| CombatStrategy.cpp           | Yes (this error) |
| DuelStrategy.cpp             | Yes              |
| FollowMasterStrategy.cpp     | No               |
| GuardStrategy.cpp            | No               |
| RTSCStrategy.cpp             | No               |

Three of six files now use the parameter. The patch is half-broken.

Fix landed: removed the entire Strategy loop from B019 (apply and
unapply). The three files that still have empty InitTriggers bodies
will emit unused-parameter warnings, but those don't break the build
under current compiler flags. If they ever do, the loop can be
restored scoped to just those three files.

Per the principle the user articulated: "It's okay if we remove
patches as long as they're tracked in git. If the upstream fixes a
bug, it's fine that we don't have to fix it anymore." B019 was
designed against an upstream where these strategy files had empty
InitTriggers; upstream has since populated them. The patch is
obsolete for the populated cases, harmful when it fires on them.

Patterns now confirmed across three rebuilds:
1. B011 — wrong direction (deprecated entirely)
2. B019 ReadyCheckAction — over-broad selector (narrowed)
3. B019 Strategy loop — over-broad selector (removed)

The "patches drift as upstream moves" lesson keeps reappearing. Worth
considering whether to retire B019 entirely once we identify which of
its remaining seds still match upstream patterns the right way.

B020's stress test still pending. Next rebuild attempt should reach
even higher.

## Related Files

- `source-beta/modules/mod-ale/src/LuaEngine/LuaEngine.cpp:856` - ExecuteCall assertion
- `source-beta/modules/mod-ale/src/LuaEngine/hooks/ServerHooks.cpp:67-86` - OnTimedEvent
- `source-beta/modules/mod-ale/src/LuaEngine/ALEEventMgr.cpp` - Event management

## Technical Report

**See:** `docs/ale/ale-integration-technical-report.md`

Comprehensive analysis of:
- Server → ALE → Lua data flow
- Registry slot allocation/deallocation
- Binding ownership model
- Corruption hypotheses with diagrams
- All custom patches and integration points

## Patch Fix (2026-04-09)

**B002 hook placement fixed:** The `sALE->OnLogin(bot)` call was being inserted at the
BEGINNING of `OnBotLoginInternal`, but should be at the END (after XP flag handling).
Script updated in `scripts/azerothcore` to insert after `RemovePlayerFlag` call.

## User Insight

> "why do we have any CreateLuaEvents? why don't we run everything through the periodic events? we wouldn't have to have stray events happening, everything periodic must be attached to a player."

> "bots are real players."

> "if we're doing a global event, it should go onto a separate 'global' structure that represents one singleton that stores all the periodic events that have to happen for the server."
