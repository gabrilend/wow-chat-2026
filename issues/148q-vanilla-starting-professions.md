# 148q - Vanilla Starting Professions (gathering by race, production by class)

## Status
- Created: 2026-07-13
- **Completed: 2026-07-15** — applied live to `acore_world_vanilla`
  (20 skill rows, 354 recipe rows, 72 tool rows), shipped as E021. Three
  refinements to the spec surfaced during the build:
  1. **No generator.** Recipes come straight from `trainer_spell` via
     `INSERT … SELECT` (`skill_line_ability` is an empty DBC table here),
     so the migration is ~120 lines of pure, data-derived SQL — no
     `scripts/generate-…` script needed.
  2. **`playercreateinfo_skills.rank` is a tier-STEP, not a value** —
     `rank=125` would be rejected exactly like 148h's `rank=100`. So the
     profession is seeded at Journeyman (`rank=2`, cap 150) and the
     first-login hook (`set_profession_skills`) bumps the skill VALUE to
     125 via `SetSkill`, the same idiom used for the starter weapon.
  3. **Three primaries for 9 combos.** With the two-gatherings ruling,
     combos where the race-default gathering AND the class-override
     gathering are both primary (e.g. Orc Warrior: Skinning + Mining +
     Blacksmithing) land 3 primary professions — beyond WoW's 2-primary
     norm. Mechanically fine (force-granted, bypasses the learn-time
     cap); flagged in Open Questions for a possible trim.
- Phase: 1 (Foundation — vanilla profile ruleset)
- Parent: 148 (vanilla profile)
- Related: 148h (starter equipment generator — same mechanism),
  148j (level-20 ability pretrain — bitmask-keying bug, found & fixed
  2026-07-13; see Keying for the lesson it teaches),
  148k (ALE auto-equip hook — may need to place profession tools)

## Problem

A vanilla character is created at level 20 with a full kit (148h) and
all trainer abilities through 20 (148j), but with **no professions**.
A level-20 character in stock WotLK would normally have picked up and
levelled a gathering and a production profession by now; starting at
20 with zero profession skill leaves that whole system cold and forces
the player back to a trainer before they can engage with it at all —
the same "no trip to nineteen trainers" problem 148j solved for
abilities, unsolved for professions.

Intended: every character spawns with **one gathering** and **one
production** profession, at skill 125, knowing every recipe available
at that skill, carrying the profession's tool so they can begin
immediately.

- **Gathering profession depends on RACE.**
- **Production profession depends on CLASS.**
- The two are chosen independently, so a character's gathering and
  production need not be thematically paired — that is expected and
  acceptable.

## Profession classification

The fourteen professions split **evenly, seven and seven**, so the
race pool and the class pool draw from equal-sized sets. Fishing,
First Aid, Cooking are secondary skills in WoW; they are folded into
the two buckets rather than treated as a separate tier.

- **Gathering (7):** Mining (186), Herbalism (182), Skinning (393),
  Fishing (356), First Aid (129), Tailoring (197), Enchanting (333).
- **Production (7):** Blacksmithing (164), Leatherworking (165),
  Alchemy (171), Engineering (202), Jewelcrafting (755),
  Inscription (773), Cooking (185).

## Primary/secondary slot interaction

WoW caps **primary** professions at 2; **secondary** (Fishing, First
Aid, Cooking) are unlimited. Under the split above:

- Primary gatherings: Mining, Herbalism, Skinning, Tailoring,
  Enchanting. Secondary gatherings: Fishing, First Aid.
- Primary productions: Blacksmithing, Leatherworking, Alchemy,
  Engineering, Jewelcrafting, Inscription. Secondary production:
  Cooking.

So a character has **two primaries** when both its gathering and
production are primary, and **one primary** when either side is a
secondary skill. It never exceeds the 2-primary cap. It must also
never hit **zero** primaries — see the coherence rule below, which is
why the single secondary-production (Cooking) is assigned to a class
(Druid) whose races only ever carry primary gatherings.

## Gathering by race — two faction matrices

Five races cannot cover seven gatherings one-per-race, and each
faction's races leave exactly three gatherings uncovered — Alliance
lacks Skinning/Tailoring/Enchanting, Horde lacks Mining/Fishing/First
Aid. So gathering splits into **two matrices**. Each keeps a thematic
**race default**, then adds three **class overrides** that fill that
faction's three gaps. Resolution rule: a class override wins; otherwise
the race default applies.

### Alliance gathering

Race defaults — Human → First Aid (field medics), Dwarf → Mining
(dwarven lore), Night Elf → Herbalism (nature), Gnome → Mining (tinker
ore), Draenei → Fishing (Azuremyst coast). Class overrides fill the
three Alliance lacks:

| Override class | Gathering |
|---|---|
| Rogue | Skinning |
| Warlock | Tailoring |
| Mage | Enchanting |

Worked examples: a Human **Warrior** gathers First Aid; a Human
**Rogue** gathers Skinning (override) instead.

### Horde gathering

Race defaults — Orc → Skinning (beast culture), Undead → Tailoring
(Forsaken weavers), Tauren → Herbalism (Cultivation racial), Troll →
Skinning (beast lore), Blood Elf → Enchanting (Arcane Affinity racial).
Class overrides fill the three Horde lacks:

| Override class | Gathering |
|---|---|
| Warrior | Mining |
| Shaman | Fishing |
| Priest | First Aid |

Worked examples: a Tauren **Druid** gathers Herbalism; a Tauren
**Shaman** gathers Fishing (override) instead.

Both factions then cover all seven gatherings. Emergent bonus: a Horde
Warrior mines *and* smiths (Blacksmithing) — self-sufficient — and any
Hunter skins for its Leatherworking. The asymmetry (different override
classes per faction) is inherent: the two factions lack *different*
gatherings, so the overrides cannot be identical — which is exactly why
it is two matrices, not one.

## Class → production mapping

Every production is represented; the nine classes cover the seven
productions (Inscription and Alchemy shared by two classes each).

| Class | Production | Rationale |
|---|---|---|
| Warrior (1) | Blacksmithing | Plate & weapons. |
| Paladin (2) | Jewelcrafting | Holy gems. |
| Hunter (3) | Leatherworking | Mail/leather from hides. |
| Rogue (4) | Engineering | Gadgets, bombs, gizmos. |
| Priest (5) | Inscription | Scribing, holy texts. |
| Shaman (7) | Alchemy | Elemental reagents/potions. |
| Mage (8) | Inscription | Arcane glyphs and scrolls. |
| Warlock (9) | Alchemy | Fel reagents/potions. |
| Druid (11) | Cooking | Natural foods; Druid races both carry a *primary* gathering, so pairing the lone secondary production here never yields a zero-primary character. |

## Skill value

Granted profession skill: **125**. Recipes: every recipe whose
required skill is **125 or below**. Skill 125 sits in the Journeyman
band, whose level gate a level-20 character clears.

The exact tier→level gates should not be hardcoded from memory — pull
them from the trainer/skill data during generation and assert level 20
clears skill 125. The granted skill value is the balance knob; if 125
feels off for the early-game economy it moves in
docs/balance-updates.md, not by a structural change.

## Starter tools

Auto-granted via `playercreateinfo_item`: **the profession's tool
only** — no starter materials. Players gather or find their own
materials through play; the tool is the one thing they cannot acquire
without the profession. Tool item IDs must be resolved by the
generator from `item_template` (do not hardcode from memory — 148h and
148j both show how a from-memory value becomes a bug).

- **Mining** → mining pick.
- **Skinning** → skinning knife.
- **Fishing** → fishing pole.
- **Blacksmithing / Engineering** → blacksmith hammer.
- **Enchanting** → runed copper rod.
- **Alchemy** → one stack of empty vials (Alchemy has no tool; the
  vials are its enabling consumable — the single deliberate exception
  to "tool only").
- **Herbalism, Tailoring, Jewelcrafting, Inscription, Cooking,
  First Aid** → no tool required; nothing granted.

## Recipes at level

Every recipe learnable at skill ≤ 125 should be known at spawn.
Enumerate them by querying `skill_line_ability` for the profession's
`SkillLine`, filtering to teachable trade spells whose required skill
value ≤ 125, and insert each as a `playercreateinfo_spell_custom` row.
This is a generator query, not a hand-list — the recipe set moves with
the skill knob above.

## Mechanism — tables and keying

Same family of tables the kit/pretrain use; no core changes needed.

- **`playercreateinfo_skills`** `(raceMask, classMask, skill, rank,
  comment)` — grants the profession skill line at `rank` = 125.
- **`playercreateinfo_spell_custom`** `(racemask, classmask, Spell,
  Note)` — the profession's learned spell + every recipe spell.
- **`playercreateinfo_item`** `(race, class, itemid, amount, Note)` —
  the tools (and the alchemy vials).

### Keying — MUST use correct bitmasks (lesson from 148j)

The core (`ObjectMgr.cpp` ~4500/4565) matches these tables with
`(mask == 0) || ((1 << (index - 1)) & mask)` — i.e. **`racemask`/
`classmask` are BITMASKS**, and `0` means "all". 148j shipped broken
because it stored **raw class IDs** (classmask 3 for Hunter), which
the core read as the *bitmask* `Warrior|Paladin` — 7 of 9 classes got
the wrong ability set until it was regenerated 2026-07-13. This
feature must not repeat that error:

- **Gathering rows (by race):** `racemask` = OR of `1 << (raceId-1)`
  over the races that share the gathering; `classmask = 0` (all
  classes). Example — Mining for Dwarf(3)+Gnome(7):
  `racemask = (1<<2)|(1<<6)`.
- **Production rows (by class):** `classmask` = OR of
  `1 << (classId-1)` over the classes that share the production;
  `racemask = 0` (all races). Example — Inscription for Priest(5)+
  Mage(8): `classmask = (1<<4)|(1<<7)`.

The generator builds every mask this way and never emits a raw id into
a mask column.

## Generator + patch wiring

Mirror the 148h equipment pipeline exactly:

- **`scripts/generate-vanilla-starting-professions-sql`** (new) — holds
  the mapping structure in code: the shared class→production table, and
  the faction-split gathering (per-faction race defaults + the three
  class overrides each). It resolves each (race, class) to its gathering
  by faction (override beats default), queries
  `skill_line_ability`/`item_template` for recipes and tool IDs, and
  emits the apply-form SQL. Self-documenting, `${DIR}`-parameterised,
  vimfolded per house style.
- **`sql/vanilla/db_world.src/07-starting-professions.apply.sql`**
  (generated) + matching revert form.
- **New E-patch** (next free `E0##`) that copies the apply-form into
  `sql/vanilla/db_world/` and registers the dir with the UpdateFetcher
  — same shape as E009 (kit) with the content-`cmp` idempotence guard,
  not the marker-grep guard.

Vanilla-DB scope only (`acore_world_vanilla`); release/beta read a
different world DB and must not receive these rows.

## Data coherence check (deliverable)

Before ship, a validator must confirm, for every valid (race, class)
in `playercreateinfo` (52 non-DK combos):
- exactly one gathering and one production profession granted,
- the profession skill line present at skill 125,
- every recipe row's `classmask`/`racemask` decodes (as a bitmask)
  back to the intended class/race set,
- the tool item for each tooled profession present,
- primary-profession count is always 1 or 2 — **never 0 and never >2**,
- **each faction covers all 7 gatherings and all 7 productions** (the
  whole reason for the two-matrix split — see Gathering by race).

## Current Behavior

No profession skills, recipes, or tools are granted at character
creation on vanilla. `playercreateinfo_skills` currently holds only
weapon/defense/language skill lines (from 148h) plus a single stray
First Aid (129) row; no gathering or production is present for any
(race, class).

## Intended Behavior

Every level-20 vanilla character spawns already carrying one gathering
and one production profession at skill 125, knowing every recipe at
that skill, with the profession's tool in the bag — ready to gather or
craft on first login without a trainer trip. Production is by class;
gathering is by race with per-faction class overrides (two matrices),
so **each faction independently has access to all seven gatherings and
all seven productions**.

## Implementation Steps (done)

- [x] No generator needed — recipes derive from `trainer_spell` at apply
      time, so `sql/vanilla/db_world.src/07-starting-professions.apply.sql`
      is hand-authored pure SQL (`INSERT … SELECT`), bitmask-keyed (correct
      `1<<(id-1)` masks, never a raw id — per 148j). Revert = tagged DELETE.
- [x] Tier/value split resolved: `rank=2` (Journeyman, cap 150) in the
      migration; skill VALUE 125 set by the first-login hook's
      `set_profession_skills` (`SetSkill(skill, 2, 125, 150)`).
- [x] `patch_E021_vanilla_starting_professions` + registration in
      `PHASE_END_PATCHES["vanilla"]`; cp-apply / cp-revert idiom.
- [x] Applied + coherence-validated across all 52 combos: every combo has
      ≥1 gathering + exactly 1 production; recipe totals check out
      (354 = 202 production + 152 gathering); tools = 72.
- [ ] In-client spot check (folds into 148o): a character per gathering
      and production — confirm skill 125, recipe book, starter tool.
- [ ] If the 3-primary combos (Open Questions) are unwanted, switch the
      relevant overrides from add to replace and re-apply.

## Open Questions

- **Three primary professions for 9 combos.** The two-gatherings ruling
  (a rogue skins *and* keeps their racial gathering — user-approved) means
  combos where both the race default and the class override are *primary*
  gatherings land 3 primaries once production is added: Orc/Undead/Tauren/
  Troll Warrior, Dwarf/NightElf/Gnome Rogue, Gnome Mage, Gnome Warlock.
  Force-granted, so the game accepts it (the 2-primary cap only gates
  *learning*), and it fits "play to the fullest" — but it's beyond the WoW
  norm. To trim: make the Warrior/Rogue/Mage/Warlock overrides *replace*
  the race default instead of adding (the Shaman/Priest overrides add a
  *secondary*, so they never trip this). Left additive pending a call.
- Mappings (race defaults, class overrides, production, skill 125) are
  **confirmed** (user sign-off 2026-07-13). Any future change must
  re-check the zero-primary guard: never move a secondary gathering
  (Fishing / First Aid) onto a Druid-eligible race, nor the secondary
  production (Cooking) off Druid — either would let a combo land zero
  primaries.
- Skill 125 is the current balance value; revisit in
  docs/balance-updates.md, not structurally.
- Should playerbots also receive these professions, or is this
  player-character-only? (Bots gear/skill via mod-playerbots, not
  `playercreateinfo`.) — still open.
