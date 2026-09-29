# 617c3 - The Dungeon Draw

## Status
- Created: 2026-09-27
- Phase: 6
- Parent: 617c
- Blocked by: 617c2
- Priority: Medium

## Current Behavior

Nothing built.

## Intended Behavior

617c's dungeon party, unchanged: on entering a dungeon, four buddies drawn
at random without replacement from a bag that refills when everyone has had
a turn (the `buddy_draw` table, 617a's data model), brought into the
instance; only empty slots filled when the owner is already in a party; no
auto-fill when two or more players are grouped; a buddy in a battleground
drawn last (617i).

## Suggested Implementation Steps

1. The `buddy_draw` table (characters database, an install step).
2. A dungeon-entry hook: draw, re-form the group, bring the drawn in.
3. In game: three runs give every buddy a turn before anyone repeats.

## Related Issues

- **617c** parent; **617c2**; **617i** battlegrounds
