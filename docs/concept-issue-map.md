# Concept-Issue Cross-Reference Map

Maps concepts from concept-catalog.md (001-1000) to issue files.

Generated: 2026-04-01

---

## Issue → Concepts

### 101-verify-server-startup
**Status:** In Progress | **Phase:** 1

Core server startup and initialization concepts.

| Concept | Title | Relevance |
|---------|-------|-----------|
| 011 | Isolation Principle | Project-local paths, port 3307 |
| 013 | AzerothCore Foundation | Base emulator being started |
| 014 | Eluna/ALE Scripting Engine | Script engine must initialize |
| 015 | Local MySQL Installation | Database must be running first |
| 028 | Directory: installed-files/ | Server binaries location |
| 029 | Directory: data-files/ | Game geometry (maps, vmaps) |
| 030 | Directory: logs/ | Runtime output destination |
| 033 | Directory: scripts/ | Startup scripts location |
| 037 | Phase 1: Foundation | Parent phase for this issue |
| 042 | Issue 101 | Self-reference |
| 181 | ALE Initialization | Lua engine startup |
| 182 | OnBeforeConfigLoad Hook | Early init hook |
| 183 | OnBeforeWorldInitialized Hook | Late init hook |
| 184 | Lua Script Directory | Where ALE loads scripts |
| 236 | Database Port | 3307 configuration |
| 237 | Data Directory | Game files path |
| 238 | Logs Directory | Log output path |
| 239 | Source Directory | AzerothCore source |
| 240 | Build Directory | CMake output |
| 241 | Installed Files Directory | Final binaries |
| 269 | worldserver.conf | Main config file |
| 270 | authserver.conf | Auth config file |
| 601 | AzerothCore Hook System | Event interception |
| 602 | WorldScript Registration | Hook attachment |
| 603 | OnBeforeConfigLoad Hook | Config init |
| 604 | OnBeforeWorldInitialized Hook | World init |
| 614 | Database Connection | MySQL connection |
| 724 | Build Script: azerothcore | Server management |
| 725 | Build Script: mysql-start | Database startup |
| 739 | Server Startup Sequence | MySQL → auth → world |
| 740 | Server Shutdown Sequence | Graceful termination |
| 741 | Log Analysis | Error diagnosis |
| 742 | Error Log Review | Historical problems |
| 743 | Console Output Monitoring | Live debugging |
| 744 | Client Connection Testing | Port verification |
| 745 | Module Loading Verification | Console messages |
| 746 | Lua Script Loading Verification | Script status |
| 800 | Initialization Testing | Startup correctness |

---

### 102-test-playerbots-spawn
**Status:** Open | **Phase:** 1

Bot spawning and AI behavior verification.

| Concept | Title | Relevance |
|---------|-------|-----------|
| 008 | Playerbots as Core Feature | Central design pillar |
| 016 | mod-playerbots Module | Module being tested |
| 043 | Issue 102 | Self-reference |
| 254 | Playerbots: Bot Spawn Settings | Spawn configuration |
| 255 | Playerbots: AI Behavior Toggles | Behavior config |
| 256 | Playerbots: Party Formation | Position rules |
| 272 | mod_playerbots.conf | Config file |
| 639 | Group System Integration | Party management |
| 750 | Bot Spawn Testing | Validation process |

---

### 103-document-configuration-options
**Status:** Completed | **Phase:** 1

Configuration documentation and reference creation.

| Concept | Title | Relevance |
|---------|-------|-----------|
| 044 | Issue 103 | Self-reference |
| 201-250 | Configuration Constants | All tunable parameters |
| 257 | Config Categories | Organizational structure |
| 269 | worldserver.conf | Main config file |
| 270 | authserver.conf | Auth config file |
| 271 | mod_ale.conf | Lua engine config |
| 272 | mod_playerbots.conf | Bot config |
| 273 | mod_aoe_loot.conf | Loot config |
| 274 | mod_grownup.conf | Scaling config |
| 281 | Category Descriptions | Help text |
| 282 | Setting Descriptions | Inline docs |
| 283 | Units Display | Measurement clarity |
| 284 | Range Display | Valid range |
| 289 | Configuration History | Change tracking |
| 299 | Configuration Documentation | Auto-generated docs |
| 721 | Documentation Updates | Keeping docs current |

---

### 104-migrate-lua-scripts-from-wowchat1
**Status:** Completed | **Phase:** 1

Lua script migration from original project.

| Concept | Title | Relevance |
|---------|-------|-----------|
| 009 | Scriptable Everything | Design principle |
| 020 | The Soul: src/lua/ | Destination directory |
| 021 | periodic_events.lua | Main loop script |
| 022 | ambush.lua | Combat system |
| 023 | treasure.lua | Reward system |
| 024 | travel.lua | NPC wandering |
| 025 | movement.lua | Position math |
| 026 | tempo.lua | Pacing utilities |
| 027 | wow-chat-survival/waves.lua.vision | Future content |
| 036 | libs/wow-chat-1/ | Source (reference impl) |
| 045 | Issue 104 | Self-reference |
| 185 | Script Load Order | Dependency ordering |
| 186 | VimFold Conventions | Code style |
| 627 | Lua Script Loading | Module import |
| 628 | Global Table | Shared namespace |
| 629 | Local Scope | Encapsulation |
| 630 | Module Pattern | API export |
| 697 | Package Integration | require() usage |
| 847 | wow-chat-1 Ancestry | Historical reference |
| 924 | Reference Implementation | Original scripts |

---

### 105-setup-local-mysql-installation
**Status:** Completed | **Phase:** 1

Project-local MySQL database setup.

| Concept | Title | Relevance |
|---------|-------|-----------|
| 011 | Isolation Principle | Self-contained database |
| 015 | Local MySQL Installation | Core of this issue |
| 031 | Directory: mysql/databases/ | Data location |
| 046 | Issue 105 | Self-reference |
| 236 | Database Port | 3307 |
| 242 | MySQL Executable Path | Binary location |
| 614 | Database Connection | Connection pooling |
| 619 | MySQL Schema | Database structure |
| 620 | creature_template Table | Creature definitions |
| 621 | character Table | Player data |
| 622 | acore_world Database | World definitions |
| 623 | acore_characters Database | Character data |
| 624 | acore_auth Database | Account data |
| 625 | acore_playerbots Database | Bot data |
| 725 | Build Script: mysql-start | Startup script |
| 761 | Database Optimization | Query efficiency |
| 769 | Connection Pooling | Connection reuse |
| 770 | Sharding Strategy | Data distribution |
| 772 | Backup Strategy | Data safety |

---

### 106-ingame-config-control-board (Parent)
**Status:** Open | **Phase:** 1

In-game configuration interface (parent issue).

| Concept | Title | Relevance |
|---------|-------|-----------|
| 047 | Issue 106 | Self-reference |
| 048 | Issue 106a | Read-only sub-issue |
| 049 | Issue 106b | Runtime modification sub-issue |
| 050 | Issue 106c | Persistence sub-issue |
| 257-266 | Config Commands | Chat interface |
| 264 | NPC Configuration Terminal | Gossip interface |
| 267 | Hot-Reload Support | Dynamic changes |
| 268 | Restart-Required Settings | Static changes |
| 293 | Runtime Variable Access | Lua reads config |
| 294 | Runtime Variable Modification | Lua writes config |
| 295 | Configuration Events | Change callbacks |
| 653 | Gossip System Integration | NPC menus |
| 943 | Config Future | Long-term vision |

---

### 106a-read-only-config-dashboard
**Status:** Open | **Phase:** 1

View configuration without modification.

| Concept | Title | Relevance |
|---------|-------|-----------|
| 048 | Issue 106a | Self-reference |
| 257 | Config Categories | Category organization |
| 258 | Chat Command: .config | Help entry point |
| 259 | Chat Command: .config list | Category enumeration |
| 260 | Chat Command: .config show | Value inspection |
| 264 | NPC Configuration Terminal | Gossip interface |
| 281 | Category Descriptions | Help text |
| 282 | Setting Descriptions | Setting details |
| 283 | Units Display | Measurement units |
| 284 | Range Display | Valid ranges |
| 285 | Current vs Default | Comparison view |
| 293 | Runtime Variable Access | Read from Lua |
| 383 | Command Registry | Chat command registration |
| 612 | OnChat Event | Command parsing |
| 653 | Gossip System Integration | NPC menus |

---

### 106b-runtime-config-modifications
**Status:** Open | **Phase:** 1

Modify configuration at runtime.

| Concept | Title | Relevance |
|---------|-------|-----------|
| 049 | Issue 106b | Self-reference |
| 261 | Chat Command: .config set | Mutation command |
| 267 | Hot-Reload Support | Immediate effect |
| 276 | Visual Feedback on Config Change | Success/failure |
| 277 | Confirmation Dialogs | Dangerous changes |
| 278 | Setting Validation | Value checking |
| 280 | Setting Dependencies | Cascading requirements |
| 294 | Runtime Variable Modification | Lua writes config |
| 295 | Configuration Events | OnConfigChange callback |
| 747 | Hot-Reload Testing | Validation process |

---

### 106c-config-persistence-layer
**Status:** Open | **Phase:** 1

Save configuration changes to files.

| Concept | Title | Relevance |
|---------|-------|-----------|
| 050 | Issue 106c | Self-reference |
| 262 | Chat Command: .config reload | Reload from files |
| 263 | Chat Command: .config save | Save to files |
| 265 | Configuration Backup | Pre-modify backup |
| 266 | Configuration Restore | Rollback capability |
| 286 | Export Configuration | Full config export |
| 287 | Import Configuration | Config restore |
| 288 | Configuration Diff | Compare configs |
| 289 | Configuration History | Change tracking |
| 300 | Configuration Migration | Version upgrades |

---

### 107-credential-manager-script
**Status:** Open | **Phase:** 1

Secure credential management.

| Concept | Title | Relevance |
|---------|-------|-----------|
| 051 | Issue 107 | Self-reference |
| 737 | Credential Management | Secrets pattern |
| 878 | No Secrets in Git | Security principle |
| 854 | DIR Variable Pattern | Script structure |
| 855 | Script Documentation | CEO-level description |

---

### 108-thread-count-variable
**Status:** Completed | **Phase:** 1

Configurable parallel build threads.

| Concept | Title | Relevance |
|---------|-------|-----------|
| 052 | Issue 108 | Self-reference |
| 243 | Thread Count Detection | nproc auto-detect |
| 279 | Default Values | Sensible defaults |
| 724 | Build Script: azerothcore | Script being modified |
| 729 | Make Parallel Build | -j flag usage |

---

### 109-add-build-mode-to-azerothcore-script
**Status:** Completed | **Phase:** 1

Debug/Release build mode selection.

| Concept | Title | Relevance |
|---------|-------|-----------|
| 053 | Issue 109 | Self-reference |
| 244 | Build Mode: Debug | Full symbols |
| 245 | Build Mode: Release | Full optimization |
| 246 | Build Mode: RelWithDebInfo | Default mode |
| 724 | Build Script: azerothcore | Script being modified |
| 728 | CMake Configuration | Build system |

---

### 200-incremental-feature-restore
**Status:** In Progress | **Phase:** 2

Restore stashed features incrementally.

| Concept | Title | Relevance |
|---------|-------|-----------|
| 003 | Ambush Timer (40s) | Core system to restore |
| 004 | Traveller Timer (130s) | Core system to restore |
| 005 | Treasure Timer (100s) | Core system to restore |
| 006 | Rest Mechanic | Core system to restore |
| 007 | Group Scaling | Core system to restore |
| 021 | periodic_events.lua | Entry point |
| 022 | ambush.lua | Combat system |
| 023 | treasure.lua | Reward system |
| 024 | travel.lua | NPC wandering |
| 025 | movement.lua | Position math |
| 026 | tempo.lua | Pacing |
| 036 | libs/wow-chat-1/ | Reference implementation |
| 054 | Issue 200 | Self-reference |
| 055-100 | Ambush System Concepts | All ambush mechanics |
| 101-112 | Gesture Command System | Behavior system |
| 113-122 | Consensus/Momentum | Bot behavior |
| 123-133 | Level Affinity System | Bot clustering |
| 140-157 | Healer Ping-Pong | Bot movement |
| 370 | Feature Restore Checklist | Migration tracking |
| 706 | Stash for WIP | Stash management |
| 707 | Stash Recovery | Selective restoration |
| 927 | Incremental Restore | One feature at a time |
| 928 | Test After Restore | Validation |
| 929 | Commit After Test | Quality gate |

---

### 329-mmap-route-precomputation
**Status:** Open | **Phase:** 3 | **Merge-Oriented:** 162

Precomputed A* pathfinding with path relaxation for dungeon navigation.

| Concept | Title | Relevance |
|---------|-------|-----------|
| 162 | Issue 162 (dungeon-rail-pathfinding) | Merge target |
| 401-420 | A* Algorithm | Core pathfinding |
| 421-430 | Path Relaxation | Gradient descent on smoothness |
| 431-440 | Tile Grids | Hex/square mmap sampling |
| 113-122 | Consensus/Momentum | Player proximity effect |
| 024 | travel.lua | Wandering integration |
| 025 | movement.lua | Position utilities |
| 055-100 | Ambush System | Spawn zone awareness |
| 126 | Issue 126 (dungeon-room-spawn-zones) | Room detection |
| 161 | Issue 161 (bot-wandering) | Integration point |
| 166 | Issue 166 (point-line-definition) | Visualization |

---

## Concept → Issues (Reverse Lookup)

Quick reference for finding which issues touch a concept.

### Foundation Layer (001-100)

| Range | Concept Group | Issues |
|-------|---------------|--------|
| 001-010 | Core Vision | 200 |
| 003-006 | Timers & Rest | 104, 200 |
| 008 | Playerbots | 102 |
| 011-015 | Infrastructure | 101, 105 |
| 016-019 | Modules | 101, 102 |
| 020-027 | Lua Scripts | 104, 200 |
| 028-036 | Directories | 101, 104, 105 |
| 037-054 | Phase 1 Issues | All Phase 1 issues |
| 055-100 | Ambush System | 200 |

### Behavior Systems (101-200)

| Range | Concept Group | Issues |
|-------|---------------|--------|
| 101-112 | Gesture Commands | 200 |
| 113-122 | Consensus/Momentum | 200 |
| 123-133 | Level Affinity | 200 |
| 140-157 | Healer Ping-Pong | 200 |
| 181-200 | ALE/Dev Process | 101, 104 |

### Configuration (201-300)

| Range | Concept Group | Issues |
|-------|---------------|--------|
| 201-235 | Constants | 103, 106, 200 |
| 236-246 | Paths & Build | 101, 105, 108, 109 |
| 247-256 | Game Settings | 102, 103 |
| 257-300 | Config System | 103, 106, 106a, 106b, 106c |

### Data Structures (301-400)

| Range | Concept Group | Issues |
|-------|---------------|--------|
| 301-330 | Player/NPC Data | 200 |
| 331-400 | Registries/Enums | 101, 103 |

### Algorithms (401-500)

| Range | Concept Group | Issues |
|-------|---------------|--------|
| 401-420 | A* Pathfinding | 329 |
| 421-430 | Path Relaxation | 329 |
| 431-440 | Tile Grids | 329 |
| 441-500 | Math/Algorithms | 200 (ambush math) |

### Visual/Aesthetic (501-600)

| Range | Concept Group | Issues |
|-------|---------------|--------|
| 501-600 | Documentation Style | 103 |

### System Integration (601-700)

| Range | Concept Group | Issues |
|-------|---------------|--------|
| 601-620 | Hooks & Database | 101, 105 |
| 621-700 | API Integration | 101, 102, 104 |

### Development Workflow (701-800)

| Range | Concept Group | Issues |
|-------|---------------|--------|
| 701-730 | Git & Build | 108, 109 |
| 731-780 | Testing | All issues |
| 781-800 | Quality | All issues |

### Philosophy (801-900)

| Range | Concept Group | Issues |
|-------|---------------|--------|
| 801-900 | Design Principles | (meta, applies to all) |

### The Thousand (901-1000)

| Range | Concept Group | Issues |
|-------|---------------|--------|
| 901-950 | Summary | All issues |
| 951-1000 | Technical Summary | 101, 200 |

---

## Statistics

| Issue | Concept Count | Status |
|-------|---------------|--------|
| 101-verify-server-startup | 42 | In Progress |
| 102-test-playerbots-spawn | 9 | Open |
| 103-document-configuration-options | 20+ | Completed |
| 104-migrate-lua-scripts-from-wowchat1 | 20 | Completed |
| 105-setup-local-mysql-installation | 18 | Completed |
| 106-ingame-config-control-board | 15 | Open |
| 106a-read-only-config-dashboard | 15 | Open |
| 106b-runtime-config-modifications | 10 | Open |
| 106c-config-persistence-layer | 10 | Open |
| 107-credential-manager-script | 5 | Open |
| 108-thread-count-variable | 5 | Completed |
| 109-add-build-mode-to-azerothcore-script | 6 | Completed |
| 200-incremental-feature-restore | 50+ | In Progress |
| 329-mmap-route-precomputation | 11 | Open |
| 346-authserver-public-ip-detection | 3 | Open |
| 347-linear-ability-scaling | 15+ | Open |

**Total unique concepts referenced:** ~200 (20% of first thousand)
**Most connected issue:** 200-incremental-feature-restore (touches most game systems)
**Most connected concepts:** 101, 200 series (infrastructure and config)

---

*End of Cross-Reference Map*
*Generated by Claude Code for Everland Ghostsong*
*2026-04-01*
