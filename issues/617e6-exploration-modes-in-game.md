# 617e6 - Exploration Modes in Game

## Status
- Created: 2026-09-27
- Phase: 6
- Parent: 617e
- Blocked by: 617e2 (the core), 617e1 (the roam action)
- Priority: High (owner, 2026-09-27: "can you build all of them? I want to
  see what kind of mechanics they create. I'm a visual learner.")

## Current Behavior

**The pattern written down, and playable, 2026-09-28**: the rules of
roaming (the ground grid, paint and the walls' paint, rooms and tunnels,
the eight-sector sensing, the owner's waypoint rule, the kraken) are in
`docs/roaming-pattern.md`, without any programming language (the owner:
"the datamodel being the same doesn't mean that it's implementation in a
specific language needs to be the same. Build the pattern, build it
twice."). Two implementations: the Lua model and
`docs/HTML/buddy-roaming/roam-pattern.js`; `scripts/test-roam-pattern`
(gjs and luajit, a few seconds) runs the same seeded situations through
both and compares what the pattern fixes: 3,020 checks, 0 failures (the
map and walkable cells, 300 points' eight sectors, 600 waypoints); planted
mistakes in the sector reach and in crowding were caught. "Sensing tunnels
by quadrants" is now a playable scene on the gallery page (Part 4,
`dungeon-sense.js`) in place of GIF 25: sensing on or off, 1/2/4 buddies,
the blocked share, the sensing radius, paint shown, walls' paint, speed;
click a buddy to see its sectors; counts of explored share, tunnels
entered, dead-end visits, time to both far rooms, picks by sensing.


**Built 2026-09-27; compile-checked, cross-checked against the model, not
yet run in game.**

- **The core** (`modules/mod-buddies/src/roam/buddy_explore_core.*`, no
  server headers; see its `.info.md`): the ground grid, paint (16-bit
  counts that wrap, noted), the wall pulse, rooms and tunnels, the squished
  circle, the three choosers (least paint, room orbit, squished circle) and
  paint-weighted grid paths, written loop for loop after the Lua model's
  "painting" so the two agree to the last bit. Two parts only the server
  needs, since its grids have no outline: distances measured on the grid
  (`ComputeDistances`) and the border traced cell by cell (`RimAngles`).
- **The cross-check** (`scripts/test-buddy-roam-core`, second part;
  `tests/buddy-roam-core/explore-driver.lua` and `explore-check.cpp`): on
  the gallery's hall (2-yard cells), the model's rooms, tunnels, wall pulse
  and disc against the core's (exact), and a clan of four exploring 1,500
  ticks with each chooser, same random numbers: every choice, every path
  point and the paint's totals every 250 ticks match. The server's own
  parts: grid distances within 0.41 yd (edge) and 1.0 yd (walls) of the
  exact ones, the same 3 rooms and 3 tunnels from them; the disc from the
  traced border never folds (every little square of cells keeps its
  turning direction). Planted bugs (the room orbit turning the wrong way;
  paint without its falloff) each fail it.
- **In game** (`modules/mod-buddies/src/buddies_explore.*`):
  - **The setting**: ".buddy explore <pinwheel|paint|rooms|disc|mixed>",
    any player for their own buddies (in the "buddy" command table of
    `buddies_beds.cpp`), kept for the session; mixed gives the four out in
    turn by character number. Pinwheel until chosen.
  - **The grid** of the area piece the owner stands in (its borders from
    `buddy_area_centre`, `BuddyAreaPieceAt` in the ground file), 3-yard
    cells (larger for areas past 250,000 cells, logged): measured from the
    owner's cell outward, 600 cells a world tick while the maps are idle
    (the world update runs after the map updates finish), each neighbour's
    ground searched from one cell's rise above down 50 yards (no roofs or
    bridges), part of the area by its area id, walkable when it rises or
    falls no more than 45 degrees (a sharper step is a wall; a cell may be
    reached from another side); then distances, rooms, the traced border
    and the disc (up to 4,000 passes, or until nothing moves 1e-6) on a
    worker thread; sizes and times logged. Kept for the server's run.
  - **The paint**, per owner per area piece: every buddy in its owner's
    area paints each second, fighting or not; the walls pulse every 3
    seconds; dropped 15 seconds after the owner leaves the area; the
    entrance is where the owner entered the area.
  - **The roam action** asks `BuddyExploreNext` first; while the grid is
    being measured (or when a buddy has no way over the measured floor)
    that pick is the pinwheel's, logged once per area (a warning).

What is not built: towns (no grid there; the town visit takes over as
before); the owner entering by one piece and the grid of another; paint
shared across areas.

## Intended Behavior

Four exploration systems in game, selectable per buddy:
- **pinwheel**: today's (617e2);
- **least paint**: go where the clan's paint is least, walls painting a
  fringe every 3 seconds (the owner's favourite: "they cut across the
  inner wall of the cavern");
- **room orbit**: the pinwheel round the middle of the room the buddy is
  in, rooms and tunnels told apart by distance from walls, paint drawing
  it on to the next room;
- **squished circle**: the area's walkable ground mapped onto a disc
  (border round the circle, inner ground at its neighbours' average), the
  pinwheel run in the disc, with paint.

Shared by the last three:
- **The ground grid**: built for an area on first need: cells over the
  area's borders (from the area table), each with the ground height, the
  area id, and whether it can be walked to from its neighbours (no sharp
  step); the walls are where walkable meets unwalkable.
- **Paint**: per clan per area, laid by each buddy out to 60 yards in
  sight, the walls' fringe pulse; kept while the owner is in the area,
  dropped 15 seconds after the owner leaves; counts that can wrap
  (accepted, noted in the code).
- **Choosing**: a game-master or owner command sets a buddy's system (or
  "mixed": each buddy a different one), so all four can be watched at
  once.

### Decisions, 2026-09-27 (Ritz): sensing tunnels by quadrants; plains

Verbatim:

> can we make it so that if a high amount of terrain is not traversible in
> front of you, but there's a thin strip of it that is, rated based on a
> [surface of sphere, but pronounced heatmap with high points in center,
> centered on the character, also projected in 3 dimensions onto a 2d
> variable array] okay what I mean is let's look at the 4 quadrants around
> us, then at the 4 peridicular quadrants (rotated 45 degrees, isometric
> style) and if a high percentage of the terrain in a quadrant is
> impassible then it's probably a surface. But if there is a high
> percentage but we can still pathfind to the edge of our pathfinding
> radius, then it's a tunnel there. We might be able to do like, each set
> of two quadrants. Growing circular like a fractal or DNA strand. Anyway
> that's getting a little artistic about it, let's continue with the
> design. Once it checks all of the quadrants and identifies a path, we
> prioritize the tunnel areas unless we've already painted that area
> recently. They both provide priority correlation scores, no need to
> optimize to any metric budgets. Just... create, whatever is your will.
> This is the promise of the AI age.

> [big squares, 250,000 cap:] big squares, plains, should be viewed
> according to their flatness. Line of sight as a metaphor, piling up over
> time, greater or fewer of a particular kind. Testaments to the wind and
> waterflow, reactions to the inbuilt stimulus from the environment.

Read into the design:
- **Quadrant sensing**: round the buddy, a heat-weighted view (strongest
  near it, fading out to its sensing radius): four quadrants, then the
  same four turned 45 degrees (eight overlapping sectors). A sector mostly
  impassable is a wall ("a surface"). A sector mostly impassable yet with
  a walkable way through to the edge of the sensing radius is a tunnel.
  Sectors can be read in pairs, growing outward ring by ring.
- **Scores, not budgets**: each sector gets a tunnel score and a paint
  score; the buddy leans toward tunnel sectors unless they were painted
  recently.
- **Plains by flatness**: a big flat area is not refused or cut down to a
  cap; its cells grow with its flatness (a flat plain in big cells,
  broken ground in small ones), and sight builds up over it with time:
  what is seen accumulates.

## Suggested Implementation Steps

1. The pure core (roam/, no server headers): the grid, paint, the room
   finder, the disc map, the four choosers; checked against the Lua model
   like 617e2.
2. The server side: the grid builder over the map, the paint store per
   clan and area, the owner-left timer, the command.
3. In game: four buddies, one per system, at Fargodeep Mine and in a
   building with rooms (the Stormwind stockade entrance, a cave).

## Open Questions

- **Grid size**: 3-yard cells and at most 250,000 cells (big zone-wide
  areas get coarser cells): right, or should huge areas be refused?
- **Measuring load**: 600 ground measurements a world tick (a few
  milliseconds); a large area takes a minute or more to measure. Faster
  (more per tick) or gentler?
- **Levels**: the grid holds one floor per cell (the first walkable one
  reached from the owner), so a building's upper floor over the lower one
  is not both measured; Darnassus's stairs down are measured only where
  they don't pass under walked ground. Worth a real many-level graph
  (the navigation mesh) later?
- **Mixed**: four systems in turn by character number; should the owner
  pick per buddy instead?

## Related Issues

- **617e** parent; **617e2**; **617e1**
