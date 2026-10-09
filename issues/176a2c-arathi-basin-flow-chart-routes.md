# 176a2c - Arathi Basin: Flow-Chart Routes

## Status
- Created: 2026-10-08
- Phase: 1
- Parent: 176a2 (an Arathi Basin match)
- Blocked by: 176a2b (squads)
- Related: 176a1 (Alterac Valley: pathfinding checked first), 176a's
  movement coroutines, 617e (buddy roaming: the exploring rules), the bot
  module's road paths (`vPaths_AB` in mod-playerbots'
  `BattleGroundTactics.cpp`)
- Priority: Medium

## Origin

The owner, 2026-10-08 (whole request in 176a2): "They should
alternatingly travel down each path intersection to reach the enemy base
- it works like a flow chart where you reverse the path each time you
cross it. [...] when they respawn they should know how to leave the
graveyard and travel one way or the other. [...] They can go along the
side paths between BS and GM, and BS and LM, but not the secret water
path unless they are knocked off by like, cyclone or something."

## Current Behavior

**2026-10-08: the rule is built and tested on paper; nothing walks it
yet** (no stand-ins, no running scene):
- `scripts/generate-arathi-basin-roads` copies the bot module's 15 paths
  (read from its committed source) into
  `src/lua-cc-test/data/arathi-basin-roads.lua`, homes named by place
  ("north-west home", "south-east home"); it stops if any path's ends
  don't meet at its places.
- `src/lua-cc-test/lib/arathi-basin-routes.lua`: the roads as a graph; at
  each place, every road but the one arrived by, taken in turn (a pointer
  per side, per place, per road arrived by); a squad that appeared at a
  place may take any road there. Rebuilt the same day: the first version
  counted only roads nearer the enemy's home, and on these uneven roads
  sent the south-east side from the Gold Mine straight into the enemy's
  home past every other base; the owner chose "any road but the one just
  come by" instead.
- `scripts/test-arathi-basin-rules` (with the bonuses): no step goes back
  the way it came; 30 squads reaching the Stables from home split 8, 8, 7,
  7 over its four other roads; the same match repeats exactly; each side's
  pointers are its own; routes start at the drawn home or at a base.

It still runs on the bot module's base-to-base roads; the owner's
crossings (the table below) replace them once confirmed and recorded.

Before this, not built. The bot module's bots pick their next base by its own
priorities and walk its 15 road paths between the two home bases and the
five bases (`vPaths_AB`). None of them is the river.

## Intended Behavior

**The roads as a graph.** Each place a road meets others is a crossing:
the two home bases, the five bases, and any fork along a road. Each road
between two crossings is an edge, walked by its waypoints. The edges are
the bot module's 15 paths (home to Stables or Farm, Gold Mine and Lumber
Mill; Stables and Farm to the Blacksmith, Gold Mine, Lumber Mill and each
other; the Blacksmith to the Lumber Mill and the Gold Mine: the side roads
the owner named). The river path is not an edge.

**The alternating rule.** At each crossing, each side keeps one pointer
per crossing, naming the branch (toward the enemy home) the next squad
there takes. A squad arriving takes the branch the pointer names, and the
pointer turns to the next branch, so the next squad goes the other way:
"you reverse the path each time you cross it". With two branches the
squads alternate; with three, they take them in turn. Over a match the
squads spread evenly over every road from home to the enemy's home, by a
rule anyone can follow by hand, and the same match played twice sends the
same squads the same way. (This is the rotor-router walk, also called the
Propp machine: a deterministic stand-in for choosing a branch at random.)

**Any road but the one it came by** (owner, 2026-10-08: ""forward"
should mean "down the path" and stand-ins should simply route along any
of the routes that they did not immediately just come from, when they're
at an intersection."). At a crossing, a squad's choices are every road
there except the one it arrived on, taken in turn: one pointer per side,
per crossing, per road arrived by. A squad leaving a base it just
captured counts the road it arrived on there; one that appeared at a
base (176a2b) arrived by none, so every road there is a choice.

**The crossings, as the owner draws them** (2026-10-08): each base has
two exits, and each exit reaches a fork:

| From | Exit | Choices at the end of it |
|---|---|---|
| Stables | left | Gold Mine, Farm (along the cliff), Blacksmith |
| Stables | right | the Blacksmith-Farm crossing, Lumber Mill |
| Farm | left | Lumber Mill, Stables, Blacksmith |
| Farm | right | Gold Mine, the Blacksmith-Farm crossing |
| Gold Mine | left | Farm |
| Gold Mine | right | Blacksmith, Stables |
| Lumber Mill | left | Stables |
| Lumber Mill | right | Blacksmith, Farm |
| Blacksmith | one way | Gold Mine, Stables |
| Blacksmith | the other | Lumber Mill, Farm |

The owner: "I think that covers everything?" (open question 6.)

**Where the crossings come from.** The bot module's 15 paths run base to
base, hand-placed with roads side by side: merging their points where
they lie within 14 yards of each other finds about 20 forks and splits
the Stables into three spots (2026-10-08). So the crossings are the
owner's table, written once as data, and each road between two crossings
is walked and recorded in game by a game master (as the boarding
recorder does for ships, `.buddy record`, 617e9), not derived.

**Starting anywhere.** Squads now also appear at bases their side holds
(176a2b), so a route starts at any base or home, not only at home.

**Graveyards: none for stand-ins.** A dead stand-in goes into its side's
pool and comes back at home (176a2b), so every route starts at a home
base; graveyards are players' only and play no part in the rule.

**The river.** Not walkable on purpose. A stand-in that ends up in it
(knocked back, cycloned, feared) walks out to the nearest point of the
nearest road, and goes on from the crossing it reaches first. Back on
the road it joins the first group it meets (owner, 2026-10-08: "they
should form a dynamic group with the first group they meet. If that group
could split into two groups of 3, then it will."): the two merge, and if
the merged group is six and holds two trios' worth of roles (four damage,
two healers), it splits into two trios.

## Suggested Implementation Steps

1. Read the 15 paths into a graph: their end points matched to the seven
   places, forks found where paths share points, each edge's length.
2. The rule, as plain data and code with no bot in it: pointers per side
   per crossing, "next branch toward the enemy home", the pointer turned.
   Tested on paper: 20 squads from each home, where each one went.
3. (Dropped 2026-10-08: stand-ins don't use graveyards.)
4. The river: detect a stand-in off every road (farther than a few yards
   from any edge) and route it to the nearest road point.
5. Logs: each squad's crossings in order, for 176a2f.

## Open Questions

1. **The pointers: per side, per match.** Each side has its own set,
   reset at each new match. Or should a side's pointers carry over from
   one match to the next, so the spread continues?
2. **Captured bases on the way:** when a squad reaches a base its side
   already holds, does it pass through by the rule, or might it stop to
   guard (176a2b's question 3)?
3. **The goal:** "to reach the enemy base": once a squad stands at the
   enemy's home, what next? Turn round by the same rule toward their own
   home, fight there, or wait?
5. (Answered 2026-10-08) **What "forward" means:** any road but the one
   just come by.
6. **The crossings table above: complete and right?** Read as one map it
   has places to settle: (a) the Stables' left exit offers the Farm
   "along the cliff": is that the long road round the west (the bot
   module's Farm-to-Stables path, 595 yards), or a road by the Gold Mine?
   (b) the Farm's two exits: do both lead to the Blacksmith-Farm crossing
   (left by the Lumber Mill road, right by the Gold Mine road), or is one
   of them a different crossing? (c) is the Gold Mine's right fork
   (Blacksmith, Stables) the same crossing as the Blacksmith's "one way"
   fork (Gold Mine, Stables), and the Lumber Mill's right fork the same as
   the Blacksmith's "other way" (Lumber Mill, Farm)? (d) the two homes:
   which crossing does each home's road reach?
7. **Where a route ends:** with no "nearer the enemy" in the rule, a squad
   walks until something stops it: a base to capture or guard (176a2b),
   a fight, or the enemy's home. Is reaching the enemy's home an end, or
   do squads keep walking the rule?
4. **The river from the Blacksmith:** does it also count as "knocked off"
   when a stand-in falls off the Lumber Mill cliff, or is any way down
   from the cliff a fall to recover from?
