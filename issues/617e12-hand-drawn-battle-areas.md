# 617e12 - Hand-Drawn Battle Areas

## Status
- Created: 2026-10-08
- Phase: 6
- Parent: 617e (buddy area adventuring)
- Related: 617e2 (the roaming core: areas from the map files), 617e4
  (town visits), 617e4a (town circles, placed by hand), 617e6 (exploring
  modes), 619 (combat footwork)
- Priority: Medium

## Origin

The owner, 2026-10-08:

> I think we need the "zone" or "areas" that players and buddy-bots battle
> in need to be adjusted in size. I think for example, we should have 3
> zones in the valley of trials - one for inside the demon cave, one for
> out in the middle upper area, then another for the town, it's cave, and
> the parts off toward the shaman quests and the entrance to the zone. In
> the town, the NPC buddy-bots should prefer fighting monsters and talking
> to NPCs just as equally important - indeed they'll most often target the
> thing that is nearest them. So they might orbit on their own.

## Current Behavior

Not built. A buddy roams the named area its owner stands in, read from
the server's map files (617e2): every map is cut into squares about 33
yards across, each labelled with an area, and
`scripts/generate-buddy-area-centres` turns each area's squares into a
row of `buddy_area_centre` (borders, middle). The Valley of Trials is one
such area (map 1, area 363): 327 squares, about 770 by 630 yards,
centred near (-449, -4302). The demon cave (the Burning Blade Coven) is
not labelled apart from the valley in the map files, so it is part of
that one area.

Towns are marked separately, by circles (617e4a: two in the Valley of
Trials, around its camp), and inside a town circle buddies do town
things (errands, leisure) rather than fight (617e4).

## Intended Behavior

**Areas drawn by hand, where the map files' areas are too big.** A game
master marks out smaller areas in game; a buddy then roams the smallest
drawn area its owner stands in, and the map files' area only where none
is drawn.

**The Valley of Trials in three:**
1. **The demon cave**: inside the Burning Blade Coven.
2. **The middle upper area**: the open middle and upper valley.
3. **The town side**: the town, its cave, the parts toward the shaman
   quests, and the valley's entrance.

**Fighting and talking, equal, in this town** (owner: "In the town, the
NPC buddy-bots should prefer fighting monsters and talking to NPCs just as
equally important - indeed they'll most often target the thing that is
nearest them. So they might orbit on their own."): in the town area, a
buddy's next target is whichever is nearest, a monster to fight or a
townsperson to talk to, with neither preferred. Moving from nearest thing
to nearest thing, buddies drift round the town on their own rather than
circling its middle.

## Suggested Implementation Steps

1. Decide how an area is drawn (open question 1) and the commands for it,
   in the shape of the town circles' (`.buddy town here`, `show`,
   `remove`; `buddies_town_circles.cpp`).
2. A table of drawn areas (map, name, shape), loaded at startup, written
   at once when a game master draws, carried into the project's SQL by a
   script, as the town circles are.
3. The roaming core's "which area is the owner in" (617e2) checks drawn
   areas first, smallest first.
4. The nearest-target rule for the town area: monsters and townspeople in
   one list, nearest first.
5. The Valley of Trials drawn in game, in its three areas.
6. Tests: a point in each of the three areas finds that area; a point
   outside all finds the map files' area; the nearest-target choice on a
   set of positions.

## Open Questions

1. **How an area is drawn:** a game master walks its edge and marks
   corners (a polygon, which fits a cave or a valley's shape), or places
   circles of a chosen radius (simpler, like the town circles, but a
   circle fits a long valley badly)?
2. **The town's rule, where:** fighting and talking equal, nearest first:
   only in the Valley of Trials' town side, in every starting valley's
   town, or in every town that has monsters close by? Elsewhere, towns
   stay errands and leisure (617e4)?
3. **Town circles and drawn areas:** the town side (area 3) holds the
   town circle. Does being inside a drawn area with this rule replace the
   town circle's behaviour there, or does the circle still mean "town
   errands first"?
4. **The other starting valleys:** drawn the same way (Northshire,
   Coldridge, Shadowglen, Ammen Vale, Deathknell, Camp Narache, Sunstrider
   Isle), once the Valley of Trials works?
5. **"Orbit on their own":** is the drift from nearest thing to nearest
   thing enough, or should a buddy in town also keep circling (617e2's
   orbit) between targets?
