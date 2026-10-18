# 628 - Buddies Wander as Baked NPCs

## Status
- Created: 2026-10-17
- Phase: 6
- Parent of: 628a, 628b, 628c, 628d
- Blocked by: 617r4 (gearsets on creatures: a creature dressed as a player
  from a record), 617f (B047's creature outfits: the mirror-image answer)
- Related: 617 (buddy bots), 617e (buddy roaming: what "wandering" is),
  623 (buddy-opened trade window), 617y (spoken orders), 617p (NPC
  awareness), 184 (play as any creature model), 160 (client cache follows
  content: creature names are cached by the client)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-17:

> can we make issue files to make it so that buddy-bots have an NPC
> profile baked for them from their sql stats and use that instead of
> their playermodel when wandering around? And if you right click on one,
> you can talk to them. Left click selects to heal or buff or whatever.
> It'll stop and stand still, and you can do things to it like say "hey
> take this thing I found" or "can you trade to me any healing potions"
> and it'll use the actual trade window to make it seem like a player.
> The player is actually there, and if they're in combat they'll stop
> talking to you. So it's definitely a "do while nothings doing" type of
> thing.

Earlier the same day, the owner's general form of the idea (from a list
of things the project could generate):

> all characters should be able to be randomized. We can do this by
> making NPCs into players behind the scenes, and "baking" their presets
> into NPCs that can be spawned quickly. That way, it's relatively easy
> to process them all, and also we can easily change them by simply
> spawning a player type character with the newly modified gear and such,
> and then baking them in the background if we expect to have them
> long-term. Otherwise, accept the performance hit on that player
> character.

## Current Behavior

Not built. A buddy is always a player character played by the bot
module, logged in on the companion account (617a2), drawn by every client
as a player of its race in its own gear. Right-clicking a buddy does what
right-clicking any player does (nothing but select it, and the player
menu on its portrait). Trading with a buddy works when the player opens
the window (623, through the bot module); a buddy never opens one.

Pieces that exist or are written:
- **Dressing a creature as a player**: source patch B047 and
  `modules/mod-buddies/src/buddies_outfits.cpp` answer the client's
  mirror-image question for listed creatures (race, skin, face, hair,
  beard, item pictures). Used today only for the three Sargobras (617f).
  Written and round-trip tested, not yet run in game.
- **From a gear record**: 617r4 plans the same dressing from a gearset
  record. Not built.

## Intended Behavior

A buddy has two bodies, and wears the cheaper one when nothing is
happening.

- **The baked body.** Each buddy has a creature of its own: its name, its
  level, its race, sex, skin, face, hair and beard, and the pictures of
  what it wears, all read from the characters database. Made by a tool
  and remade when the buddy's look or gear changes (628a).
- **Wandering in it.** While a buddy roams with nothing on (no fight, no
  group with a player, no errand that needs a player body), the baked
  creature walks in its place, and the buddy's player body is hidden.
  Combat, a group, a battleground, a dungeon or a trade brings the
  player body back (628b).
- **Right-click to talk.** Right-clicking the baked creature opens a
  conversation: it stops, faces the player and stands still. The choices
  are things said to a person: "take this thing I found", "can you trade
  me any healing potions". The ones that move items open the real trade
  window between the player and the buddy, so it reads as trading with a
  player, because it is one (628c).
- **Left-click to select.** Left-clicking selects it like any friendly
  target, to heal it, buff it, or whatever else is cast on a friend; what
  lands on the baked body reaches the buddy (628d).
- **Only while nothing is happening.** "The player is actually there":
  if the buddy enters combat, the conversation closes, the trade window
  closes, and the buddy fights as itself.

### Sub-issues

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 628a | the-bake | None | A tool reads a buddy's look and gear from the characters database and writes its creature and its outfit entry |
| 628b | the-swap | 628a | The baked creature walks in the buddy's place while it wanders; the player body comes back when something happens |
| 628c | right-click-to-talk | 628b, 623 | A conversation menu on the baked creature; its item choices open the real trade window from the buddy's side |
| 628d | left-click-to-select | 628b | Spells cast on the baked creature reach the buddy |

Order: 628a (foundation) → 628b (needs 628a) → 628c and 628d (parallel,
both need 628b; 628c also needs 623's buddy-opened trade).

## Suggested Implementation Steps

1. Answer the open questions (the two readings of "the player is
   actually there" decide most of 628b and 628d).
2. 628a: the bake tool and its output, checked on one buddy in game by
   spawning its creature beside it.
3. 628b: the swap on one buddy, roaming in a quiet zone.
4. 628c and 628d.
5. Measure: the server's update time with 50 roaming buddies in their
   player bodies and in their baked bodies (the reason for the bake).

## Related Issues

- **617r4**, **617f** (blocked by); **623**, **617e**, **617y**, **617p**,
  **184**, **160**

## Open Questions

1. **Where is the player while the creature wanders?** Two readings, and
   they cost very differently:
   - **(a) Hidden beside it.** The buddy stays logged in, invisible and
     unselectable, and moves with the creature. Talking, trading and
     casting go straight to it. Saves only the drawing (one creature
     sent to clients instead of a player with 19 equipment slots); the
     bot's thinking and the server's player update still run.
   - **(b) Logged out.** The creature alone wanders; right-clicking it
     logs the buddy in at the creature's spot (a second or two), and the
     buddy logs out again when the conversation ends. Saves the bot's
     thinking and the player update too, which is where the server's
     time goes; costs a wait before every conversation and every heal.
   "The player is actually there" reads like (a). Is it?
   (Answered 2026-10-18) Neither quite: the owner, "logged in to receive
   chat messages, but we don't have to render or update anything else
   about them so they're essentially static." The buddy stays logged in
   so whispers and party chat reach it, but while baked it is held still:
   not drawn to anyone, its bot's thinking and the server's per-tick
   update of it paused, so it costs almost nothing beyond the open
   session. The creature does the wandering; the buddy wakes (player
   body back, thinking on) only for 628b's reasons.
2. **Who walks?** In (a), does the creature follow the hidden player's
   steps (the buddy's roaming unchanged, the creature a puppet), or does
   the creature walk by creature pathing and the hidden player follow
   it?
3. **Name and title.** The client takes a creature's name from its
   creature record, not from the mirror-image answer, so each buddy needs
   a creature record of its own (an entry per buddy). Should the title
   under the name say whose buddy it is ("<Gabrilend's companion>")?
4. **What else can it be asked?** The two examples move items. Should the
   menu also carry the spoken orders (617y: "follow me", "go sell") and
   free text for the language-model buddies (617m)?
5. **Other players.** Can anyone right-click and talk to someone else's
   buddy, or only its owner? Trading with another player's buddy would
   give items away from that owner.
