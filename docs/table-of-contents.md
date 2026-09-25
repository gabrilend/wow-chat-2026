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
│   ├── scripting.md               ALE Lua scripting reference
│   ├── roadmap.md                 Development phases and milestones
│   ├── balance-updates.md         Append-only log of knob/lever tweaks
│   ├── bot-governor.md            Host-load-driven bot population governor
│   ├── class-spells-level-1-20.md Class ability reference (levels 1-20)
│   ├── concept-catalog.md         Concepts 001-800
│   ├── concept-catalog-2.md       Concepts 801-1600
│   ├── concept-issue-map.md       Cross-reference: concepts to issues
│   ├── delta-guide.md             -> (symlink) Monorepo methodology
│   │
│   ├── addons/                    Client addon documentation
│   ├── ale/                       AzerothCore Lua Engine API docs
│   │   └── ale-integration-technical-report.md  Complete data flow analysis
│   ├── archive/                   Historical / one-shot transition docs
│   │   ├── migration-guide.md     Release-to-beta transition process
│   │   └── profile-transition-flow.md  Profile system rollout plan
│   ├── patches/                   C++ patch documentation
│   │   ├── patch-registry.md      Build patch system (BEGIN/END/CONFIG phases)
│   │   ├── accuracy-level-cap.md  Monster hit chance level cap
│   │   ├── no-crushing-blows-64.md  B031: no crushing blows from creatures level 64+
│   │   ├── ale-sell-item-hook.md  ALE hook for vendor sales
│   │   ├── ale-calculate-talents-hook.md  Talent calculation module
│   │   ├── ale-gameobject-wildcard.md  Entry 0 wildcard for gameobject events
│   │   ├── playerbots-ale-login-hook.md  Playerbots trigger PLAYER_EVENT_ON_LOGIN
│   │   ├── playerbot-bot-login-strategy-guard.md  B026: duplicate-login dangling strategy
│   │   ├── playerbot-engine-init-facade-guard.md  B027: corrupt strategy facade repair
│   │   ├── playerbot-vanilla-starter-kit.md  B025: vanilla bots spawn in the 148h kit
│   │   ├── upstream-warning-fixes.md  Fix 695+ compiler warnings in upstream modules
│   │   └── contributing-upstream.md   How to translate a B-patch into an upstream PR
│   ├── playerbots/                Playerbot module documentation
│   ├── profiles/                  Per-profile reference pages (user-facing)
│   │   ├── index.md               Overview of the four profiles + how to switch
│   │   ├── basic-gear-ladder.html Chart: vanilla raids, Outland dungeons and world drops on one stat-budget scale (155f/155k)
│   │   ├── vanilla.md             Default WotLK + playerbots, light ruleset (148)
│   │   ├── release.md             Wow-chat custom design, proven-working tier
│   │   ├── beta.md                Active development tier (all in-flight features)
│   │   └── alpha.md               Holiday relic — wow-chat-1 + mod-eluna snapshot
│   └── wiki/                      AzerothCore wiki mirror
│
├── notes/
│   ├── vision                     Project vision and goals
│   ├── claude-md-asides.md        Writing lifted out of CLAUDE.md when it was trimmed
│   ├── todo-file-asides.md        Writing preserved from the root todo/new-issue files
│   ├── vision-enchanting-system-update.md  Layered, level-scaling enchantments
│   ├── vision-medal-encounters.md  Optional bosses gated by marginal stats (resilience, etc.)
│   ├── phase-3-custom-spells.md   Custom spell system design (moved from docs/)
│   ├── topology-behavior-system.md Behavior-graph design notes
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
│   ├── phase-7-progress.md        Phase 7: ...
│   ├── 1xx-*.md                   Phase 1 issues
│   ├── 2xx-*.md                   Phase 2 issues
│   ├── 3xx-*.md                   Phase 3 issues
│   └── completed/                 Resolved issues archive
│       └── demos/                 Phase demonstration scripts
│
├── tissues/                       Tasks for human expert analysis
│                                  (design, balance, narrative)
│
├── config/
│   └── patches/                   C-patches (post-promote config tuning)
│
├── src/
│   ├── lua/                       Custom Lua scripts (hot-reload)
│   │   ├── ambush.lua             Monster spawn system
│   │   ├── travel.lua             Traveler NPC wandering
│   │   ├── treasure.lua           Chest and loot system
│   │   ├── movement.lua           Movement utilities
│   │   ├── periodic_events.lua    Timer-based events
│   │   └── behaviors/             Playerbot behavior scripts
│   └── custom-class-json/         Custom class definitions
│
├── sql/
│   └── custom/                    Project-specific SQL
│       └── db_world/              World database modifications
│
├── patches/                       B-patches (pre-compile source patches)
├── libs/                          External libraries (boost, etc.)
├── modules/                       Custom module source (e.g. mod-talent-bonus)
├── scripts/                       Shell scripts
│   ├── switch                     Change active profile (.profile)
│   ├── install                    First-time install for current profile
│   ├── update                     Refresh source and rebuild
│   ├── compile                    Build only
│   ├── apply-patches              Run B/C-patch pipeline
│   ├── generate-configs           Regenerate .conf files from .dist
│   ├── promote                    Move shadow tree → installed-files-{profile}
│   ├── validate                   Smoke-test the shadow build
│   ├── verify-build               Post-install sanity check
│   ├── authserver                 Run authserver from installed-files-{profile}
│   ├── worldserver                Run worldserver from installed-files-{profile}
│   ├── start-mysql / stop-mysql   Project-local MySQL control
│   ├── extract-maps               Generate maps/vmaps/mmaps from client data
│   ├── install-client-addons      Sync client-side AIO addons
│   ├── redownload-source          Re-clone source-{profile}/
│   ├── keira                      Keira3 database editor
│   ├── export-html                Render docs as HTML
│   ├── find-issue-refs            Find cross-references to issue numbers
│   ├── update-issue-refs          Rewrite issue-number references after a migration
│   └── update-realmlist-ip        Update C011's realm address
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
8. **docs/scripting.md** - ALE Lua API quick reference
9. **docs/balance-updates.md** - Knob/lever tweak log

### Reference Documentation
10. **docs/class-spells-level-1-20.md** - Ability availability by class/level
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

### Historical Artifacts
20. **docs/archive/migration-guide.md** - Release-to-beta transition (complete)
21. **docs/archive/profile-transition-flow.md** - Profile system rollout plan (superseded by issue 136)

## Profile System

The project supports multiple version profiles. The active profile lives in
`.profile` at the project root. See
`issues/136-canonical-profile-definitions.md` for the canonical model:

- **alpha** — Legacy holiday relic; pinned old AzerothCore + wow-chat-1
  customs + mod-eluna. No playerbots, no ALE.
- **release** — Current AzerothCore + mod-ale + mod-playerbots. Public
  release target.
- **beta** — Release baseline + in-development custom features.

Each profile has isolated directories:
- `source-{profile}/` - AzerothCore source code
- `build-{profile}/` - CMake build directory
- `installed-files-{profile}/` - Compiled server
- `logs-{profile}/` - Runtime logs (RAM-backed via /tmp)

Switch profiles: `./scripts/switch beta`

## Adding New Documents

When creating new documentation:
1. Add the file to the appropriate directory
2. Update this table of contents
3. Commit with a message describing the new document

## External References

- AzerothCore Wiki: https://www.azerothcore.org/wiki/
- LuaJIT Reference: https://luajit.org/luajit.html
- rmail Repository: https://github.com/gabrilend/r-mail
