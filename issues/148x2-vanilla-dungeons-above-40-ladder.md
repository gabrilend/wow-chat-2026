# 148x2 - Vanilla: the Dungeons Above 40, on a Ladder

## Status
- Created: 2026-10-27
- Phase: 1
- Parent: 148x
- Blocked by: 148x1
- Related: 155f (basic's Outland dungeon ladder: the step and its tool),
  155i (per-dungeon multipliers)
- Priority: Medium
- State: plan only

## Current Behavior

Stock: Zul'Farrak (about 44-54), Maraudon, the Sunken Temple, Blackrock
Depths, Lower and Upper Blackrock Spire, Dire Maul, Stratholme and
Scholomance (up to 60, bosses to 62) need levels above 40 to enter some of
them and to win any.

## Intended Behavior

- **Every dungeon above 40 opens at 40** (the dungeon-access table), with
  any level-gated attunement lowered to match; keys that are items (the
  Scholomance key, the Seal of Ascension) stay keys.
- **A ladder, in the order a player meets them**: each dungeon a little
  above the last in creature level and loot budget, as basic's Outland
  dungeons step (155f), on the creature levels of 148x1's mapping.
- **Their loot is 148x3's scaled gear**, so the ladder's rungs show in
  the gear.
- **Made by basic's dungeon ladder tool**, given vanilla's dungeons and
  range.

## Suggested Implementation Steps

1. The ladder tool takes its list of dungeons and the target levels as
   settings.
2. Vanilla's ladder written out as a table for the owner to confirm (as
   155f's was), then its SQL as an install step gated on `vanilla`.
3. A quick test: every dungeon above 40 enterable at 40, and each rung's
   bosses at or above the one before.

## Open Questions

1. The order of the rungs: by stock level (Zul'Farrak first, Scholomance
   and Stratholme last), or does the owner want a different order?
