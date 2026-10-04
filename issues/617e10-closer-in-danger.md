# 617e10 - Closer in Danger: Buddies Keep Near Their Owner Where It's Tough

## Status
- Created: 2026-10-03
- Phase: 6
- Parent: 617e
- Blocked by: 617e2 (roaming), 617o4 (the monster approach)
- Related: 617c2 (the proximity party), 617e5 (fighting together)
- Priority: Medium

## Origin

The owner, 2026-10-03: "when buddy-bots are in dangerous areas, like the
monsters are tougher than they expect, they should stick closer to the
player."

## Current Behavior

Not built. A roaming buddy ranges over its owner's whole area whatever the
monsters there are like; only grouping (617c2) depends on distance to the
owner, and the monster approach (617o4) picks any monster worth
experience, of any level.

## Intended Behavior

- **Danger, measured**: a buddy keeps a reading of how tough its
  surroundings are, from what it meets:
  - the monsters near it: their level above its own, elites, how many
    stand together;
  - its own recent fights: how much health it lost, how long they took,
    deaths.
  The reading rises fast and falls slowly (a bad fight is remembered for a
  while).
- **Closer with danger**: the higher the reading, the nearer its owner a
  buddy keeps: its roaming waypoints are picked within a radius round the
  owner that shrinks as danger grows, down to staying beside the owner;
  and the monster approach skips monsters above a level the reading
  allows.
- **Back out when it calms**: as the reading falls, the radius grows back
  to the whole area.

## Suggested Implementation Steps

1. The reading: kept per buddy, fed by the monsters near it (at each
   waypoint pick) and by each fight's end (health lost, time, death).
2. Roaming's leash: waypoints outside the owner radius the reading allows
   are refused (the pinwheel asked again, nearer).
3. The approach's limit: a monster above the allowed level difference is
   passed over.
4. Trace lines for the reading and the leash.

## Open Questions

- What counts as "tougher than they expect": the monsters' levels
  against the buddy's, elites, packs, how fights actually went, or a mix?
- How close is "closer": a fixed leash (say 30 yards) whenever it's
  dangerous, or a radius that shrinks gradually with the danger?
- Is the danger the buddy's own, or shared by the clan (one buddy's bad
  fight pulling all of them in)?

## Related Issues

- **617e** parent; blocked by **617e2**, **617o4**; related **617c2**,
  **617e5**
