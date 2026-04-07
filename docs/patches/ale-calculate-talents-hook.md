# ALE Patch: OnPlayerCalculateTalentsPoints Hook

## Overview

Exposes the `OnPlayerCalculateTalentsPoints` hook to Lua, allowing scripts to modify
the expected talent point count during server validation.

## Why This Is Needed

When a player logs in or levels up, the server calls `InitTalentForLevel()` which:

1. Calls `CalculateTalentsPoints()` to get expected talent count
2. If `usedTalents > expected`, **resets ALL talents**
3. Otherwise, sets `FreeTalentPoints = expected - used`

Without this hook, any bonus talents granted via Lua will cause talent resets on login
because the server doesn't know about them during validation.

## Files to Modify

### 1. `src/LuaEngine/LuaEngine.h`

Add new hook enum value in `PlayerEvents`:

```cpp
// Find the PlayerEvents enum, add at the end before PLAYER_EVENT_COUNT:
PLAYER_EVENT_ON_CALCULATE_TALENTS_POINTS    = XX,  // (event, player, talentPoints) - can return modified points
```

### 2. `src/LuaEngine/LuaEngine.cpp`

Add hook handler. Find the PlayerScript class implementation and add:

```cpp
void OnPlayerCalculateTalentsPoints(Player const* player, uint32& talentPointsForLevel) override
{
    if (!PlayerEventBindings->HasEvents(PLAYER_EVENT_ON_CALCULATE_TALENTS_POINTS))
        return;

    LOCK_ELUNA;
    Push(player);
    Push(talentPointsForLevel);
    int n = EventBindings->ExecuteCall();

    // If Lua returned a value, use it as the new talent points
    if (n > 0)
    {
        talentPointsForLevel = CHECKVAL<uint32>(-1);
    }
    CleanUpStack(n);
}
```

### 3. `src/LuaEngine/methods/GlobalMethods.h`

Update the `RegisterPlayerEvent` documentation comment to include:

```cpp
*     PLAYER_EVENT_ON_CALCULATE_TALENTS_POINTS       =     XX,       // (event, player, talentPoints) - Can return new talent points
```

## Lua Usage

```lua
local PLAYER_EVENT_ON_CALCULATE_TALENTS_POINTS = XX  -- Use actual enum value

RegisterPlayerEvent(PLAYER_EVENT_ON_CALCULATE_TALENTS_POINTS, function(event, player, basePoints)
    local level = player:GetLevel()
    local currentXP = player:GetXP()
    local xpToLevel = player:GetUInt32Value(36)

    if xpToLevel <= 0 then return basePoints end

    local progress = currentXP / xpToLevel
    local bonusPoints = 0

    if progress >= 0.33 then bonusPoints = bonusPoints + 1 end
    if progress >= 0.66 then bonusPoints = bonusPoints + 1 end

    return basePoints + bonusPoints
end)
```

## Alternative: C++ Module

If modifying mod-ale is not desired, create a standalone module:

### `mod-talent-bonus/src/TalentBonus.cpp`

```cpp
#include "ScriptMgr.h"
#include "Player.h"

class TalentBonusScript : public PlayerScript
{
public:
    TalentBonusScript() : PlayerScript("TalentBonusScript") { }

    void OnPlayerCalculateTalentsPoints(Player const* player, uint32& talentPointsForLevel) override
    {
        uint32 xpToLevel = player->GetUInt32Value(PLAYER_NEXT_LEVEL_XP);
        if (xpToLevel == 0) return;

        float progress = static_cast<float>(player->GetXP()) / xpToLevel;

        if (progress >= 0.33f) talentPointsForLevel += 1;
        if (progress >= 0.66f) talentPointsForLevel += 1;
    }
};

void AddTalentBonusScripts()
{
    new TalentBonusScript();
}
```

### `mod-talent-bonus/src/mod-talent-bonus_loader.cpp`

```cpp
void AddTalentBonusScripts();

void Addmod_talent_bonusScripts()
{
    AddTalentBonusScripts();
}
```

## Build Instructions

After applying patch or adding module:

```bash
cd build
cmake .. -DSCRIPTS=static -DMODULES=static
make -j$(nproc)
make install
```

## Related

- `Player::CalculateTalentsPoints()` - Base calculation in Player.cpp:13647
- `Player::InitTalentForLevel()` - Validation logic in Player.cpp:2538
- `ScriptMgr::OnPlayerCalculateTalentsPoints()` - Hook dispatch in PlayerScript.cpp:57
- Issue 120 - talent-points-level-20-cap
