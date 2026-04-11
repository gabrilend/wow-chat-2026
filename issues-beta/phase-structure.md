# Everland Ghostsong - Phase Structure

## Overview

This document defines a 9-phase structure for the project, organized by
**resulting effects** (what the player experiences / what the system produces)
rather than chronological implementation order.

Each phase represents a coherent functional domain - a category of outcomes
that the project delivers. Issues are grouped by the effect they contribute to,
not by when they were conceived or when they should be implemented.

---

## Summary Table

| Phase | Effect | Core Concept |
|-------|--------|--------------|
| **1** | Server runs | **Infrastructure** |
| **2** | World is empty | **Emptiness** |
| **3** | Monsters spawn | **Danger** |
| **4** | Loot circulates | **Treasure** |
| **5** | Friendly NPCs wander | **Encounters** |
| **6** | Bots have autonomy | **Companions** |
| **7** | Classes are customizable | **Identity** |
| **8** | Progression has stakes | **Endgame** |
| **9** | World tells stories | **Immersion** |
| **10** | Game breathes beyond borders | **Integration** |

---

## Phase 1: Foundation & Tooling

**Effect:** The server runs. Developers can work on the project.

This phase encompasses everything needed to have a functional development
environment: build scripts, database setup, configuration management, and
developer tooling.

| Issue | Title | Status |
|-------|-------|--------|
| 101 | verify-server-startup | - |
| 102 | test-playerbots-spawn | - |
| 105 | setup-local-mysql-installation | Completed |
| 106a | read-only-config-dashboard | Open |
| 106b | runtime-config-modifications | Open |
| 106c | config-persistence-layer | Open |
| 107 | credential-manager-script | Open |
| 108 | thread-count-variable | Completed |
| 109 | add-build-mode-to-azerothcore-script | Completed |
| 111 | config-merge-script | Open |
| 123 | visual-powerline-mapping-tool | Open |
| 145 | git-branch-consolidation | Open |
| 166 | point-line-definition-tools | Open |
| 201 | branch-based-azerothcore-versioning | Open |
| 318 | remove-profile-system | Open |
| 321 | mysql-script-naming-aliases | Open |
| 323 | parallel-update-status-spinners | Open |

### Phase 1 Completion Criteria

- Server builds and starts without errors
- MySQL databases accessible
- Lua scripts load and execute
- Developer can make changes and test them

---

## Phase 2: The Empty World

**Effect:** The world is empty. Only spirit healers remain.

This phase establishes the blank canvas that all other systems paint on.
The retail WoW world is stripped of creatures, vendors, and quest givers,
leaving an eerie emptiness that the ambush and traveler systems will populate.

| Issue | Title | Status |
|-------|-------|--------|
| 112 | fix-drop-creatures-cascading-errors | Completed |
| 130 | ale-initialization-hook-fix | Completed |
| 136 | drop-all-creatures-except-spirit-healers | Ready |

### Phase 2 Completion Criteria

- Fresh database has no creature spawns except spirit healers
- No static NPCs (vendors, guards, quest givers)
- ALE initializes correctly and loads Lua scripts
- World feels empty and dangerous

---

## Phase 3: Danger (Ambush System)

**Effect:** Monsters spawn around players. The hunt begins.

This phase creates the core danger loop: monsters appear near players on
a timer, chase them down, and create constant tension. Environmental
hazards extend the danger beyond land.

| Issue | Title | Status |
|-------|-------|--------|
| 113 | investigate-ambush-monsters-not-spawning | Open |
| 124 | randomize-ambush-spawn-interval | Completed |
| 146 | clear-ambush-data-on-death | Completed |
| 305 | ambush-aggro-and-corpse-movement | Implemented |
| 301 | ocean-shark-hazard | Open |
| 324 | nil-bot-periodic-event-crash | Open |
| 325 | ale-gameobject-wildcard-registration | Open |

### Phase 3 Completion Criteria

- Monsters spawn 120-160 yards from players
- Spawn interval uses random walk algorithm (floor 10s, soft cap 100s)
- Grace period on login after 10+ minutes offline
- Monsters chase and attack players
- Corpses don't slide after death
- Sharks spawn in open water after time threshold

---

## Phase 4: Treasure & Economy

**Effect:** Chests spawn. Loot circulates between players.

This phase creates the treasure system where items flow through a shared
pool. Players can't see items in their own chests - cooperation is required.
Sold items re-enter circulation, creating an economy of found goods.

| Issue | Title | Status |
|-------|-------|--------|
| 121 | bounty-board-currency-system | Open |
| 148 | treasure-chest-shared-loot | Implemented |
| 149 | sold-items-to-treasure-pool | Blocked (150) |
| 150 | ale-sell-item-hook | Implemented (needs rebuild) |
| 151 | ability-tome-system | Partial |
| 152 | death-durability-system | Implemented |
| 153 | chest-vulnerability-mechanic | Implemented |
| 154 | multiplayer-chest-access | Implemented |
| 160 | custom-empty-loot-chest-templates | Implemented |
| 303 | chest-bound-hearthstones | Open |
| 305 | zero-value-treasure-duplicates | Open |

### Phase 4 Completion Criteria

- Chests spawn near players on timer (~100 seconds)
- Holder can't see items in their own chest
- Second player (searcher) can loot for the holder
- Sold items enter shared pool and appear in other players' chests
- Death costs durability on equipment
- Chest-bound hearthstones circulate through pool
- Items have 0 sell value after entering pool (no infinite gold)

---

## Phase 5: Friendly Encounters (Travelers)

**Effect:** The world has friendly faces. Trainers, merchants wander through.

This phase populates the empty world with helpful NPCs that wander into
view periodically. Class trainers, merchants, and other services come to
the player rather than the player seeking them out.

| Issue | Title | Status |
|-------|-------|--------|
| 135 | custom-merchant-system | Open |
| 137 | universal-class-trainers | Open |
| 147 | clear-traveller-data-on-despawn | Completed |
| 157 | dynamic-trainer-spawning | Completed |
| 320 | traveler-sit-with-player | Implemented |

### Phase 5 Completion Criteria

- Travelers spawn ~130 seconds apart
- Travelers wander naturally through the world
- Travelers sit when player sits (social mirroring)
- Class trainers wander by and offer training
- Merchants wander by with goods
- Travelers despawn cleanly after wandering away

---

## Phase 6: Companions (Bot Behaviors)

**Effect:** Playerbots have their own lives. They wander, explore, rest, fight.

This phase gives AI companions autonomous behavior. Bots wander like travelers,
explore dungeons, get bored, make decisions, and can join player parties.
They're not pets - they're fellow adventurers with their own agendas.

| Issue | Title | Status |
|-------|-------|--------|
| 114 | behavior-find-monsters | Implemented |
| 115 | behavior-discuss-with-npc | Open |
| 116 | behavior-avoid-monsters | Implemented |
| 117 | behavior-sit-and-rest | Implemented |
| 118 | behavior-travel-to-unique-lands | Open |
| 119 | behavior-orbit-player | Implemented |
| 125 | player-bot-behavior-commands | Open |
| 132 | healer-bot-ping-pong-behavior | Open |
| 133 | gesture-command-system-kneel-convoy | Open |
| 160 | behavior-system-integration | Implemented |
| 161 | bot-wandering-traveller-style | Implemented |
| 162 | dungeon-rail-pathfinding | Implemented |
| 164 | behavior-orchestrator-modes | Implemented |
| 165 | activity-selection-boredom | Implemented |
| 167 | ranged-bot-help-intervention | Open |
| 168 | public-healer-frames-addon | Open |

### Phase 6 Completion Criteria

- Bots wander like travelers (persistent theta, wall-hit recovery)
- Bots navigate dungeons using intersection detection
- Bots get bored after combat (15% chance) and select new activities
- Bots seek players when lonely (100+ yards from anyone)
- Bots sit and rest when low on resources
- Bots avoid dangerous monsters when appropriate
- Bots follow players when invited to party
- Bots return to autonomous wandering when dismissed

---

## Phase 7: Character Identity (Custom Classes)

**Effect:** Players can create unique classes. Choose any abilities.

This phase allows players to define their own classes by selecting abilities
from any base class. Custom class definitions use a Lua format, are validated
automatically, and spawn personalized trainers.

| Issue | Title | Status |
|-------|-------|--------|
| 140 | quest-spells-to-trainers | Implemented |
| 142 | custom-spell-system | Open |
| 143 | proc-gem-system | Open |
| 144 | low-level-class-identity | Open |
| 155 | custom-class-selection-npc | Implemented |
| 159 | knight-custom-class | Open |
| 161 | aio-tiered-talent-trainers | Open |
| 162 | talent-tree-analysis-script | Open |
| 163 | custom-class-lua-format | Open |
| 163 | custom-class-resource-bars | Open |
| 164 | custom-class-configuration-schema | Open |
| 304 | conditional-class-selector-spawn | Open |
| 345 | custom-talent-interface | Open |

### Phase 7 Completion Criteria

- Custom classes defined in Lua files with rich structure
- Class selection NPC spawns (race-specific appearances)
- Selector only appears if customs exist for player's base class
- Custom class abilities trainable from dynamic trainers
- Talents organized into schools (talent trees)
- Custom talent interface functional
- Quest-learned abilities available at trainers instead

---

## Phase 8: Progression & Endgame

**Effect:** Players level, gain talents, face permadeath, achieve immortality.

This phase defines the full progression arc from level 1 to immortality.
Level cap at 20, chunked talent points, invisible progression past 20,
mandatory grouping at endgame, and the ultimate stakes of permadeath.

| Issue | Title | Status |
|-------|-------|--------|
| 120 | talent-points-level-20-cap | Completed |
| 138 | death-knight-level-1-scaling | Implemented |
| 139 | proportional-damage-rewards | Open |
| 141 | talent-tier-limit | Open |
| 156 | monster-accuracy-level-cap | Implemented (needs rebuild) |
| 309 | invisible-level-progression | Open |
| 319 | chunked-talent-points | Open |
| 322 | vavadane-shared-daily-reset-character | Open |

### Phase 8 Completion Criteria

- Level cap at 20
- Talent points awarded in chunks (10 points at levels 5, 8, 11, 14, 17, 20)
- No talent respec (permanent choices)
- Talents limited to first 3 tiers
- Death Knights start at level 1 with scaled abilities
- Monster accuracy capped at ±3 levels
- Invisible XP tracking after level 20
- Monsters scale with invisible level (20 + invisible)
- No spawn cap for invisible-level players (mandatory grouping)
- Permadeath: death with no equipment = character deleted
- Immortality at invisible level 60: gold coin, no more spawns

---

## Phase 9: Storytelling & World Structure

**Effect:** Narrators tell stories. Portals lead to dimensions. The world has depth.

This phase adds narrative and structural depth to the world. Wandering narrators
read literature and share rumors. Portals become gateways to shared dimensions.
Dungeons have meaningful room structures. Language barriers create social puzzles.

| Issue | Title | Status |
|-------|-------|--------|
| 122 | rebellious-attitudes-freedom-of-affairs | Open |
| 126 | dungeon-room-spawn-zones | Open |
| 127 | contextual-creature-spawns | Open |
| 128 | embedding-based-creature-selection | Open |
| 129 | portal-dimension-system | Open |
| 131 | randomized-login-screen-freddi-fish | Open |
| 302 | language-barrier-system | Open |
| 307 | narrator-audience-facing | Open |
| 308 | gutenberg-text-library | Open |
| 310 | wandering-narrator-system | Open |
| 311 | shepherd-flock-system | Open |
| 312 | automated-lore-generation | Open |
| 316 | clustered-worldserver | Open |

### Phase 9 Completion Criteria

- Narrators wander the world reading from Gutenberg library
- Narrators stop and sit when players sit nearby
- Rumors propagate through narrator network (telephone game)
- Battleground portals become shared dimension gates
- Dungeons have room detection and contextual spawns
- Embedding-based creature selection for thematic consistency
- Language barriers require learned languages for communication
- Shepherds wander with critter flocks (immortality lore)
- Automated lore generation via Ollama integration

---

## Phase 10: External Integration (rmail)

**Effect:** The game breathes beyond its borders. Messages flow in and out.

This phase bridges the isolated WoW server with the external world through rmail.
Players interact with the game from outside the client. Information becomes
portable. Accounts become ephemeral. The game becomes more than the game.

**Note:** Phase 10 is a **coordination phase**. Its issues track rmail infrastructure
that enables services implemented in other phases. The service architecture spans:
- Phase 7: Custom class submission (port 4662)
- Phase 9: Narrator subscription (port 4862)
- Phase 10: Accounts, mail bridge, feedback (ports 4562, 4762, 4962)

### Core Infrastructure (Phase 10 Primary)

| Issue | Title | Status |
|-------|-------|--------|
| 313 | rmail-dns-style-addresses | Open |
| 315 | rmail-login-flush-hook | Open |
| 317 | rmail-account-creation | Open |

### Service Implementations

| Issue | Title | Impl Phase | Port |
|-------|-------|------------|------|
| 163 | custom-class-submission | 7 | 4662 |
| 306 | rmail-ingame-bridge | 10 | 4762 |
| 310 | narrator-subscription | 9 | 4862 |
| 314 | rmail-feedback-mailbox | 10 | 4962 |
| 164 | rmail-ingame-text-editor | 10 | - |

### Phase 10 Completion Criteria

- Guest accounts with public credentials (24 permanent)
- rmail accounts created/destroyed via message lifecycle
- In-game mail forwarded to rmail subscribers
- External messages delivered to in-game mailbox
- DNS-style addresses work (wow.ritzmenardi.com/service)
- Login triggers queue flush for pending messages
- Feedback mailbox collects player messages

### Phase 10 Documentation Style: Thoughts

Phase 10 introduces the "Thoughts" documentation layer - a different epistemic
style from comments. While comments describe HOW code works, thoughts explore
WHY decisions were made, connecting concepts across the system.

Thoughts are written in a contemplative tone, often questioning assumptions
and drawing relationships between disconnected ideas. They help future readers
(human or LLM) understand the reasoning behind design choices.

See `issues-beta/phase-10-progress.md` for examples of the Thoughts style.

---

## Notes on Phase Organization

### Cross-Cutting Issues

Some issues contribute to multiple phases. Assignment is based on primary effect:

- **157 (dynamic trainer spawning)** - Could be Phase 5 (travelers) or Phase 7
  (custom classes). Assigned to Phase 5 because the trainer IS a traveler.

- **160 (behavior system integration)** - Spans Phase 5 and 6. Assigned to
  Phase 6 because bots are the primary beneficiary.

- **161/162 (duplicate numbers)** - The original numbering has collisions.
  Context determines which issue is meant.

### Original Phase Mapping

The original phase numbering (1xx = Phase 1, 3xx = Phase 3) correlates loosely:

| Original | New Phase | Notes |
|----------|-----------|-------|
| 10x | 1 | Foundation (mostly matches) |
| 11x | 2, 3 | Empty world, ambush |
| 12x | 4, 6, 8 | Mixed: treasure, behaviors, progression |
| 13x | 4, 5, 6 | Mixed: treasure, travelers, behaviors |
| 14x | 7, 8 | Custom classes, progression |
| 15x | 4, 7 | Treasure, custom classes |
| 16x | 1, 6, 7 | Tools, behaviors, classes |
| 30x | 3, 4, 7, 9 | Hazards, treasure, classes, storytelling |
| 31x | 9 | Storytelling (mostly matches) |
| 32x | 1, 8 | Infrastructure, progression |
| 345 | 7 | Custom talent interface |

### Future Considerations

Phase 9 and 10 could potentially split further:

- **Phase 9** could separate World Structure (portals, dungeons) from
  Narrative Systems (narrators, lore, Gutenberg)
- **Phase 10** could separate account lifecycle from mail bridging
- **Infrastructure Scaling** (clustered worldserver) might warrant its own phase

For now, the 10-phase structure provides good granularity without excessive
fragmentation.

---

## Transition Plan

Issues will migrate from `issues/` to `issues-beta/` one at a time:

1. When an issue is completed, move to `issues-beta/completed/`
2. Update the issue's phase number to match this structure
3. Update the relevant `phase-X-progress.md` file in `issues-beta/`

The `issues/` directory remains authoritative until full migration.

---

## Proposed Renumbering Scheme

**Rationale:** Issues should be numbered sequentially within their phase (1xx for Phase 1, 2xx for Phase 2, etc.) in order of foundational importance. This section proposes a complete renumbering map.

### Phase 1: Foundation & Tooling (1xx)

**Keep existing where correctly numbered:**
- 101 verify-server-startup (KEEP)
- 102 test-playerbots-spawn (KEEP)
- 103 document-configuration-options (KEEP)
- 104 migrate-lua-scripts-from-wowchat1 (KEEP)
- 105 setup-local-mysql-installation (KEEP)
- 106a/b/c read-only-config-dashboard / runtime-config-modifications / config-persistence-layer (KEEP)
- 107 credential-manager-script (KEEP)
- 108 thread-count-variable (adaptive-build-parallelism) (KEEP)
- 109 add-build-mode-to-azerothcore-script (incremental-rebuild-detection) (KEEP)

**Renumber to fill gaps:**
- 110 concept-catalog-consolidation (was 144)
- 111 config-merge-script (KEEP)
- 112 git-branch-consolidation (was 145)
- 113 visual-powerline-mapping-tool (was 123)
- 114 point-line-definition-tools (was 166)
- 115 branch-based-azerothcore-versioning (was 201)
- 116 remove-profile-system (was 318)
- 117 mysql-script-naming-aliases (was 321)
- 118 parallel-update-status-spinners (was 323)

### Phase 2: The Empty World (2xx)

**Foundational order:**
- 201 database-integrity-cleanup (was 112) - FK cascade handling, clean logs
- 202 lua-engine-initialization (was 130) - ALE must work
- 203 drop-all-creatures-except-spirit-healers (was 136) - defines empty world
- 204 random-spawn-point-feature (was 110) - spawn in empty world
- 205 talent-points-level-20-cap (was 120) - progression system for 1-20
- 206 death-knight-level-1-scaling (was 138) - class parity for level 1
- 207 clear-traveller-data-on-despawn (was 147) - memory cleanup

### Phase 3: Danger (Ambush System) (3xx)

**Foundational order:**
- 301 ocean-shark-hazard (KEEP) - water danger
- 302 investigate-ambush-monsters-not-spawning (was 113) - debug spawn
- 303 randomize-ambush-spawn-interval (was 124) - random walk algorithm
- 304 clear-ambush-data-on-death (was 146) - memory cleanup
- 305 ambush-aggro-and-corpse-movement (was 158) - aggro/corpse fixes
- 306 nil-bot-periodic-event-crash (was 324) - crash fix
- 307 ale-gameobject-wildcard-registration (was 325) - event registration

### Phase 4: Treasure & Economy (4xx)

**Foundational order:**
- 401 bounty-board-currency-system (was 121)
- 402 treasure-chest-shared-loot (was 148)
- 403 ale-sell-item-hook (was 150) - required for sold-items-to-treasure
- 404 sold-items-to-treasure-pool (was 149)
- 405 ability-tome-system (was 151)
- 406 death-durability-system (was 152)
- 407 chest-vulnerability-mechanic (was 153)
- 408 multiplayer-chest-access (was 154)
- 409 custom-empty-loot-chest-templates (was 160)
- 410 chest-bound-hearthstones (was 303)
- 411 zero-value-treasure-duplicates (was 305)

### Phase 5: Friendly Encounters (Travelers) (5xx)

**Foundational order:**
- 501 custom-merchant-system (was 135)
- 502 universal-class-trainers (was 137)
- 503 dynamic-trainer-spawning (was 157)
- 504 traveler-sit-with-player (was 320)

### Phase 6: Companions (Bot Behaviors) (6xx)

**Foundational order:**
- 601 behavior-find-monsters (was 114)
- 602 behavior-avoid-monsters (was 116)
- 603 behavior-sit-and-rest (was 117)
- 604 behavior-travel-to-unique-lands (was 118)
- 605 behavior-orbit-player (was 119)
- 606 behavior-discuss-with-npc (was 115)
- 607 player-bot-behavior-commands (was 125)
- 608 healer-bot-ping-pong-behavior (was 132)
- 609 gesture-command-system-kneel-convoy (was 133)
- 610 behavior-system-integration (was 160 - duplicate, Phase 6 version)
- 611 bot-wandering-traveller-style (was 161 - Phase 6 version)
- 612 dungeon-rail-pathfinding (was 162 - Phase 6 version)
- 613 behavior-orchestrator-modes (was 164 - Phase 6 version)
- 614 activity-selection-boredom (was 165)
- 615 ranged-bot-help-intervention (was 167)
- 616 public-healer-frames-addon (was 168)

### Phase 7: Character Identity (Custom Classes) (7xx)

**Foundational order:**
- 701 quest-spells-to-trainers (was 140)
- 702 low-level-class-identity (was 144 - Phase 7 version, different from 144 catalog)
- 703 custom-spell-system (was 142)
- 704 proc-gem-system (was 143)
- 705 custom-class-selection-npc (was 155)
- 706 custom-class-lua-format (was 163)
- 707 custom-class-resource-bars (was 163 - duplicate)
- 708 custom-class-configuration-schema (was 164 - Phase 7 version)
- 709 knight-custom-class (was 159)
- 710 aio-tiered-talent-trainers (was 161 - Phase 7 version)
- 711 talent-tree-analysis-script (was 162 - Phase 7 version)
- 712 custom-talent-interface (was 345)
- 713 conditional-class-selector-spawn (was 304)

### Phase 8: Progression & Endgame (8xx)

**Foundational order:**
- 801 proportional-damage-rewards (was 139)
- 802 talent-tier-limit (was 141)
- 803 monster-accuracy-level-cap (was 156)
- 804 invisible-level-progression (was 309)
- 805 chunked-talent-points (was 319)
- 806 vavadane-shared-daily-reset-character (was 322)

### Phase 9: Storytelling & World Structure (9xx)

**Foundational order:**
- 901 rebellious-attitudes-freedom-of-affairs (was 122)
- 902 dungeon-room-spawn-zones (was 126)
- 903 contextual-creature-spawns (was 127)
- 904 embedding-based-creature-selection (was 128)
- 905 portal-dimension-system (was 129)
- 906 randomized-login-screen-freddi-fish (was 131)
- 907 language-barrier-system (was 302)
- 908 narrator-audience-facing (was 307)
- 909 gutenberg-text-library (was 308)
- 910 wandering-narrator-system (was 310)
- 911 shepherd-flock-system (was 311)
- 912 automated-lore-generation (was 312)
- 913 clustered-worldserver (was 316)

### Phase 10: External Integration (rmail) (10xx)

**Core Infrastructure:**
- 1001 rmail-dns-style-addresses (was 313)
- 1002 rmail-login-flush-hook (was 315)
- 1003 rmail-account-creation (was 317)

**Service Implementations:**
- 1004 custom-class-submission (was 163 - Phase 10 rmail version)
- 1005 rmail-ingame-bridge (was 306)
- 1006 narrator-subscription (was 310 - duplicate with Phase 9)
- 1007 rmail-feedback-mailbox (was 314)
- 1008 rmail-ingame-text-editor (was 164 - Phase 10 version)

### Special Cases & Duplicates

**Duplicate issue numbers in original system:**
- 160: Used in both Phase 4 (custom-empty-loot-chest-templates) and Phase 6 (behavior-system-integration)
  - Resolved: Phase 4 keeps 409, Phase 6 gets 610

- 161: Used in both Phase 6 (bot-wandering) and Phase 7 (aio-tiered-talent-trainers)
  - Resolved: Phase 6 gets 611, Phase 7 gets 710

- 162: Used in both Phase 6 (dungeon-rail-pathfinding) and Phase 7 (talent-tree-analysis-script)
  - Resolved: Phase 6 gets 612, Phase 7 gets 711

- 163: Used in Phase 7 (custom-class-lua-format) and Phase 10 (custom-class-submission)
  - Resolved: Phase 7 gets 706, Phase 10 gets 1004

- 164: Used in both Phase 6 (behavior-orchestrator-modes) and Phase 7 (custom-class-configuration-schema) and Phase 10 (rmail-ingame-text-editor)
  - Resolved: Phase 6 gets 613, Phase 7 gets 708, Phase 10 gets 1008

- 310: Used in both Phase 9 (wandering-narrator-system) and Phase 10 (narrator-subscription)
  - Resolved: Phase 9 gets 910, Phase 10 gets 1006

**Issues that moved phases during reorganization:**
- 110 random-spawn-point-feature: Originally Phase 1, moved to Phase 2 (defines spawn in empty world)
- 112 database-integrity-cleanup: Originally Phase 2 number, but logically Phase 2
- 120 talent-points-level-20-cap: Originally listed in Phase 8, moved to Phase 2 (defines 1-20 progression)
- 144 concept-catalog-consolidation: Phase 1 (docs), different from 144 low-level-class-identity (Phase 7)

### Migration Priority

**Immediate (already migrated to issues-beta):**
- Phase 1: 103, 104, 105, 108, 109, 110 (was 144)
- Phase 2: 201 (was 112), 202 (was 130), 203 (was 136), 205 (was 120), 206 (was 138), 207 (was 147)
- Phase 1 active: 101, 102
- Phase 2 active: 204 (was 110)

**Next priority (completed issues not yet migrated):**
- Phase 3: 303 (was 124), 304 (was 146)
- Phase 4: 402 (was 148), 403 (was 150), 406 (was 152), 407 (was 153), 408 (was 154), 409 (was 160)
- Phase 5: 503 (was 157), 504 (was 320)
- Phase 6: 601 (was 114), 602 (was 116), 603 (was 117), 605 (was 119), 611 (was 161), etc.

---

## Related Documents

- `issues/100-route-to-v1.md` - V1.0 feature checklist
- `docs/roadmap.md` - Original phase overview
- `docs/concept-catalog.md` - 800 concepts covering all systems
