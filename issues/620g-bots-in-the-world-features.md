# 620g - Bots in the World Features

## Status
- Created: 2026-10-14
- Phase: 6
- Parent: 620
- Blocked by: 620a, 620f
- Blocks: 620h
- Related: 155j (weekly world boss), 155u (battleground rewards), 155v
  (Aldor and Scryer by deeds), 155p (sockets), 155l (Outland without
  quests), 155z (the Dark Portal front), 155t (capital glyph traders), 167
  (spirit heals by stamina), 178 (experience counted in kills), 179
  (hearthstone network), 182 (legendary items), 169 (duels), 617h (buddy
  auction house)
- Priority: Low (bots get by without most of these; they just play less
  of the game)

## Origin

The owner, 2026-10-14: playerbots should work with "all the other
features we've added". 620f keeps bots from getting what basic withholds;
this is the other half, what basic adds that bots should be able to use.

## Current Behavior

Each feature below was built for humans (and in some cases buddies); how
an alt bot or random bot meets it is unknown until tried:

| Feature | What a bot does today, by reading the code |
|---|---|
| sockets and gems (155p) | buddies choose gems (617j2, 617r6); other bots leave sockets empty |
| spirit heals by stamina (167) | buddies weigh spirit by it (B050); other bots weigh spirit by the module's stock weights |
| Outland without quests (155l) | random bots look for quests where there are none |
| weekly world boss Kazzak (155j) | nothing draws bots to it |
| battleground rewards (155u), Aldor and Scryer by deeds (155v) | by whatever the bot module already does in battlegrounds and with reputation |
| the auction house (617h) | buddies list trade goods by remembered prices; random bots use the module's own auction logic, competing with buddies' prices |
| the Dark Portal front (155z) | not built |
| hearthstone network (179), legendaries (182), duels (169) | not reviewed |

## Intended Behavior

A bot playing basic takes part in each feature the way a careful player
would, using the buddy behaviour already built wherever there is one:

- The buddy-only behaviours that are really "how to play basic" (gem
  choice, spirit's worth, quiet inventory, never teleporting to the owner)
  are given to alt bots and random bots too, through 620a's kind, rather
  than written twice.
- Random bots in Outland hunt instead of questing.
- Each other feature gets a row in this file's table saying what a bot
  does, decided with the owner; features with no sensible bot behaviour
  are written down as left out, with the reason.

## Suggested Implementation Steps

1. List the B-patches gated to buddies only (B046, B048, B050, B052) and
   decide, per patch, whether alt bots and random bots take it too.
2. For each table row, read the feature's issue and write the intended
   bot behaviour into the row; ask the owner where it is not clear.
3. Build the rows in order of how often a bot meets them: sockets and
   spirit first, Outland next, the rest after.
4. Test each in game or in a cc-test scene, as 620h gathers.

## Open Questions

- Should every "buddy" behaviour that is simply good play (gems, spirit,
  loot judgement) become every bot's behaviour on basic, or stay a buddy
  trait that makes buddies better than other bots?
