# 148h - Class-Specific Starting Equipment for Level-20 Start

## Status
- Created: 2026-06-02
- Redesigned: 2026-06-12 (thematic curation, item cloning, damage
  normalization, loot-table-update procedure, 52-combo coverage)
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
A level-20 character handed the same kit is in trouble: no armor of
meaningful value, weapon damage well below what level-20 mobs expect,
and a stat block that's whatever cloth shirt-and-pants provides.

This sub-issue equips every newly-created vanilla character with a
full suit of level-appropriate, class-and-race-appropriate, common
(white) quality gear so they can step out of the starting zone and
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
- **Main weapon** (race-and-class-appropriate)
- **Off-hand** (shield, dual-wield weapon, or held frill) where the
  loadout calls for it
- **Ranged** (bow + ammo + quiver for Hunters; wand for casters)
- **Relic** (Shaman totem; no white libram or idol exists)

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
| Warrior | Cloth, Leather, Mail, Shield | Mail (Polished Scale set) |
| Paladin | Cloth, Leather, Mail, Shield | Mail (Polished Scale set) |
| Hunter | Cloth, Leather (Mail unlocks at 40) | Leather (Cuirboulli set) |
| Rogue | Cloth, Leather | Leather (Cuirboulli set) |
| Priest | Cloth | Cloth (Padded set) |
| Shaman | Cloth, Leather, Shield (Mail unlocks at 40) | Leather (Cuirboulli set) |
| Mage | Cloth | Cloth (Padded set) |
| Warlock | Cloth | Cloth (Padded set) |
| Druid | Cloth, Leather | Leather (Cuirboulli set) |

The chest/legs/hands/feet/waist/wrists pieces all use the class's
starting armor pick. The cape is the universal Rugged Cape across
every class (cloaks have no armor-type restriction in 3.3.5a).

## Design Philosophy: Thematic Curation

The kit's job is to make each (race, class) feel deliberately
chosen, not algorithmically picked. The starting weapon is the
strongest signal a player gets about who their character is in this
world; choosing it carefully matters more than picking the
highest-DPS option from a slot-filtered query.

The curation principles:

- **Race carries the weapon's culture.** A Tauren Shaman wields a
  Giant Mace because Tauren culture is primal-heavy-stone; a Blood
  Elf Paladin wields a Claymore because Blood Elf paladins are
  refined-knightly-sword. The class proficiency lets both classes
  wield maces or swords; the race chooses which.

- **Two-handed defaults, dual-wield for unique flavor.** Most
  warriors get a 2H weapon. Where dual-wield happens (Orc Hunter
  cleaver-pair, every Rogue's dagger-pair, Gnome Warrior's twin
  scimitars), it tells the player something about that race: Orcs
  hunt with brutal momentum, Gnomes fight with cleverness over
  reach.

- **No green-quality items in the kit.** Every starter item is
  white-quality. This prevents a starting character from having
  better stats than another at spawn. The single exception is the
  +1 spell power on the Amani Sacrificial Dagger, which is small
  enough to read as flavor rather than power.

- **Off-hand frills for 1H casters.** Priests with Wildflowers,
  Warlocks with the Darkmoon Flower, Mages with the Darkmoon Flower
  if their kit uses a 1H weapon (Blood Elf and Troll). 2H staff
  users (most Mages, all Druids, some Priests) don't get a held
  frill because the slot is occupied.

- **Damage-normalized, speed-preserved.** Every melee and ranged
  weapon in the kit is tuned to 15 DPS regardless of base entry
  (wands to 20 DPS — see the rebalance note below). Original
  attack delay is preserved — the vanilla designers chose
  weapon-specific delays for reasons of feel and animation, and
  we respect that choice while flattening damage. This lets the
  player experience the rhythm-difference between a Battle Axe
  (3.8s heavy swings) and a Scimitar (2.3s quick strikes) without
  one being a strictly-better-DPS choice.

- **Symbolic peasant-tier weapons (Militia Hammer, Militia
  Quarterstaff) still get the 15 DPS normalization.** Earlier
  drafts considered leaving them at original vanilla 2-3 DPS as a
  flavor choice; the final rule is symmetry. We don't play
  favorites between races, only between models and attack speeds.

## Per-(Race, Class) Kit Matrix

All 52 valid (race, class) combos covered. Death Knight (class 6)
is disabled per 148a and omitted. Goblin slot (race 9) is reserved
pre-Cataclysm and omitted. Troll Druid (8, 11) does not exist in
`playercreateinfo` and is omitted; if Troll Druid is ever added as
a custom-server class, this matrix gets a 53rd row.

Loadout columns reference cloned entry IDs (see Item Cloning
Procedure below). Frill column: ✿ Wildflowers · ✦ Darkmoon Flower
· — empty.

| Race | Class | Main hand / 2H | Off-hand | Ranged | Relic / Ammo | Frill |
|---|---|---|---|---|---|---|
| Human | Warrior | Claymore (2H) | — | — | — | — |
| Human | Paladin | Maul (2H) | — | — | — | — |
| Human | Rogue | Ceremonial Knife × 2 (dual) | — | — | — | — |
| Human | Priest | Militia Hammer | — | Dusk Wand | — | ✿ |
| Human | Mage | Militia Quarterstaff (2H) | — | Burning Wand | — | — |
| Human | Warlock | Scimitar | — | Dusk Wand | — | ✦ |
| Orc | Warrior | Hatchet | Ringed Buckler | — | — | — |
| Orc | Hunter | Butcher's Cleaver × 2 (dual) | — | Heavy Recurve Bow | Quiver + Arrow | — |
| Orc | Rogue | Ceremonial Knife + Flail | — | — | — | — |
| Orc | Shaman | Giant Mace (2H) | — | — | Totem of the Earthen Ring | — |
| Orc | Warlock | Militia Quarterstaff (2H) | — | Burning Wand | — | — |
| Dwarf | Warrior | Short Spear (2H polearm) | — | — | — | — |
| Dwarf | Paladin | Flail | Large Metal Shield | — | — | — |
| Dwarf | Hunter | Battle Axe (2H) | — | Heavy Recurve Bow | Quiver + Arrow | — |
| Dwarf | Rogue | Ceremonial Knife × 2 (dual) | — | — | — | — |
| Dwarf | Priest | Militia Hammer | — | Dusk Wand | — | ✿ |
| Night Elf | Warrior | Short Spear (2H polearm) | — | — | — | — |
| Night Elf | Hunter | Dacian Falx (2H polearm) | — | Heavy Recurve Bow | Quiver + Arrow | — |
| Night Elf | Rogue | Scimitar × 2 (dual) | — | — | — | — |
| Night Elf | Priest | Gnarled Staff (2H) | — | Dusk Wand | — | — |
| Night Elf | Druid | Militia Quarterstaff (2H) | — | — | — | — |
| Undead | Warrior | Battle Axe (2H) | — | — | — | — |
| Undead | Rogue | Scimitar + Ceremonial Knife (dual) | — | — | — | — |
| Undead | Priest | Amani Sacrificial Dagger | — | Dusk Wand | — | ✿ |
| Undead | Mage | Gnarled Staff (2H) | — | Burning Wand | — | — |
| Undead | Warlock | Scimitar | — | Burning Wand | — | ✦ |
| Tauren | Warrior | Short Spear (2H polearm) | — | — | — | — |
| Tauren | Hunter | Gnarled Staff (2H) | — | Heavy Recurve Bow | Quiver + Arrow | — |
| Tauren | Shaman | Giant Mace (2H) | — | — | Totem of the Earthen Ring | — |
| Tauren | Druid | Militia Quarterstaff (2H) | — | — | — | — |
| Gnome | Warrior | Scimitar × 2 (dual) | — | — | — | — |
| Gnome | Rogue | Ceremonial Knife × 2 (dual) | — | — | — | — |
| Gnome | Mage | Gnarled Staff (2H) | — | Burning Wand | — | — |
| Gnome | Warlock | Scimitar | — | Dusk Wand | — | ✦ |
| Troll | Warrior | Battle Axe (2H) | — | — | — | — |
| Troll | Hunter | Butcher's Cleaver × 2 (dual) | — | Heavy Recurve Bow | Quiver + Arrow | — |
| Troll | Rogue | Ceremonial Knife × 2 (dual) | — | — | — | — |
| Troll | Priest | Flail | — | Dusk Wand | — | ✿ |
| Troll | Shaman | Battle Axe (2H) | — | — | Totem of the Earthen Ring | — |
| Troll | Mage | Amani Sacrificial Dagger (+1 SP) | — | Burning Wand | — | ✦ |
| Blood Elf | Paladin | Claymore (2H sword) | — | — | — | — |
| Blood Elf | Hunter | Short Spear (2H polearm) | — | Heavy Recurve Bow | Quiver + Arrow | — |
| Blood Elf | Rogue | Scimitar × 2 (dual) | — | — | — | — |
| Blood Elf | Priest | Amani Sacrificial Dagger | — | Dusk Wand | — | ✿ |
| Blood Elf | Mage | Scimitar | — | Burning Wand | — | ✦ |
| Blood Elf | Warlock | Amani Sacrificial Dagger | — | Burning Wand | — | ✦ |
| Draenei | Warrior | Militia Hammer | Large Metal Shield | — | — | — |
| Draenei | Paladin | Maul (2H) | — | — | — | — |
| Draenei | Hunter | Claymore (2H sword) | — | Heavy Recurve Bow | Quiver + Arrow | — |
| Draenei | Priest | Militia Hammer | — | Dusk Wand | — | ✿ |
| Draenei | Shaman | Hatchet | Large Metal Shield | — | Totem of the Earthen Ring | — |
| Draenei | Mage | Gnarled Staff (2H) | — | Burning Wand | — | — |

Notes on race-specific shape:

- **Orc Hunter** and **Troll Hunter** dual-wield 1H cleavers, both
  using Butcher's Cleaver. Both races have a primal-momentum
  combat feel — Orcs bring the brutal swing-pair, Trolls bring the
  feral one.
- **Draenei Shaman** is melee-with-shield (Hatchet + Large Metal
  Shield) because Shaman dual-wield doesn't unlock until level 40,
  and we don't want them naked-off-hand at L20. A second hatchet
  would simply not equip.
- **Tauren Hunter with Gnarled Staff** is the deliberate odd-one-
  out: most Hunters get a melee sword or axe in the off-hand-of-
  the-bow slot, but Tauren culture is staff-and-totem, so the
  Tauren Hunter melee-with-staff fits the race even though it
  reads weirdly to a player coming from canonical WoW Hunter kits.
- **Troll Priest keeps the Flail** rather than getting the Amani
  Sacrificial Dagger like Undead and Blood Elf priests. Flail-
  wielding fits the troll voodoo-priest grim-utility flavor; the
  ceremonial dagger fits the Sin'dorei/Forsaken sanctified-blade
  flavor. Different feels, same proficiency.
- **Orc Rogue with a Flail off-hand** is also deliberate — Orcs
  get the Mace Specialization racial passive, and the Flail's
  one-hand-mace classification stacks with it. Every other rogue
  has matched daggers/swords; the Orc gets a mixed kit because
  the race's mechanical identity pulls them off the symmetric
  default.

## Damage Normalization

Every melee or ranged weapon in the kit lands at **15 DPS** at the
end of cloning. Wands land at **20 DPS** (the proper "wand DPS at
~100% of spell DPS at L20" rebalance is deferred to 148p).

The formula, per cloned weapon:

```
new_min_dmg = original_min_dmg × (target_DPS / original_DPS)
new_max_dmg = original_max_dmg × (target_DPS / original_DPS)
```

`delay` is preserved from the original entry — the vanilla designers
chose weapon-specific delays for animation/feel reasons, and a
character should still feel the rhythm difference between a 3.8s
Battle Axe and a 2.3s Scimitar even though they hit the same
sustained DPS.

### Computed kit damage values

| Weapon | Cloned entry | delay (s) | New dmg_min — dmg_max |
|---|---|---|---|
| Claymore (1198) | 2001198 | 3.2 | 38 — 58 |
| Scimitar (2027) | 2002027 | 2.3 | 24 — 45 |
| Ceremonial Knife (3445) | 2003445 | 1.4 | 14 — 28 |
| Amani Sacrificial Dagger (23923) | 2023923 | 2.0 | 20 — 40 + `stat_type1=45, stat_value1=1` (Spell Power) |
| Maul (924) | 2000924 | 2.9 | 35 — 52 |
| Flail (925) | 2000925 | 2.2 | 23 — 43 |
| Giant Mace (1197) | 2001197 | 3.5 | 42 — 63 |
| Militia Hammer (5580) | 2005580 | 2.3 | 23 — 46 |
| Battle Axe (926) | 2000926 | 3.8 | 45 — 69 |
| Hatchet (853) | 2000853 | 2.5 | 25 — 50 |
| Butcher's Cleaver (1292) | 2001292 | 1.7 | 21 — 30 |
| Short Spear (15810) | 2015810 | 3.3 | 40 — 59 |
| Dacian Falx (922) | 2000922 | 3.1 | 37 — 56 |
| Gnarled Staff (2030) | 2002030 | 2.9 | 34 — 53 |
| Militia Quarterstaff (1159) | 2001159 | 2.8 | 34 — 50 |
| Heavy Recurve Bow (3027) | 2003027 | 2.4 | 25 — 47 |
| Dusk Wand (5211) | 2005211 | 1.7 | 24 — 44 (20 DPS) |
| Burning Wand (5210) | 2005210 | 1.4 | 19 — 37 (20 DPS) |

All 18 weapon types. Bows for Hunters use the same target
because a Hunter's "ranged auto-attack" is the equivalent of a
caster's wand-or-spell rotation, not an additional axis.

## Item Cloning Procedure

Earlier drafts of this issue (the 2026-06-02 ship) modified the
`item_template.RequiredLevel` of vanilla items in-place via
`patch_E018_vanilla_kit_required_level_cap` in `patches/E-patches.sh`.
That edit leaked: any quest reward, creature drop, vendor listing,
or AH entry of (for example) a Cuirboulli Vest now used the lowered
RL value across the entire world, not just the kit. The unpatch was
a soft revert (re-floored to RL=22) and known imperfect.

The redesign replaces in-place modification with clone-to-new-ID:

1. **Clone**. For each kit item, `INSERT` a new row into
   `item_template` cloned from the original, with the new entry ID
   computed as `original_entry + 2000000`. Example: Battle Axe (926)
   clones to entry 2000926. The 2000000 offset clears the entire
   vanilla item range (max ~64000) with no collision risk and makes
   clone IDs immediately recognizable in any query.

2. **Tune**. `UPDATE` the cloned entry's `RequiredLevel = 20`,
   `dmg_min1` and `dmg_max1` per the normalization table above,
   plus any stat fields (e.g. Amani Sacrificial Dagger's +1
   Spell Power).

3. **Swap kit references**. `UPDATE playercreateinfo_item SET
   itemid = <clone>` for every kit row that referenced the
   original entry, scoped by `Note LIKE 'vanilla-148h-%'`.

4. **Swap world references**. Update every table where the original
   entry appears as a drop, reward, vendor stock, or container
   payload. See Loot Table Update Procedure below.

5. **Restore originals**. Set the original entry's `RequiredLevel`
   back to its canonical vanilla value. For items where E018
   touched the RL, this is the undo step. Approximation formula:
   `RequiredLevel = GREATEST(ItemLevel - 5, 0)` for items at
   `ItemLevel >= 22`, matching the vanilla curve closely enough
   for items in the L20-band kit. Exact per-entry canonical values
   are listed in the apply SQL as a fallback for items where the
   formula misses.

### Entry ID convention

| Item original | Entry | Clone entry |
|---|---|---|
| Claymore | 1198 | 2001198 |
| Scimitar | 2027 | 2002027 |
| Ceremonial Knife | 3445 | 2003445 |
| Amani Sacrificial Dagger | 23923 | 2023923 |
| Maul | 924 | 2000924 |
| Flail | 925 | 2000925 |
| Giant Mace | 1197 | 2001197 |
| Militia Hammer | 5580 | 2005580 |
| Battle Axe | 926 | 2000926 |
| Hatchet | 853 | 2000853 |
| Butcher's Cleaver | 1292 | 2001292 |
| Short Spear | 15810 | 2015810 |
| Dacian Falx | 922 | 2000922 |
| Gnarled Staff | 2030 | 2002030 |
| Militia Quarterstaff | 1159 | 2001159 |
| Heavy Recurve Bow | 3027 | 2003027 |
| Dusk Wand | 5211 | 2005211 |
| Burning Wand | 5210 | 2005210 |
| Ringed Buckler | 2441 | 2002441 |
| Large Metal Shield | 2445 | 2002445 |
| Cuirboulli Vest | 2141 | 2002141 |
| Cuirboulli Belt | 2142 | 2002142 |
| Cuirboulli Boots | 2143 | 2002143 |
| Cuirboulli Bracers | 2144 | 2002144 |
| Cuirboulli Gloves | 2145 | 2002145 |
| Cuirboulli Pants | 2146 | 2002146 |
| Polished Scale Belt | 2148 | 2002148 |
| Polished Scale Boots | 2149 | 2002149 |
| Polished Scale Bracers | 2150 | 2002150 |
| Polished Scale Gloves | 2151 | 2002151 |
| Polished Scale Leggings | 2152 | 2002152 |
| Polished Scale Vest | 2153 | 2002153 |
| Padded Boots | 2156 | 2002156 |
| Padded Gloves | 2158 | 2002158 |
| Padded Pants | 2159 | 2002159 |
| Padded Armor | 2160 | 2002160 |
| Padded Belt | 3591 | 2003591 |
| Padded Bracers | 3592 | 2003592 |
| Rugged Cape | 2240 | 2002240 |
| Beautiful Wildflowers | 3422 | 2003422 |
| Darkmoon Flower | 19295 | 2019295 |
| Totem of the Earthen Ring | 46978 | 2046978 |
| Linen Bag | 4238 | 2004238 |
| Medium Quiver | 11362 | 2011362 |
| Hearthstone | 6948 | 2006948 |
| Sharp Arrow | 2515 | 2002515 |

All starting gear cloned, even items with no stat changes (flowers,
totem, hearthstone, bag, arrows). Cloning items we don't currently
modify makes them safe to retune later without touching the world
again.

## Loot Table Update Procedure

After every clone exists, the world's references to the originals
get rewritten to point at the clones. This keeps the live world
internally consistent — a Battle Axe drop from a Stonetalon centaur
drops the 15-DPS RL=20 server-tuned clone, not the canonical
vanilla item.

Tables touched, in the vanilla profile world DB only:

| Table | Column | Action |
|---|---|---|
| `creature_loot_template` | `Item` | UPDATE to clone entry where Item = original |
| `gameobject_loot_template` | `Item` | UPDATE to clone entry where Item = original |
| `disenchant_loot_template` | `Item` | UPDATE to clone entry where Item = original |
| `reference_loot_template` | `Item` | UPDATE to clone entry where Item = original |
| `mail_loot_template` | `Item` | UPDATE if any references exist |
| `pickpocketing_loot_template` | `Item` | UPDATE if any references exist |
| `skinning_loot_template` | `Item` | UPDATE if any references exist |
| `fishing_loot_template` | `Item` | UPDATE if any references exist |
| `prospecting_loot_template` | `Item` | UPDATE if any references exist |
| `milling_loot_template` | `Item` | UPDATE if any references exist |
| `npc_vendor` | `item` | UPDATE to clone entry where item = original |
| `quest_template` | `RewardItem1` through `RewardItem4`, `RewardChoiceItem1` through `RewardChoiceItem6` | UPDATE per-column where any matches the original |
| `creature_questitem` | `ItemId` | UPDATE if applicable |
| `item_loot_template` | `Item` | UPDATE to clone entry where Item = original |

Originals remain in `item_template` as stable references for wiki
lookups (Wowhead, Wowdb), so when designing a future NPC or quest
the canonical Battle Axe stats remain queryable from the original
entry. Nothing in vanilla profile's loot tables uses originals
anymore, so the canonical entries are "historical" but harmless.

Other profiles (release, beta) read different world DBs and are
not affected — the clone work is scoped to `acore_world_vanilla`.

## Off-Hand Frills

The 1H caster-offhand slot (InventoryType 23, "Held in Off-hand")
gets a thematic frill for casters whose main hand is 1H. Two flowers
serve every caster:

- **Beautiful Wildflowers (3422 → 2003422)** for Priests. A bouquet
  reads as nurturing-and-restorative, fits the priest fantasy.
- **Darkmoon Flower (19295 → 2019295)** for Warlocks and the two
  Mages whose main hand is 1H (Troll Mage with Amani Dagger, Blood
  Elf Mage with Scimitar). The darkmoon imagery reads as
  arcane-and-shadowed, fits the warlock and the harder-edged mages.

Both items are no-stat, RL 0, race-and-class neutral. They occupy
the slot for visual completion only — combat math sees no
difference between a caster with a flower and a caster with the
slot empty.

2H staff casters (most Mages, all Druids, three Priests, one
Shaman) get no frill because the staff occupies both main hand
and off-hand slots.

## Bags and Hearthstone

Every newly-created vanilla character also receives:

- **3× Linen Bag (4238 → 2004238)** — six-slot containers. Equipped
  into bag positions 19, 20, 21. Eighteen regular bag slots
  universal across all classes.
- **1× Hearthstone (6948 → 2006948)** — bind point set by the ALE
  auto-equip hook (148k) to the character's race's spawn town on
  first login (148n's per-race spread), so the player's hearth
  returns them to where they started.

Hunters additionally get the **Medium Quiver (11362 → 2011362)**
equipped into bag position 22 as the 10-slot ammo container, plus
200 **Sharp Arrows (2515 → 2002515)** loaded into the quiver. The
quiver is a bonus, not a substitute for a regular bag.

The 4-slot bag scheme was considered first but rejected: 3.3.5a
has only three 4-slot bags in the entire DB, all race-themed quest
pouches (Sunstrider Book Satchel, Magister's Pouch, Empty Draenei
Supply Pouch). Linen Bag (6-slot, white, RequiredLevel 0,
race-neutral) is the universal choice.

## Weapon Skills — Full Proficiency, Starter Weapon Sharpened

Two things a level-20 starter needs that stock creation doesn't give:

1. **Proficiency in every weapon the class can learn** — so the player
   never visits a weapon master, and so the kit's own weapon is
   equippable at all. Some kit weapons sit off the class's *default*
   proficiency set (a Tauren Warrior's polearm — warriors normally
   *train* polearms), and the equip check is gated by the
   `m_WeaponProficiency` bitmask, which only a learned proficiency
   *spell* sets. Without the grant the auto-equip hook can't put the
   weapon on.
2. **The starter weapon at max-for-level skill** (level × 5 = 100 at
   level 20), so the character isn't missing/glancing with a level-1
   value. Every *other* weapon skill stays at default (1) and trains up
   normally through use — only the weapon they start holding is sharp.

### Implementation

Both run in the vanilla first-login hook
(`src/lua-vanilla/auto-equip-starter-kit.lua`,
`PLAYER_EVENT_ON_FIRST_LOGIN`), once per newly-created character:

- **Proficiencies:** `player:LearnSpell(spell)` for each weapon-proficiency
  spell the class can learn — learning it sets the equip mask *and* adds
  the skill line at default 1. Mirrors how the playerbot factory arms
  bots (`PlayerbotFactory::CanEquipWeapon` defines the same per-class
  weapon set); it is the weapon-skill sibling of 148j's ability pretrain.
  Runs BEFORE the kit is equipped so off-default kit weapons go on.
  Implemented in the hook as two tables: `CLASS_WEAPON_SKILLS`
  (class → skill lines, straight from the live-data class→skill table
  below) and `WEAPON_SKILL_PROFICIENCY` (skill line → proficiency spell).
  The proficiency spell ids are **not from memory** — each was verified
  against `acore_world.trainer_spell` (the weapon-master trainer data).
  The original plan to read them from `character_spell` does NOT work:
  bots set the `m_WeaponProficiency` mask directly and never store the
  proficiency spell, so `character_spell` holds none of them; the trainer
  table is the live source of truth instead. Druids include Fist (473),
  present in the live class→skill data even though the bot factory's
  `CanEquipWeapon` omits it.
- **Starter weapon value:** after equipping, `player:SetSkill(skill, 0,
  level*5, level*5)` for the skill governing each equipped kit weapon.
  `item_template.subclass` → skill line via the `WEAPON_SUBCLASS_SKILL`
  table in the hook. One-shot value set, NOT a pin — the skill still
  climbs normally past level 20.

Per-class weapon-proficiency set (derived from live character data;
skills 43 Sword, 44 Axe, 45 Bow, 46 Gun, 54 Mace, 55 2H-Sword, 136
Staff, 160 2H-Mace, 172 2H-Axe, 173 Dagger, 176 Thrown, 226 Crossbow,
228 Wand, 229 Polearm, 473 Fist):

| Class | Learnable weapon skills |
|---|---|
| Warrior | 43,44,45,46,54,55,136,160,172,173,176,226,229,473 |
| Paladin | 43,44,54,55,160,172,229 |
| Hunter  | 43,44,45,46,55,136,172,173,176,226,229,473 |
| Rogue   | 43,44,45,46,54,173,176,226,473 |
| Priest  | 54,136,173,228 |
| Shaman  | 44,54,136,160,172,173,473 |
| Mage    | 43,136,173,228 |
| Warlock | 43,136,173,228 |
| Druid   | 54,136,160,173,229,473 |

### Approaches rejected

- **`playercreateinfo_skills` with `rank=100`** (original design). That
  column is a skill tier-*step*, validated `< MAX_SKILL_STEP` (16), and
  ignored entirely for weapon skills — the value is level-derived. The
  rank=100 rows were rejected by the core, granted nothing, and logged
  52 warnings/boot. Removed from the generator; the `idempotence_clear`
  DELETE purges any already in the DB.
- **`AlwaysMaxSkillForLevel = 1`** (worldserver.conf). Pins skills at
  max for level *forever* — disables weapon-skill progression. Not used.
- **`AdvanceSkillsToMax()`** — maxes *all* skills at once; too broad
  (we want only the starter weapon sharp), though it informed the
  one-shot-not-a-pin shape.

### Status / checklist

- [x] Removed the dead `rank=100` `playercreateinfo_skills` rows from
      the generator; the `idempotence_clear` DELETE purges any already
      in the DB (the 52 "skill rank too high" warnings are gone).
- [x] Starter-weapon value: the hook maps the equipped kit weapon's
      `item_template.subclass` → skill line via `WEAPON_SUBCLASS_SKILL`
      and `SetSkill`s it to max-for-level (guarded by `HasSkill`).
- [x] **Weapon-proficiency pretrain.** `learn_weapon_proficiencies`
      runs on first login BEFORE `install_equipment`, `LearnSpell`-ing
      every proficiency the class can train, keyed through the
      `CLASS_WEAPON_SKILLS` × `WEAPON_SKILL_PROFICIENCY` tables (sets the
      `m_WeaponProficiency` equip mask + the skill line at default 1).
      Spell ids verified against `acore_world.trainer_spell`. Off-default
      kit weapons (a Tauren Warrior's polearm, an Orc Rogue's mace) now
      equip, and the `HasSkill` guard on the starter-weapon step sees the
      skill it needs. Wands excluded (casters hold that proficiency
      innately); Dual Wield (674) left to 148j.
- [ ] Validate in-client: roll one character per class; confirm every
      class weapon is proficient with no weapon-master visit, the
      starter weapon reads 100, and the rest read 1. This is the only
      remaining 148h step and it belongs to the 148o validation pass —
      **no implementation work is left in 148h itself.**

## Class Kit Items — Relics

Three relic types exist in 3.3.5a (libram, idol, totem). The DB
has exactly ONE white-quality relic: Totem of the Earthen Ring
(46978 → 2046978, white, RequiredLevel 1).

Per the No Greens rule, the kit reflects this asymmetry directly:

- **Shaman:** Totem of the Earthen Ring (the one white relic).
- **Paladin:** no libram — slot empty.
- **Druid:** no idol — slot empty.
- **Hunter:** Medium Quiver + Sharp Arrow stack (covered above).
- **Priest, Mage, Warlock:** Dusk Wand or Burning Wand fills the
  ranged slot.

No spell in 3.3.5a strictly requires a libram, idol, or totem
relic equipped to cast — relics are damage/healing modifiers,
not gatekeepers. Paladin and Druid not having their relic costs
them no functional ability; they just give up the buff.

## Cape — Uniform Across Classes

Every class gets the same cape: **Rugged Cape (2240 → 2002240)**.
A generic level-20 white-quality cloak with basic stamina/armor
stats. No class-specific cloak variation. The cape is the
project's small flair gesture — a hint of personality on an
otherwise utilitarian starting kit.

## Implementation Approach

A bash generator holds the kit matrix as data and emits an
idempotent SQL migration. The kit definitions for every
(race, class) plus universal cape, bags, hearthstone, and ammo
are all in the generator script's top-of-file tables. Re-run after
any kit change; commit both the script and its output.

### File layout

- `scripts/generate-vanilla-starting-equipment-sql` — the bash
  generator. Holds `RACE_CLASS_KIT` (the 52-row matrix as data),
  `RACE_CLASS_SKILL` (weapon-skill grants per row), and uses the
  clone entry IDs from the cloning procedure above. Emits ~570
  INSERT rows.
- `sql/vanilla/db_world.src/02-starting-equipment.apply.sql` — the
  E009 patch's apply-form source. E009 cp's this into
  `sql/vanilla/db_world/02-starting-equipment.sql` at install
  time; AzerothCore's UpdateFetcher then picks it up.
- `sql/vanilla/db_world.src/06-kit-required-level-cap.apply.sql` —
  the redesigned E018 patch. Performs steps 1, 2, 4, 5 of the
  cloning procedure (clone, tune, world-loot-table sweep, restore
  originals).
- `sql/vanilla/db_world.src/06-kit-required-level-cap.revert.sql` —
  the clean revert. DROPs cloned entries by entry-ID range
  (`entry BETWEEN 2000000 AND 2099999`), reverts loot table sweeps,
  restores playercreateinfo_item to whichever originals it pointed
  at before. No snapshot needed since the procedure is fully
  deterministic from the clone-ID convention.

### Per-row format

Each `playercreateinfo_item` row is `(race, class, itemid, amount,
Note)`. The Note column carries `vanilla-148h-<slot>` so audit
queries and the idempotence DELETE both filter on it.

Race wildcard (`race=0`) is NOT supported by the table's
(race, class, itemid) primary key — every combination is enumerated
explicitly. The generator iterates the 52 valid (race, class) pairs
(DK excluded per 148a; Gnome Priest also excluded as it doesn't
exist in vanilla `playercreateinfo`; Troll Mage IS included — it
exists in vanilla `playercreateinfo` and was incorrectly excluded
in the original 2026-06-02 generator as "Cataclysm-era," which is
the bug the redesign repairs).

For dual-wield kits (Orc Hunter cleaver-pair, Gnome Warrior twin
scimitars, every Rogue's dagger-pair), the same itemid appearing
twice for one (race, class) would collide on the primary key. The
generator expresses these as `amount=2` of a single row; the ALE
auto-equip hook (148k) splits the stack into main-hand and
off-hand at first login.

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
  Orc Hunter dual-cleaver, Gnome Warrior twin-scimitar, and every
  Rogue's twin-dagger kits depend on.
- `issues/148k-ale-auto-equip-starter-kit.md` — the ALE Lua hook
  that strips the DBC starter outfit on first login and auto-
  equips every item in this kit into its proper equipment slot,
  routes ammo into the quiver, and binds the hearthstone.
- `issues/148n-vanilla-racial-starting-zones.md` — per-race spawn
  zones; informs which town the hearthstone-bind hook (148k)
  points at.
- `issues/148o-vanilla-spawn-and-kit-validation-pass.md` — the
  test pass for spawn coords + per (race, class) kit equipping.
  The kit redesign here is what the validation pass validates.
- `issues/declined/148p-wand-spell-dps-parity-rebalance.md` — the
  wand DPS ≈ spell DPS rebalance, now **declined** (2026-07-15). This
  kit's wands stay at the 20-DPS placeholder; the full parity pass is
  not planned.
- `scripts/generate-vanilla-starting-equipment-sql` — kit data
  source of truth.
- `patches/E-patches.sh` — `patch_E009_vanilla_starting_equipment`,
  `patch_E018_vanilla_kit_required_level_cap` (the redesigned
  clone+tune variant).
