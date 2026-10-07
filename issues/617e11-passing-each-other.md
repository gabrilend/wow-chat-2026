# 617e11 - Passing Each Other

## Status
- Created: 2026-10-07
- Phase: 6
- Parent: 617e (buddy area adventuring)
- Blocked by: 617e2 (the roaming core in game)
- Related: 617v (kneeling at the fallen: the kneel emote), 609 (gesture
  commands: kneeling as a language), 617c2 (proximity party)
- Priority: Medium

## Origin

Asked about crowding at waypoints (617e), the owner, 2026-10-07:

> we need to build an avoidance system anyway. We could maybe do that for
> this task?

And asked what two buddies crossing paths in the open should do:

> ideally, swerve. Maybe wave at each other, or if they're high level
> compared to a low level, stop and kneel for 3 seconds (when neither is
> in combat)

## Current Behavior

Buddies don't see each other while walking. The roaming model checks for
others only when it places a waypoint: someone within 5 yards of a new
waypoint moves it 10 points of Y. Measured, that moves about 1 waypoint
in 20, because buddies mostly meet while walking, not at waypoints. In
game, two bots on crossing lines walk through each other, as stock
playerbots do.

## Intended Behavior

Buddies avoid each other (and players) as they walk, and greet as they
pass.

- **Swerve.** A buddy watches the others near its path. If one will come
  within both their body radii of it in the next few seconds, it bends
  its path to pass beside them. It bends the way the path planner bends
  around a rock (a half-cosine ease out and back), on the side that
  costs less. Both buddies may swerve. Each moves half of the way.
- **Greet.** As two buddies pass within a few yards of each other, and
  neither is in combat:
  - near the same level: one or both wave (the wave emote) as they pass;
  - a much higher level passing a much lower one: the lower one stops
    and kneels for 3 seconds (the kneel emote), then goes on.
- **Crowding at waypoints** (617e's rule, revised 2026-10-07): someone
  within 5 yards of a new waypoint moves it 10 points *toward the
  middle* if the waypoint is in the inner half of the area's radius, and
  *toward the edge* if it is in the outer half.

## Suggested Implementation Steps

1. In the roaming model (`src/lua-basic/lib/buddy-roam.lua`): each step,
   project every nearby buddy's position a few seconds ahead along its
   path. If two projected paths come within the sum of the two body
   radii, bend the path.
2. An animation in the gallery (`scripts/generate-buddy-roaming-gifs`):
   two buddies on crossing lines, before and after.
3. The waypoint crowding rule's new direction (inner half toward the
   middle, outer half toward the edge), with the generator's figures
   before and after.
4. The greeting: who counts as "much higher level", the distance, and
   which buddy waves first. Draw the kneel in the model as a 3-second
   stop.
5. In game (617e2's core): the same checks on the server, every movement
   update, using the bots' current positions and destinations.

## Open Questions

1. **"Much higher level":** how many levels apart before the lower one
   kneels? For example 10 levels, or a share of the level such as
   double?
2. **Players:** do buddies also swerve around players, wave at them, and
   kneel to a much higher-level player?
3. **Buddies of the same clan** (617l): do they greet each other every
   time they pass, or only the first time after being apart for a while?
