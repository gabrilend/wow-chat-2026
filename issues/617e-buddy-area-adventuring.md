# 617e - Buddy Area Adventuring

## Status
- Created: 2026-09-23
- Phase: 6
- Parent: 617
- Blocked by: 617c
- Priority: Medium

## Origin

Verbatim, 2026-09-23 (617 has the full answers):

> They try and fight the same creatures in the same area that you do, but
> they might be on the other side of the patch of mobs and that's okay. You
> only share exp when you're close, and they don't try to stay near - they
> just attack mobs as if the NPC bot was fighting in that particular area on
> their own.

> yes it comes back to life. It'll move to the areas that the player is in
> when it can.

And for towns, verbatim, 2026-09-23:

> they should stay in the same area as you. So if you're in town, they should
> wander around town and stand in front of random NPCs, do some talking
> animations, then walk to another NPC. Walk, not run. A random NPC in the
> area. When you're in a town or a city, you should be un-grouped with them
> too.

## Current Behavior

Bots in a master's group follow the master by default. Random bots grind
where the module sends them. Neither is "in my area, on its own".

## Intended Behavior

- A buddy's playground is the owner's current **area**: the named place
  shown on screen on entry (e.g. "Fargodeep Mine" inside Elwynn Forest). It
  fights what lives there and doesn't follow the owner. Grouped buddies stay
  inside the owner's experience radius, ungrouped ones outside it (617c).
- **In a town or city** the buddies are ungrouped (617c) and don't fight.
  Each walks (never runs) to a random NPC in the area, stands before it and
  plays talking animations, then walks to another.
- When the owner changes area, buddies travel there on foot, as a player
  would.
- When a buddy dies it resurrects (spirit healer or corpse run, like a
  player) and makes its way back to the owner's area.
- Grouped buddies share experience only when in range (stock rule);
  ungrouped buddies earn their own.

## Suggested Implementation Steps

1. A bot strategy in mod-buddies: "adventure in owner's area". It
   replaces follow, with a grind target search bounded to creatures inside
   the owner's current area.
2. Area-change travel: path to a point inside the new area.
3. Death handling: the module's existing release-and-resurrect logic, with
   the return trip from step 2.
4. Look at beta's 601 (find monsters) and 611 (wandering) for reusable
   ideas.
5. Test: owner stands at a camp's edge; buddies spread through the camp
   and fight; owner moves to the next area; buddies follow within a minute;
   a buddy that dies comes back.

## Related Issues

- **617**, **617c**; **601**, **611**, **613** (beta's Lua behaviors)

## Open Questions

- (Answered 2026-09-23) Buddies stay in the owner's area; in towns they
  visit NPCs on foot. The level band is whatever lives in that area.
- **What counts as a town?** The client flags some areas as towns and
  cities (sanctuaries, rested areas). Use "the owner is in a rested area"
  (inns and cities) as the rule?
