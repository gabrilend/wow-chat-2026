# Crushing Blows Late Patch (B031)

## Overview

Crushing blows start 4 levels later than stock and ramp in over 4 more
levels: none below a level gap of 8, part of the stock chance from 8 to 11,
the full stock chance from 12 up. For creatures of every level. Issue 803,
basic profile; kept apart from B005 (the accuracy cap) so a profile can take
either alone.

Ritz, 2026-09-27: "can we re-enable the crushing blow penalty at +4 the
level it normally is? And have it scale up to it's nominal percentage with
another 4 levels." This replaces B031's first form (2026-09-24, "crushing
blows do not take effect for creatures level 64 and higher"; its doc was
`no-crushing-blows-64.md`).

**Stock rule, for reference** (`Unit::RollMeleeOutcomeAgainst`): a creature
4 or more levels above its target can crush when its weapon skill is 15 or
more above the target's defense. The chance, in the combat table after
miss, dodge, parry, block and glancing, is 2% per point of that gap minus
15%. A crushing blow does 150% of the hit's damage (a 50% bonus). A
creature's weapon skill is 5 per level; a target's defense counts only up
to its own level's maximum (5 per level), so for a target at its defense
cap the gap is 5 points per level and the chance is 10% per level minus 15%.

**The ramp**: with gap = the creature's level minus the target's (each as
the other sees it),

    gap < 8          no crushing blows
    8 <= gap < 12    stock chance x (gap - 7) / 5
    gap >= 12        stock chance

The factor is 1/5 at a gap of 8, not 0, so a creature 8 levels up really can
crush ("+4 the level it normally is"); it reaches 1 at 12 ("another 4
levels").

| Level gap | Stock chance | New chance |
|-----------|--------------|------------|
| 3 or less | 0%           | 0%         |
| 4         | 25%          | 0%         |
| 5         | 35%          | 0%         |
| 6         | 45%          | 0%         |
| 7         | 55%          | 0%         |
| 8         | 65%          | 13%        |
| 9         | 75%          | 30%        |
| 10        | 85%          | 51%        |
| 11        | 95%          | 76%        |
| 12        | 105%         | 105%       |
| 13 and up | 115% +       | same as stock |

(For a target at its defense cap. A chance past what is left of the combat
table after miss, dodge, parry, block and glancing makes every remaining hit
a crush. A target below its defense cap widens the skill gap and so raises
both columns.) Examples on basic: a level-60 player against a level-68
Outland creature, 13% instead of 65%; against a level-70 elite, 51% instead
of 85%.

## Files to Modify

### 1. `src/server/game/Entities/Unit/Unit.cpp`

In `Unit::RollMeleeOutcomeAgainst`, the crushing-blow branch (under the
comment "mobs can score crushing blows if they're 4 or more levels above
victim"). Two lines change.

Its opening condition:

```cpp
    if (getLevelForTarget(victim) >= victim->getLevelForTarget(this) + 4 &&
```

becomes

```cpp
    if (getLevelForTarget(victim) >= victim->getLevelForTarget(this) + 8 &&
```

and inside it, the chance line:

```cpp
            tmp = tmp * 200 - 1500;
```

becomes

```cpp
            tmp = tmp * 200 - 1500;
            if (int32 b031Gap = int32(getLevelForTarget(victim)) - int32(victim->getLevelForTarget(this)); b031Gap < 12)
                tmp = tmp * (b031Gap - 7) / 5;
```

(`tmp` is in hundredths of a percent; the condition above guarantees a gap
of at least 8, so the factor is between 1/5 and 4/5.) The rest of the branch
(not player-controlled, not flagged "no crushing blows", the 15-point skill
threshold, 150% damage) is unchanged.

## Usage

Nothing to configure. The numbers are in the patch; tuning goes to
`docs/balance-updates.md` with a change to the patch.

## Build Instructions

Applied automatically by `patches/B031-crushing-blows-late.sh` for the
profiles that list B031 in `patches/patches.sh` (basic), then
`scripts/compile`. `scripts/test-source-patches` checks the apply/revert
round trip without compiling; `scripts/test-patched-syntax` compiles the
patched file's syntax.
