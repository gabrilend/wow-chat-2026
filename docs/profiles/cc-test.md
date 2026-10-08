# cc-test Profile

**One-line summary:** The custom client's test server ("custom client
test"): stock AzerothCore with only the playerbots and ALE modules, so a
failure seen by the custom client points at the client or at one test
scene, not at the game's own customisations.

Design and build record: issue 176 (the profile), 176a (test scenes, the
patches that set up a situation to test), 176a1 (the first scene: a full
Alterac Valley match).

## What you get

- **The stock game.** No level-cap change (80), stock movement speed, stock
  fall damage, no custom items, no ambushes, travellers or buddies. The
  run-speed patch every other profile takes is gated away from this one.
- **Playerbots and the Lua engine.** The playerbots module plays the bots a
  scene places (the Alterac Valley stand-ins); mod-ale runs scene scripts
  from `src/lua-cc-test/` (empty until the first scene).
- **No random bots.** A scene places the bots it needs; a wandering
  population would walk into scenes and change their logs.
- **Players log in as players.** GM level 0 on login, so a test character
  meets every check an ordinary player meets.
- **Warden kicks.** A failed Warden check (the server asking the client a
  question only the real client answers correctly) ends the session,
  instead of only being logged. Until the custom client answers Warden,
  every session ends in a kick (issue 176, open question 5).
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

A cc-test build links only mod-playerbots and mod-ale, even though the
shared source tree holds other profiles' modules: the compile script
switches every other module folder off for this profile.

## Checking it without a server

| What | Command |
|---|---|
| every config value the profile promises | `scripts/test-profile-config-gates <project> cc-test` |
| the modules each profile builds | `scripts/test-compile-module-set <project>` |
| its source patches apply and revert cleanly | `scripts/test-source-patches <project> cc-test` |
| its patched files compile | `scripts/test-patched-syntax <project> cc-test` |
| what it resolves to (tree, modules, pins) | `scripts/profiles` |

## Related

- [index.md](index.md) — every profile, and how to switch
- `issues/176-cc-test-profile.md` — the table of everything the name resolves to
- `config/patches/C033-cc-test-warden-kicks.sh` — the Warden setting
