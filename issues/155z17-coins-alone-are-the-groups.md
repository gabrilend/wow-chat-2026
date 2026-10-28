# 155z17 - Coins Alone Are the Group's

## Status
- Created: 2026-10-27
- Phase: 1
- Parent: 155 (the basic profile)
- Related: patch B062 (`patches/B062-coins-alone-are-the-groups.sh`), 617j1
  (loot turns: who opens which corpse)
- Priority: Low
- State: built 2026-10-27 (compile-checked on patched copies), not yet in a build

## Origin

The owner, 2026-10-27:

> can we make a server patch to make it so that if it's just coins on a
> body, anybody can loot it?

## Current Behavior

Built as patch B062 (basic), compile-checked on patched copies, not yet in a
running server. A body whose loot is coins and nothing else (its items
taken, or none ever) may be looted by any member of the group it fell to,
whatever the group's loot rule or whose turn it is: `Player::isAllowedToLoot`
allows it once the player is known to be in that group (which also makes it
sparkle for them, `Unit.cpp`'s lootable mark), and `Player::SendLoot` gives
such a member full permission. The coins are shared among the group as ever.
Nobody outside the group may take them (the owner, 2026-10-27, of a
passer-by: "no it's just for the group"), and a lone killer's body stays its
own. Area looting (mod-aoe-loot, "make sure it works correctly with AoE
loot") sweeps nearby bodies that `isAllowedToLoot` allows into the one
clicked, and opens that with `SendLoot`, so it follows the same rule: a
member sweeps the group's coin-only bodies, a passer-by none.

## Intended Behavior

- Coins alone on a group's body: any member of that group may loot them;
  nobody else.
- Anything else on it: as before.
- Area looting: the same.

## Suggested Implementation Steps

1. The two insertions of B062 (marker comments; a clean unpatch).
2. Seen in game: a group on round robin; a body whose items are taken, its
   coins looted by a member whose turn it isn't; area looting sweeping
   several such bodies; a player outside the group not able to.

## Open Questions

1. (Answered 2026-10-27: "no it's just for the group") Coins stay the group's.
