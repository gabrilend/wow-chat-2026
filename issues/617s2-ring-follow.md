# 617s2 - Ring Follow

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617s (the compass formation)
- Blocked by: 617s1
- Priority: High

## Origin

See 617s (the owner's words, 2026-10-04, quoted in full there).

## Current Behavior

Not built. Following is the bot module's own.

## Intended Behavior

Out of combat, in follow mode (the bot module's "follow" strategy on),
each buddy steers toward its slot instead of the bot module's follow
point. A buddy's waypoint moves only when the buddy reaches it (owner,
2026-10-04: "we should make it so that the waypoints only move when the
buddy-bot reaches one"): on arrival it reads its slot afresh round where
the owner is now and sets off for that; between arrivals the waypoint
stands still, so a buddy never chases a point that slides under it. A slot is taken onto the
navigation mesh: if it is not walkable, or not reachable from the owner
(a wall, a ledge, a doodad), it is moved in along the line to the owner
until it is. Buddies run when far, walk when near, never slower than the
owner. In combat this whole behaviour is off.

## Suggested Implementation Steps

1. A buddy action in `mod-buddies` that replaces the follow movement when
   the strategy is on and the buddy is out of combat.
2. The mesh check per slot (the module's navigation mesh calls, 617o).
3. In game: an owner walking a corridor and turning in a room.

## Open Questions

None beyond the parent's.
