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

**Built 2026-10-06**, in C:
- **Shapes:**
  - `m2_collision` (`m2.c`) reads a small model's collision triangles.
  - `wmo.c` reads each building triangle's MOPY flags. `wmo_solid` keeps
    those marked collision, or drawn and not detail.
  - `doodads.c` keeps each model's solid shape and adds it, placed, for
    every copy, including buildings' furniture.
- **`collide.h` / `collide.c` (no Raylib)** keep the placed triangles in
  a grid of 4-yard squares and answer two questions.
  - **The floor:** the highest surface under a point at or below a
    height, with its slope.
  - **Walls:** rays along the step at knee, waist and head height,
    reaching her radius past the step, against triangles too steep to
    stand on. The nearest hit gives the wall's facing.
- **The mover** (`mover.c`) asks for the floor up to a step (1 yard)
  above her feet on the ground, or just below her in the air, so she
  lands on bridges and never snaps up through them. A wall stops her;
  she slides along it with what's left of her step. In a corner she
  stops. A slide down a slope ends at a wall.
- **`main.c` combines the map's ground with the models' floors:** the
  model's wins when higher, or when the map's ground is above her (she
  is beneath it).
- **At Astranaar:** 216,661 solid triangles. Running at a house, she
  stops flush against its stone wall. Running at a raised wooden deck,
  she stops at its edge.
- **Picture options** for this: `--face DEG` and `--walk S`. The picture
  waits until the walk is done.
- **Tests:** 11 checks, on made-up shapes.
  - A plank is the floor above it, and not below it.
  - A wall is hit when walked at, not past its end.
  - A riser lower than her step isn't a wall; a higher ledge is.
  - She stops 0.46 yards short of a wall, slides along it at an angle
    and on past its end, walks up a half-yard step, stops at a two-yard
    ledge, and lands on a plank dropped onto.

**Left:**
- The original's own step height and body radius (open question 1).
- Walls for the camera (it still passes through models).
- Doors and moving objects (game objects come with the server).

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
