# No Crushing Blows From Level 64+ Patch (B031)

## Overview

Creatures of level 64 and higher never land crushing blows. Below 64 the
stock rule stands. Issue 803 (extension, 2026-09-24), basic profile; kept
apart from B005 (the accuracy cap) so a profile can take either alone.

Stock rule, for reference: a creature 4 or more levels above its target can
crush (150% damage) when its weapon skill is 15+ above the target's
defense; the chance is 2% per point of that gap minus 15%, so 25% at a
4-level gap, and every non-avoided hit is a crush past about 8 levels.

## Files to Modify

### 1. `src/server/game/Entities/Unit/Unit.cpp`

In `Unit::RollMeleeOutcomeAgainst`, find the crushing-blow branch, whose
comment reads "mobs can score crushing blows if they're 4 or more levels
above victim". Its condition opens with:

```cpp
    if (getLevelForTarget(victim) >= victim->getLevelForTarget(this) + 4 &&
```

Change that line to:

```cpp
    if (getLevelForTarget(victim) >= victim->getLevelForTarget(this) + 4 && getLevelForTarget(victim) < 64 &&
```

The rest of the condition (not player-controlled, not flagged "no crushing
blows") is unchanged.

## Usage

Nothing to configure. A level-64+ creature's melee now rolls miss, dodge,
parry, block, glancing, critical and normal hits, never crushing.

## Build Instructions

Applied automatically by `patches/B031-no-crushing-blows-64.sh` for the
profiles that list B031 in `patches/patches.sh` (basic), then
`scripts/compile`. `scripts/test-source-patches` checks the apply/revert
round trip without compiling.
