# 325 - ALE Gameobject Wildcard Registration

## Status
- Created: 2026-04-08
- Phase: 2
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

- Issue 151: Ability tome system
- Issue 153: Chest vulnerability mechanic
- B002: playerbots-ale-login-hook (similar C++ patch approach)
