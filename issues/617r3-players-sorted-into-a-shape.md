# 617r3 - Players Sorted into a Talent Shape

## Status
- Created: 2026-10-05
- Phase: 6
- Parent: 617r (gearset profiles)
- Blocked by: 617r1
- Priority: Low (the owner: "probably something we should work on separately")

## Origin

Verbatim, 2026-10-05:

> A player can be "sorted" into whichever profile best suits them, but
> that's probably something we should work on separately. We can store it
> in their character record and update it everytime they login and
> everytime they spend a talent point. Before level 10, or if they have
> no talent points, they are most similar to the 1/3rd profile.

## Current Behavior

Not built. Buddies have a planned shape (`buddy_roster.profile`);
players have none.

## Intended Behavior

Every character has a current shape (integer 1-10) in the characters
database (character guid, shape), recomputed at login and whenever it
spends a talent point: the shape whose thirds lie nearest its points per
tree (distance between the fractions), ties to the lower shape id.
Before level 10, or with no points spent, shape 7 (one-third each). The
gearset command and anything else needing a shape read it from there;
buddies keep their planned shape until their points are spent, then are
sorted the same way.

## Suggested Implementation Steps

1. The table (an E step) and the nearest-shape rule in `lib/gearsets.lua`.
2. Lua: login and talent-point events (ALE's `PLAYER_EVENT_ON_TALENTS_CHANGE`
   and login) recompute and store.
3. Tests: the rule on made-up point spreads.

## Open Questions

None.
