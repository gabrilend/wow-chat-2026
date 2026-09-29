# 155v - Aldor and Scryer by Deeds

## Status
- Created: 2026-09-26
- Phase: 1
- Parent: 155
- Blocked by: 155l (Outland without quests: built), 155j (Kazzak: the ceiling their gear stays under)
- Priority: Medium
- Planned only: not built.
- The test case for 161 (faction by reputation), on factions whose side
  doesn't decide who may attack whom.

## Origin

Verbatim, 2026-09-26:

> can we remove all quests in Outland? You can gain reputation with
> scryer/aldor the same way as with horde/alliance. We can use them as a
> test-case for the faction reputation system, since we won't have to
> actually change the player's relation to the factions at all. Anyway 20
> for killing one, 10 for the other, and you get bonus points if you defend
> their camps. They have a vendor for you that sells high level equipment
> from Outland - always less powerful than Kazzak, but still pretty good.
> Their slots don't overlap so you're encouraged to do both of them. Well
> how about they sell weapons, rings, and trinkets - but only one is
> probably useful to you. So you can get both, if you defend both. They can
> also sell rare consumables and gem crates.

## Current Behavior

- **Outland has no quests on basic already**: 155l (built 2026-09-24,
  install step E028) disables every quest filed under an Outland area,
  Shattrath included; the quest givers stay.
- So on basic nothing raises Aldor or Scryer reputation today: in the
  stock game it comes from their quests and turn-ins (marks, signets,
  fel armaments, arcane tomes), all of which are quests.
- Stock: the two are rivals; gaining with one costs with the other, and a
  character starts slightly toward one or the other by race. Their
  quartermasters sell gear, enchantments and inscriptions at reputation
  ranks.
- **Reputation from kills** is stock (the world database's reputation
  reward per creature), but the Aldor and Scryer have little of it.

## Intended Behavior

- **Reputation by deeds, as 161 describes for the Alliance and the Horde**:
  killing a member of one (or its allies) is worth reputation with the
  other; "20 for killing one, 10 for the other" (read as: +20 with the side
  you helped, -10 with the side you hurt, the other way round from 161's
  +10/-20; to confirm).
- **Defending their camps pays a bonus**: kills made inside or near an
  Aldor or Scryer camp, while its people are there to see.
- **Their vendors**, reached by reputation:
  - high-level Outland equipment, always less powerful than Kazzak's
    (155j), still good;
  - **weapons, rings and trinkets**, from both, with no slot overlap in
    purpose: each sells its own kind (Aldor and Scryer items differ in
    stats), so a character usually finds one useful item at each and
    earns both by defending both;
  - rare consumables and gem crates.
- No change to who may attack whom: the player's relation to the two
  stays as it is, which is why they are the test case (the owner: "we
  won't have to actually change the player's relation to the factions at
  all").

## Suggested Implementation Steps

1. Read the Aldor and Scryer: their faction ids, their NPCs' camps in
   Shattrath and Outland (by spawn clusters), which creatures count as
   their members or allies (by faction template), and what their
   quartermasters sell today.
2. A script: on a creature or player kill in Outland, the reputation
   change by the rule above, with the camp bonus.
3. Vendor lists by a generator: Outland weapons, rings and trinkets under
   Kazzak's item level (155j), split between the two by stat themes;
   consumables and gem crates (gem crates are new items: container items
   with a loot table of gems, 155p's supply).
4. Tests: the RAM database test for the vendor SQL; a script test for the
   reputation rule.

## Related Issues

- **155** parent; **155l** Outland without quests; **155j** Kazzak (the
  ceiling); **155k** Outland gear; **155p** gems (crates)
- **161** faction by reputation: this issue is its test case

## Open Questions

- **"20 for killing one, 10 for the other"**: +20 with the side you
  helped, -10 with the side you hurt? (161 is the other way round: +10
  and -20.)
- **Who counts as "one" of them to kill**: their NPCs (both have guards
  and members in Shattrath and in their camps), players aligned with the
  other, or the demons, nagas and others each fights?
- **The camp bonus**: how much, and which camps (Shattrath's terraces, the
  Aldor and Scryer outposts in Nagrand, Netherstorm, Shadowmoon Valley)?
- **Rank gates**: which items at which reputation rank?
- **Gem crates**: what's in one (Azeroth gems, Outland gems, a level
  band)?
