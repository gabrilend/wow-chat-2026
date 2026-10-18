# 628c - Right-Click to Talk: a Conversation and the Real Trade Window

## Status
- Created: 2026-10-17
- Phase: 6
- Parent: 628 (buddies wander as baked NPCs)
- Blocked by: 628b (the swap), 623 (a buddy opening the trade window)
- Related: 617y (spoken orders), 617m (language-model buddies), 617h2
  (every item a buddy carries: what it has to give)
- Priority: Medium

## Origin

See 628 (the owner's words, 2026-10-17, quoted in full there):
"if you right click on one, you can talk to them [...] It'll stop and
stand still, and you can do things to it like say "hey take this thing I
found" or "can you trade to me any healing potions" and it'll use the
actual trade window to make it seem like a player. The player is
actually there, and if they're in combat they'll stop talking to you."

## Current Behavior

Not built. A buddy has no conversation menu; 623 plans the buddy-opened
trade window, not built.

## Intended Behavior

- **Right-click** the baked creature: it stops, turns to face the
  player and stands still, and a conversation menu opens (the stock
  gossip window, from the creature's gossip flag, 628a).
- **The choices** are said as one person to another:
  - **"Hey, take this thing I found."** The buddy opens a trade window
    with the player, empty on its side; the player puts the thing in.
  - **"Can you trade me any healing potions?"** The buddy opens a trade
    window with its healing potions already placed (all it carries, or
    up to a share, see the questions); the player accepts or changes it.
  - More, by the same pattern: a kind of item asked for, the buddy's side
    filled with what it has of that kind.
- **The real trade window.** The window opens between the player and the
  buddy itself, by the same request a client sends to start a trade, made
  on the buddy's side (623's mechanism). The server's start-of-trade
  check asks only for distance (within the trade distance, about 11
  yards), not for sight, so a hidden buddy standing at its creature's
  spot can trade.
- **Combat ends it.** If the buddy (or the player) enters combat, the
  conversation closes, an open trade window is cancelled with nothing
  exchanged, and the buddy fights.
- **Walking away ends it.** The player moving out of range closes it the
  same way. When it ends, the creature walks on.

## Suggested Implementation Steps

1. The gossip menu on buddy creatures (one script for the whole buddy
   range of entries), with the stop and face.
2. Each choice calls 623's buddy-opened trade with the items to place
   (none, or the kind asked for).
3. Combat and distance close the menu and cancel the trade.
4. Check in game what the trade window shows for the buddy's name while
   its player body is hidden (the client names the other side from what
   it knows of that player; a hidden one may show as "Unknown").

## Open Questions

1. "Any healing potions": all of them, or does it keep some for itself?
2. Should the buddy say a line as it opens the window (as 623's question
   3 asks)?
3. If the trade window can't show a hidden player's name, does the
   player body appear for the length of the trade (628b's swap back)?
