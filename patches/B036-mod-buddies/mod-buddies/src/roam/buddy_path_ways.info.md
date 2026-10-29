# buddy_path_ways.h

Five ways for a buddy to find its way to a point (issue 617o7), as plain
arithmetic over a grid, with no server code. Checked alone by
`scripts/test-buddy-path-ways`. Everything is in the namespace `BuddyPath`.

## Data

| Name | Fields | What it is |
|---|---|---|
| `P` | `x`, `y` (float, yards) | a point on the ground |
| `Way` | Orbit, Flow, AStar, Potential, Learn (uint8_t) | which way a buddy uses |
| `Grid` | `w`, `h` (int, cells across and down); `x0`, `y0` (float, yards: the first cell's centre); `step` (float, yards between centres); `open` (vector of uint8_t, 1 walkable); `learned` (vector of uint8_t, 1 learned to block) | the ground, cell q = row × w + column |
| `Backing` | `next` (float, yards of the next back-out); `front` (bool), `frontAt`, `frontAxis` (P: the forwardmost stuck spot and the way it faced) | backing out twice as far each time |
| `Orbit` | `on` (bool), `side` (int, +1 or -1), `heading`, `fromDist` (float) | walking round what blocks, keeping it on one side |
| `Walker` | `way`; a `Backing` and an `Orbit`; the flow field and A* route kept between steps, and their targets; the stuck check's snapshot (time, distance, place); a kick's direction and end; a seed; counts of stuck checks, orbits, kicks and plans (int) | one buddy's way and memory |

## Functions

| Function | In | Out |
|---|---|---|
| `WayName(way)` / `WayFromName(name, out)` | a way / a name | its name / whether the name is a way |
| `Grid::Cell(p)` / `Grid::Centre(q)` | a point / a cell | the cell it is in (-1 off the grid) / the cell's centre |
| `LineClear(grid, a, b, learnedOnly)` | two points | whether every cell the line crosses is passable |
| `FlowField(grid, target)` | the target's cell | the walking cost from every cell (infinity where unreachable) |
| `FlowNext(grid, field, from, out)` | the field, where it stands | the point a few cells downhill in a clear line |
| `AStar(grid, from, to, learnedOnly)` | two cells | the cheapest route's cells (empty: none) |
| `PullTight(grid, route, from, reach, learnedOnly)` | a route | the farthest point of it in a clear line within reach |
| `Learn(grid, at, to)` | a step that fell short | whether a new blocked cell was learned |
| `PotentialStep(at, target, blocked)` | where it stands, the point, what blocks | the point 4 yards along pull plus pushes |
| `Stuck(closer, able, distLeft)` | yards gained, yards walkable, yards left | the owner's stuck rule |
| `Walker::Reset(way)` | a way | forgets plans and snapshot (a new order) |
| `Walker::Next(grid, at, target, now, speed)` | where it stands, the point, the time, its speed | the point to walk to now |
| `Walker::Fell(grid, at, intended)` | a refused step | for "learn", the blocked cell learned |
