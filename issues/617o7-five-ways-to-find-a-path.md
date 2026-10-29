# 617o7 - Five Ways to Find a Path, Side by Side

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617o (pathfinding on the navigation mesh)
- Related: 617e16h (stuck, back out, orbit: the sandbox's current way),
  617e16 (the sandboxes), 617e17 (the army that tries them in game),
  136d (the test realm, branched off a living profile), 617o3 (baked
  distance maps), 617o5 (orbiting)
- Priority: High
- State: in progress

## Origin

The owner, 2026-10-28:

> okay can you create at least 3-5 radically different pathfinding
> solutions with equivalent levels of complexity? then, make sure that all
> of them are viewable in-game. I want to test them myself.

And, asked how they should reach the bots in game: "Module switch, one
compile."

## Current Behavior

**Step 1 built 2026-10-28** (pictures 057-061): the ground sandbox's
"Pathfinding" choice (`way=` in the address) runs any of the five for
every bot (`scripts/templates/ground-sandbox.html`, the five-ways
section). The planning grid is the ground's points over the area in play's
box. Flow fields are kept per target and per state of learned obstacles;
A* routes are planned again when the target, the learned obstacles, or 5
seconds pass (keying either on the map's open cells, which grow every
step, made the first runs plan every step: 96,424 routes in three minutes,
a hung flow-field run). Three minutes each on the Witchwing Slayer area:

| Way | Routes or fields | Steps with no way | Spacing |
|---|---|---|---|
| orbit | (orbits: 055, 056) | low | 16-24 yd |
| flow field | 5,310 fields | 0 | 13.8 yd |
| graph and A* | 4,308 routes | 0 | 12.4 yd |
| potential field | none | 0 | 14.7 yd |
| learn the map | 2,919 routes | 60 a second | 18.8 yd |

Not built: step 2's headless comparison tool, step 3 the module switch,
step 4 trying them in game. In game, a buddy still walks the server's
navigation mesh path to wherever its behaviours send it.

## Intended Behavior

Five ways, each a whole answer to "how does a bot get from here to its
target", different in kind, of about the same size to build:

1. **Orbit** (the bug algorithm, the sandbox's present way): straight at
   the target; blocked or slow, back out and walk round the obstacle,
   keeping it on one side, until the target is in sight. No plan, no map
   beyond what it touches.
2. **Flow field**: from the target, the walking distance to every point of
   the area, spread over the walkable ground once (a breadth-first flood);
   every bot steps downhill on it. Shared by every bot with the same
   target; never stuck in a pocket, because the field already went round.
3. **Graph and A***: a sparse graph of places (the area's skeleton: the
   middle lines of its walkable ground, joined where they meet), the
   cheapest route through it by A*, then pulled tight (skipping nodes while
   the next is in sight). Plans the whole way, then follows it.
4. **Potential field**: the target pulls, every obstacle pushes (by its
   distance, from a distance map of the area's walls), the bots feel each
   other; a bot follows the sum. No route at all, only forces; local
   minima broken by a random kick.
5. **Learn the map** ("you navigate and then it is known", 617e16h): the
   bots start knowing nothing but what they have walked and bumped; each
   plans by A* over its knowledge (unknown ground assumed open), walks, and
   plans again whenever it learns a cell it had wrong.

Each is built twice:
- **In the ground sandbox**: a "Pathfinding" choice on the panel, so the
  five can be watched on the same ground, with the same measures (times
  stuck, yards walked per yard gained, spread, cover).
- **In game**: in the buddy module, behind one switch, `.buddies path
  <way>` (for one buddy, a partner's buddies, or the army of 617e17),
  each way computing on the module's own copy of the walkable ground
  (`buddies_navmesh` and the zone's grid) and giving the bot module its
  next point to walk to. One compile (the owner's), then switched live.

## Suggested Implementation Steps

1. The five in the sandbox, one at a time, each a committed version with
   its picture and page backup.
2. Their comparison: the same zone and fence, five runs, a table of the
   measures (a tool runs them headless).
3. The module patch: the switch command, each way's planner over the
   walkable grid, the point handed to the bot's movement; its quick tests
   (each planner on a small made-up grid, offline).
4. The owner's compile; trying them in game with the army (617e17), on
   the test realm (136d).

## Open Questions

1. Which measures decide the better way: least stuck, least wasted
   walking, most even spread, or how it looks (the owner's eye)?
