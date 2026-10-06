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

Not built. In a fight a buddy stands where its class's fighting puts it.

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
