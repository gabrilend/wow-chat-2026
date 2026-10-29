# 617e16f - Fences Reshaped by the Ground

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617e16 (the fish-school sandbox)
- Related: 617e16c (the ground: heights, slopes, doodads), 617e16d (the
  wanderers), 617o5 (orbiting round what blocks the way, in the world),
  617e12 (drawn areas, caves and tunnels)
- Priority: High
- State: in progress

## Origin

The owner, 2026-10-28, after the ground sandbox:

> okay the sub-zones that players are wandering in need to be modified.
> If there's an impassible space, we should build a mental "wall" around
> it and pathfind around it as if it were a doodad or object by orbiting.
> If we find ourselves outside of the zone, then, well, we've found it's
> edge. Keeping in mind, some sub-zones can be interrupted by another -
> for example walking into a tunnel with it's own name, then walking out
> into the same zone but, in a different part. We need to be sure to be
> able to merge those zones because of their shared name.
>
> the mental wall should persist as long as the character is within it.
> It should modify the accessible parts of the sub-zone, the monster
> spawning zone, the area we're wandering within. So that we more
> properly path around and through our wanderings.
>
> though, if it's fully separate from another part of that sub-zone, then
> it should be split into two. Or, the same, but accessible from afar.

## Current Behavior

**Built 2026-10-28 in the ground sandbox** (steps 1-5; pictures 028,
029), in `scripts/templates/ground-sandbox.html`'s areas section:
- An **area** per fence name: every outline of that monster in the zone,
  less ground steeper than the limit, on the ground's points; its
  walkable points cut into connected parts (four neighbours; parts under
  12 points dropped). Each part has its middle, its reach on 72 bearings
  (the farthest of its points along each), its size, and its own
  "inside". Worked out once per name and limit.
- The **part in play**: the one the player stands in (or the nearest);
  the flock, the wanderers, the patrol, the close-up and the measures all
  use it. Drawn: the part in play filled, the name's other parts faint,
  every outline of the name lit. The panel names it: "part 3 of 6, 1719
  sq yd walkable".
- **Walls**: the part's edge is a wall for a bot inside it; meeting any
  wall (steep ground, a doodad, the edge) the bot turns to its side, 20
  degrees at a time up to 160, the other side only if its own is shut,
  and keeps that side 1.5 seconds after it last met the wall.
- Seen: the Witchwing Slayer area is one part of 102,396 square yards;
  the Venture Co. Supervisors' (over Boulder Lode Mine) is six.

Not built: the walls remembered per bot (open question 1).

## Intended Behavior

- **The walkable fence.** A fence's area is its outline less the ground
  that can't be walked (steeper than the limit): worked out on the
  ground's own points (4.17 yards), so the bots' wandering area is the
  ground they can really reach.
- **Merged by name.** Every fence of one monster in the zone is one area
  ("their shared name"), however many clusters and whatever lies between
  them (a tunnel, another sub-zone, a ridge).
- **Split where it doesn't join.** The area's walkable points are
  gathered into connected parts. The part the player stands in is the
  one in play: its middle is the orbit's middle, its reach along each
  bearing the orbit's edge, its edge a wall ("If we find ourselves
  outside of the zone, then, well, we've found it's edge"). The other
  parts are the same area, drawn and waiting: "accessible from afar"
  (the player walking into one makes it the part in play).
- **Mental walls.** Where a step meets blocked ground or a doodad, the
  bot keeps that obstacle on one side and walks round it (orbits it),
  rather than trying left and right in turn; it keeps to that side while
  it is still against the obstacle, and lets go once its way to its
  target is clear.

## Suggested Implementation Steps

1. In the ground sandbox's page: the area of a fence's name (merged
   outlines, less steep ground), its connected parts, each part's middle
   and reach (72 bearings).
2. The part in play from the player's position; the flock, the
   wanderers, the patrol and the measures use the part (its middle, its
   reach, "inside" meaning its walkable points).
3. The part's edge as a wall for the bots inside it; the persistent side
   when orbiting an obstacle.
4. Drawn: the part in play filled, the other parts outlined faintly.
5. Pictures filed by the page's tool.

## Open Questions

1. **"the mental wall should persist as long as the character is within
   it"**: read here as: the area's reshaping (its walls) holds while the
   character is inside the area, and is worked out again when it enters
   another. Or should a wall a bot has met be remembered by that bot
   (each its own memory of the walls it found) rather than known to all
   from the start?
