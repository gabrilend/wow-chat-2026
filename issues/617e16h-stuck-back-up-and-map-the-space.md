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

And then, replacing backing up with orbiting:

> okay how about this - if a buddy is on an uninterrupted or redirected
> movement order for a second or more (configurable, down usually) then
> we test - are they in a state where they haven't travelled as far as
> they probably should have been able to? Basically, snapshot their
> position every second or so, and the position where they were standing.
> Then do a range check from that position to the target position. if
> that's less than the distance they were able to have travelled, then
> they're stuck on something and need to orbit the obstacle in front of
> them. We can tell they're obstacles because they're unpathable on the
> map. Those things. Orbit around them, either clockwise or
> counter-clockwise. until you get to a position on the other side that
> is in line-of-sight of a forward position on the path you're trying to
> follow. Then you should move along that.

And, keeping backing up beside the orbit:

> remember it should double it's "backup distance" anytime it's trying to
> back out of something it's stuck on. this distance should be reset when
> they've travelled farther on the forward axis than the place they were
> foremost stuck. That's when they can relax, because they've solved the
> most stuck forwardmost spot. [questing mob slain most recently]

## Current Behavior

**Built 2026-10-28 in the ground sandbox** (pictures 034-047, every
version a commit of its own), `scripts/templates/ground-sandbox.html`:
- **What the bots know and what the world holds.** A bot steers by what
  it knows: steep ground (as the navigation mesh knows it, `steepAt`), the
  shared map's walls and buffers, the area's edge. The world holds that
  and the doodads (trees, rocks, huts, `blocked`); a step into one is
  refused, and the bot stays where it was (the server pulling the client
  back).
- **Caught: the owner's test.** Each second, the moves the bot put in
  (summed) against the line from where it was to where it is: moving (at
  least 0.6 of full speed) and getting under 0.95 of its inputs along
  their way, it is caught. The refused spot becomes a known wall (no
  refusal: the cell just ahead); the last 3 cells of the track that led
  there become buffer (dispreferred); it backs up straight back, 2 yards,
  then 4, 8 ... up to 64 while it keeps being caught; a second not caught
  starts the doubling again. Not measured while backing up, fighting, or
  standing in formation. A wanderer caught on a crossing or turning aside
  takes it as its decision point (617e16d).
- **The shared map**, 2-yard cells: open where a bot has stood, a wall
  where a step was refused, buffer on the tracks that led there. Standing
  in a wall cell proves it open (a wrong mark mends itself); standing in a
  buffer doesn't clear it. Buffers are kept clear when a way round exists,
  crossed when none does, walked through on a straight crossing.
- Drawn: walls dark red, buffers amber, a bot backing up ringed white.
  Panel: times caught, steps refused, buffer cells, yards backed up, the
  share of the part known open (picture 047: caught 445 times, 28,960
  steps refused, 131 known walls in four minutes).
- The versions on the way, each kept: judged by the bot's velocity after
  the walls turned it (scraping along a wall looked fine, never backed
  up); by the straight way to the target (a detour looked stuck: false
  walls on open ground, 041-043, "dropping a red pixel every once in a
  while"); three good seconds to reset the doubling (back-ups grew to 64
  yards); bumps from brushing buffers (buffers bred buffers, 036);
  buffers as hard walls (sealed passages, 038). Crossings end after three
  times the walk's time if the far side can't be reached (037).

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
