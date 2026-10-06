# 155z3 - Portal Reinforcements

## Status
- Created: 2026-10-04
- Phase: 1
- Parent: 155z (the Dark Portal front)
- Blocked by: 155z2
- Priority: Medium

## Origin

See 155z (the owner's words, 2026-10-04, quoted in full there).

## Current Behavior

Not built.

## Intended Behavior

Allied fighters come out of the Dark Portal without end. Each second, as
many appear as fit side by side across the portal's width (its width
divided by a fighter's width). Each starts on a random heading out of the
portal ("a random running trajectory") and turns toward the nearest foe
ahead "like a compass": its heading eases toward the bearing of that foe
until it joins the lane that leads there (155z2), then runs the lane.

The mix: humans and orcs and other playable races alike, now and then
murlocs and furbolgs; never quilboar or qiraji ("they have other things to
focus on"). Bodies by the mirror-image route (617f) for the races, so they
look like players; stock creatures for murlocs and furbolgs.

## Suggested Implementation Steps

1. Spawn-rate maths from the portal's measured width.
2. The mix as data (race, weight).
3. The compass turn (heading eased toward the foe's bearing at a fixed
   turn rate) onto the nearest lane.

## Open Questions

1. Do murlocs and furbolgs fight on the allied side?
