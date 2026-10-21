# buddy_roam_core (issue 617e2)

Where a roaming buddy goes next inside its owner's named area, and the path
it walks there. Plain C++17 with no server headers; the world is reached
only through the four `Ground` questions, so the same code runs in game and
on the drawn maps of the design animations. Held to the Lua model
(`src/lua-basic/lib/buddy-roam.lua`, the "waypoints" reading with the
owner's settings) by `scripts/test-buddy-roam-core`.

## Structures

### `BuddyRoam::Point`
A place in the world.
- `x`, `y` (float): yards across.
- `z` (float): yards up. In a planned path, the ground height there.

### `BuddyRoam::Ground`
The four questions asked of the world. Each is a `std::function`:
- `height(float x, float y, float zHint) -> float`: the ground height,
  searched down from `zHint + 2` so a bridge overhead is not read. A very
  low value (below -100000) means no ground.
- `clear(float x, float y, float z, float clearance) -> bool`: may a
  waypoint stand here. It must be inside the area and `clearance` yards clear
  of anything standing up from the ground and of the area's edge.
- `edgeAlong(float cx, float cy, float cz, float bearing) -> float`: yards
  from the centre along `bearing` (radians) to the first wall or the edge.
- `seenThrough(Point a, Point b) -> bool`: whether the straight line stays
  inside the area's own walls. Rocks on the floor don't count. The end
  point `b` is tested too, because the obstacle test uses this for each test
  point.

### `BuddyRoam::Rng`
`std::function<double()>`: random numbers, 0 <= r < 1.

### `BuddyRoam::Settings`
The owner's numbers (2026-09-27). All are floats (yards or radians) unless
marked int32.

| Field | Value | Meaning |
|---|---|---|
| `turn` | a tenth of a circle | Bearing turn per waypoint |
| `yChangeMin`, `yChangeMax` (int32) | 1, 20 | Y rule step, in percent points |
| `nearYards` | 10 | No waypoint closer to the centre than this |
| `clearance` | 3 | A waypoint's distance from obstacles and the edge |
| `crowdYards` | 5 | Someone this close to a new waypoint moves its Y |
| `crowdShift` (int32) | 10 | How far the crowding rule moves Y toward 50 |
| `openingYards` | 20 | A line this much longer within half a turn counts as an opening (0: off) |
| `stepRise` | 0.6 | A height change must stand out by this much to be an obstacle |
| `slopeWeight` | 6 | Path cost per yard of grade squared |
| `maxBulge` | 16 | Largest detour bulge before that side is given up |
| `rampMin` | 3 | Shortest ease into or out of a detour |
| `maxDetours` (int32) | 8 | Detours allowed per candidate path |
| `piercePercent` (int32) | 25 | After two inward rolls in a row, a Y at or under this crosses the middle (0: off) |
| `lureReach` | 25 | A trip missing a monster's aggro radius by at most this bends through it |
| `lureDepth` | 0.7 | How far in from the radius's edge the bent trip passes (share of the radius) |

### `BuddyRoam::Mob`
A monster near the buddy that would attack it on sight.
- `at` (Point): where it stands.
- `aggro` (float): its aggro radius against this buddy, in yards (the
  server's own figure).

### `BuddyRoam::Area`
- `id` (uint32): the area's id.
- `centre` (Point): found once. In game, the average of the grid points
  that share the id.

### `BuddyRoam::Buddy`
One buddy's roaming state, kept between waypoints.
- `angle` (float): the pinwheel's own bearing from the centre, in radians.
- `spin` (int32, +1 or -1): which way it circles.
- `yPercent` (int32, 1..100): the Y rule's number. Meaningful once
  `hasWaypoint` is true.
- `body` (float): yards wide, twice the race model's bounding radius.
- `waypoint` (Point) and `hasWaypoint` (bool): where it is going.
- `path` (vector of Point): the planned test points, start first and waypoint
  last.
- `pathIndex` (size_t): the next point to walk to.
- `crowdMoves` (uint32): how often the crowding rule moved its Y.
- `inward` (int32): inward Y rolls in a row (piercing counts them).
- `pierced` (uint32): how often it crossed the middle.
- `lured` (bool) and `lurePoint` (Point): whether this trip bends through a
  monster's aggro radius, and where.

## Functions

### `Begin(Buddy&, Area const&, Point const& at, Rng const&)`
Starts a buddy on an area. It draws the direction (one random number;
below 0.5 means +1), sets the bearing to where the buddy stands, and clears
the waypoint and path.

### `NextWaypoint(Buddy&, Area const&, Point const& at, vector<Point> const& others, vector<Mob> const& mobs, Ground const&, Settings const&, Rng const&) -> bool`
Picks the next waypoint and plans the way there.
1. The bearing turns one step; near an opening, this waypoint uses the
   middle of the opening.
2. The first waypoint takes a random share of the way out, up to 8 draws
   per bearing. Later ones follow the Y rule; then piercing (after two
   inward rolls in a row, a Y at or under `piercePercent` puts the waypoint
   on the far side of the centre at the same Y and reverses `spin`); then
   crowding (`others` are where the other buddies and nearby players
   stand). A blocked spot slides along the bearing 1% at a time.
3. A bearing with no clear spot turns again, up to 12 times.
4. The path runs straight to the waypoint, or via a turning point when the
   area's walls are in the way, or (only when straight) via a point inside
   the aggro radius of the first monster in `mobs` the line misses by at
   most `lureReach` yards: `lureDepth` of the radius from the monster,
   toward the line, clear to stand on (1.5 yards) and in sight of both
   ends. Each leg is planned.

It returns false, for the caller to log, in three cases: no clear spot in 12
turns; the buddy can't see the centre; or a path can't be planned.
`angle`, `yPercent` and `crowdMoves` may have changed even then.

Random numbers are drawn in this order:
- Per bearing, for a later waypoint: the step size, then its direction.
- One more only on a crowding tie at exactly 50.
- Piercing and the monster nudge draw none.
- For a first waypoint: one per distance tried.

### `PlanPath(Point const& from, Point const& to, float body, Ground const&, Settings const&) -> vector<Point>`
The planner on its own.
1. Test points go down every `body` yards, with heights at the centre and
   both shoulders.
2. A sharp height step is an obstacle. It is bulged round with a
   half-cosine ease, a straight run, and an ease back, on whichever side
   costs less.
3. This is tried for the straight line and for bows of 15% and 30% either
   side. The cheapest wins; on an equal cost, the first in that order wins.

It returns an empty vector when no candidate gets through. Only call it for
ends that see each other; `NextWaypoint` guarantees this for its legs.
Roads are not weighed yet.

### `RestChance(float health, float maxHealth) -> float`
Returns (1 - health / maxHealth) / 2, the chance to sit and eat or
regenerate on reaching a waypoint. `maxHealth` must be above 0.
