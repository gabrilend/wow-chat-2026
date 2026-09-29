# buddy-roam.lua

The roaming and exploration model for buddies adventuring near their owner
(617c2, 617e1, 617e2): who stays close, who ranges out, and the curved
paths a buddy walks between waypoints rather than a straight line into
walls. Pure geometry and decision logic — no server object touched — so
`modules/mod-buddies/src/roam/buddy_roam_core.cpp` (the C++ port that
actually runs on the server) and the offline tests
(`scripts/test-buddy-roam-core`, `scripts/test-roam-pattern`) can each be
checked against this same model, per `tests/buddy-roam-core/cross-check.cpp`.

## Functions

### `Roam.walkable(area, x, y, margin) -> boolean`
Whether `(x, y)` is inside `area`'s walkable polygon/rects, at least
`margin` yards from its edge.

### `Roam.edge_distance(area, x, y) -> number`
Distance from `(x, y)` to the nearest edge of `area`.

### `Roam.centre(area) -> x, y`
The area's centre point, used as a fallback target and for spacing buddies
around it.

### `Roam.default_spacing(area, n) -> number`
How far apart `n` buddies should stand in `area` by default, given its
size.

### `Roam.new(area, buddies, params, rand) -> state`
Builds one roam session's state: who is near/far, each buddy's current
spin (orbit direction) and target, seeded from `rand` so a run is
reproducible.

### `Roam.plan_path(area, ax, ay, bx, by, body) -> list of points`
A walkable path from `(ax, ay)` to `(bx, by)`, curved around obstacles and
detoured through openings rather than cutting through walls; `body` is the
walking creature's collision radius.

### `Roam.PLAN`
A table of tuning constants the planner reads (kept as data, not scattered
through the functions, per the project's configuration-in-structure rule).

## Where this fits

Everything else in the file (`inside_polygon`, `nearest`, `tangent`,
`waypoint_tick`, `pick_waypoint`, and the rest) is a `local function` —
internal to the planner, not called from outside this file. Read them only
when debugging the planner itself; `sargobras.lua` and the mod-buddies C++
side only ever call the six functions above.
