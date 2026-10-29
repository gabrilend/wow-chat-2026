# 617e16k - Circulation: No Cocoons

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617e16 (the fish-school sandbox)
- Related: 617e16h (the shared map: walls and buffers), 617e16d (the
  wanderers), 617e16j (the area: the player's monster cluster in the
  player's sub-zone)
- Priority: High
- State: in progress

## Origin

The owner, 2026-10-28:

> the problem with the false walls is the bots tend to get stuck in their
> little coccoons, so if they're staying in the same quadrant of the spawn
> zone for too long, then we know they're not circulating. We want them to
> spread out and be dynamically spread throughout the subzone.

## Current Behavior

**Built 2026-10-28 in the ground sandbox** (steps 1-3; pictures 048,
049), `scripts/templates/ground-sandbox.html`'s circulation section: eight
sectors by bearing round the area's middle; a bot in one sector longer
than 30 seconds walks (through buffers) to a walkable point of the
emptiest other sector, until within 8 yards or 60 seconds; not while
exploring a peninsula. Panel: moves, and bots per sector now (picture
049: 103 moves in five minutes, 1 to 7 bots a sector). Every sector
meets at the middle, so bots near it don't count as stuck anywhere;
inner and outer halves of each sector would push them outward too.

## Intended Behavior

- **Sectors.** The area in play is cut into sectors round its middle
  (eight, by bearing). Each bot knows which sector it is in and how long
  it has been there.
- **Not circulating.** A bot in the same sector longer than CIRCULATE
  seconds (30 to start) is not circulating: it picks the sector with the
  fewest bots in it now (a random one among equals), a walkable point of
  the area in that sector, and walks there, through buffers as a crossing
  does (they are dispreferred, not walls), until it arrives or its time
  runs out; then it wanders as before.
- **Spread, dynamically.** Because the least-occupied sector is chosen at
  each move, the bots spread over the whole area and keep moving through
  it, rather than settling.
- **Measured**: moves made, and the bots in each sector now (the fewest
  and the most).

## Suggested Implementation Steps

1. Sectors of the area in play; each bot's sector and time in it.
2. The move: the least-occupied sector, a walkable point in it, walked to
   through buffers; arrival or a time limit ends it.
3. Measures; pictures; a commit and a page backup per version.

## Open Questions

1. **How long is too long**, and how many sectors? 30 seconds and eight
   to start.
