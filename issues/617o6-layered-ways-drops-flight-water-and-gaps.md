# 617o6 - Layered Ways: Drops, Flight, Water and Gaps

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617o (pathfinding on the navigation mesh)
- Related: 617o3 (baked distance maps: where the layers are baked),
  617o5 (orbiting round what blocks the way), 617e8 (routes across maps,
  which would use these layers too), 617's principle of 2026-10-28
- Priority: High
- State: plan only

## Origin

The owner, 2026-10-28, on what to bake ahead: "ore, herbs, and chests
would always be reachable because otherwise how could a player reach
them?"; "the buddy-bots will eventually be able to do everything the
players can"; and:

> The baking should be multiple layers. We should have "one way paths"
> like jumping down a cliff, and anywhere should be "pathable" to those
> with flying mounts, although they should make arcs when they fly to a
> specific spot. Underwater path finding is also important. The small gaps
> and such should either be smoothed and avoided, or if they are larger
> than a person then we should route around them the same way we route
> around doodads, with an orbit and leave as soon as we have a clear shot
> to the next waypoint.

And later the same day:

> How do we handle jumping across the Wailing Caverns gap? There's a jump
> there that players need to get across.
>
> For the one-way drops, be sure to account for the server's fall damage
> setting...
>
> Buddies can drop as far as they can survive. The arcs should be
> randomized but still on a natural trajectory toward the destination.
> The mount is following wind patterns that we can't see.

And then:

> Sometimes we need to do less than running jumps. You can jump straight
> up and then move forward to make a tiny arc, so we should treat all of
> those arcs as possibilities. I want to dynamically calculate the jumping
> patterns every time we do it because it's very intrinsic to the WoW
> character's form. Buddies can jump whenever they want. Some are just
> bouncy people.

## Current Behavior

A buddy walks only where the navigation mesh joins ground to ground, and
the bot module keeps bots off its steep slopes. It never drops off a
ledge on purpose, never flies, and swims only where the mesh's water
polygons happen to join its route. Where the mesh has a hole, a seam or a
small wall that isn't there in the game, routes stop short or go the long
way.

## Intended Behavior

The ways a buddy may go, as layers baked ahead of time (the world's ground
doesn't change) and searched together:

- **Walking**: the mesh, as today.
- **One-way drops**: from a ledge down to the ground below, each a
  one-way link: taken down, never up. **As far as the buddy can survive**,
  by the server's own fall rule (`Player::HandleFall`): a fall of h yards
  costs (0.018 x (h - its safe fall) - 0.2426) x the realm's fall-damage
  rate of its maximum health. The rate is read from the realm's settings
  (`Rate.Damage.Fall`, 10 on every profile today: config patch C004), not
  written into the bake: at 10, falls under 13.5 yards cost nothing, and
  a buddy at full health survives up to about 19 yards. So each drop link
  keeps its height, and the search, at the moment it plans, takes only
  the drops the buddy survives with its health then (and its safe-fall
  effects: Slow Fall, Levitate, safe-fall talents).
- **Jumps**: worked out live, every time, not baked ("I want to
  dynamically calculate the jumping patterns every time we do it because
  it's very intrinsic to the WoW character's form"). A jump is the
  character's own: its upward speed and the fall that follows, with any
  forward speed from none (straight up, then a nudge forward: a tiny arc)
  to its full run, so every arc in between is a possibility. Where the
  way ahead is cut (a gap, a step too high to walk, the Wailing Caverns
  gap players must cross, the first test), the search tries the arcs from
  where the buddy stands and takes one that lands on ground it can stand
  on; carried out with the server's own jump movement. A jump the search
  never finds can still be placed by hand, as inn beds are.
- **Jumping for its own sake**: "Buddies can jump whenever they want. Some
  are just bouncy people." Each buddy has its own bounciness, how often it
  hops as it goes, from never to often: drawn at random when it is made and
  kept for life; tauren never ("with their extra mass, are never bouncy").
- **Flight**: for a buddy with a flying mount (where flying is allowed),
  anywhere is reachable. The flight is an arc toward its spot, **its shape
  random each time but a natural trajectory** (rising, a curve that bends
  as if the mount rode a wind no one can see, coming down onto the spot),
  not a straight line; it lands on ground it can stand on.
- **Water**: swimming routes underwater and on the surface, joined to the
  shores, so a node in a lake or on the sea floor has a way to it.
- **Gaps**: a gap or seam smaller than a person is smoothed over (joined)
  or avoided; one larger than a person is gone round as a placed object is
  (617o5's orbit), leaving the orbit as soon as there is a clear line to
  the next waypoint.

## Suggested Implementation Steps

1. The bake's file format: the mesh's own tiles, plus links (one-way
   drops, water joins, smoothed seams) per tile, so the search reads one
   graph.
2. One-way drops: found by stepping off each ledge on the mesh and
   finding the ground below within a survivable height.
3. Water: the map files' water section (as the zone data reads it) gives
   where water is and how deep; swimming links from shore to shore and to
   the sea floor.
4. Gaps: seams and holes between mesh polygons narrower than a body width,
   joined; wider ones kept, for the orbit.
5. Flight: no bake needed for "anywhere"; the arc is a planned curve with
   its landing checked on the mesh.
6. A sweep over every herb, ore node and chest: which have a route by the
   layers, which not and why; the list is the work left (617's principle).

## Open Questions

1. (Answered 2026-10-28) **How high a drop**: "Buddies can drop as far as
   they can survive", by the server's fall-damage setting.
2. (Answered 2026-10-28) **Flight arcs**: "randomized but still on a
   natural trajectory toward the destination. The mount is following wind
   patterns that we can't see."
3. (Answered 2026-10-28) **Jumping**: "Buddies can jump whenever they
   want. Some are just bouncy people." All arcs, worked out live.
4. (Answered 2026-10-28) **Bounciness**: "Random when made. But Tauren,
   with their extra mass, are never bouncy." Drawn at random when a buddy
   is made and kept for life; a tauren's is always none.
