# 142 - Symmetric Aggro Radius (B024)

## Status
- Created: 2026-05-21
- Phase: 1 (Foundation — engine behaviour)
- Priority: Medium (gameplay-shaping, not a bug fix)
- Patch: B024

## Current Behavior (Vanilla)

`Creature::GetAttackDistance(victim)` in
`src/server/game/Entities/Creature/Creature.cpp:3592` implements the
original WoW aggro radius formula:

```cpp
float retDistance = 20.0f;
retDistance -= static_cast<float>(levelDiff);  // levelDiff = playerLevel - creatureLevel
```

The asymmetric `-=` means: positive `levelDiff` (player is higher
level) shrinks the radius, negative `levelDiff` (player is lower
level) grows it. A level-60 mob notices a level-30 player from ~50
yards but a level-90 player from only ~5 yards. The "prey on the
weak" semantic — high-level mobs are very aware of low-level
characters wandering by, and low-level mobs are barely visible to
high-level characters.

## Why That's Wrong For Everland Ghostsong

The Everland Ghostsong world has no static populated zones with
level-distributed mobs that a player gradually outgrows. Instead,
the ambush system spawns creatures *at the triggering player's
level* (the SQL query at `src/lua/ambush.lua` filters on
`minlevel <= playerLevel <= maxlevel`). Every creature is by
construction level-appropriate for the player who summoned it.

Under the vanilla asymmetric formula, those creatures still notice
*other* nearby players or bots disproportionately by level mismatch.
A level-40 spawn for a level-40 player would notice a level-20
playerbot following its owner from much further away than the
level-40 player itself — the opposite of what the per-player
ambush design (issue 210) is trying to achieve.

## Intended Behavior

Radius peaks at the *matching* level (and a tight plateau around it)
and decays symmetrically in both directions:

```
|levelDiff|   →   radius
  0, 1, 2, 3       20.0 yards   (plateau)
  4                18.0
  5                16.2
  6                14.58
  7                13.12
  ...
  13               6.97
  ...              (clamped to 5.0 yard floor further down the function)
```

Formula: `radius = 20.0 * 0.9^max(0, |levelDiff|-3)`

Implemented as an explicit loop rather than `std::pow` so the source
reads as the design intent literally: "for each level beyond the ±3
plateau, multiply the remaining radius by 0.9."

The `-25` level-diff cap from vanilla becomes redundant — exponential
decay drives the radius below the 5-yard floor naturally at
sufficiently large mismatches in either direction. Removed.

## Implementation

`patches/B024-symmetric-aggro-radius.sh` applies a single multi-line
`sed -z` substitution that replaces the three-section asymmetric
block (cap + base + signed subtraction) with the marker-wrapped
plateau-and-decay block. Round-trip verified clean against upstream
HEAD.

Registered in `patches/patches.sh` for both `release` and `beta`
profiles. Witness function `patch_needs_applying_B024` greps for the
marker.

### Affected Source

- `src/server/game/Entities/Creature/Creature.cpp::GetAttackDistance`
  — body of one function, six original lines (three logical blocks)
  replaced with marker-wrapped fourteen-line block.

### Behaviour Untouched

- In-combat target selection (`Creature::SelectVictim` and
  `ThreatManager::GetCurrentVictim`) — unchanged. Once combat
  begins, highest-threat target still wins. This patch only affects
  *who picks fights*, not who gets hit *during* fights. This is a
  deliberate scoping decision from the design conversation; see
  notes/ambush-symmetric-aggro.md if a similar issue eventually
  exists for combat targeting.
- The min 5-yard floor (vanilla code below the patched region) —
  unchanged.
- The detection-range and detected-range aura modifiers — unchanged.
- The `RATE_CREATURE_AGGRO` multiplier — unchanged.

## Verification

The radius can be observed in-game by walking a level-mismatched
player past a creature and noting at what distance it aggros. With
B024 applied:

- Level-40 player vs level-40 creature → aggros at ~20 yards
- Level-40 player vs level-37 creature → ~20 yards (plateau)
- Level-40 player vs level-30 creature → ~14.58 yards (3 decay steps beyond plateau)
- Level-40 player vs level-20 creature → ~7 yards (13 decay steps... wait — 17 levels gap, 14 steps → 20 * 0.9^14 = 4.28, clamped to 5.0)

The asymmetry test: level-40 player vs level-50 creature should
behave the same as level-50 player vs level-40 creature (both have
|levelDiff| = 10). Under vanilla they'd be wildly different.

## Upstream

This patch is gameplay-shaping, not a bug fix. Most AzerothCore
servers want the vanilla "prey on the weak" behaviour. If
submitted upstream, it should be gated behind a config flag
(e.g. `CONFIG_CREATURE_AGGRO_LEVEL_SYMMETRIC`) so existing servers
are unaffected. The plateau width (±3) and decay rate (0.9) could
also become config knobs.

See `docs/patches/contributing-upstream.md` for the workflow if you
decide to PR it.

For our local build, no config flag is needed — the project has no
vanilla creatures whose behavior must be preserved. Every creature
in this world is part of the new design.

## Related

- `issues/210-ambush-per-player-queue.md` — the per-player target
  lock this patch complements
- `issues/126-upstream-warning-fixes.md` — patch inventory + lifecycle
- `docs/patches/contributing-upstream.md` — upstream-PR workflow
- `src/server/game/Entities/Creature/Creature.cpp::GetAttackDistance`
  — the patched function

## Follow-up

If in-game testing shows the decay is too sharp or too gentle, the
curve constants (plateau width, decay multiplier) live in the
B-patch's replacement block. Tweak there, no other code changes
needed.

## Note — Bystander-One-Shot Scenario (recorded 2026-06-01)

A related but distinct problem surfaced in discussion: a high-level
player and a low-level player standing together cause the high-level's
ambush-spawned creatures to acquire and one-shot the low-level player.
This patch helps but does not fully resolve that scenario.

What this patch changes for the scenario:

- The acquisition radius for a level-80 creature noticing a level-1
  bystander shrinks dramatically (large `|levelDiff|` puts the curve
  near the 5-yard floor). The bystander has to be very close to be
  detected at all.

What this patch does not change:

- If the low-level player IS within that 5-yard floor (e.g. standing
  next to the high-level player who just got ambushed), the creature
  still acquires them.
- Once acquired, the creature deals full level-80 damage. A single
  hit one-shots the bystander.

Possible future directions if this scenario needs a dedicated fix:

1. **Spawn-side awareness.** When the ambush system picks a creature
   level, consider the lowest-level player within some "blast radius"
   and either skip the spawn, downscale the creature's level, or
   spawn a creature whose targeting is locked to the player it was
   summoned for.
2. **Target-acquisition filter.** A `CanAcquireAsTarget` check that
   refuses targets with `|levelDiff|` beyond a threshold, regardless
   of radius. Cleanly orthogonal to this patch.
3. **Target-change damage rescale (preferred direction, 2026-06-01).**
   Whenever a creature changes targets, recompute its outgoing damage
   profile against the new target's level. **Leave the creature's
   HP totals unchanged.** The result is a creature that, when it
   shifts to a low-level bystander, deals damage appropriate to that
   bystander's level — so the bystander doesn't get one-shot — but
   remains an oversized health pool that the bystander cannot solo,
   forcing coordination and retreat.

   Implementation notes (loose):
   - Hook is target-change, not per-swing — pick the damage scaling
     once at acquisition, cache it on the creature, recompute on next
     target change.
   - Scaling formula is unspecified. Likely some function of the new
     target's level and the creature's intrinsic level. Calibrate to
     "low-level bystander takes 5-10 swings to die" so retreat is
     possible but not trivial.
   - HP pool untouched, so the high-level player can finish the
     fight in normal time once threat returns to them.

No work scheduled. Recording here so the next session that touches
aggro-or-spawn behaviour has the context.

### Reward side cross-reference

The reward distribution for the bystander scenario is already
specified by issue 801 (proportional damage rewards). Under that
system, a low-level bystander who contributes a tiny fraction of the
damage to a high-level creature receives proportional XP and
currency, gated at a 5% minimum contribution. In the typical
bystander case the contribution sits below 5% and the bystander gets
nothing for the kill itself — but they survive (thanks to the
damage rescale above) and the high-level ally's loot share grows
proportionally. The two systems compose cleanly: 142-option-3 keeps
the bystander alive, 801 routes the rewards to the carrying ally.
