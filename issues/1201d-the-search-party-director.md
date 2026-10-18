# 1201d - The Search Party Director

## Status
- Created: 2026-10-17
- Phase: 12
- Parent: 1201 (robot search party)
- Blocked by: 1201a, 1201b, 1201c, 1201e
- Priority: Medium

## Current Behavior

Nothing exists. Left 4 Dead 2's Director spawns common infected in
hordes that run straight at the survivors.

## Intended Behavior

The add-on's Director script (VScript, run by the game on map start)
makes the robots a search party and is the playable demo:

- **Spawning**: robots appear out of sight in rooms the survivors have
  not reached (the map's flow attribute says which way is ahead), a few
  at a time rather than in hordes.
- **Searching**: each robot is given a room and sweeps it by the
  roaming pattern (1201a), painting ground covered; a swept room is
  handed to the next robot in turn, as buddies take sectors.
- **Closing in**: a sighting turns nearby robots to the distance map
  and steering (1201e).
- **Pacing**: the Director's own tension rules decide how many robots
  are out; ours decide where each one goes.
- **A receipt**: a bots-only run (no player) writes the house goodbye
  receipt to `output/goodbye` (seed, robots commanded, rooms swept,
  sightings, minutes run), with screenshots into `tmp/shared-memory/`
  and `development-history/`.

## Suggested Implementation Steps

1. The script on one official campaign map, robots spawning and
   sweeping, no closing in yet.
2. Closing in (1201e), then the hand-back to searching.
3. The receipt and the bots-only run.
4. A second campaign map, unchanged settings.
5. Package the add-on (`.vpk`) with the models (1201c) and the scripts.

## Open Questions

- Do robots replace every common infected, or mix with a few ordinary
  ones (an infection that has not finished)?
- Should the robots talk (radio chatter as captions, "sector four
  clear"), using the buddies' chat layer as 1202 does? It would show a
  second framework piece here.
