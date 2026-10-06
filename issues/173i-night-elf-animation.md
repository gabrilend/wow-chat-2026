# 173i - Night Elf Animation

## Status
- Created: 2026-10-05
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173d
- Priority: Medium (fourth of the owner's next five)

## Origin

See 173f (the owner's order, 2026-10-05).

## Current Behavior

Not built. She stands in the model's resting pose and glides as she
moves.

## Intended Behavior

She moves as in the game: standing, walking, running, running
backwards, strafing, turning, jumping (start, in the air, landing),
falling, and the idle fidgets, each the model's own animation (by the
game's animation ids, AnimationData.dbc), blended across changes, at the
speed the original client plays them for her movement speed (120%).

## Suggested Implementation Steps

1. Read the M2's bones (positions, rotations, scales per animation,
   with their timestamps) and its animation list; the .anim files some
   animations keep apart.
2. Skin her on the graphics card: each vertex moved by up to four bones
   by its weights.
3. Choose the animation from the mover's state; blend 150-ish ms.
4. A test: each named animation exists for her model; a bone's pose at a
   known time matches the file.

## Open Questions

None yet.
