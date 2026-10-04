# 617e2 - The Roaming Core in Game

## Status
- Created: 2026-09-27
- Phase: 6
- Parent: 617e
- Blocked by: None (pure computation; 617e1 calls it)
- Priority: High

## Current Behavior

**Runs in game** (seen 2026-10-03, Mozonn in Ammen Vale): the pure core
(built 2026-09-27, cross-checked against the Lua model) drives the "buddy
roam" action in `buddies_roam_strategy.cpp` (step 2: the ground's
callbacks in `buddies_roam_ground.cpp`, the area centres, each buddy's
state), with the rest roll on arrival (step 4: a meal, or sitting by a
campfire without food). Seen wrong in game the same day: walks through
walls and a buddy standing still for good, both from the planner judging
ground differently from the walking; answered by 617o (the navigation
mesh decides), which changes this file's walking step.

**The movement trace (step 5) built 2026-10-03 and used in game**
(`.buddy trace <name>`, lines in Playerbots.log): `buddies_trace.cpp`, the
`BuddyTrace` call in `buddies.h`, and trace lines in the roam action at
the waypoint pick, each leg order, the detour's start and end, and the
meal's start.

- **The model**: `src/lua-basic/lib/buddy-roam.lua` (the "waypoints"
  reading, the owner's settings), drawn and measured by
  `scripts/generate-buddy-roaming-gifs` (`docs/HTML/buddy-roaming.html`).
- **The core**: `modules/mod-buddies/src/roam/buddy_roam_core.h` and
  `.cpp`. Plain C++17 with no server headers; its functions and
  structures are listed in `buddy_roam_core.info.md`.
  - The world is reached through four ground questions (`Ground`: the
    height from just above a hint, whether a waypoint may stand at a spot,
    the distance to the first wall along a bearing, whether a line stays
    inside the area's walls).
  - `Begin` starts a buddy.
  - `NextWaypoint` holds the model's rules: the pinwheel, the Y rule with
    its slide and carried value, piercing the middle (after two inward
    rolls in a row, a Y at or under 25 crosses to the far side and reverses
    the direction), crowding, the 10-yard floor, openings, the turning
    point with two planned legs, and the monster nudge (`LurePoint`: a
    straight trip that misses a monster's aggro radius by at most 25 yards
    bends through a point 70% of the radius from the monster; the caller
    hands in the monsters as `Mob`s with the server's own aggro range).
  - `PlanPath` is the planner: test points one body width apart with
    shoulders, the step test, half-cosine bulges on the cheaper side, and
    five bows.
  - `RestChance` is the rest chance.
  - The numbers are one `Settings` table. It is worked in double
    precision like the model, and hands back floats.
  - Roads are not weighed (the server has no road data).
  - It compiles with the module under the last beta build's settings. The
    module is copied whole into the build tree (B036 `cp -r`, its check
    `diff -rq`), and the server collects module sources recursively, so
    `roam/` is included.
- **The cross-check**: `scripts/test-buddy-roam-core`.
  - It builds the core and `tests/buddy-roam-core/cross-check.cpp` with the
    system g++ (`-Wall -Wextra -Werror`) into `tmp/tmp/`.
  - It makes 600 situations of each kind per drawn map (the gallery's
    cluttered area and its tunnel chamber, both described once in
    `tests/buddy-roam-core/drawn-maps.lua`, with the cluttered area's
    monsters from the gallery's monster scene). The kinds are a waypoint
    pick with its path (two sets: the original rules, and piercing on with
    the map's monsters, Y and the inward count drawn low so crossings
    happen), the planner alone on trips whose ends see each other, the
    start, and the rest chance.
  - Each waypoint situation carries its own recorded random numbers. The
    Lua model (`tests/buddy-roam-core/lua-driver.lua`) answers the same
    situations with the same numbers.
  - The comparison covers:
    - the waypoint, to 0.01 yards;
    - the bearing, to 1e-4 radians;
    - the Y percent, the crowding count, and how many random numbers were
      drawn, exactly;
    - the direction afterwards, the inward count, the crossings and
      whether the trip was lured, exactly, and the lure point to 0.01
      yards;
    - every path point, to 0.01 yards.
  - A different path passes only when it is the model's path reflected
    at the same cost, across the line through the midpoints of the two
    paths' first points and of their last points (usually the straight
    trip; a detour round an obstacle right at the start pushes the first
    point sideways, found 2026-09-27). A mirror-image choice on
    flat ground ties exactly, and the last bit of rounding picks the side
    (LuaJIT's sine and the C library's may differ there).
  - Result 2026-09-27 (with piercing and monsters): 3,680 checks passed
    and none failed.
    - 54 of them are situations where both sides refuse (a buddy placed out
      of sight of the centre, which a real buddy never is).
    - 6 are mirror-image ties.
    - The situations included 243 crossings of the middle and 600 lured
      trips (with eleven monsters on the map, nearly every trip passes
      near one).
  - Planted bugs are caught. Crowding pushing Y away from the middle
    failed 309 checks. Shoulders a tenth as wide failed 536. A crossing
    that doesn't reverse the direction failed 243; the lure point on the
    far side of the monster failed 600. Accepting any
    same-cost path of the same length as a tie let 39 of the second bug's
    paths through, so ties now require the exact reflection.
- **The model changed to match the core's one question**: the model's
  lure point had to keep its walking margin off rocks only; the core asks
  its ground whether a place is clear, which includes the area's edge. The
  model's lure point now keeps the margin off the edge too, so the two mean
  the same (the gallery's monster animation may change slightly when
  regenerated).
- **Where the model and the core may differ**: the core tests the line
  between two test points against the area's walls, while the model tests
  only the test points. On a trip whose ends don't see each other, the core
  bulges wider round a concave corner. It never plans such a trip (a
  turning point splits it), so the check covers only trips in sight.

**Area centres from the map files, built 2026-09-27, not yet run.**
`scripts/generate-buddy-area-centres` reads the server's map files
(`data-files/maps`, where every map is cut into squares about 33 yards
across, each labelled with its area id), one process per processor, and
writes install step E044 (`sql/basic/db_world.src/27-buddy-area-centres`,
world table `buddy_area_centre`): one row per separate piece of an area on
a map (2,606 rows, 2,008 areas on 66 maps, 215 areas in more than one
piece), with the piece's borders, its square count and its middle (the
average of its squares; moved to the nearest own square when that lands on
another area, 146 times). Fargodeep Mine: map 0, area 57, one piece of 49
squares, x -10133.3 to -9766.7, y 100 to 300, middle (-9925.5, 218.0). In
game `BuddyAreaCentre` (`buddies_roam_ground.cpp`) loads the table once
and takes the piece the owner stands in; the middle's height is the ground
found searching down from 10 yards above the owner. The earlier flood-fill
search in game is gone. Tested by `scripts/test-basic-sql-in-ram` (apply,
re-apply, revert) and a check in `scripts/validate-basic-state`.

## Intended Behavior

The model's waypoint pinwheel and path planner, in C++ in mod-buddies,
over the real world:
- **The area**: the named area the owner stands in (its area id). Its
  centre comes from the area's borders, worked out when the server is
  installed (owner, 2026-09-27: "find the borders of the area, then
  calculate it's rough center from that [...] We could even pre-calculate
  the midpoints at compile time"): the table above. Its edge along a
  bearing: step outward from the centre until the
  area id changes or the ground steps sharply (the planner's step test):
  "the first wall along the line".
- **Waypoints**: the owner's rule. The bearing turns a tenth of a circle a
  waypoint in the buddy's own direction; Y is a whole number 1..100
  (percent of the way to the edge), moved 1..20 in or out at even odds,
  never under 10 yards from the centre; a spot within 5 yards of another
  buddy or a player moves Y 10 points toward 50; a blocked spot slides
  along the bearing; an opening 20 yards longer within half a step pulls
  that waypoint into it; a walled way turns at a point in sight of both.
- **Paths**: the owner's planner: test points one body width apart (twice
  the race model's bounding radius), the ground height at the centre and
  shoulders from the map's height lookup, searched from just above the
  last point (not from the sky, so a bridge overhead is not read); a
  sharp step is bulged round (half-cosine ease, straight run, ease back);
  five bows weighed by length, grade squared and (later) road.
- **Rest**: on reaching a waypoint, sit to eat or regenerate with chance
  (share of health missing) / 2.
- The same numbers as the model: its named constants, one table.
- A test compiled without the server runs the C++ core and the Lua model
  on the same drawn map with the same random numbers and requires the
  same waypoints and paths.
- **A movement trace, for watching one buddy in game** (the owner,
  2026-10-03, "let's build this", after Mozonn, a level-1 buddy in Ammen
  Vale, kept walking between exactly two fixed spots about 5 yards apart
  and nothing in the logs said why: roaming logs only its failures).
  `.buddy trace <buddy name>` (game masters) switches it on for one
  buddy, `.buddy trace off` for all. While on, the buddy's movements are
  written into the bot module's own log (`Playerbots.log`), interleaved
  with that log's lines of which action the bot ran, so each line of
  movement sits next to the action that caused it:
  - every half second: where it stands, whether it is moving, where its
    current movement is headed, and which kind of movement holds it (the
    server's movement generator: a point, a follow, a chase, idle);
  - a line whenever that destination changes, with the distance from the
    previous one, so a back-and-forth shows as two destinations taking
    turns;
  - from roaming itself: each waypoint picked (and by which mode), each
    walking leg ordered, each detour begun and ended, each meal begun.

## Suggested Implementation Steps

1. `modules/mod-buddies/src/roam/`: the core as plain C++ with no server
   headers (points, the waypoint pick, the planner), taking the ground as
   two callbacks (height at a point, area id at a point).
2. The server side: the callbacks over `Map::GetHeight` (with a z) and
   `Map::GetAreaId`, the area centre cache, each buddy's roaming state.
3. The cross-check: a small program built with the system compiler, fed
   the cluttered map of the gallery, compared with the Lua model's output.
4. The rest chance on arrival (playerbots' food / drink actions, or a sit
   emote and the regeneration of sitting).
5. The movement trace: `modules/mod-buddies/src/buddies_trace.cpp` (the
   command, the set of traced buddies, the half-second sampler on each
   player update) and its one call for other files (`BuddyTrace`, in
   `buddies.h`), called from the roam action at the waypoint pick, the
   leg order, the detour and the meal. Writing to the "playerbots" log
   channel puts the lines in the same file as the bot's action lines,
   whose engine keeps its last-action record private.

## Open Questions

- **Baked paths for fixed places, live paths for moving targets** (the
  owner, 2026-10-03, "for another session"): "the world is static and
  baked with it's navmeshes and such. I'm thinking pathfinding between
  areas, pathfinding in towns, and other similar places could use a baked
  pathfinding map. Then, when we're fighting monsters or chasing down
  dynamically moving NPCs or other such things, then we'd do path-based
  calculations with straight-line paths updated every half-second or so,
  and lerping the orientation to the intended direction over 2/5ths of a
  second." A baked map here would be a distance-to-destination number in
  every cell of the exploring grid (a Dijkstra map; about 290 KB per
  destination per area at 3-yard cells), stepped down by its gradient. It
  would also end the pinwheel's "no sight of the centre" failure, since a
  distance-to-middle map gives a walkable way toward the middle from
  anywhere. Which destinations get a map (area middles, area borders,
  docks, trainers, town errand spots) is not yet listed.

- **One map description**: the drawn maps now live twice, in the
  generator and in `tests/buddy-roam-core/drawn-maps.lua`. Should the
  generator read the test's file, so they can't drift apart?
- **Ties in game**: on real ground exact mirror ties are rare, but on a
  flat floor the left and right bows cost the same, and the last bit of
  rounding picks one. Should the core prefer a fixed side on a tie (say,
  the buddy's own circling direction), so the choice is by design?

## Related Issues

- **617e** parent; **617e1** walks what this returns; **617e3**
