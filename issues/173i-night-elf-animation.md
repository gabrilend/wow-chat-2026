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

**Built 2026-10-06**, in C:
- **`anim.h` / `anim.c` read her skeleton.** That's 147 bones and 151
  animations, plus the 44 animations kept in .anim files beside her
  model, attached at start. Aliases are followed to the animation that
  holds the data.
- **Posing:** a bone's pose at any moment comes from blending the two
  recorded moments around it (straight lines for moves and stretches,
  the shorter way round for turns), then parent times local, the
  original's way.
- **Bending her body (skinning)** is done on the processor, not the
  graphics card (step 2 asked for the card). For 4,113 points a frame it
  is cheap, and simpler to test. The card can take it over when many
  characters are drawn.
- **`moves.h` / `moves.c` choose the animation** from what she did this
  frame:
  - Standing: stand, with fidgets picked by the model's own frequencies.
  - On the ground: run, walk backwards, or the turning shuffle on the spot.
  - In the air: the jump's start once, then the jump loops. Dropping off
    an edge plays the fall.
  - Landing standing still plays the landing; landing on the move carries
    straight on.
  - The run plays at her real speed over the speed it was made for (8.4
    against 6.94, so 1.21 times), so her feet don't slide.
  - Changes blend over the new animation's blend time (150 ms when it
    gives none).
  - Strafing plays the run with her body turned toward the strafe: 45
    degrees on a diagonal, 90 straight sideways, eased at 10 radians a
    second. This is this client's reading of the original, still to be
    compared.
- **`main.c`** bends her points each frame and copies them into her pieces.
- **Picture option:** `--pose ID MS` holds her in an animation for
  pictures. Standing and mid-run pictures look right.
- **Tests:** 15 checks.
  - Her skeleton and its .anim files all read, and every animation the
    mover uses is there.
  - Standing, her lowest point is on the ground and she is 2.27 yards
    tall.
  - Half a stride apart, the run moves her by 0.64 yards, and its end is
    its start.
  - The choices above each pick the right animation, and the run plays at
    the right rate.

**Left:**
- Comparing the strafe body-turn with the original.
- The walk (only used when walking is toggled, which isn't built yet).

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

1. When the original strafes straight sideways, does her body turn a
   full 90 degrees and run, or does she side-step facing forward? This
   client turns her 90 degrees for now.
