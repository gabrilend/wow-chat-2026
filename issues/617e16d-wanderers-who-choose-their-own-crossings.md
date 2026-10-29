# 617e16d - Wanderers Who Choose Their Own Crossings

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617e16 (the fish-school sandbox)
- Related: 617e16c (the sandbox on the ground: heights, slopes, doodads,
  where this is built), 617e16e (formations), 617o (pathfinding)
- Priority: High
- State: in progress

## Origin

The owner, 2026-10-28, watching the ground sandbox:

> also the player click dot should move instantly.
>
> also in the simulation, they all choose to move to the center at the
> same time, they in general make movements in an orchestrated way. They
> should be more unique about it, because we are simulating it that way on
> the backend. so, they should choose when to pass through the center on
> their own, when they make I think it was... 3? direction orientation
> shifts that are toward the center? basically, a guaranteed hard turn.
> That means they should walk straight for a while until they get to the
> other side of the zone they're wandering within, and then turn aside.
> They can pick whichever one feels closer to the average of the zone. in
> terms of height slope elevation levels. Average the pathable and
> playable (intended behavior) areas and leave out ocean zones. That's the
> level, and it's what we measure ourselves against. If our wanderings put
> us above that level, then we wander down when we have decision points to
> make about that. In this case, specifically when we have crossed a zone
> through it's center because we were wandering and decided to. We'd need
> 3 pathing turns though and that doesn't happen often because the
> waypoints are far apart. Scaled to the map of course.
>
> if they make 3 turns away, then they reverse orbit direction. Oh and if
> the player is nearing the edge of the sub-zone they're wandering in, the
> one they're clearing of monsters... (spawn rates ensure everyone's
> replenished, sending bursts from afar if necessary)

(Her asides of the same message are in `notes/conversation-asides.md`.)

## Current Behavior

The sandbox's bots move as one: each circles the fence's middle at a depth
re-chosen every 6-12 seconds from the band crossed least lately. Since
every bot reads the same "least-crossed band", they all pick the same
depth at about the same time and dive toward the middle together: the
orchestrated look. The player's dot walks to a click at 7 yards a second.

**Built 2026-10-28 in the ground sandbox** (`scripts/templates/ground-sandbox.html`;
pictures 025-027): the player's dot is where it is clicked, at once; and
**"wanderers"** in the Turning list. Each wanderer orbits in its own
direction at its own depth on its own clock, and every 40-120 seconds of
its own crosses straight through its own point near the middle (up to a
quarter of the fence's reach to either side: aimed at the one middle
point, the first try made a starburst, picture 025). At the far side it
turns aside 100 degrees, left or right, whichever way the ground 25 yards
ahead is nearer the zone's level (the average height of the zone's own,
not steep, ground: 110.6 yards for the Barrens), walks that way 4
seconds, and orbits again; its third turn against its orbit reverses
it. The panel counts crossings, turns down and up, reversals. Wanderers
don't lean toward the school's heading (their heading is their own).
Not built: open question 2's edge behaviour.

## Intended Behavior

As read from the owner's words (the readings are open questions 1-2):

- **The player's dot moves instantly** to where it is clicked.
- **Each bot decides alone.** Every bot orbits on its own clock; nothing
  shared (no common band, no common timer) makes them choose together.
- **Crossing.** Now and then, at a moment of its own choosing, an
  orbiting bot turns toward the fence's middle and walks **straight**,
  through the middle, until it reaches the far side of the fence: a
  crossing. It doesn't steer back onto its circle on the way.
- **Turning aside, by the ground.** At the far side it is at a decision
  point and must turn aside, left or right (a hard turn). It takes the
  way whose ground is closer to **the zone's level**: the average height
  of the zone's walkable ground (its own squares, ocean squares already
  left out of the zone data, ground not steeper than the limit). So a bot
  above the level turns downhill, one below it turns uphill. Then it
  orbits again, in the direction that turn set it going.
- **Three turns away reverse the orbit.** A bot counts its turns aside
  that go against its orbit direction; at the third it reverses its orbit
  (clockwise to anticlockwise or back) and starts counting again.
- **Scaled to the map**: crossings are long, fence-wide walks, and turns
  rare, as in the game where waypoints are far apart.

## Suggested Implementation Steps

1. In `scripts/templates/ground-sandbox.html`: the player jumps on click.
2. The zone's level: computed by the page when the ground comes, from the
   points inside the zone's own squares that aren't steep.
3. "wanderers" in the turning list: per bot, a state (orbiting or
   crossing), its own orbit direction, its own time until it next
   crosses (random, drawn from its own clock), the heading of its
   crossing, and its count of turns against its orbit.
4. Measures on the panel: crossings a minute, turns by the ground (down
   or up), orbit reversals.
5. Pictures filed by the page's tool.

## Open Questions

1. **"3 direction orientation shifts that are toward the center"**: read
   here as: a crossing is the bot turning toward the middle and walking
   straight through it, and the "3" belongs to the next sentence (three
   turns away reverse the orbit). Or is a crossing made of three turns
   (toward the middle, through, and aside)?
2. **"if the player is nearing the edge of the sub-zone they're wandering
   in, the one they're clearing of monsters..."**: the sentence stops
   there. What should the bots do when the player nears the fence's edge:
   follow toward that edge, gather to them, or start drifting toward the
   next fence?
