# 617s3 - Tank at the Front

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617s (the compass formation)
- Blocked by: 617s1
- Priority: High

## Origin

See 617s (the owner's words, 2026-10-04, quoted in full there).

## Current Behavior

**Built in the close follow's ring, 2026-10-30 (617s2; the core
committed, the server side waits for the compile):** in the ring, a
follower the bot module counts as a tank takes the front place, on the
leader's facing; the rest share the other places by nearness
(`BuddyFollow::AssignRing`, checked in `tests/buddy-follow-core`). Not in
the arc follow (travelling), where the arc trails behind.

Not built.

## Intended Behavior

The buddy whose role is tank (or, without one, nobody) always takes the
front slot, on the owner's facing. Whoever the matching (617s1) would put
there moves to the free slot nearest its own direction. As the owner
turns, the front slot turns with them, so the tank swaps places with a
neighbour on the compass. The point (owner, 2026-10-04): the tank walks
ahead into the 110% aggro reach first (617c3).

## Suggested Implementation Steps

1. Fix the tank to the front slot before the matching; match the rest.
2. Offline test: turning the owner 360 degrees keeps the tank in front and
   moves each other buddy at most one slot per turn step.

## Open Questions

Two tanks: does only one take the front?
