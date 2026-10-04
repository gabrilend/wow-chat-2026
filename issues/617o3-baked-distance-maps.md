# 617o3 - Baked Distance Maps for Fixed Goals

## Status
- Created: 2026-10-03
- Phase: 6
- Parent: 617o
- Blocked by: 617o2 (the grid on the mesh)
- Priority: Medium

## Current Behavior

**The build-time town baker written 2026-10-03 and run on a scratch copy
of the data directory; the server's loading of it syntax-checked, not yet
built or run.**
- `tools/buddy-town-baker/buddy-town-baker.cpp` (at the project root, not
  in the module: the server build compiles every file in the module
  folder, and the baker has its own `main`) reads the area table
  (`dbc/AreaTable.dbc`), terrain (`maps/`) and mesh (`mmaps/`) files and,
  for every town piece, lays out the grid, marks floor and joins, keeps
  the largest joined stretch, and writes
  `<DataDir>/buddy-towns/<map>-<area>-<piece>.btown`. On 2026-10-03: 150
  town pieces, 931,585 walkable cells, 15 MB, 8 seconds; three Northrend
  pieces with no mesh under them get no file.
- What both sides must agree on is shared code with no server headers:
  the grid's layout and step rules (`roam/buddy_grid_rules.h`), the mesh
  questions (`roam/buddy_mesh_core.h`), which areas are towns
  (`roam/buddy_town_rules.h`: the client's flags, starting valleys
  excepted) and the file (`roam/buddy_town_file.h`). The server's own
  measuring and town test now use the same headers.
- The server (`buddies_explore.cpp`, `LoadBaked`) reads a town's file
  when its grid is first asked for, checks the layout and every mesh
  file's size and time, and on a match skips the measuring; on a mismatch
  it logs the reason and measures live.
- `scripts/bake-buddy-towns` lists the pieces at full precision, compiles
  the baker into the project's RAM exec directory when its sources are
  newer, and runs it; install step E049 runs it (skipped, and saying so,
  until E044's table is loaded at a fresh install's first start).
- Not baked, as planned: the distance maps themselves (a flood takes
  about a millisecond once the grid exists), and grids for area borders
  and docks. Accepted difference: the baker reads heights and area
  numbers from the terrain only, the live measuring with buildings.

The distance maps:
**Written 2026-10-03, syntax-checked, not yet built or run**
(`buddies_explore.cpp`, "the distance maps"; the call
`BuddyExploreStepToward` in `buddies_explore.h`). The measuring now
records which neighbouring cells a buddy can step between (the joins,
tested once per pair within the measuring's budget). A distance map is a
flood from the goal over those joins, built on first use on the asking
thread (not a worker thread: a flood of an area's cells is about a
millisecond) and kept, 64 at most. Used by: the roam action when the
pinwheel and rooms find no waypoint (a stretch toward the area's middle),
and the town visit's walks to errand people and the mailbox
(`buddies_town.cpp`, the walk across town; until the town's grid is ready
the walk is the bot module's alone, and the trace says so). Before this stage: Every trip is searched when it is needed. The pinwheel needs a
clear straight line to the area's middle and fails without one ("no sight
of the centre" in the "found no waypoint" error), and long walks in towns
go to the bot module's own long-distance walking.

## Intended Behavior

- A **distance map**: for one goal on one area's grid, each floor cell
  holds the walking distance to the goal over joined cells (a Dijkstra
  flood from the goal; diagonal steps cost 1.41 cells). Built once on a
  worker thread, kept for the server's run (the ground doesn't change),
  at most `MAPS_KEPT` maps, the least recently used dropped first.
- **Walking one**: from the buddy's cell, step to the neighbour with the
  lowest number until the goal; the steps are turned into path points
  (every few cells, straight stretches merged) and walked like any path
  (617o1's rules apply).
- **Goals with a map** in this stage: the area's middle (the pinwheel's
  "toward the middle" when it has no straight line), and the town visit's
  errand spots (trainer, vendor, repairer, mailbox, auctioneer).
- Not in this stage: area borders and docks (they need grids that span
  two areas); written here so they are not forgotten.
- **Towns baked at build time** (the owner, 2026-10-03: "could we build
  that at compile time instead?", then "yes please" to a build-time
  baker): the first visit to a town shouldn't walk the old way while its
  grid is measured. Since 617o2 a grid's floor and joins come from the
  navigation mesh alone, and the mesh is files on disk
  (`data-files/mmaps/*.mmtile`), so no running server is needed:
  - a tool built with the server (`buddy-town-baker`, a C++ program
    linking the same mesh library, Detour) reads, for every town area
    (the client's town and capital flags, as `BuddyAreaIsTown` reads
    them): its piece's borders (the area-piece table), the mesh tiles
    under it, each cell's area number from the terrain files
    (`data-files/maps/*.map`, as `scripts/generate-basic-titan-jeweler-
    spots` reads heights), the floor and joins exactly as 617o2 measures
    them, and the errand people standing in it (trainers, vendors,
    repairers, auctioneers, innkeepers, mailboxes) from the world
    database;
  - it writes one file per town: the grid, its joins and one distance
    map per errand spot, into the data directory beside the mesh
    (`data-files/buddy-towns/<map>-<area>.btown`), with a header naming
    the mesh files' sizes and dates it was built from;
  - the module loads a town's file when the town's grid is first asked
    for, in place of measuring it, and refuses (logged as an error, then
    measured live) a file whose header doesn't match the mesh files on
    disk, so a stale bake is never walked;
  - an install step runs the baker (after the world database and the
    mesh are in place); a world database change to errand people means
    re-running it, and the step says so;
  - roughly 100 towns, about 10 spots each, about 30,000 cells, 2 bytes a
    distance: about 60 MB before compression.

## Suggested Implementation Steps

1. `buddies_distmap.cpp`: build (the flood), keep (the cache), walk (the
   downhill steps), over the explorer's grid.
2. The pinwheel's fallback: when the core finds no waypoint, walk the
   middle's map a few cells instead of pausing.
3. The town visit: an errand's walk inside the town's grid uses the
   errand spot's map.
4. Log each map built (goal, cells reached, time).
5. The build-time baker: the measuring's floor and join rules moved into
   a part with no server headers (beside `roam/buddy_explore_core.cpp`)
   so the baker and the server share one copy; the baker program and its
   build target; the town file's writer and the module's reader; the
   install step. Check: a baked town's grid against the same town
   measured live in game (cell for cell, joins included).

## Related Issues

- **617o** parent; blocked by **617o2**; **617e4** (town visits)
