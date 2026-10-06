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

Not built. The compass formation (617s) is planned with one way of
choosing slots: each buddy's own compass direction.

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

1. When a buddy arrives and its own slot is still the nearest free one
   (the owner stood still), does it stay put (no new waypoint), so the
   ring is calm while the owner rests?
