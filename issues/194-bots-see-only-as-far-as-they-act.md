# 194 - Bots See Only as Far as They Act; Players See wow-chat-1's 333 Yards

## Status
- Created: 2026-10-20
- Phase: 2 (The Empty World)
- Related: `docs/wow-chat-1-settings.md` (the held sight distance), C037
  (beta's other wow-chat-1 settings)
- Priority: Medium
- State: planned; open questions first. A source patch: the owner compiles.

## Origin

wow-chat-1 let everyone see 333 yards on the continents
(`Visibility.Distance.Continents`, stock 90 then, 100 today). It was held
for beta because the server tracks that distance for every player, and to
it beta's 200 bots are players too. The owner, 2026-10-20:

> I think that's worth it. Bots should only be able to see as far as the
> largest range they can see.

## Current Behavior

Every player, bot or not, sees as far as the map's visibility distance
(100 yards on the continents, stock): `Player::GetSightRange` (in
`src/server/game/Entities/Player/Player.cpp`) returns the map's range plus
any far-sight bonus, and the server uses it to decide which creatures and
players to tell each player about (`Cell::VisitObjects` in `Unit.cpp` and
`PlayerUpdates.cpp`). A client draws only what it is told, so sight is the
server's to set.

## Intended Behavior

- On beta, real players see 333 yards on the continents, as in wow-chat-1.
- Bots see only as far as the bot module ever acts: its largest distance
  setting. In `playerbots.conf` those are `ReactDistance` 150,
  `SightDistance` 100, `GrindDistance` 75 and smaller ones, so 150 yards
  today. Nothing a bot does reaches farther, so it loses nothing; the
  server stops tracking the 150-to-333-yard ring for every bot.
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
   there does not react to things beyond 150.

## Open Questions

1. **Where the cap comes from.** (a) Read from the bot module's own
   settings at start, the largest of its distance settings, so the two can
   never drift apart; or (b) a setting of its own (say
   `Visibility.Distance.BotCap = 150`), set beside the 333 by beta's
   settings patch. (a) is what "the largest range they can see" says
   exactly; (b) is simpler to read and to change by hand.
2. **Other maps.** Instances and battlegrounds have their own visibility
   distances (`Visibility.Distance.Instances`, `.BGArenas`). Should the 333
   and the cap apply there too, or only on the continents?
