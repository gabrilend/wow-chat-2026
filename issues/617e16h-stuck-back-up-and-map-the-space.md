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

And, the same evening, after the first build:

> notice how I said *less than* not stuck. If we're bumping into
> something, then we need to give it more clearance, or else we're
> potentially likely to get stuck. So, touching objects in this way,
> implies given buffer spaces that bots route around or walk through if
> going on a straight shape.

And, seeing red marks dropped on open ground (known walls from detours
counted as stuck, after the measure was turned toward the target):

> it's moving, in some direction, and has moved farther than it's
> distance would suggest. Or rather, it has moved less far than it's
> capability would suggest after following it's path. Basically... after N
> seconds or moments, draw a line to your position you were N seconds or
> moments ago. Then, if you made less progress to your goal than your
> intended movement input array (the array of movement actions you've
> sent to the server to deterministically update your location) the
> client sends both, "here's the keypresses, and here's the position" and
> if they ever differ, the server wins, and pulls the client back. It's
> very jarring.
>
> ... anyway, if you made less progress, as a bot, we know you're not
> cheating. Instead, you must have been caught on something, or the
> geometry disagreed with your movement resolution pathfinding duties
> believed. And so, you should try and walk around that section.
> disprefer the movement track that got you onto that path. let other
> bots come across it and let it be known. This is how you pathfind
> through dynamic environments, you navigate and then it is known.

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

- **Bumps and buffers** (pictures 036-039): a second with under 0.9 of
  the progress meant, while a real obstacle (steep ground, a doodad, a
  known wall, the edge) turned the bot, is a bump: the 3 x 3 cells round
  the touch become buffer (drawn amber). Buffers are kept clear when a
  way round exists, crossed when none does, and walked through by a bot
  on a straight crossing; standing in one doesn't clear it. Tried and
  mended on the way: brushing a buffer first counted as a bump (buffers
  bred buffers, 036); as hard walls buffers sealed narrow passages (038).
- Crossings (617e16d) now end at a decision point after three times the
  time the walk should take, if the far side can't be reached (037).

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
- **Bumping leaves a buffer** (the owner's second message). Less
  progress than meant, short of stuck, while the walls turned it aside,
  means the bot touched something. The cells round where it touched
  become a **buffer**: bots steer round buffers as they do round walls,
  except a bot on a straight crossing (a wanderer crossing the fence),
  which walks through. A bot standing in a buffer doesn't clear it (a
  crossing walks through buffers all the time); a wall cell a bot stands
  in is still proven open.
- **Seen and measured**: known walls drawn (dark red), buffers (amber), the share of the
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
