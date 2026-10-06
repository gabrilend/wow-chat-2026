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

Not built. There is no water: she walks along river and lake beds.

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

None yet.
