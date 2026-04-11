# Phase 3 Progress: Danger (Ambush System)

## Effect

Monsters spawn around players. The hunt begins.

## Status: Mostly Complete

## Goal

Create the core danger loop: monsters appear near players on a timer, chase
them down, and create constant tension. Environmental hazards extend the
danger beyond land.

---

## Issues

| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 302 | investigate-ambush-monsters-not-spawning | In Progress | Debug spawn issues |
| 303 | randomize-ambush-spawn-interval | Completed | Random walk algorithm |
| 304 | clear-ambush-data-on-death | Completed | Memory cleanup |
| 305 | ambush-aggro-and-corpse-movement | Implemented | Aggro/corpse fixes |
| 301 | ocean-shark-hazard | Open | Water danger |
| 324 | nil-bot-periodic-event-crash | Open | Crash fix |
| 325 | ale-gameobject-wildcard-registration | Open | Event registration |

## Completed: 2/7 (1 more implemented, needs testing)

---

## Completion Criteria

- [x] Monsters spawn 120-160 yards from players
- [x] Spawn interval uses random walk algorithm
- [x] Grace period on login (30s after 10+ min offline)
- [x] Monsters chase and attack players
- [x] Corpses don't slide after death
- [x] Aggro re-enables when player stands
- [ ] Ocean sharks spawn in deep water
- [ ] Spawn issues fully debugged

---

## Key Files

- `src/lua/ambush.lua` - Core spawn system
- `src/lua/movement.lua` - Position calculations
- `src/lua/periodic_events.lua` - Timer management

---

## Dependencies

- Phase 1 (foundation) - ALE must work
- Phase 2 (empty world) - No retail creatures to conflict

---

## Ambush Spawn Geometry

### Distance Calculation

```
Player position: (px, py, pz)
Spawn angle: random 0 to 2π
Spawn distance: random 120 to 160 yards

Spawn position:
  x = px + cos(angle) * distance
  y = py + sin(angle) * distance
  z = map:GetHeight(x, y)
```

### Height Validation

Reject spawn if height difference too large:
- `SPAWN_MAX_HEIGHT = 15` yards
- Prevents spawning on cliffs above/below player

### Creature Selection

Select creature appropriate for player level:
- Query `creature_template` for level range
- Random selection from valid entries
- Future: embedding-based selection (Phase 9)

---

## Random Walk Interval (303)

### Algorithm

```
current_interval = 40000  -- ms (base)

on_spawn:
  jitter = random(2000, 4000)  -- 2-4 seconds
  direction = random_sign()     -- +1 or -1
  current_interval = current_interval + (jitter * direction)

  -- Floor: only goes up when reached
  if current_interval < 10000 then
    current_interval = 10000
    direction = +1
  end

  -- Soft cap: bias toward down
  if current_interval > 100000 then
    direction = random() < 0.33 and +1 or -1
  end

  -- Hard cap: strong bias toward down
  if current_interval > 200000 then
    direction = random() < 0.20 and +1 or -1
  end
```

### Effect

- Creates unpredictable spawn timing
- Sometimes rapid bursts, sometimes lulls
- Floor prevents overwhelming spawn rates
- Caps prevent excessively long waits

---

## Grace Period

### Trigger Conditions

- Player logs in
- Player was offline for 10+ minutes

### Behavior

- 30 second fixed grace period
- No ambush spawns during grace
- Timer starts after grace expires
- Quick relogs (< 10 min) resume immediately

### Purpose

- Prevents instant death on login
- Gives player time to orient
- Doesn't reward logout/login spam

---

## Combat Fixes (305)

### Corpse Sliding

**Problem**: Corpses continued moving after death.

**Cause**: `MoveTo` commands still executing on dead creatures.

**Fix**: Call `creature:MoveClear()` in `onCreatureDeath` handler.

### Aggro Lock

**Problem**: Monsters wouldn't attack after player stood from sitting.

**Cause**: Aggro disabled during sit/orbit mode, never re-enabled.

**Fix**: Call `creature:SetAggroEnabled(true)` when player stands.

---

## Ocean Shark Hazard (301)

### Concept

Deep water becomes dangerous over time:
- Timer starts when player enters deep water
- After threshold (60s?), sharks spawn
- Sharks are fast and deadly
- Discourages aimless swimming

### Implementation Notes

- Hook `PLAYER_EVENT_ON_UPDATE_ZONE` or periodic check
- Track time in water per player
- Spawn shark creature when threshold reached
- Shark despawns when player leaves water

---

## Notes

### Ambush Data Cleanup (304)

When creature dies or despawns:
- Clear tracking data from player
- Remove from active spawn count
- Free GUID for reuse

Prevents memory leaks and spawn count drift.

### Periodic Event Crash (324)

Crash when bot is nil during periodic event:
- Bot logged out between event registration and callback
- Need nil check before processing
- Common pattern in all periodic events

### Gameobject Wildcard (325)

Allow registering events for entry 0 (all gameobjects):
- Useful for chest interaction hooks
- Currently requires specific entry registration
- C++ patch to ALE needed

---

## rmail Integration (Reference)

The ambush system doesn't directly use rmail, but it creates the **pressure**
that gives rmail-integrated systems their meaning. Danger is the gravity.
See **Phase 10** for the full rmail treatment with design philosophy.

### Danger as Context

Without danger, other systems lose their weight:

| System | Phase | rmail Port | Why Danger Matters |
|--------|-------|------------|-------------------|
| Custom Classes | 7 | 4662 | Abilities matter when survival isn't guaranteed |
| Narrators | 9 | 4862 | A calm voice is precious in a hostile world |
| Feedback | 10 | 4962 | Balance reports flow from deadly encounters |
| Accounts | 10 | 4562 | Permadeath makes account lifecycle meaningful |

### How Danger Creates Value

```
Phase 3: Danger (Ambush System)
    │
    │ Creates pressure
    │
    ├──────────────────────────────────────────────────────┐
    │                         │                            │
    ▼                         ▼                            ▼
Phase 7                   Phase 9                     Phase 10
Custom Classes            Narrators                   Feedback
    │                         │                            │
    │ "I need abilities      │ "A moment of peace        │ "This balance
    │  to survive this"      │  amid the chaos"          │  feels off"
    │                         │                            │
    ▼                         ▼                            ▼
rmail (4662)              rmail (4862)                rmail (4962)
Submit class def          Subscribe to speech         Send feedback
```

### The Danger-Meaning Loop

```
THOUGHT: Danger is the question. Everything else is the answer.

A custom class is a bet. "I think THIS combination will keep me alive."
The ambush system tests that bet. Wrong answer? Dead.

A narrator is a respite. You sit, you listen, you breathe.
But only because the alternative is running, fighting, dying.
The peace has meaning because the danger is real.

Feedback about balance matters because balance is life and death.
"Wolves hit too hard at level 5" isn't a preference - it's survival data.

The ambush system doesn't USE rmail.
The ambush system makes rmail MATTER.
```

### Creature Selection and rmail (Future)

Phase 9 introduces embedding-based creature selection:
- Each zone has a thematic embedding
- Creatures selected by semantic similarity
- Creates thematically consistent encounters

This connects to rmail through automated lore generation (312):
- Ollama generates creature backstories
- Backstories inform embedding vectors
- The danger becomes narratively coherent

### Feedback Flow

When ambush balance issues arise:

```
Player encounters
    ↓
Dies to something unfair (or too easy)
    ↓
Sends feedback via rmail (port 4962)
    ↓
Balance adjustments made
    ↓
Updated spawn parameters
    ↓
Better encounters
```

The danger system is the PRIMARY source of player feedback.
It's where the game is won or lost.

### Service Architecture (Preview)

| Service | Port | Relationship to Danger |
|---------|------|----------------------|
| accounts | 4562 | Permadeath deletes accounts |
| classes | 4662 | Abilities to survive danger |
| mail | 4762 | (indirect - communicate about encounters) |
| narrator | 4862 | Peace amid danger |
| feedback | 4962 | Balance reports from deaths |

For the full WHY behind rmail, see Phase 10's "Thoughts" sections.

---

## Related Phases

- **Phase 2** - Empty world provides canvas for danger
- **Phase 4** - Treasure spawns alongside ambush
- **Phase 7** - Custom classes answer the danger (rmail port 4662)
- **Phase 8** - Monster level scales with invisible progression
- **Phase 9** - Narrators provide peace amid danger (rmail port 4862)
- **Phase 10** - rmail coordination (feedback flows from danger)
