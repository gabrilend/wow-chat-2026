# 130 - ALE Initialization Hook Fix

## Status: Completed

**Note**: C++ fix applied. Lua scripts now loading correctly. Merged with issue 134.

## Problem

ALE (AzerothCore Lua Engine) was not initializing, preventing any Lua scripts from
loading. The Lua scripts for monsters, travellers, treasure spawns, and all other
custom content were completely non-functional.

Additionally, even when ALE initializes, behavior scripts in subdirectories are not
automatically loaded - they require explicit loading via a root-level loader script.

## Root Cause Analysis

### Symptoms
- No ALE.log file created
- No "Initialize ALE Lua Engine..." message in Server.log
- No Lua script output (test-loading.lua print statements not appearing)
- `.reload ALE` command not available
- Behavior scripts in `src/lua/behaviors/` not executing

### Investigation Timeline

1. **Config Verification**: Confirmed `ALE.Enabled = true` in mod_ale.conf
2. **Binary Check**: Verified ALE code is compiled into worldserver via `strings`
3. **Module Registration**: Confirmed `Addmod_aleScripts()` is called in ModulesLoader.cpp
4. **Hook Analysis**: Discovered `WORLDHOOK_ON_BEFORE_CONFIG_LOAD` never fires
5. **Subdirectory Loading**: ALE only auto-loads root `.lua` files, not subdirectories

### Technical Details

ALE's initialization was tied to `OnBeforeConfigLoad` hook:

```cpp
void OnBeforeConfigLoad(bool reload) override
{
    ALEConfig::GetInstance().Initialize(reload);
    if (!reload)
    {
        LOG_INFO("ALE", "Initialize ALE Lua Engine...");
        ALE::Initialize();
    }
    sALE->OnConfigLoad(reload, true);
}
```

However, this hook was not firing. Meanwhile, `WORLDHOOK_ON_BEFORE_WORLD_INITIALIZED`
(used by mod-playerbots) was working correctly.

The existing `OnBeforeWorldInitialized` tried to run scripts, but since ALE was never
initialized, it failed silently or crashed:

```cpp
void OnBeforeWorldInitialized() override
{
    sALE->RunScripts();  // CRASH: sALE not initialized
    sALE->OnConfigLoad(false, false);
}
```

## Solution

### Part 1: C++ Fix (NOT YET APPLIED)

Modify `ALE_SC.cpp` to perform initialization in `OnBeforeWorldInitialized` instead
of relying on the unreliable `OnBeforeConfigLoad` hook.

**File**: `source/modules/mod-eluna/src/ALE_SC.cpp`

```cpp
void OnBeforeWorldInitialized() override
{
    // Initialize ALE here since OnBeforeConfigLoad may not fire in some builds.
    // This hook is called later but reliably fires.
    if (!ALE::IsInitialized())
    {
        ALEConfig::GetInstance().Initialize(false);
        LOG_INFO("ALE", "Initialize ALE Lua Engine...");
        ALE::Initialize();
    }

    ///- Run ALE scripts.
    sALE->RunScripts();
    sALE->OnConfigLoad(false, false);
}
```

Also add guards to other hook callbacks to prevent crashes if called before
initialization:

```cpp
void OnAfterConfigLoad(bool reload) override
{
    if (ALE::IsInitialized())
    {
        sALE->OnConfigLoad(reload, false);
    }
}
```

### Part 2: Lua Loader (COMPLETED)

Created `src/lua/load-behaviors.lua` which:
- Sets up package.path to include behaviors directory
- Requires `behaviors/init`
- Has error handling with pcall

Created `src/lua/behaviors/init.lua` which:
- Loads behaviors in dependency order
- Registers loaded behaviors in global `Behaviors` table
- Prints initialization messages

Fixed missing `.lua` extensions:
- `src/lua/levelling` → `src/lua/levelling.lua`
- `src/lua/merchants` → `src/lua/merchants.lua`

## Implementation Steps

- [x] Apply C++ fix to `source-beta/modules/mod-ale/src/ALE_SC.cpp`
- [x] Rebuild server (`./scripts/azerothcore update --force`)
- [x] Start server and verify ALE initializes
- [x] Create load-behaviors.lua (done)
- [x] Create behaviors/init.lua (done)
- [x] Fix file extensions (done)
- [x] Verify behaviors load (Lua scripts loading confirmed)

## Related Issues

- **113 - Ambush System**: Depends on Lua scripts working
- **125 - Player Bot Behavior Commands**: Lua extension scripts
- **127 - Contextual Creature Spawns**: Lua-based spawn system
- ~~**134 - Behavior Scripts Not Loading**: Merged into this issue~~

## Files Modified

**C++ (pending):**
- `source/modules/mod-eluna/src/ALE_SC.cpp`

**Lua (completed):**
- `src/lua/load-behaviors.lua` (new)
- `src/lua/behaviors/init.lua` (new)
- `src/lua/levelling.lua` (renamed from levelling)
- `src/lua/merchants.lua` (renamed from merchants)

## Testing Checklist

- [ ] Server starts without crashes
- [ ] "Initialize ALE Lua Engine..." appears in Server.log
- [ ] ALE.log file is created
- [ ] Root Lua scripts execute (ambush.lua, travel.lua)
- [ ] "[Behaviors] System initialized - 9 behaviors loaded" appears
- [ ] Monsters spawn from ambush.lua
- [ ] Travellers spawn from periodic_events.lua

## Lessons Learned

1. Not all WorldScript hooks fire reliably in all AzerothCore builds
2. `WORLDHOOK_ON_BEFORE_WORLD_INITIALIZED` is more reliable than `WORLDHOOK_ON_BEFORE_CONFIG_LOAD`
3. Always add null/initialization guards to hook callbacks
4. mod-eluna.conf (if present) may conflict with mod-ale - removed as precaution
5. ALE only auto-loads root-level `.lua` files, subdirectories need explicit require

## Concept Catalog Reference

- 001-010: Foundation (project structure)
- 101-139: Behavior systems
