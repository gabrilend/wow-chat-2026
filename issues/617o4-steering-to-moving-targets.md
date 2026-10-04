# 617o4 - Steering Toward Moving Targets

## Status
- Created: 2026-10-03
- Phase: 6
- Parent: 617o
- Blocked by: 617o1 (the mesh questions)
- Related: 617e3 (neutral monsters join the steering)
- Priority: Medium

## Current Behavior

**Written 2026-10-03, syntax-checked, not yet built or run**:
`buddies_steer.cpp` (the turn's facing over 0.4 seconds, the edge spot,
the notice radius) and, in the roam action, the monster approach: every
second a roaming buddy not on a detour picks the nearest monster worth
fighting within 60 yards, hostile or neutral; aims at the edge of its
notice radius every half second (straight when the mesh's line test
passes, by the mesh's route otherwise, given up and skipped for a minute
with neither, or after 20 seconds); at the edge turns to face it over 0.4
seconds and opens the fight as the bot module's own attack does (target
selected and remembered, fighting engine on, first swing). Every turn
follows the turn rule below.

**Seen in game 2026-10-03, then changed (syntax-checked, not yet built):**
Carago (a rogue) reached the edge of a neutral Volatile Mutation and
opened the fight, and the bot module dropped the target at once ("drop
target"), the approach choosing the same monster again, round and round,
with a turn each time: a neutral monster not yet struck is no fight to
the bot module. Now a melee buddy also runs in after the monster (the
server's chase) so the first blow lands; a ranged one is left to its
class's pull from the edge; and a fight not begun 5 seconds after the
opening skips that monster for a minute, the trace saying what the bot
module would have objected to (sight, detection, friendliness, alive).
With aggro off server-wide (a radius of 0) the edge is the two bodies'
reach. Before this stage: A buddy never goes toward a neutral monster (617e3: only
hostile, aggressive ones bend its trip), so in starting zones, where
nearly every monster is neutral, it fights nothing. The server's own
notice radius (`Creature::GetAggroRange`) works for any monster: the
monster's detection range (usually 20 yards), a yard less for each level
the buddy is above it and a yard more for each level below (to 25 below),
the detection auras on both, between 5 and 45 yards; only the server's
"should I attack?" check skips neutral monsters.

## Intended Behavior

- **The steering**: every `STEER_MS` (half a second) the buddy aims at
  its target's current spot; when the mesh's straight-line test passes,
  it moves straight there (no path search), otherwise along a mesh route
  (617o1). It turns toward its heading over `TURN_MS` (0.4 seconds), a
  few small facing steps, not a snap.
- **Its first use, the monster approach** (617e3, the owner 2026-10-03:
  "we should dynamically calculate the radius, and steer the buddy-bot to
  the edge of that circle. [...] Then they should start casting spells or
  charging in to fight or stealthing up or whatever the class the
  buddy-bot is does. Once the monster is slain, they continue on their
  circuit."): while roaming, the nearest monster worth experience within
  60 yards, hostile or neutral, not fighting, not someone else's, with a
  path to it: the buddy steers to the edge of that monster's notice
  radius for it (the server's own radius), then makes it the bot's
  target and lets the bot module's class fighting open the fight (a pull
  spell, a charge, stealth). After the kill, roaming carries on.

- **The turn rule, for every turn** (the owner, 2026-10-03: "anytime we
  turn toward a new point or waypoint, we should always have lerping
  orientation smoothing. If we are stopped while turning, we shouldn't
  start until we're facing the right direction. If we're moving while
  turning, we can keep moving until we're pointed the right way."):
  before setting off toward a new point (a roaming leg's next point, the
  first aim at a monster, the edge's facing, a town walk from standing),
  a turn of more than about 10 degrees is smoothed over 0.4 seconds:
  standing, in place (a facing step at every player update), the move
  waiting for it; moving, along a short curve on the mesh whose heading
  swings over the distance 0.4 seconds of travel covers (stopping to turn
  in place when the curve would leave the mesh). Built 2026-10-03 with
  the rest of this stage (`buddies_steer.cpp`, the turn rule), not yet
  built into the server or run.

## Suggested Implementation Steps

1. `buddies_steer.cpp`: the steering for one buddy toward a unit, with
   its per-buddy state (last aim time, facing steps).
2. In the roam action, before the waypoint walking: the monster choice
   and the approach; at the edge, the bot's target is set and the attack
   begun the bot module's way.
3. Trace lines: the monster chosen, its radius, each re-aim (straight or
   routed), the attack begun.

## Related Issues

- **617o** parent; blocked by **617o1**; **617e3**, **617e5**
