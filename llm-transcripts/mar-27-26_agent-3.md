# Conversation Summary: agent-acf314b

Generated on: 2026-04-05 18:43:46

--------------------------------------------------------------------------------

### User Request 1

Explore this project to understand its current status. Look at:

1. The project structure and what it's for

2. Any vision or roadmap documents in docs/ or notes/

3. The issues/ directory structure and current issues

4. The phase progress file (issues/phase-1-progress.md)

5. Recent completed issues


Give me a comprehensive summary of what the project is, what phase it's in,
what's been completed recently, and what work remains.


--------------------------------------------------------------------------------

### Assistant Response 1

Perfect! Now I have a comprehensive understanding. Let me create a summary
report:


## Project Exploration Summary: WoW Chat 2


## Project Overview


**WoW Chat 2** is a resurrection of an earlier project that combines World of Warcraft (WotLK 3.3.5a) with a roguelike survival layer. It's fundamentally about creating a playground for friends to play together with AI companions in a dynamically-challenging environment. The core philosophy prioritizes **software design** over product - this is an exploration of custom game mechanics, scripting, and collaborative play.


**Vision**: A game to play with friends while talking, built on WoW with a survival-style game loop featuring timed ambushes, travelers, and treasure spawns. Difficulty scales with group size.


---


## Current Project Status


**Phase**: Phase 1 (Foundation) - **In Progress**


**Overall Phase 1 Completion**: 5 completed issues out of 9 core issues (55% complete)


---


## Architecture


The project follows a monorepo structure:


```

wow-chat-2/

├── source/ # AzerothCore source (cloned during install)

├── installed-files/ # Compiled server binaries

├── src/lua/ # THE SOUL - all custom game logic scripts

├── mysql/ # Local MySQL installation (project-scoped, port 3307)

├── docs/ # Documentation framework

├── notes/ # Vision and design documents

├── issues/ # Issue tracking with phase progress files

├── scripts/ # Build and maintenance utilities

├── data-files/ # Game data (maps, dbc, etc.) - 3.1GB, gitignored

└── logs/ # Runtime logs

```


**Key Components**:

- **AzerothCore**: WotLK emulator with Playerbot support

- **mod-eluna**: LuaJIT scripting engine (200+ event hooks)

- **mod-playerbots**: AI companion system

- **mod-aoe-loot**, **mod-grownup**: Quality-of-life and level scaling


---


## Completed Work (Phase 1)


### Issue 103: Document Configuration Options ✓

- Created comprehensive `docs/configuration.md`

- Documented 50+ modified worldserver.conf settings

- Organized by category: rates, movement, economy, PvP, instances, etc.

- Updated table-of-contents


### Issue 104: Migrate Lua Scripts from wow-chat-1 ✓

- Copied 13+ Lua scripts into `src/lua/` for full project ownership

- Scripts migrated from external `/home/ritz/games/` location

- Core game loop files:

- `periodic_events.lua` - Main event loop (ambush, treasure, traveller timers)

- `ambush.lua` - Enemy spawning and combat (22KB, complex system)

- `treasure.lua` - Level-scaled chest spawning

- `travel.lua` - NPC traveller system (36KB, largest)

- Supporting files: movement, tempo, death-knights, hearthstone, levelling,
merchants


### Issue 105: Setup Local MySQL Installation ✓

- MySQL 9.6.0 compiled and installed to `mysql/installed-files/`

- Database files at `mysql/databases/` with all paths project-local

- Three AzerothCore databases created: `acore_auth`, `acore_world`, `acore_characters`

- User `ritz` created with credentials from `secrets.conf`

- Working scripts: `mysql-start`, `mysql-stop`, `mysql-client`

- Fixed MySQL 9.x deprecated config options

- Uses port 3307 to avoid conflicts with system MySQL


### Issue 108: Thread Count Variable ✓

- MAKE_JOBS now auto-detects to `(nproc - 1)` - no manual config needed

- Leaves one core free for multitasking during builds

- Removed hardcoded `-j15` assumption


### Issue 109: Improve Update Command ✓

- Enhanced `azerothcore update` command

- Now checks for remote changes before rebuilding (saves 30+ minutes on unchanged code)

- Added `--force` flag to rebuild without remote changes (needed for first compile)

- Removed deprecated `scripts/update-2` script

- Update script now "just works" without manual configuration


---


## Currently Open Issues (Phase 1)


### Issue 101: Verify Server Startup (IN PROGRESS)

- **Status**: In Progress but blocked on binaries compilation

- **What's Done**: 

- Paths migrated from `/home/ritz/games/azeroth-core/` to project-local

- Config files (authserver.conf, worldserver.conf) updated to use `${DIR}` paths

- Database port changed to 3307 (local MySQL)

- Data files copied into project (3.1GB)

- MySQL dependency resolved (Issue 105)



- **What Remains**:

- Run `azerothcore install` to compile AzerothCore from source

- Start auth and world servers to verify startup

- Analyze Errors.log (4.7MB from Sep 2024) to understand previous issues

- Verify Eluna scripts load

- Verify playerbots module initializes


### Issue 102: Test Playerbots Spawn (OPEN)

- Depends on Issue 101 (server startup)

- Requires: Verify mod-playerbots compiled, check configuration, test `.bot` commands in-game


### Issues 106a, 106b, 106c: In-Game Config Control Board (SPLIT, OPEN)

- **106a**: Read-only dashboard (view settings via `.config` chat commands and NPC gossip)

- **106b**: Runtime modifications (change hot-reloadable settings live)

- **106c**: Persistence layer (save to files, backup/restore)

- Sub-issues must be completed in order due to dependencies

- Requires server to be running (Issue 101 dependency)


### Issue 107: Credential Manager Script (OPEN)

- Currently: Credentials hardcoded in `scripts/azerothcore` (MySQL user `ritz`, password `menardi`)

- Goal: Create `scripts/credentials` self-modifying script

- Implement `cred_get()` and `cred_set()` functions

- Needs to create backups before modifications

- Actual credentials file should be gitignored; only `.dist` template in version control


---


## Recent Git History


```

90d1812 feat(103,106,107,108): Complete config docs, add credential manager,
split config issues

05b057d feat(105): Complete local MySQL installation setup

8e0b262 feat(105,106): Add secrets pattern, MySQL scripts, and config control
board issue

86b61b3 feat(104): Migrate wow-chat-1 Lua scripts and update project structure

3db5dda feat(104): Create issue for migrating wow-chat-1 Lua scripts

3bd871e feat: Initialize wow-chat-2 project

```


---


## Phase 1 Milestones Progress


| Milestone | Status |

|-----------|--------|

| Installation script functional | ✓ Complete |

| Update script functional | ✓ Complete |

| Server runs without errors | ❌ Blocked (needs Issue 101) |

| Playerbots module operational | ❌ Blocked (needs Issue 101) |

| Documentation complete | ✓ Complete |


---


## Uncommitted Changes


The working directory has uncommitted changes that appear to be completing
Issues 108 and 109:

- `issues/108-thread-count-variable` - moved to `issues/completed/`

- `issues/109-add-build-mode-to-azerothcore-script` - moved to `issues/completed/`

- `issues/phase-1-progress.md` - updated with completion notes

- `scripts/azerothcore` - modified with MAKE_JOBS auto-detection and improved update command


These changes are staged in git but not yet committed.


---


## Key Documentation Files


- **notes/vision** - Project vision and core experience

- **docs/roadmap.md** - 5-phase development plan (currently in Phase 1)

- **docs/architecture.md** - System components and data flow

- **docs/configuration.md** - 50+ settings reference

- **docs/scripting.md** - Eluna Lua API reference

- **docs/installation.md** - Setup procedures

- **docs/table-of-contents.md** - Doc hierarchy and navigation


---


## Next Steps (Recommended Priority Order)


1. **Issue 101** (Verify Server Startup) - Compile binaries and start servers to
establish baseline

2. **Issue 102** (Test Playerbots) - Verify bot spawning and commands work

3. **Issue 107** (Credential Manager) - Extract hardcoded credentials into
secure script

4. **Issue 106a** (Read-Only Config Dashboard) - Add `.config` chat commands and
NPC interface

5. **Issue 106b** (Runtime Config Modifications) - Enable hot-reload for
tweakable settings

6. **Issue 106c** (Config Persistence) - Save/restore configuration to files


Phase 1 will be complete when all issues are resolved and a demo script is
created showing server startup and basic functionality.


--------------------------------------------------------------------------------
