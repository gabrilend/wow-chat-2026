# 194 - Players See as Far as the Server Allows; Bots Only as Far as They Act

## Status
- Created: 2026-10-20
- Phase: 2 (The Empty World)
- Related: `docs/wow-chat-1-settings.md` (the held sight distance), C037
  (beta's wow-chat-1 settings), C039 (instances and battlegrounds)
- Priority: Medium
- State: completed 2026-10-23: built; its in-game check taken as done (the owner, 2026-10-23: "let's mark all the issues that are just waiting on a visual check as complete")
  a look in game (step 4), then completed

## Origin

wow-chat-1 let everyone see 333 yards on the continents
(`Visibility.Distance.Continents`, stock 100 today). It was held for beta
because the server tracks that distance for every player, and to it bots
are players too. The owner, 2026-10-20:

> I think that's worth it. Bots should only be able to see as far as the
> largest range they can see.

The cap read from "bot module's settings". Then, the same day:

> how about for battlegrounds and instances we just have 100% view
> distance for all players and bots, always? That way we can see distant
> stuff happening. Makes it more immersive I think. Though, buddy-bots
> probably can't use vast distances, and stand-ins definitely. So how
> about the largest size for them in dungeons and BGs and instances and
> such?

## Current Behavior

Built, not yet compiled, on every profile built from source-beta (basic,
vanilla, release, beta, cc-test; alpha's older server has other code):

- `patches/B056-bots-see-only-as-far-as-they-act.sh` changes the last line
  of `Player::GetSightRange` (`src/server/game/Entities/Player/Player.cpp`):
  for a bot (its session is headless: random bots, buddies, stand-ins),
  on every map, the reach is at most the bot module's largest sight-like
  distance, the largest of `AiPlayerbot.SightDistance`, `ReactDistance`,
  `GrindDistance`, `RpgDistance`, `SpellDistance`, `HealDistance`,
  `FishingDistance`, `LootDistance`, `AggroDistance` and `FarDistance`,
  each read once from the server's settings with the bot module's own
  default (200 yards with stock settings: `RpgDistance`). Players as
  before.
- `config/patches/C039-instances-and-battlegrounds-see-all.sh`: instances
  and battlegrounds 250 yards (stock 170 and 250) for every one of those
  profiles.
- C037: beta's continents 250.

**250 is the most there is.** The server caps every view distance at 250
yards (`MAX_VISIBILITY_DISTANCE` in `ObjectDefines.h`): a larger setting is
clamped to 250 with an error at every start (`World.cpp`). So wow-chat-1's
333 was 250 in effect, and beta writes 250. Seeing farther would mean
raising that constant, a source patch of its own and a larger area loaded
around every player.

Checked: the line compiled and run in a stand-in (bots capped at 200 on a
continent, in a battleground and between maps; a player not);
`scripts/test-source-patches` applies and reverts each of the five
profiles' source patches to a byte-identical tree; the settings test
checks the distances for basic (instances 250, continents stock 100),
beta (all 250) and cc-test (instances 250). Vanilla and release have no
expected-values table in that test (a gap older than this).

Before this, every player, bot or not, saw as far as the map's distance:
100 yards on the continents, 170 in instances, 250 in battlegrounds.

## Intended Behavior

- Players see as far as the server allows: 250 yards in instances and
  battlegrounds on every profile, and on beta's continents too.
- Bots, buddies and stand-ins see only as far as the bot module ever looks
  or acts, read from its own settings so the two never drift apart: 200
  yards today. Nothing a bot does reaches farther, so it loses nothing,
  and the server stops tracking the outer ring for every bot.
- A player still sees a bot out to the player's own distance: the viewer's
  reach decides.

## Suggested Implementation Steps

1. B056 in `Player::GetSightRange`, on every source-beta profile's list.
2. C039 for instances and battlegrounds; beta's continents in C037.
3. Tests: the source-patch round trip per profile; the settings test's
   distances.
4. In game: a player sees a creature 240 yards off in a dungeon; bots and
   buddies behave as before.

## Open Questions

None. (Answered 2026-10-20: the cap from the bot module's settings; full
distance in instances and battlegrounds for players, bots at their own
largest.)
