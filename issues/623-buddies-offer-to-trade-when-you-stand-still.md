# 623 - Buddies Offer to Trade When You Stand Still

## Status
- Created: 2026-10-15
- Phase: 6
- Related: 617j (giving within the clan: needs the same buddy-opened
  trade window, "nothing in the module does that yet"), 617h (the auction
  house: what a buddy keeps to sell), 622 (its weapon record: what it
  might offer)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-15:

> also we should be able to trade to buddy-bots? And they should be able
> to give things to us? If we stand still for too long, they can offer to
> trade with us... and when the offer is about to expire, another nearby
> buddy-bot prioritizes walking over and being ready to trade you as soon
> as the previous one expires... whichever one's not busy or in combat.

## Asked again, 2026-10-26

The owner: "If I want to give an item to a buddy-bot, they currently
won't accept a trade request. Can we make it so they do? But only if
they're in my clan." So the first piece of this issue, on its own: a
buddy accepts a trade opened by a player of its own clan (its owner and
the owner's clan mates), and refuses anyone else's, saying so.

## Current Behavior

**Clan trades, built 2026-10-26 (source patch B058, not yet compiled):**
a player in a bot's own guild may now open a trade with it, and the bot
accepts what it is given; anyone else is refused as before ("I'm kind of
busy now"). A buddy's clan is a guild (617l), so the owner and clan mates
can hand a buddy items even when it is out of their group (in town,
617c2). The change: the bot module's two trade refusals ("neither master
nor group member", "ungrouped without full security", in
`TradeStatusAction::Execute`) each gain "and not in the bot's guild".
Gated to the buddy profiles (basic, cc-test). Round trip and compile
checked; not yet seen in game (whether buddies' trimmed strategies still
react to a trade window is to be seen). The rest of this issue (buddies
offering trades, the helper walking over) is not built.

Before:

- **Player to buddy: works today, through the bot module.** Opening a
  trade window with a bot makes it show its inventory and take part in
  the trade (`docs/playerbots/Playerbot-Commands.md`, Reactions: "open
  trade window | show inventory and start trading"). Not yet tried with a
  buddy in this project.
- **Buddy to player: nothing.** No buddy ever opens a trade window; the
  buddy module has no code that starts a trade between two characters
  (617j's clan giving waits on the same thing).

## Intended Behavior

1. **The offer.** When the owner has stood still for a while (out of
   combat, not in a trade, not mounted or flying), one free buddy (not
   busy at an errand, not in combat) walks up and opens a trade window
   with the owner, its offer already placed: what it would give (see the
   questions).
2. **The window has a life.** The offer stays open for a fixed time; the
   owner may accept, change it, or ignore it. Ignored, it closes when the
   time is up.
3. **The queue.** As the offer nears its end, the next free buddy nearby
   walks over and waits beside the owner, so that the moment the first
   window closes the next one opens. Whichever buddy is free goes; one in
   combat or busy is passed over. It stops when no free buddy is left, or
   when the owner moves.
4. **The owner's side.** The owner can still open a trade with any buddy
   at any time, as today.

## Suggested Implementation Steps

1. Answer the open questions.
2. Try the player-to-buddy trade in game as it is; write down what the
   bot module does with what is put in the window.
3. The buddy-opened trade: the same request a client sends to start a
   trade (the server's initiate-trade handler, called on the buddy's
   session, as `buddies_town.cpp` already calls the auto-equip handler),
   then items placed in its slots the same way.
4. The stand-still timer and the offer's lifetime, as tuning beside the
   other buddy timings; the queue (the next free buddy chosen and walked
   over before the current offer ends) in the buddy module's pass over
   online buddies.
5. In game: stand still in Orgrimmar with three buddies; watch the turns.

## Open Questions

1. What does a buddy put in its offer: items that would be upgrades for
   the owner, things it doesn't need (trade goods, greens it saves for
   the auction house), gold, or an empty window the owner fills by
   asking?
2. How long is "standing still too long", and how long does an offer
   stay open before it expires?
3. Should a buddy say something as it opens the window (a line in /say,
   a whisper)?
4. When a player puts an item in a buddy's window: does the buddy always
   accept, or judge it (it would accept an upgrade, refuse junk)?
