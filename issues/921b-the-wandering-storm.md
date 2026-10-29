# 921b - The Wandering Storm

## Status
- Created: 2026-10-29
- Phase: 9
- Parent: 921 (Alterac Valley's shared weather)
- Blocked by: 921a (the shared clock it rides on)
- Switch: `Buddies.AlteracWeather` (the parent's)
- State: planned

## Origin

The owner, 2026-10-29 (whole request in 921): "A storm cloud should wander
across the map and always be intensely downpowering".

## Current Behavior

Not built. Weather in the game covers a whole zone at once; nothing in
Alterac Valley moves across it.

## Intended Behavior

- **One storm, everywhere the same.** A single storm cell with a place on
  the Alterac Valley map, the same in every copy at the same moment (it
  lives on 921a's server-wide clock).
- **It wanders.** It drifts at a walking pace (2 yards a second), keeping
  its heading for a while and turning gently: a random walk with momentum,
  never a straight line, never a jitter. It turns back from the valley's
  edges (the playable box read from the zone data, `assets/zone-maps/` for
  map 30), so it never leaves.
- **It covers the valley evenly over time.** A storm that lingers in one
  corner is a broken storm. Its turning leans toward the parts of the
  valley it has visited least lately, so over a long match every part has
  had its share of storm. (The same unpredictable-but-even idea as 921a's
  deck, in space.)
- **Always a downpour.** Within its radius (60 yards), every player gets
  the heaviest rain the game shows, at full strength, with thunder. It
  never weakens and never takes the deck's kind. From 60 to 90 yards it
  fades into the shared sky; beyond 90, the shared sky alone.
- **Sent to each player.** Weather in the game is zone-wide, so the storm
  is drawn by sending each player under it their own weather. It is
  checked every couple of seconds, and sent only when a player's weather
  changes, so nobody's screen flickers.

## Suggested Implementation Steps

1. The storm's walk as plain arithmetic beside 921a's deck: its place at
   time t, the momentum, the turn back from the edge, the lean toward the
   least-visited parts.
2. Its offline test:
   - over a simulated day it never leaves the box;
   - every tenth of the valley is under it for a share near its tenth;
   - its heading changes smoothly;
   - a player at 59, 75 and 91 yards gets the downpour, a blend, and the
     shared sky.
3. The server side: each player in an Alterac Valley copy measured against
   the storm every couple of seconds, and sent their weather when it
   changes.
4. Shown on the battleground sandbox page beside Arathi Basin (617e16l)
   once Alterac Valley's ground is drawn there, so the walk can be watched
   from above.

## Open Questions

1. The storm's size (60 yards, fading to 90) and pace (2 yards a second):
   big and slow enough to be weather, small enough to be dodged?
2. One storm, or one for every few matches running (a busier sky as more
   play)?
