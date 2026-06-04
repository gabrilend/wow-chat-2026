# 148k - ALE Auto-Equip Starter Kit on Character Creation

## Status
- Created: 2026-06-02
- Phase: 1 (Foundation — profile model)
- Parent: 148 (vanilla profile)
- Sibling: 148h (starting equipment SQL), 148j (pretrain abilities SQL)
- Priority: Polish — without it the vanilla profile still functions,
  but every new character walks out of the starting zone with their
  full level-20 kit sitting **in the bag** instead of equipped, looking
  like a level-1 character in linen rags. With it, the character is
  visibly dressed in their starter kit the moment they appear on the
  character-select screen.

## Problem

AzerothCore grants new-character items in two layers:

1. The DBC `CharStartOutfit` outfit (shirt, pants, basic weapon,
   food, water, hearthstone, starter bag) is read from the client
   data file and the engine **auto-equips** these items into their
   equipment slots during the character-creation transaction.
2. The `playercreateinfo_item` rows that 148h's S4 migration writes
   are added to the character's **bag** — not equipped, just sitting
   in the first available bag slot.

So a vanilla character at first login has:
- Cloth shirt, cloth pants, the level-1 starter weapon: equipped
- Polished Scale Vest, the rest of the mail kit, the Longsword, the
  Reinforced Targe, the Rugged Cape: in the bag, unequipped

The player has to manually drag every item from the bag to its slot.
This is twelve drag-and-drops for a Warrior (six armor, cape,
main-hand, off-hand, plus moving the DBC starter weapon out of the
way), and the off-hand axe for an Orc Hunter or any Rogue can't even
be equipped until Dual Wield is granted (which 148j handles, but the
player still has to drag).

This sub-issue closes the gap with an ALE Lua hook that auto-equips
kit items into their appropriate slots before the player ever sees
the character.

## Why ALE (not C++, not a stored procedure)

- **Lives outside the C++ source tree.** No fork maintenance burden.
- **Hot-reloadable.** Tweaks land instantly via `/reload` without
  rebuilding the worldserver.
- **Already installed.** mod-ale is part of the vanilla profile's
  module set; the script lives in `src/lua-vanilla/` (the
  per-profile Lua dir introduced 2026-06-02 alongside the ALE
  enablement). It does NOT sit next to the ambush/travel/movement
  scripts — those live in `src/lua-beta/` (formerly just
  `src/lua/`) and are deliberately not loaded on vanilla.
- **The right tier of abstraction.** Equipment manipulation is
  gameplay logic, not infrastructure — Lua is where gameplay logic
  belongs in this project.

## Trigger Event

ALE exposes two once-per-character events that could fire the hook:

| Event | ID | When it fires |
|-------|----|---------------|
| `PLAYER_EVENT_ON_CHARACTER_CREATE` | 1 | During the character-creation transaction |
| `PLAYER_EVENT_ON_FIRST_LOGIN`      | 30 | First time the character enters the world after creation |

Both fire exactly once per character. The difference matters only
if `playercreateinfo_item` rows haven't landed in the bag yet by the
time the chosen event fires — in which case the scan finds nothing
to equip.

**Decision (verify during implementation):** prefer
`PLAYER_EVENT_ON_FIRST_LOGIN`. Reasoning: the bag is unambiguously
populated by login time. `ON_CHARACTER_CREATE` might fire before
the engine writes the playercreateinfo_item additions to the
character's inventory — depends on hook insertion point in
`Player::Create`. First login is the safer bet at a cost of
"items appear equipped on first character-select-screen render,
not the moment of clicking 'Create'."

The character-select-screen visibility test is the user-visible
acceptance criterion either way — both events save the equipment
state to disk before the select screen renders.

## Algorithm

The hook's shape is **strip everything, query the DB for the kit,
re-install in categorized order**. No allowlist check during strip
— the kit-definition source of truth is the S4 SQL, fetched at
runtime so the Lua holds no parallel kit table.

### Step 1: async kit fetch

The first thing on first-login is dispatching an async query against
the world DB:

```sql
SELECT pci.itemid, pci.amount, it.InventoryType, it.class, it.subclass
FROM playercreateinfo_item pci
JOIN item_template it ON it.entry = pci.itemid
WHERE pci.race = ? AND pci.class = ?
  AND pci.Note LIKE 'vanilla-148h-%'
ORDER BY pci.itemid;
```

This pulls every kit row for the (race, class) plus the
`InventoryType`/`class`/`subclass` metadata needed to route each
item. The `Note` filter scopes to S4's rows only (the
`vanilla-148h-*` prefix the bash generator stamps on every INSERT).

`WorldDBQueryAsync` is used instead of sync — the project's
`ambush.lua` precedent calls out a buffer-corruption bug in the
sync path. The async callback re-resolves the player by name
defensively.

### Step 2: strip every slot

When the callback fires, all three inventory ranges get emptied:

```
equipped slots 0-18        — RemoveItem each
equipped bag positions 19-22 — RemoveItem each
backpack 23-38             — RemoveItem each
```

No checking, no allowlist. The strip leaves the character in a
known-empty state. The kit will be re-installed immediately after
from the freshly-fetched query results.

### Step 3: categorize the kit rows

Each row from step 1 sorts into one of five buckets based on the
item-template metadata:

| Bucket    | Identified by                       | Install order |
|-----------|-------------------------------------|---------------|
| bags      | `item_template.class = 1`           | 1st           |
| quiver    | `item_template.class = 11`          | 2nd           |
| equip     | everything else routable by InventoryType | 3rd     |
| ammo      | `item_template.class = 6`           | 4th           |
| hearth    | `entry = 6948` (Hearthstone)        | 5th           |

Order matters. Bags before quiver so the quiver lands in bag
position 22 with no bag contention. Equipment before ammo so the
backpack has room. Ammo after the quiver is equipped so the engine
routes the new arrow stack into the quiver rather than the backpack
— this is exactly the "wait to add the ammo until the quiver is
equipped" the user called out 2026-06-02.

### Step 4: install each bucket

For each bucket, the install function `AddItem`s each row's
quantity, then equips/places as appropriate:

- **bags + quiver:** `AddItem(entry, 1)` per amount unit (split the
  stack so each container is its own item), then `EquipItem` into
  the next empty bag position.
- **equip:** look up the target slot via the `InventoryType` table;
  `AddItem(entry, 1)` per amount unit; for 1H weapons (InventoryType
  13 or 21), try main-hand first then fall back to off-hand if
  main-hand is already taken (this is the dual-wield branch — orc
  hunter dual axes, dual-Kris rogue, dual-Longsword BE/NE rogue).
- **ammo:** `AddItem(entry, amount)` as a single stack; the engine
  routes into the equipped quiver automatically.
- **hearth:** `AddItem(entry, 1)`; lands in the first Linen Bag with
  room.

### Slot Resolution Table

The `InventoryType` → equipment-slot mapping is a small static table
in the Lua. ALE's `enum EquipmentSlots` lives in
`docs/ale/docs/Player/EquipItem.html`; the relevant constants are
HEAD=0, NECK=1, SHOULDERS=2, BODY=3 (shirt), CHEST=4, WAIST=5,
LEGS=6, FEET=7, WRISTS=8, HANDS=9, FINGER1=10, TRINKET1=12, BACK=14,
MAINHAND=15, OFFHAND=16, RANGED=17.

| InventoryType | Slot        | Notes                              |
|---------------|-------------|------------------------------------|
| 1             | HEAD        | not in vanilla kit                 |
| 3             | SHOULDERS   | not in vanilla kit                 |
| 4             | BODY        | shirt — stripped, never re-added   |
| 5             | CHEST       | chest armor                        |
| 6             | WAIST       | belt                               |
| 7             | LEGS        | pants                              |
| 8             | FEET        | boots                              |
| 9             | WRISTS      | bracers                            |
| 10            | HANDS       | gloves                             |
| 13            | MAINHAND    | 1H (may spill to OFFHAND)          |
| 14            | OFFHAND     | shield                             |
| 15            | RANGED      | bow                                |
| 16            | BACK        | cape                               |
| 17            | MAINHAND    | 2H (occupies main + off mechanically) |
| 20            | CHEST       | robe (alias)                       |
| 21            | MAINHAND    | main-hand only                     |
| 22            | OFFHAND     | off-hand only                      |
| 23            | OFFHAND     | held-in-off-hand (Wildflowers, Darkmoon Flower) |
| 25            | RANGED      | thrown                             |
| 26            | RANGED      | wand / gun / crossbow              |
| 28            | RANGED      | relic (Totem of the Earthen Ring)  |

InventoryType 24 (ammo) and 27 (quiver) bypass this table — they're
routed by the bucket categorization above.

### Hearthstone Binding

After all items are installed, `Player:SetBindPoint` sets the home
location based on faction (`Player:GetTeam()` returns 0 for Alliance,
1 for Horde):

- **Alliance →** Darkshire, Duskwood (map 0, zone 10, x=-10573.0,
  y=-1182.51, z=28.0148).
- **Horde →** Tarren Mill, Hillsbrad Foothills (map 0, zone 267,
  x=-34.1467, y=-923.366, z=54.5576).

Coordinates from R3 results.

## Scope

In scope:
- ALE Lua script at `src/lua-vanilla/auto-equip-starter-kit.lua`
  (per-profile Lua dir; see E001 in `patches/E-patches.sh` for the
  symlink mechanism) hooked on `PLAYER_EVENT_ON_FIRST_LOGIN`.
- Strip-all-then-rebuild logic (no allowlist check).
- WorldDBQueryAsync against `playercreateinfo_item` JOINed with
  `item_template` for the kit definition.
- Categorized install (bags → quiver → equipment → ammo → hearth).
- Hearthstone bind-point setting via `SetBindPoint` based on
  `GetTeam()`.

Out of scope:
- **Character-CREATION-screen visibility.** The creation screen
  renders before the character exists in the database, driven by
  the client-side `CharStartOutfit.dbc`. User decision 2026-06-02:
  accept the mismatch. Kit appears on the select screen the
  instant creation finishes.
- Filtering kit items by player level. Vanilla starts at level 20
  uniformly; no level-up edge cases.
- Re-running the hook on every login. The hook's event-driven
  once-per-character semantics rule this out by construction.
- Maintaining a parallel kit table in Lua. The DB JOIN keeps the
  S4 SQL as the sole source of truth.

## Mechanism

### Event Registration

```lua
local PLAYER_EVENT_ON_FIRST_LOGIN = 30
RegisterPlayerEvent(PLAYER_EVENT_ON_FIRST_LOGIN, on_first_login)
```

The hook's entry point dispatches the async query and bounces into
the callback when results land:

```lua
local function on_first_login(event, player)
    local race       = player:GetRace()
    local class      = player:GetClass()
    local playerName = player:GetName()
    WorldDBQueryAsync(
        build_kit_query(race, class),
        function(query)
            apply_kit(playerName, query)
        end)
end
```

### Idempotence

`PLAYER_EVENT_ON_FIRST_LOGIN` fires exactly once per character;
re-firing is not a concern. The hook holds no per-character state.
A higher-level character will never re-trigger because the event
has fired already — the user's earlier critique of every-login
behavior is structurally avoided.

### Source-of-Truth Discipline

The Lua hook reads the kit from the DB at runtime, so the S4 SQL
remains the single source of truth for what a starter kit
contains. Adding a new kit item to the bash generator
(`scripts/generate-vanilla-starting-equipment-sql`) propagates to
this hook automatically — no Lua edit required, no parallel kit
table to keep in sync.

The Lua does hold one static table (`SLOT_BY_INVTYPE`) mapping
InventoryType to equipment slot. That's a 3.3.5a engine fact, not
kit data, so it lives in the Lua.

## Implementation Steps

1. Confirm `WorldDBQueryAsync` returns the expected JOIN result
   shape during install (column order, types). The signature is
   documented in `docs/ale/docs/Global/WorldDBQueryAsync.html`.
2. Test that `PLAYER_EVENT_ON_FIRST_LOGIN` fires AFTER the
   playercreateinfo_item additions are in the backpack. This is
   the strip-all-then-rebuild design's assumption.
3. Acceptance test per class on first login:
   - Create one character of each enabled class.
   - At character-select-screen, confirm the character renders
     wearing the kit's chest/legs/hands/feet/waist/wrist/back.
   - Confirm main-hand, off-hand, and (where applicable) ranged
     slots populate correctly.
   - For Orc Hunter and all Rogues, confirm both weapons are
     equipped — requires 148j to have applied (Dual Wield).
   - Open the inventory: three Linen Bags in positions 19-21;
     hunters with Medium Quiver in position 22; hearthstone in
     the first bag.
   - Type `/hearth` and confirm the player teleports to Darkshire
     (Alliance) or Tarren Mill (Horde).
   - Inventory should contain only the kit items plus the
     hearthstone — no DBC shirt, no DBC starter weapon, no DBC
     food/water clutter.

## Cross-References

- `issues/148.md` — parent vanilla-profile issue.
- `issues/148h-class-specific-starting-equipment.md` — the kit
  definition this hook auto-equips.
- `issues/148j-pretrain-level-20-abilities.md` — the spell-grant
  migration that lets the Orc Hunter and Rogue off-hand weapons
  actually equip. Without 148j, those slots stay empty even with
  this hook in place.
- `scripts/generate-vanilla-starting-equipment-sql` — the kit
  data source. The hook does NOT read this script; it derives
  equip slots from each item's own `InventoryType` so kit changes
  propagate without Lua edits.
- `docs/ale/docs/Global/RegisterPlayerEvent.html` — ALE event
  catalog. Source of truth for event IDs.

## Open Questions

- **Does `WorldDBQueryAsync` exhibit the same buffer-corruption bug
  the disabled `ambush.lua` flagged for sync `WorldDBQuery`?** The
  async path is the project's known-good precedent; the sync path
  is not used. If async also corrupts, the fallback is to encode
  the kit as a Lua table inside the script (duplicating the bash
  generator's data; maintenance burden, but functionally
  bulletproof).
- **Engine ammo routing.** After the quiver is equipped and the
  arrow stack is `AddItem`'d, the engine is expected to place the
  arrows into the quiver as the only valid ammo destination.
  Verify in playtest. If the arrows land in the backpack instead,
  the fix is a follow-up `RemoveItem` + `AddItem` to nudge the
  engine, or moving them explicitly to a slot inside the quiver
  via `Player:GetItemByPos(bag, slot)` indexing.
- **Stack semantics for amount=2 dual-wield weapons.** The hook
  calls `AddItem(entry, 1)` per unit, splitting the stack at
  install time. If `AddItem(entry, 1)` twice creates two stacks of
  one in separate slots (correct) vs. one stack of two (would
  need re-splitting before equipping the off-hand), the equip
  loop's `GetEquippedItemBySlot(MAINHAND) == nil` check handles
  the difference — but worth confirming for clarity in the comments.
