# 617o7 - Five Ways to Find a Path, Side by Side

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617o (pathfinding on the navigation mesh)
- Related: 617e16h (stuck, back out, orbit: the sandbox's current way),
  617e16 (the sandboxes), 617e17 (the army that tries them in game),
  136d (the test realm, branched off a living profile), 617o3 (baked
  distance maps), 617o5 (orbiting)
- Priority: High
- State: in progress

## Origin

The owner, 2026-10-28:

> okay can you create at least 3-5 radically different pathfinding
> solutions with equivalent levels of complexity? then, make sure that all
> of them are viewable in-game. I want to test them myself.

And, asked how they should reach the bots in game: "Module switch, one
compile."

## Current Behavior

**Step 1 built 2026-10-28** (pictures 057-061): the ground sandbox's
"Pathfinding" choice (`way=` in the address) runs any of the five for
every bot (`scripts/templates/ground-sandbox.html`, the five-ways
section). The planning grid is the ground's points over the area in play's
box. Flow fields are kept per target and per state of learned obstacles;
A* routes are planned again when the target, the learned obstacles, or 5
seconds pass (keying either on the map's open cells, which grow every
step, made the first runs plan every step: 96,424 routes in three minutes,
a hung flow-field run). Three minutes each on the Witchwing Slayer area:

| Way | Routes or fields | Steps with no way | Spacing |
|---|---|---|---|
| orbit | (orbits: 055, 056) | low | 16-24 yd |
| flow field | 5,310 fields | 0 | 13.8 yd |
| graph and A* | 4,308 routes | 0 | 12.4 yd |
| potential field | none | 0 | 14.7 yd |
| learn the map | 2,919 routes | 60 a second | 18.8 yd |

**Step 3, its first half, built 2026-10-28**: the five in the buddy
module's own arithmetic, with no server code
(`patches/B036-mod-buddies/mod-buddies/src/roam/buddy_path_ways.h`): a
grid of open and blocked cells; the flow field, A* (for "learn", over the
learned cells alone), the potential step, the stuck check, the doubling
back-out and the walk round; and a walker, one per buddy, holding its way
and what it remembers between steps, which gives the next point to walk to
and is told when the world refused a step. The A* here plans over the grid
of cells, not over a sparse skeleton graph as Intended Behavior says: the
same answer at this size, simpler to build first; the skeleton is still
open. Its quick test, `scripts/test-buddy-path-ways`
(`tests/buddy-path-ways/path-check.cpp`), walks all five over three
made-up courses on an 80-yard grid (a 60-yard wall with a gap, a cup open
toward the start with the target behind it, a grove of single trees),
with a world that refuses blocked ground as the mesh does. Its first runs
found four faults, each now fixed and commented where it was:

- a diagonal step past a wall's end slipped through the corner of a
  blocked cell (flow stood at the wall's end ten minutes): a diagonal now
  needs both cells beside it open;
- the line check sampled points and missed a line clipping a corner (A*
  walked into a cup's rim): it now walks every cell the line crosses;
- orbit's stuck check fired a second into each walk round (walking round
  isn't getting closer) and backed it out again, forever: the check waits
  while it backs out or walks round, for up to 15 seconds, as in the
  sandbox;
- potential's kick lasted one step and was pulled straight back into the
  dip: it now holds its direction 1.5 seconds, as in the sandbox;
- orbit's walk round (2026-10-29, the owner asking which part of
  pathfinding to iron out) turned in toward the obstacle every step,
  felt or not: a yard or two off the wall after backing out, nothing
  stopped the turn and it walked rings 3 yards across until its 15
  seconds ran out (269 steps round the wall). Now it walks in at its
  target until the way is blocked, turns side-on, hugs what it feels
  beside it within 4.5 yards, and rounds a corner by 30 degrees a step
  once it no longer feels it (121 steps). A first mend that began
  side-on at once never met the wall and rounded a corner it had never
  touched, in a ring 15 yards across (663 steps). The sandbox page's
  orbit had the same fault and has the same mend (picture 065).

What the test measures now (`scripts/test-buddy-path-ways` prints it,
steps of half a second): flow and A* arrive by the shortest way and never
bump; learn arrives in 3 to 4 times their steps, bumping as it learns;
orbit arrives in about 4 times their steps round the wall (121 steps), 8
round the cup (189); the potential field crosses the grove but stays trapped by the wall
and the cup. That last is the method's own limit (forces with no route and
no memory of where it has been), not a fault: the test checks that it is
trapped, so a change shows.

**Step 3, its second half, written 2026-10-28, not yet compiled**: the
server side (`buddies_path.h`, `buddies_path.cpp` in the buddy module,
registered in `buddies_loader.cpp`, called from the roam action in
`buddies_roam_strategy.cpp`). `.buddy path <orbit|flow|astar|potential|
learn|mesh>` picks the way for the speaker's buddies (mesh, the default,
is the walking as before); `.buddy path` alone says which, and a table of
each way's walks since the server started (arrived, given up, mean
seconds, refused steps, stuck checks, orbits, kicks, plans). With a way
picked, each roaming waypoint is walked by it: a grid round the buddy and
the waypoint (cells 3 yards apart, coarser for a far waypoint, at most 80
across, 24 yards of margin) is filled outward from the buddy's own cell
like water, a cell open where the mesh has ground near its middle reached
by a clear straight walk from its neighbour; every half second the walker
gives the next point, which is moved onto the mesh and walked in a
straight line (no server path search), unless the mesh says the line
crosses a wall, a cliff or a gap: then the step is refused (not walked,
the buddy stopped, the way told). Arrived within 3 yards; given up after
90 seconds, the waypoint dropped as one the mesh refuses is. A syntax-only
check against the server's headers passes; the owner's compile is the
real test.

Not built: step 2's headless comparison tool; step 4 trying them in game
(after the compile, on the test realm, with the army of 617e17).

## Intended Behavior

Five ways, each a whole answer to "how does a bot get from here to its
target", different in kind, of about the same size to build:

1. **Orbit** (the bug algorithm, the sandbox's present way): straight at
   the target; blocked or slow, back out and walk round the obstacle,
   keeping it on one side, until the target is in sight. No plan, no map
   beyond what it touches.
2. **Flow field**: from the target, the walking distance to every point of
   the area, spread over the walkable ground once (a breadth-first flood);
   every bot steps downhill on it. Shared by every bot with the same
   target; never stuck in a pocket, because the field already went round.
3. **Graph and A***: a sparse graph of places (the area's skeleton: the
   middle lines of its walkable ground, joined where they meet), the
   cheapest route through it by A*, then pulled tight (skipping nodes while
   the next is in sight). Plans the whole way, then follows it.
4. **Potential field**: the target pulls, every obstacle pushes (by its
   distance, from a distance map of the area's walls), the bots feel each
   other; a bot follows the sum. No route at all, only forces; local
   minima broken by a random kick.
5. **Learn the map** ("you navigate and then it is known", 617e16h): the
   bots start knowing nothing but what they have walked and bumped; each
   plans by A* over its knowledge (unknown ground assumed open), walks, and
   plans again whenever it learns a cell it had wrong.

Each is built twice:
- **In the ground sandbox**: a "Pathfinding" choice on the panel, so the
  five can be watched on the same ground, with the same measures (times
  stuck, yards walked per yard gained, spread, cover).
- **In game**: in the buddy module, behind one switch, `.buddies path
  <way>` (for one buddy, a partner's buddies, or the army of 617e17),
  each way computing on the module's own copy of the walkable ground
  (`buddies_navmesh` and the zone's grid) and giving the bot module its
  next point to walk to. One compile (the owner's), then switched live.

## Suggested Implementation Steps

1. The five in the sandbox, one at a time, each a committed version with
   its picture and page backup.
2. Their comparison: the same zone and fence, five runs, a table of the
   measures (a tool runs them headless).
3. The module patch: the switch command, each way's planner over the
   walkable grid, the point handed to the bot's movement; its quick tests
   (each planner on a small made-up grid, offline).
4. The owner's compile; trying them in game with the army (617e17), on
   the test realm (136d).

## Open Questions

1. Which measures decide the better way: least stuck, least wasted
   walking, most even spread, or how it looks (the owner's eye)?
2. The potential field can't get round a long wall or out of a cup: keep
   it as it is (a way that shows what forces alone do), or give it a
   memory (cells it has stood in push too, so it can't sink back into the
   same dip)? With the memory it is no longer "no map at all".
3. ~~The sandbox's flow and A* may cut the same corners the module's
   first version did: mend them there too?~~ Answered 2026-10-29 (the
   owner: "Okay let's do all of those things"): mended in the sandbox the
   same way (a diagonal needs both points beside it open; the line check
   walks every point it crosses; flow's look-ahead keeps to a clear
   line), pictures 062-063. The corner rule asks whether a point is open
   two or three times as often, so each point's answer is now kept until
   what is known changes (without that, 120 seconds of play overran the
   picture tool's 90).
