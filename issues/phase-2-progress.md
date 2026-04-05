# Everland Ghostsong - Phase 2 Progress: Behaviors and Systems

## Goal
Implement custom playerbot behaviors and game systems that create emergent gameplay.

## Status: In Progress

## Issues

### Core Systems
| ID | Title | Status |
|----|-------|--------|
| 120 | talent-points-level-20-cap | Completed |
| 121 | bounty-board-currency-system | Open |
| 122 | rebellious-attitudes-freedom-of-affairs | Open (placeholder) |
| 124 | randomize-ambush-spawn-interval | Completed |
| 125 | player-bot-behavior-commands | Open |
| 126 | dungeon-room-spawn-zones | Open |
| 127 | contextual-creature-spawns | Open (depends on 126) |
| 128 | embedding-based-creature-selection | Open (depends on 127) |
| 129 | portal-dimension-system | Open (Design Phase) |
| 130 | ale-initialization-hook-fix | Completed |

### Class Scaling & Training
| ID | Title | Status |
|----|-------|--------|
| 138 | death-knight-level-1-scaling | Implemented (needs testing) |
| 140 | quest-spells-to-trainers | Implemented (needs testing) |
| 141 | talent-tier-limit | Open |
| 142 | custom-spell-system | Open (Phase 3 prep) |
| 143 | proc-gem-system | Open (Phase 3 prep) |
| 155 | custom-class-selection-npc | Implemented (race-specific NPCs) |
| 157 | dynamic-trainer-spawning | Completed |

### Ambush System
| ID | Title | Status |
|----|-------|--------|
| 146 | clear-ambush-data-on-death | Completed |
| 147 | clear-traveller-data-on-despawn | Completed |
| 158 | ambush-aggro-and-corpse-movement | Implemented (needs testing) |

### C++ Patches
| ID | Title | Status |
|----|-------|--------|
| 150 | ale-sell-item-hook | Implemented (needs rebuild) |
| 156 | monster-accuracy-level-cap | Implemented (needs rebuild) |

### Treasure Chest Systems
| ID | Title | Status |
|----|-------|--------|
| 148 | treasure-chest-shared-loot | Implemented (per-player queue) |
| 149 | sold-items-to-treasure-pool | Ready (depends on 150 rebuild) |
| 151 | ability-tome-system | Partial (Lua done, needs SQL) |
| 152 | death-durability-system | Implemented |
| 153 | chest-vulnerability-mechanic | Implemented |
| 154 | multiplayer-chest-access | Implemented |
| 159 | custom-empty-loot-chest-templates | Implemented (SQL + Lua) |

### Playerbot Behaviors
| ID | Title | Status |
|----|-------|--------|
| 114 | behavior-find-monsters | Implemented |
| 115 | behavior-discuss-with-npc | Open |
| 116 | behavior-avoid-monsters | Implemented |
| 117 | behavior-sit-and-rest | Implemented |
| 118 | behavior-travel-to-unique-lands | Open |
| 119 | behavior-orbit-player | Implemented |
| 160 | behavior-system-integration | Implemented (needs testing) |
| 161 | bot-wandering-traveller-style | Open (design complete) |
| 162 | dungeon-rail-pathfinding | Open (design complete) |

## Completed: 2/10 core, 5/9 behaviors (4 open)

## Phase Milestones

### Core Systems
- [ ] Level 20 cap implemented
- [ ] Talent points every 1/3 level working
- [ ] Bounty board currency system functional
- [ ] Training currency for abilities

### Behaviors
- [ ] Find monsters behavior functional
- [ ] Bots interact with wandering NPCs
- [ ] Avoidance system integrated with travel.lua
- [ ] Bots rest during downtime
- [ ] Cross-zone exploration working
- [ ] Player orbit creates social opportunities

## Dependencies

Phase 2 depends on:
- Phase 1 completion (server stable, Lua scripts loading)
- Issue 113 (ambush monsters spawning) - needed for find_monsters to have targets
- travel.lua working (wandering NPCs for discuss behavior)

## Behavior Priority Order

1. **114 - Find Monsters** (core gameplay)
2. **116 - Avoid Monsters** (safety, used by others)
3. **117 - Sit and Rest** (polish, easy win)
4. **115 - Discuss with NPC** (social, needs travel.lua)
5. **118 - Travel to Unique Lands** (exploration)
6. **119 - Orbit Player** (social, lower priority)

## Notes

### 2026-04-05 - Custom Class Selection NPC (155)
- Race-specific selector NPCs: each race sees one of their own kind
- SQL: `source-beta/data/sql/custom/db_world/custom-class-selector-npcs.sql`
- NPC entries 900001-900011 (skipping 900009 for Goblin)
- Thematic names per race: Mysterious Guide (Human), Spirit Walker (Orc), etc.
- Lua updated: `spawnSelectorNPC()` uses `player:GetRace()` for entry lookup
- Gossip events registered for all 10 race-specific entries
- Trainer NPC entries shifted to 900021-900031 (avoid collision with selectors)
- **To deploy:** Run SQL file against acore_world, `.reload ale`

### 2026-03-31 - Behavior Implementations Started
- Created issue files 114-119 with detailed implementation steps
- Implemented find-monsters.lua: scans for hostiles, level-appropriate targeting, LoS checks
- Implemented avoid-monsters.lua: danger scoring, flee logic, escape vectors, safe path finding
- Implemented sit-and-rest.lua: resource monitoring, consumable usage, danger awareness
- Implemented orbit-player.lua: formation positioning, clump avoidance, state-aware radius
- All behaviors follow established style: vertical alignment, vim folds, dense configs
- Behaviors integrate: orbit-player calls avoid-monsters, sit-and-rest calls avoid-monsters
- talentpoints level 20 cap completed in levelling.lua with database persistence

### 2026-04-05 - Monster Accuracy Level Cap (156)
- Cap level/skill difference at ±3 levels for hit/miss calculations
- Modified Unit.h: Added `ACCURACY_LEVEL_CAP 3` and `ACCURACY_SKILL_CAP 15`
- Modified Unit.cpp:
  - `MagicSpellHitResult()`: Cap levelDiff at ±3
  - `MeleeSpellMissChance()`: Cap skillDiff at ±15
  - `RollMeleeOutcomeAgainst()`: Cap skillBonus calculation
- Result: High-level monsters are dangerous but hittable, low-level monsters retain some threat
- Does NOT cap damage/health/armor - only hit chance mechanics
- **To deploy:** Full rebuild required
- Patch doc: `docs/patches/accuracy-level-cap.md`

### 2026-04-05 - ALE Sell Item Hook (150)
- Added `PLAYER_EVENT_ON_SELL_ITEM = 74` to ALE
- Fires BEFORE item goes to buyback slot, allowing Lua to capture item data
- Modified files:
  - `modules/mod-ale/src/LuaEngine/Hooks.h` - event enum
  - `modules/mod-ale/src/LuaEngine/LuaEngine.h` - declaration
  - `modules/mod-ale/src/LuaEngine/hooks/PlayerHooks.cpp` - implementation
  - `src/server/game/Handlers/ItemHandler.cpp` - hook call sites
- **To deploy:** Full rebuild required (`cmake .. && make -j$(nproc) && make install`)
- Patch doc: `docs/patches/ale-sell-item-hook.md`
- Unblocks issue 149 (sold items to treasure pool)

### 2026-04-05 - Treasure Chest System Overhaul (148, 153, 154, 160)
- **Per-player queue distribution**: Items entering pool are immediately assigned to
  level-appropriate player queues using mancala-style fair distribution
- **Holder/searcher mechanics corrected**: Holder = first to interact (not chest spawner),
  holder logout = chest snaps shut (no searcher promotion)
- **Loot hiding from holder: COMPLETE**
  - Issue 160: Created 37 custom chest templates (900001-900037) with `data1=0`
  - SQL: `source-beta/data/sql/custom/db_world/custom-empty-loot-chests.sql`
  - Holder sees truly empty chest, searcher triggers loot injection
  - `Treasure.generateBaseLoot()` creates level-appropriate items
- Updated treasure.lua with: `Treasure.addToPool(itemId, itemLevel, count)`,
  `Treasure.playerQueues`, `Treasure.activeChests`, `Treasure.injectPendingLoot()`
- Test commands: `#pooladd <itemId> <itemLevel> [count]`, `#poolsize`, `#myqueue`
- Coordination between treasure.lua and chest-vulnerability.lua for delayed loot injection
- Status: Implemented, needs testing with multiple players
- **To deploy:** Run SQL file against acore_world, restart server

### 2026-04-05 - Ambush System Fixes (146, 158)
- Fixed corpse sliding: Added `MoveClear()` in `onCreatureDeath` to stop movement physics
- Fixed aggro lock-on: Added `SetAggroEnabled(true)` when player stands up after sitting
- Issue 146 (clear ambush data) was already partially implemented, now complete
- Issue 158 created to track the aggro re-enable and corpse movement bugs
- Root causes: aggro disabled during orbit mode but never re-enabled; MoveTo commands
  continued executing on corpses after death
- Status: Needs testing - kill ambush mobs, verify corpses stay in place

### 2026-04-05 - Behavior System Integration (160)
- **Restored behavior Lua files** from git (were deleted from working tree)
  - zone-consensus.lua, level-affinity.lua, orbit-player.lua, gestures.lua
  - find-monsters.lua, avoid-monsters.lua, sit-and-rest.lua, convoy.lua
- **Configured playerbots to defer movement to Lua**
  - Set all RPG weights to 0, Rest=100 in playerbots.conf
  - Playerbots idles while our Lua behaviors control movement
- **Added dispersion behavior** to zone-consensus.lua:
  - `LONELY_RADIUS = 200` yards - if no one nearby, move toward closest
  - `APPROACH_DISTANCE = 100` yards - how far to move toward others
  - `CLUMP_RADIUS = 15` yards - too close, disperse
  - `handleDispersion()` checks lonely/clumped before drift
- **Centralized periodic event management** in periodic_events.lua:
  - All bot behaviors now register through periodic_events.lua
  - Removed individual `RegisterPlayerEvent` calls from behavior files
  - Timer constants defined in one place:
    - `DELAY_BOT_ZONE_CONSENSUS = 3000` ms
    - `DELAY_BOT_LEVEL_AFFINITY = 5000` ms
    - `DELAY_BOT_SIT_AND_REST = 3000` ms
    - `DELAY_BOT_ORBIT_PLAYER = 2000` ms
    - `DELAY_BOT_FIND_MONSTERS = 5000` ms
  - `InitialLogin()` now branches: spawn events for players, behaviors for bots
  - Behavior files expose only their update functions:
    - zone-consensus.lua → `periodicUpdate(bot)`
    - level-affinity.lua → `periodicUpdate(bot)`, `trackLogin()`, `trackLogout()`
    - sit-and-rest.lua → `checkAndRest(bot)`
    - orbit-player.lua → `updatePosition(bot)`
    - find-monsters.lua → `scan(bot)`
- **Command blocking investigation** (C++ patch needed):
  - Playerbots security system gives masters ALLOW_ALL when in group
  - To block commands, need C++ patch to whitelist specific commands
  - Issue 160 documents proposed patch location in PlayerbotAI.cpp
- Status: Implemented, needs testing - observe bot dispersion

### 2026-04-02 - Quest Spells to Trainers (140)
- Created SQL file: `source-beta/data/sql/custom/db_world/quest-spells-to-trainers.sql`
- Adds quest-learned abilities to class trainers for levels 1-20
- Affected classes: Warrior, Paladin, Hunter, Rogue, Shaman, Warlock, Druid
- Fixed Stoneskin Totem spell ID (3599 → 8071)
- Created comprehensive `docs/class-spells-level-1-20.md` reference document
- Status: Needs testing - create characters and verify abilities appear at trainers

### 2026-04-01 - Issue 130/134 Merged
- Issue 134 (behavior scripts not loading) merged into 130 (ALE init fix)
- C++ fix was documented but never applied to source
- Lua-side fixes completed: load-behaviors.lua, behaviors/init.lua, file extensions
- Next step: apply C++ fix to source/modules/mod-eluna/src/ALE_SC.cpp, then rebuild

### 2026-03-31 - ALE Initialization Fix (130) - Investigation
- Diagnosed ALE not initializing - `OnBeforeConfigLoad` hook not firing
- Designed fix: move initialization to `OnBeforeWorldInitialized` hook
- Added guard checks to prevent crashes from uninitialized sALE calls
- Removed conflicting mod_eluna.conf file

### 2026-03-31 - Portal Dimension System Design (129)
- Created comprehensive design for unified portal/battleground system
- BG portals become shared dimension gates (no instancing)
- Faction portal rules: Horde/Alliance/Neutral
- Neutral portals lead to secret dimensions (GM Island, etc.)
- Dynamic aperture randomization when areas empty
- Dungeon map mirroring concepts documented
- Links to related issues: 126, 127, 128

### 2026-03-31 - Embedding System Design Enhanced
- Updated issue 128 with scalable equidistant selection
- Added diversity_factor parameter (0.0-1.0) for configurable spawn variety
- Designed percentile-based selection algorithm
- Referenced neocities similarity-engine.lua for cosine similarity patterns
- Added zone-specific diversity configuration (dungeons vs open world)
- Use cases documented: boss rooms (cohesive), open world (varied), horde mode (identical)

### 2025-03-31 - Phase 2 Issues Created
- Created 6 behavior issues for playerbot AI
- All behaviors integrate with existing movement.lua helpers
- Behaviors designed to work together (find_monsters calls avoid_monsters, etc.)
- Configuration via worldserver.conf WowChat2.Bot.* settings

## Related Files
- src/lua/movement.lua - Shared movement helpers
- src/lua/travel.lua - Wandering NPC system
- src/lua/ambush.lua - Monster spawn system
- src/lua/levelling.lua - Talent points and XP system
- src/lua/treasure.lua - Treasure chest spawn and per-player queue system
- src/lua/chest-vulnerability.lua - Holder/searcher mechanics, daze, mild taunt
- src/lua/custom-classes.lua - Custom class selection and dynamic trainer system
- src/lua/behaviors/find-monsters.lua - Combat targeting behavior
- src/lua/behaviors/avoid-monsters.lua - Danger awareness and flee behavior
- src/lua/behaviors/sit-and-rest.lua - Resource recovery behavior
- src/lua/behaviors/orbit-player.lua - Formation positioning behavior
- docs/playerbots/ - Playerbot documentation
- docs/ale/ - ALE Lua API
