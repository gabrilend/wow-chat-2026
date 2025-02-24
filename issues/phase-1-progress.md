# Phase 1 Progress: Foundation

## Goal
Establish stable server environment with documented setup process.

## Status: In Progress

## Issues

| ID | Title | Status |
|----|-------|--------|
| 101 | verify-server-startup | In Progress |
| 102 | test-playerbots-spawn | Open |
| 103 | document-configuration-options | Completed |
| 104 | migrate-lua-scripts-from-wowchat1 | Completed |
| 105 | setup-local-mysql-installation | Completed |
| 106 | ingame-config-control-board | Open (split) |
| 106a | read-only-config-dashboard | Open |
| 106b | runtime-config-modifications | Open |
| 106c | config-persistence-layer | Open |
| 107 | credential-manager-script | Open |
| 108 | thread-count-variable | Completed |
| 109 | improve-update-command | Completed |

## Completed: 5/9 (5/12 including sub-issues)

## Phase Milestones

- [x] Installation script functional
- [x] Update script functional
- [ ] Server runs without errors
- [ ] Playerbots module operational
- [x] Documentation complete

## Notes

### 2025-02-24 - Issues 108, 109 Completed
- **108**: MAKE_JOBS now auto-detects to (nproc - 1), no config needed
- **109**: Improved `update` with `--force` flag and remote change detection
- `update` checks for remote changes before rebuilding (saves 30+ min)
- `update --force` rebuilds without requiring remote changes (for first compile)
- Removed deprecated `scripts/update-2` (all functionality now in main script)
- Script now "just works" - no manual configuration required

### 2026-01-29 - Issue 103 Completed
- Created comprehensive `docs/configuration.md` documenting all server settings
- Documented 50+ modified worldserver.conf settings organized by category
- Added path configuration, database settings, module configs, Lua script constants
- Updated `docs/table-of-contents.md` to include new document
- Documentation milestone achieved

### 2026-01-29 - Issue 105 Completed
- MySQL 9.6.0 compiled and installed locally to `mysql/installed-files/`
- Database initialized at `mysql/databases/` with all paths local to project
- AzerothCore databases created: acore_auth, acore_world, acore_characters
- User `ritz` created with credentials from secrets.conf
- Scripts verified working: mysql-start, mysql-stop, mysql-client
- Fixed deprecated innodb_log_file_size config option for MySQL 9.x
- Gitignore updated to properly handle MySQL runtime files

### 2025-01-29 - Issue 106 Split
- Split 106-ingame-config-control-board into three sub-issues for incremental delivery
- 106a: Read-only dashboard (view settings via chat commands and NPC)
- 106b: Runtime modifications (change hot-reloadable settings live)
- 106c: Persistence layer (save to files, backup/restore)
- Sub-issues must be completed in order due to dependencies

### 2025-01-28 - Project Initialization
- Converted existing project to monorepo structure
- Created documentation framework
- Created initial issue files for Phase 1
- Existing scripts (azerothcore, update) preserved and documented

### Pre-existing State
The project contained functional installation and update scripts before
monorepo initialization. Server binaries appear to have been built previously
(Sep 2024 timestamps on logs). LuaJIT libraries present in installed-files/share/.

## Next Steps

1. Complete 101-verify-server-startup to establish baseline
2. Address any errors found in Errors.log
3. Proceed with 102-test-playerbots-spawn
4. ~~Document findings in 103-document-configuration-options~~ (Done)
5. Begin 106a-read-only-config-dashboard for in-game config viewing

## Phase Completion Criteria

- All three issues resolved and in completed/
- Demo script verifies server can start and accept connections
- Configuration reference document exists
