# 1201b - A Map's Navigation Mesh as Roaming Areas

## Status
- Created: 2026-10-17
- Phase: 12
- Parent: 1201 (robot search party)
- Blocked by: nothing
- Priority: Medium

## Current Behavior

The roaming pattern takes an area as an outline or a union of
axis-aligned rectangles, plus rocks (circles) (`docs/roaming-pattern.md`,
"The data model"). In World of Warcraft those come from the project's
own mesh tooling (`scripts/lib/navmesh-tiles.lua`, 617o2's rooms).
Nothing reads Left 4 Dead 2's navigation mesh.

## Intended Behavior

Left 4 Dead 2's navigation mesh is made of nav areas: rectangles in
plan, each with its four corner heights, joined to neighbours, and
tagged with attributes (the map's flow from start to safe room, spawn
rules, and more). Two readers turn it into the pattern's areas:

- **In the game** (`src/l4d2/nav-areas.nut`): the script walks the nav
  areas through the game's NavMesh interface, groups joined areas into
  rooms (by the same rule 617o2 uses for rooms: joined floor, cut at
  narrow doorways), and gives each room to the pattern as a union of
  rectangles with its heights.
- **Offline** (`scripts/export-l4d2-nav-areas`): the same rooms written
  to a plain file per map, so 1201a's checks and the GIF generator can
  run on a real map with the game closed. Exported once from inside the
  game (a console command that writes the file), not by parsing the
  `.nav` format ourselves.

## Suggested Implementation Steps

1. Find, in the game, what the NavMesh interface returns for an area
   (its extents, corner heights, connections, attributes); write it
   into a comment at the top of `nav-areas.nut`.
2. The grouping into rooms, with its narrow-doorway rule taken from
   617o2.
3. The export command and the file format (one line per rectangle,
   one block per room).
4. A check: a map's exported rooms cover every walkable nav area once,
   and no room's rectangles overlap.

## Open Questions

- Are the corner heights needed, or is each rectangle's middle height
  enough for robots that walk (no jumping between levels)?
