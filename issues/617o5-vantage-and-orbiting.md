# 617o5 - Climbing for a View, Circling What Blocks It

## Status
- Created: 2026-10-03
- Phase: 6
- Parent: 617o
- Blocked by: 617o2 (the grid on the mesh: heights and joins to climb by)
- Related: 617o3 (the distance-to-middle map, the other answer to the
  same failure)
- Priority: Medium

## Current Behavior

**Written 2026-10-03, syntax-checked with the build's own flags, not yet
built or run.** When the pinwheel and the rooms find no waypoint, the
roam action (`buddies_roam_strategy.cpp`, "the view") asks what blocks the
look at the middle (`BuddySightBlocker`, `buddies_navmesh.cpp`: the map's
collision models for an object, terrain heights every 2 yards for the
ground):
- **an object**: its patch of non-floor cells on the grid gives its
  middle and its reach (`BuddyExploreObstacle`, `buddies_explore.cpp`; a
  patch over 1,500 cells, or running off the grid, is not circled); the
  buddy circles at the reach times 1.15 to 1.30, a random direction each
  time, 4 yards a step on the mesh, turning by the turn rule; the middle
  coming into sight at any point ends it; a whole circle without sight
  routes it to the spot 3 yards outside the circle toward the middle;
- **the ground**: one of the three hills at random
  (`BuddyExploreHilltop`): the hilltop nearest the middle, the hill in the
  way (the highest floor under the straight line, then uphill to its
  top), or the high ground nearest the buddy (hilltop: no floor within 3
  cells higher; at least 3 yards above the buddy; reachable over the
  grid's joins); it climbs by that hill's distance map, looks once it has
  climbed 85% of the rise, then looks at every step on up, giving up at
  the top;
- **nothing**: the distance-map stretch toward the middle (617o3).
A climb or circle not done in 60 seconds is given up. Before this stage,
the pinwheel found no waypoint and (since 617o3) walked a stretch toward
the middle.

## Intended Behavior

The owner, 2026-10-03, on the "no sight of the middle" case:

> in this case, we should walk to the top of the hill that is nearest to
> the middle, to get a better vantage point. We only have to walk to the
> top ~85% of the hill though. If the line-of-sight check still doesn't
> work, then we walk upward until it does.
>
> also, if there's a doodad in the way, then we should orbit that doodad
> until we get a good line-of-sight. If we do a complete circle, then we
> should prune the waypoint paths until they reach out of the circle we
> made, and then route to that spot instead. A doodad is a vocabulary
> term from Warcraft 3, idk if they use the same terminology here.

(WoW uses the same word: its map files call the placed objects
"doodads", as the server's own map extractor names them, apart from the
large buildings, "world map objects".)

- **What blocks the view decides the answer.** The sight test's hit point
  says where the line stopped: on the ground (a hill) or on a placed
  object (a doodad, or a building).
- **A hill: climb for a view.** Of the grid's hilltops (cells higher than
  every neighbour within `HILL_RADIUS`), the one nearest the middle that
  the buddy can walk to; the buddy walks the grid's route toward it and
  stops where it has climbed `VANTAGE_SHARE` (85%) of the rise from its
  own height to the top's, then tests the sight again. Still blocked: on
  up the same route, testing at each cell, to the top at most.
- **A doodad: circle it.** The buddy orbits the object at the distance of
  the hit point, a little way off its edge, on the mesh, testing the
  sight as it goes. Sight found: the pinwheel resumes from there. A whole
  circle without sight: the pinwheel's candidate paths are cut where they
  leave the circle the orbit traced, and the buddy routes (617o1) to the
  first point of a cut path outside the circle.

## Suggested Implementation Steps

1. The sight test's hit point and what was hit (the server's line of
   sight against the map's objects, against the terrain alone, compared).
2. The hilltops of a grid, found once when the grid is ready.
3. The climb, as a roaming mode with its own trace lines.
4. The orbit, as a roaming mode: the circle's centre and radius from the
   hit point, steps round it on the mesh, the turn rule (617o4) at each.
5. The prune and route after a whole circle.

## Open Questions

- (Answered 2026-10-03) Which hill: "one of these three randomly".
- (Answered 2026-10-03) The prune after a whole circle: "um sure. We
  don't even need to make a full circle if the intended path crosses the
  orbit circle she's making, then great! Just follow the path. She should
  orbit in a random direction each time she comes to such a case." Built
  as: the middle coming into sight anywhere on the circle ends the circle.
- (Answered 2026-10-03) The circle's distance: "depends on the shape of
  the object. From it's center to it's most distant component, add
  15-30%."

## Related Issues

- **617o** parent; blocked by **617o2**; **617o3**, **617o4**, **617e2**
