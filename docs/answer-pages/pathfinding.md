title: Pathfinding, End to End
subtitle: How a bot learns the ground and finds its way across it
part: Ground and Bodies
state: built; the in-game switch waits for the compile
issues: 617o 617o1 617o2 617o3 617o4 617o5 617o6 617o7 617o8
gifs: 2a 2b 2c 2d 2e

The owner, 2026-10-29: "let's get back to ironing out the pathfinding.
It's our most important component." And: "Remember we want bots to paint
surfaces and collectively get better at navigating as we gather more
data. Also they should give space to walls, less if they need something
nearby or directly nearby opposite the wall, and they should spread out
through an area."

## The painted map

gif: 2a

The ground is cut into cells a yard across. Every cell starts unknown.
A bot walking paints the cells it crosses as open ground; a step the
world refuses (a rock, a tree, a wall the game's own map did not mention)
paints the thing it hit as a wall. The map is shared: what one bot
learns, every bot plans with at once. In the first test, ten bots crossing
a field of 81 pillars nobody knew were refused 362 times on their first
round of trips, then 30, then 1.

## One step, layer by layer

gif: 2b

Each step goes through four layers:

1. **The cells**: open, wall, too steep, outside the area, or unknown
   (unknown ground costs a little more than open, so known ways are
   preferred without forbidding the new).
2. **The route**: a search across the cells (A*), where a cell close to a
   wall costs more, so routes keep their distance.
3. **The straight**: the route pulled tight into the fewest straight
   pieces that keep the same distance from walls.
4. **The turn**: the bot follows a point a few yards ahead, turning at
   most 240 degrees a second, so it walks curves, not corners.

## Six ways, side by side

gif: 2c

Six ways of finding a path were raced on the same ground (the Barrens,
36 bots, two minutes; turning is degrees turned a yard walked, lower is
smoother):

| Way             | Turning | Stuck | Spacing yd |
|-----------------|--------:|------:|-----------:|
| painted map     |     6.3 |     0 |       19.1 |
| flow field      |    11.7 |     0 |       24.6 |
| orbit           |    13.4 |   224 |       12.9 |
| potential field |    18.3 |     0 |       18.9 |
| learn the map   |   113.1 |     0 |       16.5 |
| graph and A*    |   120.4 |     0 |       22.5 |

The painted map is the smoothest and never stuck. It is the one in the
buddy module's switch (`.buddy path paint`), waiting for the compile.

## Space from walls, and less when it matters

gif: 2d

A bot wants four yards from a wall. Near its goal the want relaxes, so a
bot heading for a door, a chest or a vendor against the wall can reach it,
and a goal just across a thin wall is gone round closely. Bots leaving
together take lanes of their own and count each other's routes as a
crowd, so twelve bots leaving in one knot cross a gap spread 3.3 yards
apart instead of single file.

## Better, day after day

gif: 2e

The paint is kept: one map for each 512-yard region of a game map,
shared by every buddy on the server, saved every ten minutes and at
shutdown, and loaded back at start. The owner, asked whether it should be
shared and kept: "yes yes and yes." Small floating pieces of ground (the
asteroids around Outland) get no stored map; they are painted as they are
walked.

## The questions

questions:
