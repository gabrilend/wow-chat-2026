# 617o1 - The Mesh Decides Every Spot and Route

## Status
- Created: 2026-10-03
- Phase: 6
- Parent: 617o
- Blocked by: none
- Priority: High

## Current Behavior

**Written 2026-10-03, syntax-checked with the build's own flags, not yet
built or run**: `patches/B036-mod-buddies/mod-buddies/src/buddies_navmesh.cpp` (the
nearest standing spot, the straight-line test, the route and its kind;
each bot thread keeps its own mesh query object) and, in the roam action
(`buddies_roam_strategy.cpp`), the waypoint's snap and route check at the
pick, the passing and stuck rules where the bookmark advances, and the
leg's snap and route check once per target point (a refused leg switches
to the mesh's own route to the waypoint, or drops it). Before this stage: Roaming (`buddies_roam_strategy.cpp`, the roam action) hands
the bot module's walking a point up to 8 yards along its planned path
each tick. The bookmark of "the next point not yet passed" moves only
when the buddy comes within 2 yards of that exact point, so a point she
can't reach (on a rock, 2.7 yards above the ground beside it, seen
2026-10-03) holds her forever: the walking refuses an order to where she
already stands, and nothing gives up. A point the mesh can't route to is
walked to in a straight line by the server.

## Intended Behavior

- **Onto the mesh**: a newly picked waypoint, and each path point before
  its leg is ordered, is moved to the nearest spot on the mesh within
  `SNAP_YARDS`; none that near and the pick is dropped (a waypoint) or
  the rest of the planned path is replaced by the mesh's own route to the
  waypoint (a path point).
- **Only complete routes**: before a leg is ordered, the mesh is asked
  for the route; anything but a complete route (no route, a partial one,
  a straight-line shortcut, an end far from the mesh) means the leg is
  not ordered: the planned path is replaced by the mesh route to the
  waypoint, and if that too is incomplete the waypoint is dropped and a
  new one picked.
- **Passing points**: every point up to the farthest one within reach of
  the buddy counts as passed, not only the bookmarked one.
- **Stuck points**: a bookmarked point not reached after `STUCK_MS` of
  no progress (standing, the order refused) is skipped; the last one
  skipped ends the waypoint as reached.
- The movement trace gets the mesh's answer on each leg ("complete",
  "partial", "none", "shortcut") and each snap's distance.

## Suggested Implementation Steps

1. `buddies_navmesh.cpp` / `.h`: nearest mesh point, route with its
   kind (the server's own path search, `PathGenerator`), and the line
   test (for 617o4), each in plain words in the header.
2. In the roam action: snap the waypoint at the pick; before each leg,
   snap the point and ask the route; the passing and stuck rules where
   the bookmark advances.
3. Watch Mozonn in Ammen Vale with `.buddy trace Mozonn`.

## Open Questions

- (Needs more testing, the owner 2026-10-03: "requires additional
  testing, keep it in the back of your head") "Carago didn't seem to walk
  into the structure in Ammen Vale": he no longer walked through its walls
  (this stage working), or he never went inside when he should have?

## Related Issues

- **617o** parent; **617e2** (the trace, the roaming core)
