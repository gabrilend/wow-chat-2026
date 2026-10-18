# 1202d - Clicks for Small Hands: How the Show Plays

## Status
- Created: 2026-10-17
- Phase: 12
- Parent: 1202 (the robot stage show)
- Blocked by: 1202a, 1202b, 1202c
- Priority: Medium

## Current Behavior

Nothing exists.

## Intended Behavior

The show is played by clicking or tapping, nothing else.

- **An act**: the curtain opens on a scene; the robots enter and wander.
  A robot now and then says something about the scene (1202c), unasked.
- **A click on a thing**: the robots turn and gather round it (1202b),
  and one or two of them say a line about it, each in their own manner.
  The thing does a small animation (the shell hums and glows).
- **A click on a robot**: it waves and says something to the audience.
- **Between acts**: after a few minutes, or when every thing in the
  scene has been clicked, the curtain closes and opens on the next scene.
- **Pace for small children**: one line at a time, a pause after each,
  never two robots talking at once; a click while a robot is talking
  waits its turn rather than cutting it off.
- **Nothing to read, nothing to type, nothing kept**: captions are
  there for grown-ups and early readers but the show works without
  them; there is no text box anywhere; the show stores nothing about
  who played.

## Suggested Implementation Steps

1. The act loop: curtain, entrances, wandering, unasked lines.
2. Clicks on things and on robots, with the turn-taking for speech.
3. Scene changes.
4. Scripted-click runs (`--click SECONDS X Y`) and the receipt
   (`output/goodbye`), with screenshots into `development-history/`.
5. A grown-up's settings corner (sound, captions, speed), opened by a
   long press so a small child does not find it by accident.
