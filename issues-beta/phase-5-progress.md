# Phase 5 Progress: Friendly Encounters (Travelers)

## Effect

The world has friendly faces. Trainers, merchants wander through.

## Status: Partial

## Goal

Populate the empty world with helpful NPCs that wander into view periodically.
Class trainers, merchants, and other services come to the player rather than
the player seeking them out.

---

## Issues

| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 135 | custom-merchant-system | Open | Wandering merchants with goods |
| 137 | universal-class-trainers | Open | Any trainer teaches any class |
| 207 | clear-traveller-data-on-despawn | Completed | Memory cleanup |
| 157 | dynamic-trainer-spawning | Completed | Trainers spawn for player's class |
| 320 | traveler-sit-with-player | Implemented | Social mirroring behavior |

## Completed: 2/5

---

## Completion Criteria

- [ ] Travelers spawn ~130 seconds apart
- [ ] Travelers wander naturally through the world
- [x] Travelers sit when player sits (social mirroring)
- [ ] Class trainers wander by and offer training
- [ ] Merchants wander by with goods
- [x] Travelers despawn cleanly after wandering away

---

## Key Files

- `src/lua/travel.lua` - Core traveler spawn and movement
- `src/lua/movement.lua` - Shared movement utilities
- `src/lua/custom-classes.lua` - Dynamic trainer integration

---

## Dependencies

- Phase 2 (empty world) - travelers need empty canvas
- Phase 3 (ambush system) - travelers coexist with danger

---

## Notes

### Traveler Spawn Pattern

Travelers use the same spawn geometry as ambush:
- Spawn 50-100 yards from player (closer than ambush)
- Use persistent theta for natural wandering direction
- Despawn when 200+ yards from any player

### Social Mirroring (320)

When player sits within range:
- Traveler stops movement
- Traveler sits facing player
- Creates natural conversation moments
- Resumes wandering when player stands

### Dynamic Trainers (157)

Class trainers spawn as travelers:
- Check player's class on spawn
- Spawn appropriate trainer NPC
- Trainer offers abilities for player's level
- Integrates with custom class system (Phase 7)

---

## rmail Integration (Reference)

Travelers don't directly use rmail, but they are the **foundation** that
rmail-integrated systems build upon. See **Phase 10** for the full rmail
treatment with design philosophy.

### Travelers as Foundation

The traveler system provides spawn and movement patterns reused by:

| System | Phase | rmail Service | Port |
|--------|-------|---------------|------|
| Dynamic Trainers | 5 → 7 | Custom class submission | 4662 |
| Narrators | 5 → 9 | Speech subscription | 4862 |
| Shepherds | 5 → 9 | (none, but uses traveler movement) | - |

### How the Layers Connect

```
Phase 5: Traveler System (Foundation)
    │
    ├── Spawn geometry (50-100 yards from player)
    ├── Persistent theta wandering
    ├── Social mirroring (sit with player)
    └── Despawn at distance
         │
         ├─────────────────────────────────────┐
         │                                     │
         ▼                                     ▼
Phase 7: Trainers                    Phase 9: Narrators
    │                                     │
    │ Trainer spawns as traveler          │ Narrator spawns as traveler
    │ Offers custom class abilities       │ Reads from Gutenberg library
    │                                     │ Shares rumors via PM
    │                                     │
    ▼                                     ▼
rmail (port 4662)                   rmail (port 4862)
    │                                     │
    │ Submit class definitions            │ Subscribe to speech
    │ Receive validation results          │ Receive TTS audio
    │                                     │
    └─────────────────┬───────────────────┘
                      │
                      ▼
               Phase 10: Coordination
               (DNS addresses, login flush, accounts)
```

### Why Travelers Matter for rmail

```
THOUGHT: The traveler is the body. rmail is the voice.

A trainer that spawns from nowhere feels artificial.
A trainer that WANDERS IN feels like a person.
The traveler system makes NPCs feel alive.

When that alive-feeling NPC offers abilities defined via rmail,
the external becomes internal. Your custom class, designed in
a text editor, taught by a wandering sage.

The traveler movement is the embodiment.
rmail is the channel for external content.
Together: external content with internal presence.
```

### Service Architecture (Preview)

| Service | Port | Foundation |
|---------|------|------------|
| accounts | 4562 | (standalone) |
| classes | 4662 | Trainers (Phase 5 → 7) |
| mail | 4762 | (standalone) |
| narrator | 4862 | Narrators (Phase 5 → 9) |
| feedback | 4962 | (standalone) |

For the full WHY behind rmail, see Phase 10's "Thoughts" sections.

---

## Related Phases

- **Phase 6** - Bot companions also wander like travelers
- **Phase 7** - Trainers teach custom class abilities (rmail port 4662)
- **Phase 9** - Narrators reuse traveler movement (rmail port 4862)
- **Phase 10** - rmail coordination (traveler system enables services)
