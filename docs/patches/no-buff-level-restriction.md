# No Buff Level Restriction Patch (B032)

## Overview

A player's buff can be put on any target, whatever the gap between the
buff's level and the target's. Stock, a buff cast on someone else is refused
when the target is more than 10 levels below the buff's lowest rank ("target
is too low level"). Issue 155o, basic profile: Inscription's scrolls are
usable at 60 in every rank, and ranks VII and VIII carry spells of level 70
and 80. Choosing a lower rank for a low-level target, where one exists, is
unchanged.

## Files to Modify

### 1. `src/server/game/Spells/Spell.cpp`

In `Spell::prepare` (the part after targets are selected, where positive
auras are rank-scaled), find the target filter whose comment reads "remove
targets which did not pass min level check":

```cpp
                    if (!targetInfo.scaleAura && targetInfo.targetGUID != m_caster->GetGUID())
                        return true;
```

Make its condition never hold, so no target is removed:

```cpp
                    if (false && !targetInfo.scaleAura && targetInfo.targetGUID != m_caster->GetGUID())
                        return true;
```

## Usage

Nothing to configure. A level-60 player can read Scroll of Stamina VIII
(spell level 80) on another level-60 player.

## Build Instructions

Applied automatically by `patches/B032-no-buff-level-restriction.sh` for the
profiles that list B032 in `patches/patches.sh` (basic), then
`scripts/compile`. `scripts/test-source-patches` checks the apply/revert
round trip without compiling.
