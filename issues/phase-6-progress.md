# Phase 6 Progress: Companions (Bot Behaviors)

## Effect

Playerbots have their own lives. They wander, explore, rest, fight.

## Status: Mostly Implemented

## Goal

Give AI companions autonomous behavior. Bots wander like travelers, explore
dungeons, get bored, make decisions, and can join player parties. They're
not pets - they're fellow adventurers with their own agendas.

---

## Issues

Ordered by narrative arc: orchestrator → individual behaviors →
movement/pathfinding → social/cooperation → tooling/UI.

### Orchestrator (the keystone)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 610 | behavior-system-integration | Implemented | Centralized orchestration. Blocks every behavior below. |
| 613 | behavior-orchestrator-modes | Implemented | Activity-page modes. Built on 610. |
| 614 | activity-selection-boredom | Implemented | Emergent decisions; 15% chance after combat. Built on 613. |

### Individual behaviors (depend on 610)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 601 | behavior-find-monsters | Implemented | Combat targeting. |
| 603 | behavior-avoid-monsters | Implemented | Danger awareness. Inverse of 601. |
| 604 | behavior-sit-and-rest | Implemented | Resource recovery. |
| 606 | behavior-orbit-player | Implemented | Formation positioning. |
| 605 | behavior-travel-to-unique-lands | Open | Cross-zone exploration. |
| 602 | behavior-discuss-with-npc | Open | Social interaction. |

### Movement & pathfinding
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 611 | bot-wandering-traveller-style | Implemented | Natural movement. Pattern from Phase 5 travelers. |
| 612 | dungeon-rail-pathfinding | Implemented | Reactive intersection sampling for caves/dungeons. |
| 612b | mmap-route-precomputation | Open (Research) | Precompute full routes via mmap data. Complements/replaces 612. (was 329) |
| 606b | getposition-nil-errors | Resolved | Bot crash fix when GetPosition returns nil. (was 328) |

### Social / cooperation
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 607 | player-bot-behavior-commands | Open | Player control interface (party invite, dismiss). |
| 608 | healer-bot-ping-pong-behavior | Open | Healer positioning. |
| 609 | gesture-command-system-kneel-convoy | Open | Non-verbal commands. |
| 615 | ranged-bot-help-intervention | Open | Ranged assistance pattern. |

### UI / tooling
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 616 | public-healer-frames-addon | Open | UI for healer bots. Client-side AIO addon. |

## Completed: 0/18 (10 Implemented, 1 Resolved, 1 Research)

---

## Completion Criteria

- [x] Bots wander like travelers (persistent theta, wall-hit recovery)
- [x] Bots navigate dungeons using intersection detection
- [x] Bots get bored after combat (15% chance) and select new activities
- [x] Bots seek players when lonely (100+ yards from anyone)
- [x] Bots sit and rest when low on resources
- [x] Bots avoid dangerous monsters when appropriate
- [x] Bots follow players when invited to party
- [x] Bots return to autonomous wandering when dismissed
- [ ] Bots discuss with wandering NPCs
- [ ] Bots travel to unexplored zones
- [ ] Gesture commands work (kneel = convoy mode)
- [ ] Healer bots position intelligently

---

## Key Files

### Behavior Scripts
- `src/lua/behaviors/find-monsters.lua` - Combat targeting
- `src/lua/behaviors/avoid-monsters.lua` - Danger scoring, flee logic
- `src/lua/behaviors/sit-and-rest.lua` - Resource monitoring
- `src/lua/behaviors/orbit-player.lua` - Formation positioning
- `src/lua/behaviors/bot-wander.lua` - Traveler-style wandering
- `src/lua/behaviors/dungeon-rails.lua` - Cave/dungeon navigation

### Core Systems
- `src/lua/periodic_events.lua` - Timer registration, orchestration
- `src/lua/movement.lua` - Shared movement utilities

---

## Dependencies

- Phase 1 (foundation) - ALE must initialize correctly
- Phase 5 (travelers) - Bots reuse traveler movement patterns

---

## Behavior Architecture

### Orchestrator Modes

Bots operate in discrete modes (activity pages):

| Mode | Behaviors Active |
|------|-----------------|
| WANDERING | wander, loneliness, sit_and_rest, find_monsters |
| DUNGEON_DELVE | dungeon_rails, find_monsters, sit_and_rest |
| PROFESSION | wander, sit_and_rest |
| SOCIAL | orbit_player, discuss_npc |
| COMBAT_SEEK | wander, find_monsters |
| PARTY_FOLLOW | orbit_player (defer to playerbots) |

### Periodic Events

All behaviors register through `periodic_events.lua`:

| Event | Interval | Purpose |
|-------|----------|---------|
| PeriodicBotWander | 3000ms | Movement updates |
| PeriodicBotLonelinessCheck | 30000ms | Seek nearby players |
| PeriodicBotSitAndRest | 3000ms | Resource checks |
| PeriodicBotFindMonsters | 5000ms | Combat scanning |
| PeriodicDungeonCooldownCleanup | one-shot | Post-dungeon cooldown |

### Boredom System (165)

After combat ends:
1. 15% chance to trigger boredom
2. Bot sits for 1-3 minutes
3. Bot stands and selects new activity
4. 80% WANDERING, 20% DUNGEON_DELVE

### Dungeon Navigation (162)

Intersection detection via radial height sampling:
- 8 directions, count walkable paths
- 3+ paths = intersection (pick random excluding origin)
- 2 paths = corridor (continue)
- 1 path = dead end (probability-based turnaround)
- 0 paths = stuck (exit dungeon)

---

## Notes

### Wall-Hit Recovery (161)

When bot hits terrain boundary:
1. First 3 failures: random reorientation
2. After 3 failures: reorient to zone consensus direction
3. Continued failures: seek nearest player within ±3 levels

### Party Transitions

- `GROUP_EVENT_ON_MEMBER_ADD`: Switch to PARTY_FOLLOW
- `GROUP_EVENT_ON_MEMBER_REMOVE`: Trigger boredom → activity selection
- Playerbots module handles party combat; Lua handles solo wandering

### Anti-Clump Behavior

2-yard rule: if too close to another bot, disperse.
Prevents bot herding into single locations.

---

## rmail Integration (Reference)

Phase 6 doesn't directly use rmail, but it creates the **autonomous actors** that can
interact with rmail-integrated NPCs. Bots are the audience for narrators, the students
for trainers. See **Phase 10** for the full rmail treatment with design philosophy.

### Bots as Audience

When a narrator (Phase 9) wanders by reading poetry, who listens?
Players, yes. But also bots. The world has witnesses.

| Interaction | Bot Role | rmail Service |
|-------------|----------|---------------|
| Narrator speaks | Bot sits, "listens" | narrator (4862) |
| Trainer arrives | Bot could "learn" | classes (4662) |
| NPC discussion | Bot engages socially | (behavior-only) |

### Shared DNA with Narrators

Bots and narrators use the same movement system (Phase 5):
- Persistent theta wandering
- Wall-hit recovery
- Social mirroring (sit when player sits)

```
THOUGHT: The bot is an actor without a script. The narrator has a script.

Both walk the same paths through the empty world.
Both stop when you stop. Both sit when you sit.
But the narrator has something to say. The bot has intentions.

The narrator's voice comes from outside (rmail, Gutenberg).
The bot's decisions come from inside (behavior system, boredom).

Two kinds of presence. External content, internal autonomy.
They share a body (movement patterns) but differ in soul.
```

### Why Bots Matter for rmail Immersion

Without bots, the player is often alone when a narrator arrives.
Alone in an empty world, one narrator speaking to one listener.
Intimate, but isolated.

With bots, there's a small crowd. Fellow adventurers.
The narrator has an audience. The reading becomes an event.
Multiple witnesses create shared experience.

```
THOUGHT: A story told to one person is a confession.
A story told to a crowd is a performance.

The bots transform narrators from personal moment to public event.
They don't understand the words. They just happen to be there.
But their presence changes everything.

rmail brings external content into the game.
Bots bring internal population to receive it.
Together: external content with internal audience.
```

### Bot Discussion with NPCs (115)

Future: Bots could discuss with rmail-integrated NPCs:
- Bot encounters narrator
- Bot "asks" about the story
- Narrator responds (content from Gutenberg, transformed)
- Creates emergent conversation

This would be pure flavor - bots don't understand.
But it animates the world. Life happening around you.

### Service Architecture (Preview)

| Service | Port | Bot Relationship |
|---------|------|-----------------|
| accounts | 4562 | Bots ARE accounts (playerbot system) |
| classes | 4662 | Bots have classes, could learn custom abilities |
| mail | 4762 | Bots could receive/send mail (future) |
| narrator | 4862 | Bots are audience for narrator speech |
| feedback | 4962 | (no direct connection) |

For the full WHY behind rmail, see Phase 10's "Thoughts" sections.

---

## Related Phases

- **Phase 5** - Bots can discuss with traveler NPCs
- **Phase 9** - Bots can discuss with narrators (rmail port 4862)
- **Phase 10** - rmail coordination (bots as internal audience)
