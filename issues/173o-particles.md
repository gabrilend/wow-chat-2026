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

Not built. Models with particle emitters (torches, wisps, fireflies)
draw only their solid pieces.

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
