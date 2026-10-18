# 173r - Water and Swimming

*Continues in the W client (`/mnt/kaun/custom-client/`), since the move on 2026-10-07 (173v): 309, 801. This issue stays as the record of how the client began; its paths are as they were then.*

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173q (collision), 173f (the ground)
- Related: 173n (light: water colours by time of day), 173i (animation:
  swim, swim idle)
- Priority: High (owner, 2026-10-06: "Then water and swimming.")

## Origin

Verbatim, 2026-10-06: "Then water and swimming."

## Current Behavior

**Built 2026-10-06** (ground files' water; buildings' pools not yet):
- **Reading:** `adt.c` reads MH2O. For each chunk it gives every water
  layer's kind, which cells are wet, and its surface heights.
  - **A fault found and fixed:** some layers hold heights of 0 at points
    round their wet cells while stating a range of 102.76 to 102.76.
    A height outside the layer's stated range now takes its lowest.
- **The water map:** `liquid.h` / `liquid.c` (no Raylib) file the
  layers by chunk and answer "the surface here" (blended between a
  cell's corners, the highest layer winning).
- **Drawing:** `water.h` / `water.c`.
  - One mesh per layer over its wet cells.
  - Each kind's numbered ripple pictures from LiquidType.dbc, at 15 a
    second, repeating once a cell.
  - Tinted by the zone's river or sea colour (`light.c` now reads the
    water bands 14-17), lit a little, fogged.
  - See-through (0.75) after the solid world. Lava and slime are drawn
    solid and unlit.
- **Swimming** (`mover.c`):
  - She swims when the water is deeper than 1.6 yards over her feet.
  - Swim speed is 4.72 yards a second forward (2.5 back), times her
    bonus.
  - With the right button held, forward follows the camera's pitch.
    Space goes up, X goes down.
  - Left alone, she floats up to the surface at 2 yards a second.
  - She can't rise past the surface nor sink through the bottom, and
    walls stop her. She walks out where the bottom rises.
- **Animations** (`moves.c`): swim, swim backwards, swim left and right,
  and treading water. Her body faces ahead while swimming.
- **At Astranaar:** the lake round the town island (surfaces at 100.43
  and 102.76) draws and can be swum in. From above, she swims beside a
  moored boat.
- **Tests:** 10 checks.
  - Astranaar's 60 layers read with no stray zeros. The lake has water,
    the town none.
  - She swims in deep water, floats up to 1.6 under the surface, dives
    with X, swims at 5.67 yards a second, and walks out onto a shore.
  - The swim animations are chosen right.

**The view underwater (2026-10-06; the light since 2026-10-07):** with
the camera below the water's surface, the light is the zone's own
underwater set (173n: at Astranaar, fog from 0 to 167 yards in dark
teal). It first was a stand-in: the zone's deep-water colour from 0 to
40 yards. Diving at Astranaar's
deepest water (20.8 yards, at 2866, -331), murky water closes in round
her, with seaweed and the lake bed. Picture option `--dive S` holds X
after the walk.

**Buildings' pools (built 2026-10-06):**
- **Reading** (`wmo.c`): each building part's pool (MLIQ): a grid of
  points with surface heights, in the building's own space, and a flag
  byte per cell (low four bits all set: dry). The layout and the dry rule
  are the server's own (AzerothCore's `vmap4_extractor/wmo.cpp` and
  `WorldModel.cpp`).
- **Its kind** (`wmo_liquid_kind`): by the server's extractor's rule (the
  part's liquid field, an older numbering unless the root says otherwise,
  else the first wet cell's), mapped to the building liquids: water 13,
  sea 14, magma 19, slime 20.
- **Placed** (`doodads.c`): a building's pools are kept with it; each
  placed copy hands them, with its placement, to the water drawer
  (`water_add_pool`: its wet cells as a mesh, drawn as ground water is)
  and to the water finder (`liquid_add_pool`: a spot turned into the
  building's space, its cell found, the height blended and turned back).
  They go with the tile that brought them.
- **Around Astranaar:** the small night-elf houses hold a 2 x 2-cell basin
  in their garden (seen: it fills inside its wooden rim, ankle-deep), and
  the Timbermaw cave (3257, -660, under the hill) a 32 x 29-cell pool.
- **Tests:** the house's pool reads as 3 x 3 points of building water;
  turned and placed, its surface is found where the original's files put
  it (109.88), none 15 yards off; dropping the tile forgets it.

**Depth (built 2026-10-06):** the ground files' water carries a depth
byte per point (formats 0, 2 and 3); measured against the ground at
Astranaar's lake, it is the depth in yards times about 9 (174 at 19.4
yards), so 255 is about 28 yards. `adt.c` reads it (`AdtLiquid.depth`),
`light.c` reads the water's shallow and deep opacity from LightParams
(fields 6-9, blended between lights like the colours), and `water.c`
shades each point from the near colour and shallow opacity to the deep
ones by depth / 255. Seen: by the shore the lake is see-through, out in
the middle opaque. The straight 0-255 curve is this client's guess (check
list); buildings' pools have no depth in their files and are drawn
shallow. Tests: the lake's bytes run 0 to 186 (its deepest is 20.8
yards); Astranaar's water opacity is 0.75-1 for the sea, 0.5-1 for rivers.

**Left:**
- The original's own swim depth for her model (an open question, below).
- Telling the server she swims (with the network).

## Intended Behavior

- **Water drawn:** the ground files' liquids (MH2O: per chunk, its
  liquid kind, its height grid and which cells it covers) and buildings'
  pools (MLIQ). Each is drawn with its liquid's own scrolling pictures
  (LiquidType.dbc) and coloured by the zone's water colours (the light's
  river and ocean bands, 173n).
- **Swimming:** in water deeper than her waist she swims. She floats at
  the surface, moves at swim speed (the game's base 4.72 yards a second,
  times her bonus), swims up and down with the camera's pitch and the
  jump key, and plays the swim and swim-idle animations. She leaves the
  water by walking out onto ground.
- **The server** is told she is swimming (a movement flag) when the
  client talks to it.

## Suggested Implementation Steps

1. Read MH2O; a test that Ashenvale's rivers have water where the map
   shows them.
2. Draw it.
3. The mover's swim mode; tests.
4. Swim animations.

## Open Questions

1. How deep over her feet the water must be before she swims, and how
   deep she floats: the original's numbers (per race and model) aren't
   read yet; this client uses 1.6 yards. To check in-game (listed in
   docs/custom-client-ingame-checks.md).
