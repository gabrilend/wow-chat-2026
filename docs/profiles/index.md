# Server Profiles

This project supports six server profiles, each delivering a
distinct play experience while sharing most of the underlying
infrastructure. Pick whichever fits your mood:

| Profile | One-liner | Detailed page |
|---------|-----------|---------------|
| **basic** | The level 1–60 development baseline — stock game + playerbots + QoL, rotating faction starting valleys, Outland open at the cap, level-64 early Outland dungeons | [basic.md](basic.md) |
| **cc-test** | The custom client's test server — stock AzerothCore + playerbots + ALE only, no random bots, Warden kicks, for test scenes (176) | [cc-test.md](cc-test.md) |
| **vanilla** | Default WotLK 3.3.5a + AI companion playerbots, light ruleset (level 40 cap, start at 20, no flight paths, full level-20 starter kit) | [vanilla.md](vanilla.md) |
| **release** | The wow-chat custom design at its proven-working tier — modern AzerothCore + playerbots + ALE Lua, only features that have graduated from beta | [release.md](release.md) |
| **beta** | Active-development tier — release baseline plus every in-flight feature, all source patches applied | [beta.md](beta.md) |
| **alpha** | Holiday relic — pinned-old AzerothCore + mod-eluna, the original wow-chat-1 corpus, ~1 week per year | [alpha.md](alpha.md) |

## How profiles work

The active profile lives in a single file: `.profile` at the project
root. The contents are exactly one of `basic`, `cc-test`, `vanilla`,
`alpha`, `release`, `beta` followed by a newline. Switching profiles is one command:

```bash
echo vanilla > .profile
```

Every script in `scripts/` reads `.profile` to decide which install
directory, source tree, and database namespace to operate on. So
`scripts/install`, `scripts/authserver`, `scripts/worldserver` all
respect the active profile without needing flags.

To list the profiles and their pinned (or HEAD-tracking)
upstream sources:

```bash
./scripts/profiles
```

## Two design axes, not one

The profiles aren't a linear ladder. They form two independent axes:

- **Promotion pipeline** (alpha → beta → release): a feature is
  written in beta, hardened against bugs, and graduates to release
  only after proving out. Release is always a strict subset of beta.
  Alpha sits outside this for historical reasons (it's the
  pre-pipeline snapshot).
- **Vanilla branch** (just vanilla): a parallel ruleset. It doesn't
  participate in the promotion pipeline because it's a different
  design — playerbots + light tunings rather than the full wow-chat
  custom layer. Vanilla shares infrastructure with beta/release
  (same source tree, same MySQL port) but its own ruleset, database
  namespace, and Lua corpus.

If you're new to the project, **start with vanilla**. It's the
closest to a stock WoW 3.3.5a experience and the most likely to
make sense without context. Move to release once you want the
wow-chat design layer.

## Infrastructure shared across profiles

Read from the scripts on 2026-10-08 (`config/patches/C001`, `C010`,
`C019`, `patches/E-patches.sh`); `scripts/test-profile-config-gates
<project> <profile>` reads the written values back for basic and cc-test.

| Resource | basic | cc-test | vanilla | release | beta | alpha |
|---|---|---|---|---|---|---|
| Source tree | `source-beta/` | `source-beta/` | `source-beta/` | `source-beta/` | `source-beta/` | `source-alpha/` |
| MySQL port | 3307 | 3307 | 3307 | 3307 | 3307 | 3308 |
| Auth server port | 4362 | 4362 | 4362 | 4362 | 4362 | 4363 |
| World server port | 4462 | 4462 | 4462 | 4462 | 4462 | 4463 |
| Realm id | 5 | 6 | 3 | 1 | 2 | 4 |
| Auth database | `acore_auth` | `acore_auth` | `acore_auth` | `acore_auth` | `acore_auth` | `acore_auth_alpha` |
| World database | `acore_world_basic` | `acore_world_cc_test` | `acore_world_vanilla` | `acore_world` | `acore_world` | `acore_world_alpha` |
| Character database | `acore_characters_basic` | `acore_characters_cc_test` | `acore_characters_vanilla` | `acore_characters` | `acore_characters` | `acore_characters_alpha` |
| Playerbots database | `acore_playerbots_basic` | `acore_playerbots_cc_test` | `acore_playerbots_vanilla` | `acore_playerbots` | `acore_playerbots` | n/a |
| Install dir | `installed-files-basic/` | `installed-files-cc-test/` | `installed-files-vanilla/` | `installed-files-release/` | `installed-files-beta/` | `installed-files-alpha/` |
| Lua scripts dir | `src/lua-basic/` | `src/lua-cc-test/` | `src/lua-vanilla/` | `src/lua-beta/` | `src/lua-beta/` | `src/lua-alpha/` |

The five profiles built from `source-beta/` share one login server port
and one game server port (issue 136a), so one of them runs at a time; the
realm list names every profile and marks the running one online. Alpha
runs on its own port range and its own MySQL instance (port 3308; not yet
stood up). (Until 2026-10-08 this table gave vanilla its own ports, 4364
and 4464, and its own account database; 136a had replaced both.)

## Canonical reference

The promotion pipeline rules, the rationale for each profile's
existence, and the protocol for adding a fifth profile (should that
ever happen) live in
[`issues/136-canonical-profile-definitions.md`](../../issues/136-canonical-profile-definitions.md).
This documentation page summarises that issue for end users.

## Related documentation

- [`docs/installation.md`](../installation.md) — first-time setup
- [`docs/configuration.md`](../configuration.md) — config options
- [`docs/architecture.md`](../architecture.md) — system architecture
- [`docs/ale/`](../ale/) — ALE Lua scripting API (beta/release/vanilla)
- [`docs/playerbots/`](../playerbots/) — playerbot module docs
