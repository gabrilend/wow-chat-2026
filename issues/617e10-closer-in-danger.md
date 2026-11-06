# 617e10 - Closer in Danger: Buddies Keep Near Their Owner Where It's Tough

## Status
- Created: 2026-10-03
- Phase: 6
- Parent: 617e
- Blocked by: 617e2 (roaming), 617o4 (the monster approach)
- Related: 617c2 (the proximity party), 617e5 (fighting together)
- Priority: Medium
- State: in progress (the reading and the leash built offline 2026-11-06;
  not yet fed or asked by the server)

## Origin

The owner, 2026-10-03: "when buddy-bots are in dangerous areas, like the
monsters are tougher than they expect, they should stick closer to the
player."

## Current Behavior

**The reading and the leash, built 2026-11-06 (offline, on a branch for
review):** `roam/buddy_danger_core.h` (with its `.info.md`), plain
arithmetic, checked by `scripts/test-buddy-danger` (34 checks, a quick
test; 23 of 23 deliberately broken versions caught). Steps 1 to 4's
arithmetic:
- **One reading per clan** (the owner and its buddies), fed by all of them,
  0 (calm) to 1 (the worst): the heaviest pack a buddy sees as it picks a
  waypoint, weighed as the tank's pace weighs a pack (normals, three per
  elite, 10% more per level above the clan; `roam/buddy_pace_core.h`), per
  clan member, no danger at one and the worst at three; each fight's end,
  by the share of the clan's health it cost (no danger under 15%, the
  worst at 60%) or a death (the worst); close calls as they happen: an
  ally under 20% health or the healer under 10% mana (0.75), an ally dead
  (the worst).
- **Rises fast, falls slowly**: a higher reading is taken 70% of the way at
  once; quiet halves it every three minutes; each fight that went well
  (under 20% of the clan's health, no close call, no death) takes a quarter
  off.
- **The steps**: four above calm, the reading cut into fifths (0.2, 0.4,
  0.6, 0.8); a step is taken as soon as its edge is reached and let go only
  0.05 below it, so the leash doesn't flicker on an edge.
- **The leash** (step 2): the radius round the owner a waypoint must fall
  within, the whole area at calm, the close-follow ring (617s, 5 yards) at
  the worst, the same share off each step (a 200-yard area: 200, 80, 32,
  13, 5).
- **The approach's limit** (step 3): monsters up to three levels above the
  buddy when calm, one fewer each step (only monsters beneath it at the
  worst); elites passed over from step 2.
- **The trace line** (step 4): `danger 0.70 step 3/4 leash 13 yd, monsters
  up to +0 levels, no elites`.
Not yet, the server's part: feeding the reading (the sight at each
waypoint pick, each fight's end, the close calls from each update),
refusing waypoints outside the leash in the roaming (the pinwheel asked
again, nearer), and the approach passing over monsters it may not seek.

Before: A roaming buddy ranges over its owner's whole area whatever the
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

Gathered 2026-10-28 into 617's own list (question 3), merged with the
same questions from other sub-issues; answers are written back here.

- **Answered 2026-10-28** (617's question 3): the roaming radius shrinks
  step by step as danger rises, down to the close-follow ring (617s) at
  its worst, and widens again as fights go well.

- **Answered 2026-10-28** (617's question 3): what makes a place
  dangerous: elites and packs; monsters above the buddies' level; how fights
  went; close calls, "when allies drop to low health and or die"; and "if
  the healer nearly runs out of mana". The allies' close calls make it the
  group's danger, not one buddy's. How close "closer" is stays open.

- What counts as "tougher than they expect": the monsters' levels
  against the buddy's, elites, packs, how fights actually went, or a mix?
  (Answered 2026-10-28, above: a mix.)
- How close is "closer": a fixed leash (say 30 yards) whenever it's
  dangerous, or a radius that shrinks gradually with the danger?
  (Answered 2026-10-28, above: step by step, to the close-follow ring.)
  **Decided 2026-11-06 (the agent's call, for the owner to curate), the
  part left open, "how close closer is"**: four steps, each taking the same
  share off the radius, from the whole area down to the 5-yard ring (200
  yards: 200, 80, 32, 13, 5). By share rather than by yards, so a small
  cave and a wide field both narrow by steps that feel alike.
- Is the danger the buddy's own, or shared by the clan (one buddy's bad
  fight pulling all of them in)?
  **Decided 2026-11-06**, from the owner's 2026-10-28 answer ("the group's
  danger, not one buddy's"): one reading per clan, fed by every member.

## Decisions (2026-11-06)

The agent's calls while building the reading, for the owner to curate;
each is one field of `BuddyDanger::Settings`:
- **What a pack weighs**: the tank's own weighing (617z), per clan member:
  one normal at level per member is no danger, three is the worst.
- **What a fight's cost reads**: under 15% of the clan's health nothing,
  60% the worst; a death the worst; a fight under 20%, with no close call,
  went well and takes a quarter off.
- **Close calls**: an ally under 20% health or the healer under 10% mana
  reads 0.75; a death reads the worst.
- **How fast**: 70% of the way up at once; halved by three minutes of
  quiet.
- **The approach**: three levels above when calm, one fewer per step;
  elites passed over from the second step.

## Related Issues

- **617e** parent; blocked by **617e2**, **617o4**; related **617c2**,
  **617e5**
