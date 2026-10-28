# 617e14e - The Picture Judge

## Status
- Created: 2026-10-27
- Phase: 6
- Parent: 617e14
- Blocked by: 617e14c
- Priority: Medium
- State: plan only

## Current Behavior

Movement is judged by numbers (`scripts/measure-buddy-spread`) and by eye.

## Intended Behavior

The owner, 2026-10-27: "then we feed it to an image recognition program,
and we describe our task goal, then say "does this look like rippling
waves of silk? Is this the flow of a school of tranquil fish? etc. We're
looking for something that feels whirling, but semi chaotic, like a
maelstrom of swirls but in all directions at once."

- **A tool** that takes the renderer's frames (617e14c), a statement of
  the goal (the owner's words above, kept in a file), and a list of
  questions, asks an image model each question of each frame (or of a
  strip of frames, for motion), and writes its answers beside the frames.
- **Its answers kept** with the record they judged, so a change to the
  movement can be judged by them before and after, as by the numbers.

## Suggested Implementation Steps

1. The goal and the questions as a file.
2. The tool, given a model (open question 1).
3. A strip of frames as one picture (motion shows only across frames).

## Open Questions

1. **Which image model**: one run on this computer (which, and is there
   one installed?), or a hosted one (Claude, by the project's API key, if
   it has one)? A hosted model sends the pictures off this computer.
2. **One frame or a strip**: still pictures can't show "flow"; a strip of
   frames side by side, or the animation itself where the model takes one?
