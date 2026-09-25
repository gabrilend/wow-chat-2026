# 155k - Outland World Gear Ladder

## Status
- Created: 2026-09-24
- Phase: 1
- Parent: 155
- Blocked by: 155a, 155c
- Related: 155f (dungeon tiers), 155h (raid tiers), 155j (Kazzak, Fel
  Reaver)
- Priority: Medium

## Origin

Verbatim, 2026-09-24:

> We should adjust the green item levels to be roughly appropriate. The
> highest level Outland zones like Netherstorm for example should have mobs
> that are more difficult than for example Zangarmarsh or Hellfire
> Penninsula. So they should have better equipment drops. The highest tier
> Outland zones should drop gear that's roughly equivalent to... Which tier
> of dungeon/raid? Can you chart the three gear sources (Vanilla raids,
> Outland dungeons, and Outland world farming) alongside one another so we
> can gauge where to align each tier?

The chart: the "Level-60 Gear Ladder" artifact published 2026-09-24
(https://claude.ai/artifact/MZ1mumH84gVxVicSnskvD8), built from the queries
below.

Answers, verbatim, 2026-09-24:

> world blues should be roughly the same as dungeon blues. But, if you find
> a world blue in Hellfire Penninsula for example, it should match Ramps
> blues in ilevel. I think it will be very difficult to kill / farm high
> level world monsters, so finding blues and such (essentially raid gear
> quality, and the best raids too...

> The Outland world dungeons should match the progression of blues from
> dungeons, with the most powerful blues being about as valuable as AQ40
> gear, and the least powerful as AQ20 gear.

(Read as: the open world's blues follow the dungeons' ladder zone by zone,
from Ahn'Qiraj 20 in Hellfire Peninsula to Ahn'Qiraj 40 at the top.)

> All of it should become wearable at level 60. Quest rewards, well, we
> should remove all quests in Outland. Not questgivers, but quests. (155l)

## Current Behavior

Stock. Outland's open world keeps its stock creature levels (155f) and its
stock loot. Its gear mostly requires levels 61–70, so a level 60 on basic
can wear almost none of it (8 blues of item level 82–85 from level-61/62
creatures are the exception).

**The stock loot already ramps by zone.** For each normal creature (level
58+) in a zone, the average item level of the greens and blues its loot
table can give; the middle half across the zone's creatures (zones from
the client's map bounds, WorldMapArea.dbc):

| Zone | Typical creature levels | Greens (ilvl) | Blues, rare (ilvl) | Greens ≈ epic | Blues ≈ epic |
|---|---|---|---|---|---|
| Hellfire Peninsula | 59–62 | 84–92 | 88–91 | 53–58 | 71–74 |
| Zangarmarsh | 62–63 | 92–95 | 91–97 | 58–60 | 74–79 |
| Terokkar Forest | 64–67 | 95–104 | 97–106 | 60–66 | 79–86 |
| Nagrand | 65–67 | 98–105 | 100–108 | 62–67 | 81–88 |
| Blade's Edge | 66–68 | 102–107 | 105–109 | 65–68 | 85–88 |
| Netherstorm | 68–69 | 108–111 | 111–112 | 69–71 | 90–91 |
| Shadowmoon Valley | 69–70 | 110–114 | 111–114 | 70–73 | 90–92 |
| Isle of Quel'Danas | 69–70 | 114–116 | 114 | 73–74 | 92 |

"Typical creature levels" is the middle half of the zone's hostile, lootable
creature spawns (Ritz, 2026-09-24: the full range misleads, "in every zone
there's a lot of level 70 monsters, but those aren't really the 'intended'
monster ranges"). Full ranges, for reference, run up to 71–73 everywhere
(Skettis in Terokkar, Ogri'la in Blade's Edge and similar corners). Under
the +4 (+6 on the Isle) these become 63–66, 66–67, 68–71, 69–71, 70–72,
72–73, 73–74 and 75–76.

"≈ epic" is the stat-budget conversion (green ≈ (ilvl − 4) ÷ 2, blue ≈
(ilvl − 1.84) ÷ 1.6, epic ≈ (ilvl − 1.3) ÷ 1.3, expressed as an epic's item
level). Every zone can also drop the item-level-100 rare world epics.

**Isle of Quel'Danas** (asked 2026-09-24): Burning Crusade content on the
Eastern Kingdoms side of the same map. In this database its spawns do not
shuffle: 1,001 of its 1,004 creature spawns are in the default phase (the
live game's Sun's Reach phases changed vendors and NPCs; the daily quests
rotate, the mobs don't). Its fighting creatures are normal (not elite)
blood elves, demons and naga of level 69–71, about 5,400–7,200 health and
110–210 melee per second, much like Netherstorm's and Shadowmoon's (plus
level-60 Greengill Slaves). Its loot sits at the top of the open world:
greens just above Shadowmoon Valley's, blues at 114.

So: top-zone **greens** sit at about Molten Core / Zul'Gurub / Onyxia
epics; top-zone **blues** (rare drops) sit at about Naxxramas-40. Ratings
on all of it are ~1.6× stronger at level 60 (see 155f).

## Intended Behavior

- **Outland's hostile creatures are +4 levels too** (Ritz, 2026-09-24:
  "I think we might need to give all the monsters in Outland a +4 level
  bonus, because a level 58 normal mob dropping raid gear semi-rarely
  is... too powerful."). This reverses 155f's "open world stays stock" for
  Outland's hostile creatures. Zones' typical creature levels become:
  Hellfire Peninsula 63–66, Zangarmarsh 66–67, Terokkar Forest 68–71,
  Nagrand 69–71, Blade's Edge 70–72, Netherstorm 72–73, Shadowmoon Valley
  73–74 (+4), and the Isle of Quel'Danas 75–76 (+6, the top zone). Loot tables don't change
  (they belong to the creature, not its level). Friendly NPCs are not
  raised. With 155f's dungeon templates also raised, a template shared by
  a dungeon and the open world is simply +4 in both.

- **All Outland gear is wearable at 60** (Ritz, 2026-09-24).
- **World greens and blues, re-spread** (Ritz, 2026-09-24, replacing the
  earlier "greens stay" and "Hellfire blues = Ramparts blues"): "I think
  we should make the Hellfire Penninsula greens be roughly equivalent to
  the Azeroth dungeon blues, and the Isle of Quel Danas greens be
  equivalent roughly to the Emerald Dragons. The Outland Blues should
  range from roughly half of the green scale, up about the same amount of
  distance to around 1.5x the item level of the greens. I'm guessing
  that's roughly around the start of Naxxramas gear?"
  - Read on the stat-budget scale (≈ epic item level): the **green scale**
    runs from ≈ 47 (level-60 dungeon blues) to ≈ 72 (Emerald Dragons),
    25 wide. **Blues** start halfway up it (≈ 60) and run one full width
    higher, ending half a width above its top (≈ 83): the start of
    Naxxramas-40 (83–92). Her guess holds.
  - Both are proportional by item level, so every item keeps its place
    and its loot table: greens raw 84–116 → ≈ epic 47–72; blues raw 85–115
    → ≈ epic 60–83. Stats are scaled to the new budget.

  | Zone | Greens, raw (≈ epic) | Blues, raw (≈ epic) |
  |---|---|---|
  | Hellfire Peninsula | 74–84 (47–53) | 77–80 (62–65) |
  | Zangarmarsh | 84–88 (53–56) | 80–85 (65–69) |
  | Terokkar Forest | 88–98 (56–63) | 85–94 (69–76) |
  | Nagrand | 91–100 (58–63) | 88–96 (72–78) |
  | Blade's Edge | 96–102 (61–65) | 93–97 (75–78) |
  | Netherstorm | 103–107 (66–68) | 99–100 (80–81) |
  | Shadowmoon Valley | 106–110 (67–70) | 99–101 (80–82) |
  | Isle of Quel'Danas | 110–113 (70–72) | 101 (82) |

  (Middle half of what each zone's normal creatures drop, as in the stock
  table above.) Hellfire's blues now sit a little below Ramparts' (≈ 69),
  so the first dungeon stays ahead of the first zone.
- **World blues come down by scaling their stats** (Ritz: "That helps
  keep the aesthetics valid"): same item, same look, smaller numbers.
  Their rating stats also take 155f's Burning Crusade rating discount.
  Greens are scaled the same way.
- The item-level-100 rare world epics: required level 60 (155f), and they
  **stay bind-on-equip** ("They are rare, powerful artifacts."), so
  buddies mail them to their owner (617j).
- **Proportional, by item level** (Ritz, 2026-09-24: "scale the drops
  according to ilevel, and try to keep them proportionally at the same
  position in the new range that they were in the old range. They should,
  if we design it correctly, they should be able to be left on the exact
  same loot tables."): the rule behind the re-spread above. (Its first
  version mapped blues onto ≈ epic 69–84 and left greens stock; replaced
  by the re-spread.)

## Suggested Implementation Steps

1. A generator reads the zone map bounds and the creatures' loot tables,
   and writes `sql/basic/db_world.src/NN-outland-world-gear.apply.sql` and
   its revert: required level 60 on every weapon and armor piece these
   creatures drop; bind on pickup for the blues; each green and blue's
   item level and stats rescaled by the two proportional maps (and the
   rating discount); creature levels +4 (+6 on the Isle).
2. Test on the RAM database; re-run the zone query and compare with the
   table above.

## Related Issues

- **155** parent
- **155f** Outland dungeons — the dungeon rows of the chart
- **155h** Onyxia and Naxxramas — the raid rows
- **155j** Kazzak (top of the ladder) and Fel Reaver (a possible world
  boss between)

## Open Questions

- **Gem sockets and socket bonuses** when item stats are scaled. Ritz,
  2026-09-24: "Gem sockets and socket bonuses I think require an MPQ edit
  which is a client-side thing that we can't touch." Read in the server
  (2026-09-24): half of it is server data. An item's sockets (how many,
  which colours) and *which* bonus it has are fields of the item's
  database row, sent to the client in the item query (ItemHandler.cpp: the
  reply writes each socket's colour and the `socketBonus` id). What a bonus
  *gives* ("+4 Stamina") and what a gem gives live in the client's
  enchantment tables (SpellItemEnchantment.dbc, GemProperties.dbc), which
  would need a client patch. So the scaler can keep sockets as they are,
  remove them, or swap a bonus for another existing, smaller one, without
  touching the client; only changing a bonus's or gem's own numbers needs
  the client. Proposal: leave sockets and bonuses as they are (gems are
  crafted by Jewelcrafting, capped at 300 on basic, so Outland gems come
  only from drops). Agreed?

- (Answered 2026-09-24) The Isle of Quel'Danas gets **+6** (typical 75–76; full range 75–77), the
  top of the open world, just under Kael'thas (78): "It gets +4. In-fact
  since it's the highest level zone, maybe we give them +5 or +6." / "+6".
- (Answered 2026-09-24) The world bosses stay at stock levels: "let's see
  how they fare at stock levels."

- (Answered 2026-09-24) Bind-on-pickup Outland blues, tradeable within the
  clan both ways for 2 hours; a buddy gives an unusable blue to the clan
  member it upgrades most, guessing each of its owner's possible specs,
  and vendors it if nobody gains. Consequence noted: no Outland blue
  reaches the auction house, and none can go to a friend outside the clan.
  The item-level-100 world epics stay bind-on-equip.
- (Answered 2026-09-24) Zone pairing and targets: "this loot tier list
  looks good for now"; the best world blues stay at ≈ 84.
- (Answered 2026-09-24) A blue that drops both in the world and in
  dungeons is scaled by the world mapping: "they should be scaled
  according to how they are scaled in the world."
- (Answered 2026-09-24) Scale by item level, proportionally, same loot
  tables.
- (Answered 2026-09-24, revised the same day) Greens re-spread to ≈ 47–72,
  blues to ≈ 60–83, both proportional, stats scaled.
- (Answered 2026-09-24) All Outland gear wearable at 60; Outland quests
  removed (155l).
