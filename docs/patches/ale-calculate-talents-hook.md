# Talent Point Bonus — C++ Module

**Status:** Implemented as `mod-talent-bonus` (linked via B008)

## Why This Is Needed

When a player logs in or levels up, the server calls `InitTalentForLevel()` which:

1. Calls `CalculateTalentsPoints()` to get the expected talent count
2. If `usedTalents > expected`, **resets ALL talents**
3. Otherwise, sets `FreeTalentPoints = expected - used`

Without intervention, any bonus talents granted via Lua would cause talent
resets on login, because the server's own validation does not know about
them.

The original design explored adding `PLAYER_EVENT_ON_CALCULATE_TALENTS_POINTS`
to ALE as a Lua-callable hook. We chose the **standalone module** path
instead: it's cleaner (no ALE diff), it's faster to compute (no Lua
round-trip on every level validation), and it leaves the Lua surface
free of a hook nobody else needs.

## Implementation

A custom AzerothCore module, `mod-talent-bonus`, lives at
`modules/mod-talent-bonus/` and is symlinked into `source-{profile}/modules/`
by B008 so the AzerothCore build picks it up.

The module overrides `PlayerScript::OnPlayerCalculateTalentsPoints` and
adjusts the expected count based on the player's progress toward the next
level.

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

### B008 link step

B008 creates the symlink before cmake runs:

```bash
ln -sfn "${DIR}/modules/mod-talent-bonus" \
        "${DIR}/source-${PROFILE}/modules/mod-talent-bonus"
```

## Build

A normal `./scripts/update` rebuild picks up the module.

## Related

- `Player::CalculateTalentsPoints()` — base calculation in `Player.cpp`
- `Player::InitTalentForLevel()` — validation logic that would reset talents
- `ScriptMgr::OnPlayerCalculateTalentsPoints()` — hook dispatch
