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

Not built. The bot module's bots pick their next base by its own
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

**Only forward.** "Toward the enemy home": a branch counts only if it
gets nearer the enemy's home in road distance, so a squad never turns
back the way it came. A squad stopping to capture a base (176a2b) leaves
it by the same rule.

**Graveyards.** Each graveyard's way onto the roads is a crossing too,
with its own pointer: risen stand-ins leave "one way or the other", the
two ways in turn.

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
3. Graveyard exits as crossings.
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
4. **The river from the Blacksmith:** does it also count as "knocked off"
   when a stand-in falls off the Lumber Mill cliff, or is any way down
   from the cliff a fall to recover from?
