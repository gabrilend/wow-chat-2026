# 617s7 - Box Select in the Custom Client

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617s (the compass formation)
- Blocked by: 617s6 (sending buddies), the project's own client (not yet
  an issue; 916o also waits on it)
- Priority: Low

## Origin

Verbatim, 2026-10-04: "Then, ideally, an issue file in the custom client
to allow us to select them by clicking and dragging a box."

## Current Behavior

Not built. The stock 3.3.5a client selects one unit by clicking it; it
has no box selection, and its addons can't add one over the 3D world.

## Intended Behavior

In the project's own client: click and drag a box over the world; every
buddy of the player's inside it is selected (highlighted), and the next
"send" (617s6) applies to them all, as `@1,3` does by typing.

## Suggested Implementation Steps

1. When the custom client exists: screen-space box to world units (each
   unit's position projected to the screen, inside the box or not).
2. The selection sent to the server as the same addressing 617s6 reads.

## Open Questions

None until the custom client is under way.
