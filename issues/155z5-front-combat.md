# 155z5 - Front Combat

## Status
- Created: 2026-10-04
- Phase: 1
- Parent: 155z (the Dark Portal front)
- Blocked by: 155z3, 155z4
- Priority: Medium

## Origin

See 155z (the owner's words, 2026-10-04, quoted in full there).

## Current Behavior

Not built.

## Intended Behavior

- Everyone fights only what is directly ahead on their lane; when that
  foe falls, the one just to its side becomes "ahead" (the lane bends to
  it), so the line grinds sideways as well as forward.
- Allied spellcasters cast from afar, standing still, wherever the flow
  of runners can pass them; where it can't, they cast from the front.
  They clump, ideally, so melee runners pass across their face toward the
  enemy.
- No retreat: every fighter fights to the last.
- Later talks: "successively more successful tactical planning degrees".

## Suggested Implementation Steps

1. "Directly ahead": the nearest foe within a narrow cone along the lane.
2. Caster placement: standing spots off the lane where the lane's
   throughput stays above the arrival rate.
3. The clump: casters choose standing spots near other casters.

## Open Questions

1. How narrow is "directly ahead" (a cone angle)?
