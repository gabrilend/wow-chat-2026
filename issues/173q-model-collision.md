# 173q - Model Collision

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173g (doodads and buildings), 173a (the mover)
- Related: 173e (what the server checks: it trusts the client's position)
- Priority: High (owner, 2026-10-06: "Can we work on model collision next?")

## Origin

Verbatim, 2026-10-06: "Can we work on model collision next? Then water
and swimming."

## Current Behavior

Not built. She walks only on the map's ground: through trees, walls and
buildings, and under bridges and floors.

## Intended Behavior

She collides with the world's models as in the original:
- **Shapes:** each small model's own collision shape (the M2's collision
  triangles, header offsets 216 and 224, simpler than what is drawn), and
  each building's triangles that its MOPY flags mark as solid (collision,
  or drawn and not detail). Trees, rocks, fences, walls, floors, stairs,
  bridges. The furniture inside buildings counts too.
- **Placed** with the same matrices as drawn, gathered into a grid of
  small cells so the mover asks only about triangles near her.
- **Floors:** the ground under her is the highest surface at or below her
  feet plus a step height, whether the map's ground, a bridge, a floor or
  a stair. She walks onto it, falls onto it, and the slope rule applies
  to it as to the map's ground.
- **Walls:** moving into a surface too steep to stand on stops her short
  of it, and she slides along it rather than sticking.
- **The server** doesn't re-check this (173e: it trusts the client's
  position), so the client's own collision is what keeps her honest.

## Suggested Implementation Steps

1. Read the collision triangles (M2 collision mesh; WMO MOPY flags).
2. A world store: triangles placed in world space, in a grid; the
   floor-height and wall questions. Pure C, tested with made-up shapes.
3. The mover asks the world for floors (with her height) and walls.
4. Tests on Astranaar: standing on a bridge, stopped by a building's
   wall, walking up a stair.

## Open Questions

1. Her step height (how high a ledge she walks up without jumping) and
   her body's radius are the original's own numbers; until measured,
   this client uses 1 yard and 0.4 yards.
