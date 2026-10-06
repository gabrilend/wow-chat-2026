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

**Moving doodads built 2026-10-06:**
- **What moves:** a doodad whose standing animation moves any bone
  (`anim_moves`: a track with more than one moment in it) keeps its
  skeleton.
- **How:** `doodads_animate` bends it once a frame on the processor. All
  its copies share that pose and play in step, as the original plays
  them.
- **At Astranaar:** 51 of the 394 models move. Measured on Astranaar's
  own tile:
  - birds circle overhead, up to 38 yards;
  - fish swim, up to 4 yards;
  - the hippogryph roost moves, up to 5 yards;
  - fireflies drift, up to 1.6 yards;
  - street lamps sway 0.3 yards, banners 0.08.
  The giant Ashenvale trees don't move: their standing animation is
  still in the original too.
- **Picture option:** `--clock MS` starts the world's animations later.

**Faults the owner saw (2026-10-06):** "there's some scaling issues on
some doodads (like the archway near the bridge has weird moss stretched
over it?) and some of the particles halos seem off (like they are meant
to be 360 degrees displayed as an orb, but they turn out to be painted
flat? But only some of them)". Likely causes, to be confirmed:
- **Moss:** a piece drawn with two pictures (a skin unit's picture count
  above 1). The client draws only the first, with the first set of
  picture positions, and ignores picture-position animation (the M2's
  UV animations). A second, moss layer meant to blend or scroll is
  instead stretched across the arch.
- **Flat halos:** these are not particles but flat squares in the model
  on bones marked to face the camera (bone flags 0x8 and 0x40-0x200:
  billboards). The client ignores the marks, so they stay flat as made.
  Only some orbs are built this way, which fits "only some of them".

**Flat halos fixed (2026-10-06), to be confirmed by the owner:**
- **The cause, as suspected:** camera-facing bones. Around Astranaar the
  street lamps, the wisps and the fireflies have bones marked to face
  the camera (flag 0x8), and the boat and the gazebo have ones marked to
  turn upright toward it (0x40).
- **The fix:** `anim_pose_facing` turns such a bone so that its x axis
  (the side the original's billboard squares face) points at the camera,
  keeping its pivot where its pose put it. Upright ones turn round z
  only.
- **In the drawer:** a model with such bones is posed and bent per copy,
  into its own meshes (`bend_copies` in `doodads.c`), since each copy is
  turned its own way. Every other model still shares one pose.
- **Seen:** the street lamp's halo is now a round glow.
- **Test:** the lamp's glow bone turns its face to a camera off to the
  side.

**Left:**
- The moss fault above.
- Pieces whose picture the game chooses at run time (none so far at
  Astranaar).
- Particles (torch flames, wisps, firefly glow) and picture animations
  (scrolling water, glowing runes): what makes the torches and wisps look
  alive. Both are separate parts of the model files, not read yet.
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
