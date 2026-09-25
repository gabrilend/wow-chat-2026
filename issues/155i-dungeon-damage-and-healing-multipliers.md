# 155i - Dungeon Damage and Healing Multipliers

## Status
- Created: 2026-09-24
- Phase: 1
- Parent: 155
- Blocked by: 155a
- Blocks: 155h (its level-80 spells are scaled with this)
- Related: 155f, 803
- Priority: Medium

## Origin

Verbatim, 2026-09-24, on what +4 levels should change:

> Ideally, it'd only change health and damage. Armor might scale weirdly,
> but I'm open to it. We should also consider resistances and such.
> Question, can we modify the damage or healing or whatever that the boss
> and creature spells do? If so, that helps a lot.

Answers, verbatim, 2026-09-24: per dungeon or per creature — "Per
creature." Whether healing multipliers also cover creatures healing
themselves — "... yes?"

## Current Behavior

**Built 2026-09-24; not yet compiled** (Ritz runs the compile).

- **Table**: `basic_creature_multipliers` in the world database, created by
  install step E026 from `sql/basic/db_world.src/11-creature-multipliers.apply.sql`
  (revert drops it). Columns: `entry` (creature template, or 0 for a map
  row), `map_id` (for a map row), `melee`, `spell`, `heal`, `health`
  (floats, 1 = stock), `comment` (who and why). Starts empty.
- **Code**: in `src/cpp-basic/basic_rules.cpp` (copied into the server by
  B030):
  - loads the table at startup (the world's custom-table hook) and on
    `.basic reload multipliers` (reload permission); a missing table is
    logged as an error ("install step E026 not run?"), an empty one as
    "every creature stock";
  - picks a unit's row: its own template's row, else its creature owner's
    (adds and pets), else its map's; players and anything a player
    controls never;
  - melee hook (after the attacker's bonuses, before armor) × `melee`;
    direct spell damage × `spell`; damage-over-time ticks × `spell`,
    skipping positive spells, because the server also sends heal-over-time
    ticks through that hook; healing × `heal` when either the healer or the
    healed has a row (the server's two heal call sites pass the two units
    in opposite orders);
  - health × `health` at the end of level selection (spawn, respawn), from
    creature rows only: the creature's map isn't reliably known at that
    moment, so a map row's health is ignored (said in the SQL header).
- **Tests**: `scripts/test-basic-sql-in-ram` applies and reverts the table
  with the rest of basic's SQL; `scripts/validate-basic-state` checks the
  table and its six value columns exist; `scripts/test-source-patches`
  still round-trips all basic source patches. Nothing exercises the C++
  until the compile; after it, a row for a Ramparts trash creature with
  `melee = 2` should double its hits in the combat log.

## Intended Behavior

- A world-database table maps a **creature template** (and, as a
  convenience, a whole map) to four multipliers: its melee damage, its
  spell damage (direct and over time), healing it does or receives (so a
  boss healing itself is scaled too), and its health (applied at spawn). A
  creature row wins over its map's row. Missing = no change.
- The script reads the table at startup and on a reload command, and
  applies the multipliers when the damage or healing source is a listed
  creature (or its pet or summon), or a creature in a listed map. Players' damage is untouched.
- The table rows are generated from a source file per dungeon, and every
  change of a value is logged in `docs/balance-updates.md` with its reason.

## Suggested Implementation Steps

1. Table schema and its generator (basic's SQL source folder, with a revert).
2. A unit script in basic's rules file: load the table into two lookups (by
   creature template, then by map); in each hook, look up the attacker's (or
   its owner's) template, falling back to its map, and
   multiply.
3. Tests: a creature in a listed map hits for the multiplied amount; in an
   unlisted map, unchanged; a player's own damage unchanged.
4. First values: all 1.0 for the 155f dungeons until the bot-party test
   in Hellfire Ramparts; 155h's values from its spell damage survey.

## Related Issues

- **155** parent; **155a** blocks this
- **155f** the +4 Outland dungeons — the main user
- **155h** Onyxia and Naxxramas at 60 — needs the spell multiplier to
  bring level-80 spells down
- **803** the level-gap caps — the other half of "+4 changes only health
  and damage"

## Open Questions

- (Answered 2026-09-24) Spells can be patched: damage and healing through
  these hooks; any other spell property (duration, radius, cooldown, cast
  time) through the server's spell-corrections file
  (`SpellInfoCorrections.cpp`, 700+ existing fixes in the same shape), as a
  source patch on basic.
- (Answered 2026-09-24) Players' healing is not scaled: "No, the healing
  can be left as normal."
- (Answered 2026-09-24) Per creature. Creatures healing themselves are
  scaled too.
