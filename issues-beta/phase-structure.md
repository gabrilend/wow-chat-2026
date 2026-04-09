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
| 158 | ambush-aggro-and-corpse-movement | Implemented |
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

## Related Documents

- `issues/100-route-to-v1.md` - V1.0 feature checklist
- `docs/roadmap.md` - Original phase overview
- `docs/concept-catalog.md` - 800 concepts covering all systems
