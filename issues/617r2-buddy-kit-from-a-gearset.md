# 617r2 - Buddies Dressed from a Gearset

## Status
- Created: 2026-10-05
- Phase: 6
- Parent: 617r (gearset profiles)
- Blocked by: 617r1
- Related: 617a4 (the buddy starting kit, whose gear step this replaces)
- Priority: High

## Origin

Verbatim, 2026-10-05:

> Can we update Sargobras's buddy-bot spawning routine to use a gear
> profile? We'll need to create a translator tool that builds a profile
> from a set of specifications like we have for the current buddy-bots.
> Then, we can deprecate that old system or remove it entirely. And we can
> remove the tool once we've fully transitioned to the gear profile route.

## Current Behavior

Not built. A buddy chosen at Sargobras is made by the buddy module
(`buddies_create.cpp`), which gives its kit (`buddies_kit.cpp`): the gear
step chooses each slot live from the world database (white vendor items
of the buddy's last five levels, never required level 0 or 1, heaviest
armour first, weapons by the plan's main tree from a table `WANTS`), with
a hand-made tier for levels 20-29 (`buddies_kit_tiers.h`, generated from
the vanilla starter kit by `scripts/generate-buddy-kit-tiers`). The same
step runs when a buddy is made again at a new stage (`buddies_stage.cpp`).
Bags, food and money are given in the same kit.

## Intended Behavior

The gear comes from a gearset profile, `buddy-white`, keyed by `shape,
level` (617r1), so it can be looked at (617r5) and changed by editing one
data file:

- **The translator** (`scripts/translate-buddy-kit-to-gearset`, Lua, run
  once and again until the profile is curated by hand) applies today's
  rules offline against the world database for every class, shape and
  level bracket (one record each 5 levels from 2 to 80, the width of
  today's window), and writes `data/gearsets/buddy-white.lua`. It adds
  the owner's wish: within a slot's candidates, the item whose stats
  best fit the shape (each tree's role weighted by its thirds: healer
  trees value spell power, intellect, spirit; tank trees stamina, armour,
  defence, dodge, parry; physical damage trees strength, agility,
  attack power; caster damage trees spell power, intellect) wins before
  item level. Only items every race of the class can use are chosen, so
  the profile needs no race key.
- **Profiles into the database**: `scripts/generate-gearset-sql` writes
  every profile as rows of a world-database table `gearset_item`
  (profile, key1, key2, key3, slot, item, amount), installed by an E
  step, so the buddy module (C++) reads the same profiles the Lua
  command does.
- **The buddy module**: the gear step reads `buddy-white` rows for the
  buddy's class, shape and level bracket and equips them (bags, food and
  money unchanged). The live chooser (`GiveGear`, `WANTS`), the tier
  header and its generator are removed. A missing record is logged as a
  problem, never filled with something close.
- When the profile is curated and the owner is happy, the translator is
  removed (it stays in history).

## Suggested Implementation Steps

1. The translator: the same candidate query and sort as `GiveGear`,
   stat weights per shape, writing records per class, shape and bracket.
2. A test: every record's items exist, fit, suit the class, are white
   and sold by a vendor; every class, shape and bracket has a record.
3. `generate-gearset-sql` and the E step for `gearset_item`.
4. The buddy module's gear step reads the table (a source patch-free
   change: the module is ours); remove `GiveGear`, `WANTS`, the tiers.
5. Rebuild (owner), make a buddy at Sargobras, inspect.

## Open Questions

1. The level-20 tier came from the vanilla starter kit by race. With no
   race key, should `buddy-white`'s level-20 records keep the starter
   kit's look (class-wide, the first race's pick), or follow the rules?
