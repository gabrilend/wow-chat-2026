# 617o2 - Rooms and Tunnels Measured on the Mesh

## Status
- Created: 2026-10-03
- Phase: 6
- Parent: 617o
- Blocked by: 617o1 (the mesh questions)
- Priority: Medium

## Current Behavior

**Written 2026-10-03, syntax-checked, not yet built or run**
(`buddies_explore.cpp`, the measuring): a cell with ground but no mesh
within 1.5 yards sideways and 3 up or down is not floor, a floor cell's
height is the mesh's, and a step between cells needs the mesh's line test;
the "ready" log line counts cells without mesh and steps walled off. Not
done: loading mesh tiles the map hasn't loaded (the height probe's own
loading is relied on; the "no mesh" count shows whether that is enough).
Before this stage: The exploring grid (`buddies_explore.cpp`, the measuring)
paces out an area 3 yards at a time from where the owner stands: a cell
is floor where the terrain height lookup finds ground in the area, and
two cells join where the height changes by no more than one yard per
yard. Placed objects (rocks, crystals, wreckage, fences) are invisible to
that lookup, so the grid's floor runs through them and its rooms and
tunnels don't match the walls a buddy actually meets.

## Intended Behavior

- A cell is floor when the mesh has a spot within `GRID_SNAP_YARDS` of
  the cell's middle at about the ground's height; its height is the
  mesh's.
- Two neighbouring cells join only when the mesh's straight-line test
  passes from one middle to the other (no wall, no gap, no cliff between).
- The mesh tiles of the area are loaded for the measuring if the map
  hasn't loaded them (an area wider than what players stand near); the
  measuring says in its log line how many it loaded.
- Everything built on the grid (rooms, tunnels, the squished circle,
  least paint, 617o3's maps) then follows the mesh.

## Suggested Implementation Steps

1. In the grid's measuring step, after the height probe: the mesh point
   for the cell; a cell with none is not floor.
2. The joining test between a cell and the neighbour it was reached from:
   the line test from 617o1's mesh file.
3. Load the area's mesh tiles before measuring (the map's own tile
   loader).
4. Compare the "ready" line's counts (walkable cells, rooms, tunnels) for
   Ammen Vale before and after.

## Related Issues

- **617o** parent; blocked by **617o1**; **617e6** (the grid's design)
