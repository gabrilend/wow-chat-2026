# 617o - Buddy Pathfinding on the Navigation Mesh

## Status
- Created: 2026-10-03
- Phase: 6
- Parent: 617
- Blocked by: 617e2 (the roaming core), 617e6 (the exploring grid)
- Sub-issues: 617o1 (the mesh decides), 617o2 (rooms and tunnels on the
  mesh), 617o3 (baked distance maps), 617o4 (steering toward moving
  targets, and the turn rule), 617o5 (climbing for a view, circling what
  blocks it)
- Priority: High (buddies walk through walls and stand stuck)

## Origin

2026-10-03, watching Mozonn (a level-1 buddy in Ammen Vale) with the
movement trace (617e2): she walked through a wall, then stood still for
good. The trace showed why: the roaming planner and the walking judge the
world by two different maps.

The owner: "So... Why don't we plan with the same navmesh that we're
going to walk with?" And earlier: "I'm thinking pathfinding between
areas, pathfinding in towns, and other similar places could use a baked
pathfinding map. Then, when we're fighting monsters or chasing down
dynamically moving NPCs or other such things, then we'd do path-based
calculations with straight-line paths updated every half-second or so,
and lerping the orientation to the intended direction over 2/5ths of a
second." On the four stages: "okay let's build all four of these then
recompile. It's okay if they don't work, we'll test the behavior
bit-by-bit."

## Current Behavior

Two pictures of the ground disagree:
- **The planner** (the pinwheel and the exploring grid, 617e2 and 617e6)
  judges ground by the terrain height lookup (`Map::GetHeight`), which
  knows hills and buildings' floors but not rocks, crystals, wreckage and
  other placed objects. It picks points the walking can't reach.
- **The walking** (the bot module's move order, then the server's point
  movement, `PointMovementGenerator.cpp`) searches the navigation mesh,
  which does know those objects. When the search finds no route, the
  server moves the unit **in a straight line**, through anything between.

So a point on a rock gets either a walk that ends short (roaming waits
for a point it can never reach: she stands forever) or a straight line
through a wall.

## Intended Behavior

The navigation mesh is the only judge of where a buddy can stand and how
it gets there; the planners keep deciding where it *wants* to go. Built
in four stages, each testable alone with the movement trace:

| ID | Name | Dependencies | Description |
|----|------|--------------|-------------|
| 617o1 | mesh-decides | None | Every waypoint and path point moved onto the mesh; a leg ordered only along a complete mesh route, never a straight-line fallback; points reached are passed, stuck points skipped |
| 617o2 | rooms-on-the-mesh | 617o1 | The exploring grid measured on the mesh (a cell is floor when the mesh is there, two cells join when the mesh's straight-line test passes between them), so rooms and tunnels match the walls |
| 617o3 | baked-distance-maps | 617o2 | Distance-to-goal maps over a grid for fixed goals (the area's middle, town errand spots), built once on a worker thread and walked downhill |
| 617o4 | steering-to-moving-targets | 617o1 | Re-aim every half second at a moving target, straight when the mesh says the line is clear, by path otherwise, turning smoothly over 0.4 seconds; used to bring a buddy to the edge of a monster's notice radius |

| 617o5 | vantage-and-orbiting | 617o2 | With no sight of the area's middle: climb the nearest hill for a view, or circle the object in the way; after a whole circle, route out past it |

Execution order: `617o1 → (617o2 → (617o3 ∥ 617o5)) ∥ 617o4`.

Why split: each stage changes a different part of the walking (the leg,
the grid, long trips, live targets) and each can be seen working or not
in game on its own; one issue could not be tested piece by piece, which
the owner asked for.

## Suggested Implementation Steps

1. One small file of mesh questions for the module
   (`patches/B036-mod-buddies/mod-buddies/src/buddies_navmesh.cpp`): the nearest point on
   the mesh, whether a straight line stays on the mesh, a full route and
   whether it is complete. Each bot thread keeps its own mesh-query
   object (the server's notes say a query object is not safe to share
   between threads).
2. Then each stage's own steps, in its sub-issue.

## Related Issues

- **617** parent; blocked by **617e2**, **617e6**; **617e3** (the
  monster steering 617o4 serves), **617e4** (town walking 617o3 serves)
