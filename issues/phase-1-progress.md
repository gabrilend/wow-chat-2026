# Phase 1 Progress: Foundation & Tooling

## Effect

The server runs. Developers can work on the project.

## Status: Mostly Complete

## Goal

Establish a functional development environment: build scripts, database setup,
configuration management, and developer tooling. Everything needed before
gameplay systems can be implemented.

---

## Issues

Ordered by narrative arc. Number-order is preserved from history; the
table-order below reflects dependency / blocking relationships. Where
the two diverge, the **Notes** column calls out blockers.

### Act 1 — The server runs (foundational)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 101 | verify-server-startup | In Progress | Substrate. Blocks every later issue. |
| 102 | test-playerbots-spawn | In Progress | Module loading verification. Blocks all bot work in Phase 6. |

### Act 2 — Knowledge is captured (documentation foundation)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 103 | configuration-documentation | Completed | docs/configuration.md established. |
| 104 | lua-script-ownership | Completed | src/lua/ established as project's Lua home. |
| 110 | concept-catalog-consolidation | Reopened | First pass done (1000→800 concepts). Second pass open: CLAUDE.md still duplicates catalog entries 146, 633-634, 638-646. Moved back out of completed/. |

### Act 3 — Local data substrate
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 105 | project-local-database | Completed | MySQL 9.6.0 local install. Required by every DB-touching system. |

### Act 4 — Build pipeline (the engine that builds the engine)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 108 | adaptive-build-parallelism | Completed | Auto-detect nproc for make. |
| 109 | incremental-rebuild-detection | Completed | `update --force` flag. |
| 112 | patch-staleness-detection | Completed | Source vs patch mtime. Blocks 127. |
| 127 | patch-system-improvements | Implemented | Built on 112. (was issue 334) |

### Act 5 — Profile model (canonical truth)
The keystone. Every later build/profile decision derives from 136.
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 136 | canonical-profile-definitions | Open | **Keystone.** alpha/release/beta semantics. Supersedes 129, 133. (was 412) |
| 129 | release-to-beta-transition | Superseded | Earlier transition plan, replaced by 136. Archived to completed/. (was 400) |
| 133 | profile-transition-system | Superseded | Earlier transition spec, replaced by 136. Archived to completed/. (was 405) |
| 130 | verify-release-baseline | Open | Validation step for release profile. (was 402) |
| 131 | incremental-patch-integration | Open | Promote-from-beta workflow. Depends on 136. (was 403) |
| 134 | alpha-baseline-setup | Open | Pin alpha to old AC commit + eluna. Depends on 136. (was 406) |
| 132 | alpha-playerbots-working | Invalidated | Per 136 alpha has no playerbots. Kept for traceability. (was 404) |
| 135 | release-profile-build-fixes | Open | Cleanup after 136 lands. (was 408) |
| 138 | sql-profile-switch-rollback | Deferred Low | Move-to-archive-table approach. Not started. (was 414) |

### Act 6 — Build pipeline correctness
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 115 | shadow-build-setup | Completed | Shadow build dir exists; previously marked "Will Not Implement" but file lives in completed/ — reconcile. |
| 122 | atomic-shadow-builds | Open | Compile-or-keep-old, no half-states. (was 327) |
| 137 | shadow-conf-path-baked-into-binary | Open | CONF_DIR was baked to shadow path; fix in scripts/compile applied 2026-04-28. (was 413) |
| 145 | playerbots-compile-fix-patches-B009-B010 | Open | Register B009/B010 in PHASE_BEGIN_PATCHES for release+beta. Discovered during rebuild prep audit. |
| 146 | patch-status-command | Open | Report what patches are scheduled for the active profile across PHASE_BEGIN/END/CONFIG. Downstream of 127's three-tier model. |
| 147 | alpha-mysql-instance-isolation | Open (deferred low) | Stand up mysql-alpha/ on port 3308 so alpha can run its declared isolation. Activates when alpha is actually run. |
| 114 | remove-profile-system | Will Not Implement | Decision: keep profiles for isolation. |

### Act 7 — Networking & ops
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 113 | authserver-ip-caching | Completed | Replaced by DNS hostname; see issue's superseded-by note. |

### Act 8 — Configuration system
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 107 | credential-manager-script | Open | Secrets management. Blocks 119. |
| 111 | config-merge-script | Open | Merge config changes across rebuilds. |
| 119 | config-value-orchestrator | Completed | Config management. Depends on 107. |
| 106 | ingame-config-control-board | Open | Parent: full in-game config dashboard. |
| 106a | read-only-config-dashboard | Open | View phase. Blocks 106b. |
| 106b | runtime-config-modifications | Open | Modify phase. Depends on 106a. |
| 106c | config-persistence-layer | Open | Save phase. Depends on 106b. |

### Act 9 — Repository hygiene & dev ergonomics
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 116 | git-branch-consolidation | Open | Clean up legacy branches. |
| 121 | mysql-script-naming-aliases | Open | Verb-first vs noun-first script names. (was 321) |
| 120 | parallel-update-status-spinners | Open | Better build feedback. |
| 128 | script-command-history | Open | Per-script history. (was 411) |
| 126 | upstream-warning-fixes | Open | Suppress AzerothCore upstream noise. (was 333) |

### Act 10 — Visualization & dev tools
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 117 | visual-powerline-mapping-tool | Open | Code-flow visualizations. |
| 118 | point-line-definition-tools | Open | Dungeon waypoint editor. |
| 123 | html-source-tree-export | Open | Static HTML site of source/issues/docs. (was 327) |
| 124 | wimmelbilder-embedding-artwork | Open | Depends on 123. (was 328) |

### Act 11 — Research / experimental
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 125 | algorism-priority-scheduler | Open | Research only; future architecture. (was 329) |

### Act 12 — Latecomers (slotted at end of Phase 1)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 139 | recreate-missing-sql-files | Open | Reconstruct custom SQLs that became orphaned in DB. (was 167) |
| 140 | branch-based-azerothcore-versioning | Implemented (Superseded) | Original profile-system spec. **Superseded by 136.** Infrastructure still active. (was 201) |
| 152 | profile-rename-basic-and-expert | Open | vanilla → basic, release → expert, after the OSR D&D box sets. Renames directories, databases, config-patch gates, and the `.profile` switch. 136 gets the new names when it lands. |

### Act 13 — Vanilla profile (148 cluster)
The vanilla ruleset (WotLK 3.3.5a, level-40 cap, level-20 start,
playerbots). Phase-1-tagged as a profile-model slice; tracked here.
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 148 | vanilla-profile-default-wotlk-playerbots | In Progress | Parent. Install wiring in place; sub-issues in flight. |
| 148a | disable-death-knights | **Completed** | One config knob (ClassMask 32) blocks player creation AND bot generation; 0 DK bots verified in the vanilla fleet. |
| 148h | class-specific-starting-equipment | Implemented | Kit clone/tune/loot-sweep SQL + first-login hook incl. weapon-proficiency pretrain. Pending 148o in-client validation. |
| 148j | pretrain-level-20-abilities | Implemented | 287-row trainer-spell pretrain SQL built. Apply/validate pending. |
| 148k | ale-auto-equip-starter-kit | Implemented | First-login strip + equip + ammo + hearth hook. |
| 148n | vanilla-racial-starting-zones | Live | Per-race spawn spread, innkeeper-anchored coords; hearth binds + bot fleet moved. |
| 148o | vanilla-spawn-and-kit-validation-pass | In Progress | 52 race×class reroll matrix; blockers cleared, matrix not yet run. |
| 148i | remove-all-flight-paths | **Completed** | Flightmaster flag cleared network-wide; 69 hand-authored per-NPC flavor lines (EK + Kalimdor); applied + verified live. |
| 148l | vanilla-mount-level-requirements | Open | Low-priority flavor. |
| 148q | vanilla-starting-professions | Open | QoL; generator not built. |
| 148s | vanilla-playerbots-start-in-148h-kit | Open | Consistency; not built. |
| 148t | starting-town-racemate-npcs | Open | 148n follow-up; race-flavored town NPC reskins. |
| 148v | cloned-kit-items-render-invisible | Open (cause known, fix decided) | Fresh mage logs in with no gear on the model and "?" icons. All 51 clones carry their originals' displayid, so the kit SQL is fine — the client has simply never cached entries in the 2000000 range and only fetches item data when an event prompts it. **Decision 2026-08-07: revert to editing the original entries in place**, reversing 148h's clone design. The clones never contained the world-wide retune anyway, since the loot sweep pointed all thirteen tables at them. |
| 148w | mage-level-20-spell-gap | Open (cause confirmed) | **`PlayerStart.CustomSpells = 0`** in the vanilla worldserver.conf, and `Player::LearnCustomSpells()` returns immediately when it is false. All 717 pretrain rows have never been read, by anything, on any boot. Fix is one config patch. Also corrected 148j's schema section, which documented `race`/`class` columns that do not exist (the table is racemask/classmask bitmasks). |
| 148g | class-combination-modifier-system | Promoted → 716 | Redirect stub; moves to completed/ when 716 ships. |
| 148b–f, 148m, 148p | (various) | Declined | Kept in issues/declined/ as record. |

Vanilla cluster: 2 completed (148a, 148i), 4 implemented/live
(148h/j/k/n), 2 in progress (148, 148o), 6 open, 7 declined/promoted.

148v and 148w were both found on the same character in the same
session and are both invisible to `scripts/validate-vanilla-starter-state`,
which reports all five of its checks passing. That is the more
interesting finding than either defect: the validator checks that rows
exist, and both failures are about what the client does with rows that
do exist. Strengthening it is an implementation step in 148w.

## Completed: 14/44 (2 Will Not Implement, 4 Superseded, 1 Invalidated, 1 Deferred Low)

---

## Completion Criteria

- [x] Server builds without errors
- [x] Server starts without crashes
- [x] MySQL databases accessible (local installation)
- [x] Lua scripts load and execute (ALE working)
- [x] Playerbots module loads
- [ ] Configuration viewable in-game
- [ ] Configuration modifiable at runtime
- [ ] Developer tooling complete

---

## Key Files

### Scripts
- `scripts/azerothcore` - Main server management script
- `scripts/start-mysql` - Start local MySQL
- `scripts/stop-mysql` - Stop local MySQL
- `scripts/mysql-client` - Connect to local MySQL

### Configuration
- `config/beta/worldserver.conf` - World server settings
- `config/beta/authserver.conf` - Auth server settings
- `config/beta/playerbots.conf` - Playerbot settings
- `config/beta/mod_ale.conf` - ALE settings

### Lua Scripts
- `src/lua/` - Game Lua scripts (Issue 104)
- `src/lua/periodic_events.lua` - Main event loop
- `src/lua/ambush.lua` - Monster spawning
- `src/lua/treasure.lua` - Chest spawning
- `src/lua/travel.lua` - Wandering NPCs

### Database
- `mysql/` - Local MySQL installation
- `mysql/databases/` - Data directory
- `mysql/conf/my.cnf` - MySQL configuration

### Documentation
- `docs/configuration.md` - Configuration reference (Issue 103)

---

## Dependencies

None - this is the foundation phase.

---

## Server Management

### Build Commands

```bash
# Full build (first time or after pulling changes)
./scripts/azerothcore update --force

# Update only if remote has changes
./scripts/azerothcore update

# Start servers
./scripts/azerothcore authserver
./scripts/azerothcore worldserver
```

### MySQL Commands

```bash
# Start MySQL (required before worldserver)
./scripts/start-mysql

# Connect to MySQL
./scripts/mysql-client

# Stop MySQL
./scripts/stop-mysql
```

### Database Credentials

- Host: localhost (via socket)
- Port: 3307
- User: ritz
- Password: (in secrets.conf)
- Databases: acore_auth, acore_world, acore_characters, acore_playerbots

---

## Profile System

Currently supports multiple build profiles:
- **beta** - Current development
- **release** - Stable snapshot
- **alpha** - Cutting edge (not yet used)

Each profile has isolated:
- `source-{profile}/` - AzerothCore source
- `build-{profile}/` - CMake artifacts
- `installed-files-{profile}/` - Compiled binaries
- `config/{profile}/` - Symlinks to configs

### Simplification Pending (318)

Profile system may be removed in favor of single build.
Reduces complexity, simplifies scripts.

---

## Notes

### MySQL Local Installation (105)

MySQL 9.6.0 compiled locally to avoid system conflicts:
- Binary: `mysql/installed-files/bin/mysql`
- Socket: `mysql/databases/mysql.sock`
- Config: `mysql/conf/my.cnf`

Fixed deprecated `innodb_log_file_size` for MySQL 9.x.

### Build Optimization (108, 109)

- MAKE_JOBS auto-detects to (nproc - 1)
- `update` checks remote before rebuilding
- `update --force` rebuilds unconditionally
- Saves 30+ minutes on no-change updates

### Config Dashboard (106a-c)

Planned three-phase implementation:
1. **106a**: Read-only view via chat commands and NPC
2. **106b**: Modify hot-reloadable settings live
3. **106c**: Persist changes to config files

---

## rmail Integration (Reference)

Phase 1 doesn't use rmail - it IS the substrate that makes rmail possible.
Every rmail service depends on this foundation existing and working.
See **Phase 10** for the full rmail treatment with design philosophy.

### Foundation as Substrate

rmail services require Phase 1 components:

| Component | Phase 1 Provides | rmail Requires |
|-----------|-----------------|----------------|
| ALE | Lua script execution | Hook scripts (on_receive, on_send, on_delete) |
| MySQL | Database access | Account table, character data, mail table |
| Server Process | Running worldserver | Event hooks, player sessions |
| Configuration | Settings files | Service ports, paths, credentials |

### What Each rmail Service Needs

| Service | Port | ALE Hooks | MySQL Tables | Config |
|---------|------|-----------|--------------|--------|
| accounts | 4562 | on_receive, on_delete | acore_auth.account | credentials |
| classes | 4662 | on_receive | (validation only) | class paths |
| mail | 4762 | on_receive, on_send | acore_characters.mail | poll interval |
| narrator | 4862 | on_receive, on_send | (memory only) | TTS settings |
| feedback | 4962 | on_receive | (file storage) | inbox path |

### The Invisible Layer

```
THOUGHT: Infrastructure is invisible when it works.

You don't think about MySQL when you're fighting wolves.
You don't think about ALE when a narrator speaks.
You don't think about the build system when submitting a class.

But take any piece away, and everything collapses.
No MySQL? No accounts. No characters. No mail.
No ALE? No hooks. No custom behavior. No rmail integration.
No server? No game.

Phase 1 is the silence that lets other sounds be heard.
The foundation doesn't speak. It holds.
```

### How Hooks Execute

When rmail delivers a message:

```
1. rmail writes file to game-mail/*/inbox/
2. rmail calls on_receive hook: lua script.lua sender subject filepath
3. ALE executes the Lua script
   └── Script reads message, parses content
   └── Script accesses MySQL via ALE bindings
   └── Script writes response to outbox
4. rmail picks up outbox files, delivers responses

All of this requires:
- ALE initialized (Phase 1)
- MySQL running (Phase 1)
- Lua scripts loadable (Phase 1)
- File permissions correct (Phase 1)
```

### Credential Flow

```
Phase 1: Foundation
    │
    ├── secrets.conf (database credentials)
    │       │
    │       ▼
    ├── MySQL (acore_auth, acore_characters)
    │       │
    │       ▼
    └── ALE (Lua execution environment)
            │
            ▼
Phase 10: rmail Services
    │
    ├── on_receive hooks read/write database
    ├── on_send hooks check delivery status
    └── on_delete hooks clean up accounts
```

### Failure Modes

When Phase 1 breaks, rmail fails:

| Failure | Symptom | rmail Impact |
|---------|---------|--------------|
| MySQL down | Connection refused | No accounts, no mail |
| ALE not loaded | Hooks don't fire | Messages arrive, nothing happens |
| Bad credentials | Access denied | Hooks can't read/write DB |
| Disk full | Write failures | Messages lost, queues corrupt |

```
THOUGHT: The foundation doesn't get credit. It gets blame.

When rmail works, players thank the narrator system.
When rmail breaks, they blame the server admin.

Phase 1 is maintenance. Backups. Monitoring. Restarts.
The unglamorous work that makes glamorous things possible.

Every THOUGHT in Phase 10 assumes Phase 1 exists.
Every diagram starts AFTER the server is running.
The foundation is the implicit first line of every story.
```

### Service Architecture (Preview)

| Service | Port | Foundation Dependencies |
|---------|------|------------------------|
| accounts | 4562 | MySQL (account table), ALE (hooks) |
| classes | 4662 | ALE (validation), filesystem (class files) |
| mail | 4762 | MySQL (mail table), ALE (hooks) |
| narrator | 4862 | ALE (hooks, speech events) |
| feedback | 4962 | Filesystem (inbox storage) |

For the full WHY behind rmail, see Phase 10's "Thoughts" sections.

---

## Related Phases

- All other phases depend on Phase 1
- Phase 2 requires ALE initialization fix (202, now in Phase 2)
- **Phase 10** - rmail services depend entirely on Phase 1 substrate
