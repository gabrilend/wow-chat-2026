# ALE Gameobject Wildcard Patch

## Overview

This patch enables entry 0 as a wildcard for `RegisterGameObjectEvent` and `RegisterGameObjectGossipEvent`,
allowing Lua scripts to register handlers for ALL gameobjects without specifying individual entries.

## Problem

ALE validates gameobject templates before registration. When entry 0 is passed:

```lua
RegisterGameObjectEvent(0, 14, handler)  -- entry 0 = all gameobjects
```

ALE throws an error:
```
Couldn't find a gameobject with (ID: 0)!
```

The handler is never registered, breaking features that need to hook all gameobjects.

## Files to Modify

### 1. `modules/mod-ale/src/LuaEngine/LuaEngine.cpp`

Two locations need patching to skip template validation when entry is 0.

**Location 1: REGTYPE_GAMEOBJECT (around line 1414)**

Find:
```cpp
        case Hooks::REGTYPE_GAMEOBJECT:
            if (event_id < Hooks::GAMEOBJECT_EVENT_COUNT)
            {
                if (!eObjectMgr->GetGameObjectTemplate(entry))
                {
                    luaL_unref(L, LUA_REGISTRYINDEX, functionRef);
                    luaL_error(L, "Couldn't find a gameobject with (ID: %d)!", entry);
                    return 0; // Stack: (empty)
                }
```

Replace with:
```cpp
        case Hooks::REGTYPE_GAMEOBJECT:
            if (event_id < Hooks::GAMEOBJECT_EVENT_COUNT)
            {
                // entry 0 = wildcard for all gameobjects (Issue 325)
                if (entry != 0 && !eObjectMgr->GetGameObjectTemplate(entry))
                {
                    luaL_unref(L, LUA_REGISTRYINDEX, functionRef);
                    luaL_error(L, "Couldn't find a gameobject with (ID: %d)!", entry);
                    return 0; // Stack: (empty)
                }
```

**Location 2: REGTYPE_GAMEOBJECT_GOSSIP (around line 1431)**

Find:
```cpp
        case Hooks::REGTYPE_GAMEOBJECT_GOSSIP:
            if (event_id < Hooks::GOSSIP_EVENT_COUNT)
            {
                if (!eObjectMgr->GetGameObjectTemplate(entry))
                {
                    luaL_unref(L, LUA_REGISTRYINDEX, functionRef);
                    luaL_error(L, "Couldn't find a gameobject with (ID: %d)!", entry);
                    return 0; // Stack: (empty)
                }
```

Replace with:
```cpp
        case Hooks::REGTYPE_GAMEOBJECT_GOSSIP:
            if (event_id < Hooks::GOSSIP_EVENT_COUNT)
            {
                // entry 0 = wildcard for all gameobjects (Issue 325)
                if (entry != 0 && !eObjectMgr->GetGameObjectTemplate(entry))
                {
                    luaL_unref(L, LUA_REGISTRYINDEX, functionRef);
                    luaL_error(L, "Couldn't find a gameobject with (ID: %d)!", entry);
                    return 0; // Stack: (empty)
                }
```

## Verification

After applying this patch:

1. Rebuild ALE: `cd build && make -j$(nproc) && make install`
2. Start worldserver
3. Check Server.log - no "Couldn't find gameobject" errors
4. Test chest interaction - ability-tomes and chest-vulnerability should work

## Idempotent Check

The patch is idempotent. Check if already applied:

```bash
grep -q "entry != 0 && !eObjectMgr->GetGameObjectTemplate" LuaEngine.cpp
```

If this returns true (exit 0), the patch is already applied.

## Build Instructions

```bash
cd build && make -j$(nproc) && make install
```

## Related

- Issue: `issues/325-ale-gameobject-wildcard-registration.md`
- Affected Lua: `src/lua/ability-tomes.lua:307`, `src/lua/chest-vulnerability.lua:326`
- Similar pattern: B002 playerbots-ale-login-hook
