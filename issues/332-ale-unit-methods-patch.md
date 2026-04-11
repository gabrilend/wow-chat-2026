# 332 - ALE Unit Methods Patch

## Status
- Created: 2026-04-08
- Resolved: 2026-04-08
- **PATCH RE-IMPLEMENTED** (2026-04-09)
- Phase: 2
- Priority: High
- Related: Issue 328 (GetPosition nil errors)

**Note (2026-04-09):** Patch added to `scripts/azerothcore` as B007.
- `patch_B007_ale_unit_methods()` adds SetWalk, IsWalking, IsHostileTo, IsFriendlyTo to ALE
- `unpatch_B007_ale_unit_methods()` removes the methods after build
- Source is now patched during build and reverted after (Issue 334)

## Current Behavior (Before Fix)

Bot behavior scripts called Eluna-compatible methods that don't exist in ALE:

```
lua_scripts/custom/behaviors/bot-wander.lua:318: attempt to call method 'SetWalk' (a nil value)
lua_scripts/custom/behaviors/find-monsters.lua:36: attempt to call method 'IsHostileTo' (a nil value)
```

- `Unit:SetWalk(enable)` - Only existed for Creature in ALE, not Player/Unit
- `Unit:IsHostileTo(target)` - Did not exist in ALE
- `Unit:IsFriendlyTo(target)` - Did not exist in ALE
- `Unit:IsWalking()` - Did not exist in ALE

## Intended Behavior (After Fix)

All four methods work for any Unit type (Player, Creature, etc.):

| Method | Description | Implementation |
|--------|-------------|----------------|
| `Unit:SetWalk(enable)` | Set walk/run movement state | Sets MOVEMENTFLAG_WALKING |
| `Unit:IsWalking()` | Check if unit is walking | Reads movement flags |
| `Unit:IsHostileTo(target)` | Faction-based hostility check | Uses GetReactionTo <= REP_HOSTILE |
| `Unit:IsFriendlyTo(target)` | Faction-based friendship check | Uses GetReactionTo >= REP_FRIENDLY |

## Implementation Steps

### 1. Patch ALE C++ Source

Added methods to `source-beta/modules/mod-ale/src/LuaEngine/methods/UnitMethods.h`:

```cpp
int SetWalk(lua_State* L, Unit* unit)
{
    bool enable = ALE::CHECKVAL<bool>(L, 2, true);
    unit->SetWalk(enable);
    return 0;
}

int IsWalking(lua_State* L, Unit* unit)
{
    ALE::Push(L, unit->IsWalking());
    return 1;
}

int IsHostileTo(lua_State* L, Unit* unit)
{
    Unit* target = ALE::CHECKOBJ<Unit>(L, 2);
    ALE::Push(L, unit->IsHostileTo(target));
    return 1;
}

int IsFriendlyTo(lua_State* L, Unit* unit)
{
    Unit* target = ALE::CHECKOBJ<Unit>(L, 2);
    ALE::Push(L, unit->IsFriendlyTo(target));
    return 1;
}
```

### 2. Register Methods in LuaFunctions.cpp

Added to `source-beta/modules/mod-ale/src/LuaEngine/LuaFunctions.cpp` in UnitMethods array:

```cpp
{ "SetWalk", &LuaUnit::SetWalk },
{ "IsWalking", &LuaUnit::IsWalking },
{ "IsHostileTo", &LuaUnit::IsHostileTo },
{ "IsFriendlyTo", &LuaUnit::IsFriendlyTo },
```

### 3. Rebuild Server

```bash
./scripts/azerothcore update
```

## Why Native Methods Required

### SetWalk - Animation Control

Initial workaround attempted speed manipulation (`SetSpeedRate()`), but user correctly identified:
"we need to change the walking animation too" - speed changes don't trigger MOVEMENTFLAG_WALKING.

The native `Unit::SetWalk()` method:
- Sets/clears MOVEMENTFLAG_WALKING movement flag
- Calls `propagateSpeedChange()` to sync with clients
- Produces proper walking animation, not just slower running

### IsHostileTo - Faction Relationships

Initial workaround used proximity checks (`GetCreaturesInRange()`), but user correctly identified:
"IsHostileTo should check whether two units are hostile to one another, not whether they're close enough to fight"

The native `Unit::IsHostileTo()` method:
- Calls `GetReactionTo(unit) <= REP_HOSTILE`
- `GetReactionTo()` checks faction template data (friend/enemy lists, flags)
- Uses server's existing faction relationship data - no hardcoded faction IDs needed

## Related Files

- `docs/patches/ale-unit-setwalk.md` - Patch documentation
- `src/lua/behaviors/bot-wander.lua:318` - Uses SetWalk for walking animation
- `src/lua/behaviors/find-monsters.lua:36` - Uses IsHostileTo for targeting
- `src/lua/behaviors/avoid-monsters.lua` - Uses IsHostileTo for threat detection

## Secondary Fix: ObjectVariables.ext Duplicate

During testing, encountered crash:
```
[ALE]: Cannot execute call: registered value is 576, not a function.
```

**Root Cause:** Duplicate ObjectVariables.ext files causing Lua state corruption:
- `installed-files-beta/bin/lua_scripts/extensions/ObjectVariables.ext` - Broken (uses GetObjectType)
- `src/lua/extensions/ObjectVariables.ext` - Fixed (uses GetTypeId)
- Recursive symlink `extensions -> src/lua/extensions` inside extensions directory

**Fix:** Replaced `installed-files-beta/bin/lua_scripts/extensions/` directory with symlink to `src/lua/extensions/`, matching how `custom/` directory is already configured.

## Tertiary Fix: ObjectVariables Memory Cleanup

The original ObjectVariables.ext registered event handlers for cleanup:
```lua
RegisterServerEvent(31, DestroyObjData) -- creature delete
RegisterServerEvent(32, DestroyObjData) -- gameobject delete
RegisterServerEvent(17, DestroyMapData) -- map create
RegisterServerEvent(18, DestroyMapData) -- map destroy
```

**Problem:** These server event IDs (17, 18, 31, 32) don't exist in ALE - only 1-7 exist.
Registering non-existent events corrupted the Lua registry.

**Solution:** Removed event registrations from extension, exposed cleanup functions instead:
- `ObjectVariables.cleanupPlayer(player)` - call from logout handlers
- `ObjectVariables.cleanupCreature(creature)` - call when despawning creatures
- `ObjectVariables.cleanupGameObject(gameobject)` - call when despawning gameobjects
- `ObjectVariables.cleanupGameObjectByLocation(mapId, instanceId, guid)` - for cached location data
- `ObjectVariables.getStats()` - debug function to monitor memory usage

**Integration points:**
- `periodic_events.lua:OnPlayerLogout` - calls cleanupPlayer
- `ambush.lua:Ambush.despawn` - calls cleanupCreature
- `travel.lua:Travel.despawn` - calls cleanupCreature
- `treasure.lua:Treasure.returnToPool` - calls cleanupGameObjectByLocation

**Design principle:** Event registrations in .ext files can corrupt ALE's Lua registry.
Move event registrations to .lua files where they work correctly.

## Quaternary Fix: ALE Source Extensions (2026-04-09)

Persistent crash with assertion failure `base > 0` in ExecuteCall.

**Root Cause:** ALE module ships with its own copy of extensions at:
```
source-beta/modules/mod-ale/src/LuaEngine/extensions/
├── ObjectVariables.ext  (broken - uses GetObjectType, invalid event IDs)
├── StackTracePlus/      (may interfere with ALE traceback handling)
└── _Misc.ext           (enables StackTracePlus)
```

This directory contains the original Eluna-compatible extensions, not our ALE-fixed versions.
Even though `installed-files-beta/bin/lua_scripts/extensions` symlinks to our fixed versions,
ALE might load from its source directory during certain operations.

**Fix:** Updated ALE source extensions to match our fixed versions:
1. Copied `src/lua/extensions/ObjectVariables.ext` → ALE source extensions
2. Copied `src/lua/extensions/_Misc.ext` → ALE source extensions
3. Renamed `StackTracePlus/` → `StackTracePlus.disabled/` in both locations

**Directory locations fixed:**
- `source-beta/modules/mod-ale/src/LuaEngine/extensions/`
- `src/lua/extensions/`

## Lessons Learned

1. **No fallbacks** - Workarounds that don't match the intended behavior should not be implemented under the original function name. If proximity checks are useful, they get their own function.

2. **AzerothCore already has the data** - Faction relationships, movement flags, etc. are already computed by the C++ core. The fix is exposing them to Lua, not reimplementing them.

3. **Check for duplicates** - When extensions fail to load, verify there aren't multiple versions being loaded.

4. **No event registration in .ext files** - Extensions load before main Lua files. Event registration in this early phase can corrupt ALE's registry. Use .ext files only for method definitions and global setup.

5. **Check ALL extension locations** - ALE has extensions in multiple places: the runtime lua_scripts directory AND the module source directory. Both must be kept in sync or issues will occur.
