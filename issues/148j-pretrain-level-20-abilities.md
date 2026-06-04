# 148j - Pre-Train All Level-≤20 Class Abilities at Character Creation

## Status
- Created: 2026-06-02
- Phase: 1 (Foundation — profile model)
- Parent: 148 (vanilla profile)
- Sibling: 148h (starting equipment) — runs in parallel; same
  creation-time mechanism
- Priority: Blocking — without this, a level-20 starting character
  knows only their level-1 racial spells and the handful of
  abilities a class normally has at creation. They cannot dual
  wield as a rogue, cannot cast Frostbolt above rank 1 as a mage,
  cannot use the level-20 abilities their kit (148h) is balanced
  around.

## Problem

Vanilla starts characters at level 20 (see 148, C007c). A level-20
character in retail WoW 3.3.5a has, by that point, visited a class
trainer at every even-numbered level and learned roughly thirty to
forty individual spells and weapon skills — each new ability or new
rank of an existing ability granted by a one-line conversation with
their class trainer. Without those nineteen trainer visits, the
freshly-created level-20 character is functionally a level-1
character wearing a level-20 body.

Concrete examples a player would notice immediately:

- A rogue created at level 20 has **no Dual Wield** (normally
  spell 674, learned at level 10). Their off-hand dagger from
  148h's starting kit cannot be equipped.
- A mage has only **Frostbolt rank 1** (level-1 starter spell), not
  the rank 4 a level-20 mage normally has. Damage is roughly a
  third of what mobs at level 20 expect.
- A warrior knows only the abilities a level-1 warrior knows. No
  Charge (level 4), no Rend (level 4), no Thunder Clap (level 6),
  no Mocking Blow (level 6), no Bloodrage (level 10), no
  Demoralizing Shout (level 14), no Heroic Strike rank 2 (level 8)
  or 3 (level 16), etc.

This sub-issue grants, at character creation, every spell and
every weapon skill the class would normally have trained at a
trainer by the time it reaches level 20.

## Scope

Pre-trained at creation:
- **Class trainer spells** (the "level N: visit trainer" pattern)
  for every rank learnable at level ≤ 20.
- **Weapon-skill unlock spells** trained from class trainers, e.g.
  Rogue Dual Wield (674), Warrior Two-Handed Maces, etc., where
  the unlock level is ≤ 20.
- **Class trainer talents/passives** auto-granted by training
  (e.g. proficiencies tied to spells).

Not in scope:
- **Quest-only spells.** If a spell is only obtained from a quest
  (Shaman totem call chain, Warlock pet quests), it stays a quest
  reward. Players can do those quests in-game.
- **Starting racials.** Already granted by the engine at creation.
- **Profession spells.** First aid, cooking, fishing, gathering —
  players opt into these by visiting a profession trainer.
- **Talents.** Talent points are spent by the player; this issue
  only grants the abilities the trainer would have given.

## Data Source

The authoritative table for trainer-taught abilities in AzerothCore
is `npc_trainer`:

| Column | Meaning |
|--------|---------|
| `entry` | Trainer creature ID |
| `SpellID` | Spell taught |
| `MoneyCost` | Cost in copper |
| `ReqSkillLine` | Skill line prerequisite (0 = none) |
| `ReqSkillRank` | Skill rank prerequisite |
| `ReqLevel` | Character level required to learn the spell |
| `ReqSpell` | Prerequisite spell |

Joined against `creature_template` filtered to class-trainer
creatures, this yields the (class, spell) pairs to grant.

**Identifying class trainers.** Class trainers have `npcflag` bit
`NPC_FLAG_TRAINER_CLASS` (0x10 — bit 4) set; the trainer's class
specialty is encoded in `creature_template.trainer_class` (a
direct class ID 1..11). Filter:

```sql
SELECT ct.trainer_class AS class_id, nt.SpellID, nt.ReqLevel
FROM creature_template ct
JOIN npc_trainer nt ON nt.entry = ct.entry
WHERE ct.npcflag & 0x10
  AND ct.trainer_class BETWEEN 1 AND 11
  AND ct.trainer_class <> 6   -- DK excluded per 148a
  AND nt.ReqLevel <= 20
ORDER BY class_id, SpellID;
```

The same spell often appears in multiple trainer entries (Stormwind
mage trainer, Ironforge mage trainer, etc.). De-duplicate to
`DISTINCT class_id, SpellID` before generating INSERT rows.

## Granting Mechanism

The target table is `playercreateinfo_spell_custom`:

| Column | Meaning |
|--------|---------|
| `race` | Race ID, or 0 for "any race" |
| `class` | Class ID 1..11 |
| `Spell` | Spell ID to grant at creation |
| `Note` | Free-text description |

For the vanilla pre-train migration: one row per (class, spell)
with `race=0`. The engine grants the spell to every character of
that class regardless of race at creation time.

Rank handling: WoW spells have explicit rank IDs (Frostbolt rank 1
is spell 116, rank 2 is 205, rank 4 is 7322, etc.). The
`npc_trainer` table lists each rank as its own row with its own
`ReqLevel`. Selecting `ReqLevel <= 20` naturally pulls every rank
the player would have learned by level 20 — no rank-resolution
logic required.

The engine automatically supersedes lower ranks when a higher rank
is known, so granting all ranks 1 through N at creation is safe
and results in the player's spellbook showing only the highest
rank, exactly as if they had trained each rank in order.

## Implementation Approach

Mirrors 148a and 148h: a vanilla-profile-only SQL migration
applied by `scripts/install` when `PROFILE=vanilla`.

### File layout
- `sql/vanilla/04-pretrain-abilities.sql` — DELETE existing
  `playercreateinfo_spell_custom` rows for `Note LIKE 'vanilla-148j-%'`
  (so the migration is idempotent), then INSERT the full set.

### Generation strategy
The SQL file should be generated, not hand-written. Hand-curating
~300 (class, spell) rows invites typos and grows stale every time
upstream AzerothCore updates trainer data. Approach:

1. Write a generator script (`scripts/generate-148j-sql` or
   similar; bash or Lua) that runs the join query above against
   `acore_world_release` (substrate DB during build; the same
   data lands in `acore_world_vanilla` after install).
2. Generator emits a single `sql/vanilla/04-pretrain-abilities.sql`
   with the DELETE+INSERT block.
3. Re-run the generator any time upstream trainer data shifts
   (handful of times per year) and re-commit the regenerated SQL.
4. The committed SQL is the source of truth applied by
   `scripts/install` — the generator script is a build-time tool,
   not a runtime dependency.

This keeps the migration deterministic and auditable while not
locking the project into hand-typed spell IDs.

### Idempotence
The DELETE step removes only rows tagged with the migration's
`Note` prefix (`'vanilla-148j-%'`). Re-running the migration after
a regeneration produces the same end state without touching rows
inserted by other sub-issues or upstream data.

## Implementation Steps

1. Write the generator script that runs the `npc_trainer` ⋈
   `creature_template` query and emits SQL.
2. Run the generator against the playerbot-fork world DB content
   that `scripts/install` will populate for vanilla. Confirm the
   spell counts look sane (~30–50 per class).
3. Commit the generated `sql/vanilla/04-pretrain-abilities.sql`.
4. Hook the migration into `scripts/install` after S4 (starting
   equipment).
5. Test: create one character of each enabled class, log in, open
   the spellbook, confirm each class shows the spells it should
   have at level 20. Pay special attention to:
   - Rogue spellbook contains Dual Wield (674) and the level-20
     versions of Sinister Strike, Eviscerate, Backstab.
   - Mage spellbook contains Frostbolt rank 4, Fireball rank 3+,
     Frost Nova rank 1, Polymorph, Counterspell if ≤20.
   - Warrior spellbook contains Charge, Rend, Thunder Clap,
     Demoralizing Shout, Heroic Strike rank 3.
   - Shaman spellbook contains the foundational totem-summoning
     spells, Lightning Bolt rank 4, Earth Shock, Healing Wave
     rank 3.
   - Hunter spellbook contains Aspect of the Monkey, Mongoose Bite,
     Wing Clip, Concussive Shot, plus the pet-related spells.
   - Druid spellbook contains Bear Form, Cat Form (level 20!),
     Healing Touch ranks, Wrath ranks.
6. Equipment cross-check with 148h: confirm Rogue's off-hand
   dagger (5093 Razormane Backstabber) is equippable — meaning
   Dual Wield was successfully granted.

## Cross-References

- 148  — parent vanilla-profile issue
- 148h — starting equipment (S4); this migration runs after it
- C007c-starting-level-20.sh — the `StartPlayerLevel=20` setting
  that creates the gap this migration fills
- R5+R6 results in the 148 parallelization roadmap — DK is
  excluded from `class BETWEEN 1 AND 11` filter via the
  `trainer_class <> 6` clause

## Open Questions

- **Should the cap track `StartPlayerLevel` if it changes?** Yes —
  this migration is paired with the start-level decision. If the
  vanilla starting level ever shifts, regenerate with the matching
  `ReqLevel <= N` filter.
- **What about ability ranks the player trains AT level 20
  exactly?** Included. `ReqLevel <= 20` matches `ReqLevel = 20`.
- **Talent points?** Granted automatically by the engine based on
  level; no migration needed. The player still chooses where to
  spend them.
- **Race-specific spell variants** (e.g. Troll Berserking is a
  racial, granted by the engine; Tauren War Stomp is a racial).
  These are out of scope — the engine handles racials at level 1.
