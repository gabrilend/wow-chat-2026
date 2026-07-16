# 148o - Vanilla Spawn & Kit Validation Pass (per race × class)

## Status
- Created: 2026-06-11
- Phase: 1 (Foundation — closes 148n's deferred test pass)
- Parent: 148 (vanilla profile)
- Predecessor: 148n (per-race starting zones), 148h (per-race kit),
  148j (level-20 pretrain), 148k (auto-equip kit hook)
- Priority: High — one anchor (Stonetalon / Sun Rock) is
  confirmed broken in production, the others need ground-truth
  confirmation rather than guesswork from town anchors.

## Problem

The per-race starting-zone work (148n) shipped six town anchors
in `playercreateinfo` and the hearthstone-bind table inside the
ALE first-login kit hook. The anchor coordinates were copied from
memory rather than measured. A live reroll on Blood Elf surfaced
the failure mode: the character spawns inside terrain, slides out
underneath the world, and dies on void-fall. The death state
appears to skip the spirit-walk transition entirely — character
re-materialises at the closest graveyard as a still-prone corpse
at zero hit points with no ghost form and no release option. The
character is then unrecoverable without an admin-side teleport or
revive.

The shape of the failure is *not* race-specific. Any anchor where
the configured Z sits above the static terrain mesh's collision
ceiling will reproduce it — the engine treats spawn-inside-mesh
as out-of-world and routes the player through the void-death
pipeline. Every (race, class) combination that lands at a
mis-Z'd anchor inherits the bug.

This issue covers the test pass: a structured reroll matrix
across all valid (race, class) pairs, anchored against a stable
test-dev account so the production play account isn't polluted
with throwaway characters.

## Current Behavior (all anchors moved to innkeepers, 2026-07-13)

Every anchor now sits on its town innkeeper's tile. Coordinates
were pulled live from `acore_world_vanilla.creature` joined against
`creature_template` (innkeeper `npcflag` bit `0x10000`), picking the
nearest innkeeper to each former town-center guess — so the spawn is
guaranteed walkable ground on a tavern floor rather than a
copied-from-memory coordinate. Per user direction the fix was
generalised from "Sun Rock only" to "every anchor on an innkeeper."

| Race | Town | Innkeeper (entry) | Spawn (x, y, z) |
|---|---|---|---|
| 1, 3 (Human, Dwarf) | Menethil Harbor | Helbrek (1464) | (-3827.93, -831.9, 10.09) |
| 11 (Draenei) | Darkshire | Trelayne (6790) | (-10516, -1161.21, 28.12) |
| 4, 7 (Night Elf, Gnome) | Astranaar | Kimlya (6738) | (2781.16, -433, 116.67) |
| 2 (Orc) | Ratchet | Wiley (6791) | (-1050.04, -3664.8, 23.97) |
| 5, 8 (Undead, Troll) | Tarren Mill | Shay (2388) | (-5.97, -942.28, 57.16) |
| 6, 10 (Tauren, Blood Elf) | Sun Rock Retreat | Jayka (7731) | (893.65, 927.95, 106.36) |

The prior Sun Rock anchor (736, 1019, 137) spawned Tauren/Blood Elf
~200m NW of town and ~32m above the mesh → void-death; that row and
the five town-center rows are all replaced. The change lives in three
places kept in lockstep: the E007 heredoc in `patches/E-patches.sh`,
the active `sql/vanilla/db_world/01-starting-zones.sql` (UpdateFetcher
re-hashes on next boot), and the `HEARTH_BY_RACE` table in
`src/lua-vanilla/auto-equip-starter-kit.lua` (so hearthing returns to
the spawn inn). A live UPDATE set the running DB immediately. The
in-client reroll matrix below is the remaining validation.

**Data-side validation automated (2026-07-15).** The checks that do
not need a human eye now live in `scripts/validate-vanilla-starter-state`.
It asserts, across all 52 combos at once, that each spawns in its 148n
town zone, carries a weapon + three bags + a hearthstone, wears only
`RequiredLevel <= 20` gear, and that every class has its 148j pretrain
rows. As of this writing it reports **all five checks PASS**, so the
reroll matrix below narrows to the genuinely physical/visual checks:
is the spawn tile walkable, does the kit show equipped on the model,
does the hearthstone tooltip name the spawn inn. Run the script for
current ground truth rather than trusting any static table here.

## Intended Behavior

A test pass with the following deliverables:

1. **Sun Rock anchor fixed** for Tauren and Blood Elf — both the
   `playercreateinfo` row and the hearthstone-bind lookup updated
   to a known-good (x, y, z) inside Sun Rock Retreat. The
   suggested anchor is the Sun Rock Retreat innkeeper's tile:
   (893.65, 927.95, 106.36), orientation ~0.0. Innkeeper Jayka
   (creature_template entry 6272) sits there, so the ground is
   guaranteed walkable.

2. **Five other anchors confirmed walkable** by reroll — one
   character per anchor town, observing that the character
   materialises standing, in town, on solid ground.

3. **Per (race, class) reroll matrix executed** — one character
   per valid pair, observing:
   - Spawn anchor reachable (no fall, no void-death).
   - Starter kit applied (kit hook fires, full equipment set
     populated, hearthstone present in backpack).
   - Hearthstone bind set to the spawn town (right-click the
     hearthstone, verify teleport destination matches spawn).
   - Equipped weapons match the kit table for that (race, class).

4. **Test-dev account created** so the matrix doesn't accumulate
   characters on the main play account.

5. **Open question resolved** — the corpse-at-graveyard /
   no-ghost-form behaviour observed on Blood Elf's death. Either
   reproduce it (file follow-up issue) or document why the
   pipeline behaved that way under a void-fall death from
   inside-terrain spawn.

## Test-Dev Account Setup

Single account, full GM access, separate from the main play
account so test rerolls don't pollute the character list.

Recommended credentials: username `TESTDEV`, password `menardi`
(matches the project mysql convention so it's memorable). One-time
setup, then reuse across all test rerolls.

Two paths to create. **Path A (recommended)** uses the worldserver
console while the server is up, so the SRP6 verifier/salt are
generated correctly by the auth code path. **Path B** is a
fallback for cases where worldserver console is unavailable.

### Path A — worldserver console

From the worldserver console prompt (the terminal running
`./scripts/azerothcore worldserver`):

```
account create TESTDEV menardi
account set gmlevel TESTDEV 3 -1
account set addon TESTDEV 2
```

The first command creates the account with a proper SRP6
verifier. The second grants GM level 3 (full admin) on all realms.
The third sets the expansion access to WotLK so the client allows
Draenei/Blood Elf creation.

### Path B — direct DB (fallback if console unavailable)

AzerothCore's auth.account uses SRP6 with per-account salt and
verifier. Direct INSERT is possible but requires computing the
verifier with the right algorithm — easier to spin up worldserver
and use Path A. If Path B is genuinely needed, see
`src/server/database/Database/Implementation/LoginDatabase.cpp`
in the AC source for the SRP6 reference implementation.

### Verification

After setup, log in once to the test-dev account from the client
to confirm:

- Login succeeds with username + password.
- Character creation screen offers all races (Draenei, Blood Elf
  visible, confirming expansion = 2).
- GM commands work in-game (`.gm on`, `.tele`, `.revive` all
  respond).

## Per (race × class) Reroll Matrix

Execute against the test-dev account. Delete each character after
its checks complete so the slot is free for the next race × class.

Valid (race, class) pairs from `playercreateinfo` (Death Knight
class 6 is disabled per 148a, so omitted; race 9 reserved-Goblin
slot is also omitted):

| Race | Class set | Town |
|---|---|---|
| 1 Human | Warrior, Paladin, Rogue, Priest, Mage, Warlock | Menethil Harbor |
| 2 Orc | Warrior, Hunter, Rogue, Shaman, Warlock | Ratchet |
| 3 Dwarf | Warrior, Paladin, Hunter, Rogue, Priest | Menethil Harbor |
| 4 Night Elf | Warrior, Hunter, Rogue, Priest, Druid | Astranaar |
| 5 Undead | Warrior, Rogue, Priest, Mage, Warlock | Tarren Mill |
| 6 Tauren | Warrior, Hunter, Shaman, Druid | Sun Rock Retreat |
| 7 Gnome | Warrior, Rogue, Mage, Warlock | Astranaar |
| 8 Troll | Warrior, Hunter, Rogue, Priest, Shaman, Mage | Tarren Mill |
| 10 Blood Elf | Paladin, Hunter, Rogue, Priest, Mage, Warlock | Sun Rock Retreat |
| 11 Draenei | Warrior, Paladin, Hunter, Priest, Shaman, Mage | Darkshire |

52 characters total across the matrix. (An earlier draft said 49;
the authoritative count is `SELECT COUNT(*) FROM playercreateinfo
WHERE class != 6 AND race != 9` = 52 non-DK, non-reserved combos.)

### Per-character checklist

For each character created:

1. **Spawn check**
   - Character appears standing, in town, with terrain visible
     below their feet.
   - No fall, no void-death, no stuck-in-mesh.

2. **Kit check** (drives 148h / 148k validation)
   - Three Linen Bags in bag slots 19, 20, 21.
   - Hunter only: Medium Quiver in bag slot 22, Sharp Arrows
     inside it.
   - Full armor set equipped (head through feet, cape, etc.).
   - Weapon(s) equipped per the kit table (see Weapon Reference
     below).
   - Hearthstone present in backpack.
   - Backpack otherwise empty (no leftover starter items, no
     racial bread/water).

3. **Bind check**
   - Right-click hearthstone, observe tooltip says the spawn
     town's inn (e.g. "Hearthstone — Hearthstone is bound to
     Stonetalon Mountains, Sun Rock Retreat").

4. **Level check** (drives 148j validation)
   - Character is level 20.
   - Talent points available (per 148m's tuning — should be
     enough for one full tree spec).

5. **Log the result** — pass / fail per (race, class) row, with
   notes for any deviation. A pass row can be just the (race,
   class) pair. A fail row should note which check failed and
   what the actual behaviour was.

### Suggested execution order

Test the broken anchor first so the fix gets the most reps:

1. Tauren Warrior → Sun Rock Retreat (anchor check)
2. Blood Elf Paladin → Sun Rock Retreat (anchor check, race 10)
3. Then sweep one of each class for the other five towns to
   surface anchor-level failures early before doing the full
   matrix.
4. Then complete the matrix.

## Weapon Reference (kit table from playercreateinfo_item)

> **Stale (pre-clone).** This table was assembled 2026-06-11, one day
> before 148h's 2026-06-12 clone redesign, so it lists the original
> weapon entries (Longsword 923, Kris 2209, …) rather than the tuned
> clones (2000000+) the kit uses now. The anomalies flagged below
> (Troll Mage no weapon, etc.) were re-checked against the CURRENT kit
> and do NOT reproduce — `scripts/validate-vanilla-starter-state`
> confirms every combo has a weapon. Kept for the DPS methodology;
> regenerate real numbers from the live DB, not from this table.

Generated by joining `playercreateinfo_item` (Note prefix
`vanilla-148h-%`) against `item_template`, computing DPS as
(dmg_min + dmg_max) / 2 / (delay / 1000). The kit installer
(148k) assigns one-handers to main + off based on
`INVTYPE_IS_ONE_HAND`, so `amount=2` rows produce a dual-wield
setup.

The weapon set is small — nine distinct entries cover the entire
matrix:

| Entry | Name | Subclass | InvType | Slot | dmg | delay | DPS |
|---|---|---|---|---|---|---|---|
| 922 | Dacian Falx | 8 (polearm) | 17 | 2H | 39-60 | 3.1 | 15.97 |
| 923 | Longsword | 7 (sword) | 21 | MH | 19-37 | 2.3 | 12.17 |
| 924 | Maul | 5 (mace 2H) | 17 | 2H | 37-56 | 2.9 | 16.03 |
| 925 | Flail | 4 (mace 1H) | 21 | MH | 18-34 | 2.2 | 11.82 |
| 926 | Battle Axe | 1 (axe 2H) | 17 | 2H | 46-70 | 3.8 | 15.26 |
| 927 | Double Axe | 0 (axe 1H) | 13 | 1H | 19-36 | 2.5 | 11.00 |
| 928 | Long Staff | 10 (staff) | 17 | 2H | 36-55 | 3.0 | 15.17 |
| 2209 | Kris | 15 (dagger) | 13 | 1H | 12-23 | 1.6 | 10.94 |
| 3027 | Heavy Recurve Bow | 2 (bow) | 15 | Ranged | 21-40 | 2.4 | 12.71 |
| 5211 | Dusk Wand | 19 (wand) | 26 | Ranged | 21-39 | 1.7 | 17.65 |
| 15810 | Short Spear | 6 (polearm) | 17 | 2H | 40-60 | 3.3 | 15.15 |

### Per (race × class) weapon assignment

| Race | Class | Weapons (qty × name) | DPS profile |
|---|---|---|---|
| Human | Warrior | 1× Longsword (MH) | 12.17 |
| Human | Paladin | 1× Maul (2H) | 16.03 |
| Human | Rogue | 2× Kris (dual) | 10.94 + 10.94 |
| Human | Priest | 1× Flail (MH), 1× Dusk Wand | 11.82 + wand 17.65 |
| Human | Mage | 1× Long Staff (2H), 1× Dusk Wand | 15.17 + wand 17.65 |
| Human | Warlock | 1× Longsword (MH), 1× Dusk Wand | 12.17 + wand 17.65 |
| Orc | Warrior | 1× Longsword (MH) | 12.17 |
| Orc | Hunter | 2× Double Axe (dual 1H), 1× Heavy Recurve Bow | 11.00 + 11.00, bow 12.71 |
| Orc | Rogue | 1× Kris, 1× Flail (mixed dual) | 10.94 + 11.82 |
| Orc | Shaman | 1× Flail (MH) | 11.82 |
| Orc | Warlock | 1× Longsword (MH), 1× Dusk Wand | 12.17 + wand 17.65 |
| Dwarf | Warrior | 1× Longsword (MH) | 12.17 |
| Dwarf | Paladin | 1× Flail (MH) | 11.82 |
| Dwarf | Hunter | 1× Longsword (MH), 1× Heavy Recurve Bow | 12.17, bow 12.71 |
| Dwarf | Rogue | 2× Kris (dual) | 10.94 + 10.94 |
| Dwarf | Priest | 1× Flail (MH), 1× Dusk Wand | 11.82 + wand 17.65 |
| Night Elf | Warrior | 1× Short Spear (2H) | 15.15 |
| Night Elf | Hunter | 1× Longsword (MH), 1× Heavy Recurve Bow | 12.17, bow 12.71 |
| Night Elf | Rogue | 2× Longsword (dual MH) | 12.17 + 12.17 |
| Night Elf | Priest | 1× Flail (MH), 1× Dusk Wand | 11.82 + wand 17.65 |
| Night Elf | Druid | 1× Long Staff (2H) | 15.17 |
| Undead | Warrior | 1× Longsword (MH) | 12.17 |
| Undead | Rogue | 1× Longsword, 1× Kris (mixed dual) | 12.17 + 10.94 |
| Undead | Priest | 1× Flail (MH), 1× Dusk Wand | 11.82 + wand 17.65 |
| Undead | Mage | 1× Long Staff (2H), 1× Dusk Wand | 15.17 + wand 17.65 |
| Undead | Warlock | 1× Longsword (MH), 1× Dusk Wand | 12.17 + wand 17.65 |
| Tauren | Warrior | 1× Longsword (MH) | 12.17 |
| Tauren | Hunter | 1× Longsword (MH), 1× Heavy Recurve Bow | 12.17, bow 12.71 |
| Tauren | Shaman | 1× Maul (2H) | 16.03 |
| Tauren | Druid | 1× Long Staff (2H) | 15.17 |
| Gnome | Warrior | 1× Longsword (MH) | 12.17 |
| Gnome | Rogue | 2× Kris (dual) | 10.94 + 10.94 |
| Gnome | Mage | 1× Long Staff (2H), 1× Dusk Wand | 15.17 + wand 17.65 |
| Gnome | Warlock | 1× Longsword (MH), 1× Dusk Wand | 12.17 + wand 17.65 |
| Troll | Warrior | 1× Battle Axe (2H) | 15.26 |
| Troll | Hunter | 1× Longsword (MH), 1× Heavy Recurve Bow | 12.17, bow 12.71 |
| Troll | Rogue | 2× Kris (dual) | 10.94 + 10.94 |
| Troll | Priest | 1× Flail (MH), 1× Dusk Wand | 11.82 + wand 17.65 |
| Troll | Shaman | 1× Battle Axe (2H) | 15.26 |
| Troll | Mage | — *(no weapon row in kit — confirm during test pass)* | — |
| Blood Elf | Paladin | 1× Dacian Falx (2H polearm) | 15.97 |
| Blood Elf | Hunter | 1× Short Spear (2H), 1× Heavy Recurve Bow | 15.15, bow 12.71 |
| Blood Elf | Rogue | 2× Longsword (dual MH) | 12.17 + 12.17 |
| Blood Elf | Priest | 1× Flail (MH), 1× Dusk Wand | 11.82 + wand 17.65 |
| Blood Elf | Mage | 1× Long Staff (2H), 1× Dusk Wand | 15.17 + wand 17.65 |
| Blood Elf | Warlock | 1× Longsword (MH), 1× Dusk Wand | 12.17 + wand 17.65 |
| Draenei | Warrior | 1× Longsword (MH) | 12.17 |
| Draenei | Paladin | 1× Maul (2H) | 16.03 |
| Draenei | Hunter | 1× Longsword (MH), 1× Heavy Recurve Bow | 12.17, bow 12.71 |
| Draenei | Priest | 1× Flail (MH), 1× Dusk Wand | 11.82 + wand 17.65 |
| Draenei | Shaman | 1× Double Axe (1H) | 11.00 |
| Draenei | Mage | 1× Long Staff (2H), 1× Dusk Wand | 15.17 + wand 17.65 |

### Observations during table assembly

A handful of kit rows look surprising. Flag for human eyes during
the matrix pass — these may be intentional or may be SQL
generation bugs in 148h:

- **Orc Rogue with a Flail.** Flail (entry 925) is `InventoryType
  21` (`WEAPONMAINHAND`) and is the kit's go-to one-hand mace
  filler. Rogues can wield it, but the rest of the matrix's
  rogues get daggers or swords — the Orc Rogue is the only one
  with a mace. Likely intentional (Orc Mace Specialization
  racial), worth a verify.
- **Undead Rogue with a Longsword + Kris mix.** Most rogues get
  matched dual-wield (2× Kris or 2× Longsword). Undead has 1+1
  asymmetric. May be intentional, may be SQL bug.
- **Troll Mage has no weapon kit row.** Other mages get Long
  Staff + Dusk Wand; Troll Mage's kit query returns no weapon
  row. Confirm in-game whether they spawn with a weapon at all.
- **Draenei Shaman gets a Double Axe** (one-hand axe), but no
  shield row paired with it. Other 1H casters either have a wand
  or a 2H. Confirm whether a shield is expected.

## Sun Rock Anchor Fix

> **Done + generalised (2026-07-13).** The three-place mechanism
> below (SQL apply-form + hearth table + live UPDATE) was applied to
> *all six* anchors, not just Sun Rock — see Current Behavior for the
> innkeeper coordinates. This section is retained as the worked
> example for the mechanism.

Two file edits and one live UPDATE so the fix takes effect
without a worldserver restart.

### 1. `sql/vanilla/db_world/01-starting-zones.sql`

Last UPDATE statement (Stonetalon row for race in (6, 10)):

```sql
-- Before:
UPDATE `playercreateinfo` SET `map`=1, `zone`=406, `position_x`=736.0,  `position_y`=1019.0,  `position_z`=137.0,  `orientation`=0.0 WHERE `race` IN (6,10) AND `class` != 6;

-- After:
UPDATE `playercreateinfo` SET `map`=1, `zone`=406, `position_x`=893.65, `position_y`=927.95,  `position_z`=106.36, `orientation`=0.0 WHERE `race` IN (6,10) AND `class` != 6;
```

The UpdateFetcher hashes the file on next worldserver boot and
re-applies, so the apply-form rewrite is durable.

### 2. `src/lua-vanilla/auto-equip-starter-kit.lua`

`HEARTH_BY_RACE` table, race 6 and race 10 rows. Replace the
(736, 1019, 137) coordinates with (893.65, 927.95, 106.36) on
both rows. Map and area IDs stay the same. The hot-reload that
ALE supports means the kit hook will pick up the new bind point
without a restart.

### 3. Live UPDATE (so the change takes effect immediately)

```sql
UPDATE acore_world_vanilla.playercreateinfo
SET position_x=893.65, position_y=927.95, position_z=106.36
WHERE race IN (6, 10) AND class != 6;
```

Run via `scripts/mysql-client acore_world_vanilla`. Without this
step the next reroll still reads the old (736, 1019, 137) from
the in-memory playercreateinfo cache — UpdateFetcher only fires
on worldserver boot.

## Open Questions

- **Corpse-at-graveyard with no ghost transition.** The Blood Elf
  death-from-void produced a still-prone corpse at the closest
  graveyard with no spirit-walk animation. User reported the
  transition was instantaneous — "here one minute then ghost the
  second" — with no intermediate travel. Hypothesis: the void-
  death pipeline (`Player::RepopAtGraveyard` invoked from out-of-
  world detection) teleports the player's coordinates but leaves
  the death-state machine in a transitional state where neither
  alive nor ghost-form flags resolve. The corpse-only-no-ghost
  state then prevents the release-spirit input from registering
  (the engine thinks the release has already happened). Worth
  reproducing once the spawn fix is in — fall a Blood Elf into
  the void from elsewhere and see whether the bug is "spawn-
  inside-mesh death specifically" or "any void death."
- **Wetlands and Darkshire anchor Z's flagged "likely OK".** The
  +9m delta at Menethil and +1-2m at Darkshire are within
  tolerance based on town-floor measurements, but neither has
  been live-confirmed. The matrix pass closes this — the first
  character that rolls Human/Dwarf and Draenei is the live
  confirm.
- **Gnomes in Ashenvale.** 148n flagged this as the most unusual
  per-race choice. The matrix pass is where the design call gets
  feedback — if rolling a Gnome there feels weird, the open
  question on 148n stays open and the per-race table gets
  another revision.

## Files to Update

| Path | Action | Note |
|---|---|---|
| `sql/vanilla/db_world/01-starting-zones.sql` | edit one row | Stonetalon UPDATE — new coords for race in (6, 10) |
| `src/lua-vanilla/auto-equip-starter-kit.lua` | edit two rows | `HEARTH_BY_RACE[6]` and `[10]` |
| `acore_world_vanilla.playercreateinfo` | live UPDATE | Same coord change for race in (6, 10), class != 6 |
| `auth.account` + `auth.account_access` | one-time INSERT | Test-dev account via worldserver console |
| (new during matrix pass) | observation log | Notes per (race, class) — spawn / kit / bind / level outcomes |

## Implementation Steps

1. Create the test-dev account via worldserver console (Path A
   above). Confirm login from client.
2. Edit `sql/vanilla/db_world/01-starting-zones.sql` Stonetalon
   UPDATE row with the corrected coords.
3. Edit `src/lua-vanilla/auto-equip-starter-kit.lua`'s two
   Stonetalon rows in `HEARTH_BY_RACE`.
4. Live-UPDATE `playercreateinfo` for race in (6, 10) so the
   change is immediate.
5. Reroll Tauren Warrior and Blood Elf Paladin first — confirm
   Sun Rock anchor is now walkable.
6. Sweep one (race, class) per remaining town to surface anchor
   issues on the other five towns.
7. Complete the full 49-character matrix, logging pass/fail per
   row with notes on any kit deviation.
8. Investigate the corpse-at-graveyard open question if
   reproducible. If reproducible standalone, file a follow-up
   issue tracking the death-state-machine angle separately.
9. Close 148n's two open questions (Stonetalon coords, gnome
   placement feel) based on matrix results.
