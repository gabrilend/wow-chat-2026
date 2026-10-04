# 617j1 - Loot Turns: Who Opens Which Corpse

## Status
- Created: 2026-10-03
- Phase: 6
- Parent: 617j
- Blocked by: 617c2 (the proximity party: who is grouped with whom)
- Related: 617j (need and greed by the clan's judgement), 617h1 (full bags
  send a buddy to a vendor)
- Priority: Medium

## Origin

The owner, 2026-10-03: "can we make an issue file for a new loot system
for the buddy-bots? They should set the loot rules to 'free for all' or
maybe 'group loot but buddy bots pass on everything' if that's possible.
Then, they should loot corpses to try and maintain a proper ratio so that
everyone has looted roughly the same amount of times."

## Current Behavior

Not built. The group's loot rule is whatever the group was made with (the
bot module's default when a buddy invites, the game's when the owner
does). Buddies loot corpses by the bot module's own loot behaviour, which
opens whatever corpse it may, nearest first, so a buddy standing by
the kills takes most of them. Rolls on items of a set quality and above
are judged per 617j (need, greed or pass by the clan's needs).

## Intended Behavior

- **The loot rule**: whoever leads a group with buddies in it sets one of:
  - **free for all**: anyone may open any corpse it is allowed to, and
    takes all of it; or
  - **group loot, buddies always pass**: the game's turn-taking for
    ordinary items (round robin) and rolls for better ones, with every
    buddy passing on every roll (617j's judgement then never runs).
  Which of the two is the open question below; both are possible in the
  game's own rules (a buddy can be made to pass on every roll).
- **Taking turns at corpses**: each member's count of corpses opened in
  this group is kept. A corpse the group may open is left to the member
  with the lowest count (the owner included: a buddy waits a moment for
  its owner's turn, and doesn't open a corpse that is the owner's turn);
  the others don't open it. Ties: the nearest member. The aim is "everyone
  has looted roughly the same amount of times", not the same value.
- The counts start again when the group changes (a buddy joining or
  leaving by distance, 617c2).

## Suggested Implementation Steps

1. The group's loot rule set when a buddy forms or joins a group (the
   game's own "set loot method" call), the leader's choice kept.
2. The corpse counts per group member, counted when a member's loot window
   on a corpse opens (the server's loot hook).
3. The buddies' loot behaviour asked "is it my turn for this corpse?"
   before it walks to one (the bot module's loot action, by a source patch
   like B046, or the buddy roam's own detour logic).
4. Trace lines: whose turn a corpse is, and each count.

## Open Questions

- Free for all, or group loot with buddies passing on everything? Under
  free for all the turns decide who gets every item on a corpse; under
  group loot, items of the roll threshold and above are rolled for and
  buddies always pass, so the owner gets every good item, and the turns
  only share the ordinary loot.
- Does "everyone" include the owner in the count, or only the buddies
  among themselves (the owner looting whatever they like)?
- How long does a buddy wait for its owner to take their turn before the
  corpse goes to the next lowest count?

## Related Issues

- **617j** parent; blocked by **617c2**; related **617h1**
