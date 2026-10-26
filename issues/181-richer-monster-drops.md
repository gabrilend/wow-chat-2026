# 181 - Richer Monster Drops

## Status
- Created: 2026-10-08
- Phase: 1
- Profile: basic
- Related: 178 (experience by kills), 180 (no quests: quest reward gear
  gone), 182 (legendary items), 155p (white gear, sockets)
- Priority: Medium

## Origin

The owner, 2026-10-08:

> can we double the drop-rate of green and blue gear from monsters,
> untouched from things like dungeon bosses. Rares have the same
> percentage chance, but double the amount. Also can we 5x the drop rate
> of epic items?

### Decisions, 2026-10-08 (owner)

- **Epics x5 from ordinary monsters only**: "From raid bosses it's
  guaranteed" (they already drop an epic every kill).
- **Rares**: "rare monsters have their loot doubled. Not elites. But, rare
  elites, yes." Creatures of rank rare and rare elite; plain elites keep
  stock loot.

## Current Behavior

**Built 2026-10-25, not yet compiled** (the owner runs the compile):
- **The rule**, in basic's rules code (`src/cpp-basic/basic_rules.cpp`,
  "Richer monster drops", copied in by B030), through two of the
  server's loot hooks: the roll hook (each loot entry's chance, as it is
  rolled; the loot knows its creature) and the reference-count hook (how
  many times a shared table is processed). Whose loot it is: a creature's
  own loot only; bosses stock (every creature a dungeon's or raid's
  encounter list credits, world bosses by rank or type flag); rares by
  rank (rare, rare elite); everything else ordinary, elites included.
- **Where the chances live**: a monster's table points at a level band's
  table; a band points, each with its own chance, at tables of one quality
  ("Vanilla Greens 36-40", "... Blues ...", "... Purples ..."). The
  multiplier goes on the entry pointing at a one-quality table (greens and
  blues x2, epics x5 for ordinary monsters), or on a plain item by its own
  quality; a band pointing at a mixed table is left alone, so nothing is
  multiplied twice.
- **Rares**: the bands their own table points at are processed twice
  (only those: 79 bands sit inside other tables, none of the 354 creatures
  use directly, so it doubles once), and a plain item with its own chance
  outside a group gets two tries. (The group-amount hook was tried first;
  the server repeats a group only when it lands on a plain item.)
- **Settings**: `Basic.Drops.GreenBlueRate = 2`, `Basic.Drops.EpicRate =
  5`, `Basic.Drops.RareRolls = 2`, written by config patch C040 (basic
  only); missing settings are logged as an error and drops stay stock.
- **Tests**: `scripts/test-basic-drop-layout` checks the table layout the
  rule relies on (no band creatures use is inside another; bands point at
  one-quality tables; greens, blues and epics have such tables);
  `scripts/test-patched-syntax basic` compiles the rule; the settings
  checks pass. Not yet seen in game: kill counts against the multipliers.
- **Mixed tables split, 2026-10-26 (install step E073, not yet
  installed)**, as the owner chose (open question 4):
  `scripts/generate-basic-split-loot-sql` splits each stock shared table
  that mixes qualities under one equal chance into one table per quality
  (new tables 1840000 and up, the same items), and every loot entry that
  pointed at it now points at the new ones with its chance shared out by
  each quality's count, in one group, so unboosted the drops are exactly
  as before. In the world now: 42 tables into 88, 1,604 loot entries
  rewritten (each saved first, `basic_181_split_parents`, for an exact
  revert). Left as they are: 9 mixed tables whose items carry their own
  chances (the roll rule already reaches those item by item), 21 of
  several groups or with nested tables, and the project's own tables
  (Onyxia's hoard mixes on purpose, 155h). The RAM test applies,
  re-applies and reverts it; `scripts/validate-basic-state` checks the
  new tables are one quality each and nothing points at a split table.

## Intended Behavior

- **Ordinary monsters drop green and blue gear twice as often.** Bosses
  (dungeon and raid bosses) keep their stock chances.
- **Rare monsters** (the named rares, rank "rare" and "rare elite") keep
  the same chances but drop twice as much: each of their drops rolled
  twice, or every item they drop doubled (open question 2).
- **Epic items five times as often** (open question 1: from which
  monsters).

Why: with quests gone from players (180), quest reward gear is gone too;
more gear from the monsters players fight, above their level by choice
(178), makes up for it, without making bosses' loot common.

## Suggested Implementation Steps

1. A source patch in the loot roll (`LootMgr`, where a loot item's chance
   is multiplied by its quality's rate), gated to basic by a setting: the
   doubled green and blue rates applied only when the looted creature is
   not a boss; rares' loot rolled twice.
2. Config values for the multipliers (2 for green and blue, 5 for epic,
   2 for rares' rolls), written by a basic-only config patch, so they are
   tuned without a rebuild (`docs/balance-updates.md` records each change).
3. A test: loot rolled many times for a normal monster, a rare and a
   boss on a RAM copy of the loot tables, the counts against the
   multipliers.

## Open Questions

1. (Answered 2026-10-08: ordinary monsters only) **Epic x5 from what:** ordinary monsters only (world-drop epics, few
   and rare), or bosses too (which would make raid and dungeon epics five
   times as common)?
2. (Answered 2026-10-08: (a), their whole loot rolled twice) **"Double the amount" for rares:** two rolls of their whole loot (two
   chances at each item), or the items that drop doubled (every drop
   comes in twos)?
3. (Answered 2026-10-23: the dungeon bosses, whatever their rank) "elites and rare elites. Dungeon bosses. The elites in dungeons that aren't bosses should have the updated rates." So a boss is a creature on a dungeon's or raid's list of encounters (most are ranked "elite" or "rare elite" in the data, a few "boss"), plus the rank-"boss" world bosses; they keep stock chances. Every other elite, the trash inside dungeons included, gets the doubled green and blue and the fivefold epic chances. **What counts as a boss:** the creature's rank "boss" (raid bosses and
   the world bosses), or also every dungeon boss (most are elite, not
   rank boss; the server marks them by their instance encounter)?
4. (Answered 2026-10-26: split them) "have a generator split each into
   one table per quality, so their greens are boosted like the rest."
   **The mixed tables**: 106 shared loot tables (98 below level 58) hold
   whites and greens (or blues, or epics) together, sharing one chance
   equally, so their greens are not made likelier. Leave them, make the
   whole table likelier (its whites too), or split each into one table per
   quality with a generator (the greens' share then multiplied like the
   rest)?
