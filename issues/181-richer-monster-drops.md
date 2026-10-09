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

## Current Behavior

Not built. Basic drops at stock rates (`Rate.Drop.Item.Uncommon`,
`.Rare`, `.Epic` and the rest all 1 in `worldserver.conf`). Those settings
scale every creature's loot alike, dungeon bosses included.

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

1. **Epic x5 from what:** ordinary monsters only (world-drop epics, few
   and rare), or bosses too (which would make raid and dungeon epics five
   times as common)?
2. **"Double the amount" for rares:** two rolls of their whole loot (two
   chances at each item), or the items that drop doubled (every drop
   comes in twos)?
3. **What counts as a boss:** the creature's rank "boss" (raid bosses and
   the world bosses), or also every dungeon boss (most are elite, not
   rank boss; the server marks them by their instance encounter)?
