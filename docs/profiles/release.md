# Release Profile

**One-line summary:** The wow-chat custom design at its
proven-working tier — modern AzerothCore + AI playerbots + ALE Lua
engine, only the features that have graduated from beta.

## What you get

The production server intended for ongoing public play. The
wow-chat design layer is loaded, but only the parts that have been
hardened on beta and promoted up. Release is always a strict subset
of what beta does, which is what makes it the "guaranteed-working"
tier.

The wow-chat design itself is documented across many issue files
and the concept catalog
([`docs/concept-catalog.md`](../concept-catalog.md)). Briefly:

- **Empty world by default.** Monsters spawn around players via
  the ambush system rather than as static populations. Treasure
  spawns and traveler NPCs wander.
- **AI companion playerbots.** Same playerbots system as the other
  profiles, integrated with the ambush + travel logic.
- **ALE Lua engine.** The full wow-chat Lua corpus
  (`src/lua-beta/`) runs on this profile via mod-ale.
- **Per-level talent points and ability training.** Ability tomes
  granted by quests rather than only by trainers (see issue 405).

The release-specific cut of the wow-chat design is "what we know
works." For the in-flight experimental cut, switch to beta.

## Installed modules

- **mod-ale** — Lua scripting engine, runs the wow-chat corpus
- **mod-playerbots** — AI companion bots
- **mod-aoe-loot** — area loot for convenience
- **mod-grownup** — character model size scales with level

All four modules track upstream HEAD; release stays current with
upstream AzerothCore improvements.

## Promotion-pipeline position

Release sits at the bottom of the alpha → beta → release pipeline
(though chronologically it's the top — features graduate UP into
release from beta after proving out). A feature is in release if
and only if:

1. It exists in beta.
2. It has been observed working without crashes or regressions for
   long enough to trust.
3. It was explicitly promoted (config patches scope it to
   `release`, B-patches list it in `PHASE_BEGIN_PATCHES["release"]`,
   E-patches list it in `PHASE_END_PATCHES["release"]`).

If a feature is in beta and not yet in release, that's a
deliberate choice — it's still proving out. Don't run release if
you want the latest experimental thing; run beta.

<!-- patch-lists: begin. Written by scripts/generate-patch-lists from the patches' headers (issue 189f): edit a header, then run it; do not edit by hand. -->
## Patches

Every patch this profile takes, in the order the build runs them:
lowest priority first, each line its header's own (`scripts/plan-patches release`).

**Before the compile (source patches, taken off again once it is through):**

| priority | id   | kind   | about                                                                                       |
| -------: | ---- | ------ | ------------------------------------------------------------------------------------------- |
|      140 | B004 | source | Fix ~695 compiler warnings in upstream modules                                              |
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
|     1040 | E004  | install  | Create RAM-backed log directory symlink                                    |
|     1060 | E006  | install  | Initialize config files (.dist -> .conf) and apply profile-specific values |
|     1100 | C001  | settings | Database Connections                                                       |
|     1105 | C002  | settings | Directory Paths                                                            |
|     1110 | C003  | settings | Run Speed 85% (named for its first value, 80%)                             |
|     1115 | C004  | settings | Fall Damage 10x                                                            |
|     1120 | C005  | settings | Experience Rate 2x                                                         |
|     1130 | C006b | settings | Max Level 20 (Beta/Release)                                                |
|     1150 | C007b | settings | Starting Level 1 (Beta/Release/Basic)                                      |
|     1160 | C008  | settings | GM Login State                                                             |
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
|     1305 | C038  | settings | No Quest Sparkles, Object Quest Marks or Map Points                        |
|     1310 | C039  | settings | Instances and Battlegrounds: See as Far as the Server Allows               |

**After the databases are brought to upstream's state (our SQL):** none.
<!-- patch-lists: end -->

## How to switch to release

```bash
echo release > .profile
./scripts/install --profile release
./scripts/start-mysql
./scripts/authserver &
./scripts/worldserver
```

Release uses the shared `acore_*` databases on MySQL port 3307,
authserver port 4362, worldserver port 4462.

## Where to ask for help

- The promotion pipeline rules: [`issues/136-canonical-profile-definitions.md`](../../issues/136-canonical-profile-definitions.md)
- Active development tier: [beta.md](beta.md)
- Stock WoW + bots experience: [vanilla.md](vanilla.md)
- Historical snapshot: [alpha.md](alpha.md)
- The wow-chat design system overview: [`docs/concept-catalog.md`](../concept-catalog.md)
- Profile system overview: [index.md](index.md)
