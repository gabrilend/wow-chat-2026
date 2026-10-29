# 617e16h - Stuck: Back Up, Try Again, and Map the Space

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617e16 (the fish-school sandbox)
- Related: 617e16c (the ground), 617e16f (walls; its open question 1 on
  walls learned by bumping), 617o (pathfinding in the world: the same rule
  for the buddies, later), 617o5 (orbiting round what blocks)
- Priority: High
- State: in progress

## Origin

The owner, 2026-10-28, watching the ground sandbox:

> okay they keep getting stuck on obstacles - here's our solution - if
> they're moving at full speed in a direction but they aren't making
> progress moving in that direction, then that means they're stuck on
> something. When that happens, they need to back up, and try again. If it
> happens again, then they back up twice as far, and so on, and keep
> trying until we've fully mapped out the available space. Only then can
> we properly route-pathfind to things.

## Current Behavior

**Built 2026-10-28 in the ground sandbox** (steps 1-3; pictures 034, 035),
`scripts/templates/ground-sandbox.html`'s stuck section:
- Each bot's second: how far it meant to go (speed before the walls) and
  how far it got along that way; meant at least 0.6 of full speed but got
  under a quarter of it: stuck. Backs up 2 yards straight away from where
  it meant to go, then 4, 8 ... up to 64 while it keeps getting stuck;
  three good seconds in a row start the count again. Not measured while
  backing up, fighting, or standing in formation.
- One map the zone's bots share, 2-yard cells: open where a bot has
  stood, a wall where one got stuck facing (a bot standing in a wall cell
  proves it open: wrong marks from a crowd mend themselves). Known walls
  join the walls bots steer round. Started afresh with each zone.
- Drawn: known walls as dark red squares. Panel: times stuck, yards
  backed up, the deepest run of doubling, the share of the part in play
  known open, the known walls (picture 035: stuck twice, 38% known open
  after four minutes).

Not built: step 4, routes over the known cells (open question 1).

## Intended Behavior

- **Noticing it's stuck.** Each bot measures, over each second, how far
  it meant to go (its speed times the time) and how far it really went.
  Meaning to go at nearly full speed (more than three fifths of it) but
  getting less than a quarter of that: stuck.
- **Backing up, twice as far each time.** A stuck bot backs up, straight
  away from the way it was heading: 2 yards the first time, 4 the next,
  then 8, and so on (up to 64), then tries again. Three good seconds in a
  row (most of what it meant to go, gone) and the count starts again.
- **Mapping the space.** Everything learned is kept on one map the
  zone's bots share, in 2-yard cells: each cell a bot stands in is
  known open; the cell just ahead of a bot that got stuck is a known wall,
  and every bot walks round known walls from then on, as it does round
  steep ground. The map is kept while the player stays in the zone.
- **Seen and measured**: known walls drawn (dark red), the share of the
  part in play known open on the panel, stuck events and back-ups
  counted.
- **Then routes** (after the map; the owner: "Only then can we properly
  route-pathfind to things"): a bot's way to a far target found over the
  known-open cells (A*), instead of heading straight for it.

## Suggested Implementation Steps

1. The per-bot second's measure, the stuck rule, the back-up and its
   doubling (in `scripts/templates/ground-sandbox.html`).
2. The shared map: open and wall cells; walls joining the walls a bot
   steers round.
3. Drawing and measures; pictures filed.
4. Routes over the known-open cells, once a part is mostly known.

## Open Questions

1. **When is the space "fully mapped"?** Routes could start for a part
   once some share of it is known open (say four fifths), or per target:
   a route found over known cells is used, and a target not yet reachable
   over known cells is walked to straight, mapping as it goes. Which?
