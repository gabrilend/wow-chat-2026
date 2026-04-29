# 307 - ALE Gameobject Wildcard Registration

**Phase:** 3 (Danger - Ambush System)
**Effect:** Entry 0 acts as wildcard for gameobject events
**Status:** Completed (2026-04-08)

---

## The Effect

When registering gameobject events in Lua, `entry = 0` acts as a wildcard matching ALL gameobjects. This enables universal event handlers without enumerating every gameobject template.

```lua
-- This works - catches all chest opens
RegisterGameObjectEvent(0, GAMEOBJECT_EVENT_ON_USE, onAnyChestOpen)
```

---

## What This Solved

### Before (Entry 0 Rejected)

**ALE validation logic:**
```cpp
if (!eObjectMgr->GetGameObjectTemplate(entry))
{
    luaL_error(L, "Couldn't find a gameobject with (ID: %d)!", entry);
    return 0;
}
```

**Result:**
- `RegisterGameObjectEvent(0, ...)` fails with error
- Handler never registered
- Features broken:
  - Ability tome spawning (any chest → tome drop)
  - Chest vulnerability (any chest → attackable mechanic)

**Workarounds considered:**
1. Register each chest entry individually (900+ entries)
2. Query database at runtime for chest types
3. Switch to player loot events (wrong semantics)

All workarounds are verbose, fragile, or semantically incorrect.

### After (Entry 0 = Wildcard)

**Patched validation:**
```cpp
// entry 0 = wildcard for all gameobjects (Issue 307)
if (entry != 0 && !eObjectMgr->GetGameObjectTemplate(entry))
{
    luaL_error(L, "Couldn't find a gameobject with (ID: %d)!", entry);
    return 0;
}
```

**Result:**
- Entry 0 bypasses template validation
- Handler registered for ALL gameobjects
- Clean, maintainable Lua code
- Matches behavior from other Eluna-based engines

---

## Why This Matters

**Universal Event Handlers**

Without wildcard support, every gameobject feature requires:
- Database enumeration at load time
- Hardcoded entry lists (outdated when content added)
- Separate registration per template

With wildcard support:
- One registration handles all cases
- Future-proof (works with new templates)
- Cleaner code, easier maintenance

**Feature Enablement**

Two blocked features immediately work:
1. **Ability tomes** - Drop tomes from ANY chest, not just specific ones
2. **Chest vulnerability** - ANY chest can be attacked while searching

Both features need global behavior, not per-chest config.

**Pattern Consistency**

Wildcard entry 0 already works for:
- Creature events (entry 0 = all creatures)
- Item events (entry 0 = all items)

Gameobjects should match this pattern.

---

## Implementation

### C++ Patch to ALE

**File:** `modules/mod-ale/src/LuaEngine/LuaEngine.cpp`
**Location:** Line 1414-1417 (gameobject event registration)

**Before:**
```cpp
if (!eObjectMgr->GetGameObjectTemplate(entry))
{
    luaL_unref(L, LUA_REGISTRYINDEX, functionRef);
    luaL_error(L, "Couldn't find a gameobject with (ID: %d)!", entry);
    return 0;
}
```

**After:**
```cpp
// entry 0 = wildcard for all gameobjects (Issue 307)
if (entry != 0 && !eObjectMgr->GetGameObjectTemplate(entry))
{
    luaL_unref(L, LUA_REGISTRYINDEX, functionRef);
    luaL_error(L, "Couldn't find a gameobject with (ID: %d)!", entry);
    return 0;
}
```

**Change:** Added `entry != 0 &&` condition to skip validation for wildcard.

### Patch Application

**Method:** Automated sed replacement in build script
**Phase:** PHASE_BEGIN (pre-compile source fix)
**Patch ID:** B003
**Documentation:** `docs/patches/ale-gameobject-wildcard.md`

**Build script:**
```bash
FILE="$SOURCE_DIR/modules/mod-ale/src/LuaEngine/LuaEngine.cpp"
sed -i 's/if (!eObjectMgr->GetGameObjectTemplate(entry))/\/\/ entry 0 = wildcard (Issue 307)\n                if (entry != 0 \&\& !eObjectMgr->GetGameObjectTemplate(entry))/g' "$FILE"
```

**Idempotent:** Safe to run multiple times (sed won't double-apply).

### Affected Lua Scripts

**ability-tomes.lua:307**
```lua
RegisterGameObjectEvent(0, GAMEOBJECT_EVENT_ON_USE, AbilityTome.onChestOpen)
```

**chest-vulnerability.lua:326**
```lua
RegisterGameObjectEvent(0, GAMEOBJECT_EVENT_ON_USE, ChestVuln.onChestUse)
```

Both scripts now register successfully at server startup.

---

## Technical Details

### ALE Event Registration Flow

1. Lua calls `RegisterGameObjectEvent(entry, eventType, handler)`
2. ALE pushes handler to registry, gets functionRef
3. **Validation step:**
   - Old: `GetGameObjectTemplate(entry)` must exist
   - New: Skip validation if `entry == 0`
4. Store binding in event map
5. When gameobject triggers event, ALE checks:
   - Specific entry handler (if registered)
   - Wildcard handler (entry 0, if registered)
   - Execute all matching handlers

### Why Entry 0?

- Entry 0 never exists in actual gameobject templates (reserved ID)
- No collision with real content
- Convention from Eluna/TrinityCore scripting APIs
- Matches creature/item wildcard pattern

### Runtime Behavior

**Specificity wins:**
```lua
RegisterGameObjectEvent(0, event, wildcardHandler)     -- All gameobjects
RegisterGameObjectEvent(1234, event, specificHandler)  -- Chest template 1234
```

When gameobject 1234 fires event:
- Both handlers execute
- Specific handler runs first
- Wildcard handler runs second

This allows global + override patterns.

---

## Lessons Learned

### Template Validation Rigidity

ALE's strict validation helps catch typos but blocks intentional wildcards. The fix:
- Validate specific entries (catch errors)
- Allow entry 0 explicitly (enable wildcards)

Best of both worlds.

### Consistency Across Event Types

Players expect similar patterns across event APIs:
- If `RegisterCreatureEvent(0, ...)` works
- Then `RegisterGameObjectEvent(0, ...)` should too

Breaking consistency creates confusion. Matching behavior improves learnability.

### Build-Time Patches vs Runtime Workarounds

**Option:** Enumerate 900+ chest entries in Lua
**Better:** One-line C++ patch enabling the intended API

Don't work around bad APIs. Fix the API.

### Documentation Before Implementation

Created `docs/patches/ale-gameobject-wildcard.md` describing:
- What to change
- Where to change it
- Why it's needed
- How to verify

LLM or human can read this and apply the patch to ANY fork. The documentation IS the implementation.

---

## Phase 3 Contribution

This issue enables **Phase 3: Danger - Ambush System** by unblocking:

> **Ability tomes (151):** Chests drop ability scrolls
> **Chest vulnerability (153):** Chests attackable while searching

Both features require global gameobject event hooks. Without wildcard support, these features remain incomplete or require fragile workarounds.

By enabling entry 0 wildcards, we restore clean Lua scripting patterns and allow features to work as designed.
