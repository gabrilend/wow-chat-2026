# 617e16j - The Sub-Zone Fence

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617e16 (the fish-school sandbox)
- Related: 617e16f (the walkable parts, merged by monster name), 617e14b
  (the zone data: each square's sub-zone)
- Priority: High
- State: in progress

## Origin

The owner, 2026-10-28:

> so, I noticed a problem, there's some sub-zones that are so large
> they're covering essentially the entire map, meaning the buddy-bots have
> too far of a distance to roam. Can you help me figure out how to select
> only the appropriately sized ones? Maybe by zone text or sub-zone name
> or similar? So... two types of fences... one is the monster spawners,
> the other is the sub-zone area that you're in. Gosh that means...
> they'd always be anywhere in the sub-zone that all the monsters that you
>'re in the spawning area of can visit. OMG can you make that pls

## Current Behavior

The wandering area is every fence of the monsters the player stands
among, merged by name across the whole zone (617e16f), less steep ground.
A monster living all over a zone makes an area as big as the zone (the
Barrens' Zhevra Runners: 179,340 square yards walkable in one part).

## Intended Behavior

- **Two fences.** The monster fences, as before; and the **sub-zone
  fence**: the named sub-zone the player stands in, from the zone data
  (each ~33-yard square's sub-zone: The Crossroads, Field of Giants, The
  Dry Hills ...).
- **The wandering area is where both hold**: the walkable ground inside
  the spawn areas of the monsters the player stands among, and inside the
  player's sub-zone ("anywhere in the sub-zone that all the monsters that
  you're in the spawning area of can visit"). Walking into another
  sub-zone, the area is worked out again for it.
- **Seen**: the sub-zone named on the panel; its squares shaded faintly
  on the map; the area's size before and after the cut.

## Suggested Implementation Steps

1. The page keeps each continent square's sub-zone (it is already read
   when the continent is drawn).
2. An area (617e16f) is worked out per monster name **and** sub-zone: a
   point counts only if its square is in the player's sub-zone.
3. The panel names the sub-zone; its squares drawn faintly.
4. Pictures, one commit each.

## Open Questions

1. **A sub-zone that is the zone itself**: much of a zone is "The
   Barrens" (the zone's own name as its sub-zone, the ground between the
   named places). Standing there, the cut does little. Should a cap on
   size apply too (say the area within some distance of the player), or
   the nearest named sub-zone be used?
