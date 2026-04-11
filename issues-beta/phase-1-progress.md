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

| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 101 | verify-server-startup | In Progress | Baseline validation |
| 102 | test-playerbots-spawn | Open | Module verification |
| 103 | document-configuration-options | Completed | Created docs/configuration.md |
| 104 | migrate-lua-scripts-from-wowchat1 | Completed | Copied to src/lua/ |
| 105 | setup-local-mysql-installation | Completed | MySQL 9.6.0 local |
| 106a | read-only-config-dashboard | Open | View settings in-game |
| 106b | runtime-config-modifications | Open | Change settings live |
| 106c | config-persistence-layer | Open | Save to files |
| 107 | credential-manager-script | Open | Secrets management |
| 108 | thread-count-variable | Completed | Auto-detect nproc |
| 109 | add-build-mode-to-azerothcore-script | Completed | --force flag |
| 111 | config-merge-script | Open | Merge config changes |
| 123 | visual-powerline-mapping-tool | Open | Code visualization |
| 144 | concept-catalog-consolidation | Completed | 1000→800 concepts |
| 145 | git-branch-consolidation | Open | Clean up branches |
| 166 | point-line-definition-tools | Open | Dungeon waypoint editor |
| 201 | branch-based-azerothcore-versioning | Open | Profile system |
| 318 | remove-profile-system | Open | Simplify to single build |
| 321 | mysql-script-naming-aliases | Open | Consistent script names |
| 323 | parallel-update-status-spinners | Open | Better build feedback |

## Completed: 6/20

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
- Phase 2 requires ALE initialization fix (130, now in Phase 2)
- **Phase 10** - rmail services depend entirely on Phase 1 substrate
