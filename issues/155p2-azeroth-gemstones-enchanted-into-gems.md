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
## Answers, 2026-10-22

1. **They become Outland's gems.** The enchanted gemstone is an uncut
   Outland gem of its colour (an uncut Blood Garnet for a red stone, say),
   cut with the existing recipes; no new gems.
2. **Colour by its look**, and colours only merge, never split (the owner:
   "by it's look, but if we have to change it's color (like purple can't
   become red and blue, but red and blue can become purple if they're
   merged together somehow) sorta like how you can't take salt out of a
   spaghetti. then we need an extra processing step inbetween to split it
   into two of the same type, maybe alchemy?"). A purple stone (Shadowgem)
   makes a purple gem; a red and a blue could be merged into a purple; a
   stone whose look doesn't give the colour wanted needs an extra step,
   perhaps alchemy, that splits it into two of one kind.
3. **The tier's shard, one per gemstone**: Small Glimmering for copper's
   stones up through Large Glimmering, Small and Large Glowing, Small and
   Large Radiant, to Small and Large Brilliant for thorium's. Never dust.
4. **The yield** (the owner: "the rare gemstones just make one. And
   sometimes they make chiplets which stack to 10, which can be merged
   into a larger one - usually they make 6ish, slightly better than
   half."). Read as: a common gemstone makes two cut gems, a rare one
   (Star Ruby, Blue Sapphire, Large Opal, Huge Emerald, Azerothian
   Diamond, and the like) one; and sometimes the work leaves chiplets
   instead, a new item that stacks to 10, ten of which merge into one
   uncut gem; a batch of chiplets is usually about 6 (slightly better than
   half a gem). Open question 1 below checks the reading.
5. **Chiplets come from cutting and prospecting** (2026-10-22): a cut or a
   prospect sometimes yields chiplets (about 6, a stack holds 10), and
   "other professions might use them for things, like engineering for
   anything with lazers. Inscription for the most holy of paints."
6. **Alchemy is the third craft of the gem chain**: alchemists combine ten
   chiplets into an uncut gem of their colour, and split a mixed-colour
   stone (purple, green, orange) into two of one colour. Jewelcrafting,
   enchanting and alchemy need each other.
7. **Skills by the ore:** each gemstone's enchant and cut at the skill
   where its ore is prospected (copper 1-75, tin 50-125, iron 125-175,
   mithril 175-250, thorium 250-300).
8. **155p's +4 gems stay** (vendors, copper and tin): the supply for
   players without the crafts, beside the crafters' road.

## Open Questions

1. **Chiplets in other recipes** ("engineering for anything with lazers.
   Inscription for the most holy of paints"): new recipes that use them,
   or added as a reagent to existing ones (which engineering items count
   as "lazers": the scopes, the death ray, the goggles)? A list to draw up
   when the chain is built.
