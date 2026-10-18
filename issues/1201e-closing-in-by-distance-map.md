# 1201e - Closing In: Distance Maps and Steering on the Game's Mesh

## Status
- Created: 2026-10-17
- Phase: 12
- Parent: 1201 (robot search party)
- Blocked by: 1201b (the rooms)
- Related: 617o3 (baked distance maps), 617o4 (steering to moving targets)
- Priority: Medium

## Current Behavior

Buddies close on a target with two pieces of 617o: a distance map (for
one goal, every floor cell of an area holds the walking distance to it,
a flood outward from the goal; 617o3) and steering (every half second,
aim at the target's spot: straight there when the mesh's line test is
clear, along a route when it is not; 617o4). Both work on World of
Warcraft's mesh only.

## Intended Behavior

The same two, in Squirrel (`src/l4d2/closing-in.nut`), on 1201b's rooms:

- When a robot sees a survivor, it shares where: that spot becomes the
  goal of a distance map over the rooms nearby. Every robot within it
  walks downhill on the map, so a search party converges from all sides
  by the shortest walking routes, not in a line behind the first robot.
- Close to the survivor, steering takes over: straight at them when the
  line is clear, along the route when it is not, re-aimed every half
  second, as 617o4 does.
- Lost sight for long enough: back to searching (the roaming pattern,
  1201a), from the last spot seen.

The moving parts are commanded through `CommandABot` (move to a
position, attack a target); the game's own infected AI is paused while
a robot is commanded, so it never fights our decisions.

## Suggested Implementation Steps

1. The flood over rooms: costs between joined nav areas by the distance
   between their middles; one map per sighting, rebuilt when the
   sighting moves a room away.
2. The steering loop with the game's line test.
3. The hand-back to searching after `LOST_SIGHT_SECONDS`.
4. Offline checks on an exported map (1201b): from every room the map
   leads to the goal, and no robot's route is longer than the shortest
   by more than one room.

## Open Questions

- How far does a sighting spread: every robot on the map (a hive), or
  only robots that could have heard (within a radius)? The second is
  fairer to players and closer to "a search party".
