# 617c - Buddy Login and the Proximity Party

## Status
- Created: 2026-09-23
- Phase: 6
- Parent: 617
- Blocked by: 617a
- Priority: High

## Origin

Verbatim, 2026-09-23:

> we should dynamically adjust which ones are in a party as you based on which
> are closest. Remember, they're just adventuring in the same zone as you.
> Same areas too. If you enter a dungeon, then enough join to make a dungeon
> party. We can choose them randomly, without replacement, cycling through to
> make sure everyone gets a chance to go.

## Current Behavior

The bot module logs a character in as a bot with
`PlayerbotHolder::AddPlayerBot(guid, masterAccountId)`. Bots accept group
invitations through `AcceptInvitationAction`. Nothing re-forms a group by
distance, and nothing draws a dungeon party.

## Intended Behavior

- **Login/logout**: when the owner logs in, every buddy on the roster logs
  in as a bot near the owner's area (not on top of the owner). When the
  owner logs out, they log out.
- **Proximity party**: the owner's group holds the owner and the four
  closest buddies. At a fixed interval (a few seconds), if a buddy outside
  the group is now closer than one inside, they swap. Buddies outside the
  group keep adventuring (617e).
- **Dungeon party**: when the owner enters a dungeon, the group becomes the
  owner plus four buddies drawn at random **without replacement**. The draw
  bag persists across dungeon runs and refills only when every buddy has
  had a turn. The drawn buddies are brought into the instance; the rest
  wait outside.
- **Loyalty**: buddies decline every group invitation except their owner's.

## Suggested Implementation Steps

1. Login/logout hooks in mod-buddies (617a).
2. The proximity loop: sort buddies by distance to the owner, compare with
   the current group, swap the farthest member for the nearest outsider.
   Hysteresis (a margin in yards) so two buddies at nearly equal distance
   don't swap every tick.
3. Dungeon entry hook: draw from the bag, re-form the group, teleport the
   drawn buddies to the entrance.
4. Invitation refusal: an extra check in the module's accept-invitation
   path for buddies (a module patch, marker-bracketed like B025).
5. Test with a level-40 owner (five buddies): group composition changes as
   the owner walks between buddies; three dungeon runs give every buddy a
   turn before anyone repeats.

## Related Issues

- **617**, **617a**; **617e** for what ungrouped buddies do

## Open Questions

- **Swap interval and margin**: a starting value (for example every 5 s,
  10-yard margin) to be tuned in `docs/balance-updates.md`.
- **Raids**: at 40+ the owner could also form a raid with all buddies. Out
  of scope unless wanted.
