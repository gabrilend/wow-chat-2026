# Development Roadmap

## Overview

Everland Ghostsong is a WoW 3.3.5a private server with roguelike survival mechanics.
- **Max level:** 20
- **Talent points:** Every 1/3 level
- **World:** Empty by default - monsters spawn around players (ambush system)
- **Companions:** Playerbots as AI party members

---

## Phase 1: Foundation (Complete)

**Goal**: Establish stable server environment with working modules.

### Milestones
- [x] Installation script functional
- [x] Update script functional
- [x] Local MySQL installation
- [x] Server runs without errors
- [x] Playerbots module operational
- [x] mod-ale (Lua engine) operational
- [x] Lua scripts loading and executing
- [x] Profile system (alpha/beta/release)

### Key Issues
- 101-verify-server-startup
- 102-test-playerbots-spawn
- 105-setup-local-mysql-installation
- 130-ale-initialization-hook-fix

---

## Phase 2: Behaviors and Systems (In Progress)

**Goal**: Implement custom playerbot behaviors and core game systems.

### Milestones
- [x] Level 20 cap with 1/3 level talent points
- [x] Ambush spawn system with randomized intervals
- [x] Treasure chest system (per-player queues, holder/searcher)
- [x] Bot behaviors: find-monsters, avoid-monsters, sit-and-rest, orbit-player
- [x] Bot wandering (traveller-style with dungeon navigation)
- [x] Activity selection and boredom system
- [ ] C++ patches applied (150, 156) - **needs rebuild**
- [ ] Sold items to treasure pool (depends on 150)
- [ ] Discuss with NPC behavior
- [ ] Point/line definition tools
- [ ] Dungeon room spawn zones

### Key Issues
- 120: Talent points level 20 cap
- 124: Randomize ambush spawn interval
- 148-154: Treasure chest system
- 114-119: Playerbot behaviors
- 160-166: Behavior orchestration and tooling

### Blocking
- Issues 150/156 need server rebuild to unblock treasure pool integration

---

## Phase 3: World Immersion and Hazards (Planning)

**Goal**: Create a living, dangerous world with storytelling and progression.

### Environmental Hazards
- [ ] Ocean sharks after time threshold (301)
- [ ] Language barriers - racial languages only (302)

### Treasure Expansion
- [ ] Chest-bound hearthstones (303)
- [ ] Zero-value treasure duplicates (305)

### Custom Classes
- [ ] Conditional selector spawn (304)
- [ ] Custom talent interface (345)

### rmail Integration
- [ ] In-game mail bridge (306)
- [ ] DNS-style addresses (313)
- [ ] Feedback mailbox (314)
- [ ] Login flush hook (315)
- [ ] Account creation (317)

### NPC Storytelling
- [ ] Narrator audience facing (307)
- [ ] Gutenberg text library (308)
- [ ] Wandering narrator system (310)
- [ ] Shepherd flock system (311)
- [ ] Automated lore generation (312)

### Progression
- [ ] Invisible level progression past 20 (309)
- [ ] Permadeath and immortality mechanics

---

## Future Phases (Conceptual)

### Phase 4: Social and Economy
- Trading post system
- Bounty board currency
- Cross-faction communication
- Player-driven economy

### Phase 5: Content Generation
- Procedural quest generation
- Dynamic event system
- World state persistence
- Seasonal content

---

## Phase Completion Checklist

For each phase:
1. All issues resolved and moved to `completed/`
2. Phase demo created in `issues/completed/demos/`
3. `phase-X-progress.md` updated with final status
4. Git commit with phase completion summary

## Version Milestones

| Version | Phase | Description |
|---------|-------|-------------|
| 0.1.0 | 1 | Stable foundation |
| 0.2.0 | 2 | Behaviors and systems |
| 0.3.0 | 3 | World immersion |
| 0.4.0 | 4 | Social and economy |
| 1.0.0 | - | Feature complete |

## Related Documents

- `issues/phase-1-progress.md` - Phase 1 detailed status
- `issues/phase-2-progress.md` - Phase 2 detailed status
- `issues/phase-3-progress.md` - Phase 3 detailed status
- `notes/vision` - Project vision and philosophy
