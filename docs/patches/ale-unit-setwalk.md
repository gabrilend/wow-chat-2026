# ALE Unit Methods Patch

## Overview

Adds missing Eluna-compatible methods to ALE for Unit types:

| Method | Description |
|--------|-------------|
| `Unit:SetWalk(enable)` | Set walk/run movement state |
| `Unit:IsWalking()` | Check if unit is walking |
| `Unit:IsHostileTo(target)` | Check faction-based hostility |
| `Unit:IsFriendlyTo(target)` | Check faction-based friendship |

All methods work for all Unit types (Player, Creature, etc.).

## Motivation

Bot behaviors need:
- Walking animation for natural movement (not just slower running)
- Faction relationship checks for targeting decisions

The underlying C++ methods exist in AzerothCore's Unit class - this patch exposes them to Lua.

## Files Modified

### 1. `modules/mod-ale/src/LuaEngine/methods/UnitMethods.h`

Added after `SetSpeedRate` method:

```cpp
    /**
     * Sets whether the [Unit] is currently walking or running.
     * Works for all Unit types including Player.
     *
     * @param bool enable = true : true to enable walking, false for running
     */
    int SetWalk(lua_State* L, Unit* unit)
    {
        bool enable = ALE::CHECKVAL<bool>(L, 2, true);
        unit->SetWalk(enable);
        return 0;
    }

    /**
     * Returns whether the [Unit] is currently walking.
     *
     * @return bool isWalking
     */
    int IsWalking(lua_State* L, Unit* unit)
    {
        ALE::Push(L, unit->IsWalking());
        return 1;
    }

    /**
     * Returns true if the [Unit] is hostile to the specified [Unit].
     * Uses faction relationship data to determine hostility.
     *
     * @param [Unit] target : the unit to check hostility against
     * @return bool isHostile
     */
    int IsHostileTo(lua_State* L, Unit* unit)
    {
        Unit* target = ALE::CHECKOBJ<Unit>(L, 2);
        ALE::Push(L, unit->IsHostileTo(target));
        return 1;
    }

    /**
     * Returns true if the [Unit] is friendly to the specified [Unit].
     * Uses faction relationship data to determine friendship.
     *
     * @param [Unit] target : the unit to check friendship against
     * @return bool isFriendly
     */
    int IsFriendlyTo(lua_State* L, Unit* unit)
    {
        Unit* target = ALE::CHECKOBJ<Unit>(L, 2);
        ALE::Push(L, unit->IsFriendlyTo(target));
        return 1;
    }
```

### 2. `modules/mod-ale/src/LuaEngine/LuaFunctions.cpp`

In the `UnitMethods` array (after SetSpeedRate):

```cpp
    { "SetWalk", &LuaUnit::SetWalk },
    { "IsWalking", &LuaUnit::IsWalking },
    { "IsHostileTo", &LuaUnit::IsHostileTo },
    { "IsFriendlyTo", &LuaUnit::IsFriendlyTo },
```

## How It Works

### SetWalk / IsWalking
- `Unit::SetWalk(bool)` sets `MOVEMENTFLAG_WALKING` movement flag
- Calls `propagateSpeedChange()` to sync with clients
- Proper walking animation, not just speed reduction

### IsHostileTo / IsFriendlyTo
- `Unit::IsHostileTo()` returns `GetReactionTo(unit) <= REP_HOSTILE`
- `Unit::IsFriendlyTo()` returns `GetReactionTo(unit) >= REP_FRIENDLY`
- `GetReactionTo()` checks faction template data (friend/enemy lists, flags)
- Server already has this data - no hardcoded faction lists needed

## Usage

```lua
-- Walking
player:SetWalk(true)
player:MoveTo(0, x, y, z, false)

if player:IsWalking() then
    print("Player is walking")
end

-- Hostility checks
if creature:IsHostileTo(player) then
    print("Creature is hostile to player")
end

if player:IsFriendlyTo(npc) then
    print("Player is friendly to NPC")
end
```

## Build Instructions

```bash
./scripts/azerothcore update
```

## Related Issues

- Issue 606b: GetPosition Nil Errors (Eluna→ALE compatibility)
- CreatureMethods.h:972 TODO comment: "Move same to Player?"
