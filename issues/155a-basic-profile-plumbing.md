# 155a - Basic Profile Plumbing

## Status
- Created: 2026-09-23
- Phase: 1
- Parent: 155
- Priority: High — 155b and 155c cannot be tested until the name resolves.

## Current Behavior

**Built 2026-09-23; waiting on the owner's install run.** `basic` now
resolves in every row of the table below: the source-tree `case` blocks in
eight scripts, the repo/branch/pin/module tables in `scripts/profiles`,
`install`, `update`, `compile`, `switch`, the database-name composer
(`acore_*_basic`), C001, C002, C008 (admin login, like vanilla), C010
(shared ports), C019 and `scripts/set-active-realm` (realm 5, row
"Everland Ghostsong (basic)"), `scripts/verify-build`, `src/lua-basic/`
(README only) and `sql/basic/`. The config applier's printed summary now
lists every profile a gate names, and the Lua link step (E001) stops with
an error when a profile's Lua directory is missing, where it used to
create an empty one and carry on.

Found and fixed while doing this (each would have bitten the first basic
install):

- `scripts/install` dropped and recreated the MySQL user `ritz` on the
  first install of any profile, granting it only that profile's databases,
  so the other profiles lost access to theirs. It now creates the user only
  if missing and never drops it.
- `scripts/install` named databases `acore_world_${PROFILE}` for every
  profile, disagreeing with C001 for release/beta (which read the
  unsuffixed names). It now asks the same composer the patches use, and it
  also creates and grants the playerbots database, which it never did.
- `scripts/profiles` displayed the shared source tree as tracking HEAD
  while install/update pin it to 52f58186a533; the display now matches.

Still to do: the owner's install run creates the three databases (a fresh
AzerothCore base, per step 8) and the check in step 9.

The table below is the map of where a profile name is resolved (swept
2026-09-23). A profile missing from a row fails in one of two ways:

- **loudly**: a `case` statement with an error arm (the database-name
  composer in `patches/E-patches.sh`, `scripts/set-active-realm`), or an
  associative array lookup that comes back empty and stops a script;
- **silently**: a config patch whose profile gate never mentions the word
  just never runs, and the server boots with upstream defaults. That looks
  like a working server.

A profile is a single word (the contents of `.profile`) that many separate
pieces of machinery each look up in their own table:

| Machinery | Where | What vanilla resolves to |
|---|---|---|
| active selector | `.profile` | the word itself |
| source tree choice | `case` blocks in `scripts/compile`, `install`, `apply-patches`, `authserver`, `worldserver`, `switch`, `redownload-source`, and `config/patches/C002-directory-paths.sh` | `source-beta` |
| upstream repo, branch, pinned commit | `scripts/profiles`, `scripts/install`, `scripts/switch` | liyunfan1223 fork, `Playerbot` branch, unpinned |
| module list | `scripts/profiles`, `scripts/install`, `scripts/compile` | playerbots, solo-lfg, aoe-loot, fireworks-on-level, ale |
| profile listing / help text | loops `for p in vanilla alpha release beta` in `scripts/profiles`; echo lines in `scripts/switch` | — |
| database names | the database-name composer in `patches/E-patches.sh`; `config/patches/C001-database-connections.sh` | `acore_*_vanilla` |
| realm id | `config/patches/C019-realm-id.sh`, `scripts/set-active-realm` (id and realmlist row) | 3 |
| network ports | `config/patches/C010-network-ports.sh` | shares 4462 / 4362 with release and beta |
| build-verification arm | `scripts/verify-build` | the release/beta/vanilla arm |
| source-patch list, setup-step list | the two per-profile tables in `patches/patches.sh` | see 155c |
| Lua directory | the Lua symlink step (E001) links `src/lua-<profile>/`; it currently *warns and creates an empty dir* when the directory is missing | `src/lua-vanilla/` |
| SQL directories | `sql/<profile>/db_world`, `db_world.src`, `db_characters`, `db_characters.src` | `sql/vanilla/…` |
| installed tree, build dir, log dir | `installed-files-<profile>/`, `build-*`, `logs-<profile>` | `installed-files-vanilla/`, `logs-vanilla` |
| config-patch listing | the grouping loop in the config applier in `patches/E-patches.sh` prints only `all alpha beta release`, so vanilla-only patches are already missing from its printed summary | — |

## Intended Behavior

Owner's rule for sharing between servers (2026-09-23): "characters should be
separate between servers, but world databases are okay to share." Today
every profile with its own name has its own world and characters databases
(release and beta already share a world database). basic cannot share
vanilla's world database, because the two profiles edit the world
differently (quest masks, mentors, dungeon levels). What they share is
source SQL files (155c), not databases. The rule matters most for the
multi-machine deployment another session is planning (issue 157).

`basic` resolves in every row of the table above:

- source tree `source-beta`, same upstream fork, branch and pin as vanilla,
  same module list as vanilla;
- databases `acore_auth` (shared, as every profile shares it — verify in
  C001), `acore_world_basic`, `acore_characters_basic`,
  `acore_playerbots_basic`;
- realm id **5** (1–4 are release, beta, vanilla, alpha) and a realmlist row
  named `Everland Ghostsong (basic)`;
- the shared 4462 / 4362 ports, like vanilla (only one profile runs at a
  time);
- `src/lua-basic/` as a real directory with a README saying what belongs
  there. Vanilla's only script equips the starter kit, which basic does not
  have, so the directory starts empty of scripts;
- `sql/basic/` with the four subdirectories; 155c fills them.

The config applier's printed summary groups by every known profile, not
by a hard-coded four.

The Lua symlink step's create-an-empty-directory fallback becomes an error:
a missing Lua directory is a missing profile, and the owner's rule is that
fallbacks are errors.

## Suggested Implementation Steps

1. Re-run the sweep (`grep -rn vanilla scripts config patches`) and diff it
   against the table above; the table is the checklist, the sweep proves it is
   complete.
2. Add `basic` to each `case` block and associative array, next to `vanilla`.
3. Add `basic` to the database-name composer and to C001.
4. Add realm id 5 to C019 and to `set-active-realm`'s id table
   and realmlist rows.
5. Create `src/lua-basic/README.md`, `sql/basic/{db_world,db_world.src,db_characters,db_characters.src}/`.
6. Make the config applier's summary loop derive its profile list from the
   gates it just loaded.
7. Turn the Lua step's missing-directory warning into an error, with a
   message that names the profile and the directory it looked for.
8. Create the three databases. Seed them from a **fresh AzerothCore base**,
   not from vanilla's databases: vanilla's world database already holds
   cloned kit items, pretrain rows and relocated spawn points, and basic
   wants none of them.
9. The user runs install/compile for basic. Read back `.profile`-driven
   paths in the output: source tree, install dir, database names, realm id.

## Related Issues

- **155** parent
- **153a** explore plumbing — the same sweep; whichever lands second reuses
  the first's table
- **152** profile rename — adds `basic` to its sweep
- **136** canonical profile definitions

## Open Questions

- None.
