# 617o8 - The Painted Map: Pathfinding That Learns, Keeps Its Distance and Spreads

## Status
- Created: 2026-10-29
- Phase: 6
- Parent: 617o (pathfinding on the navigation mesh)
- Related: 617o7 (the five ways: this is a sixth, built from what they
  taught), 617e16h (the shared map of walls and buffers, the stuck rule),
  617e16k (circulation: spreading by wedges), 617e6 (exploration's paint:
  a different paint, coverage for choosing where to go), 617o3 (baked
  distance maps), 617e16l (the battleground page)
- Priority: High
- State: in progress

## Origin

The owner, 2026-10-29, after orbit's rings were mended, asked "The orbit
system is slow because we're essentially building a new kind of mmap
right?" (answer: no, orbit keeps no map; "learn the map" is the way that
builds one), and then:

> Remember we want bots to paint surfaces and collectively get better at
> navigating as we gather more data. Also they should give space to walls,
> less if they need something nearby or directly nearby opposite the wall,
> and they should spread out through an area. This is a very difficult
> path finding problem so I want to spend a lot of time and effort on
> making it powerful and performant. I'm going to make pasta now please
> continuously reiterate and improve the system until I get back. I'll
> interrupt you when i've returned and we can share our two status
> updates. We are trying to make the path finding look natural. We can
> make arcs between way points if necessary. Please open up a new branch
> for each path finding style if you'd like a blanker canvas, or handle it
> however you please. I'm switching you to high effort mode to see if it
> works. Remember, keep working until I get back.

Branches: the work stays on main, as a new choice in the sandbox's
Pathfinding list, since switching branches would swap the files under the
other session working in the same folder.

## Current Behavior

**The core built and tested 2026-10-29** (step 1 and 2):
`scripts/templates/paint-paths.js`, checked by `scripts/test-paint-paths`
(`tests/paint-paths/paint-check.js`), 12 checks, all holding. What the
test measures (it prints each number):
- **learning together**: ten bots shuttling across a field of 81 pillars
  nobody knows finish all 60 trips in about 4 minutes; refused steps by
  round of trips 362, 30, 1, 3, 2, 2;
- **space kept**: through a 16-yard gap the closest 5% of steps are 4.2
  yards from the wall (2.0 with no space wanted);
- **relaxed near the goal**: a goal 1.5 yards from a wall's face is
  reached; with the goal just across a thin wall the bot rounds its end
  at 0.6 yards (1.6 keeping full space);
- **spreading**: twelve bots leaving in one knot cross a 20-yard gap
  spread 3.3 yards (0.4 in single file without lanes and the crowd);
- **smoothness**: 3.6 degrees turned a yard, never over 240 a second;
- **speed**: 300 plans over 250,000 one-yard cells (500 yards square)
  take 4 ms in the middle case, 15 ms at the 95th percentile.

What the first runs taught, each fixed and commented where it happened:
1. **Coarse cells shut real gaps.** At 2-yard cells, painting every cell
   a pillar touched closed the 3.4 yards between pillars, and plans found
   no way. Cells are now a yard, painted by their middles.
2. **A bot kept grinding the same thing.** Each refusal now teaches at
   least one cell (the thing's footprint, or failing that the refused
   point), and the refused bot plans again.
3. **A followed point far ahead cuts inside every bend.** Bots clipped
   what their routes went round, thousands of refusals after the map was
   learned. The followed point now comes nearer until the straight to it
   is clear and keeps a yard of space.
4. **Space was too cheap.** The wall weight went from 3 to 8.
5. **A goal across a wall is near.** Only the cells near the goal used to
   relax, and a wall's end 20 yards off kept its full space. A goal within
   24 yards of the bot, straight, now relaxes the whole route.
6. **Plans in the same moment couldn't see each other.** A new route now
   joins the crowd at once.
7. **A bot painted itself in.** Refusals beside it painted its own cell
   and its neighbours. Now the refused point is never painted within a
   cell of the bot. A plan that finds no way may squeeze through painted
   walls beside the start, and a bot with no clear point ahead steps to
   the most open ground beside it.

**Step 3 built 2026-10-29**: "painted map" in the ground sandbox's
Pathfinding list (pictures 066-067). One map per part in play, a yard a
cell, built when first used. Steep ground (by the slider) and the part's
edge are known from the start. Each bot:
- plans at most when the map says to, six plans a step at most;
- follows its route in a lane of its own;
- paints the ground it walks;
- when refused, paints the doodad it hit and plans again.

The crowd is remade each second. The paint is drawn (walked ground gold,
learned walls orange), and routes as the curves walked.

The six ways on one run (the Barrens' Witchwing Slayer area, 36 bots,
wedges, 120 seconds; pictures 067-073; turning = degrees turned a yard
walked, measured for every way since this issue):

| Way              | Turning | Stuck | Refused | Turned aside /s | Spacing yd | Covered | Real time |
|------------------|--------:|------:|--------:|----------------:|-----------:|--------:|----------:|
| painted map      |     6.3 |     0 |      54 |              24 |       19.1 |     26% |     16 s  |
| flow field       |    11.7 |     0 |      93 |              45 |       24.6 |     26% |    108 s  |
| orbit            |    13.4 |   224 |      53 |              45 |       12.9 |     23% |           |
| potential field  |    18.3 |     0 |      75 |              80 |       18.9 |     25% |           |
| learn the map    |   113.1 |     0 |      64 |             103 |       16.5 |     20% |           |
| graph and A*     |   120.4 |     0 |      63 |              63 |       22.5 |     20% |           |

(Real time: seconds the picture tool took for the 120 seconds of play.)

A* and learn wobble. Two causes:
- **The steered-to point flipped from step to step.** Now it is held
  while more than 3 yards off and in sight: A* fell to 92.9 (picture 073).
- **Their routes graze steep edges.** They keep no distance, so each step
  the bot's own look-ahead turns it off the edge and its route point pulls
  it back. This is the "rubbing" the owner saw on 2026-10-28, and the
  painted map's space from walls is what removes it.

Bots on the painted map still bunch at one narrow notch (picture 067),
where three of them explore a peninsula (617e16i).

**Step 4 built 2026-10-29**: the C++ twin,
`patches/B036-mod-buddies/mod-buddies/src/roam/buddy_paint_paths.h`, step
for step the script's. Its test, `scripts/test-buddy-paint-paths`, runs the
page's own courses with the same random numbers, and all 12 checks hold.
Beside the script's numbers:
- the same space through the gap (4.2 yards, 2.0 without);
- the same thin-wall rounding (0.6 against 1.6);
- the same 20,707 cells opened a plan;
- a spread of 3.2 yards against 3.3;
- plans in 2.7 ms against 4.0;
- the pillar runs differ in detail (the two languages' sine and cosine
  differ in the last digit, and long walks drift apart), and both learn
  the field.

**Step 5, in game, written 2026-10-29, not yet compiled**: `.buddy path
paint` (the buddy module's path switch, `buddies_path.cpp`; `Way::Paint`
in `roam/buddy_path_ways.h`).
- **One map per region.** The world is cut into 512-yard regions, each
  with 96 yards of margin, a yard a cell. A region's map is made when a
  buddy first walks there by the painted map, and is shared by every buddy
  there. At most 6 are kept, the least recently used let go first.
- **It starts knowing nothing.** Each tick a buddy paints the cell it
  stands in. A step the navigation mesh refuses paints the spot where the
  straight leaves the mesh, found by halving the straight four times, and
  the buddy plans again.
- **Lanes, the crowd and arcs.** Each buddy gets a lane and a replanning
  jitter from its character number, the crowd is remade each second a
  region, and the followed point is re-aimed every half second (arcs as
  short straights).
- **Its limit.** A trip whose start or goal is off its region's map (about
  190 yards near a border) is given up and the reason given, as a waypoint
  the mesh refuses is.
- **Checked.** `.buddy path` counts its walks in the same table. A
  syntax-only check against the server's headers passes.

Not built: keeping the paint between runs (it is lost at a restart;
question 1).

Before this, the five ways (617o7) each lacked something asked for here:
- "learn the map" remembers bumps, but each plan ignores walls' nearness
  (paths graze trunks and cliff edges);
- flow and A* see only what is known to block, and keep no distance from it;
- none spreads bots that share a target; all draw corners, not arcs.

## Intended Behavior

**One painted map per area, shared by every bot** ("collectively get
better at navigating as we gather more data"). Fine cells (2 yards) over
the area, each holding what the bots have learned:
- **unknown**: nobody has stood there; assumed walkable, costing the same
  as ground already proven (the unknown premium is a lever, 0 by default
  since 2026-10-30: a premium finds the fastest way, which doesn't look
  like people walking);
- **painted**: a bot has walked it (the count of walks kept too);
- **wall**: a step into it was refused, or a doodad it belongs to was found
  by a bump (the whole doodad is painted at once);
- **steep**: too steep by the ground's own heights (known before any walk,
  as the navigation mesh knows it).
Every bot paints as it walks and every bot plans by the same map, so each
bump teaches all of them and the bumps a minute fall as the area is
learned.

**Space from walls** ("give space to walls, less if they need something
nearby or directly nearby opposite the wall"). Each cell also holds its
clearance: the yards to the nearest wall or steep cell. It is worked out
once by a distance transform and mended locally when a wall is painted. A
cell nearer a wall than the wanted space costs more, the more so the
nearer it is. The extra fades near the bot's goal (within the relax
distance, measured straight, so a goal just across a wall counts as near):
a bot fetching something by a wall walks up to it, and one whose goal is
just across a wall walks close round the wall's end, not wide.

**The space bubble shrinks in clutter** (2026-10-30, Open Questions 2):
the wanted space between a bot and others (4 yards) is smaller on
uneven, crowded ground, by how cluttered the ground around the bot is
(the share of wall and steep cells near it), and grows back to the full
4 yards in the open.

**Levers and data sources first** (the owner, 2026-10-30, Open Questions
2): every number here is a lever that can be pulled, and the map is one
data source among several, so an ultimate pathfinding can later combine
them. A second source is planned, the **smap** (named 2026-10-30): a
stand-in walking the world taking pictures from at least two angles of
each place (photogrammetry-like, coarser; mountain tops not needed for
now), to paint the world before any buddy walks it. Trails (worn ground
cheaper to walk) wait on it.

**The steering point follows the ground** (2026-10-30, Open Questions
2): a bot steers toward a point on its route ahead of it, nearer in
clutter (tracing the route's turns) and farther in the open (rounder
corners), by the same clutter measure as the space bubble.

**Spreading** ("they should spread out through an area"):
- bots heading the same way plan round each other: where bots stand and
  where their next few yards of route run costs a little more (the crowd),
  so they take side-by-side lanes instead of single file;
- the targets themselves keep spreading by the wedges of 617e16k.

**Natural paths** ("We are trying to make the path finding look natural.
We can make arcs between way points if necessary"):
- the route of cells is pulled tight into a few long straights, but never
  closer to walls than the route itself ran (the space is kept);
- the bot then follows a point a few yards ahead along it, turning at a
  limited rate, so every corner becomes an arc and no step snaps.

**Powerful and performant**:
- the planner reuses its memory (no fresh arrays per plan);
- a plan is made only for a new goal, a wall painted near the route ahead,
  or now and then for the crowd;
- the measures report the planning time a second of play costs, so a
  slowdown shows.

**Measures**:
- bumps a minute, first minutes against later ones (the learning);
- share of the area painted;
- clearance kept (median yards to the nearest wall where bots walk);
- spacing;
- smoothness (degrees turned a yard walked);
- plans a second and milliseconds a plan.

## Suggested Implementation Steps

1. The core as a pure script shared by the page and its test
   (`scripts/templates/paint-paths.js`, inlined into the sandbox page as
   `ground-decode.js` is): the map and its paint, clearance, costs, the
   planner, pulling tight, following with limited turning, the crowd.
2. Its Node test (`scripts/test-paint-paths`):
   - courses with walls the bots don't yet know: a corridor of pillars, a
     wall with a gap, a goal against a wall, a goal just across a thin
     wall, a dozen bots through a gap;
   - checks that bumps fall over repeated trips, that space is kept and
     relaxed at the goal, that lanes spread, that turning stays smooth;
   - planning time measured.
3. The sandbox: "painted map" in the Pathfinding list, the paint drawn
   (walked, walls, clearance), routes drawn as the curves walked, the
   measures above, pictures filed, page backups.
4. The buddy module's C++ core and its offline test, matching the script.
5. In game (later): the paint kept per area and saved between runs, so
   the clan's knowledge grows over days; a refusal is the mesh's.

## Open Questions

1. **Kept between runs, and whose** (answered 2026-10-29): asked whether
   every buddy on the server should share one painted map per area,
   saved to disk so it keeps improving over days, or each clan keep its
   own, the owner: "yes yes and yes." One map per area, shared by every
   buddy on the server, saved and kept. (The module already keeps one per
   512-yard region of a map for the whole realm, saved every 10 minutes
   and at shutdown, so this is what is built.)
2. **The numbers**: wanted space 4 yards, relaxed within 10 yards of the
   goal; unknown ground 15% dearer; the crowd's weight; following 6 yards
   ahead and turning at most 240 degrees a second. Which feel natural?
   **Answered 2026-10-30** (the owner, word for word, number by number):
   - the 4 yards: "yes but on un-even terrain (lots of obstacles) the
     personal space bubble is reduced until they navigate through that to
     a more open area. This might be overwritten with the movement map
     caching we're going to do with the stand-in walking around the map
     taking screenshots of everything until we've fully painted the
     world, similar to photogrammetry style but not as detailed. So long
     as we get two angles of the same area, that should be good, and we
     don't have to do things like the tops of mountains and such for now.
     Right now for pathfinding we're kinda building a bunch of systems and
     tools that we can combine into an ultimate pathfinding solution once
     we've build all the mechanics, so focus on making levers that can be
     pulled and data sources that we can pull from."
   - the unknown premium: "this would make sense if we were trying to
     find the fastest way to walk somewhere, but it doesn't look very
     natural. Bots should be more like people, and they will be once
     we've built out their "visual map" of the area. Except "vmaps" are
     already taken, hmmmm...."
   - the 6 yards ahead: "not sure about this, what does that mean?"
     Explained in conversation: the route a bot plans is a line of
     cells; the bot doesn't walk to each cell, it steers toward a point
     on its route a few yards ahead of itself (6 yards, brought nearer
     when the straight line to it isn't clear). The farther that point,
     the rounder and lazier its corners; the nearer, the more it traces
     the route's exact turns. **Answered 2026-10-30**, asked whether to
     keep it, make it a lever, or vary it with the ground, word for word:
     "nearer in clutter, farther in the open." The steering point's
     distance follows the same clutter measure as the space bubble.
   - the 240 degrees a second: "sure I guess".
   What follows (in Intended Behavior): the personal space shrinks on
   crowded, cluttered ground and grows back in the open; the unknown
   premium is set to none by default and kept as a lever; and the
   pathfinding work is aimed at levers and data sources to be combined
   later, the stand-in's photographed map among them (the "visual map";
   named 2026-10-30 by the owner, word for word: "smap works": the
   **smap**, beside the server's own vmaps and mmaps).
3. **Trails**: should well-walked ground grow cheaper, so trails form
   (natural, as deer paths are), or would that undo the spreading?
   **Answered 2026-10-30** (the owner, word for word): "yes, but this
   waits on the smaps to identify trails and such." Trails form, once
   the smap can tell where they are; not built before it.
   Measured 2026-10-29 on the sandbox (pictures 067 and 074-076; the
   address can now set the map's numbers, `paint.UNKNOWN=0`):

   | Unknown premium | Spacing (yd) | Covered |
   |---|---|---|
   | 15% (as now) | 19.1, 19.3 | 26%, 26% |
   | none | 22.6, 19.0 | 27%, 28% |

   The premium is not what bunches the bots: one setting varies 19.0 to
   22.6 yards from run to run. Coverage leans slightly to no premium,
   within that noise. So a stronger trail effect would have to be judged
   by eye, or over longer runs.

   Also tried and undone the same day: choosing each wedge waypoint as the
   least-walked of five (by the paint's counts, other bots' waypoints
   counted against it), exploration's "least paint" (617e6) inside the
   wedges. Coverage rose barely (27%, 28%) and spacing fell to 15.8 and
   14.1 yards, since several bots chased the same fresh corner (pictures
   079-080). The template keeps a note of it where it was.
4. **Tiny parts of an area** (picture 078): on the Burning Steppes'
   Firegut fence the part in play was a 260-square-yard pocket, and all 36
   bots were crammed into it (spacing 2 yards, 155 degrees turned a yard).
   No way of finding a path spreads 36 bots through a sliver. Should a
   part that small be skipped as the part in play (the bots taking the
   next part), or take only as many bots as it has room for?
   **The owner, 2026-10-29:** "we do not have to have maps for the
   floating asteroids in the Twisting Nether surrounding Outland. We can
   figure those out as we go, no need to store a baked map for them."
   So small floating pieces of ground get no stored map ahead of time;
   they are painted live as bots walk them. The Firegut pocket itself (a
   small part of a big area, where many bots are sent at once) is still
   to be asked again: how many bots it should take.
   **The owner, 2026-10-30, word for word:** "sounds like they were
   clumped up for some reason. Why were they all trying to touch the
   same waypoint? Also, creatures in WoW can pass through each other so
   it's probably not too big of a concern." Why (read from picture 078's
   notes): they weren't chasing one waypoint. The sandbox picked as the
   part in play the 260-square-yard pocket where it put the player
   ("part 4 of 6"), instead of the 47,569-square-yard area picture 077
   used, so every wedge target of all 36 bots fell inside a pocket about
   16 yards across. The fault is in how the part in play is chosen, to
   be mended there; and since creatures pass through each other, bots
   sharing a small spot is not itself a fault.
