# 155z2 - Front Lanes

## Status
- Created: 2026-10-04
- Phase: 1
- Parent: 155z (the Dark Portal front)
- Blocked by: None
- Priority: Medium
- Related: 617e2 (buddy roaming designed from drawn animations), 617o (navigation mesh)

## Origin

See 155z (the owner's words, 2026-10-04, quoted in full there).

## Current Behavior

Not built. Stock creatures walk straight to a point or chase a target by
the server's own pathing.

## Intended Behavior

Every fighter at the front runs on a lane: a path fixed when it is laid,
made of straight lines, arcs and splines, "running mostly forward":
straight ahead at a right angle from the portal for the allies, straight
up the causeway for the demons.

- Lanes never cross, and keep a minimum gap from each other (yards, a
  number) along their whole length.
- A runner never slows: its speed along the lane is constant; it stops
  only to fight (155z5).
- Lanes are laid round players: a player standing on the causeway is a
  circle the lanes bend round (an arc out and back), and because the lanes
  are fixed and mostly straight, the runners' paths round a player are
  known in advance.
- The lane set is deterministic: the same inputs (causeway outline, players'
  positions, lane count) always give the same lanes.

Lane: an ordered list of segments, each a line (two points), an arc
(centre, radius, start and end angles) or a spline (four control points),
plus its width (number). Positions along it by distance.

## Suggested Implementation Steps

1. Read the causeway's walkable outline from the navigation mesh (617o).
2. Lay lanes offline (Lua, the drawing language of the project) and draw
   them to an animated image for the owner, with a player standing in the
   middle, before any server code.
3. Port the lane maths to C++ with a comparison test, as the roaming core
   was (`scripts/test-buddy-roam-core`).

## Open Questions

1. The minimum gap between lanes, and the runners' speed.
