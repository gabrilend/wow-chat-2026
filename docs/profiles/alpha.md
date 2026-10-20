# Alpha Profile

Pinned-old AzerothCore + the original mod-eluna scripting engine + the
wow-chat-1 Lua, kept as they were in the early project.

## What you get

A playable time-capsule of how the project looked before the
migration to playerbots and ALE. Alpha is not on the development
pipeline; it doesn't get features, it doesn't get bug fixes, it
doesn't drift with upstream. It's preserved so the wow-chat-1
design can be experienced in its original form for nostalgia.

The intended cadence is **roughly one week per year** as a holiday
special — pull alpha out of the closet, log in, play through the
original wow-chat-1 scripts, put it away again. Not for daily use.

What's here:

- **Pinned-old AzerothCore.** A specific commit from before the
  playerbots/ALE migration. The exact pin lives in
  `scripts/install` (currently TBD per issue 136 — alpha's source
  pin is still on a TODO list because the right "before the
  playerbots migration" commit hasn't been selected).
- **mod-eluna.** The original Lua engine, predecessor to ALE.
  Different API, different feature set. The wow-chat-1 scripts
  were written for this engine, not for ALE — they don't port
  cleanly to release/beta.
- **The wow-chat-1 Lua corpus.** Lives in `libs/wow-chat-1/`. **Do
  not modify** — these are the original Lua scripts from the
  previous version of the project, kept as a read-only reference
  so the alpha era can be reproduced faithfully. The placeholder
  `src/lua-alpha/` directory exists in case alpha-specific scripts
  ever need to be added on top of the wow-chat-1 corpus, but
  currently it's empty.
- **No playerbots.** The fork pinned for alpha pre-dates
  mod-playerbots integration. You play with whatever live players
  are also running alpha (presumably nobody, during the 51 weeks
  of the year alpha isn't in use).

What's NOT here:

- **No playerbots.** As above.
- **No ALE.** mod-eluna handles scripting on this profile.
- **No mod-grownup, mod-aoe-loot, mod-solo-lfg, mod-fireworks.**
  None of the modules the current profiles ship with.

## Installed modules

- **mod-eluna** — the older Lua engine
- **mod-transmog** — character appearance customization (a
  wow-chat-1 era addition)

Per CLAUDE.md / issue 136, alpha is meant to be a frozen reference,
so additions to this module set should be deliberate and rare.

## Isolation from other profiles

Alpha is the most isolated profile:

- **Its own MySQL port (3308).** Release/beta/vanilla share port
  3307; alpha sits on a separate instance (see issue 147 — the
  port 3308 MySQL endpoint is still TBD). The pre-migration AC
  schema is incompatible with the current one, so a shared MySQL
  instance would risk cross-contamination.
- **Its own source tree (`source-alpha/`).** Release/beta/vanilla
  share `source-beta/`; alpha gets its own clone of the older fork.
- **Its own database names (`acore_*_alpha`).** Even within its
  own MySQL instance, the names are suffixed to make the
  isolation visible.
- **Its own port range (auth 4363, world 4463).** No collision
  possible with the current-tier profiles.

This isolation is the reason alpha can coexist with a running
release server on the same machine without breaking either.

<!-- patch-lists: begin. Written by scripts/generate-patch-lists from the patches' headers (issue 189f): edit a header, then run it; do not edit by hand. -->
## Patches

Every patch this profile takes, in the order the build runs them:
lowest priority first, each line its header's own (`scripts/plan-patches alpha`).

**Before the compile (source patches, taken off again once it is through):** none.

**After the compile and install (install steps and settings, mixed by priority):**

| priority | id    | kind     | about                                                                      |
| -------: | ----- | -------- | -------------------------------------------------------------------------- |
|     1040 | E004  | install  | Create RAM-backed log directory symlink                                    |
|     1060 | E006  | install  | Initialize config files (.dist -> .conf) and apply profile-specific values |
|     1100 | C001  | settings | Database Connections                                                       |
|     1105 | C002  | settings | Directory Paths                                                            |
|     1110 | C003  | settings | Run Speed 85% (named for its first value, 80%)                             |
|     1125 | C006a | settings | Max Level 80 (Alpha)                                                       |
|     1145 | C007a | settings | Starting Level 40 (Alpha)                                                  |
|     1160 | C008  | settings | GM Login State                                                             |
|     1170 | C010  | settings | Network Ports                                                              |
|     1175 | C011  | settings | Realmlist Setup                                                            |
|     1210 | C019  | settings | RealmID per profile                                                        |
|     1220 | C021  | settings | SOAP Loopback Console (remote command channel for local scripts)           |
|     1240 | C025  | settings | Client cache version follows the profile's content (issue 160)             |
|     1275 | C032  | settings | Preserve Custom Channels (so a script can tell one channel from another)   |
|     1285 | C034  | settings | No Faster Healing Below Level 15, on Every Server                          |

**After the databases are brought to upstream's state (our SQL):** none.
<!-- patch-lists: end -->

## How to switch to alpha

```bash
echo alpha > .profile
./scripts/install --profile alpha
# Start the alpha-specific MySQL instance (see issue 147 — not yet stood up)
# ./scripts/start-mysql-alpha
./scripts/authserver &
./scripts/worldserver
```

As of writing, the alpha MySQL instance on port 3308 is **not yet
operational** — see [issue 147](../../issues/147-alpha-mysql-instance-isolation.md)
for the work needed to stand it up. Running alpha currently
requires either spinning up that second MySQL or temporarily
pointing alpha at the shared 3307 instance with manually-renamed
databases.

## Where to ask for help

- The promotion pipeline rules (and why alpha is outside them):
  [`issues/136-canonical-profile-definitions.md`](../../issues/136-canonical-profile-definitions.md)
- Alpha MySQL setup: [`issues/147-alpha-mysql-instance-isolation.md`](../../issues/147-alpha-mysql-instance-isolation.md)
- The wow-chat-1 corpus: `libs/wow-chat-1/` (read-only reference)
- Current-tier profiles: [release.md](release.md), [beta.md](beta.md)
- Stock WoW + bots: [vanilla.md](vanilla.md)
- Profile system overview: [index.md](index.md)
