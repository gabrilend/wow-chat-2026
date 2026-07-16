# 148n - Vanilla Racial Starting Zones (per-race refinement of 148h)

## Status
- Created: 2026-06-04
- Phase: 1 (Foundation — profile model; carries gameplay-zone
  semantics but the change shape is a playercreateinfo data tweak)
- Parent: 148 (vanilla profile)
- Predecessor: 148h's E007 (which set Alliance → Darkshire, Horde →
  Tarren Mill as a bulk per-faction rule)
- Priority: Medium (gameplay-feel)

## Problem

E007 today applies a coarse two-zone split: every Alliance race
spawns at Darkshire (Duskwood), every Horde race at Tarren Mill
(Hillsbrad). That solves the "level-1 racial enclaves are wrong for
a level-20 start" problem but flattens what could be a richer
opening-area distribution. With 10 races compressed into 2 zones,
the world feels sparser than it should — the two designated towns
get crowded with Tauren and Blood Elf and Orc shoulder-to-shoulder,
and the rest of Eastern Kingdoms / Kalimdor is empty of fresh-spawn
players.

A per-race mapping spreads the opening population across more
appropriate zones — places that match the race's lore "near home"
distance while also fitting the level-20 difficulty band.

## Current Behavior

**The per-race spread described under Intended Behavior is now live**
(shipped with the 148n/148o work). The vanilla `playercreateinfo` no
longer uses E007's coarse two-zone bucket — each race (all non-DK
classes) is sent to its own town, and every anchor coordinate is
measured live from that town's **innkeeper NPC** in the creature
table, so the spawn lands on walkable ground rather than a
copied-from-memory town-center guess that risked dropping the player
inside a building facade or over a void.

Live migration: `sql/vanilla/db_world/01-starting-zones.sql` (the
E007 apply-form). Note there is no separate `.src` twin for the zones
file — unlike the equipment migrations, it is maintained directly in
`db_world/`.

| Race | Spawn zone (map, zone) | Anchor | position_x, y, z, orient |
|---|---|---|---|
| 1 Human, 3 Dwarf | Wetlands (0, 38) | Menethil Harbor inn | -3827.93, -831.9, 10.09, 0.4014 |
| 11 Draenei | Duskwood (0, 10) | Darkshire inn | -10516.0, -1161.21, 28.12, 4.0317 |
| 4 Night Elf, 7 Gnome | Ashenvale (1, 331) | Astranaar inn | 2781.16, -433.0, 116.67, 2.5831 |
| 2 Orc | Northern Barrens (1, 17) | Ratchet inn | -1050.04, -3664.8, 23.97, 6.0039 |
| 5 Undead, 8 Troll | Hillsbrad (0, 267) | Tarren Mill inn | -5.97, -942.28, 57.16, 2.7415 |
| 6 Tauren, 10 Blood Elf | Stonetalon (1, 406) | Sun Rock Retreat inn | 893.65, 927.95, 106.36, 5.7072 |

The hearthstone bind follows the same spread now — the auto-equip
first-login hook binds each character's hearth to its own spawn town
(resolving the bind-point Open Question below), and the existing bot
fleet was moved onto the spread in the same pass. DK (class 6) rows
remain untouched (class disabled per 148a).

## Intended Behavior

Per-race zone assignment, mixing factional flavor and
geographic logic:

| Race | Race name | Spawn zone | Map | Zone ID | Approx. anchor |
|---|---|---|---|---|---|
| 1 | Human | Wetlands | 0 | 38 | Menethil Harbor |
| 3 | Dwarf | Wetlands | 0 | 38 | Menethil Harbor |
| 11 | Draenei | Duskwood | 0 | 10 | Darkshire |
| 4 | Night Elf | Ashenvale | 1 | 331 | Astranaar |
| 7 | Gnome | Ashenvale | 1 | 331 | Astranaar |
| 2 | Orc | Northern Barrens | 1 | 17 | Ratchet |
| 5 | Undead | Hillsbrad Foothills | 0 | 267 | Tarren Mill |
| 8 | Troll | Hillsbrad Foothills | 0 | 267 | Tarren Mill |
| 6 | Tauren | Stonetalon Mountains | 1 | 406 | Sun Rock Retreat |
| 10 | Blood Elf | Stonetalon Mountains | 1 | 406 | Sun Rock Retreat |

Design notes per pairing:

- **Humans + Dwarves → Wetlands.** Both Alliance, both starting
  from a "stronghold further north" feel. Menethil Harbor is a
  port town, gives the opening a "headed out into the world"
  framing.
- **Draenei → Duskwood.** Asymmetric choice — Draenei don't
  normally have lore in the Eastern Kingdoms south. Putting them
  at Darkshire makes them feel transplanted, which fits the
  Exodar refugees framing.
- **Night Elves + Gnomes → Ashenvale.** Gnomes ride along with
  Night Elves here — engineering-curious newcomers finding their
  feet in Kaldorei territory. Astranaar is the Alliance town in
  Ashenvale.
- **Orcs → Northern Barrens (Ratchet).** Ratchet is the neutral
  goblin port on the Barrens coast. Orcs starting here read as
  "out into the world to find work" rather than "stay in your
  hometown" — fits a level-20 opening.
- **Undead + Trolls → Hillsbrad.** Tarren Mill is a Forsaken
  stronghold. Trolls ride along as Horde allies operating from
  there.
- **Tauren + Blood Elves → Stonetalon.** Stonetalon Mountains is
  contested between Alliance and Horde at this level band. Sun
  Rock Retreat is the Horde encampment — Tauren and Blood Elves
  start at a faction outpost in a frontier zone.

Class 6 (DK) rows still untouched; the class remains disabled per
148a.

## Disablement Mechanism — Rewrite of E007's apply SQL

The shape stays identical to what E007 does today: rewrite
`sql/vanilla/db_world.src/01-starting-zones.apply.sql` with the
new per-race UPDATEs. AC's UpdateFetcher hashes the file on next
worldserver boot, sees the change, re-applies.

Each row in the table above becomes one UPDATE statement:

```sql
UPDATE playercreateinfo SET map=0, zone=38, position_x=-3826, position_y=-793, position_z=19, orientation=4.84 WHERE race IN (1,3) AND class != 6;
UPDATE playercreateinfo SET map=0, zone=10, position_x=-10573, position_y=-1182.51, position_z=28.0148, orientation=0.309 WHERE race = 11 AND class != 6;
UPDATE playercreateinfo SET map=1, zone=331, position_x=2728, position_y=-380, position_z=107, orientation=0.0 WHERE race IN (4,7) AND class != 6;
UPDATE playercreateinfo SET map=1, zone=17, position_x=-978, position_y=-3771, position_z=5, orientation=0.0 WHERE race = 2 AND class != 6;
UPDATE playercreateinfo SET map=0, zone=267, position_x=-34.1467, position_y=-923.366, position_z=54.5576, orientation=0.15019 WHERE race IN (5,8) AND class != 6;
UPDATE playercreateinfo SET map=1, zone=406, position_x=736, position_y=1019, position_z=137, orientation=0.0 WHERE race IN (6,10) AND class != 6;
```

Coordinates are approximate town-center anchors. Live testing
during implementation may nudge them by a few meters to land on
a clean tile rather than inside a building's facade.

## Files To Update

| Path | Action | Note |
|---|---|---|
| `sql/vanilla/db_world.src/01-starting-zones.apply.sql` | rewrite | replace the two faction-bucket UPDATEs with five per-race UPDATEs |
| `acore_world_vanilla.playercreateinfo` | live-apply | run the new UPDATEs directly so existing-conf new characters move immediately, instead of waiting for E007 to re-fire on next worldserver boot |

E007's E-patch handler (`patch_E007_vanilla_starting_zones`) is
profile-anonymous already (since the post-refactor pass in 804ead3),
so no change needed to the patch function — just to its source SQL.

## Implementation Steps

1. Rewrite `sql/vanilla/db_world.src/01-starting-zones.apply.sql`
   with the new UPDATEs. Preserve the `MARKER_E007_APPLY` header.
2. Live-apply the new UPDATEs against `acore_world_vanilla` so the
   change takes immediate effect without waiting for worldserver
   restart's UpdateFetcher hash-check.
3. Optionally update E007's revert form (`unpatch_*` in
   E-patches.sh) to restore the upstream per-race racial enclave
   coords if a profile-off-ramp is ever needed. The current revert
   already does this (it hardcodes the upstream coords by race), so
   no change required — the per-race revert is already in place.
4. Reroll a character of each race in turn and confirm spawn at the
   new town.

## Open Questions

- **Map 1 (Kalimdor) routing for Gnomes.** Putting Gnomes at
  Astranaar is the most unusual choice. If feedback says "Gnomes
  feel out of place in Ashenvale" we'd move them — Loch Modan,
  Wetlands (shared with Humans/Dwarves), or even Stranglethorn
  are candidate alternatives. (Still open — a feel/feedback call,
  not a correctness bug.)

### Resolved

- **Inn / hearthstone bind point.** RESOLVED — the
  `auto-equip-starter-kit` first-login hook now binds each race's
  hearth to its own spawn town, matching the per-race spread, so a
  hearth returns the player to where they started rather than the
  old Darkshire/Tarren Mill bucket.
- **Existing bot characters.** RESOLVED — the existing bot fleet was
  moved onto the per-race spread (`characters.position_*` +
  `character_homebind`) in the same pass.
- **Stonetalon coords specifically.** RESOLVED — every anchor
  (Sun Rock included) is now measured live from the town innkeeper
  in the creature table instead of approximated from memory, which
  is exactly what guarantees a walkable-ground spawn.
