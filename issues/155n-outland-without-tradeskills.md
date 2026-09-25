# 155n - Outland Without Tradeskills

## Status
- Created: 2026-09-24
- Phase: 1
- Parent: 155
- Blocked by: 155a, 155c
- Related: 155l (Outland without quests), 155k (Outland gear)
- Priority: Medium

## Origin

Verbatim, 2026-09-24:

> Can we also remove all tradeskills from Outland? No herbs, mining nodes,
> etc. Also, no profession trainers will train the Outland profession
> skills. This will encoura-force players to still spend some time in
> Azeroth for materials. Later, we should take a pass at the ilevel design
> of profession created equipment and such...

Answers, verbatim, 2026-09-24:

> we can keep fishing pools, actually, I think. Any edge case concerns with
> that? Maybe we could keep cooking as well... What do you think?

> gas clouds, yes. skinning, yes. netherweave cloth, no, but tailors can't
> make it into anything, so effectively yes. elemental motes can remain as
> vendor trash. I hate calling them trash. Maybe we can make a repeatable
> quest later on that the players can exchange them for something...?

> [recipes above 300 from drops and vendors:] remove them.

> keep it up to 300, same as other professions. We should remove
> inscription though. Actually, let's remove the glyphs from inscription,
> and just make it a buff-scroll creation profession. (155o)

## Current Behavior

**Built 2026-09-24** as install step E027,
`sql/basic/db_world.src/12-outland-without-tradeskills.apply.sql` (+ revert),
with its client-data lists written by
`scripts/generate-basic-outland-tradeskills-sql` (herb and ore locks from
Lock.dbc: 83; named areas inside Outland's zones, Shattrath and the Isle
from AreaTable.dbc: 348; Master and Grand Master rank spells from Spell.dbc
by name: 46). "Outland" by position: map 530 with y > -2000 (north of the
elf and draenei isles) or x > 11350 (the Isle), plus the Outland instance
maps and Magisters' Terrace. What it does, each removal saved first:

1. herb and ore spawns (by lock) and fishing pools there are removed, with
   their addon, event and pool rows;
2. gas clouds (Swamp Gas, Felmist, Arcane Vortex, Windy Cloud) there are
   removed;
3. pools left with no member are removed (two passes, for a mother pool
   emptied by its children), because the server reports an empty pool as
   broken;
4. templates spawned only in Outland lose their skinning loot, and so do the
   gas clouds;
5. every Outland zone (and Shattrath, the Isle) needs fishing skill 300,
   rows added where a zone had none; fishing loot filed under a sub-area is
   removed, so the zone's own loot applies there;
6. trainer rows needing more than 300 in any profession, and every Master /
   Grand Master rank, are removed;
7. recipes needing more than 300 are removed from every loot table and
   every vendor.

The revert re-inserts every saved row and restores skinning and fishing
skill. Tested in `scripts/test-basic-sql-in-ram` with the exact-revert
checksum over the tables it touches; `scripts/validate-basic-state` checks
the seven results.

Stock numbers, for reference. Read from the world database, 2026-09-24 (Outland part of its map:
everything north of the elf and draenei isles, plus the Isle of
Quel'Danas):

- **Gathering nodes** (spawn points; many share a pool, so fewer are up at
  once): mining — Khorium Vein 1,130, Fel Iron Deposit 599, Adamantite
  Deposit 531, Rich Adamantite Deposit 349, Nethercite Deposit 32; herbs —
  Felweed 487, Dreaming Glory 317, Flame Cap 130, Ragveil 130, Terocone
  108, Nightmare Vine 106, Netherbloom 91, Netherdust Bush 86, Glowcap 57,
  Mana Thistle 29.
- **Fishing pools**: 453 spawn points.
- **Trainers**: 562 recipe and rank rows needing skill 301–375 across 43
  trainers (Master rank and the recipes that go with it).
- Other Outland materials that aren't nodes: leather from skinning Outland
  beasts, Netherweave Cloth from humanoids, Motes from elementals, and gas
  clouds for engineers (see Open Questions).

## Intended Behavior

- **No gathering nodes in Outland**: every herb and mining node spawn in
  Outland (and on the Isle) is removed. Treasure chests stay (they are not
  nodes).
- **No gas clouds, no skinning of Outland creatures** (their skinning
  loot is cleared). Netherweave Cloth still drops but nothing uses it
  (tailoring stops at 300). Motes still drop, sold to vendors for now; a
  repeatable exchange for them is an idea for later.
- **No Outland profession training**: no trainer teaches the Outland
  ranks and recipes (skill above 300), anywhere, and recipes above 300 are
  removed from creature loot and vendors too. Professions top out at
  Artisan (300) on basic, whose materials all come from Azeroth.
  Jewelcrafting stays, to 300 like the rest.
- **Fishing in Outland needs exactly 300 everywhere; no pools, no special
  spots** (Ritz, 2026-09-24: "let's say fishing in Outland always requires
  level 300. The increasing zone difficulty is what makes it more or less
  valuable to fish in certain spots. We should also remove all pools and
  special fishing zones."): every Outland zone's fishing skill is set to
  300, all 453 fishing-pool spawns are removed (this reverses "pools
  stay"), and sub-zones with their own fishing loot fall back to their
  zone's.
- **Fishing, cooking and First Aid stop
  at 300 like every profession** (Ritz, 2026-09-24: "Hmmmmmmmmmmmmmmmm I
  think no. Let outland meat and cloth be vendor goods."). So **Outland's
  fishing skill levels are set to 300** ("we will need to adjust these
  numbers"; see above). Stock, for
  reference: each zone has a
  fishing skill below which most casts come up empty (from the database:
  Hellfire Peninsula and Shadowmoon Valley 280, Zangarmarsh 305, Terokkar
  Forest and the Isle 355, Nagrand and Netherstorm 380). At 300, only the
  first two zones' pools would be worth fishing. Cooking the Outland fish
  and meat also needs skill above 300. Trainer rows above 300 (removed with
  the rest): 20 cooking, 4 First Aid, 1 fishing. For reference, what the
  cap gives up:
  - **Food** (one "well fed" buff at a time): the best Azeroth foods give
    +25 Stamina (Dirge's Kickin' Chimaerok Chops), +20 Strength (Smoked
    Desert Dumplings), +12 Stamina and Spirit (Monster Omelet), +10
    Agility, +10 Intellect or +10 mana per 5 seconds. Outland foods give
    two stats: +30 Stamina and +20 Spirit (Fisherman's Feast, Spicy
    Crawdad); +20 Agility and +20 Spirit (Warp Burger, Grilled Mudfish);
    +20 Strength and +20 Spirit (Roasted Clefthoof); +23 spell power and
    +20 Spirit (Blackened Basilisk, Golden Fish Sticks); +20 hit rating and
    +20 Spirit (Spicy Hot Talbuk); +20 crit rating and +20 Spirit
    (Skullfish Soup). Roughly twice Azeroth's best. The rating foods convert
    at level 60's rate: +20 hit rating is 2% hit at 60, about 1.3% at 70.
  - **Bandages** (First Aid, healing over 8 seconds): Runecloth 1,360,
    Heavy Runecloth 2,000 (the best at 300), Netherweave 2,800, Heavy
    Netherweave 3,400.
- Players still visit Azeroth for materials ("encoura-force").
- **Later**: an item-level pass on crafted equipment, to fit it into the
  gear ladder (155f, 155k).

## Suggested Implementation Steps

1. A generator lists Outland node spawns (gameobject spawns of herb and
   ore templates, found by their lock's required skill rather than by
   name) and pool entries, and writes apply/revert SQL that saves and
   deletes them.
2. The same generator saves and deletes trainer rows whose required skill
   is above 300 (all trainers), and Master-rank learning spells.
3. Test on the RAM database: no Outland node spawns remain; a level-60
   Artisan finds no trainer offering Master.

## Related Issues

- **155** parent; **155l** Outland without quests; **155k** gear ladder

## Open Questions

- (Answered 2026-09-24) Outland fishing: 300 in every zone; pools and
  special spots removed.
- (Answered 2026-09-24) Fishing, cooking and First Aid capped at 300;
  Outland meat, fish and cloth are vendor goods.
- (Answered 2026-09-24) Gas clouds and skinning removed; Netherweave Cloth
  stays but unusable; motes stay (vendor); recipes above 300 removed from
  drops and vendors; Jewelcrafting to 300; Inscription loses its glyphs
  (155o).
