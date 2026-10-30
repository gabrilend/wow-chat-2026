# 921a - The Shared Weather Deck

## Status
- Created: 2026-10-29
- Phase: 9
- Parent: 921 (Alterac Valley's shared weather)
- Switch: `Buddies.AlteracWeather` (the parent's)
- State: planned

## Origin

The owner, 2026-10-29 (whole request in 921): "it oscillates in a pattern
(is collages) that is non deterministic yet still equally distributed."

## Current Behavior

Not built. Each Alterac Valley copy gets its zone's stock weather,
separately.

## Intended Behavior

- **The deck.** The weather kinds fitting a snowy mountain valley: fine,
  fog, light snow, snow, heavy snow, light slush, slush (7). They are
  dealt as a shuffled deck: each kind once, in a random order, then the
  deck is shuffled again.
  - **Slush** (the owner, 2026-10-29: "the rain freezes to slush"): the
    valley's rain freezes as it falls. The game has no sleet (its kinds
    are fine, fog, rain, snow and sandstorm at three strengths, thunder,
    and black rain and snow), so a slush turn is drawn from rain and
    snow: it opens as rain, trades back and forth between rain and snow
    through its middle (every 20 to 40 seconds, the client fading each
    change), and closes as snow, the rain freezing as the turn goes on.
    Light slush uses the light kinds, slush the medium ones.
  - **Unpredictable:** the shuffle draws from a seed taken fresh at server
    start (the system's own source of randomness, not the time), so no two
    runs deal alike and nobody can foresee the next.
  - **Even:** each kind gets exactly one turn a deck, so over any whole
    number of decks every kind has had the same time. This is the
    "equally distributed".
  - **No stutter:** a new deck never opens with the kind the last one
    closed on (that kind is moved to a random later place), so the same
    sky never runs two turns together.
- **The oscillation.** Each turn lasts TURN minutes (6). Its strength
  rises from nothing to full and back along a smooth curve (half a sine),
  so the sky swells and fades rather than snapping between kinds.
- **One clock, server-wide.** The deck and the turn's clock are one for
  the whole server. Every Alterac Valley copy is given the current kind
  and strength when it opens, again whenever they change (at most every
  few seconds), and every player arriving in one is given it on arrival.
- **Its numbers in one place**: the kinds, TURN, and how often the
  strength is re-sent.

## Suggested Implementation Steps

1. The deck as plain arithmetic in the buddy module's pure core (a header
   with no server code): a shuffle with the no-stutter rule, the turn's
   strength curve, and "the kind and strength at time t".
2. Its offline test:
   - over 10,000 decks, each kind's share of time is 1/7 within a hair;
   - no kind twice running, across any deck's seam;
   - two seeds deal two different orders;
   - the strength starts and ends each turn at nothing and peaks in the
     middle.
3. The server side: the server's own weather for the Alterac Valley zone
   set from the deck in every copy of the map, and sent to each arriving
   player (first, read how this server keeps weather per copy and how it
   sends it to a player, and write down what was found).
4. The switch (`Buddies.AlteracWeather`), and `.buddy weather` for game
   masters: the current kind, strength, and the rest of the deck.

## Open Questions

1. The kinds: snow is native to the valley; is rain right there at all,
   or should the deck be snows and fog only (with the storm the one rain)?
   **Answered 2026-10-29:** "the rain sneezes to slush. sorry it freezes
   to sluyuch." The deck's rain becomes slush (above). The wandering
   storm stays a downpour, as asked when it was first described; whether
   it should freeze too is still open.
