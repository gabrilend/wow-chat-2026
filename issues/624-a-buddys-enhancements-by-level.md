# 624 - A Buddy's Enhancements by Level: Rings, Amulets, Enchants

## Status
- Created: 2026-10-15
- Phase: 6
- Related: 621 (the weapon enchant at 30: the first of these), 617a4 (the
  starting kit), 617a6 (buddies made again at a tier), 617j2 (gems)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-15:

> At level 10 and above they should have one jewelcrafter ring (if it
> exists), remember they might be made at level 14 or something. At level
> 20 and above they should have wrist enchantments (do any exist?). At
> level 30 they get weapon enchantments, then at 40 they should get chest
> enchantments. Level 50 is boots, and level 60 is legs. Does that sound
> right? Oh also at level 20 they should get another jemcrafter ring. And
> at level 30 they should get amulets too. Then at 50 maybe shoulder or
> head or glove enchantments??
>
> also... can we add the item that the blacksmith can make that adds a
> socket to a belt-buckle? What recipe is that?

Answers, 2026-10-15 (verbatim): on legs, head and shoulders, which classic
enchanting has none for, "we should still do it. We're trying to buff the
white-quality gear armor so the newly created buddy-bots have a fighting
chance, and can learn from their equipment what works best and what
doesn't. Since they can't compare to those enchants specifically, they
must learn from the combination." On the belt buckle: "can we lower it to
level 60ish?" On cloaks, rings and trinkets: "They should have cloaks and
rings and trinkets at the specified level. When they are level
appropriate. And don't forget the PvP gear..." (built the same day: gray
cloaks in the white lists, the PvP necklace, rings and trinkets from 18).

## Current Behavior

A buddy is made in white vendor gear with no neck, rings, trinkets or
cloak (`buddy-white-*` gearsets), gems in its sockets (617j2), and from
level 30 a random weapon enchant on its first kit (621). Nothing else.

What the game offers, read 2026-10-15 from the client's tables and the
world database (the scratch readers `craft-tiers.lua` and
`enchant-names.lua`, session scratchpad, not kept):
- **Jewelcrafted rings** from required level 10 (Woven Copper Ring,
  Braided Copper Ring) up through 57 (Band of Natural Fire); **necklaces**
  from 13 (Malachite Pendant) to 58 (Arcanite Sword Pendant). Mostly
  uncommon, some rare.
- **Enchanting** has permanent enchants for: bracers (34, Minor Health up),
  chest (32), cloak (39), weapon (49), boots (26), gloves (34), shield
  (19), and two-handed and staff ones. **None for legs, shoulders or
  head.** Those come from other items: head and legs from Arcanums (the
  classic ones, "Lesser Arcanum of ...", need level 50-60; Arcanum of
  Focus needs 50), shoulders from late classic reputation items.
- **The belt buckle** is the Eternal Belt Buckle (item 41611), made by
  blacksmiths at skill 415 in Northrend; it needs level 70 to use (item
  level 80), beyond basic's level-60 cap.

## Intended Behavior

When a buddy is made at a level (or made again at a tier), it gets every
enhancement of the steps at or below that level, each chosen for its
talent plan:

| From level | Enhancement |
|---|---|
| 10 | one jewelcrafted ring of its level |
| 20 | a second jewelcrafted ring; a bracer enchant |
| 30 | a weapon enchant (621, built); a jewelcrafted necklace |
| 40 | a chest enchant |
| 50 | a boot enchant; perhaps a glove enchant (and head or shoulder?) |
| 60 | a leg enhancement (an Arcanum: there is no leg enchant in classic) |

A buddy made at 14 gets the level-10 step; at 34, the 10, 20 and 30 steps.

## Suggested Implementation Steps

1. Answer the open questions.
2. A generator (like the gearset translator) that writes, per level, the
   jewelcrafted rings and necklaces and the enchants by slot, scored by
   each talent shape's stat weights, as a data file the kit reads.
3. The kit applies the steps of its level (rings and necklace equipped,
   enchants in the permanent slot), logging any step with nothing of the
   buddy's level ("neta, nothing eta").
4. An offline test: a buddy at 14, 34 and 60 gets exactly its steps.

## Open Questions

1. (Answered 2026-10-15: do legs, head and shoulders anyway.) Which
   enhancement for them: the classic Arcanums and reputation items as
   they are (levels 50-60), or made enchants of the buddy's level?
2. Level 50: boots only, or boots and gloves (gloves exist), and head
   (Arcanum) or shoulder (late reputation items)?
3. The belt buckle: lowered to level 60ish (answered 2026-10-15). Its
   required level lives in the world database (item 41611), so an
   install-time edit can set it to 60; the recipe stays at blacksmithing
   415, which basic's blacksmiths (capped at 300) can't reach. Given to
   buddies at 60 by the kit, sold, or a recipe lowered too?
4. Which ring and necklace at a level: the best for the plan among those
   of its level, or random among them like the weapon enchants?
