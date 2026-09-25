# 155q - Outland Ability Tomes

## Status
- Created: 2026-09-25
- Phase: 1
- Parent: 155
- Related: 405 (ability tome system, another profile's rank-agnostic tomes;
  the mechanism to reuse), 155f / 155k (the high-level Outland creatures
  that would drop them), 156 (expert, 61–80, where these abilities are
  ordinary)
- Priority: Low (an idea, not designed)

## Origin

Verbatim, a note left in the project root (`new-issue-please-sort`,
2026-09-24):

> for the basic profile, I was wondering, if we made class abilities that
> required between levels 61 and 80 learnable from tomes? I think there's
> issue files for a different profile for tomes for each ability. Then, we
> could make them drop from high level Outland mobs. Just a thought,
> continuing progression...

## Current Behavior

Basic stops at level 60, so its characters never learn anything a trainer
teaches from 61 to 80. That is about 800 trainer entries across the classes
(new abilities and higher ranks of known ones), read 2026-09-25 from the
stock trainer tables:

| Class | Warrior | Paladin | Hunter | Rogue | Priest | Death knight | Shaman | Mage | Warlock | Druid |
|---|---|---|---|---|---|---|---|---|---|---|
| Entries at 61–80 | 48 | 64 | 60 | 42 | 91 | 65 | 113 | 107 | 98 | 107 |

Issue 405 already designs rank-agnostic tomes for another profile: one
"Tome of Rejuvenation" teaches whichever rank the reader may learn next.

## Intended Behavior

Level 61–80 class abilities (new ones and higher ranks) become learnable at
60 from tomes that drop, rarely, from basic's high-level Outland creatures:
progression past the level cap through what a character finds.

## Suggested Implementation Steps

1. Answer the open questions below with Ritz.
2. Reuse 405's tome mechanism (a Lua use-handler that teaches the next rank
   of a spell family) rather than one item per rank.
3. A generator lists each class's 61–80 trainer entries by spell family and
   writes the tome drop tables.
4. Test on the RAM database; then in game, a level-60 reading a tome.

## Open Questions

- Which abilities: every 61–80 entry, only new abilities, or only higher
  ranks of what a level 60 already knows?
- Where the tome items come from: 405's tomes are new items, which the
  client may show wrongly (no entry in its own item file); are there
  existing unused tome items to reuse?
- Drop sources and rates: which Outland creatures (the upper zones, the
  upper dungeons, bosses), and how rare?
- Balance: higher ranks are sized for levels 61–80; do they need scaling
  down on basic (see 715, linear ability scaling)?
- Death knights are allowed on basic with limits (148a); do they get tomes
  too?
