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

**Two fixes, 2026-10-15; generated and syntax-checked, not yet rebuilt,
installed (E052) or run.**
- The kit asks whether the buddy can use an item before it destroys
  what that slot held. Before, a refused weapon left empty hands, and the
  bot module then equipped the only weapon in its bags, its fishing pole
  (Montahmu, fighting Uldaman with one). A refusal now keeps the old item
  and names the server's reason number in the log line.
- The translator now takes weapons from required level 1 (armour still
  from 2): the starter weapons (Short Staff, Dirk, Shortsword) need level
  1, and without them 23 level 2-9 records (mages, warlocks, feral
  druids) had no weapon at all. A first try at "everything from 0" put
  holiday mantles, jewellers' rings and romance goggles on every buddy,
  so armour stays at 2. Every record now has a main hand. The re-run also
  picked up items whose required level had changed in the world database
  since 2026-10-05 (Cuirboulli Gloves now need 22, not 20), which the old
  records would have had refused.

**Built 2026-10-05; module syntax-checked against the build's own
compile commands; not yet rebuilt or run.** Needs the owner's rebuild
(the buddy module changed) and an install (E052).

- **One profile per ten-level tier** (owner, 2026-10-05: "We should
  call it buddy-white-20 because we're going to have one for each level
  tier"): `buddy-white-1` (levels 2-9), `buddy-white-10`, `-20` ... `-60`,
  each keyed shape then level (a record each five levels inside the tier).
  The buddy module picks the profile by the buddy's tier.
- `scripts/translate-buddy-kit-to-gearset` (Lua) applies the old rules
  offline and writes the seven `src/lua-basic/data/gearsets/buddy-white-*.lua`:
  1300 records (10 classes x 10 shapes x 13 level brackets: 2, 5, 10 ... 60),
  from the 266 white vendor armour and weapon items between required
  levels 2 and 60, in a third of a second. Items are scored by the bot
  module's own per-tree stat weights (`acore_playerbots_basic.
  playerbots_weightscale*`), weighted by the shape's thirds. None of the
  266 carries a stat, so today the score sees armour and weapon damage
  only; the shape's weights matter once a record names better items.
- `scripts/generate-gearset-sql` writes every profile into
  `sql/basic/db_world.src/33-gearsets.apply.sql` (tables
  `gearset_profile`, `gearset_item`; 11150 rows), install step E052.
- The buddy module (`buddies_kit.cpp`): the gear step reads the
  buddy's `buddy-white` record (class x 100 + shape, the highest level at
  or below its own) and equips it; a missing record is logged in full.
  The live chooser (`WANTS`, the candidate sort) is gone; `.buddy kit`
  re-kits from the profile by the buddy's shape. Creation and the
  stage remake pass the roster's shape.
- **Retired 2026-10-05**: `buddies_kit_tiers.h`, `scripts/generate-buddy-kit-tiers`
  and E048's apply form. E048 now applies its own revert on every
  install: the 46 starter items get their own required levels back (a
  database it never touched is left alone). Copies of those items without
  a level requirement (the owner asked) aren't needed now; they are
  possible: a new item number isn't in the original client's own item
  table (`Item.dbc`, 46096 items, checked 2026-10-05), so a worn copy is
  drawn as nothing only until the client has asked the server about it
  (148v); issue 175 plans to tell the client ahead of time. Once every
  database has had an install, E048 leaves the list.
- What the old rules can't give, the profile doesn't have either: no
  white cloak is sold anywhere (so no cloak in any record), and level 40
  plate classes wear level-32 mail until plate appears at 45. Both are
  for hand curation (617r5).
- Checked by `scripts/test-gearsets`: every class and shape has records
  from level 2; every item white, sold, wearable at its record's level,
  fitting, suiting the class; the E052 SQL equals what the profiles make.

Before this: a buddy chosen at Sargobras is made by the buddy module
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

1. (Answered 2026-10-05) "the rules were just there to throw together a
   programmatically gathered gear list. We're going to curate them all
   eventually." The level-20 records follow the rules like the rest.
2. Gems are not in gearsets (owner, 2026-10-05): see 617r6.
