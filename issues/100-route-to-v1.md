# 100 - Route to v1.0

## Purpose

This issue defines the complete feature set for Everland Ghostsong v1.0.
**Only features described in README.md are in scope.** Everything else is out of scope until v1.0 ships.

When looking for work toward v1.0, reference this file.
When considering new features, check if they're listed here first.

---

## Feature Checklist

### 1. Empty World

The world contains no NPCs, creatures, or vendors by default.

| Feature | Status | Issue | Notes |
|---------|--------|-------|-------|
| Remove all creature spawns | Partial | 136 | SQL created, needs testing |
| Keep spirit healers only | Partial | 136 | Part of creature removal |
| Remove static NPCs | Open | - | Vendors, quest givers, guards |
| Verify empty world on fresh install | Open | - | End-to-end test |

### 2. Ambush System (Monster Spawning)

Monsters spawn around players on a timer and chase them.

| Feature | Status | Issue | Notes |
|---------|--------|-------|-------|
| Monsters spawn 120-160 yards from player | Done | - | ambush.lua |
| Spawn timer ~40 seconds base | Done | 124 | Random walk algorithm |
| Timer drifts randomly (±2-4 seconds) | Done | 124 | Floor 10s, soft cap 100s |
| Monsters chase player | Done | - | Standard AI |
| Grouping spawns stronger enemies | Open | - | Scale spawn level/count |
| Grace period on login (30s) | Done | 124 | Only after 10+ min offline |

### 3. Traveler System (Friendly NPCs)

Merchants, trainers, and quest givers wander into view periodically.

| Feature | Status | Issue | Notes |
|---------|--------|-------|-------|
| Travelers spawn ~130 seconds | Done | - | travel.lua |
| Travelers sit when player sits | Done | 320 | Social mirroring |
| Merchants wander by | Open | - | Need merchant travelers |
| Class trainers wander by | Open | 157 | Dynamic trainer spawning |
| Quest givers wander by | Open | - | Future feature |
| Travelers despawn after wandering away | Done | 147 | Clear data on despawn |

### 4. Treasure System (Chest Spawning)

Chests appear nearby with level-appropriate loot.

| Feature | Status | Issue | Notes |
|---------|--------|-------|-------|
| Chests spawn ~100 seconds | Done | - | treasure.lua |
| Loot scaled to player level | Done | - | Level-appropriate items |
| Sold items enter shared pool | Blocked | 149 | Needs 150 (C++ hook) |
| Items appear in other players' chests | Blocked | 149 | Depends on pool system |
| Can't see items in your own chest | Done | 148, 160 | Holder/searcher mechanic |
| Second player must loot for you | Done | 154 | Multiplayer chest access |
| Death costs durability | Done | 152 | Equipment damage on death |

### 5. Sit Mechanic

Sitting pauses combat; enemies orbit instead of attacking.

| Feature | Status | Issue | Notes |
|---------|--------|-------|-------|
| Enemies stop attacking when player sits | Done | - | Aggro disabled on sit |
| Enemies orbit around seated player | Done | 119 | orbit-player behavior |
| Standing re-engages combat | Done | 158 | Aggro re-enabled on stand |

### 6. Playerbots (AI Companions)

Bots wander the world independently and can join parties.

| Feature | Status | Issue | Notes |
|---------|--------|-------|-------|
| Bots wander like travelers | Done | 161 | Traveler-style wandering |
| Bots get bored after combat | Done | 165 | 15% chance on combat end |
| Bots decide what to do next | Done | 164 | Activity selection system |
| Bots explore caves/dungeons | Done | 162 | Dynamic rail pathfinding |
| Bots seek other players when lonely | Done | 161 | Loneliness check |
| Bots sit and rest when hurt | Done | 117 | sit-and-rest behavior |
| Bots follow when invited to party | Done | - | Playerbots module |
| Bots return to wandering when dismissed | Done | 165 | Party leave → boredom |

### 7. Level 20 Cap

Maximum level is 20 with modified progression.

| Feature | Status | Issue | Notes |
|---------|--------|-------|-------|
| Level cap at 20 | Done | 120 | levelling.lua |
| Chunked talent points (10 × 6) | Open | 319 | At levels 5, 8, 11, 14, 17, 20 |
| No respec allowed | Open | 319 | Talents are permanent |
| Tier 1-3 only (no deep talents) | Open | 319 | Block tier 4+ |
| Abilities from trainers (not quests) | Done | 140 | Quest spells → trainers SQL |

**v1.0 Talent System:** 10 points awarded at levels 5, 8, 11, 14, 17, 20 (60 total).
No respec. Limited to first 3 talent tiers.

**v2.0 Plan:** Return to incremental system (3 points per level, respec allowed, all tiers).

### 8. Custom Classes

Players can create custom classes from any abilities.

| Feature | Status | Issue | Notes |
|---------|--------|-------|-------|
| Custom class JSON format | Done | 163 | Design complete |
| Class selection NPC per race | Done | 155 | Race-specific NPCs |
| Dynamic trainer for custom abilities | Done | 157 | Spawns with class abilities |
| Pick any abilities from base game | Open | 163 | Parser implementation |
| Arrange abilities in any order | Open | 163 | Level assignment |
| System is automatic (no approval) | Open | 163 | Validation only |

### 9. Death Knight Scaling

Death Knights start at level 1 with scaled abilities.

| Feature | Status | Issue | Notes |
|---------|--------|-------|-------|
| DK starts at level 1 | Done | 138 | Needs testing |
| DK abilities scaled for 1-20 | Done | 138 | Damage/healing adjusted |
| DK power comparable to other classes | Open | - | Balance testing needed |

---

## Blocking Dependencies

These must be resolved to unblock other features:

| Blocker | Blocks | Status |
|---------|--------|--------|
| 150 (ALE sell item hook) | 149 (sold items to pool) | Needs C++ rebuild |
| 156 (monster accuracy cap) | Balance testing | Needs C++ rebuild |
| C++ rebuild | 150, 156 | In progress |

---

## Out of Scope for v1.0

The following are NOT in the README and are deferred:

- Ocean shark hazards (301)
- Language barrier system (302)
- Chest-bound hearthstones (303)
- rmail integration (306, 313-317)
- Narrator/storytelling system (307, 308, 310-312)
- Invisible level progression (309)
- Bounty board currency (121)
- Portal dimension system (129)
- Dungeon room spawn zones (126-128)
- Embedding-based creature selection (128)
- Profile system removal (318) - operational, not player-facing

---

## V1.0 Definition of Done

All checkboxes above marked "Done" or "Open" must be "Done".
All "Blocked" items must be unblocked and completed.

### Verification Steps

1. Fresh install produces empty world (no creatures except spirit healers)
2. Login triggers grace period, then ambushes start
3. Travelers spawn and wander (including class trainers)
4. Treasure chests spawn and require cooperation to loot
5. Sitting pauses combat, enemies orbit
6. Playerbots wander independently, join parties, have behaviors
7. Level 20 cap works, talent points awarded correctly
8. Custom class system accepts and loads player definitions
9. Death Knights function at level 1-20

### Test Characters

- [ ] Human Warrior to level 20
- [ ] Custom class character
- [ ] Death Knight to level 20
- [ ] Multiplayer chest looting session

---

## Progress Summary

| Category | Done | Open | Blocked | Total |
|----------|------|------|---------|-------|
| Empty World | 0 | 4 | 0 | 4 |
| Ambush System | 5 | 1 | 0 | 6 |
| Traveler System | 3 | 3 | 0 | 6 |
| Treasure System | 4 | 0 | 3 | 7 |
| Sit Mechanic | 3 | 0 | 0 | 3 |
| Playerbots | 8 | 0 | 0 | 8 |
| Level 20 Cap | 2 | 3 | 0 | 5 |
| Custom Classes | 3 | 3 | 0 | 6 |
| DK Scaling | 2 | 1 | 0 | 3 |
| **Total** | **30** | **15** | **3** | **48** |

**Completion: 30/48 (63%)**

---

## Related Documents

- `README.md` - The source of truth for v1.0 features
- `docs/roadmap.md` - Phase overview
- `issues/phase-2-progress.md` - Current phase details
