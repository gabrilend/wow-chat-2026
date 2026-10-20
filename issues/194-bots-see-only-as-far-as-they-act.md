# 194 - Bots See Only as Far as They Act; Players See wow-chat-1's 333 Yards

## Status
- Created: 2026-10-20
- Phase: 2 (The Empty World)
- Related: `docs/wow-chat-1-settings.md` (the held sight distance), C037
  (beta's other wow-chat-1 settings)
- Priority: Medium
- State: built 2026-10-20, tested offline; waits on the owner's compile and
  a look in game (step 4), then completed

## Origin

wow-chat-1 let everyone see 333 yards on the continents
(`Visibility.Distance.Continents`, stock 90 then, 100 today). It was held
for beta because the server tracks that distance for every player, and to
it beta's 200 bots are players too. The owner, 2026-10-20:

> I think that's worth it. Bots should only be able to see as far as the
> largest range they can see.

## Current Behavior

Built, not yet compiled. `patches/B056-bots-see-only-as-far-as-they-act.sh`
(on beta's list) changes the last line of `Player::GetSightRange`: for a
bot's player (headless session) on a map that is not instanced, the reach
is at most the bot module's largest sight-like distance, the largest of
`AiPlayerbot.SightDistance`, `ReactDistance`, `GrindDistance`,
`RpgDistance`, `SpellDistance`, `HealDistance`, `FishingDistance`,
`LootDistance`, `AggroDistance` and `FarDistance`, each read once from the
server's settings with the bot module's own default (200 yards with stock
settings: `RpgDistance`). Everyone else, and bots in dungeons, raids,
battlegrounds and arenas, as before. C037 gives beta's continents 333.
Checked: the line compiled and run in a stand-in (a continent bot capped,
a battleground bot and a player not, a bot between maps not);
`scripts/test-source-patches <project> beta` applies and reverts every
beta source patch to a byte-identical tree; the settings test checks the
333 and the stock instance and battleground distances (170, 250).

Answered 2026-10-20: the cap from "bot module's settings"; "BGs and
instances should have their stock distances I think?" (so the cap is
continents-only too: a battleground's stock 250 is above the bots' 200).

Before this, every player, bot or not, saw as far as the map's visibility distance
(100 yards on the continents, stock): `Player::GetSightRange` (in
`src/server/game/Entities/Player/Player.cpp`) returns the map's range plus
any far-sight bonus, and the server uses it to decide which creatures and
players to tell each player about (`Cell::VisitObjects` in `Unit.cpp` and
`PlayerUpdates.cpp`). A client draws only what it is told, so sight is the
server's to set.

## Intended Behavior

- On beta, real players see 333 yards on the continents, as in wow-chat-1.
- Bots see only as far as the bot module ever looks or acts: its largest
  sight-like distance setting. In `playerbots.conf` those are
  `RpgDistance` 200, `ReactDistance` 150, `SightDistance` 100,
  `GrindDistance` 75 and smaller ones, so 200 yards today (chat, teleport
  and task distances are not sight and don't count). Nothing a bot does
  reaches farther, so it loses nothing; the server stops tracking the
  200-to-333-yard ring for every bot.
- A real player still sees bots out to 333 (the viewer's range decides).

## Suggested Implementation Steps

1. A source patch, B056 (B055 was retired unbuilt), in `Player::GetSightRange`:
   for a bot's player (its session is headless, `GetSession()->IsHeadless()`,
   the core's own test that the Lua engine's `IsBot` uses), return at most
   the cap; everyone else, as before. The cap from a new setting (question 1),
   read once at start; 0 or absent means no cap, so profiles without the
   setting are unchanged.
2. A settings patch for beta: `Visibility.Distance.Continents` 333 (C037's
   list) and the cap.
3. Tests: the patch applies and reverts cleanly (`scripts/verify-patches`);
   the settings test checks beta's two values.
4. In game on beta: a player sees a creature at 300 yards; a bot standing
   there behaves as before.

## Open Questions

1. **Where the cap comes from.** **Answered** 2026-10-20: "bot module's
   settings" (read from them, the largest sight-like one).
2. **Other maps.** **Answered** 2026-10-20: stock distances in
   battlegrounds and instances, for players and bots both.
