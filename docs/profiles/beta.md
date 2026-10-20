# Beta Profile

**One-line summary:** the wow-chat survival game — an empty world that
fills in around each player with ambushes, treasure and wandering
travellers — on the game's own content, levels 1–20. A realm of its own
beside the other profiles.

*Rewritten 2026-10-17 after an audit. The older page called beta "every
B-patch, where features start". New features have been landing in basic
since the summer, and beta runs 11 of the source patches. The plan for
bringing the rest of its game back: [beta-roadmap.md](beta-roadmap.md).*

## What you get today

- **The ambush.** Monsters are sent at every player and every bot, from
  120–160 yards, on a clock that starts at 40 seconds and drifts 2–4
  seconds each time (10-second floor, pulled back down above 100 and 200
  seconds). None comes while you sit, lie dead or swim, while three are
  already chasing you, or during a rare's fight. After more than ten
  minutes offline you get 30 seconds' grace on login.
- **An empty world.** Install step E012 clears every creature spawn except
  critters and spirit healers.
- **Death knights from level 1,** leaving Ebon Hold at once (their
  starting quests are completed on first login; three exits teleport
  them out).
- **A group hearthstone by invitation** (issue 211, 2026-10-17): when
  someone in a group starts a hearthstone or Astral Recall, the others are
  asked in a window whether to come along, naming the zone they are
  hearthing to (bots always come); those who say yes
  travel when the cast finishes and stand in a circle round where the
  hearther lands. A cancelled hearth moves nobody.
- **Druids hearth by Moonglade** (issue 211a, 2026-10-18): every druid
  knows Teleport: Moonglade from level 1 (they meet no innkeepers, so this
  is their way home). Cast in the world, it lands them on a random spot of
  the glade's open ground and remembers where they were (from a dungeon,
  battleground or arena: where they entered it); cast in the glade, it
  sends them back there. The spot is kept in the characters database. The
  group is invited along as visitors, the dead too ("<druid> is going to
  Moonglade. Visit with them?"), placed round the druid and raised if dead,
  and sent back to where each came from as soon as the druid leaves the
  glade (raised first if they died there, unless they came dead). A
  battleground's or arena's join spot is the one the game saves with the
  character (`character_entry_point`), read after a save asked for at the
  cast.
- **Travellers** (branch beta-homework, 2026-10-17): a minute after
  login and then every 130 seconds, a vendor, innkeeper or class trainer
  of your level appears 30-45 yards away and walks past; it sits when you
  sit and leaves when nobody is near. Not while you're dead, swimming or
  sitting. Each class trainer teaches only up to the top of its slice of
  levels 1-20 (E014).

Switched off for now (the roadmap brings them back in order): treasure
(a design question first), ability tomes, death durability, custom
classes, bot behaviors.

## Settings

Checked by `scripts/test-profile-config-gates <project> beta`, which runs
the real settings patches on scratch copies and reads every value back.

| Setting                         | Value      | From  | Why |
|---------------------------------|------------|-------|-----|
| Level cap                       | 20         | C006b | the wow-chat design |
| Starting level                  | 1          | C007b | |
| Death knight starting level     | 1          | C017  | issue 206 |
| Death knights need a level-55 character first | no (0) | C036 | issue 206: an option, not an exception |
| Experience from kills           | 3×         | C037  | no quests on beta (E012); until 2026-10-20 2× from C005 |
| Faster healing below level 15   | off        | C034  | every profile: "It feels cheap!" |
| wow-chat-1's survival settings  | the list in C037 | C037 | wear and 25× repairs, loot sells for more, corpses lie 10 hours, dungeons at any level, both factions together, battleground timings; the list and the held ones: `docs/wow-chat-1-settings.md` |
| Quest sparkles, object marks, map points | off | C038 | also on basic, vanilla and release |
| Fall damage                     | 10×        | C004  | |
| Run speed                       | 0.85       | C003  | |
| Instant flight paths            | on         | C009  | |
| Login as game master            | yes (3)    | C008  | development realm |
| Random bots                     | 200, levels 1–20 | C035, C012 | every one is ambushed too |
| Realm id                        | 2          | C019  | |
| Ports                           | world 4462, auth 4362 | C010 | shared with other profiles until 136b |

## Installed modules

`scripts/install` and `scripts/compile`, `PROFILE_MODULES["beta"]`:

- **mod-ale** — Lua engine, runs `src/lua-beta/`
- **mod-playerbots** — AI players
- **mod-aoe-loot** — area loot
- **mod-grownup** — character size grows with level (cloned on install;
  not in the shared source folder until then)

<!-- patch-lists: begin. Written by scripts/generate-patch-lists from the patches' headers (issue 189f): edit a header, then run it; do not edit by hand. -->
## Patches

Every patch this profile takes, in the order the build runs them:
lowest priority first, each line its header's own (`scripts/plan-patches beta`).

**Before the compile (source patches, taken off again once it is through):**

| priority | id   | kind   | about                                                                                       |
| -------: | ---- | ------ | ------------------------------------------------------------------------------------------- |
|      120 | B002 | source | Add ALE OnLogin hook to playerbots bot login                                                |
|      130 | B003 | source | Enable entry 0 as wildcard for RegisterGameObjectEvent                                      |
|      140 | B004 | source | Fix ~695 compiler warnings in upstream modules                                              |
|      150 | B005 | source | Cap level difference impact on hit/miss at ±3 levels                                        |
|      160 | B006 | source | Add PLAYER_EVENT_ON_SELL_ITEM to ALE                                                        |
|      170 | B007 | source | Add SetWalk, IsWalking, IsHostileTo, IsFriendlyTo to ALE Unit methods                       |
|      300 | B020 | source | Add LOCK_ALE to ALEEventProcessor::RemoveEvent                                              |
|      320 | B022 | source | A --conf-dir option for the servers and dbimport, over the compiled-in module config folder |
|      340 | B024 | source | Creatures notice weaker players from farther, the reverse of stock aggro                    |
|      360 | B026 | source | Fix the bot-login Engine::Init crash (dangling strategy on duplicate add)                   |
|      370 | B027 | source | Guard Engine::Init against a strategy with a stale/foreign bot facade                       |
|      660 | B056 | source | Bots see only as far as they act                                                            |
|      670 | B057 | source | The most any view distance may be, as a setting                                             |

**After the compile and install (install steps and settings, mixed by priority):**

| priority | id    | kind     | about                                                                      |
| -------: | ----- | -------- | -------------------------------------------------------------------------- |
|     1010 | E001  | install  | Create symlinks from install dir to the profile-specific Lua source        |
|     1040 | E004  | install  | Create RAM-backed log directory symlink                                    |
|     1060 | E006  | install  | Initialize config files (.dist -> .conf) and apply profile-specific values |
|     1100 | C001  | settings | Database Connections                                                       |
|     1105 | C002  | settings | Directory Paths                                                            |
|     1110 | C003  | settings | Run Speed 85% (named for its first value, 80%)                             |
|     1115 | C004  | settings | Fall Damage 10x                                                            |
|     1130 | C006b | settings | Max Level 20 (Beta/Release)                                                |
|     1150 | C007b | settings | Starting Level 1 (Beta/Release/Basic)                                      |
|     1160 | C008  | settings | GM Login State                                                             |
|     1165 | C009  | settings | Instant Teleport (Beta)                                                    |
|     1170 | C010  | settings | Network Ports                                                              |
|     1175 | C011  | settings | Realmlist Setup                                                            |
|     1180 | C012  | settings | Playerbot Level Cap (Beta/Release)                                         |
|     1195 | C016  | settings | Missing server config keys                                                 |
|     1200 | C017  | settings | Level-correlated caps                                                      |
|     1210 | C019  | settings | RealmID per profile                                                        |
|     1220 | C021  | settings | SOAP Loopback Console (remote command channel for local scripts)           |
|     1240 | C025  | settings | Client cache version follows the profile's content (issue 160)             |
|     1275 | C032  | settings | Preserve Custom Channels (so a script can tell one channel from another)   |
|     1285 | C034  | settings | No Faster Healing Below Level 15, on Every Server                          |
|     1290 | C035  | settings | Beta Playerbot Population (200 random bots)                                |
|     1295 | C036  | settings | Beta: Death Knights for Everyone                                           |
|     1300 | C037  | settings | Beta: wow-chat-1's Survival Settings                                       |
|     1305 | C038  | settings | No Quest Sparkles, Object Quest Marks or Map Points                        |
|     1310 | C039  | settings | Instances and Battlegrounds: See as Far as the Server Allows               |
|     1890 | E059  | install  | The narrators' books (issue 909): every book on the shelf                  |

**After the databases are brought to upstream's state (our SQL):**

| priority | id   | kind | about                                                                                  |
| -------: | ---- | ---- | -------------------------------------------------------------------------------------- |
|     2410 | E011 | sql  | Death Knight class system for beta profile (issue 206/167). Wires DK                   |
|     2420 | E012 | sql  | Removes all creature spawns except critters and spirit healers                         |
|     2430 | E013 | sql  | Adds quest-learned class abilities to the class trainers' lists (issue                 |
|     2440 | E014 | sql  | Caps each travelling class trainer to the top of its level slice (issue                |
|     2450 | E015 | sql  | Race-specific selector NPCs for the custom class selection system                      |
|     2460 | E016 | sql  | Custom gameobject templates for empty-loot treasure chests (issue                      |
|     2470 | E017 | sql  | Fixes upstream mod-playerbots migration ordering bug (the                              |
|     2880 | E058 | sql  | Beta's death knights start at level 1 (issue 206), but the game hands                  |
|     2900 | E060 | sql  | Each druid's way back from Moonglade, and the visitors they brought there              |
|     2910 | E061 | sql  | Where each narrator is in its book (issue 910a): one row per narrator bot,             |
|     2920 | E062 | sql  | Beta: trade with the other faction (permission 51), every account, beta's realm.       |
|     2930 | E063 | sql  | Beta: mail to the other faction (permission 27), every account, beta's realm.          |
|     2940 | E064 | sql  | Beta: the other faction in the /who list (permission 28), every account, beta's realm. |
|     2950 | E065 | sql  | Beta: friends of the other faction (permission 29), every account, beta's realm.       |
<!-- patch-lists: end -->

`scripts/test-source-patches <project> beta` applies and reverts the
source patches on a copy in RAM.

## Databases

Beta's own since 2026-10-17 (issue 136b, branch beta-homework):
`acore_world_beta`, `acore_characters_beta`, `acore_playerbots_beta`, and
the shared `acore_auth`. Until then beta used release's, so installing beta
emptied release's world too; release's `acore_world` still holds that
emptied world until it is restored (136b, open question 4). The next beta
install builds the new databases from the stock ones.

## Scripts and their checks

- `src/lua-beta/` — what the engine loads: `scripts/test-beta-lua-load`
  loads them all as the engine does and fails on any that stop.
  Files ending `.disabled`, and folders starting with a dot, are not
  loaded (`scripts/test-lua-unique-names` checks this).
- The ambush: `scripts/test-ambush` plays it in a toy world; travellers:
  `scripts/test-travel`; treasure (still switched off): `scripts/test-treasure`;
  the shared geometry: `scripts/test-movement`.
- The whole loop at once: `scripts/demo-beta-toy-session [--minutes N]
  [--players N] [--seed N]` plays a stretch of beta in the pretend world
  with the real scripts (ambush, travellers, treasure, the group
  hearthstone) and reports, per player, the monsters, travellers, trainers
  and chests they met; its receipt goes to `output/goodbye`.
- The world database steps: `scripts/test-beta-sql-in-ram` applies,
  re-applies and undoes them on a stock world database in RAM.

## How to switch to beta

```bash
echo beta > .profile
./scripts/install --profile beta
./scripts/start-mysql
./scripts/authserver &
./scripts/worldserver
```

## Where to ask for help

- The plan: [beta-roadmap.md](beta-roadmap.md), issue 200
- Profile system overview: [index.md](index.md)
- ALE Lua scripting reference: [`docs/scripting.md`](../scripting.md)
- The wow-chat design: [`docs/concept-catalog.md`](../concept-catalog.md)
- The reference implementation: `libs/wow-chat-1/`
