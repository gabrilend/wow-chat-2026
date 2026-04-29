# Documentation Table of Contents

## Project Root
```
wow-chat-2026/
├── docs/
│   ├── table-of-contents.md       [this file]
│   ├── architecture.md            System architecture and data flow
│   ├── configuration.md           Configuration options reference
│   ├── installation.md            Setup and installation guide (server)
│   ├── connection-guide.md        Player connection guide (client)
│   ├── rmail-integration.md       rmail setup for server services
│   ├── scripting.md               Lua scripting reference
│   ├── roadmap.md                 Development phases and milestones
│   ├── class-spells-level-1-20.md Class ability reference (levels 1-20)
│   ├── phase-3-custom-spells.md   Custom spell system design
│   ├── concept-catalog.md         Concepts 001-800
│   ├── concept-catalog-2.md       Concepts 801-1600
│   ├── concept-issue-map.md       Cross-reference: concepts to issues
│   ├── delta-guide.md             -> (symlink) Monorepo methodology
│   │
│   ├── addons/                    Client addon documentation
│   ├── ale/                       AzerothCore Lua Engine API docs
│   │   └── ale-integration-technical-report.md  Complete data flow analysis
│   ├── migration-guide.md         Release to beta transition process
│   ├── patches/                   C++ patch documentation
│   │   ├── patch-registry.md      Build patch system (BEGIN/MIDDLE/END phases)
│   │   ├── accuracy-level-cap.md  Monster hit chance level cap
│   │   ├── ale-sell-item-hook.md  ALE hook for vendor sales
│   │   ├── ale-calculate-talents-hook.md  ALE hook for talent calculation
│   │   ├── ale-gameobject-wildcard.md  Entry 0 wildcard for gameobject events
│   │   ├── playerbots-ale-login-hook.md  Playerbots trigger PLAYER_EVENT_ON_LOGIN
│   │   └── upstream-warning-fixes.md  Fix 695+ compiler warnings in upstream modules
│   ├── playerbots/                Playerbot module documentation
│   └── wiki/                      AzerothCore wiki mirror
│
├── notes/
│   ├── vision                     Project vision and goals
│   ├── wow-chat-2-ideas           Deferred feature ideas
│   ├── wow-chat-secretary         rmail secretary concept
│   ├── wow-chat-secretary-2       rmail secretary (cont.)
│   ├── Wow-chat-rumble-dungeon    Dungeon gameplay mode concept
│   ├── r-mail-improvements        rmail feature ideas
│   └── rmail-improvements-too     rmail feature ideas (cont.)
│
├── issues/
│   ├── phase-1-progress.md        Phase 1: Server Setup
│   ├── phase-2-progress.md        Phase 2: Behaviors and Systems
│   ├── phase-3-progress.md        Phase 3: World Immersion
│   ├── 1xx-*.md                   Phase 1 issues
│   ├── 2xx-*.md                   Phase 2 issues
│   ├── 3xx-*.md                   Phase 3 issues
│   └── completed/                 Resolved issues archive
│       └── demos/                 Phase demonstration scripts
│
├── issues-beta/                   Reorganized issue structure (9 phases)
│   ├── phase-structure.md         Phase definitions by resulting effect
│   └── completed/                 Resolved issues archive
│
├── config/
│   ├── beta/                      Beta profile configs (symlinks)
│   └── release/                   Release profile configs (symlinks)
│
├── src/
│   ├── lua/                       Custom Lua scripts (hot-reload)
│   │   ├── ambush.lua             Monster spawn system
│   │   ├── travel.lua             Traveler NPC wandering
│   │   ├── treasure.lua           Chest and loot system
│   │   ├── levelling.lua          XP and talent points
│   │   ├── movement.lua           Movement utilities
│   │   ├── periodic_events.lua    Timer-based events
│   │   └── behaviors/             Playerbot behavior scripts
│   └── custom-class-json/         Custom class definitions
│
├── sql/
│   └── custom/                    Project-specific SQL
│       └── db_world/              World database modifications
│
├── libs/                          External libraries (boost, etc.)
├── modules/                       Custom module source
├── scripts/                       Shell scripts
│   ├── azerothcore               Server management
│   ├── start-mysql               Start local MySQL
│   └── stop-mysql                Stop local MySQL
│
├── source-{profile}/              AzerothCore source per profile
├── build-{profile}/               CMake build artifacts per profile
├── installed-files-{profile}/     Compiled binaries per profile
├── logs-{profile} -> /tmp/...     Runtime logs (RAM symlink)
└── mysql/                         Local MySQL installation
```

## Document Hierarchy

### Core Documentation
1. **notes/vision** - Project purpose and direction
2. **docs/architecture.md** - Technical design overview
3. **docs/roadmap.md** - Development phases

### Operational Documentation
4. **docs/installation.md** - Server setup procedures
5. **docs/connection-guide.md** - Player client setup and security
6. **docs/rmail-integration.md** - rmail service configuration
7. **docs/configuration.md** - All server and script settings
8. **docs/scripting.md** - Lua API quick reference

### Reference Documentation
9. **docs/class-spells-level-1-20.md** - Ability availability by class/level
10. **docs/phase-3-custom-spells.md** - Custom spell system design
11. **docs/ale/** - Full ALE API documentation
    - **ale-integration-technical-report.md** - Server→ALE→Lua data flow, registry mechanics
12. **docs/playerbots/** - Playerbot configuration and commands
13. **docs/wiki/** - AzerothCore wiki (offline mirror)
14. **docs/patches/** - C++ modification documentation

### Concept Catalogs
15. **docs/concept-catalog.md** - Foundation through Workflow (001-800)
16. **docs/concept-catalog-2.md** - Social through Philosophy (801-1600)
17. **docs/concept-issue-map.md** - Concept-to-issue cross-reference

### Process Documentation
18. **docs/delta-guide.md** - Issue tracking methodology
19. **issues/phase-X-progress.md** - Phase completion tracking
20. **issues-beta/phase-structure.md** - 9-phase reorganization (by effect)

### Migration Documentation
21. **docs/migration-guide.md** - Release to beta transition process
22. **issues/129-release-to-beta-transition.md** - Master migration tracking (was 400; superseded by 136)
23. **issues/completed/115-shadow-build-setup.md** - Shadow build directory (was 401)
24. **issues/130-verify-release-baseline.md** - Baseline verification (was 402)
25. **issues/131-incremental-patch-integration.md** - Patch-by-patch integration (was 403)

## Profile System

The project supports multiple version profiles:
- **beta** - Current development (liyunfan playerbots fork)
- **release** - Stable June 2023 snapshot (wow-chat-1 compatible)
- **alpha** - Cutting edge (not yet implemented)

Each profile has isolated directories:
- `source-{profile}/` - AzerothCore source code
- `build-{profile}/` - CMake build directory
- `installed-files-{profile}/` - Compiled server
- `config/{profile}/` - Symlinks to installed config files

Switch profiles: `./scripts/azerothcore switch beta`

## Adding New Documents

When creating new documentation:
1. Add the file to the appropriate directory
2. Update this table of contents
3. Commit with message describing the new document

## External References

- AzerothCore Wiki: https://www.azerothcore.org/wiki/
- ALE Documentation: https://www.azerothcore.org/mod-ale/
- LuaJIT Reference: https://luajit.org/luajit.html
- rmail Repository: https://github.com/gabrilend/r-mail
