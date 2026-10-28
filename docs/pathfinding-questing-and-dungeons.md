# Pathfinding while questing and in dungeons: how it works, and the plan

*Written 2026-10-27 at the owner's ask: "let's only do the pathfinding ideas
that I commented on earlier - can you give me a report?" and "why are they
climbing up mountains? What does their pathfinding behavior look like?
Let's focus on one activity at a time." Today's activity is questing, then
dungeons; no PvP. The ideas themselves, with the owner's comments, are in
`docs/pathfinding-improvements.md` (ideas 1, 3, 6, 7 and 9 here); this page
says how buddies move today and how each idea would be built.*

## How a buddy moves today, while questing

A **sub-zone** is the small named place the game shows at the top of the
minimap (Fargodeep Mine, Felstone Field). Buddies roam the owner's
sub-zone instead of following:

1. **The middle.** The sub-zone's centre is read once from a table made at
   install time (the average of every map point carrying the sub-zone's
   name).
2. **The next waypoint, by the pinwheel** (the default of the four ways of
   exploring). Each waypoint's bearing from the centre turns a tenth of a
   circle from the last one, in the buddy's own direction. Its distance
   out is a percentage of the way from the centre to the **edge** along
   that bearing, moved 1 to 20 points in or out at each step. Within 5
   yards of another player or buddy, it moves 10 points toward the middle.
3. **The edge** along a bearing is found by walking the line a yard at a
   time from the centre until one of three things happens: the sub-zone's
   name changes, the ground ends, or a **sharp step**, meaning a height
   change much bigger than the yard before it (a crate, a ledge, a wall).
4. **A waypoint may stand** where a ring of points 3 yards round it is in
   the sub-zone, has ground, has no sharp step, and is no steeper than 45
   degrees.
5. **The walk there** is planned in short legs on the navigation mesh (the
   server's map of walkable ground), bending round obstacles and preferring
   the gentlest line up or down a slope.
6. **On the way**: monsters near the line bend the walk through the edge of
   their aggro radius so they notice the buddy (the monster nudge). A herb,
   ore node or chest within reach becomes a one-off waypoint. At a waypoint
   there is a chance to sit and eat, higher the more health is missing.
7. **The owner in another sub-zone**: "buddy travel" walks the buddy to an
   arc of places 5 yards in front of the owner, 4 yards apart, each buddy
   given the place nearest it. Three failed walks in a row send it back to
   where it last stood well (the unstick).

### Why they climb mountains

Steps 3 and 4 between them do it. A mountainside rises by about the same
amount every yard, so it never counts as a sharp step: the edge search
walks straight up it and stops only where the sub-zone's name changes, and
many sub-zones end along a ridge line. Any spot under 45 degrees can hold
a waypoint, which is steeper than most hillsides. So a bearing that points
at the hills puts the waypoint, at its percentage of the way, part-way up
them. Nothing compares the waypoint's height with the owner's or the
centre's.

**The owner's answers (2026-10-27):**

- **The edge search is baked** ("this should be baked"): worked out once
  per sub-zone ahead of time and kept in a file, as the town circles are
  (`scripts/bake-buddy-towns`), not walked out a yard at a time while the
  buddy waits.
- **The slope limit is a walker's** ("what's the limit for a player
  walking up a slope? That should be the limit."). The server's own
  numbers, read from its source: its navigation mesh counts ground up to
  60 degrees as walkable (`walkableSlopeAngle: 60` in the mesh builder's
  settings), and marks the band from 50 to 60 degrees "steep"; the bot
  module keeps its bots off steep ground, its builder naming 50 degrees
  "the player's slope angle". So the limit is **50 degrees**, read from
  the mesh's steep mark, not a number of ours: no waypoint, and no edge
  search past, ground the mesh calls steep. Written 2026-10-27, waiting
  for the owner's compile: the buddies' own mesh questions already left
  steep ground out; the waypoint rule's 45 degrees became 50, and the edge
  search now stops at ground steeper than 50 (`WALK_SLOPE_DEGREES` in
  `buddies_roam_ground.cpp`). The baking is not built yet.
- **Heights are judged from the buddy** ("it's about the buddy-bot, not
  the player"): a waypoint is good when the buddy, from where it stands,
  can walk to it within that limit; there is no comparison with the
  owner's height. So a buddy may still climb a hill a person could walk
  up; what stops is the climbing of ground a walker couldn't.

## How a buddy moves today, in a dungeon

Roaming is off in dungeons, raids and battlegrounds. Each buddy uses the
bot module's own **follow**: it stands about a yard and a half behind the
owner and walks after them. Twice a second, when the owner comes within
1.1 times a hostile monster's aggro radius (a little before it would
notice them), every buddy not already fighting goes at that monster: melee
runs in, casters move into range. The owner's path is not used: each
buddy walks its own straight-line route to the owner, so in corridors they
bunch up behind one another and push through doorways together.

## Following: the owner's formation (2026-10-27)

The owner: "when following our trail, we should always have them walk to
within 1 yard of the trail and then follow it in parallel. [...] this is
how they should follow the player, by the way." Wherever a buddy follows
(the "follow" order, in dungeons, along the trail of idea 3):

- **Beside the trail.** Each buddy walks to within a yard of the line the
  owner walked, then walks along it, parallel.
- **Shared sides, as a half circle 1-2 yards behind the owner**, "behind"
  being the way the owner came. Across the trail, by how many buddies
  follow:

  | Buddies | Places across the trail (yards; 0 is the trail itself) |
  |--------:|--------------------------------------------------------|
  |       1 | -1                                                     |
  |       2 | -1, +1                                                 |
  |       3 | -1,  0, +1                                             |
  |       4 | -1, -0.5, +0.5, +1                                     |

  Each place stands on the half circle, so the ones near the trail are
  farthest back:

  ```
              owner
          1   .   1        (the places at -1 and +1: 1 yard back)
           0.5 . 0.5       (-0.5 and +0.5)
              0            (on the trail: 2 yards back)
              .
              .  the trail, the way the owner came
  ```

- **At rest.** Following starts again only when the owner is more than 10
  yards away. Until then each buddy, now and then, has a 10% chance to
  mingle (a short wander near the others); otherwise it stands and turns
  to face the owner, as Sargobras does.

## The plan: the five ideas the owner commented on

In the order they would be built (each depends on the one before only
where it says so):

### 1. The referee: one mover at all times (first)

**What it is.** One table, read before every movement action, that says
which single behaviour moves the buddy this moment, with a row per
situation: roaming its sub-zone, travelling to the owner, a town errand,
a town pastime or a chat, sitting with nothing to do (the owner: "if
there's nothing to do, sometimes they'll sit down and just chill"),
fighting, a boat crossing, and in dungeons following and the monster
charge. Every row is written in the buddy's trace with its name.

**Questing.** The fault the measurements found ("nothing moved Matis") is
a moment no row claims. With the table, that moment is a line in the log
saying so, and the measuring tool counts the seconds a buddy stood still
with no row naming why: the target is zero.

**Dungeons.** The same table with the dungeon's rows, so a buddy left at
the entrance (seen in Zul'Farrak, 2026-10-03) is a named fault, not a
puzzle.

**The owner asked** (2026-10-27): "so, it's just... a task list or
something? An active movement pattern? Like a state machine? Except,
external for some reason?" Yes: it is a state machine's state picker.
Why it would sit outside: today there is no one machine. The bot module
runs, many times a second, a ranked list of behaviours, each with its own
trigger asking "is this mine?"; roaming, travel, the town visit, the boat
crossing and following each answer for themselves, and none knows the
others' answers. The gap the measurements found is a moment when every
trigger says no. The referee is that one machine: its state is "who moves
the buddy", chosen from one table, and the behaviours then only carry it
out. It could instead be built inside the bot module's own ranking, as
the lowest-ranked behaviour, the one that runs when nothing else does and
logs why. That is smaller, but it only names the gap after the fact.

### 2. Not fighting on errands, fighting through what blocks the way

**What it is.** While a buddy is travelling (to the owner, to sell, to a
boat), the referee's travel row is marked "on an errand":

- a monster standing on the way is fought (the owner: "unless a foe is in
  their way, as is the case when they have to fight through wilderness");
- a monster off the way is left alone, and the monster nudge is off;
- a fight the buddy judges it would lose (the monsters' levels and number
  against its health and its group's) is walked round instead, on a curve
  outside the monster's aggro radius, rejoining the way past it (the owner:
  "orbit move aside fights that they don't think they can win").

**Measured by** a new column in the recording, "on an errand", so the
measuring tool can count fights started while travelling.

**Dungeons.** Not used: in a dungeon every fight is the group's.

### 3. Following the owner's own track (needs 1)

**Built 2026-10-27, waiting for the owner's compile:** each owner's track
is noted (`buddies_follow.cpp`), the following formation walks along it
(in dungeons, and after "follow me"), and travel that finds no way to the
owner's arc walks the track instead, a few points on from the point
nearest the buddy (`buddies_town.cpp`). The referee (1) is not built: the
track is used where travel's own walk fails.

**What it is.** The owner's position every few yards over the last few
hundred yards, kept as a trail of breadcrumbs. A buddy that can find no way
to its owner, or is going through a gate, bridge or tunnel, walks to the
trail and then along it in the formation above (Following). Where its
place is blocked,
it moves toward the middle of the room or passage instead (the exploring
grid already measures each cell's distance from the walls), never far from
the trail (the owner: "they just stick to the nearest 'center of the
room' gradient, preferentially. But still remaining close.").

**Questing.** The Bulwark's gate, Undercity's lift, cave mouths: the
owner's feet already proved the way.

**Dungeons.** The same trail replaces the follow's straight line: buddies
walk where the owner walked, round the corners the owner took, instead of
cutting them.

### 4. Single file on narrow ways (needs 3)

**Built 2026-10-27, waiting for the owner's compile:** where the track,
at the formation's middle, is less than 1.5 yards from the mesh's nearest
edge (a wall or a drop; the formation's own half-width and half a body),
followers walk the track in single file, 2.5 yards apart, and fan out
again where it widens (`ColumnPlaces`, `roam/buddy_follow_core.h`; the
width from the navigation mesh, `BuddyMeshWallDistance`). Both numbers are
ours.

**What it is.** Where the walkable ground under the trail is narrower than
two bodies (a bridge, a ramp, a tunnel, a doorway), buddies walk the trail
in a column a few yards apart, and fan back out onto the arc on open
ground. The width is read from the exploring grid or the navigation mesh.

**Questing.** Mostly bridges and cave tunnels.

**Dungeons.** Most of a dungeon is corridor, so here it matters most: the
column is the dungeon's normal shape, with the arc only in rooms.

**The owner asked: "What if we're running up a mountain face?"** With the
fix above, roaming buddies no longer choose to climb. When the *owner*
climbs and they follow along the trail, the trail itself is the one line
known to be climbable, so they take it in file, behind the owner.

### 5. Watching the record live (any time; a tool)

**Built 2026-10-27:** `scripts/watch-buddy-spread` (its test,
`scripts/test-watch-buddy-spread`, a quick test). It follows the record as
it grows and says, once at the start and once at the end of each episode:
a buddy still for 30 s while its owner is more than 10 yards off, two
buddies on one spot for 10 s, a buddy in another sub-zone more than 150
yards from its owner. `--once` reads what is there and stops.

**What it is.** The measuring tool follows the movement recording as it
grows, the way the compile ledger follows a compile, and prints a line the
moment a rule breaks: a buddy still for 30 seconds with no row naming why,
two stacked on one spot, one more than so many yards from its sub-zone.
Only on a Debug build and only for game-master characters, as the
recording already is (the owner: "we will only record our paths in debug
mode. and then, only for GMs").

## Open questions

1. **Mountains** (answered 2026-10-27): the walker's limit, 50 degrees,
   judged from the buddy, and the edge search baked. See "Why they climb
   mountains".
2. **The referee**: one state picker of its own, or the bot module's
   lowest-ranked behaviour (see idea 1)?
3. **Following at rest**: how often a buddy rolls its 10% mingling chance
   (every 5 seconds is proposed), and whether the formation is the one
   drawn above.
4. **Questing, a new thought, not yet one of the ideas**: should roaming be
   drawn toward the owner's quest objectives? The game already knows where
   each quest's objectives are (the quest map markers the client shows).
   The pinwheel's middle could move from the sub-zone's centre to the
   marked area of the owner's quests in that sub-zone. Yes, no, or later?
5. **Dungeons** (answered 2026-10-27 by the following formation): behind
   the owner, on the half circle, in rooms as in corridors.
