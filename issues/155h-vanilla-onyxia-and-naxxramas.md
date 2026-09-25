# 155h - Vanilla Onyxia and Naxxramas

## Status
- Created: 2026-09-24
- Phase: 1
- Parent: 155
- Blocked by: 155a, 155c
- Related: 155f (the dungeon side of "same tier"), 155i (damage and healing
  multipliers, which these raids will need too), 803 (level-gap caps)
- Priority: Medium

## Origin

Verbatim, 2026-09-24:

> We want Onyxia and Naxxramas to be scaled *down*, since they are part of
> vanilla. The loot that they give should be set to the original, vanilla
> loot they had. I want the dungeon and raids to be about the same tier,
> because they require the same number of players - you can do 5 humans in
> a dungeon, or 1 human and five of their bots, so they're slightly more
> accessible than the raids, which can use minimum 5 players but up to 40
> as well.

Answers, verbatim, 2026-09-24. On the loot source: "external sources like
wowhead or similar. It's our only option for generating these loot lists."
On the Wrath-era boss scripts: "I think so? They were generally considered
to be improved right? In terms of behavior, fight difficulty and enjoyment,
etc. Let's just rescale them, it's much easier to do for now." On raid
size: "ah nuts... I guess 10 and 25 player is what we gotta do, sadly. Same
for Onyxia." On Onyxia's head quest and tier-2 helm: "Yeah!"

Context: with seven buddies each at 60 (617), five players fill a
40-person raid, so the vanilla raids are reachable content on basic.

## Current Behavior

Stock. In this client Onyxia's Lair (map 249) and Naxxramas (map 533) are
the Wrath of the Lich King versions: entry level 80, 10- and 25-person
modes, bosses level 83 with level-80-era health (Naxxramas 10-person
bosses ~0.8–6.7 million, Onyxia ~4.9 million) and melee (~9,700 per second
before armor). Their loot is item level 200/213 (Naxxramas 10/25) and
232/245 (Onyxia 10/25), required level 80.

The original level-60 items still exist in the item table but nothing
drops most of them: of the level-60 epics at item level 85, 86, 89, 90 and
92 (Naxxramas-40's weapons, armor and Atiesh), none are in any loot table.
Examples: Kingsfall 22802 (89), Might of Menethil 22798 (89), the tier-3
helms such as Dreadnaught Helmet 22418 (88), and the tier-2 helm Netherwind
Crown 16914 (76, originally Onyxia's). **Which boss dropped which item in
vanilla is not in this database**; the boss-to-item mapping has to come
from an outside source (see Open Questions).

Vanilla item levels for reference: Onyxia (original) ~71–76, about
Blackwing Lair; Naxxramas-40 83–92, above Ahn'Qiraj 40 (73–88).

## Intended Behavior

- Onyxia's Lair and Naxxramas are level-60 raids: entry at 60, in the
  client's **10- and 25-person modes** (40 cannot be restored on this
  client), bosses at the vanilla boss level (63). The **Wrath-era boss
  scripts are kept and only rescaled**: health for each mode's group size,
  damage through 155i's per-creature multipliers.
- Their loot is their original vanilla loot, taken from an outside item
  database (Wowhead or similar): each boss drops the items it dropped at
  level 60. The Wrath items are unreachable on basic. Onyxia also gets back
  the tier-2 helm drop and the Head of Onyxia quest (hand-in for the
  vanilla reward).
- Items per kill follow the Wrath version's count for each mode; tier 3
  comes back through the vanilla token-and-quest path.
- Onyxia's Lair and Naxxramas sit at about the same tier as the top Outland
  dungeons (155f).
- Boss spells were written for level-80 players (fixed damage values in the
  spell data), so they are scaled down with 155i's per-creature multipliers
  rather than by level.

## Suggested Implementation Steps

1. Choose the boss-to-item source and write the loot mapping as a
   generator input (one row per boss and item), not hand-written SQL.
2. A generator writes `sql/basic/db_world.src/NN-vanilla-raids.apply.sql`
   and its revert: saves and replaces the bosses' loot tables, sets boss
   and trash levels to 63 / 60–62, sets their health multipliers for each
   mode's group size (10 and 25), and lowers `dungeon_access_template` entry for both maps
   to 60.
3. Set 155i's per-creature multipliers for the level-80 spell damage.
4. Test on the RAM database (`scripts/test-basic-sql-in-ram`), then a
   bot raid on one boss.

## Related Issues

- **155** parent; **155a**, **155c** block this
- **155f** Outland dungeons (+4) — the same tier from the dungeon side
- **155i** per-creature damage and healing multipliers
- **617** buddy bots — why raids are reachable

## Open Questions

- (Answered 2026-09-24) Items per kill: the same count the Wrath version
  drops in each mode. Tier 3: "The vanilla token-and-quest path is probably
  fine to restore?" — restore it (tokens from bosses, turned in with
  materials at the Argent Dawn in Naxxramas).
- (Answered 2026-09-24) Loot from an outside database; Wrath scripts kept
  and rescaled; 10 and 25 person for both raids; Onyxia's head quest and
  tier-2 helm restored.
