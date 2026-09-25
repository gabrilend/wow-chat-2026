# 155q - Level 61–80 Ability Tomes from Azeroth

## Status
- Created: 2026-09-25
- Phase: 1
- Parent: 155
- Related: 155h (Naxxramas at 60, where the Wrath-era tomes drop), 405
  (ability tome system, another profile's rank-agnostic tomes; the
  mechanism to reuse), 156 (expert, 61–80, where these abilities are
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
60 from tomes that drop: progression past the level cap through what a
character finds.

**Tomes drop only in Azeroth** (Ritz, 2026-09-25, replacing the note's
Outland mobs): "can we make tomes only drop from Azeroth? We should treat
Outland as alien and strange, and Azeroth is where we go to focus our
strength. It's fitting I think that the WotLK tomes would then be dropping
from Naxxramas." So the Wrath-era abilities' tomes drop from Naxxramas (at
60 on basic, 155h). (The file keeps its name, `155q-outland-ability-tomes`,
so links to it stay valid.)

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
  existing unused tome items to reuse? (405 read 2026-09-25: no AIO; its
  Inscription recipes would be new spells the client doesn't know, which
  needs a client patch, but tomes that drop, as here, skip recipes
  entirely. Using a tome needs an on-use spell the client knows, then the
  server's Lua teaches the next rank.)
- (Answered 2026-09-25) Where: Azeroth only; the Wrath-era tomes from
  Naxxramas. Still open: do Burning Crusade–era abilities (the 61–70
  ones) drop from somewhere else in Azeroth, and how rare are they?
- Balance: higher ranks are sized for levels 61–80; do they need scaling
  down on basic (see 715, linear ability scaling)?
- Death knights are allowed on basic with limits (148a); do they get tomes
  too?
