# cc-test Profile

**One-line summary:** The custom client's test server ("custom client
test"): stock AzerothCore with only the playerbots, ALE and buddy modules, so
a failure seen by the custom client points at the client or at one test
scene, not at the game's own customisations.

Design and build record: issue 176 (the profile), 176a (test scenes, the
patches that set up a situation to test), 176a1 (the first scene: a full
Alterac Valley match).

## What you get

- **The stock game.** No level-cap change (80), stock movement speed, stock
  fall damage, no custom items, no ambushes or travellers, no buddy
  selector (no player picks buddies here). The
  run-speed patch every other profile takes is gated away from this one.
- **Playerbots and the Lua engine.** The playerbots module plays the bots
  a scene places (the Alterac Valley stand-ins); mod-ale runs scene scripts
  from `src/lua-cc-test/` (empty until the first scene).
- **No random bots.** A scene places the bots it needs; a wandering
  population would walk into scenes and change their logs.
- **Players log in as players.** GM level 0 on login, so a test character
  meets every check an ordinary player meets.
- **Warden failures logged.** Warden is the server asking the client
  questions only the real client answers correctly. For now a wrong answer
  is only written to the log, which lists what the custom client still
  gets wrong; once the client answers Warden, a wrong answer will end the
  session (`config/patches/C033-cc-test-warden-kicks.sh`).
- **The buddy module.** It makes the Alterac Valley scene's stand-ins the
  way it makes buddies, with its data (roster, area centres, beds, town
  circles, gearsets) read from basic's sources. Not the buddy selector
  NPCs, and no other change to the stock world.
- **Its own databases** (`acore_world_cc_test`, `acore_characters_cc_test`,
  `acore_playerbots_cc_test`; the account database `acore_auth` is shared),
  so test characters are made and wiped without touching anyone's play.

## Running it

It shares the login and game ports of basic, vanilla, beta and release,
so it runs instead of them, not beside them. The realm list shows it as
`cc-test` (realm 6) and marks whichever profile is running as online.

```bash
echo cc-test > .profile
./scripts/install            # first time: clones what's missing, builds, makes the databases
./scripts/authserver
./scripts/worldserver
```

A cc-test build links only mod-playerbots, mod-ale and mod-buddies, even
though the shared source tree holds other profiles' modules: the compile
script switches every other module folder off for this profile.

## Checking it without a server

| What | Command |
|---|---|
| every config value the profile promises | `scripts/test-profile-config-gates <project> cc-test` |
| the modules each profile builds | `scripts/test-compile-module-set <project>` |
| its source patches apply and revert cleanly | `scripts/test-source-patches <project> cc-test` |
| its patched files compile | `scripts/test-patched-syntax <project> cc-test` |
| what it resolves to (tree, modules, pins) | `scripts/profiles` |

<!-- patch-lists: begin. Written by scripts/generate-patch-lists from the patches' headers (issue 189f): edit a header, then run it; do not edit by hand. -->
## Patches

Every patch this profile takes, in the order the build runs them:
lowest priority first, each line its header's own (`scripts/plan-patches cc-test`).

**Before the compile (source patches, taken off again once it is through):**

| priority | id   | kind   | about                                                                                       |
| -------: | ---- | ------ | ------------------------------------------------------------------------------------------- |
|      120 | B002 | source | Add ALE OnLogin hook to playerbots bot login                                                |
|      140 | B004 | source | Fix ~695 compiler warnings in upstream modules                                              |
|      300 | B020 | source | Add LOCK_ALE to ALEEventProcessor::RemoveEvent                                              |
|      320 | B022 | source | A --conf-dir option for the servers and dbimport, over the compiled-in module config folder |
|      360 | B026 | source | Fix the bot-login Engine::Init crash (dangling strategy on duplicate add)                   |
|      370 | B027 | source | Guard Engine::Init against a strategy with a stale/foreign bot facade                       |
|      460 | B036 | source | Build the project's buddy module (mod-buddies) into the worldserver                         |
|      470 | B037 | source | Playerbots: a switch for the group invite at a bot's login                                  |
|      520 | B042 | source | A bot says "AI was reset to defaults" only when asked to reset                              |
|      540 | B044 | source | Companion accounts: their characters are not in /who and can't be friended                  |
|      550 | B045 | source | Playerbots: a bot on a companion account takes no chat commands                             |
|      560 | B046 | source | Playerbots: buddies judge gear by their own talent plan and roll                            |
|      570 | B047 | source | Creature outfits: a creature can look like a dressed player character                       |
|      580 | B048 | source | Buddies don't whisper their owner about failed item moves                                   |
|      600 | B050 | source | Playerbots: a buddy weighs spirit by what it heals                                          |
|      620 | B052 | source | Playerbots: a buddy's long walk never ends in a teleport                                    |
|      640 | B054 | source | The server accepts navigation tiles built by version 19 of the                              |
|      660 | B056 | source | Bots see only as far as they act                                                            |
|      670 | B057 | source | The most any view distance may be, as a setting                                             |

**After the compile and install (install steps and settings, mixed by priority):**

| priority | id   | kind     | about                                                                      |
| -------: | ---- | -------- | -------------------------------------------------------------------------- |
|     1010 | E001 | install  | Create symlinks from install dir to the profile-specific Lua source        |
|     1040 | E004 | install  | Create RAM-backed log directory symlink                                    |
|     1060 | E006 | install  | Initialize config files (.dist -> .conf) and apply profile-specific values |
|     1100 | C001 | settings | Database Connections                                                       |
|     1105 | C002 | settings | Directory Paths                                                            |
|     1160 | C008 | settings | GM Login State                                                             |
|     1170 | C010 | settings | Network Ports                                                              |
|     1175 | C011 | settings | Realmlist Setup                                                            |
|     1195 | C016 | settings | Missing server config keys                                                 |
|     1210 | C019 | settings | RealmID per profile                                                        |
|     1220 | C021 | settings | SOAP Loopback Console (remote command channel for local scripts)           |
|     1230 | C023 | settings | Basic: No Random Bots                                                      |
|     1240 | C025 | settings | Client cache version follows the profile's content (issue 160)             |
|     1250 | C027 | settings | Basic: Buddies Spend Their Own Talents                                     |
|     1260 | C029 | settings | Basic: Buddies Keep Their Own Parties                                      |
|     1265 | C030 | settings | Basic: No Group Invite at a Buddy's Login                                  |
|     1275 | C032 | settings | Preserve Custom Channels (so a script can tell one channel from another)   |
|     1280 | C033 | settings | cc-test: Warden Kicks on a Failed Check                                    |
|     1285 | C034 | settings | No Faster Healing Below Level 15, on Every Server                          |
|     1310 | C039 | settings | Instances and Battlegrounds: See as Far as the Server Allows               |

**After the databases are brought to upstream's state (our SQL):**

| priority | id   | kind | about                                                                      |
| -------: | ---- | ---- | -------------------------------------------------------------------------- |
|     2720 | E042 | sql  | The buddy clan and roster tables (issue 617a1): each owner's companion     |
|     2740 | E044 | sql  | Every named area's borders and middle (issue 617e2), for the buddies'      |
|     2750 | E045 | sql  | The beds buddies sleep on in towns (issue 617e4), placed by hand in game   |
|     2800 | E050 | sql  | The world's little towns as circles (issue 617e4a): every cluster of       |
|     2820 | E052 | sql  | Every gearset profile (issue 617r: src/lua-basic/data/gearsets/*.lua) as   |
|     2830 | E053 | sql  | The `command` rows for the game master commands the project compiles in    |
|     2860 | E056 | sql  | The kept stand-ins (issue 617t1): one row per stand-in character the buddy |
<!-- patch-lists: end -->

## Related

- [index.md](index.md) — every profile, and how to switch
- `issues/176-cc-test-profile.md` — the table of everything the name resolves to
- `config/patches/C033-cc-test-warden-kicks.sh` — the Warden setting
