# 173r - Water and Swimming

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

**The view underwater (2026-10-06):** with the camera below the water's
surface, the fog becomes the zone's deep-water colour (river or sea band)
from 0 to 40 yards (this client's distances). Diving at Astranaar's
deepest water (20.8 yards, at 2866, -331), murky water closes in round
her, with seaweed and the lake bed. Picture option `--dive S` holds X
after the walk.

**Buildings' pools:** around Astranaar only one building carries water (a
small house: a 2 x 2 patch), so buildings' pools (MLIQ) wait; recorded,
low priority.

**Left:**
- Buildings' pools (WMO MLIQ).
- The original's own swim depth for her model (an open question, below).
- Depth-darkened water (deep against shallow colours).
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
