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

**Small models (M2 doodads) built 2026-10-06**, in C:
- **Reading the placements:** `adt.c` reads each ground file's model
  names (MMDX/MMID) and placements (MDDF), and its building names and
  placements (MWMO/MWID/MODF) too. Each placement becomes a world
  position, turn and size.
- **Placing them:** `adt_place_matrix` builds the turn the way the
  original's model viewer orders it, around the game's axes. With only
  the heading set, a model faces 180 degrees past its angle.
- **Drawing them:** `doodads.c` loads each model once, with its pieces,
  pictures and materials. It draws every copy of a piece in one call.
  Solid and cut-out pieces (leaves) come first, then see-through and
  glowing ones without depth writing. A doodad listed by two tiles is
  drawn once.
- **The model reader:** `m2.c` now gives each piece its material (blend
  mode and flags) and checks that every table it reads lies inside the
  file.
- **At Astranaar:** 247 models and 6,671 placements in the 3 x 3 tiles,
  none left out.
- **Tests:**
  - 925 of the tile's 1,074 doodads stand within 2 yards of the server's
    ground. The rest stand on rocks, roots or buildings.
  - A 30-degree turn faces a model's front at 210 degrees, upright, at
    twice the size.
  - The tile places buildings.

**Buildings (WMO) built 2026-10-06:**
- **The reader:** `wmo.h` / `wmo.c` read a building's root file (its
  materials, furnishings and furnishing sets) and its group files (points,
  facings, picture positions, baked colours, triangles, and batches of
  one material each). Every block is bounds-checked.
- **The drawer:** `doodads.c` keeps each building as one model entry
  whose pieces are all its groups' batches, drawn like any doodad. Each
  placement also places furnishing set 0 (shown by every copy) and the
  set the placement names. A furnishing's matrix comes from
  `adt_inside_matrix`: scale, turn, move, then the building's own place.
- **Indoor light:** indoor groups are lit by their baked colours plus a
  little ambient light. This is this client's first reading of the
  original's indoor light, still to be compared with it.
- **At Astranaar:** 394 models (doodads and buildings) and 7,383
  placements.
- **Tests:**
  - All 7 of the tile's building placements read, with their first part.
  - All 228 of their furnishings land inside the box the ground file
    gives each building.
- **Picture options** for checking: `--turn DEG` and `--pitch DEG` aim
  the camera.

**Left:**
- Pieces whose picture the game chooses at run time (none so far at
  Astranaar).
- Swaying and other animation (models are drawn in their resting pose).
- Step 4's cross-check against the server's collision placements
  (`data-files/vmaps`). The furnishing-box check and the pictures cover
  placement for now.
- Comparing the indoor light with the original.

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
