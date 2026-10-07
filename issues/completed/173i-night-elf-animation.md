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

**Built 2026-10-06 and 2026-10-07**, in C:
- **`anim.h` / `anim.c` read her skeleton.** That's 147 bones and 151
  animations, plus the 44 animations kept in .anim files beside her
  model, attached at start. Aliases are followed to the animation that
  holds the data.
- **Posing:** a bone's pose at any moment comes from blending the two
  recorded moments around it (straight lines for moves and stretches,
  the shorter way round for turns), then parent times local, the
  original's way.
- **Bending her body (skinning):** first built on the processor (4,113
  points a frame); since 173u (step 3a) the graphics card bends her:
  each point's four bones and weights go to the card once, and each
  frame only the bone poses go, as a one-row float picture.
- **`moves.h` / `moves.c` choose the animation** from what she did this
  frame:
  - Standing: stand, with fidgets picked by the model's own frequencies.
  - On the ground: run, walk backwards, or the turning shuffle on the
    spot. With walk toggled, the walk instead of the run (forward and
    strafing); backwards stays the walk-back.
  - In the air: the jump's start once, then the jump loops. Dropping off
    an edge plays the fall.
  - Landing standing still plays the landing; landing on the move carries
    straight on.
  - Moving animations play at the speed the keys ask for over the speed
    they were made for (the run: 8.4 against 6.94, so 1.21 times; the
    walk: 3.0 against 2.5, 1.2 times), so her feet don't slide. The keys'
    speed (`mover_intended_speed`), not the distance she went: running
    into a wall she runs on the spot, as the original does (owner,
    2026-10-07; at first the distance was used, and against a wall she
    froze mid-stride).
  - Changes blend over the new animation's blend time (150 ms when it
    gives none).
  - Strafing plays the run (or the walk) with her body turned toward the
    strafe: 45 degrees on a diagonal, 90 straight sideways, eased at 10
    radians a second. The owner confirmed the original turns her
    (2026-10-06).
- **Walking (2026-10-07):** the keypad's `/` toggles walking and running,
  the stock game's key (TOGGLERUN). Walking, she moves at the game's walk
  speed, 2.5 yards a second, every way (forward, back and strafing), times
  her 120% (`MOVER_WALK` in `mover.h`; the mover's input carries
  `walking`). Swimming is unchanged by it. The server will be told with
  the walking flag once the client talks to it (173e).
- **`main.c`** bends her each frame (on the card), and reads the walk
  toggle.
- **Picture options:** `--pose ID MS` holds her in an animation;
  `--walking` starts with walk toggled. Standing, mid-run and mid-walk
  pictures look right.
- **Tests** (`build-custom-client --test`):
  - Her skeleton and its .anim files all read, and every animation the
    mover uses is there (the walk among them).
  - Standing, her lowest point is on the ground and she is 2.27 yards
    tall.
  - Half a stride apart, the run moves her by 0.64 yards, and its end is
    its start.
  - The choices above each pick the right animation, and the run and the
    walk play at the right rate.
  - Walking moves her 3 yards a second forward, back and sideways.

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
   by its weights (first on the processor; on the card since 173u).
3. Choose the animation from the mover's state; blend 150-ish ms. The
   walk toggle is part of the mover's input, so the speed and the
   animation follow the same switch.
4. A test: each named animation exists for her model; a bone's pose at a
   known time matches the file.

## Open Questions

None. (Answered 2026-10-06, owner: strafing straight sideways, "she
turns": the body turns 90 degrees and runs, as built.)
