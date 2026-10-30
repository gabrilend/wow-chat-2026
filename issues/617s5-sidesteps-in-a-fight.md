# 617s5 - Sidesteps in a Fight

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617s (the compass formation)
- Blocked by: 617o
- Priority: High

## Origin

See 617s (the owner's words, 2026-10-04, quoted in full there).

## Current Behavior

**Built 2026-10-30, both step sizes (the arithmetic committed; the server
side built by the owner's compile of 2026-10-30 and committed):** `buddies_sidestep.h`
works out the step round the target at the buddy's present distance, by
share (melee 20-35% of the circle, ranged 10-20%) or by distance (2-3
yards at 40 yards out, shrinking toward the target), a random direction;
`scripts/test-buddy-sidestep` (a quick test) checks the distance kept,
both shares, both distances and both directions. `buddies_sidestep.cpp`:
when a buddy in a fight casts a spell with no cast time, at most once
every 1.5 seconds, it is moved to the step's spot on the mesh (tried the
other way round if the mesh refuses). Switch `Buddies.Sidestep`: 0 off
(the default), 1 by share, 2 by distance, for the owner to choose. Not
known until seen in game: whether the bot module's own fight movement
cuts the step short.

## Intended Behavior

During a fight a buddy moves round its target between spellcasts: when
it is about to cast an instant spell, which it can cast on the move
(owner, 2026-10-04: "inbetween a spellcast, when they're casting an
instant spell"). The step: along the
circle centred on the target whose radius is the buddy's current
distance, by a share of that circle's length (a random amount in the range, a
random direction): melee 20-35%, ranged 10-20% (owner, 2026-10-04: "melee
should do a larger proportion of the circle each time"). The owner's
alternative, to compare: the step scaled by distance, from 2-3 yards at
40 yards out down to, near the target (0-3 yards), between the
character's melee reach and the target's centre, perhaps scaled for model
size, on the navigation mesh; a step the mesh
refuses is tried the other way, then skipped. Its distance to the target
is unchanged, so a caster stays in range and a melee buddy stays in
reach. Getting out of the bot module's known dangers (AoE) stays the bot
module's.

## Suggested Implementation Steps

1. A combat action with a timer, low priority, in `mod-buddies`.
2. Offline test of the arc step (length, distance kept).

## Open Questions

None beyond the parent's.
