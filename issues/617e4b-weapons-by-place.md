# 617e4b - Weapons by Place: Bare in Town, Sheathed in the Wilds, Drawn in Danger

## Status
- Created: 2026-10-15
- Phase: 6
- Parent: 617e4 (town visits)
- Related: 617a4 (the starting kit: the weapons), 617k (the fishing pole),
  622 (the buddy's weapon record)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-15, on a buddy holding its fishing pole in a fight:

> when in town, they shouldn't carry any weapons at all. While in the
> wilds, they should bear their sword on their hip or back. When in
> danger, they should bear it in hand. in town or at peace, they
> shouldn't bear the fishing pole - only when they are fishing, or when
> it's on their todo list and they would otherwise bear nothing.

## Current Behavior

- A buddy wears its weapons everywhere; whether they are drawn or
  sheathed is left to the bot module and the game's defaults.
- The fishing pole goes into its hand for a town fishing visit and back
  to its bags when the visit ends in town (617e4). Since 2026-10-15
  (`buddies_town.cpp`, "the pole in a fight"), a pole still in hand at
  login or when a fight starts is swapped for the best weapon in its
  bags, so the pole never fights.

## Intended Behavior

Three places, three ways of carrying:

| Where | Weapons | The fishing pole |
|---|---|---|
| In a town (the town areas of 617e4, its buildings too) | none worn: main hand, off hand and ranged go into the bags | in hand only while fishing, or walking to fish, since its hands are otherwise empty |
| In the wilds, at peace | worn and sheathed (on the hip or back) | in the bags |
| In danger (in combat, or a hostile closing in) | worn and drawn | in the bags |

Entering a town takes the weapons off; leaving it puts them back on
(sheathed). A fight in town (a raid on a capital, a duel) puts them on and
draws them at once.

## Suggested Implementation Steps

1. Answer the open questions.
2. A per-buddy note of what it wore in each hand slot (item guids),
   stored in the characters database rather than memory (memory is what
   lost Mozonn's hammer), written as the weapons come off.
3. Entering town (the town step's first turn in a town): each weapon
   moved to the bags through the client's own swap-to-bags request, so
   every server rule applies; full bags leave that weapon worn and say
   so.
4. Leaving town, or a fight starting anywhere: the noted weapons put
   back, then drawn (in a fight) or sheathed (at peace), by the sheath
   state the server sends for a player.
5. The pole: in hand when a fishing visit begins in town (its hands are
   empty there), back in the bags when it ends; the login and
   fight-start check of 2026-10-15 stays as the safety net.
6. In game: walk a buddy into Orgrimmar and out to the Barrens; start a
   fight at the gate.

## Open Questions

1. "In danger": only once a fight begins, or already when a hostile
   creature comes within some distance (and how far)?
2. Ranged weapons and wands: also taken off in town, or only the hands?
3. Should the owner's own weapons follow the same rule (a Lua script for
   players), or only buddies?
