# buddy_paint_paths.h

The painted map (issue 617o8): pathfinding that learns, keeps its distance
from walls, spreads, and walks in arcs. The C++ twin of
`scripts/templates/paint-paths.js` (the ground sandbox's), step for step;
checked alone by `scripts/test-buddy-paint-paths` on the page's own test
courses. Everything is in the namespace `BuddyPaint`.

## Data

| Name | Fields | What it is |
|---|---|---|
| `Options` | each a double: WANT (yards of space wanted), WALL_W, RELAX, NEAR, UNKNOWN, CROWD_W, CROWD_AHEAD, CLEAR_CAP, LOOK, SAFE, TURN (radians a second), LANE, REACH, REPLAN (seconds), ARRIVE | the guesses, one place |
| `Kind` | Unknown, Painted, Wall, Steep, Outside (uint8_t) | what a cell is known to be |
| `Map` | `w`, `h`, `n` (int cells); `step`, `x0`, `y0` (double yards); `know` (Kind per cell); `walks` (uint16_t); `clear`, `crowd` (float); `walls` (latest wall paintings: version and cell box); `version`, `painted`, `wallCells`, `inside`; the planner's reused memory; `stats` (plans, failed, bumps, cells opened, milliseconds) | one area's shared map |
| `Path` | `cells` (route, int); `pts` (the straights' corners, `Pt` x/y doubles); `gx`, `gy`, `len`, `box[4]`; `seg` (segment on); `at` (when planned); `v` (map version known) | one bot's route |

## Functions

| Function | In | Out |
|---|---|---|
| `Make(w, h, step, x0, y0, opt)` | size, spacing, corner | a map, all unknown |
| `SetGround(M, kindAt)` | what each cell's middle is before any walk | steep and outside marked, clearance worked out |
| `Walked(M, x, y)` | where a bot stands | its cell painted and counted |
| `PaintWall(M, x0, y0, x1, y1)` / `Refused(M, x, y, box, bx, by)` | a thing found / a refused step | cells painted as wall (never the bot's own; a refused point not beside it), clearance mended |
| `CostAt(M, q, gx, gy, trip)` | a cell, the goal, the trip's nearness | a yard's cost |
| `Plan(M, sx, sy, gx, gy, out)` | from, to | true and the path, or false (no way) |
| `NeedsPlan(M, path, gx, gy, t, jitter)` | a bot's path or null | whether to plan again |
| `Follow(M, path, x, y, lane)` | where the bot is, its lane | the point to steer to |
| `Steer(M, x, y, h, tx, ty, dt, heading, share)` | heading, the point | the new heading, the share of speed |
| `Crowd(M, bots)` / `CrowdRoute(M, path, x, y)` | the bots / a new route | the crowd remade / a route added |
