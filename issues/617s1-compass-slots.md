# 617s1 - Compass Slots

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617s (the compass formation)
- Blocked by: None
- Priority: High

## Origin

See 617s (the owner's words, 2026-10-04, quoted in full there).

## Current Behavior

Not built. The game masters' commands place buddies on a ring once (`lib/buddy-arc.lua`); nothing keeps a place.

## Intended Behavior

Each buddy has its own compass direction, from its roster slot: seven
slots, seven directions evenly round the circle (slot 1 north, then on
round). The ring has one slot per buddy present, evenly spaced, rotated so
that one slot points along the owner's facing (the front slot, 617s3).
Each present buddy is matched to a slot so that the total of the angles
between each buddy's direction and its slot is least (a small assignment:
at most seven, tried exhaustively or by the Hungarian method), so with
fewer present each keeps the "same general compass direction", projected
onto fewer slots.

Inputs: owner position and facing (numbers), radius (yards), the present
buddies' directions (radians). Output: buddy -> slot position (x, y) and
facing (toward the owner).

## Suggested Implementation Steps

1. The geometry as a pure Lua library (`lib/buddy-compass.lua`).
2. An offline test: every count 1-7; the matching is least; turning the
   owner moves the slots; a buddy keeps its slot when others leave unless
   a nearer one opens.
3. An animation of an owner walking and turning with seven buddies.

## Open Questions

None beyond the parent's.
