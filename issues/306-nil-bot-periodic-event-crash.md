# 306 - Nil Bot Periodic Event Crash

**Phase:** 3 (Danger - Ambush System)
**Effect:** Bots trigger Lua events on login, periodic events work correctly
**Status:** Open (Patch documented, needs application)

---

## The Effect

Playerbots fire the same Lua `PLAYER_EVENT_ON_LOGIN` hook that real players do, enabling periodic behavior events to register correctly. Bot behavior scripts no longer crash with "attempt to call method 'GetPosition' (a nil value)" errors.

This makes bots first-class citizens in the Lua scripting system.

---

## What This Solved

### Before (Bots Skip Lua Hooks)

**The problem:**

Playerbots log in through mod-playerbots C++ code (autologin, random bots), which bypasses ALE's Lua hooks:
```cpp
// mod-playerbots login code (simplified)
bot->SetSession(session);
bot->LoadFromDB();
bot->AddToWorld();
// [MISSING] sALE->OnLogin(bot)  -- Never called!
```

**Result:**
- `InitialLogin` in `periodic_events.lua` never fires for bots
- Bot periodic events (find-monsters, bot-wander, gestures) never register
- Global timers iterate `GetPlayersInWorld()` which includes bots
- Timers try to call methods on uninitialized bot references
- **Crash:** "attempt to call method 'GetPosition' (a nil value)"

**Evidence in logs:**
```
[PeriodicEvents] Registered behavior events for bot:  <-- Never appears for bots
lua_scripts/custom/behaviors/find-monsters.lua:28: attempt to call method 'GetPosition' (a nil value)
lua_scripts/custom/behaviors/gestures.lua:73: attempt to call method 'GetPosition' (a nil value)
lua_scripts/custom/behaviors/bot-wander.lua:275: attempt to call method 'GetPosition' (a nil value)
```

### After (Bots Fire Lua Hooks)

**The patch:**

Add `sALE->OnLogin(bot)` to mod-playerbots login path:
```cpp
// RandomPlayerbotMgr.cpp, after bot fully loaded
bot->SetSession(session);
bot->LoadFromDB();
bot->AddToWorld();
sALE->OnLogin(bot);  // FIRE LUA HOOKS
```

**Result:**
- Bots trigger `PLAYER_EVENT_ON_LOGIN` (event 3) just like real players
- `InitialLogin` in `periodic_events.lua` fires for bots
- Bot periodic events register correctly
- No more GetPosition nil errors
- Bots behave identically to players in Lua scripts

---

## Why This Matters

**Bots Are Players**

The mod-playerbots module creates bot objects as `Player*` instances:
- They have the same C++ type as real players
- They're in the same `GetPlayersInWorld()` list
- They should trigger the same Lua hooks

But the C++ login path bypassed ALE, making bots "second-class" in the Lua system.

**No Fallbacks, Fix the Pipeline**

We could add nil checks everywhere:
```lua
if not bot then return end  -- Fallback approach
if not bot:IsBot() then return end
```

But this is treating the symptom, not the cause. The real fix: **make bots trigger Lua events**.

**Global Timers Need All Players**

Many behavior systems use global timers:
```lua
CreateLuaEvent(Gestures.proximityCheck, 5000, 0)  -- Fires every 5 seconds

function Gestures.proximityCheck()
    for _, player in ipairs(GetPlayersInWorld()) do  -- Includes bots!
        -- Process player...
    end
end
```

If bots are in `GetPlayersInWorld()` but don't have initialized behavior data, crash.

**Consistency Principle**

If a bot can be obtained via `GetPlayersInWorld()`, it should be safe to call Player methods on it. The Lua system shouldn't care whether it's a bot or a real player.

---

## Technical Details

### ALE Hook System

ALE fires hooks at specific lifecycle events:
```cpp
// For real players (World.cpp):
sALE->OnLogin(player);   // PLAYER_EVENT_ON_LOGIN (3)
sALE->OnLogout(player);  // PLAYER_EVENT_ON_LOGOUT (4)
```

Lua scripts register handlers:
```lua
RegisterPlayerEvent(3, InitialLogin)  -- Fires when player logs in
RegisterPlayerEvent(4, OnLogout)      -- Fires when player logs out
```

Bots never fired event 3, so `InitialLogin` never ran for them.

### Mod-Playerbots Login Flow

Bot login happens in `RandomPlayerbotMgr::LoginPlayerBot()`:
1. Create WorldSession
2. Load bot from database
3. Add to world
4. **[MISSING]** Fire ALE hooks

The patch adds step 4.

### Periodic Events System

`periodic_events.lua` registers behavior events:
```lua
function InitialLogin(event, player)
    if player:IsBot() then
        -- Register periodic events for bot behaviors
        player:RegisterEvent(PeriodicBotFindMonsters, 10000, 0)
        player:RegisterEvent(PeriodicBotWander, 5000, 0)
        -- ...
    end
end
```

Without the hook firing, these events never register.

### Why GetPosition Fails

When a timer references an invalid bot:
```lua
function PeriodicBotFindMonsters(eventID, delay, repeats, bot)
    local x, y, z = bot:GetPosition()  -- CRASH if bot invalid
```

The error is "attempt to call method 'GetPosition' (a nil value)" because:
- The Lua userdata exists (bot reference)
- But the underlying C++ WorldObject was deleted
- ALE's method binding fails: "this object doesn't exist anymore"
- Returns nil instead of a function
- Calling nil() crashes

### The Patch

See `docs/patches/playerbots-ale-login-hook.md` for complete implementation.

**File:** `modules/mod-playerbots/src/RandomPlayerbotMgr.cpp`

**Location:** After bot is added to world (around line 285)

**Code:**
```cpp
#include "ALE.h"  // Add to includes

// In LoginPlayerBot(), after bot->AddToWorld()
sALE->OnLogin(bot);  // Fire Lua login hooks for bots
```

**Build:**
```bash
./scripts/azerothcore update
```

---

## Related Phase 3 Issues

- 302 - investigate-ambush-monsters-not-spawning (spawn system)
- 303 - randomize-ambush-spawn-interval (periodic timer system)
- 304 - clear-ambush-data-on-death (cleanup pattern)
- 305 - ambush-aggro-and-corpse-movement (combat fixes)

---

## Lessons Learned

### Bots Are Players, Treat Them Equally

Don't special-case bots. If they're `Player*` objects, they should trigger all the same hooks and events.

**Lesson:** Consistency in object lifecycle prevents special-case bugs.

### Fix the Pipeline, Not the Symptoms

Adding nil checks everywhere is a band-aid:
```lua
if not bot then return end  -- Treats symptom
```

Firing the hook is the cure:
```cpp
sALE->OnLogin(bot);  -- Fixes root cause
```

**Lesson:** When code assumes something (hooks fire), make sure that something happens.

### GetPlayersInWorld() Implies Safety

If an object is in `GetPlayersInWorld()`, Lua scripts assume it's safe to use. If it's not safe, don't put it in the list—or make it safe.

**Lesson:** Collections imply contracts. Objects in the collection must fulfill the contract.

### Mod Integration Requires Hook Awareness

When integrating two systems (mod-playerbots + ALE), check that lifecycle events align:
- Does the module fire the hooks the scripting system expects?
- Are there bypass paths that skip essential initialization?

**Lesson:** Integration = ensuring both systems' assumptions hold true.

### Error Messages Can Mislead

"attempt to call method 'GetPosition' (a nil value)" sounds like:
- GetPosition is nil (wrong)
- The method doesn't exist (wrong)

Actually means:
- The underlying object is invalid
- ALE's binding layer returned nil

**Lesson:** Error messages from binding layers need context. "Object no longer valid" would be clearer.

---

## Implementation Status

**Patch documented:** `docs/patches/playerbots-ale-login-hook.md`

**Status:** Needs application to source-beta

**Testing:**
1. Apply patch
2. Rebuild with `./scripts/azerothcore update`
3. Restart worldserver
4. Check logs for `[PeriodicEvents] Registered behavior events for bot:`
5. Verify no GetPosition nil errors after bot login
6. Observe bots executing behaviors (wander, find-monsters, gestures)

---

## Phase 3 Contribution

This issue enables **Phase 3: Danger (Ambush System)** by ensuring:
> "Bots operate within the same Lua behavior framework as players"

The ambush system spawns monsters around all players (including bots). Bot behaviors need periodic events to:
- Find nearby monsters (find-monsters behavior)
- Navigate away from danger (avoid-monsters behavior)
- Wander when safe (bot-wander behavior)

Without this fix, bots are static NPCs. With it, they're dynamic AI companions.
