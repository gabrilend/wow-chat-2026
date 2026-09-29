# 617b1 - A Buddy's Entrance: From Behind Sargobras, a Wave or a Salute

## Status
- Created: 2026-09-29
- Phase: 6 (buddies)
- Parent: 617b (Sargobras, the buddy selector)
- Related: 617c1 (buddy login and placement), 617c4 (loyalty; the
  greeting is an early personality trait)

## Origin

Verbatim, the owner, 2026-09-29:

> when buddy-bots are spawned, they should spawn about 5 yards behind and to
> the left/right of Sargobras. They should step forward about 3 steps, then
> stop and either wave or salute randomly. We should remember which one they
> did because it'll inform their personality later. After the animation
> finishes, they'll hang out with the player for a bit.

## Current Behavior

**Built 2026-09-29, not yet compiled or tried in game** (`buddies_login.cpp`,
the entrance; roster column `greeting`). As built, following the owner's
answers of 2026-09-29: the buddy appears behind Sargobras facing the
owner, steps forward along his facing, and waves or salutes *to the
owner*; then it hangs out, standing until the owner is 5 yards from where
they stood when it appeared, turning to face them every quarter second
after that, and running off to roam once the owner is 10 yards from that
spot. With no Sargobras near it is placed the ordinary way, silently
(owner: "This should never happen in the future"). Roaming now runs in
the open and walks only indoors (`buddies_roam_strategy.cpp`; owner: "we
don't have to rp walk, that's only for inside towns and dungeons and
interior areas").

Before:

A buddy's every login, its first included, places it 20–30 yards from its
owner in a random direction with ground under it, facing the owner
(`modules/mod-buddies/src/buddies_login.cpp`, the placing step), and the
bot module's AI takes over at once. Nothing marks a buddy's first
appearance, and nothing is remembered about it.

## Intended Behavior

- **Once per buddy, at its first appearance:** when a buddy is placed and
  has no greeting on record, and a Sargobras (the valley one or the
  wandering one) stands within 50 yards of its owner, the buddy appears
  5 yards behind him, a quarter-turn to his left or right (chosen at
  random), facing the way he faces.
- It walks about 3 steps (2.5 yards) forward, stops, and plays one
  gesture, wave or salute, chosen at random with even odds.
- The gesture is written to the buddy's roster row (`greeting`: 0 none
  yet, 1 wave, 2 salute), which also marks the entrance as done.
- For the length of the entrance (about 4 seconds) the bot module's AI
  makes no decisions, so it cannot walk the buddy off mid-entrance. Then
  the ordinary behaviour resumes: grouping with the owner by distance
  (617c2) and roaming near them (617e1), which is "hang out with the
  player for a bit".
- No Sargobras near the owner (the owner walked away before the buddy
  was made, or logged out): the buddy is placed the ordinary way, with a
  warning in the server log, and its greeting stays unrecorded until an
  entrance happens.

## Suggested Implementation Steps

1. **Roster column** (`sql/basic/db_characters.src/04-buddy-roster.apply.sql`):
   `greeting tinyint unsigned NOT NULL DEFAULT 0`, added with an
   idempotent `ALTER` for databases that already hold the table.
2. **The entrance** (`buddies_login.cpp`, the placing step): read the
   greeting with the owner; if 0, look for the nearest creature of entry
   6170001 or 6170002 within 50 yards of the owner; if found, teleport
   the buddy behind him, pause its AI (`SetNextCheckDelay`), walk it
   forward (`MovePoint`), and schedule the gesture for when the walk ends
   (`HandleEmoteCommand` with the wave or salute emote), writing the
   greeting as the gesture plays.
3. **Test** in game: pick a buddy at a valley Sargobras; the new buddy
   appears behind him, steps out, gestures once; the roster row holds 1
   or 2; logging out and back in places it the ordinary way.

## Related Documents

- `modules/mod-buddies/src/buddies_login.cpp`
- `src/lua-basic/sargobras.lua` (where the pick is made)

## Open Questions

- (Answered 2026-09-29: "don't worry about it. This should never happen in
  the future") With no Sargobras near, should the entrance happen anyway (behind the
  owner, say), rather than waiting for one that may never come?
- (Answered 2026-09-29: until the owner is 10 yards from where they stood;
  see Current Behavior) How long is "a bit"? Today the buddy simply goes back to its ordinary
  roaming and distance grouping after the gesture; a set time spent
  following the owner first would be a separate state to build.
