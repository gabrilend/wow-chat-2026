# Phase 2 Progress: The Empty World

## Effect

The world is empty. Only spirit healers remain.

## Status: Ready

## Goal

Establish the blank canvas that all other systems paint on. Strip the retail
WoW world of creatures, vendors, and quest givers, leaving an eerie emptiness
that the ambush and traveler systems will populate.

---

## Issues

| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 112 | fix-drop-creatures-cascading-errors | Completed | FK constraint handling |
| 130 | ale-initialization-hook-fix | Completed | ALE loads correctly |
| 136 | drop-all-creatures-except-spirit-healers | Ready | SQL created |

## Completed: 2/3

---

## Completion Criteria

- [x] ALE initializes correctly and loads Lua scripts
- [x] Foreign key cascading handled correctly
- [ ] Fresh database has no creature spawns except spirit healers
- [ ] No static NPCs (vendors, guards, quest givers)
- [ ] World feels empty and dangerous

---

## Key Files

- `sql/custom/db_world/drop-creatures.sql` - Creature removal SQL
- `src/lua/init.lua` - Lua script entry point
- `modules/mod-ale/` - ALE module source

---

## Dependencies

- Phase 1 (foundation) - Server must build and run

---

## Creature Removal (136)

### SQL Approach

```sql
-- Keep only spirit healers (entry 6491)
DELETE FROM creature WHERE id != 6491;

-- Or use creature_template approach:
-- Set all spawns to respawn_time = -1 except spirit healers
```

### What Gets Removed

- All hostile creatures (wolves, bandits, etc.)
- All friendly NPCs (vendors, trainers, guards)
- All quest givers
- All rare spawns
- All world bosses

### What Stays

- Spirit Healers (entry 6491) - resurrection
- Gameobjects (nodes, chests, doors)
- Triggers and invisible markers

### Cascading Considerations (112)

Creature removal can break foreign key relationships:
- `creature_addon` references `creature.guid`
- `creature_queststarter` references `creature.id`
- Various other tables

Solution: Delete in correct order, or use CASCADE.

---

## ALE Initialization (130)

### The Problem

ALE wasn't initializing on server start:
- `OnBeforeConfigLoad` hook not firing
- Lua scripts never loaded
- All custom gameplay broken

### The Fix

Move initialization to `OnBeforeWorldInitialized` hook:
- More reliable timing
- Guard checks prevent crashes
- Remove conflicting `mod_eluna.conf`

### Verification

After fix, check server log for:
```
[ALE] Loading Lua scripts...
[ALE] Loaded X scripts from src/lua/
```

---

## Notes

### Empty World Philosophy

The empty world is foundational to the roguelike feel:
- No safety anywhere
- Help comes to you (travelers)
- Danger comes to you (ambush)
- You are alone in a hostile wilderness

### Spirit Healers Only

Why keep spirit healers:
- Death must have consequences but not frustration
- Corpse runs in empty world would be brutal
- Spirit healers provide resurrection points
- They're ethereal, fitting the empty aesthetic

### Testing Empty World

1. Create fresh character
2. Walk around starting zone
3. Should see NO creatures except spirit healers
4. Should see NO NPCs (vendors, trainers)
5. Gameobjects (mailboxes, etc.) may remain

---

## rmail Integration (Reference)

The empty world doesn't use rmail - it IS the void that makes rmail-integrated
presences meaningful. Emptiness is negative space.
See **Phase 10** for the full rmail treatment with design philosophy.

### Emptiness as Contrast

Without emptiness, rmail-integrated systems lose their impact:

| System | Phase | rmail Port | Why Emptiness Matters |
|--------|-------|------------|----------------------|
| Trainers | 5 → 7 | 4662 | A wandering trainer is special because no one else is there |
| Narrators | 5 → 9 | 4862 | A storytelling voice pierces the silence |
| Feedback | 10 | 4962 | The empty world IS the experience being reported |

### The Void and the Voice

```
THOUGHT: Emptiness is not nothing. Emptiness is potential.

A crowded world numbs you. Another NPC, another vendor, another guard.
You stop seeing them. They become noise.

An empty world wakes you up. Movement on the horizon - what is it?
Friend or enemy? Help or death?

When a narrator wanders into view, reading poetry aloud,
you NOTICE. You stop. You listen.
Because silence preceded the voice.

The empty world is the rest between notes.
rmail-integrated NPCs are the melody.
Without the rest, the melody is just sound.
```

### How Emptiness Enables rmail

```
Phase 2: Empty World (The Void)
    │
    │ Creates silence / negative space
    │
    ├────────────────────────────────────────┐
    │                                        │
    ▼                                        ▼
Phase 5: Travelers                    Phase 3: Ambush
(presence in absence)                 (danger in silence)
    │                                        │
    │                                        │
    ▼                                        ▼
Phase 7: Trainers                    Phase 9: Narrators
    │                                        │
    ▼                                        ▼
rmail (4662)                         rmail (4862)
Custom classes                       Speech subscription
    │                                        │
    └────────────────┬───────────────────────┘
                     │
                     ▼
              Phase 10: Coordination

The empty world is the prerequisite for presence to matter.
```

### Spirit Healers and Emptiness

Spirit healers remain because death needs a response.
But they're ethereal - not quite present.
They reinforce the emptiness rather than filling it.

```
THOUGHT: The spirit healer is the exception that proves the rule.

One ghostly figure at the graveyard.
Not a vendor. Not a trainer. Not a guard.
Just a quiet offer: return to life.

The spirit healer doesn't break the emptiness.
It defines the boundary. Here is death. Here is return.
Everything else - the living world - is empty.
```

### Service Architecture (Preview)

| Service | Port | Relationship to Emptiness |
|---------|------|--------------------------|
| accounts | 4562 | Accounts enter empty world |
| classes | 4662 | Classes survive in empty world |
| mail | 4762 | Messages across empty space |
| narrator | 4862 | Voice in the wilderness |
| feedback | 4962 | Reports about the empty experience |

For the full WHY behind rmail, see Phase 10's "Thoughts" sections.

---

## Related Phases

- **Phase 3** - Ambush system populates with danger
- **Phase 5** - Traveler system populates with help
- **Phase 9** - Narrators pierce the silence (rmail port 4862)
- **Phase 10** - rmail coordination (emptiness enables impact)
