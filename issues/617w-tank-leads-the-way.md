# 617w - The Tank Leads the Way

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617 (buddy bots)
- Blocked by: 617s (the compass formation)
- Priority: Medium

## Origin

Verbatim, 2026-10-04: "the tank should move to the next mobs in a dungeon
or raid automatically. The buddy-bots should orient themselves around the
tank (half circle though, facing away from where the tank is facing,
arcing behind the tank like a peacock tailfeather display.) and do the
thing where they only get a new waypoint when the previous one is
reached. The compass style follow mode will also be of use. Same for the
'goto' target spell. We will make great things with this system."

## Current Behavior

Not built. In a dungeon the bot module's bots follow their leader and
fight what the leader attacks (617c3 adds striking at 110% of an aggro
radius).

## Intended Behavior

- **The tank advances**: in a dungeon or raid, a buddy tank walks to the
  next monsters on its own (the nearest pack ahead on the mesh, not yet
  fought), and pulls.
- **The tail feathers**: the other buddies arrange on a half circle behind
  the tank, the arc's open side toward the tank's facing, like a
  peacock's display; each takes a place on the arc (617s1's matching) and
  gets a new waypoint only when it reaches the last (617s2).
- The compass follow (617s) and the send-one-buddy spell (617s6) are the
  same machinery used here.

## Suggested Implementation Steps

1. The tank's next-pack choice on the mesh.
2. The half-circle places behind the tank (617s1's geometry, half the
   circle).
3. Waypoint-on-arrival (617s2).

## Open Questions

1. Should the tank wait for the party's health and mana before each pull?
