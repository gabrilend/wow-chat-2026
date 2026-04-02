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
| 130 | ale-initialization-hook-fix | In Progress (merged 134) |

### Playerbot Behaviors
| ID | Title | Status |
|----|-------|--------|
| 114 | behavior-find-monsters | In Progress |
| 115 | behavior-discuss-with-npc | Open |
| 116 | behavior-avoid-monsters | In Progress |
| 117 | behavior-sit-and-rest | In Progress |
| 118 | behavior-travel-to-unique-lands | Open |
| 119 | behavior-orbit-player | In Progress |

## Completed: 2/10 core, 0/6 behaviors (5 in progress)

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

### 2026-03-31 - Behavior Implementations Started
- Created issue files 114-119 with detailed implementation steps
- Implemented find-monsters.lua: scans for hostiles, level-appropriate targeting, LoS checks
- Implemented avoid-monsters.lua: danger scoring, flee logic, escape vectors, safe path finding
- Implemented sit-and-rest.lua: resource monitoring, consumable usage, danger awareness
- Implemented orbit-player.lua: formation positioning, clump avoidance, state-aware radius
- All behaviors follow established style: vertical alignment, vim folds, dense configs
- Behaviors integrate: orbit-player calls avoid-monsters, sit-and-rest calls avoid-monsters
- talentpoints level 20 cap completed in levelling.lua with database persistence

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
- src/lua/behaviors/find-monsters.lua - Combat targeting behavior
- src/lua/behaviors/avoid-monsters.lua - Danger awareness and flee behavior
- src/lua/behaviors/sit-and-rest.lua - Resource recovery behavior
- src/lua/behaviors/orbit-player.lua - Formation positioning behavior
- docs/playerbots/ - Playerbot documentation
- docs/ale/ - ALE Lua API
