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
| 136 | drop-all-creatures-except-spirit-healers | Ready (SQL created) |
| 122 | rebellious-attitudes-freedom-of-affairs | Open (placeholder) |
| 124 | randomize-ambush-spawn-interval | Completed |
| 125 | player-bot-behavior-commands | Open |
| 126 | dungeon-room-spawn-zones | Open |
| 127 | contextual-creature-spawns | Open (depends on 126) |
| 128 | embedding-based-creature-selection | Open (depends on 127) |
| 129 | portal-dimension-system | Open (Design Phase) |
| 130 | ale-initialization-hook-fix | Completed |
| 318 | remove-profile-system | Open |

### Class Scaling & Training
| ID | Title | Status |
|----|-------|--------|
| 138 | death-knight-level-1-scaling | Implemented (needs testing) |
| 140 | quest-spells-to-trainers | Implemented (needs testing) |
| 141 | talent-tier-limit | Open (see 319) |
| 319 | chunked-talent-points | Open (v1.0 requirement) |
| 142 | custom-spell-system | Open (Phase 3 prep) |
| 143 | proc-gem-system | Open (Phase 3 prep) |
| 155 | custom-class-selection-npc | Implemented (race-specific NPCs) |
| 157 | dynamic-trainer-spawning | Completed |
| 163 | custom-class-lua-format | Open (design complete) |

### Ambush System
| ID | Title | Status |
|----|-------|--------|
| 146 | clear-ambush-data-on-death | Completed |
| 147 | clear-traveller-data-on-despawn | Completed |
| 305 | ambush-aggro-and-corpse-movement | Implemented (needs testing) |

### Traveler System
| ID | Title | Status |
|----|-------|--------|
| 320 | traveler-sit-with-player | Implemented (needs testing) |

### C++ Patches
| ID | Title | Status |
|----|-------|--------|
| 150 | ale-sell-item-hook | Implemented (needs rebuild) |
| 156 | monster-accuracy-level-cap | Implemented (needs rebuild) |
| 332 | ale-unit-methods-patch | Completed |

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
| 161 | bot-wandering-traveller-style | Implemented (needs testing) |
| 162 | dungeon-rail-pathfinding | Implemented (needs testing) |
| 164 | behavior-orchestrator-modes | Implemented (foundation) |
| 165 | activity-selection-boredom | Implemented (needs testing) |
| 166 | point-line-definition-tools | Open (tooling) |
| 328 | getposition-nil-errors | Implemented (needs testing) |

## Completed: 2/10 core, 9/10 behaviors (2 open), 1 tooling

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

### 2026-04-08 - ALE Unit Methods Patch (332)
- **Problem:** Bot behavior scripts called Eluna-compatible methods not in ALE
  - `SetWalk()` only existed for Creature, not Player/Unit
  - `IsHostileTo()` and `IsFriendlyTo()` did not exist in ALE
- **Solution:** Added native methods to ALE C++ source
  - `Unit:SetWalk(enable)` - Sets MOVEMENTFLAG_WALKING for proper walking animation
  - `Unit:IsWalking()` - Reads movement flags
  - `Unit:IsHostileTo(target)` - Uses `GetReactionTo() <= REP_HOSTILE`
  - `Unit:IsFriendlyTo(target)` - Uses `GetReactionTo() >= REP_FRIENDLY`
- **Files patched:**
  - `source-beta/modules/mod-ale/src/LuaEngine/methods/UnitMethods.h`
  - `source-beta/modules/mod-ale/src/LuaEngine/LuaFunctions.cpp`
- **Secondary fix:** Removed duplicate ObjectVariables.ext causing Lua state corruption
  - Replaced `installed-files-beta/bin/lua_scripts/extensions/` directory with symlink to `src/lua/extensions/`
  - Same pattern already used for `custom/` directory
- **Design lesson:** "No fallbacks" - workarounds under the original function name are wrong
  - Speed manipulation is not SetWalk (doesn't trigger MOVEMENTFLAG_WALKING)
  - Proximity checks are not IsHostileTo (different purpose entirely)
- **Patch doc:** `docs/patches/ale-unit-setwalk.md`
- **Status:** Completed, ready for testing

### 2026-04-08 - GetPosition Nil Errors Fixed (328)
- **Root cause identified**: Timing race condition during bot login
  - Playerbots queues `OnBotLoginOperation` which eventually calls `sALE->OnLogin(bot)`
  - Lua `InitialLogin` immediately registers periodic events
  - First tick of `PeriodicBotWander` fires before bot has world position
  - `bot:GetPosition()` fails with "method is nil" (stale userdata or uninitialized state)
- **Architectural fix implemented**: Option A - Delayed event registration
  - Added `WaitForBotReady()` function that polls for valid position
  - Uses `pcall` to safely test `GetPosition()` - handles stale userdata gracefully
  - Polls every 500ms until position available
  - Only then registers behavior events via `registerBotBehaviors()`
- **Design principle**: "Make the dangerous state impossible, not just guarded against"
  - Behavior events are never registered until bot is confirmed ready
  - No guard rails needed in individual behavior functions
- **File modified**: `src/lua/periodic_events.lua`
  - Added `DELAY_BOT_READY_CHECK = 500`
  - Added `registerBotBehaviors(bot)` helper
  - Added `WaitForBotReady()` polling function
  - Modified `InitialLogin()` to start polling for bots instead of immediate registration
  - Added clarifying comment to `BotOrchestrator.switchMode()`
- **Related**: Issue 329 (Algorism Priority Scheduler) proposes centralized WorldTick as alternative
- **Status**: Implemented, needs testing

### 2026-04-05 - Activity Selection and Boredom System (165)
- **Event-driven activity selection**: Bots get bored and pick new activities
- **Combat end trigger**: 15% chance to get bored when combat ends
  - Uses `PLAYER_EVENT_ON_LEAVE_COMBAT = 34` hook
  - Only triggers for bots not in party (playerbots handles party bots)
- **Rest period**: Bot sits for 1-3 minutes before selecting new activity
  - `bot:SetStandState(1)` for sitting, `bot:SetStandState(0)` for standing
  - One-shot timer registered with `bot:RegisterEvent()`
- **Activity selection**: Weighted - 80% WANDERING, 20% DUNGEON_DELVE
  - Future: PROFESSION, SOCIAL, COMBAT_SEEK activities
- **Party transitions**: Group event hooks for automatic mode switching
  - `GROUP_EVENT_ON_MEMBER_ADD = 1`: Switch to PARTY_FOLLOW mode
  - `GROUP_EVENT_ON_MEMBER_REMOVE = 3`: Trigger boredom → activity selection
- **Cave/dungeon seeking**: Bots actively travel toward caves/dungeons when in DUNGEON_DELVE
  - `DungeonRails.seekEntrance(bot)` called when not in dungeon
  - Known entrance locations stored in `CAVE_DUNGEON_ENTRANCES` table
  - Falls back to wandering if no known entrances on map
  - Requires manual population via issue 166 (point definition tools)
- **Files modified:**
  - `src/lua/periodic_events.lua`:
    - Added boredom config constants (BOREDOM_CHANCE_AFTER_COMBAT, BOREDOM_REST_MIN/MAX)
    - Added BotOrchestrator.onCombatEnd(), triggerBoredom(), selectActivityCallback(), selectActivity()
    - Added event handlers: OnPlayerLeaveCombat, OnGroupMemberAdd/Remove, OnGroupDisband
    - Registered GROUP_EVENT and PLAYER_EVENT_ON_LEAVE_COMBAT hooks
  - `src/lua/behaviors/bot-wander.lua`:
    - Check for DUNGEON_DELVE mode, call DungeonRails.seekEntrance() if not in dungeon
  - `src/lua/behaviors/dungeon-rails.lua`:
    - Added DUNGEON_ENTRANCES table with known entrance coordinates
    - Added findNearestEntrance(), seekEntrance() functions
- **Bot data keys:**
  - `resting_for_activity`: true while sitting before activity selection
- **Status:** Implemented, needs testing
  - Test combat end → 30% boredom chance → sit → stand → new activity
  - Test party join → PARTY_FOLLOW mode → party leave → boredom → new activity
  - Test DUNGEON_DELVE mode → seek nearest dungeon entrance

### 2026-04-05 - Behavior Orchestrator Modes (164)
- **Mode-based behavior switching**: Bots operate in discrete modes (activity pages)
- Modes: WANDERING, DUNGEON_DELVE, PROFESSION, SOCIAL, COMBAT_SEEK, PARTY_FOLLOW
- **Periodic event pattern change**: Events only re-register if in valid mode
  - Check `BotOrchestrator.isModeValid(bot, "behavior_name")` first
  - If invalid, return without re-registering (event dies)
  - Enables dynamic behavior switching via mode changes
- **Behavior-to-modes mapping**: Each behavior lists which modes it runs in
  - wander: WANDERING, PROFESSION, COMBAT_SEEK
  - loneliness: WANDERING only
  - sit_and_rest: All except PARTY_FOLLOW
  - find_monsters: WANDERING, DUNGEON_DELVE, COMBAT_SEEK
  - orbit_player: SOCIAL, PARTY_FOLLOW
- **One-shot events**: PeriodicDungeonCooldownCleanup is now one-shot
  - Registered by exitDungeon(), not on login
  - Re-registers only while cooldown active, then stops
- **Files modified:**
  - `src/lua/periodic_events.lua` - Added BotOrchestrator module, mode checking
  - `src/lua/behaviors/dungeon-rails.lua` - Register cleanup event on exit
- **Future work**: Mode transition logic (PeriodicOrchestratorCheck)

### 2026-04-05 - Bot Wandering and Dungeon Navigation (161, 162)
- **Issue 161: Traveller-style wandering** replaces zone-consensus/level-affinity as default
  - Uses `Movement.generateNewWanderPosition()` with persistent theta (same as travellers)
  - Wall-hit fallback: after 3 failures, reorient to zone consensus direction
  - Continued failures: seek nearest player within ±3 levels
  - Loneliness check: every 30s, if no valid players within 100 yards, seek nearest
  - Water handling: reactive `IsInWater()` check, reverse theta and back out
  - Party behavior: defer to playerbots when in group
  - Anti-clump: 2-yard rule - disperse if too close to another bot
- **Issue 162: Dynamic dungeon/cave navigation**
  - Intersection detection via radial height sampling (8 directions, count walkable)
  - Position classification: intersection (3+), corridor (2), dead_end (1), stuck (0)
  - At intersection: pick random direction excluding way we came
  - Dead-end: probability-based turnaround (closer = more likely to turn)
  - Exactly 10 yards per movement, 10 consecutive failures = exit dungeon
  - 2-minute cooldown after exiting dungeon (cleanup via periodic event)
  - Dungeon detection: instance check, subzone keywords, exception list
- **Files created:**
  - `src/lua/behaviors/bot-wander.lua` - main wandering behavior
  - `src/lua/behaviors/dungeon-rails.lua` - dungeon navigation
- **Files modified:**
  - `src/lua/movement.lua` - added `getConsensusDirection()`, `normalizeAngle()`
  - `src/lua/behaviors/init.lua` - added Group 7 for wandering behaviors
  - `src/lua/periodic_events.lua` - replaced ZoneConsensus/LevelAffinity events
    - New events: PeriodicBotWander, PeriodicBotLonelinessCheck, PeriodicDungeonCooldownCleanup
- **Status:** Implemented, needs testing
  - Test wandering pattern (should look like travellers)
  - Test wall-hit reorientation after 3 failures
  - Test loneliness check seeking behavior
  - Test dungeon intersection navigation
  - Test dungeon dead-end turnaround probability

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

### 2026-04-05 - Ambush System Fixes (304, 305)
- Fixed corpse sliding: Added `MoveClear()` in `onCreatureDeath` to stop movement physics
- Fixed aggro lock-on: Added `SetAggroEnabled(true)` when player stands up after sitting
- Issue 304 (clear ambush data) was already partially implemented, now complete
- Issue 305 created to track the aggro re-enable and corpse movement bugs
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
