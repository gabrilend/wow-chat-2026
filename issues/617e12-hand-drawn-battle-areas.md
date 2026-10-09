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

Not built; decided in part (2026-10-08, below). A buddy roams the named area its owner stands in, read from
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

### Decisions, 2026-10-08 (owner)

**Drawn by an AI, from what a person would look at.** Asked whether a
game master walks the edge or places circles: "sorta like this, but placed
by an AI examining the map, the minimap, a top-down screenshot of the
area, and a screenshot of various parts that have high levels of
elevation difference, to see the boundaries and cliffs and lakes. it can
also see, one additional input image with annotations per, the spawn
locations and area regions for different quests, overlayed as a plane
onto the 3d world. To better approximate what kinds of monsters populate
what parts of the map, and better to draw demarcating lines. It should be
able to open up a sql query on any of the spawn points to see everything
about that creature. Also, to download it's wow-wiki.com or whatever's
html page, to use as input source too." So areas are polygons drawn by a
model with these inputs:
- the zone's map and minimap, and a top-down picture of the area;
- pictures of the places where the ground rises or falls steeply (cliffs,
  lake shores, cave mouths);
- one picture per quest, annotated: its spawn points and quest regions
  laid as a plane over the ground;
- a database query on any spawn point (everything about that creature);
- the area's wiki page, fetched as a source.
It answers with each area's corners and a name; the result goes into the
drawn-areas table like any other area.

**The town rule, in every town** ("anytime they're in a town. Take the
Crossroads for instance - there's a fort in the middle, and outside it
there's some plains. If the buddy-bots wandered inside that area,
including the plains, then they could interact with friendly NPCs
sometimes, and monsters the rest. Fight! Might as well, all night."):
inside any town's area, the plains round it included, buddies talk to
friendly townspeople sometimes and fight monsters the rest of the time.

**Everywhere split up** ("in general, they each have roughly two or three
areas. We should split everywhere else up into areas as well. Look at the
monster types as a clue."): every starting valley in two or three areas,
and every other zone too, the kinds of monster living in each part being
the main clue to where one area ends.

**Empty places: an arc round the player** ("if we're in a zone that
doesn't really have any monsters, and not really any friendly npc's too,
then we should have the buddy-bots follow the player in an arc around
them."): where an area has almost no monsters and almost no friendly
people, buddies follow the player, spread on an arc round them
(`lib/buddy-arc.lua`, the arc the game masters' buddy commands already
place them on).

**The boar and the vendor.** Asked what a buddy in the camp does with a
boar 15 yards off and a vendor 10 yards off: "charges the boar first,
because he walks within the aggro radius while walking to the vendor.
except in rare cases where the vendor and the boar are opposite each
other in the distance spectrum wheel iron isotope in red notebook." The
nearest target is chosen, but walking toward it can bring a monster into
its aggro radius, and the fight then comes first; only when the two lie
in opposite directions does the nearer one simply win.

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

1. (Answered 2026-10-08) **How an area is drawn:** polygons, drawn by an
   AI from pictures, quest overlays, spawn queries and wiki pages (above).
   Still open: which model and how it is run (one zone at a time, offline,
   its drawing reviewed in the zone view from above, 617e7, before it is
   kept?), and how the pictures are made (the custom client's windowless
   pictures, 176a, or the zone view's renderer).
2. (Answered 2026-10-08) **The town's rule, where:** in every town, its
   surrounding plains included; sometimes talk, mostly fight. Still open:
   how often "sometimes" is (one target in five a townsperson?), and do
   errands (617e4: trainer, vendor, repair) still come first when due?
3. **Town circles and drawn areas:** the town side (area 3) holds the
   town circle. Does being inside a drawn area with this rule replace the
   town circle's behaviour there, or does the circle still mean "town
   errands first"?
4. (Answered 2026-10-08) **The other starting valleys:** two or three
   areas each, and every other zone split too, monster kinds the clue.
6. **"Almost no monsters, almost no friendly people":** counted how (the
   spawns inside the area, per square yard, below a threshold?), and
   decided once when the area is drawn, or live?
5. **"Orbit on their own":** is the drift from nearest thing to nearest
   thing enough, or should a buddy in town also keep circling (617e2's
   orbit) between targets?
