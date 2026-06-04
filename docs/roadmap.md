# Development Roadmap

## Overview

Everland Ghostsong is a WoW 3.3.5a private server with roguelike survival mechanics.
- **Max level:** 20
- **Talent points:** Every 1/3 level
- **World:** Empty by default — monsters spawn around players (ambush system)
- **Companions:** Playerbots as AI party members

---

## Phase 1: Foundation (Complete)

**Goal:** Establish stable server environment with working modules.

### Milestones
- [x] Installation script functional
- [x] Update script functional
- [x] Local MySQL installation
- [x] Server runs without errors
- [x] Playerbots module operational
- [x] mod-ale (Lua engine) operational
- [x] Lua scripts loading and executing
- [x] Profile system — canonical definitions in
      `issues/136-canonical-profile-definitions.md`
      (alpha = legacy holiday relic, release = current public target,
       beta = release + in-dev features)

---

## Phase 2: Behaviors and Systems (In Progress)

**Goal:** Implement custom playerbot behaviors and core game systems.

### Milestones
- [x] Level 20 cap with 1/3 level talent points
- [x] Ambush spawn system with randomized intervals
- [x] Treasure chest system (per-player queues, holder/searcher)
- [x] Bot behaviors: find-monsters, avoid-monsters, sit-and-rest, orbit-player
- [x] Bot wandering (traveller-style with dungeon navigation)
- [x] Activity selection and boredom system
- [x] ALE sell-item hook landed (B006)
- [x] Accuracy level cap landed (B005)
- [ ] Sold items to treasure pool (uses B006)
- [ ] Discuss-with-NPC behavior
- [ ] Point/line definition tools
- [ ] Dungeon room spawn zones

---

## Phase 3: World Immersion and Hazards (Planning)

**Goal:** Create a living, dangerous world with storytelling and progression.

### Environmental Hazards
- [ ] Ocean sharks after time threshold
- [ ] Language barriers — racial languages only

### Treasure Expansion
- [ ] Chest-bound hearthstones
- [ ] Zero-value treasure duplicates

### Custom Classes
- [ ] Conditional selector spawn
- [ ] Custom talent interface

### rmail Integration
- [ ] In-game mail bridge
- [ ] DNS-style addresses
- [ ] Feedback mailbox
- [ ] Login flush hook
- [ ] Account creation

### NPC Storytelling
- [ ] Narrator audience facing
- [ ] Gutenberg text library
- [ ] Wandering narrator system
- [ ] Shepherd flock system
- [ ] Automated lore generation

### Progression
- [ ] Invisible level progression past 20
- [ ] Permadeath and immortality mechanics

(Issue numbers in this section have shifted under successive renumbering
passes — consult `issues/` directly for the current ticket IDs rather than
trusting numbers transcribed here.)

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
| 0.1.0   | 1     | Stable foundation |
| 0.2.0   | 2     | Behaviors and systems |
| 0.3.0   | 3     | World immersion |
| 0.4.0   | 4     | Social and economy |
| 1.0.0   | -     | Feature complete |

## Related Documents

- `issues/phase-1-progress.md` — Phase 1 detailed status
- `issues/phase-2-progress.md` — Phase 2 detailed status
- `issues/phase-3-progress.md` — Phase 3 detailed status
- `notes/vision` — Project vision and philosophy
