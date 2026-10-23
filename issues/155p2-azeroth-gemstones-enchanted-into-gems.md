# 155p2 - Azeroth's Gemstones, Enchanted, Then Cut

## Status
- Created: 2026-10-22
- Phase: 1
- Parent: 155p (sockets and socket bonuses on basic gear)
- Related: 155p1 (each capital jewelcrafter's order of cuts: the low-skill
  cuts need raw gems early), 155n (professions capped at 300), 617k (a
  clan's buddies with professions: "a clan enchanter")
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-22, asked where the raw gems for a low-skill
jewelcrafter's cuts should come from (Outland's raw gems come only from
prospecting mithril and thorium):

> you should be able to cut the azeroth gemstones into gems that suit
> their color. But, we'll need to enchant the gemstones, otherwise they're
> just pretty rocks. So, JC prospects the ores and gets gemstones from
> them sometimes. These go on the AH or to a clan enchanter, and then the
> enchanter uses shards (not dust!) to enchant the gemstones and make them
> into uncut gems, that the JC can then cut. One gemstone should make two
> cut gemstones, typically.

## Current Behavior

Azeroth's gemstones (Malachite, Tigerseye, Shadowgem, Moss Agate, Lesser
Moonstone, Jade, Citrine, Aquamarine, Star Ruby, Blue Sapphire, Large
Opal, Huge Emerald, Azerothian Diamond and others) come from prospecting
Azeroth's ores and from monsters, and serve as crafting materials
(jewelcrafting's rings and necklaces, other professions' recipes). They
can't be cut into socket gems. On basic, 155p made low-level gear socketed
(+4 to +8 gems) and the +4 cut gems come from prospecting copper and tin
and from Outland's gem vendors; Outland's own raw gems come from
prospecting mithril and thorium.

## Intended Behavior

A gemstone is a pretty rock until an enchanter wakes it:

1. **The jewelcrafter prospects** Azeroth's ores and sometimes gets
   gemstones (as now). Gemstones are traded (the auction house) or handed
   to an enchanter (a clan's, among a player's buddies).
2. **The enchanter enchants a gemstone** with enchanting shards (never
   dust): a new enchanting recipe per gemstone, turning it into an uncut
   gem.
3. **The jewelcrafter cuts the uncut gem** into socket gems of the
   gemstone's own colour: one gemstone makes two cut gems, typically.

So the low-skill cuts of 155p1 have raw gems from the start of
jewelcrafting, and jewelcrafting and enchanting need each other.

## Suggested Implementation Steps

1. Answer the open questions.
2. A generator (as the other basic SQL generators) that, for each Azeroth
   gemstone: picks its colour, its tier (by the ore it prospects from),
   the shard it takes (by tier), and writes the uncut gem items (new, one
   per gemstone, or reusing Outland's uncut gems), the enchanting recipe
   spells and trainer rows, and the jewelcrafting cut recipes (two gems
   from one) into a basic world database step with its revert.
3. The post-install checker: every gemstone has its enchant and its cuts.
4. Tests: the RAM database test (apply, re-apply, revert); in game: prospect
   copper, enchant the gemstone, cut it, socket the gem.

## Open Questions

1. **What the cut gems are:** new gems (Azeroth's own, at 155p's +4 to +8
   tiers, named after the gemstone: "Bold Tigerseye"), or the existing
   Outland gems of that colour (the gemstone turning into, say, an uncut
   Blood Garnet)?
2. **Each gemstone's colour:** by its look (Malachite and Jade green, Star
   Ruby red, Blue Sapphire blue, Citrine yellow, Shadowgem purple,
   Tigerseye orange...), or another rule? Gems of a mixed colour (green,
   orange, purple) fit two socket colours.
3. **Which shards:** the shard of the gemstone's tier (Small Glimmering
   for copper's gems up to Large Brilliant or Nexus Crystal for
   thorium's), one per gemstone?
4. **"Two cut gems, typically":** always two, or sometimes one or three
   (a chance, like prospecting)? And is the enchanting step one gemstone
   to one uncut gem, the cutting step one uncut gem to two cut gems?
5. **The skill levels:** each gemstone's enchant and cut at the
   enchanting and jewelcrafting skill where its ore is prospected (copper
   1-75, tin 50-125, iron 125-175, mithril 175-250, thorium 250-300)?
6. **What happens to the existing +4 cut gems from copper and tin and
   Outland's gem vendors (155p):** kept beside this, or replaced by it?
