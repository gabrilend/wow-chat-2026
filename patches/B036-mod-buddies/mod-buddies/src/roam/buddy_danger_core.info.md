# buddy_danger_core.h

How dangerous a clan's surroundings are, and how near its owner a roaming
buddy keeps because of it (issue 617e10). Plain arithmetic, no server;
checked by `scripts/test-buddy-danger`. Not yet wired into the server:
feeding the reading (each waypoint pick, each fight's end, each update's
health and mana) and asking it in the roaming and the monster approach
are the server's part, still to build.

## Settings

| Field | Type | Default | Meaning |
|---|---|---|---|
| `steps` | int32 | 4 | steps above calm; the last is the close-follow ring |
| `riseShare` | float | 0.7 | of the way up to a higher reading, taken at once |
| `halfLife` | float | 180 | seconds of quiet that halve the reading |
| `wellDoneFall` | float | 0.25 | share taken off by a fight that went well |
| `stepSlack` | float | 0.05 | below a step's edge by this before it is let go |
| `packEasy`, `packHard` | float | 1, 3 | pack weight per clan member: no danger, the worst |
| `lostEasy`, `lostHard` | float | 0.15, 0.60 | share of the clan's health a fight cost: no danger, the worst |
| `closeHealth` | float | 0.20 | an ally under this share of its health: a close call |
| `closeMana` | float | 0.10 | the healer under this share of its mana: a close call |
| `closeCall` | float | 0.75 | what a close call reads |
| `wellDoneLost` | float | 0.20 | a fight under this cost, no close call, no death, went well |
| `levelsCalm` | float | 3 | levels above the buddy a monster may be, when calm |
| `eliteStep` | int32 | 2 | from this step on, elites are passed over |
| `ringYards` | float | 5 | the close-follow ring (617s) |
| `weigh` | BuddyPace::Settings | | how a pack is weighed: the tank's own (`buddy_pace_core.h`) |

## Pieces

| Name | What it is |
|---|---|
| `Sight` | `pack` (BuddyPace::Pack), `members` (uint32): the heaviest pack a buddy sees, and the clan's size |
| `FightEnd` | `lost` (float 0-1, the clan's health it cost), `death`, `closeCall` (bool) |
| `Ramp(x, easy, hard)` | -> float: 0 at or below easy, 1 at or above hard, straight between |

## Reading

One per clan, fed by all of its members.

| Member | Type | Meaning |
|---|---|---|
| `value` | float | 0 calm to 1 the worst |
| `step` | int32 | 0 to `steps` |
| `lastAt` | double | seconds, the last `Tick` |
| `Raise(to, s)` | | a higher reading heard: `riseShare` of the way up at once |
| `Edge(i, s)` | -> float | where step i begins: i / (steps + 1) |
| `Restep(s)` | | the step from the value: up at an edge, down `stepSlack` below it |
| `Tick(now, s)` | | halved every `halfLife` seconds of quiet |
| `Saw(sight, s)` | | the pack's weight per member, `packEasy` to `packHard` |
| `Close(allyHealth, healerMana, death, s)` | | a close call: the worst for a death, `closeCall` for low health or mana |
| `Fought(fightEnd, s)` | | a death the worst, else by the health it cost; a fight gone well takes `wellDoneFall` off |
| `Leash(areaYards, s)` | -> float | the radius round the owner: the whole area at 0, the ring at the worst, the same share off each step |
| `Within(yards, areaYards, s)` | -> bool | whether a waypoint that far from the owner may stand |
| `LevelsAllowed(s)` | -> float | `levelsCalm` less the step |
| `Seeks(levelAbove, elite, s)` | -> bool | whether the monster approach may go for it |
| `Trace(areaYards, s)` | -> string | one line: reading, step, leash, monsters it may seek |
