# Phase 8 Progress: Progression & Endgame

## Effect

Players level, gain talents, face permadeath, achieve immortality.

## Status: Partial

## Goal

Define the full progression arc from level 1 to immortality. Level cap at 20,
chunked talent points, invisible progression past 20, mandatory grouping at
endgame, and the ultimate stakes of permadeath.

---

## Issues

Ordered by narrative arc: combat fairness → talent constraints →
post-20 endgame → shared-character meta layer.

### Combat fairness (the floor)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 803 | monster-accuracy-level-cap | Implemented | ±3 level hit cap (C++ patch). Blocks 801 since hit-rate affects damage. |
| 801 | proportional-damage-rewards | Open | XP based on contribution. Depends on 803 for fair hit rates. |

### Talent constraints (the cap before endgame)
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 802 | talent-tier-limit | Open | Block tier 4+ talents (cap at first 3 tiers). |

### Post-20 endgame
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 804 | invisible-level-progression | Open | Post-20 invisible XP tracking. Mandatory grouping at high invisible levels. Permadeath / immortality at invisible 60. |

### Shared-character meta
| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| 805 | vavadane-shared-daily-reset-character | Open | One shared character that resets daily. Cross-player layer above per-character progression. |

## Completed: 0/5 (1 Implemented)

Note: Issues 205 (talent-points-level-20-cap) and 206 (death-knight-level-1-scaling)
moved to Phase 2. Issue 714 (chunked-talent-points) moved to Phase 7.

---

## Completion Criteria

- [x] Level cap at 20
- [ ] Talent points awarded in chunks (10 at levels 5, 8, 11, 14, 17, 20)
- [ ] No talent respec (permanent choices)
- [ ] Talents limited to first 3 tiers
- [x] Death Knights start at level 1 with scaled abilities
- [x] Monster accuracy capped at ±3 levels (needs C++ rebuild)
- [ ] Invisible XP tracking after level 20
- [ ] Monsters scale with invisible level (20 + invisible)
- [ ] No spawn cap for invisible-level players (mandatory grouping)
- [ ] Permadeath: death with no equipment = character deleted
- [ ] Immortality at invisible level 60: gold coin, no more spawns

---

## Key Files

- `src/lua/levelling.lua` - XP handling, talent points
- `src/lua/ambush.lua` - Spawn level selection, cap checks
- `docs/patches/accuracy-level-cap.md` - C++ patch documentation

---

## Dependencies

- Phase 1 (foundation) - Server must run stably
- Phase 3 (ambush) - Spawn system handles invisible level scaling
- Phase 7 (custom classes) - Talent interface for spending points

---

## Talent System

### V1.0: Chunked Points (319)

| Level | Points Awarded | Total |
|-------|---------------|-------|
| 5 | 10 | 10 |
| 8 | 10 | 20 |
| 11 | 10 | 30 |
| 14 | 10 | 40 |
| 17 | 10 | 50 |
| 20 | 10 | 60 |

- No respec allowed
- Talents are permanent choices
- Forces commitment to build identity

### Tier Limit (141)

Only first 3 tiers of talents available:
- Tier 1: 0 points required
- Tier 2: 5 points in tree
- Tier 3: 10 points in tree
- Tier 4+: BLOCKED

This prevents deep-tree 31-point talents that would be too powerful at 20.

### V2.0 Plan (Post-Release)

Return to incremental system:
- 3 points per level (1/3 level = 1 point)
- Respec allowed
- All tiers unlocked
- More traditional progression feel

---

## Invisible Level System (309)

### XP Tracking

After level 20, XP continues accumulating invisibly:
- Stored in character data: `invisible_xp`
- Thresholds match normal 21-80 curve
- Player sees level 20, but invisible level increases

### Monster Scaling

Ambush spawns scale with invisible level:

| Invisible Level | Monster Level | Notes |
|-----------------|--------------|-------|
| 0 | 20 | Fresh level 20 |
| 5 | 25 | Early endgame |
| 20 | 40 | Mid endgame |
| 40 | 60 | Late endgame |
| 60 | 80 | Immortality threshold |

### Mandatory Grouping

**Players with invisible XP have NO spawn cap.**

Normal players (1-19): Limited concurrent ambush spawns.
Invisible-level players: Unlimited spawns. They pile up.

Solo play becomes impossible. Groups required to survive.
Creates natural social pressure toward cooperation.

### Permadeath

**Death while wearing no equipment = character deletion.**

- Can "opt out" of danger by unequipping and sitting
- But if something kills you naked, you're done forever
- Creates high-stakes equipment management
- Strategic use of vulnerability windows

### Immortality

Reach invisible level 60 (effective level 80):
- Gold coin arrives in mailbox
- Monsters stop spawning forever
- Player has "won" the game
- Can continue playing as immortal helper

---

## Monster Accuracy Cap (156)

C++ patch caps level difference for hit calculations:
- `ACCURACY_LEVEL_CAP = 3`
- `ACCURACY_SKILL_CAP = 15`

Effects:
- Level 50 monster vs level 20 player: calculated as ±3
- High-level monsters are dangerous but hittable
- Low-level monsters retain some threat

Does NOT cap damage/HP/armor - only hit chance.

---

## Death Knight Scaling (206)

DKs normally start at level 55. For level 20 cap:
- Start at level 1 instead
- Abilities scaled to 1-20 range
- Damage/healing values reduced proportionally
- Power comparable to other classes at same level

### Scaling Formula

```
scaled_value = original_value * (target_level / 55)
```

Example: Icy Touch at 55 deals 227 damage.
At level 10: `227 * (10/55) = 41 damage`

---

## Notes

### Proportional Damage Rewards (139)

XP distributed based on damage contribution:
- Prevents kill stealing
- Encourages cooperation
- Supports invisible-level group play

### Shared Daily Reset (322)

Special character that resets daily:
- Community shares single character
- Progress resets each day
- Experimental social gameplay mode

---

## rmail Integration (Reference)

Phase 8 has the **most direct rmail connection**: permadeath triggers account deletion.
When stakes are permanent, the account service matters. See **Phase 10** for the full
rmail treatment with design philosophy.

### Permadeath → Account Deletion

The progression system defines when characters die permanently:
- Death with no equipment = character deleted
- Character deletion triggers rmail account service (port 4562)
- rmail account deleted (if using ephemeral guest accounts)
- The external identity mirrors the internal death

```
THOUGHT: Permadeath is the ultimate stake.

Most games, death is a setback. You respawn, you try again.
In Everland Ghostsong, death while naked is THE END.

But what does that mean for the player outside the game?
If they had an rmail account tied to that character...
The account dies too. The inbox is cleared. The subscriptions end.

This is deliberate. Identity inside reflects identity outside.
Your character's death doesn't just affect the game world.
It ripples outward. The echo of permadeath crosses borders.
```

### Account Lifecycle

| Game Event | rmail Event | Service |
|------------|-------------|---------|
| New character | (none or create) | accounts (4562) |
| Level to 20 | (normal play) | - |
| Invisible progression | (normal play) | - |
| Permadeath | Account deletion | accounts (4562) |
| Immortality | Permanent account | accounts (4562) |

### Immortality and rmail

Reaching invisible level 60 grants immortality:
- Gold coin delivered via in-game mail
- Mail system connects to rmail (port 4762)
- The coin is PROOF - it came from outside

```
THOUGHT: The gold coin is the only external reward.

Everything else in the game, you find or earn inside.
Loot from chests, abilities from trainers, progress from kills.

But the gold coin for immortality? It arrives by MAIL.
Someone outside the game sent it. The system acknowledges you.

The coin isn't just a token. It's a message.
"You made it. You won. Welcome to forever."

This is rmail's ultimate expression: external validation
of internal achievement. The game can't give you this.
Only the world outside can send this particular letter.
```

### Progression Stakes and rmail Meaning

Higher stakes make services meaningful:

| Stake Level | What It Means | rmail Impact |
|-------------|---------------|--------------|
| Normal death | Durability loss | None |
| Permadeath | Character gone | Account deleted |
| Immortality | Won forever | Account permanent |

Without permadeath, rmail accounts are just convenience.
With permadeath, rmail accounts have life and death.

### Feedback from Progression

Balance reports flow most heavily from progression issues:
- "Invisible level 35 spawns are impossible solo"
- "Chunked talents feel weird at level 8"
- "DK scaling feels weak compared to Warrior"

These reach the feedback service (port 4962).
Progression is where the design is tested most harshly.

```
THOUGHT: Progression is the crucible.

Everything else - ambush, treasure, companions - is experienced.
But progression is MEASURED. You either survived or you didn't.

The feedback from invisible-level players is the most valuable.
They've been through the whole system. They know what works.
Their deaths are the data. Their survival is the proof.

rmail feedback from endgame players shapes the game
for everyone who comes after. The dead teach the living.
```

### Service Architecture (Preview)

| Service | Port | Progression Relationship |
|---------|------|-------------------------|
| accounts | 4562 | **Permadeath deletes accounts** |
| classes | 4662 | Custom classes used throughout progression |
| mail | 4762 | **Immortality coin delivered via mail** |
| narrator | 4862 | Narrators explain invisible level lore |
| feedback | 4962 | **Balance reports from progression deaths** |

For the full WHY behind rmail, see Phase 10's "Thoughts" sections.

---

## Related Phases

- **Phase 3** - Ambush system handles level scaling
- **Phase 7** - Talent interface for spending chunked points
- **Phase 9** - Shepherd system explains immortality lore
- **Phase 10** - rmail coordination (permadeath triggers account lifecycle)
