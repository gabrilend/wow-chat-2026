# 617o9 - The smap: the World Seen, Grown into a Map of Its Ground

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 617o (buddy pathfinding)
- Related: 617o8 (the painted map: the smap is its second data source),
  617o7 (five ways to find a path: the forces-only routine's states),
  617e2 (ties between equal ways), 617e4c (roads), 617e12 (caves and
  areas), 176a (test scenes: headless pictures from the custom client)
- Priority: High
- State: planned; nothing built

## Origin

The owner, 2026-10-30, on the painted map's wanted space, word for word:
"This might be overwritten with the movement map caching we're going to
do with the stand-in walking around the map taking screenshots of
everything until we've fully painted the world, similar to
photogrammetry style but not as detailed. So long as we get two angles
of the same area, that should be good, and we don't have to do things
like the tops of mountains and such for now. Right now for pathfinding
we're kinda building a bunch of systems and tools that we can combine
into an ultimate pathfinding solution once we've build all the
mechanics, so focus on making levers that can be pulled and data
sources that we can pull from."

On its name: "Bots should be more like people, and they will be once
we've built out their "visual map" of the area. Except "vmaps" are
already taken, hmmmm...." Then: "smap works".

On telling a canyon from a dip, word for word: "this fiddly stuff is why
for complex problems like this, which COULD be engineered at great
difficulty, are better suited to a natural processing technique like the
smaps, which build a sight based categorization of terrain that can only
improve with additional smap input. Once it's built, it's solved, and we
*grew* a solution out of the clay of the earth, rather than specified
with harsh tolerances."

On what takes the pictures: "might be custom client work, but we can do
it with a UI addon that we spin up and then a sandboxed client that we
use. I think we have a plan for headless client usage somewhere...?
Maybe it was this haha"

On where to start: "it does not matter at all, we must do all of them.
But starting zones is a good idea, so... Durotar, not the Valley of
Trials. Maybe also the capitals."

On roads: "smaps." On a road's danger: "determined from surrounding
monsters and such, not baked into the smap, because monster positions
might change, but the terrain is more static."

On trails (617o8): "yes, but this waits on the smaps to identify trails
and such." On ties (617e2): "Or defer to the smap."

## Current Behavior

Nothing built. The server has its own vmaps (line of sight and heights
from models) and mmaps (the walking mesh); neither says what ground
looks like: a road, a trail, a dip, a canyon, a cave mouth. The painted
map (617o8) learns walls and walked ground only from bots bumping and
walking. The headless picture plan exists for the custom client's test
scenes (176a: "we should be able to "headlessly" generate pictures of
scenes, so we can create hundreds of these pictures at once").

## Intended Behavior

**What it is.** A map of what the ground is, learned by sight: for each
place, from pictures of it taken from at least two angles, the kind of
ground (road, trail, open, cluttered, dip, canyon, cave mouth, water's
edge, cliff), kept beside the painted map as a data source the ways of
finding a path read. It is static, as terrain is: nothing that moves
(monsters, people) is baked into it.

**How the pictures are taken.** A stand-in walks the world; at each
spot a client draws the view from where it stands, at least two angles
of every place. The client: a sandboxed game client running a UI addon
that steers the camera and takes the pictures, or the custom client's
headless picture mode (176a). Mountain tops are skipped for now.

**Grown, not specified.** The categories come from the pictures (an
image model reading them, its readings checked against the ground's
heights and the walking mesh), not from hand-tuned height tests, and
the smap only improves as more pictures arrive: a place seen again is
read again and its reading firmed up.

**What reads it:**
- the forces-only way (617o7) enters and leaves by the ground's kind (a
  dip, a canyon, a long wall);
- ties between equal ways (617e2) are decided by it where it knows the
  ground;
- roads (617e4c) come from it; a road's danger does not (it is worked
  out live from the monsters round it);
- trails (617o8) are found by it, and only then made cheaper to walk.

**Order.** All of the world in the end. First Durotar (the whole zone,
not only the Valley of Trials), then the capitals.

## Suggested Implementation Steps

1. Choose the picture taker: try the sandboxed client with a small
   addon first (camera turn, screenshot, move on), the custom client's
   headless mode beside it; one Durotar spot from two angles each way.
2. The stand-in's walk: a grid of spots over a zone on the walking
   mesh, each visited once, the pictures filed by map, spot and angle in
   the RAM drive, then kept.
3. The reading: an image model labelling each spot's ground kind, with
   the ground's height and the mesh as checks; disagreements listed.
4. The smap file per region beside the painted map's, with its levers
   (which kinds, how sure).
5. The readers above, each behind its own switch.
6. Durotar, then the capitals; a picture of the smap over the zone view
   from above (617e7) for the owner to judge.

## Open Questions

1. Which image model reads the pictures: the image pipeline's own
   text-and-picture encoder (its CLIP part), or a larger model run
   offline?
2. How many spots per zone: a fixed spacing (say every 20 yards on the
   mesh) or denser where the ground changes? **Answered 2026-10-30**
   (the owner, word for word): "as many as we need to paint the whole
   picture. If we take an additional picture and it doesn't give us new
   information even though it's from a new angle, then it's probably
   fine. If two attempts disagree, then it might be an angle thing, so we
   should approach that area from multiple extra angles until we can
   figure it out. Maybe also we zoom in the character until they can see
   the details more clearly about that specific area." No fixed count:
   pictures are taken until a new angle adds nothing new; where two
   readings disagree, more angles are taken there, and closer views
   (the camera zoomed in on that spot) until the readings agree.
3. Does Q (depth from the nearest exit, 617e12) cover buildings, crypts
   and instances too? **Answered 2026-10-30:** "yes, yes, and yes."
