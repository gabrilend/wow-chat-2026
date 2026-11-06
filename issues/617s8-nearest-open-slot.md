# 617s8 - Nearest Open Slot (the other follow mode)

## Status
- Created: 2026-10-05
- Phase: 6
- Parent: 617s (the compass formation)
- Blocked by: 617s2 (ring follow), 168 (Chromie, who keeps the switch)
- Priority: Medium

## Origin

Verbatim, 2026-10-05:

> does this include the Chromie settings alteration NPC? To enable /
> disable the NPCs following the compass, and instead moving to the
> nearest unclaimed open waypoint each time they reach a waypoint, instead
> of their assigned, compass based slot.

Owner, 2026-10-05: one on/off switch, compass on or off; off is this
mode. The bot module's stock follow is not one of the choices.

## Current Behavior

Not built in the server. The compass formation (617s) is planned with one
way of choosing slots: each buddy's own compass direction.

**The claim table and the "nearest unclaimed from here" choice, built
2026-11-06 (offline, on a branch for review):**
`roam/buddy_open_slots_core.h` (step 1 without its drawing). Each update,
`Step` keeps, lets go and takes the claims on the close follow's ring
(617s2's `RingPlaces`): a claim on a slot the ring no longer has is let
go; the tank holds the front slot, displacing its holder even mid-walk; a
buddy still walking to its waypoint keeps its claim and its waypoint; a
buddy at its waypoint (within the ring's slack, 1.5 yards) or holding
nothing lets go and claims the nearest free slot, measured by the
caller's distance (the mesh's path length in the server, a straight line
by default), several pickers sharing by least walking in all; its new
waypoint is that slot's spot round where the owner is now, and stands
still until reached. Checked by `scripts/test-buddy-open-slots` (21
checks, a quick test): 400 updates of an owner walking, turning and
standing with seven buddies and a tank never put two buddies on one slot,
keep the tank in front, never change a walker's claim, and give a lone
picker the nearest free slot; once the owner stands, the ring is calm; a
wall in the distance sends a buddy to the farther slot. 19 of 19
deliberately broken versions of the header caught. Not yet: the drawing
of both modes side by side, Chromie's switch (168) and the ring follow
choosing by it (step 2), and the test in game (step 3).

## Intended Behavior

A player who switches the follow mode to "open slot" at Chromie (168)
has the same ring of slots round them as in compass mode (617s1: one slot
per buddy present, the front slot on the owner's facing), but no buddy
owns a direction. Each slot is claimed by at most one buddy (a claim is
the buddy's id, an integer, against the slot's index, an integer). When a
buddy reaches the slot it was walking to, it gives up that claim and
claims the unclaimed slot nearest to where it stands (measured on the
navigation mesh, as ring follow walks), then walks there. Slots move with
the owner as in compass mode; a claim follows its slot.

The tank still takes the front slot (617s3) in this mode. A buddy that
has not yet reached its slot keeps walking to it, so two buddies never
trade claims mid-walk.

## Suggested Implementation Steps

1. Offline, beside 617s1's geometry: the claim table and the "nearest
   unclaimed from here" choice; drawn as the same animation (owner walking
   and turning, seven buddies) in both modes side by side.
2. In the buddy module's ring follow (617s2), choose the slot by the
   player's mode, read from Chromie's settings table.
3. Test: in open-slot mode no two buddies hold one slot; a buddy that has
   arrived always takes the nearest free slot; in compass mode nothing
   changes.

## Open Questions

Gathered 2026-10-28 into 617's own list (question 2), merged with the
same questions from other sub-issues; answers are written back here.

1. When a buddy arrives and its own slot is still the nearest free one
   (the owner stood still), does it stay put (no new waypoint), so the
   ring is calm while the owner rests?
   **Decided 2026-11-06 (the agent's call, for the owner to curate):** yes,
   it stays. The rule above already says so: the slot it just let go is
   free again and the nearest, so it claims it back and has nowhere to
   walk. The ring moves only when the owner does.

## Decisions (2026-11-06)

The agent's calls while building `roam/buddy_open_slots_core.h`, for the
owner to curate:
- **"Reached"** is within the ring's slack (`ringSlack`, 1.5 yards, the
  distance at which a ring follower walks back to its place, 617s2), not
  the arc follow's 1 yard.
- **Several pickers at once** (the first claims, or a ring that changed
  size) share the free slots by least walking in all, the arc follow's own
  sharing, rather than first come first served; one picker alone simply
  takes its nearest.
- **The tank's front slot is the tank's** in this mode: a buddy holding it
  when a tank comes is displaced even mid-walk (617s3), the one exception
  to "never trade mid-walk". With two tanks, the first in the clan's order
  holds the front and the other picks like anyone else.
- **The tank's own waypoint** is renewed, like everyone's, only on arrival
  at the front slot's spot.
