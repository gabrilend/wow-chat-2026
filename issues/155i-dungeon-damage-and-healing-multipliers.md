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

Nothing like this exists on basic. Creature health and melee damage follow
the creature's level and its template's health and damage multipliers;
creature **spell** damage comes from the spell's own data and mostly does
not follow level, so raising levels (155f) barely changes it.

The server already has the hooks: its unit-script interface
(`UnitScript.h`) is called for every melee hit, every direct spell hit,
every damage-over-time tick and every heal, with the amount passed by
reference so a script can change it:

- a melee hook (`ModifyMeleeDamage`)
- a spell damage hook (`ModifySpellDamageTaken`)
- a periodic damage hook (`ModifyPeriodicDamageAurasTick`)
- a healing hook (`ModifyHealReceived`)

Basic's compiled rules file (`src/cpp-basic/basic_rules.cpp`, copied in by
B030) is where such a script lives. The upstream module mod-zone-difficulty
does this kind of per-map scaling (it is not cloned here, and its current
table layout has not been checked).

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
