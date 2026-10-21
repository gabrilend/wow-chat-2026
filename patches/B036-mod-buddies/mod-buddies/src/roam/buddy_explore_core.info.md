# buddy_explore_core — exploring an area as painting (issue 617e6)

The three painting explorers (least paint, the room orbit, the squished
circle) and the ground grid, paint, rooms, disc and paths they share. No
server headers: the server fills the grid from the map
(`../buddies_explore.cpp`), the test from the Lua model
(`tests/buddy-roam-core/explore-check.cpp`, run by
`scripts/test-buddy-roam-core`). The design and numbers are the Lua model's
(`src/lua-basic/lib/buddy-roam.lua`, "painting"), loop for loop: the test
holds the two to the same answers, to the last bit.

## Structures

- **`Settings`** — the model's numbers (doubles, int32): `vision` 60,
  `rays` 90, `nearPaint` 12, `wallReach` 5, `wallPaint` 400, `roomMin` 7,
  `roomLeave` 0.8, `saturate` 200, `disc` 6, `pathMargin` 1.5, `close` 20,
  `farWeight` 0.3, `pathWeight` 3, `clearance` 3, `nearYards` 10, `turn` a
  tenth of a circle, `yChangeMin`/`yChangeMax` 1/20 (the owner's Y rule).
- **`Grid`** — square cells `cell` yards across from corner (`x0`, `y0`),
  `nx` by `ny`; cell `i = iy * nx + ix`. Filled by its maker: `inside`
  (uint8, part of the area), `open` (uint8, walkable), `edge` (double, yards
  to the area's edge, -1 outside), `wall` (double, yards to the nearest
  wall, -1 where not open), `height` (float, ground z; 0 on drawn maps).
  `Prepare` fills `openList`, `wallCells` (cell, pulse level uint16),
  `room`/`tunnel` (int32 labels, 1-based, 0 none), `rooms`, `tunnels`,
  `places`. `DiscMap` fills `du`, `dv` (doubles), `hasDisc`, `rim` (uint8),
  `discClear`. `CellOf(x, y)` (-1 off the grid), `CellXY(i, x, y)`.
- **`Place`** — a room or tunnel: `isRoom`, `id` (1-based), `cells`
  (walkable cells, in cell order), `cx`, `cy` (its middle).
- **`Paint`** — a clan's paint: `buddy`, `wallp` (uint16 counts that wrap
  at 65,536: accepted by the owner, noted in the header), `close` (uint8,
  seen from within 20 yards). `Reset(grid)`.
- **`Explorer`** — one buddy between waypoints: position `x`, `y`; `id`,
  `spin`; the disc's `dang`, `dshare`; the room orbit's `room`, `rshare`,
  `rang`, `rangSet`, `heading`; the last goal `hasGoal`, `gx`, `gy`.
- **`Point2`** — `x`, `y` (doubles).
- **`Rng`** — `std::function<double()>`, 0 <= r < 1.

## Functions

- **`Prepare(grid, settings)`** — the open list, the wall pulse's cells and
  levels, rooms (cores at least 7 yards from the edge, grown 7 yards) and
  tunnels (the rest), each room's middle.
- **`ComputeDistances(grid)`** — `edge` and `wall` from the `inside`/`open`
  flags alone (for grids measured from the map); within about a cell of the
  exact distances (the test measures it on the model's hall: 0.41 yd to the
  edge, 1.0 yd to walls, at 2-yard cells).
- **`RimAngles(grid)`** → `(cell, angle)` list — the outer border traced cell
  by cell, each cell's angle its share of the border's length; for the
  disc of a measured grid.
- **`DiscMap(grid, rimPoint, sweeps, tolerance)`** → passes made — the
  squished circle: border cells at `rimPoint(i)` (cos, sin), inner cells
  relaxed to their neighbours' average (over-relaxed, weight 1.9). Can't
  fold (a harmonic map onto a convex disc); the test checks every little
  square keeps its turning direction.
- **`Deposit(grid, paint, settings, x, y)`** — a buddy's paint: 90 sight
  lines out to 60 yards, more where it stands.
- **`WallPulse(grid, paint)`** — tops the ground within 5 yards of walls up
  to its level (never adds on top).
- **`PaintedNear(grid, paint, settings, x, y)`** → 0..1 — how painted the
  ground within 6 yards is.
- **`Coverage(grid, paint)`** → 0..1 — share of walkable cells seen close.
- **`FarRef(grid, ex, ey)`** → yards — the farthest walkable cell from the
  entrance.
- **`PickLeast`**, **`PickRooms`**, **`PickDisc`** (grid, paint, settings,
  explorer, entrance x/y, farRef, rng) → bool — the three choosers; set the
  explorer's goal; draw random numbers exactly as the model. False only when
  nothing can be chosen (no walkable cells, no rooms, no disc).
- **`BeginDisc(grid, explorer)`** — a disc explorer's start angle and radius
  from where it stands.
- **`GridPath(grid, paint, settings, ax, ay, bx, by, weight)`** → points —
  A* over walkable cells 1.5 yards off walls, dearer through paint, pulled
  straight; excludes the start, ends at b; empty when there is no way.
