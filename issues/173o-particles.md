# 173o - Particles

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173g (doodads), 173n (light)
- Priority: High (owner, 2026-10-06: "let's work on particle effects next.")

## Origin

Verbatim, 2026-10-06: "let's work on particle effects next." (after:
"Torch flames, the floating wisps and the fireflies' glow are particles
... That's what will make Astranaar look alive at night.")

## Current Behavior

**Built for doodads, 2026-10-06**, in C:
- **`particles.h` / `particles.c` (no Raylib) read and run emitters.**
  - Each emitter's bone, position, picture slot and grid, blend, shape,
    animated settings (as tracks, through `anim_track_value`, which
    `anim.c` now exports for any track kind), and its colour, opacity,
    size and cell over life.
  - Each frame the living age, fall by gravity, slow by drag and move.
    New ones are born at the rate (with its variation), placed over a
    plane or a sphere shell, shot up or outward within the spreads, at
    the speed and its variation.
  - Particles live in the world: once born, they don't follow the emitter.
- **`doodads.c` runs them:**
  - Each placed copy of a model with emitters runs its own, while within
    150 yards of the camera. Farther copies hold none.
  - The model keeps its skeleton for this even when it doesn't move.
  - They're drawn after everything solid as squares facing the camera,
    added or see-through as the emitter says, without writing depth.
- **At Astranaar:** 47 of the 394 models have particles. At night the
  gate's orb and the lamp posts glow.
- **Picture mode** now runs 3 world-seconds (60 steady frames) before
  its picture, so particles have filled out.
- **Particles in fog** (`particles_fog`): by its distance into the fog,
  a see-through particle's colour goes to the fog's, and an added-light
  one's goes dark, so far sparks vanish rather than lighting the fog.
- **Tests:** 7 checks.
  - The torch has 2 emitters. Its flame makes 20 sparks a second, each
    living 1 second, added light, from a 4 x 4 grid.
  - After 2 seconds about 20 live, rising from the flame.
  - A new spark is orange.
  - Past the fog's end a spark adds nothing and a see-through particle
    is the fog's colour; before its start, a spark is untouched.

**Left:**
- Figures' particles (spells, weapon glows). None of the figures shown
  today (her, the tauren, furbolg, ancient protector and nightsaber)
  has an emitter (checked 2026-10-06: each model's emitter count is 0),
  so this waits for spells and items that carry them. Their glowing
  pieces (an eye's glow) are drawn now (173d).
- Ribbons (trails).
- Spline emitters, which are run as planes.
- Wind and twinkle.
- Lit particles (flag 0x1).
- Comparing torches with the original up close.

## Intended Behavior

Every model's particle emitters run as the original runs them:
- **Reading:** each emitter is read from the model file (3.3.5a: header
  offset 296, 476 bytes each). That gives the bone it rides on, its
  position, its picture (cut into a grid of cells), how it blends, its
  shape (a plane or a sphere), and its animated settings: speed and its
  variation, spread, gravity, lifespan, rate, area. It also gives how
  each particle's colour, opacity and size change over its life.
- **Running:** particles are born at the emitter's rate, fly with their
  speed, gravity and drag, and age through their colour, opacity and
  size. They die at the end of their lifespan.
- **Drawing:** each particle is a square facing the camera, from its
  picture's cell, blended as the emitter says (see-through or added
  light), over the solid world.
- **Where:** doodads first, each placed copy with its own emitters, run
  only near the camera. Figures (spells, weapon glows) come later.

## Suggested Implementation Steps

1. Read the emitters. Test: Astranaar's torch has an emitter, with a
   picture, a lifespan and a rate.
2. Run them (pure C, testable): a particle's age, position and colour
   over time.
3. Draw them in the client; pictures by night.

## Open Questions

None yet.
