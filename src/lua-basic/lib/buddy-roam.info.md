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

## Painting an area as buddies explore it

The exploring model: buddies leave "paint" on the cells they see, and pick
their next waypoint by what is unpainted, where rooms, tunnels and dead
ends are.

### `Roam.paint_grid(area, cell) -> grid`
A clan's paint grid over an area, `cell` yards square, from the area's
outline and walls (or its rectangles).

### `Roam.paint_rooms(grid)`
Splits the grid's open cells into rooms (wide places, each with a centre)
and tunnels (the narrow places between them and dead ends); fills
`grid.room`, `grid.tunnel`, `grid.rooms`, `grid.tunnels`.

### `Roam.paint_disc_map(grid, sweeps)`
The "squished circle": gives every open cell a place in a unit disc, the
outline laid round its rim in order, so a pinwheel run in the disc turns
round bends and runs down corridors in the area. It cannot fold, because
every cell sits at the average of its neighbours.

### `Roam.sense_sectors(grid, x, y, radius) -> list of 8 sectors`
What a buddy senses round itself, in eight overlapping quarter-circles:
for each, how blocked it is, whether a walkable way runs through it, and
so whether it reads as open ground, a wall or a tunnel.

### `Roam.paint_coverage(grid) -> share (0..1)`
How much of the area some buddy has seen up close.

### `Roam.tick(state, rand)`
Every buddy takes one step or stands, in turn, each seeing the others'
new places; records what each considered, for drawing.

### `Roam.rest_chance(health, max_health) -> chance (0..0.5)`
The chance a buddy sits to rest on reaching a waypoint: half its missing
health (the owner, 2026-09-27).

### `Roam.grouping(buddies, ox, oy, join, leave, seats, far) -> grouped count`
The proximity party (issue 617c2): a buddy leaves past `leave` yards from
its owner and joins inside `join` while there are seats.

`Roam.paint_path`, `Roam.paint_line_clear` and `Roam.paint_passable` are
the grid's own path, line-of-sight and walkability helpers, handed out
under those names.

## Where this fits

Everything else in the file (`inside_polygon`, `nearest`, `tangent`,
`waypoint_tick`, `pick_waypoint`, and the rest) is a `local function` —
internal, not called from outside this file. Read them only when debugging
the planner itself. Outside the file, only the functions listed above are
called (`sargobras.lua`, the mod-buddies C++ side, and the roaming tests
and drawings); `scripts/test-info-files-match-source` checks that this
list keeps up with the file.
