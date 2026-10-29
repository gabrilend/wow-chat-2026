# 921 - Alterac Valley's Shared Weather, and the Storm That Wanders It

## Status
- Created: 2026-10-29
- Phase: 9
- Sub-issues: 921a (the shared weather deck), 921b (the wandering storm)
- Related: 176a1 (a full Alterac Valley match, the test scene that will
  show it), 617i (buddies in battlegrounds), 617e16l (the battleground
  sandbox page)
- Switch: the buddy module's setting `Buddies.AlteracWeather` (0 off, the
  default; 1 on)
- Priority: Medium
- State: planned

## Origin

The owner, 2026-10-29:

> Can we make issue files for a feature where the Alterac Valleys on the
> server all share the same weather? And it oscillates in a pattern (is
> collages) that is non deterministic yet still equally distributed. A
> storm cloud should wander across the map and always be intensely
> downpowering

## Current Behavior

Not built. Each Alterac Valley match is its own copy of the map, and the
server gives it the weather of its zone as the stock rules have it, chosen
separately per copy. Two matches running at once may have different skies,
and nothing moves across the valley.

## Intended Behavior

- **One sky for every match.** Every Alterac Valley on the server shows the
  same weather at the same moment: one server-wide clock, and every match,
  and every player entering one, is given the weather of that moment.
- **It oscillates, unpredictably but evenly** (921a). The weather kinds are
  dealt like a shuffled deck, each kind exactly once per deck, the order
  drawn anew from an unpredictable seed each time the deck runs out. Within
  its turn each kind swells and fades. Nobody can predict the next sky, and
  over any few decks every kind has had the same time.
- **A storm that wanders** (921b). One storm cell, the same in every match,
  drifts across the valley, never leaving it. Anyone under it is in the
  heaviest rain the game shows, with thunder, always: the storm never
  weakens. Its edge fades into the shared sky.
- **Behind a switch**, off until the owner turns it on (the design target,
  CLAUDE.md).

## Suggested Implementation Steps

1. 921a: the deck and the clock, as plain arithmetic with an offline test
   (each kind's share over many decks, no kind twice running across a deck's
   seam, a fresh order each start), then the server side: every Alterac
   Valley copy and every arriving player given the current weather.
2. 921b: the storm's walk and its reach, the same way (an offline test of
   the walk staying in the valley and covering it evenly over time), then
   each player under it sent the storm's weather personally, the rest the
   shared sky.
3. The switch, and the GM command reference.
4. Tried in the full-match scene (176a1), or on a branch realm with two
   matches open at once.

## Open Questions

(The design calls below were made by the agent under the owner's "design
all of our stuff and we'll curate it as we go"; they are for the owner to
curate.)
1. How long a turn of the deck lasts: 6 minutes was chosen, so a deck of 7
   kinds runs 42 minutes, about one long match.
2. Should the storm do anything besides look and sound like one (slow
   riders, hide players from far sight), or only be weather?
