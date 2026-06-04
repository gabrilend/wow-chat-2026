# 806 - Proximity Raid System

## Status
- Created: 2026-06-02
- Phase: 8 (XP / reward / group-mechanics balance)
- Priority: Medium (the cross-level proximity design assumes shared
  raid membership is the default state of any nearby cluster of
  players; without this, manual /invite ceremony becomes a constant
  friction)
- Related: 801 (proportional damage rewards — this system is the
  social-membership half of what makes proportional rewards land
  cleanly), 142 (symmetric aggro radius — nearby low-levels sharing
  fate with a high-level works best when they're sharing a raid)

## Problem

The proportional reward system in 801 distributes XP, currency, and
loot based on damage and healing contribution within 60 yards of a
kill. That works without any group membership. But other rewards,
buffs, and social mechanics (heal-target eligibility, party-frame
visibility, follow-leader-on-map, voice-chat channel association,
loot bind decisions) still depend on actual raid membership in
the WoW client's sense.

Asking players to manually `/invite` everyone they happen to be
fighting near is friction that scales with player count and breaks
the spontaneous-coordination feel the larger reward design is
trying to encourage. Two strangers fighting the same elite shouldn't
have to type at each other to share heals.

This issue replaces explicit raid formation with **automatic
proximity-based raid assignment**: nearby players are continuously
re-grouped into the same raid by their physical positions in the
world.

## Intended Behavior

- Every online player belongs to exactly one raid (possibly a
  "solo raid" of size 1).
- Raid membership is recomputed periodically by the server based on
  player positions.
- Players within **40 yards** of a raid's center are members of that
  raid.
- A player whose distance from their current raid's center exceeds
  40 yards becomes a candidate for reassignment. If they are now
  within 40 yards of another raid's center, they swap. If they are
  not within 40 yards of any raid, they become their own (solo)
  raid.
- Raid centers are computed as the centroid of the current
  members' world positions.
- The recompute cadence is **once every few seconds** (suggested:
  5s) — fast enough to feel responsive but slow enough to avoid
  flicker-merging when a player walks the boundary.

## Implementation Approach

**Server-side patch, not a client addon.** The WoW 3.3.5a client
already understands raid membership — it draws party/raid frames,
routes heals, handles the loot UI — so the only modification needed
is on the server: continuously reassign players to raids based on
position.

This matters because it means the system can ship to **vanilla**
(which has no client-patching capability) without waiting on the
client-patching pipeline.

Mechanism sketch:

1. A periodic timer (suggested 5s) fires on the worldserver.
2. The timer iterates every online player; for each, compute their
   distance to their current raid's centroid.
3. Build a candidate-reassignment list of players whose distance
   exceeds 40 yards.
4. For each candidate, search nearby raids (within 40 yards of
   their position); reassign them to the nearest qualifying raid,
   or split them into a new solo raid if none qualifies.
5. Apply changes via the standard raid invite/leave packets so the
   client experiences them as normal raid events.

## Edge Cases

- **Player wants to be alone.** Need an opt-out: a per-character
  "Solitary" flag. When set, the player is excluded from automatic
  reassignment and stays in a solo raid regardless of proximity.
  Opt-out is voluntary and reversible.
- **Two raids drift together.** Their centroids end up within 40
  yards of each other. Option A: merge them into one raid. Option B:
  leave them separate but let individual members cross the boundary
  naturally as they move. **Recommend A** — keeping them separate
  defeats the proximity-as-membership principle.
- **Raid grows past 40 members.** Standard WoW raid cap is 40. If a
  proximity cluster has more than 40 candidate members, the excess
  go into a sibling raid centered on the nearest cluster of
  themselves. The two raids may stay adjacent.
- **Player teleports/loads zones.** Briefly off-grid; skip them
  this tick. Pick them back up on the next tick.
- **In a dungeon instance.** Proximity reassignment is suspended
  inside instances — instance membership is a different system and
  the raid that walked in stays as the raid that walks through.
- **Mid-combat reassignment.** Suspend reassignment for any player
  currently in combat. Wait until they leave combat before moving
  them. Otherwise the reassignment can interrupt heal targeting or
  loot eligibility in awkward ways.

## Composition With Other Systems

- **801 (proportional rewards)** — these fire on contribution within
  60 yards regardless of raid membership, so they keep working with
  or without proximity raid. With proximity raid, the players who
  share the rewards also share a heal-target list, a loot UI, and
  voice channel.
- **142 (symmetric aggro radius)** — assumes "nearby" players are
  sharing fate with the high-level. Proximity raid makes that
  "sharing" mechanical, not just emergent: the low-level bystander
  isn't just in danger near the high-level, they're in the same raid
  as them, with heals routed.

## Implementation Steps

1. Add a periodic 5-second tick on the worldserver that runs the
   reassignment pass.
2. Implement the centroid computation per raid.
3. Implement the candidate-reassignment search (find nearest raid
   whose center is within 40 yards of the candidate).
4. Wire reassignment through the existing raid-invite / raid-leave
   packets so the client sees normal raid events.
5. Add the Solitary opt-out flag and a `/solitary` (or similar)
   chat command.
6. Test: two characters walking together stay in the same raid;
   one walks 100 yards away and becomes solo; walks back and rejoins.
   Three-way scenarios. Combat suppression. Instance suppression.
7. Document the system in `docs/raids/proximity-raid.md` (or the
   equivalent multiplayer-mechanics page).

## Open Questions

- Should the 40-yard threshold be config-driven? Almost certainly
  yes — different profiles may want different feel.
- Should the recompute cadence be config-driven? Probably yes for
  the same reason.
- What happens when a player explicitly `/invites` someone who is
  far away? Override the proximity system, accept the explicit
  raid? Reject the invite? Recommend: accept and let the proximity
  system honor the explicit composition until distance breaks it
  organically. Explicit beats automatic.
- Does this break with mod-playerbots? Bots may need to be excluded
  from proximity reassignment (their raid membership is managed by
  their owner). Confirm during testing.
- Should the system have a "raid leader" concept? Vanilla WoW
  raids do. Auto-assigning leadership is fraught (whose name shows
  up?). One option: leadership rotates to whoever has been in the
  raid longest, or to the highest-level member, or stays unassigned.
  Decide during step 4.
