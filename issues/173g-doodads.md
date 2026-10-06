# 173g - Doodads (trees, rocks, buildings)

## Status
- Created: 2026-10-05
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173f (the ADT reader)
- Priority: High (second of the owner's next five)

## Origin

See 173f (the owner's order, 2026-10-05).

## Current Behavior

Not built. Only the ground and the night elf are drawn.

## Intended Behavior

Every object the map places is drawn where the original client draws
it: the ADT's small models (MDDF: trees, rocks, fences; M2) and its
buildings (MODF: WMO, with their groups and their own doodad sets), each
at its position, rotation and scale, textured, through the readers built
for the night elf (`lib/m2.lua`, `lib/blp.lua`) plus a WMO reader. Models
are loaded once and drawn many times.

## Suggested Implementation Steps

1. Read the placements (MMDX/MMID/MDDF, MWMO/MWID/MODF) from the ADT.
2. Static M2 doodads first (resting pose), sharing meshes and pictures.
3. A WMO reader: root file (materials, groups, doodad sets) and group
   files (vertices, indices, batches).
4. Placement maths checked against the server's own collision placements
   (`data-files/vmaps`), which come from the same records.

## Open Questions

None yet.
