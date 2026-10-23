# Patch Registry

Every change this project makes to AzerothCore, its modules and its installs
is a patch: a file with a header saying what it is, which profiles take it
and its priority (issue 189). This page says how they fit together, and
lists every one of them, written from their headers.

**The source tree is a build artifact.** `source-{profile}/` is cloned
from upstream by `scripts/redownload-source` and gitignored (line 17 of
the project `.gitignore`, pattern `source*/`). It is never tracked, never
committed. The B-patches in PHASE_BEGIN are the *only* mechanism by
which the source acquires our customizations, and they revert after
every build to keep the tree pristine. Any modification to source code
that survives across builds is a bug — either an unapply that failed,
or a manual edit that should have been a patch. See issue 136's
"Source Tree Is A Build Artifact" section for the canonical
description of this design.

## One number line, with gates

All patches share one line of priorities, whatever they change; the build
runs a profile's patches lowest first. A gate (`patches/gates`) is a number
where the build does a stage of its own work; nothing at or above it runs
until everything below has finished and the gate's work is done.

| priorities   | what runs there |
|-------------:|-----------------|
|      10      | quick tests (they run before anything, and are not on a profile's plan) |
|   100 -  999 | source patches (`patches/B*.sh`): applied to the source before the compile, taken off once it is through |
|  1000        | gate: compile and install |
|  1000 - 1999 | install steps (`patches/E*.sh`) and settings (`config/patches/C*.sh`), mixed by priority |
|  2000        | gate: the databases brought to upstream's state (the shadow server started once; its updater runs) |
|  2000 - 8999 | the steps handing our SQL to that updater (kind `sql`, issue 189d); the validation start applies them |
|  9000        | gate: the server may start |

Patches of one priority may run in any order; two that change the same
file may not share one (`scripts/test-source-patches` checks the source
patches). Undo runs the same patches last first.

The numbering rule a new patch's priority follows by default
(`scripts/add-patch-header`): a source patch `100 + 10 × its number`, an
install step `1300 + 10 × its number` (E001, E004, E006 sit lower, at 1010,
1040, 1060, so the config files exist before the settings), a settings
patch 5 above the last one.

## Reading the pipeline

```
1. quick tests              ← every test whose header says quick-test: yes
2. source patches           ← below gate 1000, by priority
3. cmake configure + make   ← gate 1000
4. cmake --install (to shadow)
5. install stage            ← 1000-1999: install steps and settings
6. gate 2000                ← the shadow server started once: upstream's SQL applied
7. SQL stage                ← 2000-8999: our SQL placed for the updater, own names
8. source patches undone    ← last first (the exit trap also does it on failure)
9. validate (applies ours), promote, server start
```

<!-- patch-lists: begin. Written by scripts/generate-patch-lists from the patches' headers (issue 189f): edit a header, then run it; do not edit by hand. -->
## Every patch

Each patch and quick test, lowest priority first, as its header says it.
A patch's profiles are profile names, a group from `patches/groups`,
`all` or `none`; `patches/gates` says where the build's own stages stand
on the priority line. `scripts/plan-patches PROFILE` gives one profile's,
in the build's order.

| id                             | kind         | priority | profiles                                 | about                                                                                        | file                                                                                     |
| ------------------------------ | ------------ | -------: | ---------------------------------------- | -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| test-acherus-vendors           | test (quick) |       10 | all                                      | The Acherus vendors step applies, repeats and reverts, in one rolled-back transaction        | `scripts/test-acherus-vendors`                                                           |
| test-ale-method-names          | test (quick) |       10 | all                                      | checks that every method the server-side Lua                                                 | `scripts/test-ale-method-names`                                                          |
| test-ambush                    | test (quick) |       10 | all                                      | runs beta's ambush script (src/lua-beta/ambush.lua) in a                                     | `scripts/test-ambush`                                                                    |
| test-arathi-basin-rules        | test (quick) |       10 | all                                      | the Arathi Basin scene's two rules that need no                                              | `scripts/test-arathi-basin-rules`                                                        |
| test-beta-lua-load             | test (quick) |       10 | all                                      | loads every Lua file the beta server would load, in                                          | `scripts/test-beta-lua-load`                                                             |
| test-beta-two-side-permissions | test (quick) |       10 | all                                      | beta's four cross-faction permissions (issue 193)                                            | `scripts/test-beta-two-side-permissions`                                                 |
| test-buddy-arc                 | test (quick) |       10 | all                                      | checks where a partner's buddies are placed when a game                                      | `scripts/test-buddy-arc`                                                                 |
| test-buddy-choice              | test (quick) |       10 | all                                      | play thousands of buddy picks at Sargobras and check                                         | `scripts/test-buddy-choice`                                                              |
| test-buddy-gems                | test (quick) |       10 | all                                      | checks that a buddy's starting gear can always be fully                                      | `scripts/test-buddy-gems`                                                                |
| test-buddy-gm                  | test (quick) |       10 | all                                      | runs the game masters' buddy commands                                                        | `scripts/test-buddy-gm`                                                                  |
| test-buddy-hearth              | test (quick) |       10 | all                                      | buddies follow their partner's hearthstone                                                   | `scripts/test-buddy-hearth`                                                              |
| test-buddy-kit                 | test (quick) |       10 | all                                      | checks how a new buddy's bag slots are split over its bags                                   | `scripts/test-buddy-kit`                                                                 |
| test-buddy-roam-core           | test (quick) |       10 | all                                      | holds the server's C++ roaming core to the Lua model                                         | `scripts/test-buddy-roam-core`                                                           |
| test-buddy-stand-ins           | test (quick) |       10 | all                                      | checks the stand-in maker's choices (issue 617t1):                                           | `scripts/test-buddy-stand-ins`                                                           |
| test-buddy-talents             | test (quick) |       10 | all                                      | level every class's buddy through every talent                                               | `scripts/test-buddy-talents`                                                             |
| test-carried-files             | test (quick) |       10 | all                                      | a patch that is a directory carries exactly what it says (issue 189e)                        | `scripts/test-carried-files`                                                             |
| test-check-issue-references    | test (quick) |       10 | all                                      | checks the issue reference checker against                                                   | `scripts/test-check-issue-references`                                                    |
| test-compile-module-set        | test (quick) |       10 | all                                      | check which modules the compile script builds                                                | `scripts/test-compile-module-set`                                                        |
| test-dk-buddies-by-level       | test (quick) |       10 | all                                      | a death knight player's buddies come by level                                                | `scripts/test-dk-buddies-by-level`                                                       |
| test-dk-buddy-gear             | test (quick) |       10 | all                                      | what a death knight player's buddies wear                                                    | `scripts/test-dk-buddy-gear`                                                             |
| test-dk-skip-story             | test (quick) |       10 | all                                      | Sargobras's "skip the story" for death knights                                               | `scripts/test-dk-skip-story`                                                             |
| test-dk-soul-trade             | test (quick) |       10 | all                                      | a death knight gives a soul to the Lich King at                                              | `scripts/test-dk-soul-trade`                                                             |
| test-druid-moonglade           | test (quick) |       10 | all                                      | plays the druids' Moonglade return (issue 211a) in                                           | `scripts/test-druid-moonglade`                                                           |
| test-forget-z-prefixed-updates | test (quick) |       10 | all                                      | The SQL stage forgets our files' z_ update records, and nothing else (189d)                  | `scripts/test-forget-z-prefixed-updates`                                                 |
| test-gear-designs              | test (quick) |       10 | all                                      | check the gear design loop without a picture                                                 | `scripts/test-gear-designs`                                                              |
| test-gearsets                  | test (quick) |       10 | all                                      | holds the gearset profiles (issue 617r) to their rules,                                      | `scripts/test-gearsets`                                                                  |
| test-gm-command-reference      | test (quick) |       10 | all                                      | the project's game master commands, their one                                                | `scripts/test-gm-command-reference`                                                      |
| test-hearthstone               | test (quick) |       10 | all                                      | runs beta's group hearthstone (src/lua-beta/hearthstone.lua)                                 | `scripts/test-hearthstone`                                                               |
| test-info-files-match-source   | test (quick) |       10 | all                                      | checks that each Lua file's ".info.md"                                                       | `scripts/test-info-files-match-source`                                                   |
| test-line-edits                | test (quick) |       10 | all                                      | check that the source patches' whole-line edits apply                                        | `scripts/test-line-edits`                                                                |
| test-lua-globals               | test (quick) |       10 | all                                      | checks that the game's Lua scripts do not step on each                                       | `scripts/test-lua-globals`                                                               |
| test-lua-unique-names          | test (quick) |       10 | all                                      | checks the files a profile's Lua engine will load:                                           | `scripts/test-lua-unique-names`                                                          |
| test-make-intuition-copy       | test (quick) |       10 | all                                      | checks the comment-free copy's maker (issue 190)                                             | `scripts/test-make-intuition-copy`                                                       |
| test-movement                  | test (quick) |       10 | all                                      | checks beta's shared geometry helpers                                                        | `scripts/test-movement`                                                                  |
| test-navmesh-caves             | test (quick) |       10 | all                                      | the walking mesh and the terrain together find a                                             | `scripts/test-navmesh-caves`                                                             |
| test-patch-headers             | test (quick) |       10 | all                                      | the patch header's reader and checker (issue 189a)                                           | `scripts/test-patch-headers`                                                             |
| test-patch-lists-current       | test (quick) |       10 | all                                      | the docs' patch lists say what the headers say (issue 189f)                                  | `scripts/test-patch-lists-current`                                                       |
| test-patch-plan                | test (quick) |       10 | all                                      | the build's order comes from the patches' headers (issue 189c)                               | `scripts/test-patch-plan`                                                                |
| test-patch-undo-order          | test (quick) |       10 | all                                      | patches come off last first (issue 189)                                                      | `scripts/test-patch-undo-order`                                                          |
| test-profile-config-gates      | test (quick) |       10 | all                                      | run a profile's config patches on scratch                                                    | `scripts/test-profile-config-gates`                                                      |
| test-profile-tables-agree      | test (quick) |       10 | all                                      | checks that every script holding a copy of a                                                 | `scripts/test-profile-tables-agree`                                                      |
| test-quest-reward-has-a-giver  | test (quick) |       10 | all                                      | No project C++ hands the quest reward step no quest giver (the 2026-10-22 crash)             | `scripts/test-quest-reward-has-a-giver`                                                  |
| test-redirect-listener         | test (quick) |       10 | all                                      | The redirect experiment's pretend second server accepts a redirected client                  | `scripts/test-redirect-listener`                                                         |
| test-roam-pattern              | test (quick) |       10 | all                                      | hold both implementations of the roaming pattern to                                          | `scripts/test-roam-pattern`                                                              |
| test-sargobras-follow          | test (quick) |       10 | all                                      | The wandering Sargobras keeps near his owner, in a stand-in world                            | `scripts/test-sargobras-follow`                                                          |
| test-sql-mirror                | test (quick) |       10 | all                                      | checks that the project's SQL reaches the core's updater                                     | `scripts/test-sql-mirror`                                                                |
| test-steady-mtimes             | test (quick) |       10 | all                                      | the compile script gives patched files back their                                            | `scripts/test-steady-mtimes`                                                             |
| test-travel                    | test (quick) |       10 | all                                      | runs beta's traveller script (src/lua-beta/travel.lua) in a                                  | `scripts/test-travel`                                                                    |
| test-treasure                  | test (quick) |       10 | all                                      | runs beta's treasure script (src/lua-beta/treasure.lua.disabled)                             | `scripts/test-treasure`                                                                  |
| test-validate-needs-world-up   | test (quick) |       10 | all                                      | checks that a build is only called good when                                                 | `scripts/test-validate-needs-world-up`                                                   |
| test-valley-deal               | test (quick) |       10 | all                                      | "Can I go somewhere else?": each character's valley order, and where a press lands           | `scripts/test-valley-deal`                                                               |
| test-watch-compile             | test (quick) |       10 | all                                      | checks scripts/watch-compile's verdicts on made-up                                           | `scripts/test-watch-compile`                                                             |
| test-world-boss-countdown      | test (quick) |       10 | all                                      | checks the world bosses' respawn countdown                                                   | `scripts/test-world-boss-countdown`                                                      |
| B002                           | source       |      120 | basic beta cc-test vanilla               | Add ALE OnLogin hook to playerbots bot login                                                 | `patches/B002-playerbots-ale-login-hook.sh`                                              |
| B003                           | source       |      130 | beta                                     | Enable entry 0 as wildcard for RegisterGameObjectEvent                                       | `patches/B003-ale-gameobject-wildcard.sh`                                                |
| B004                           | source       |      140 | basic beta cc-test release vanilla       | Fix ~695 compiler warnings in upstream modules                                               | `patches/B004-upstream-warning-fixes.sh`                                                 |
| B005                           | source       |      150 | basic beta                               | Cap level difference impact on hit/miss at ±3 levels                                         | `patches/B005-accuracy-level-cap.sh`                                                     |
| B006                           | source       |      160 | beta                                     | Add PLAYER_EVENT_ON_SELL_ITEM to ALE                                                         | `patches/B006-ale-sell-item-hook.sh`                                                     |
| B007                           | source       |      170 | beta                                     | Add SetWalk, IsWalking, IsHostileTo, IsFriendlyTo to ALE Unit methods                        | `patches/B007-ale-unit-methods.sh`                                                       |
| B010                           | source       |      200 | none                                     | Add the ARENA_TYPE_NONE value the bot module compares against                                | `patches/B010-playerbots-arena-type-none.sh`                                             |
| B011                           | source       |      210 | none                                     | Retired 2026-05-19: matched the Lua engine's resurrect hook to the older core's              | `patches/B011-ale-resurrect-signature.sh`                                                |
| B020                           | source       |      300 | basic beta cc-test release vanilla       | Add LOCK_ALE to ALEEventProcessor::RemoveEvent                                               | `patches/B020-ale-event-removeevent-lock.sh`                                             |
| B022                           | source       |      320 | basic beta cc-test release vanilla       | A --conf-dir option for the servers and dbimport, over the compiled-in module config folder  | `patches/B022-runtime-conf-dir-override.sh`                                              |
| B024                           | source       |      340 | beta release                             | Creatures notice weaker players from farther, the reverse of stock aggro                     | `patches/B024-symmetric-aggro-radius.sh`                                                 |
| B025                           | source       |      350 | vanilla                                  | Vanilla playerbots start in the 148h starter kit (issue 148s)                                | `patches/B025-playerbots-vanilla-starter-kit.sh`                                         |
| B026                           | source       |      360 | basic beta cc-test release vanilla       | Fix the bot-login Engine::Init crash (dangling strategy on duplicate add)                    | `patches/B026-playerbots-bot-login-strategy-guard.sh`                                    |
| B027                           | source       |      370 | basic beta cc-test release vanilla       | Guard Engine::Init against a strategy with a stale/foreign bot facade                        | `patches/B027-playerbots-engine-init-facade-guard.sh`                                    |
| B028                           | source       |      380 | basic                                    | Basic: new characters spawn in their faction's rotating starting valley                      | `patches/B028-basic-starting-valley-rotation.sh`                                         |
| B029                           | source       |      390 | basic                                    | A trainer gossip option can name which trainer list it opens                                 | `patches/B029-gossip-option-trainer-list.sh`                                             |
| B030                           | source       |      400 | basic                                    | Build the basic profile's own server rules into the worldserver                              | `patches/B030-basic-rules-script.sh`                                                     |
| B031                           | source       |      410 | basic                                    | Crushing blows start 4 levels later and ramp in over 4 more                                  | `patches/B031-crushing-blows-late.sh`                                                    |
| B032                           | source       |      420 | basic                                    | A buff can be cast on anyone, whatever the gap between its level and theirs                  | `patches/B032-no-buff-level-restriction.sh`                                              |
| B033                           | source       |      430 | basic                                    | White (common-quality) gear is never repaired                                                | `patches/B033-white-gear-never-repaired.sh`                                              |
| B035                           | source       |      450 | basic                                    | Respec cost: no cap, and it falls on the weekly reset                                        | `patches/B035-respec-cost-weekly.sh`                                                     |
| B036                           | source       |      460 | buddy-set                                | Build the project's buddy module (mod-buddies) into the worldserver                          | `patches/B036-mod-buddies/B036-mod-buddies.sh`                                           |
| B037                           | source       |      470 | buddy-set                                | Playerbots: a switch for the group invite at a bot's login                                   | `patches/B037-playerbots-invite-alts-on-login.sh`                                        |
| B038                           | source       |      480 | basic                                    | Built-in chat channels a profile refuses                                                     | `patches/B038-refused-channels.sh`                                                       |
| B039                           | source       |      490 | basic                                    | Log why the console thread shuts the world down (issue 163)                                  | `patches/B039-cli-console-silent-shutdown-logging.sh`                                    |
| B040                           | source       |      500 | basic                                    | Creatures one player cannot select                                                           | `patches/B040-per-player-unselectable.sh`                                                |
| B041                           | source       |      510 | basic                                    | Lua calls for creatures one player cannot select                                             | `patches/B041-ale-per-player-unselectable.sh`                                            |
| B042                           | source       |      520 | buddy-set                                | A bot says "AI was reset to defaults" only when asked to reset                               | `patches/B042-quiet-automatic-ai-reset.sh`                                               |
| B043                           | source       |      530 | basic                                    | The world says who stopped it                                                                | `patches/B043-say-why-the-world-stopped.sh`                                              |
| B044                           | source       |      540 | buddy-set                                | Companion accounts: their characters are not in /who and can't be friended                   | `patches/B044-companion-accounts-unseen.sh`                                              |
| B045                           | source       |      550 | buddy-set                                | Playerbots: a bot on a companion account takes no chat commands                              | `patches/B045-playerbots-companions-take-no-commands.sh`                                 |
| B046                           | source       |      560 | buddy-set                                | Playerbots: buddies judge gear by their own talent plan and roll                             | `patches/B046-playerbots-buddy-loot-judgement.sh`                                        |
| B047                           | source       |      570 | buddy-set                                | Creature outfits: a creature can look like a dressed player character                        | `patches/B047-creature-outfits.sh`                                                       |
| B048                           | source       |      580 | buddy-set                                | Buddies don't whisper their owner about failed item moves                                    | `patches/B048-playerbots-buddies-quiet-inventory.sh`                                     |
| B049                           | source       |      590 | basic                                    | Spirit heals by stamina, in combat too                                                       | `patches/B049-spirit-heals-by-stamina.sh`                                                |
| B050                           | source       |      600 | buddy-set                                | Playerbots: a buddy weighs spirit by what it heals                                           | `patches/B050-playerbots-buddy-spirit-worth.sh`                                          |
| B051                           | source       |      610 | basic                                    | a Lua call that asks the navigation mesh how far a walk is                                   | `patches/B051-ale-walkable-path-length.sh`                                               |
| B052                           | source       |      620 | buddy-set                                | Playerbots: a buddy's long walk never ends in a teleport                                     | `patches/B052-playerbots-buddies-never-teleport-to-owner.sh`                             |
| B053                           | source       |      630 | basic                                    | Players walk at the full stock speed; only running and the rest                              | `patches/B053-walking-at-full-speed.sh`                                                  |
| B054                           | source       |      640 | buddy-set                                | The server accepts navigation tiles built by version 19 of the                               | `patches/B054-accept-version-19-navigation-tiles.sh`                                     |
| B056                           | source       |      660 | basic beta cc-test release vanilla       | Bots see only as far as they act                                                             | `patches/B056-bots-see-only-as-far-as-they-act.sh`                                       |
| B057                           | source       |      670 | basic beta cc-test release vanilla       | The most any view distance may be, as a setting                                              | `patches/B057-view-distance-limit-as-a-setting.sh`                                       |
| E001                           | install      |     1010 | basic beta cc-test vanilla               | Create symlinks from install dir to the profile-specific Lua source                          | `patches/E001-lua-script-symlinks.sh`                                                    |
| E004                           | install      |     1040 | alpha basic beta cc-test release vanilla | Create RAM-backed log directory symlink                                                      | `patches/E004-log-directory-setup.sh`                                                    |
| E006                           | install      |     1060 | alpha basic beta cc-test release vanilla | Initialize config files (.dist -> .conf) and apply profile-specific values                   | `patches/E006-initialize-config-files.sh`                                                |
| C001                           | settings     |     1100 | all                                      | Database Connections                                                                         | `config/patches/C001-database-connections.sh`                                            |
| C002                           | settings     |     1105 | all                                      | Directory Paths                                                                              | `config/patches/C002-directory-paths.sh`                                                 |
| C003                           | settings     |     1110 | alpha basic beta release vanilla         | Run Speed 85% (named for its first value, 80%)                                               | `config/patches/C003-run-speed-80-percent.sh`                                            |
| C004                           | settings     |     1115 | basic beta release vanilla               | Fall Damage 10x                                                                              | `config/patches/C004-fall-damage-10x.sh`                                                 |
| C005                           | settings     |     1120 | release                                  | Experience Rate 2x                                                                           | `config/patches/C005-exp-rate-2x.sh`                                                     |
| C006a                          | settings     |     1125 | alpha                                    | Max Level 80 (Alpha)                                                                         | `config/patches/C006a-max-level-80.sh`                                                   |
| C006b                          | settings     |     1130 | beta release                             | Max Level 20 (Beta/Release)                                                                  | `config/patches/C006b-max-level-20.sh`                                                   |
| C006c                          | settings     |     1135 | vanilla                                  | Max Level 40 (Vanilla)                                                                       | `config/patches/C006c-max-level-40.sh`                                                   |
| C006d                          | settings     |     1140 | basic                                    | Max Level 60 (Basic)                                                                         | `config/patches/C006d-max-level-60.sh`                                                   |
| C007a                          | settings     |     1145 | alpha                                    | Starting Level 40 (Alpha)                                                                    | `config/patches/C007a-starting-level-40.sh`                                              |
| C007b                          | settings     |     1150 | basic beta release                       | Starting Level 1 (Beta/Release/Basic)                                                        | `config/patches/C007b-starting-level-1.sh`                                               |
| C007c                          | settings     |     1155 | vanilla                                  | Starting Level 20 (Vanilla)                                                                  | `config/patches/C007c-starting-level-20.sh`                                              |
| C008                           | settings     |     1160 | all                                      | GM Login State                                                                               | `config/patches/C008-gm-login-state.sh`                                                  |
| C009                           | settings     |     1165 | beta                                     | Instant Teleport (Beta)                                                                      | `config/patches/C009-instant-teleport-beta.sh`                                           |
| C010                           | settings     |     1170 | all                                      | Network Ports                                                                                | `config/patches/C010-network-ports.sh`                                                   |
| C011                           | settings     |     1175 | all                                      | Realmlist Setup                                                                              | `config/patches/C011-realmlist-setup.sh`                                                 |
| C012                           | settings     |     1180 | beta release                             | Playerbot Level Cap (Beta/Release)                                                           | `config/patches/C012-playerbot-level-cap.sh`                                             |
| C014                           | settings     |     1185 | vanilla                                  | Vanilla Playerbot Progression (enter at 20, climb to the 40 cap)                             | `config/patches/C014-vanilla-playerbot-level-cap.sh`                                     |
| C015                           | settings     |     1190 | vanilla                                  | Disable Death Knight (Vanilla)                                                               | `config/patches/C015-vanilla-disable-deathknight.sh`                                     |
| C016                           | settings     |     1195 | basic beta cc-test release vanilla       | Missing server config keys                                                                   | `config/patches/C016-missing-server-config-keys.sh`                                      |
| C017                           | settings     |     1200 | basic beta release vanilla               | Level-correlated caps                                                                        | `config/patches/C017-level-correlated-caps.sh`                                           |
| C018                           | settings     |     1205 | vanilla                                  | Vanilla Playerbot Account Count                                                              | `config/patches/C018-vanilla-playerbot-account-count.sh`                                 |
| C019                           | settings     |     1210 | all                                      | RealmID per profile                                                                          | `config/patches/C019-realm-id.sh`                                                        |
| C020                           | settings     |     1215 | vanilla                                  | Vanilla Playerbot Population Band (hold 128–256 active bots)                                 | `config/patches/C020-vanilla-playerbot-population.sh`                                    |
| C021                           | settings     |     1220 | all                                      | SOAP Loopback Console (remote command channel for local scripts)                             | `config/patches/C021-soap-loopback-console.sh`                                           |
| C022                           | settings     |     1225 | vanilla                                  | Enable Custom Starting Spells (Vanilla)                                                      | `config/patches/C022-vanilla-custom-spells.sh`                                           |
| C023                           | settings     |     1230 | buddy-set                                | Basic: No Random Bots                                                                        | `config/patches/C023-basic-no-random-bots.sh`                                            |
| C024                           | settings     |     1235 | basic                                    | Basic Death Knight Rules (interim, until issue 718)                                          | `config/patches/C024-basic-death-knight-rules.sh`                                        |
| C025                           | settings     |     1240 | all                                      | Client cache version follows the profile's content (issue 160)                               | `config/patches/C025-client-cache-version.sh`                                            |
| C026                           | settings     |     1245 | basic                                    | Basic: No Dual Spec                                                                          | `config/patches/C026-basic-no-dual-spec.sh`                                              |
| C027                           | settings     |     1250 | buddy-set                                | Basic: Buddies Spend Their Own Talents                                                       | `config/patches/C027-basic-buddy-own-talents.sh`                                         |
| C028                           | settings     |     1255 | basic                                    | Basic: Honor Without a Cap                                                                   | `config/patches/C028-basic-honor-uncapped.sh`                                            |
| C029                           | settings     |     1260 | buddy-set                                | Basic: Buddies Keep Their Own Parties                                                        | `config/patches/C029-basic-buddies-keep-own-parties.sh`                                  |
| C030                           | settings     |     1265 | buddy-set                                | Basic: No Group Invite at a Buddy's Login                                                    | `config/patches/C030-basic-buddies-no-login-invite.sh`                                   |
| C031                           | settings     |     1270 | basic                                    | Basic: No World Channels (General, Trade, the Defense channels, LFG, Guild Recruitment)      | `config/patches/C031-basic-refused-channels.sh`                                          |
| C032                           | settings     |     1275 | all                                      | Preserve Custom Channels (so a script can tell one channel from another)                     | `config/patches/C032-preserve-custom-channels.sh`                                        |
| C033                           | settings     |     1280 | cc-test                                  | cc-test: Warden Kicks on a Failed Check                                                      | `config/patches/C033-cc-test-warden-kicks.sh`                                            |
| C034                           | settings     |     1285 | all                                      | No Faster Healing Below Level 15, on Every Server                                            | `config/patches/C034-no-low-level-regen-boost.sh`                                        |
| C035                           | settings     |     1290 | beta                                     | Beta Playerbot Population (200 random bots)                                                  | `config/patches/C035-beta-playerbot-population.sh`                                       |
| C036                           | settings     |     1295 | beta                                     | Beta: Death Knights for Everyone                                                             | `config/patches/C036-beta-death-knights-for-everyone.sh`                                 |
| C037                           | settings     |     1300 | beta                                     | Beta: wow-chat-1's Survival Settings                                                         | `config/patches/C037-beta-wow-chat-1-survival-settings.sh`                               |
| C038                           | settings     |     1305 | basic beta release vanilla               | No Quest Sparkles, Object Quest Marks or Map Points                                          | `config/patches/C038-no-quest-sparkles-or-map-points.sh`                                 |
| C039                           | settings     |     1310 | basic beta cc-test release vanilla       | Instances and Battlegrounds: See as Far as the Server Allows                                 | `config/patches/C039-instances-and-battlegrounds-see-all.sh`                             |
| E049                           | install      |     1790 | basic                                    | Every town's exploring grid baked ahead of time (issue 617o3), so buddies                    | `patches/E049-basic-buddy-town-bake.sh`                                                  |
| E059                           | install      |     1890 | beta                                     | The narrators' books (issue 909): every book on the shelf                                    | `patches/E059-beta-narrator-library.sh`                                                  |
| E066                           | install      |     1960 | basic                                    | Sargobras, his own patch: his script and his own copies of what it loads, placed per profile | `patches/E066-sargobras/E066-sargobras.sh`                                               |
| E007                           | sql          |     2370 | vanilla                                  | Override playercreateinfo so vanilla characters spawn at the                                 | `patches/E007-vanilla-starting-zones.sh`                                                 |
| E008                           | sql          |     2380 | basic vanilla                            | Clear the flightmaster bit network-wide and replace gossip with                              | `patches/E008-vanilla-remove-flight-paths/E008-vanilla-remove-flight-paths.sh`           |
| E009                           | sql          |     2390 | vanilla                                  | Apply vanilla profile's class-specific starting equipment kit                                | `patches/E009-vanilla-starter-kit.sh`                                                    |
| E010                           | sql          |     2400 | vanilla                                  | Grant every newly-created vanilla character the full set of                                  | `patches/E010-vanilla-pretrain-abilities.sh`                                             |
| E011                           | sql          |     2410 | beta                                     | Death Knight class system for beta profile (issue 206/167). Wires DK                         | `patches/E011-beta-dk-class-system.sh`                                                   |
| E012                           | sql          |     2420 | beta                                     | Removes all creature spawns except critters and spirit healers                               | `patches/E012-beta-drop-creatures-keep-essential.sh`                                     |
| E013                           | sql          |     2430 | beta                                     | Adds quest-learned class abilities to the class trainers' lists (issue                       | `patches/E013-beta-quest-spells-to-trainers.sh`                                          |
| E014                           | sql          |     2440 | beta                                     | Caps each travelling class trainer to the top of its level slice (issue                      | `patches/E014-beta-trainer-spell-level-cap.sh`                                           |
| E015                           | sql          |     2450 | beta                                     | Race-specific selector NPCs for the custom class selection system                            | `patches/E015-beta-class-selector-npcs.sh`                                               |
| E016                           | sql          |     2460 | beta                                     | Custom gameobject templates for empty-loot treasure chests (issue                            | `patches/E016-beta-empty-loot-chests.sh`                                                 |
| E017                           | sql          |     2470 | beta                                     | Fixes upstream mod-playerbots migration ordering bug (the                                    | `patches/E017-beta-relocate-logout-texts.sh`                                             |
| E019                           | sql          |     2490 | basic vanilla                            | Installs a BEFORE INSERT trigger on acore_characters_vanilla.characters                      | `patches/E019-vanilla-no-intro-cinematic/E019-vanilla-no-intro-cinematic.sh`             |
| E020                           | sql          |     2500 | basic vanilla                            | Push the two ground riding skills to Classic level gates (148l): Apprentice                  | `patches/E020-vanilla-mount-level-requirements/E020-vanilla-mount-level-requirements.sh` |
| E021                           | sql          |     2510 | vanilla                                  | Grant every level-20 vanilla character a gathering + a production profession                 | `patches/E021-vanilla-starting-professions.sh`                                           |
| E022                           | sql          |     2520 | basic                                    | Open every quest to its whole faction on the basic profile (issue 155e):                     | `patches/E022-basic-faction-quest-gating.sh`                                             |
| E023                           | sql          |     2530 | basic                                    | Create and seed the rotation-state table the basic profile's                                 | `patches/E023-basic-starting-valley-rotation.sh`                                         |
| E024                           | sql          |     2540 | basic                                    | Basic's Outland dungeon ladder (issue 155f): sixteen dungeons open at 60,                    | `patches/E024-basic-outland-dungeons-64.sh`                                              |
| E025                           | sql          |     2550 | basic                                    | One "Visiting Mentor" per starting valley that teaches exactly the classes                   | `patches/E025-basic-valley-universal-trainers.sh`                                        |
| E026                           | sql          |     2560 | basic                                    | The table of per-creature (and per-map) damage, healing and health                           | `patches/E026-basic-creature-multipliers.sh`                                             |
| E027                           | sql          |     2570 | basic                                    | Outland without tradeskills (issue 155n): its herb, ore, gas and fishing                     | `patches/E027-basic-outland-without-tradeskills.sh`                                      |
| E028                           | sql          |     2580 | basic                                    | Outland without quests (issue 155l): every Outland, Shattrath, Isle and                      | `patches/E028-basic-outland-without-quests.sh`                                           |
| E029                           | sql          |     2590 | basic                                    | Inscription without glyphs (issue 155o): glyph recipes off the trainers,                     | `patches/E029-basic-inscription-without-glyphs.sh`                                       |
| E030                           | sql          |     2600 | basic                                    | Darkmoon cards (issue 155o): nothing from a Darkmoon deck binds, and the                     | `patches/E030-basic-darkmoon-cards.sh`                                                   |
| E031                           | sql          |     2610 | basic                                    | Outland gear scaling (issue 155k, with 155f's dungeon ladder): Outland's                     | `patches/E031-basic-outland-gear-scaling.sh`                                             |
| E032                           | sql          |     2620 | basic                                    | Outland world levels (issue 155k): Outland's open-world monsters +4, the                     | `patches/E032-basic-outland-world-levels.sh`                                             |
| E033                           | sql          |     2630 | basic                                    | Gem supply (issue 155p, stage 1): prospecting yields, Wrath and epic gem                     | `patches/E033-basic-gem-supply-and-sockets.sh`                                           |
| E036                           | sql          |     2660 | basic                                    | White gear durability (issue 155p): white weapons and armor last twice as                    | `patches/E036-basic-white-durability.sh`                                                 |
| E037                           | sql          |     2670 | basic                                    | Class books for the level 61-80 abilities (issue 155q): one stock-style                      | `patches/E037-basic-ability-tomes.sh`                                                    |
| E038                           | sql          |     2680 | basic                                    | The Dark Portal as the only door into Outland (issue 155l): Shattrath's                      | `patches/E038-basic-outland-one-door.sh`                                                 |
| E039                           | sql          |     2690 | basic                                    | No guild banks (issue 617l): every Guild Vault spawn removed. Same                           | `patches/E039-basic-no-guild-banks.sh`                                                   |
| E040                           | sql          |     2700 | basic                                    | Sargobras at the gate of Acherus (issue 718): the gossip NPC in the Ebon                     | `patches/E040-basic-death-knight-story-at-acherus.sh`                                    |
| E042                           | sql          |     2720 | buddy-set                                | The buddy clan and roster tables (issue 617a1): each owner's companion                       | `patches/E042-basic-buddy-roster/E042-basic-buddy-roster.sh`                             |
| E043                           | sql          |     2730 | basic                                    | Sargobras, the buddy selector (issue 617b): his two creatures (the valley                    | `patches/E043-basic-buddy-selector.sh`                                                   |
| E044                           | sql          |     2740 | buddy-set                                | Every named area's borders and middle (issue 617e2), for the buddies'                        | `patches/E044-basic-buddy-area-centres/E044-basic-buddy-area-centres.sh`                 |
| E045                           | sql          |     2750 | buddy-set                                | The beds buddies sleep on in towns (issue 617e4), placed by hand in game                     | `patches/E045-basic-buddy-beds/E045-basic-buddy-beds.sh`                                 |
| E046                           | sql          |     2760 | basic                                    | The world bosses' respawn taken off the server's timer (issue 155j): the                     | `patches/E046-basic-world-bosses.sh`                                                     |
| E050                           | sql          |     2800 | buddy-set                                | The world's little towns as circles (issue 617e4a): every cluster of                         | `patches/E050-basic-buddy-town-circles/E050-basic-buddy-town-circles.sh`                 |
| E052                           | sql          |     2820 | buddy-set                                | Every gearset profile (issue 617r: src/lua-basic/data/gearsets/*.lua) as                     | `patches/E052-basic-gearsets/E052-basic-gearsets.sh`                                     |
| E053                           | sql          |     2830 | buddy-set                                | The `command` rows for the game master commands the project compiles in                      | `patches/E053-custom-command-help.sh`                                                    |
| E054                           | sql          |     2840 | basic                                    | The game's legendaries as level-60 raid drops (issue 182): level-60 copies                   | `patches/E054-basic-legendaries.sh`                                                      |
| E055                           | sql          |     2850 | basic                                    | The smaller places buddies roam (issue 617e12, the first cut): every named                   | `patches/E055-basic-buddy-subareas.sh`                                                   |
| E056                           | sql          |     2860 | buddy-set                                | The kept stand-ins (issue 617t1): one row per stand-in character the buddy                   | `patches/E056-basic-buddy-stand-ins/E056-basic-buddy-stand-ins.sh`                       |
| E057                           | sql          |     2870 | basic                                    | The Eternal Belt Buckle usable from level 60 (issue 624): one item's                         | `patches/E057-basic-belt-buckle.sh`                                                      |
| E058                           | sql          |     2880 | beta                                     | Beta's death knights start at level 1 (issue 206), but the game hands                        | `patches/E058-beta-dk-outfit-for-level-1.sh`                                             |
| E060                           | sql          |     2900 | beta                                     | Each druid's way back from Moonglade, and the visitors they brought there                    | `patches/E060-beta-moonglade-return.sh`                                                  |
| E061                           | sql          |     2910 | beta                                     | Where each narrator is in its book (issue 910a): one row per narrator bot,                   | `patches/E061-beta-narrator-reading.sh`                                                  |
| E062                           | sql          |     2920 | beta                                     | Beta: trade with the other faction (permission 51), every account, beta's realm.             | `patches/E062-beta-two-side-trade.sh`                                                    |
| E063                           | sql          |     2930 | beta                                     | Beta: mail to the other faction (permission 27), every account, beta's realm.                | `patches/E063-beta-two-side-mail.sh`                                                     |
| E064                           | sql          |     2940 | beta                                     | Beta: the other faction in the /who list (permission 28), every account, beta's realm.       | `patches/E064-beta-two-side-who.sh`                                                      |
| E065                           | sql          |     2950 | beta                                     | Beta: friends of the other faction (permission 29), every account, beta's realm.             | `patches/E065-beta-two-side-friends.sh`                                                  |
| E067                           | sql          |     2970 | basic                                    | One enchanting scroll per classic dungeon boss kill, near the boss's level (issue 812)       | `patches/E067-basic-boss-enchant-scrolls/E067-basic-boss-enchant-scrolls.sh`             |
<!-- patch-lists: end -->

## Older write-ups of source patches

Each patch file's own comments are where its symptom, its edit and its
undo are described; these longer write-ups of the first source patches
were kept from this page's hand-kept days.

### B001: aoe-loot-item-namespace

**File:** `modules/mod-aoe-loot/src/aoe_loot.cpp`
**Line:** 458
**Pattern:** `Item* pItem = player->GetItemByGuid`
**Fix:** `::Item* pItem = player->GetItemByGuid`
**Reason:** AzerothCore has both `class Item` and `namespace WorldPackets::Item`. The global scope operator `::` disambiguates.

```bash
# Idempotent check: only patch if unfixed pattern exists
grep -q "^[[:space:]]*Item\* pItem = player->GetItemByGuid" "$FILE" && \
sed -i 's/^\([[:space:]]*\)Item\* pItem = player->GetItemByGuid/\1::Item* pItem = player->GetItemByGuid/' "$FILE"
```

### B002: playerbots-ale-login-hook

**File:** `modules/mod-playerbots/src/Bot/RandomPlayerbotMgr.cpp`
**Issue:** 306 (was 324) - playerbots don't trigger PLAYER_EVENT_ON_LOGIN
**Reason:** Playerbots log bots in through their own C++ path, bypassing ALE Lua hooks. This prevents Lua scripts from initializing bot behaviors.

**Changes:**
1. Add `#include "LuaEngine.h"` after existing includes
2. Add `sALE->OnLogin(bot);` at end of `OnBotLoginInternal` function

```bash
# Idempotent check: only patch if hook not present
grep -q "sALE->OnLogin(bot)" "$FILE" || {
    # Add include
    sed -i '/#include "RandomPlayerbotMgr.h"/a #include "LuaEngine.h"'
    # Add hook call via awk (brace-depth tracking)
    awk '...' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
}
```

**See:** `docs/patches/playerbots-ale-login-hook.md` for full implementation details.

### B003: ale-gameobject-wildcard

**File:** `modules/mod-ale/src/LuaEngine/LuaEngine.cpp`
**Issue:** 307 (was 325) - ALE doesn't support entry 0 wildcard for gameobject events
**Reason:** ALE validates gameobject templates before registration. Entry 0 fails validation since no template exists with that ID.

**Changes:**
1. Add `entry != 0 &&` check before `GetGameObjectTemplate` validation (2 locations)

```bash
# Idempotent check: only patch if wildcard not present
grep -q "entry != 0 && !eObjectMgr->GetGameObjectTemplate" "$FILE" || {
    sed -i 's/if (!eObjectMgr->GetGameObjectTemplate(entry))/\/\/ entry 0 = wildcard (Issue 307)\n                if (entry != 0 \&\& !eObjectMgr->GetGameObjectTemplate(entry))/g' "$FILE"
}
```

**See:** `docs/patches/ale-gameobject-wildcard.md` for full implementation details.

### B004: upstream-warning-fixes

**Files:** Multiple files in `mod-playerbots/` and `mod-ale/`
**Issue:** 333 - Upstream code produces ~1137 compiler warnings
**Reason:** Clean build improves code quality and makes real issues easier to spot.

**Warning Categories Fixed (~650):**
- 500: NextAction deprecated copy assignment (`Action.h`)
- 119: MovementActions.h signed/unsigned loop
- 13: ItemCountValue.h unused parameter
- 12: PositionInfo deprecated copy assignment
- 3: CraftData deprecated copy assignment
- 3: UnitPosition deprecated copy assignment
- 2: PlayerMethods.h signed/unsigned comparison

**Not Fixed (~490):**
- 442: boost unary_function deprecated (boost 1.74 → needs 1.81+)
- 40: HunterActions.h unused params (4 locations, low priority)
- 3: Arrow.h initializer order (requires verifying member declaration order)
- ~5: Scattered individual warnings

**Boost Note:**
Current boost version: **1.74** (2020)
The `unary_function` deprecation was fixed in boost **1.81** (2022).
Upgrading boost would eliminate 442 warnings.

**See:** `docs/patches/upstream-warning-fixes.md` for detailed implementation.

### B005: accuracy-level-cap

**Files:** `src/server/game/Entities/Unit/Unit.h`, `Unit.cpp`
**Issue:** 156 - Monster accuracy level cap
**Reason:** Cap level difference impact on hit/miss at ±3 levels for flatter combat curve.

**Changes:**
1. Add `ACCURACY_LEVEL_CAP` and `ACCURACY_SKILL_CAP` defines to Unit.h
2. Cap `levelDiff` in `MagicSpellHitResult()` at ±3
3. Cap `skillDiff` in `MeleeSpellMissChance()` at ±15 (3 levels × 5 skill/level)
4. Cap `skillBonus` in `RollMeleeOutcomeAgainst()` at ±15

**See:** `docs/patches/accuracy-level-cap.md` for detailed implementation.

### B006: ale-sell-item-hook

**Files:** `mod-ale/*/Hooks.h`, `LuaEngine.h`, `PlayerHooks.cpp`, `Handlers/ItemHandler.cpp`
**Issue:** 403 (was 150) - ALE sell item hook
**Reason:** Allow Lua scripts to react to vendor sales for treasure pool recycling.

**Changes:**
1. Add `PLAYER_EVENT_ON_SELL_ITEM = 74` to Hooks.h
2. Add `OnSellItem()` declaration to LuaEngine.h
3. Add `OnSellItem()` implementation to PlayerHooks.cpp
4. Add `sALE->OnSellItem()` calls to ItemHandler.cpp

**See:** `docs/patches/ale-sell-item-hook.md` for detailed implementation.

### B007: ale-unit-methods

**Files:** `mod-ale/*/UnitMethods.h`, `LuaFunctions.cpp`
**Issue:** 332 - ALE unit methods patch
**Reason:** Bot behaviors need walking animation and faction hostility checks.

**Changes:**
1. Add `SetWalk()`, `IsWalking()`, `IsHostileTo()`, `IsFriendlyTo()` to UnitMethods.h
2. Register methods in LuaFunctions.cpp

**See:** `docs/patches/ale-unit-setwalk.md` for detailed implementation.

### B008: mod-talent-bonus

**Files:** (symlink) `modules/mod-talent-bonus`
**Issue:** 120 - Talent points system
**Reason:** Server validates expected talent points on login; module adjusts count for bonus points.

**Changes:**
1. Create symlink from `modules/mod-talent-bonus/` to `source-beta/modules/mod-talent-bonus/`

**See:** `docs/patches/ale-calculate-talents-hook.md` for module details.

---

## Adding a patch

1. Take the next free number of its kind (`B###`, `E###`, `C###`; a
   per-profile variant of a setting is `Cnnna`, `Cnnnb`).
2. Write `patches/<ID>-<name>.sh` or `config/patches/<ID>-<name>.sh`: an
   idempotent apply and, for a source patch, an exact undo (multi-line
   insertions wrapped in `// {{{ B###-name ... // }}} B###-name` markers so
   the undo removes them by marker). Read the `upstream-patch-system`
   skill first.
3. Give it its header: `scripts/add-patch-header <file> --profiles "..."`.
   The header is what puts it on a profile; nothing else lists it.
4. `scripts/generate-patch-lists`, so this page and the profile pages list
   it (the compile's quick tests stop until they do).

### Design Principles

1. **Idempotent** — apply and unapply are safe to re-run.
2. **Self-contained** — each patch/unpatch pair is independent.
3. **One-to-one targeting** — N upstream errors = N anchored apply seds +
   N anchored inverse seds. Broad seds corrupt clean source.
4. **Failure-safe** — bash traps ensure cleanup on build failure.

The hand-kept tables and the description of the old three-stage design
this page held until 2026-10-20 are in `profile-patch-history.md`.
