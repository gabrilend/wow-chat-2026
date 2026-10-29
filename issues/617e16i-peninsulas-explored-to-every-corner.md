# 617e16i - Peninsulas Explored to Every Corner

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617e16 (the fish-school sandbox)
- Related: 617e16f (the walkable parts), 617e16h (the shared map of known
  ground), 617e14 and `docs/pathfinding-questing-and-dungeons.md` (the
  tank's dungeon routes, the floor skeleton), 617e12 (caves and tunnels)
- Priority: High
- State: in progress (planning)

## Origin

The owner, 2026-10-28:

> also they should treet navmesh "peninsulas" like indoor buildings and
> such as something to investigate thoroughly, and they'll try to paint
> every corner of it as they explore through. Each time they get near the
> door or through-ouuuu, they'll move in and only leave when they've seen
> the whole patch of spot.

> if a player is inside one, then they treat it like an instance, as if
> they were tanks.

## Current Behavior

The walkable parts (617e16f) are one shape each; nothing tells a room or
a dead-end pocket joined to the rest by a narrow neck from open ground,
and the bots wander them all alike.

## Intended Behavior

- **Finding peninsulas.** In a walkable part, a peninsula is ground joined
  to the rest only through a narrow way (a door, a gap, a gully): worked
  out by shrinking the part's walkable ground by a few yards (what a
  narrow way can't keep is cut), finding the pieces it falls into, and
  growing each back. A piece that isn't the main body is a peninsula; the
  narrow cells joining it back are its door.
- **Exploring them.** A bot coming near a peninsula's door that hasn't
  been seen whole goes in, and walks to the nearest corner of it not yet
  seen (seen: within sight, a few yards, of a bot), until every corner
  is seen; then it leaves and wanders on. Seen corners go on the shared
  map (617e16h), so the next bot finds a seen peninsula seen.
- **The player inside one: an instance.** When the player stands inside
  a peninsula, the bots treat it as a dungeon: as tanks would, they go
  ahead through it in order, each corner taken in turn, rather than
  wandering round the player.
- Drawn: peninsulas outlined, their doors marked, seen corners shaded;
  measured: peninsulas found, seen whole, being explored.

## Suggested Implementation Steps

1. Peninsulas of a part: erosion (a few cells), the pieces, growing back,
   doors.
2. Exploring: near a door and unseen, go in; the nearest unseen corner;
   out when all seen; the seen corners on the shared map.
3. The player inside: the tank's way (ahead, in order).
4. Drawing, measures, pictures.

## Open Questions

1. **How narrow is a door?** The shrink sets it: 2 cells each way (about
   8 yards: a way under about 16 yards wide is a door) to start. Wider,
   or narrower?
2. **"as if they were tanks"**: in order of what: nearest unseen corner
   first (a sweep), or along the peninsula's skeleton from its door to
   its far end (as the tank's dungeon routes)?
