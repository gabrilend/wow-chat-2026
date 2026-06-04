# 148h - Class-Specific Starting Equipment for Level-20 Start

## Status
- Created: 2026-06-02
- Phase: 1 (Foundation — profile model)
- Parent: 148 (vanilla profile)
- Priority: Blocking — without this, a level-20 starting character
  is naked except for the default shirt-and-pants stub, which is
  unplayable at level 20.

## Problem

Vanilla starts new characters at level 20 (see 148's starting-level
design). The stock `playercreateinfo_item` table assigns minimal
level-1 starting kit: a shirt, a pair of pants, a basic weapon, and
sometimes a quest item or food/water. That kit is correct for a
level-1 character because they'll outgrow it within thirty minutes.
A level-20 character handed the same kit is in trouble: they have
no armor of meaningful value, their weapon damage is well below
what level-20 mobs expect, and their stat block is whatever cloth
shirt-and-pants provides.

This sub-issue equips every newly-created vanilla character with a
full suit of level-appropriate, class-appropriate, common (white)
quality gear so they can step out of the starting zone and
immediately participate in level-20 content.

## Equipment Slot List

Each character receives a piece of gear for every one of these slots:

- **Chest** (full body armor)
- **Legs** (pants/leggings)
- **Hands** (gloves)
- **Feet** (boots)
- **Waist** (belt)
- **Wrists** (bracers)
- **Back** (cape)
- **Main weapon** (class-appropriate)
- **Off-hand or ranged or secondary**, where the class kit calls for it

**Deliberately NOT issued:**
- **Head** (no helmet). The player looks at their character's face,
  not a metal pot, from the moment of creation. Helmets become a
  later-game reward.
- **Shoulders** (no shoulderpads). Same reasoning — clean silhouette
  at the start, shoulderpads earned through play.

The shirt-and-pants slot (the cosmetic shirt under armor) is left to
the existing stock entries; we don't override it.

## Per-Class Armor Type at Level 20

WoW armor proficiencies in 3.3.5a determine which materials each
class can wear without penalty. At level 20, the matrix is:

| Class | Proficient armor at L20 | Starting armor pick |
|-------|------------------------|---------------------|
| Warrior | Cloth, Leather, Mail, Shield | Mail |
| Paladin | Cloth, Leather, Mail, Shield | Mail |
| Hunter | Cloth, Leather (Mail unlocks at 40) | Leather |
| Rogue | Cloth, Leather | Leather |
| Priest | Cloth | Cloth |
| Shaman | Cloth, Leather, Shield (Mail unlocks at 40) | Leather |
| Mage | Cloth | Cloth |
| Warlock | Cloth | Cloth |
| Druid | Cloth, Leather | Leather |
| Death Knight | (disabled on vanilla per 148a) | — |

The chest/legs/hands/feet/waist/wrists pieces all use the class's
starting armor pick. The cape is cloth for every class (cloaks have
no armor-type restriction in 3.3.5a). The belt is the same armor
type as the other slots.

## Per-Class Weapon Kit at Level 20

Class defaults give every member of the class the same kit; a small
set of race-specific overrides (see next section) replaces the
default kit for races whose flavor calls for a different weapon.

| Class   | Main hand                   | Off-hand                       | Ranged                 | Notes                          |
|---------|-----------------------------|--------------------------------|------------------------|--------------------------------|
| Warrior | Longsword (1H)              | Reinforced Targe (shield)      | —                      |                                |
| Paladin | Maul (2H mace)              | —                              | —                      | libram dropped — none white    |
| Hunter  | Longsword (1H melee filler) | —                              | Heavy Recurve Bow      | uniform bow across all races   |
| Rogue   | Kris (1H dagger ×2 dual-wield) | (second Kris)               | —                      | symmetric: same item both hands |
| Priest  | Flail (1H mace)             | Beautiful Wildflowers (held)   | Dusk Wand              |                                |
| Shaman  | Flail (1H mace)             | Reinforced Targe (shield)      | Totem of the Earthen Ring | white totem (the only one)  |
| Mage    | Long Staff (2H)             | —                              | Dusk Wand              |                                |
| Warlock | Longsword (1H)              | Darkmoon Flower (held)         | Dusk Wand              |                                |
| Druid   | Long Staff (2H)             | —                              | —                      | idol dropped — none white      |

The two held-in-off-hand items (Beautiful Wildflowers for priest,
Darkmoon Flower for warlock) are white, RequiredLevel 0, no stats.
They fill the slot for aesthetics without granting any combat power
— see the No Greens rule below for the principle.

## Per-(Race, Class) Weapon Kit Overrides

Thirteen (race, class) combinations break from their class default
to give a more thematically appropriate kit. Each override also
flips the starter weapon-skill grant to match the new main-hand
weapon type.

| Race      | Class    | Kit                                              | Starter skill        |
|-----------|----------|--------------------------------------------------|----------------------|
| Dwarf     | Paladin  | Flail (1H mace) + Reinforced Targe (shield)      | Maces (1H)           |
| Blood Elf | Paladin  | Dacian Falx (2H sword)                           | Two-Handed Swords    |
| Orc       | Hunter   | Double Axe ×2 (dual-wield) + bow + arrows + quiver | Axes (1H)          |
| Blood Elf | Hunter   | Short Spear (polearm melee) + bow + arrows + quiver | Polearms          |
| Night Elf | Warrior  | Short Spear (polearm 2H)                         | Polearms             |
| Troll     | Warrior  | Battle Axe (2H axe)                              | Two-Handed Axes      |
| Tauren    | Shaman   | Maul (2H mace) + Totem of the Earthen Ring       | Two-Handed Maces     |
| Troll     | Shaman   | Battle Axe (2H axe) + Totem of the Earthen Ring  | Two-Handed Axes      |
| Draenei   | Shaman   | Double Axe (1H axe) + Reinforced Targe (shield) + Totem of the Earthen Ring | Axes (1H) |
| Orc       | Rogue    | Flail (1H mace) + Kris (dagger off-hand)         | Maces (1H)           |
| Undead    | Rogue    | Longsword (1H) + Kris (dagger off-hand)          | Swords (1H)          |
| Blood Elf | Rogue    | Longsword ×2 (dual-wield 1H swords)              | Swords (1H)          |
| Night Elf | Rogue    | Longsword ×2 (dual-wield 1H swords)              | Swords (1H)          |

Orc Hunter dual axes and every Rogue's twin-1H kit depend on the
Dual Wield spell (674) being granted at character creation, which
sub-issue 148j handles via `playercreateinfo_spell_custom`.

## No Greens Rule

No item in the starter kit is green (Quality 2) or higher. When the
3.3.5a database has no white-quality option for a slot (no white
libram, no white idol, no white off-hand-held stat item), the slot
is left empty rather than filled with a green. The single exception
is the cape (Rugged Cape, white but RequiredLevel 0 instead of
18-22) — capes simply don't exist as white at level 18-22 in any
form, so the constraint relaxes for back slot.

Reasoning: starter equipment must not empower one character over
another at spawn. Better to leave a slot empty than ship a green.

## Cape — Uniform Across Classes

Every class gets the same cape: a generic level-20 white-quality
cloak with basic stamina/armor stats. No class-specific cloak
variation. The cape is the project's small flair gesture — a hint
of personality on an otherwise utilitarian starting kit.

## Quality and Aesthetic — Functional Grab-Bag

The starter kit uses whichever white-quality items at or near level
20 happen to exist in the 3.3.5a item database for each class+slot.
No attempt is made to match aesthetics across slots — pieces are
picked for stats and proficiency, not for visual coherence. A
character may walk out of creation in a Linen tunic, Embossed
Leather boots, and a Burnished belt. That's intentional. The
mismatch is part of the texture of the ruleset — gear feels
scavenged rather than uniformed, and that fits the small-world
exploration tone better than a tidy uniform would.

**Implementation:** SQL queries against `item_template` filtering by
`Quality=1` (common/white), `ItemLevel BETWEEN 18 AND 22`, plus the
appropriate slot and armor-type constraints. Pick the first
qualifying item per slot per class, or any selection rule — the
specific items don't matter as long as the proficiency is right.

## Weapon Skill — Pre-Trained for Starter Weapons Only

The starting kit's weapons come with their corresponding weapon
skill **pre-trained to 100** (max weapon skill at level 20 = level
× 5). A warrior starting with a 1H sword has Swords skill at 100
from the moment of creation; a Troll Warrior starting with a 2H
axe has Two-Handed Axes at 100 instead.

**This applies ONLY to the starter weapon's TYPE.** Any other weapon
type the player picks up later — different weapon class, even an
upgrade with different proficiency — starts at default skill 1.
Picked-up swords by a sword-starter character keep training Swords;
picked-up maces by the same character train Maces from scratch.

### Implementation
The grant uses `playercreateinfo_skills` with per-(race, class) rows
rather than grouped class-bitmask rows. This is what lets the
thirteen race overrides (above) each carry their own skill type at
100 without collision — Troll Warrior gets `raceMask=128,
classMask=1, skill=172 (Two-Handed Axes), rank=100`, separate from
the default Warrior row `raceMask=<everyone-else>, classMask=1,
skill=43 (Swords), rank=100`. Per-(race, class) granularity is the
cleanest expression of the override pattern.

## Class Kit Items (Relics) — What's Left

Three relic types exist in 3.3.5a (libram, idol, totem). The DB has
exactly ONE white-quality relic: `46978 Totem of the Earthen Ring`
(white, RequiredLevel 1). Paladin librams and Druid idols all start
at green quality.

Per the No Greens rule, the kit reflects this asymmetry directly:

- **Shaman:** Totem of the Earthen Ring (the one white relic).
- **Paladin:** no libram — slot empty.
- **Druid:** no idol — slot empty.
- **Hunter:** Medium Quiver + Sharp Arrow stack (white, RequiredLevel
  0 + 10). Mechanically required for the bow to fire.
- **Priest, Mage, Warlock:** Dusk Wand fills the ranged slot.

No spell in 3.3.5a strictly requires a libram, idol, or totem
relic equipped to cast — relics are damage/healing modifiers, not
gate-keepers. Paladin and Druid not having their relic costs them
no functional ability; they just give up the buff.

## Bags and Hearthstone

Every newly-created vanilla character also receives:

- **3× Linen Bag** (4238) — six-slot containers. Equipped into bag
  positions 19, 20, 21. Eighteen regular bag slots universal across
  all nine classes.
- **1× Hearthstone** (6948) — bind point set by the ALE
  auto-equip hook (148k) to Darkshire (Alliance) or Tarren Mill
  (Horde) on first login, so the player's hearth returns them to
  their starting town.

Hunters additionally get the **Medium Quiver** already listed in
their weapon kit — equipped into bag position 22 as the 10-slot
ammo container. The quiver is a bonus, not a substitute for a
regular bag: every player has equal regular bag capacity (18
slots); hunters get +10 ammo slots on top because they carry ammo
no other class needs to.

The 4-slot bag scheme was considered first but rejected: 3.3.5a
has only three 4-slot bags in the entire DB, all race-themed quest
pouches (Sunstrider Book Satchel, Magister's Pouch, Empty Draenei
Supply Pouch). Linen Bag (6-slot, white, RequiredLevel 0, race-
neutral) is the universal choice.

## Implementation Approach

A bash generator holds the kit matrix as data and emits an
idempotent SQL migration. The kit definitions for every class plus
the thirteen race overrides plus the universal cape, bags, and
hearthstone are all in the generator script's top-of-file tables.
Re-run after any kit change; commit both the script and its output.

### File layout
- `scripts/generate-vanilla-starting-equipment-sql` — the bash
  generator. Holds CLASS_DEFAULT_KIT, RACE_CLASS_KIT_OVERRIDE,
  CLASS_DEFAULT_SKILL, RACE_CLASS_SKILL_OVERRIDE, VALID_COMBOS
  data structures. Emits ~570 INSERT rows.
- `sql/vanilla/db_world.src/02-starting-equipment.apply.sql` — the
  E009 patch's apply-form source. E009 cp's this into
  `sql/vanilla/db_world/02-starting-equipment.sql` at install
  time; AzerothCore's UpdateFetcher then picks it up.

### Per-row format
Each `playercreateinfo_item` row is `(race, class, itemid, amount,
Note)`. The Note column carries `vanilla-148h-<slot>` so audit
queries and the idempotence DELETE both filter on it.

Race wildcard (`race=0`) is NOT supported by the table's
(race, class, itemid) primary key — every combination is enumerated
explicitly. The generator iterates the 51 valid (race, class) pairs
(DK excluded per 148a; Gnome Priest and Troll Mage also excluded as
Cataclysm-era additions).

For dual-wield kits (Orc Hunter dual axes, default Rogue dual Kris,
BE/NE Rogue dual Longsword), the same itemid appearing twice for
one (race, class) would collide on the primary key. The generator
expresses these as `amount=2` of a single row; the ALE auto-equip
hook (148k) splits the stack into main-hand and off-hand at first
login.

### Idempotence
The migration's first statements DELETE all rows tagged
`Note LIKE 'vanilla-148h-%'` from `playercreateinfo_item` and rows
tagged `comment LIKE 'vanilla-148h-%'` from `playercreateinfo_skills`.
Re-applying the migration leaves the table in the same state
without touching unrelated rows (default shirt/pants/hearthstone
entries the engine populates).

## Cross-References

- `issues/148j-pretrain-level-20-abilities.md` — pre-trains every
  spell + weapon-skill a class would normally learn from a trainer
  at levels 1-20, including the Dual Wield (spell 674) that the
  Orc Hunter / dual-Rogue kits depend on.
- `issues/148k-ale-auto-equip-starter-kit.md` — the ALE Lua hook
  that strips the DBC starter outfit on first login and auto-
  equips every item in this kit into its proper equipment slot,
  routes ammo into the quiver, and binds the hearthstone.
- `scripts/generate-vanilla-starting-equipment-sql` — kit data
  source of truth.
- R7 Results in `tmp/148-parallelization-roadmap.md` — the item-ID
  research that produced the matrix.

## Open Questions

- **Should the starting kit scale if the starting level ever changes
  from 20?** Probably yes — the kit's level should track
  `StartPlayerLevel` from C007c. But for now (level 20 is the only
  vanilla start level) a hardcoded item list is fine. Revisit if
  starting level becomes a knob.
- **Hunter ammo amount?** Currently 200 arrows (one stack). Lasts
  the first questing session. Increase if playtest shows it runs
  out too quickly.
