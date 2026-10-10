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

In progress: decided in part (2026-10-08, below); the automatic first cut
is built, the roaming that uses it and the AI pass are not.

**What roaming uses today.** A buddy roams the named area its owner stands
in, read from the server's map files (617e2): every map is cut into
squares about 33 yards across, each labelled with an area, and
`scripts/generate-buddy-area-centres` turns each area's squares into a
row of `buddy_area_centre` (borders, middle). The Valley of Trials is one
such area (map 1, area 363): 327 squares, about 770 by 630 yards,
centred near (-449, -4302). The demon cave (the Burning Blade Coven) is
not labelled apart from the valley in the map files, so it is part of
that one area.

**The first cut, built (no AI yet).** `scripts/generate-buddy-subareas`
(LuaJIT, one worker process per map, Eastern Kingdoms and Kalimdor by
default) cuts every named area into parts the way the owner described,
monster kinds as the clue and steep ground as the edges:
1. Each square gets a steepness: the share of neighbouring height samples
   (the map files' fine height grid, a sample about every 4 yards) whose
   rise over run is above 1.2 (about 50 degrees).
2. Monsters are the spawns whose creature trains nobody, isn't a critter,
   can be attacked, and whose faction belongs to and befriends none of
   players, Alliance or Horde, and is either hostile to players or has no
   reputation (so camp guards of the Argent Dawn, Cenarion Hold and the
   Keepers of Time stay out). Holiday-only spawns (the autumn feast's
   turkeys) and training dummies are left out.
3. Monsters are grouped by kind: a beast by its family (boars, scorpids),
   anything else by creature type and faction. A kind with at least 3
   spawns within 3 squares of each other makes a seed.
4. Each seed spreads over its area square by square, a steep square
   costing up to 7 flat ones, so seeds meet along ridges and cliffs.
5. Neighbouring parts of one kind merge; a part under 25 squares joins the
   neighbour it shares the longest border with.
6. Each part's centre is the middle of its own square nearest its average
   point, so the centre is always inside it (a bent part's average point
   fell outside 18% of the time).

Results are in `sql/basic/db_world.src/36-buddy-subareas.{apply,revert}.sql`
(tables `buddy_subarea`: one row per part with its area, square count,
centre, levels and three leading monsters; `buddy_subarea_square`: which
part each square of a split area belongs to), installed for basic by step
E055. It also draws one picture per split area into
`tmp/shared-memory/subareas/<map>-<area>.png` (parts in colours, steep
ground dark, monster spawns as dots). The starting valleys come out as
the owner described: the Valley of Trials in three (Mottled Boars round
the edges and the camp, Scorpid Workers in the middle, the demons in the
north by the Coven), Coldridge in four, Deathknell in five, Shadowglen in
four, Northshire in two. Run the generator for the current counts, and
`scripts/test-buddy-subareas` for its 14 checks (the valleys, what counts
as a monster, every centre inside its part, the SQL applied twice and
reverted in the `_smoke_test` database). Nothing reads the tables yet.

**Seeing the cut in game (2026-10-09, written, compile-checked, not yet
built):** the owner asked for a game-master command to see the areas and
another for a creature's spawn points, in wisps ("Usually we can use an
un-interactable wisp unit"). `modules/mod-buddies/src/buddies_show.cpp`:
`.buddy area show` names the part the game master stands in (named area,
its parts, levels, leading monsters, squares) and draws its border in
wisps for 30 seconds, along every square edge it shares with another
part within 250 yards; `.buddy area spawns <creature id or name>` puts a
wisp on each spawn point of that creature within 300 yards. The wisp is
the town circles' (617e4a), now one shared call, `BuddyPlaceWisp`. Their
queries, tried on the data: standing among the Valley of Trials boars
finds part 100151 (132 squares, levels 1-2, Mottled Boars, one of 3), and
the boars' spawn points there number 65, the part's own count.

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

0. (Built) The automatic first cut, above: `scripts/generate-buddy-subareas`,
   step E055, `scripts/test-buddy-subareas`. The roaming core (step 3)
   reads its parts until the AI pass replaces them; the AI pass starts
   from these parts rather than from nothing.
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
7. **The first cut against the owner's three:** the owner's Valley of
   Trials is the cave, the middle upper area, and the town side with the
   entrance. The first cut's are the demons (north, by the Coven), the
   scorpids (the middle) and the boars, which wrap round both sides of
   the scorpids as well as holding the camp. Is a part that wraps round
   another acceptable, or must every part be one solid piece of land on
   one side?
8. (Answered 2026-10-09) **Caves:** the Coven's inside is not told apart
   from the valley in the map files, and the generator sees the ground's
   height, not the roof. The owner: "should use movement navmesh?" Yes:
   the server's walking mesh (`data-files/mmaps/`, Detour tiles) covers
   every walkable floor with polygons, cave floors and building interiors
   included, and says which polygons join. A floor several yards below
   the height map's ground is under the hill: a cave; where those
   polygons join the surface ones is its mouth. The same mesh can replace
   the steepness guess: two squares are apart when no walkable link joins
   them, not when the ground between them is steep.
   - **Buildings' interiors:** "like a cave for now, but more skeletan in
     the future. Think... Roboquest rails." A cellar, mine or crypt is its
     own part like a cave today; later, interiors become a skeleton of
     rails (the paths through them, as Roboquest's grind rails carry a
     player along fixed lines) that buddies ride rather than roam.
   - **A tunnel open at both ends** (explore it, or walk through it?):
     "the navmesh". Decided by the mesh's shape, how is still open
     (question 9).
   Not built: a Detour tile reader in Lua for the generator.
9. **Tunnel or cave, from the mesh:** one reading is a dead end against a
   through-way: a cave's under-hill polygons join the surface at one
   mouth, a tunnel's at two or more, on different parts' sides. Another is
   width against length: a passage is long and one corridor wide, a cave
   opens into rooms. Which one did the owner mean, or both?
