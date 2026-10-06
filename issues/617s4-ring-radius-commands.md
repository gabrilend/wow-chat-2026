# 617s4 - Ring Radius Commands

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617s (the compass formation)
- Blocked by: 617s2
- Priority: High

## Origin

See 617s (the owner's words, 2026-10-04, quoted in full there).

## Current Behavior

Not built.

## Intended Behavior

Two commands for a player's own buddies, `.buddy wider` (a step out,
5 yards, up to 25) and `.buddy closer` (back in to the smallest, 5);
default radius 5 yards (owner, 2026-10-04: "5, 5, 25" ... "yes. And 5 is
the minimum.").

**Macros** ("ideally with pre-made macros if we can figure out how"): a
macro lives in the player's own client files, so the server can't hand
one out. Two ways: the optional addon family (155y's) creating the two
macros with the client's macro functions the first time it loads; or the
commands printed as a line a player can drag into a macro by hand. The
radius is per owner (a number, yards), kept while they play. Where the
mesh can't hold the wider ring, slots come in on their own (617s2).

## Suggested Implementation Steps

1. Two commands in `mod-buddies` (player level), the radius kept per owner.
2. Test: wider stops at 25; closer goes to 5 at once.

## Open Questions

None beyond the parent's.
