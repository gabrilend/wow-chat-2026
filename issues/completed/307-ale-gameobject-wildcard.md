# 325 - ALE Gameobject Wildcard Registration

**MIGRATED TO:** issues-beta/307-ale-gameobject-wildcard.md

## Status
- Created: 2026-04-08
- Migrated: 2026-04-11 (325→307)
- Phase: 3
- Priority: Medium

## Current Behavior

When `RegisterGameObjectEvent(0, event, handler)` is called with entry 0 (intended as a wildcard to catch all gameobjects), ALE throws an error:

```
Couldn't find a gameobject with (ID: 0)!
```

This error appears in Server.log from:
- `ability-tomes.lua:307`
- `chest-vulnerability.lua:326`

The handler is never registered, breaking these features.

## Root Cause

ALE validates gameobject templates before registration at `LuaEngine.cpp:1414-1417`:

```cpp
if (!eObjectMgr->GetGameObjectTemplate(entry))
{
    luaL_unref(L, LUA_REGISTRYINDEX, functionRef);
    luaL_error(L, "Couldn't find a gameobject with (ID: %d)!", entry);
    return 0;
}
```

Since no gameobject template with entry 0 exists in the database, the validation fails.

## Intended Behavior

Entry 0 should act as a wildcard, matching ALL gameobjects for the specified event. This is a common pattern in WoW scripting:
- Entry 0 for creature events = all creatures
- Entry 0 for item events = all items
- Entry 0 for gameobject events = all gameobjects

## Affected Files

- `src/lua/ability-tomes.lua:307` - Tome spawning on any chest open
- `src/lua/chest-vulnerability.lua:326` - Vulnerability on any chest use

## Suggested Implementation

### Option 1: C++ Patch to ALE (Recommended)

Patch `source-beta/modules/mod-ale/src/LuaEngine/LuaEngine.cpp` to skip template validation when entry is 0:

```cpp
// Before line 1414, add:
if (entry != 0)  // entry 0 = wildcard for all gameobjects
{
    if (!eObjectMgr->GetGameObjectTemplate(entry))
    {
        luaL_unref(L, LUA_REGISTRYINDEX, functionRef);
        luaL_error(L, "Couldn't find a gameobject with (ID: %d)!", entry);
        return 0;
    }
}
```

This matches how creature events handle entry 0 in other Eluna forks.

### Option 2: Register Specific Entries

Query database for all chest-type gameobjects and register each:

```lua
-- Query: SELECT entry FROM gameobject_template WHERE type = 3
local CHEST_ENTRIES = {2843, 2844, 2849, ...}  -- Hundreds of entries
for _, entry in ipairs(CHEST_ENTRIES) do
    RegisterGameObjectEvent(entry, 14, handler)
end
```

Downsides:
- Verbose and unmaintainable
- Misses dynamically spawned custom chests
- Requires database queries at load time

### Option 3: Player Event Approach

Use `PLAYER_EVENT_ON_LOOT_ITEM` or packet events to detect chest interactions.

Downsides:
- Fires after loot, not on chest open
- Different event semantics
- Requires restructuring the feature logic

## Recommendation

**Option 1 (C++ patch)** is the correct fix. It:
- Matches expected behavior from other Lua engines
- Requires no changes to existing Lua scripts
- Works for all current and future gameobjects
- Is idempotent and can be added to PHASE_BEGIN patches

## Patch Documentation

If implementing Option 1, create: `docs/patches/ale-gameobject-wildcard.md`

## Related

- Issue 405: Ability tome system
- Issue 153: Chest vulnerability mechanic
- B002: playerbots-ale-login-hook (similar C++ patch approach)

## What Came After

Added 2026-10-17 (the text above is the copy from before the April
renumbering, when this was issue 325; it is left as it was).

- **The fuller copy is `issues/307-ale-gameobject-wildcard.md`**, the
  version kept up after the migration. It says "Completed (2026-04-08)" but
  was never moved here, because it has the same file name as this one.
  Which copy should stay is an open question for the owner.
- **The fix lives on as patch B003** (`patches/B003-ale-gameobject-wildcard.sh`),
  applied before every build and taken off after, as the patch system does.
- **The two scripts that needed it moved and were switched off.** When the
  Lua tree was split by profile (2026-06-02) `src/lua/` became
  `src/lua-beta/`, and both scripts are there as
  `ability-tomes.lua.disabled` and `chest-vulnerability.lua.disabled`:
  beta's survival features were switched off for the profile baseline and
  are being brought back by the beta roadmap (issue 200). The wildcard is
  ready for them when they return.
- **Built on by:** issue 405 (the ability tome system registers its chest events
  with entry 0, and lists this issue as required) and issue 606b (the nil
  position errors, which notes the gameobject errors as resolved here).
- **The number 307 meant something else before April:** the narrator
  audience-facing issue, now 908. Narrator issues still said "307" for it;
  909, 910 and 100 were corrected on 2026-10-17.
