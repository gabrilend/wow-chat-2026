# The Roaming Pattern

How buddies roam, explore and fight, written down without any programming
language. Two implementations follow this document, and a check holds both
to it:

| Part of the pattern | Lua (the model; drawn into the GIFs, checked against the server's C++) | JavaScript (the playable scenes in the gallery) |
|---|---|---|
| The ground grid, paint, walls' paint, sectors | `src/lua-basic/lib/buddy-roam.lua` (paint mode) | `docs/HTML/buddy-roaming/roam-pattern.js` |
| The owner's waypoint rule | same file (the "waypoints" reading) | same file |
| The dungeon map | `scripts/generate-buddy-roaming-gifs` (`DUNGEON`) | `roam-pattern.js` (`maps.dungeon`) |
| The kraken fight | `scripts/generate-buddy-roaming-gifs` (scenes 22, 26) | `docs/HTML/buddy-roaming/dungeon-kraken.js` |
| The check | `scripts/test-roam-pattern` (both, the same seeded situations) | |

The owner, 2026-09-28: "the datamodel being the same doesn't mean that
it's implementation in a specific language needs to be the same. Build the
pattern, build it twice." So each implementation is written the way its
language wants. They must agree on what this document says, not on how
they store it.

Units: yards for distance, seconds for time, radians for bearings (0 east,
growing toward +y). A random number is uniform on [0, 1).

## The data model

**An area**: either an outline (a closed polygon of corners) or a union of
axis-aligned rectangles (x0, y0, x1, y1; a point on a rectangle's edge is
inside); plus rocks (circles: centre, radius); plus, for the pinwheel, a
centre.

**The ground grid** over an area: square cells of side `cell` (3 yards in
the dungeon). The grid's corner is the area's bounds less one cell on each
side, so every inside cell has outside neighbours. Cell (ix, iy) has its
middle at corner + ((ix + ½)·cell, (iy + ½)·cell); a point belongs to the
cell floor((p − corner)/cell). A cell is:

- *inside* when its middle is inside the area;
- *open* when inside and its middle is not strictly inside any rock;
- its *edge distance*: yards from its middle to the nearest outside cell's
  square (the area's own walls; rocks left out);
- its *wall distance*: the smaller of its edge distance and its distance to
  the nearest rock's rim.

**Paint**, one layer per clan (an owner and its buddies), per area: a count
per cell laid by the buddies, and a second laid by the walls. Counts only
grow; stored in fixed-width integers they wrap round (at 65,536 for 16
bits), and a wrapped cell briefly looks unexplored (accepted by the owner,
2026-09-27). Kept while the owner is in the area; dropped 15 seconds after
the owner leaves it. Each cell also keeps when it was last *seen up close*
(from within 20 yards).

**A buddy**: position; its pinwheel bearing (angle) and direction (spin,
+1 or −1); its Y (a whole number 1..100, the percent of the way from the
centre to the edge on its bearing); how many inward Y rolls in a row
(inward); its waypoint and the path to it.

**A sector** (sensing): a bearing (one of eight, 45 degrees apart), a
blocked share (0..1), a reach (yards), and a kind: wall, tunnel or open.

**A monster**: position, home, level-derived health, whether elite, its
pack (monsters that fight together), an optional patrol route, state
(idle, fighting, dead), its target, a slow timer.

## The rules

### The owner's waypoint rule (the pinwheel)

On reaching a waypoint, a buddy picks the next:

1. **Bearing**: turn the bearing a tenth of a circle (36 degrees) in the
   buddy's direction.
2. **Reach**: the distance from the centre along the bearing to the first
   side of the outline it meets, less the clearance (3 yards).
3. **Y**: from the last Y, add or take away (even odds) a whole number from
   1 to 20, kept within 1..100. (The first waypoint draws Y freely.) The
   draw uses two random numbers, in this order: the change, then the sign
   (below one half: take away).
4. **Piercing**: count inward rolls in a row (the new Y below the last).
   From the second, a Y at or under 25 sends this waypoint across the
   centre: the bearing turns half a circle, the direction reverses, the
   count starts again, and the reach is measured anew.
5. **Crowding**: if another buddy or a player stands within 5 yards of
   where Y lands (at max(10, Y% × reach) out), Y moves 10 toward 50
   (from exactly 50: a random side). Once; the moved Y is kept.
6. **Place**: the waypoint is at max(10, Y% × reach) out along the bearing.
   If that spot is within the clearance of a rock or of the outline, slide
   it along the bearing a percent at a time, alternating in then out (−1,
   +1, −2, +2 …, up to 99 each way), skipping values below 1% or above
   100%, until clear. (A first waypoint instead tries up to 8 freely drawn
   shares.) The buddy's Y stays the drawn (and crowd-moved)
   value, not the slid one. No clear spot on the bearing: turn another
   step and try again (up to 12 turns).
7. **Opening** (optional): a line 20 yards longer within half a step
   either side is an opening; this waypoint takes its middle.
8. **Monster nudge** (optional): a straight trip that misses a monster's
   aggro circle by at most 25 yards bends through a point 70% of the way
   in from the circle's edge.

### Paint

- **Deposits**: each buddy, every half second (fighting or not), paints
  what it can see out to its vision (60 yards in the model, 40–45 in the
  playable scenes), most at its feet, falling to nothing at the edge;
  cells within 20 yards are marked seen up close.
- **The walls' paint**: every 3 seconds, each open cell within 5 yards of a
  wall is topped up to 400 × (1 − wall distance / 5)², never lowered. It
  keeps paths in a tunnel's middle and waypoints off walls.
- **Choosing by least paint**: of 30 random spots 12–70 yards off, the one
  with the least paint round it (a 6-yard disc), farther from the entrance
  weighing more.
- **Paths**: over the open cells, eight neighbours, no cutting a corner;
  a step costs its length, more within a few yards of a wall, and less
  through unpainted ground.

### Rooms and tunnels

A cell at least 7 yards from the area's own walls (edge distance) is a
room's core; connected cores are one room; cells within 7 yards of a core
join that room. What's left is tunnel; connected tunnel cells are one
tunnel.

### Sensing: the eight sectors

Round a buddy, eight sectors 45 degrees apart; each covers the directions
within 45 degrees of its bearing, so neighbours overlap.

- **Blocked share**: over the cells within the sensing radius (40 yards),
  each weighted 1 − distance/radius, the weighted share that is not open
  (cells outside the grid count as not open).
- **Reach**: walking breadth first over open cells within the radius from
  the buddy's cell (eight neighbours), the farthest distance reached in
  each sector's middle half (within 22.5 degrees of its bearing).
- **Kind**: blocked share at least the threshold (0.6) and a reach of at
  least radius − 1.5 cells is a *tunnel*; blocked share at least the
  threshold otherwise is a *wall*; anything else is *open*.
- **Choosing**: lean toward the tunnel sector whose far half hasn't been
  seen up close recently (more than 35% of it within the last while is
  "recently"); the tunnel's far point becomes the goal. No such tunnel:
  choose by least paint.

### The kraken (a battle pattern; only with a tank)

- **The maw**: where the pack is held and the area spells land, chosen by
  the damage dealers where their ranges overlap best.
- **The tank**: stays within 6 yards of the maw, taunts (30 yards) what is
  on someone else, reaches out to take idle monsters near the maw while the
  hold is light (six or fewer, an elite counting three) and its health is
  above half, and steps to the maw's far side from a newly taken monster.
- **Pullers** (ranged): reach an idle monster near the maw, hit it once
  (little threat) and slow it, lead it to the far side of a neighbouring
  quadrant (never the opposite), blink or disengage when it closes, kite
  round the maw until the tank takes it; only while the enemies' total
  threat stays under what the tank has shown it can take.
- **Area spells** land on the maw when two or more stand in it; against a
  boss, area and single-target spells about equally.
- **Moving on**: when all held monsters are dead, the whole party moves on.
- **Monsters are faster than the party** (2026-09-27): slows, blinks,
  disengages and taunts save a puller, not its legs.
- **Patrols**: a third of the monsters (in the scenes, a chosen number)
  walk set routes back and forth; one passing near a fight joins it.
- **Melee kinds**: whirlwind (hits everything near it), heavy hitter (kills
  the marked target, skull then cross), control (slows and disables what
  isn't on the tank).

## What the check compares

`scripts/test-roam-pattern` runs the same seeded situations through both
implementations and compares what this document fixes:

- **The dungeon's grid**: which cells are open, and the map itself (both
  sides' rectangles and rocks).
- **Sectors**: for many points in the dungeon, every sector's kind and
  reach.
- **Waypoints**: for many buddy states on an outline area, with the same
  random numbers, the waypoint's place, the new Y, direction and inward
  count.

Internal structures are not compared.

## Monsters in melee: chasing and swinging (the server's rules)

Read from the server's source (AzerothCore, 2026-09-28), so the pattern
matches the game rather than a guess (the owner: "we should be trying to
build the datamodel to match the game, so try not to take shortcuts, and
instead describe the behavior as best you can"). Distances centre to
centre, yards.

- **Combat reach**: every body has one; players and ordinary monsters 1.5
  (the default), large creatures more (from their model's data).
- **Chasing**: a monster chasing its target runs until it is within the sum
  of the two reaches, then stands. Every 0.4 seconds it looks again; it
  sets off only when the target is more than half a yard (contact
  distance) beyond that sum. So a target that edges away a little is not
  chased at once, and one that runs is.
- **Melee range**: a swing reaches the two reaches plus 4/3 of a yard, and
  never less than 5 yards (so 5 for two ordinary bodies).
- **Leeway**: when both are running (not walking) and one of them is a
  player, melee range grows by 2.66 yards (7.66 for two ordinary bodies):
  the thin strip beyond the chase distance where a chasing monster still
  lands blows on a player running from it.
- **Swings**: melee lands once per attack time (about 2 seconds for most
  monsters), if the target is in melee range when the swing comes; not a
  steady drain.
- **Speed**: ordinary monsters chase at about 8 yards a second, players run
  at 7: a monster gains slowly on a running player, and with the leeway
  keeps hitting it.

Implementations: the owner-as-tank widget (`docs/HTML/buddy-roaming/
owner-tank.js`, constants REACH, CONTACT, RECHECK, MELEE_MIN, LEEWAY,
SWING); the other scenes still use their earlier simpler chase until
brought in line.
