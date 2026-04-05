# Accuracy Level Cap - C++ Patch

**Issue:** 156 - Monster Accuracy Level Cap
**Purpose:** Cap level difference impact on hit/miss at ±3 levels

## Overview

This patch modifies combat hit/miss calculations to cap the effective level difference at ±3. A monster 10 levels above you has the same hit/miss modifier as one 3 levels above. Similarly, a monster 10 levels below has the same modifier as one 3 levels below.

## Files to Modify

### 1. src/server/game/Entities/Unit/Unit.cpp

#### Location: GetMissChance() or equivalent

Find functions that calculate miss chance based on level difference:
- `Unit::RollMeleeOutcomeAgainst()`
- `Unit::MagicSpellHitResult()`
- Any helper that computes level-based miss penalty

#### Change Pattern

Wherever level difference is calculated for accuracy purposes:

**Before:**
```cpp
int32 levelDiff = victim->GetLevel() - GetLevel();
// ... use levelDiff in calculations
```

**After:**
```cpp
int32 rawLevelDiff = victim->GetLevel() - GetLevel();
// Cap level difference at ±3 for accuracy calculations
int32 levelDiff = std::max(-3, std::min(3, rawLevelDiff));
// ... use levelDiff in calculations
```

### 2. src/server/game/Entities/Unit/Unit.h (optional)

If creating a reusable helper:

```cpp
// In Unit class, public section:
static int32 GetCappedLevelDiff(Unit const* attacker, Unit const* victim, int32 cap = 3)
{
    int32 rawDiff = victim->GetLevel() - attacker->GetLevel();
    return std::max(-cap, std::min(cap, rawDiff));
}
```

## Specific Functions to Modify

### RollMeleeOutcomeAgainst

This function determines melee attack outcomes (hit, miss, dodge, parry, etc.).

Look for patterns like:
```cpp
int32 attackerLvlModifier = GetLevel();
int32 defenderLvlModifier = victim->GetLevel();
```

Or:
```cpp
int32 levelDiff = GetLevelDiff(victim);
```

Apply the cap before these values are used in miss chance calculations.

### MagicSpellHitResult

This function determines spell hit/miss outcomes.

Similar patterns exist. Cap the level difference before it's used to modify hit chance.

### GetWeaponSkillValue / GetDefenseSkillValue

If weapon/defense skill values incorporate level, cap the level component.

## Constants

The level cap (3) should be defined as a constant for easy tuning:

```cpp
// In Unit.h or a config file
#define ACCURACY_LEVEL_CAP 3
```

## Testing Approach

1. Create level 1 character
2. Fight level 20 monster
3. Verify hit rate is poor but not impossible (same as fighting level 4 monster)
4. Create level 20 character
5. Fight level 1 monster
6. Verify miss rate is low but not zero (same as fighting level 17 monster)

## Design Notes

This intentionally does NOT cap:
- Damage calculations (high level monsters still hit harder)
- Health differences (high level monsters still have more HP)
- Armor/resistance calculations (may use actual level)

Only the hit/miss probability is capped, ensuring combat is possible across large level gaps while maintaining challenge through other mechanics.

## Alternative: Config Option

If making this configurable via worldserver.conf:

```cpp
// In worldserver.conf
AccuracyLevelCap = 3  // 0 = disabled (vanilla behavior)
```

Then read from config:
```cpp
int32 cap = sWorld->getIntConfig(CONFIG_ACCURACY_LEVEL_CAP);
if (cap > 0)
    levelDiff = std::max(-cap, std::min(cap, levelDiff));
```
