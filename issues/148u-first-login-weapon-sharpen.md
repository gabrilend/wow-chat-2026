# 148u - First-Login Weapon Sharpen (a one-time send-off)

## Status
- Created: 2026-07-15
- Phase: 1 (Foundation — vanilla profile flavor)
- Parent: 148 (vanilla profile)
- Related: 148k / 148h (the `auto-equip-starter-kit.lua` first-login hook
  this rides in), 148q (built alongside)
- Priority: Low (flavor)
- **Blocked on one datum:** the temp-enchant ids live in the client's
  `SpellItemEnchantment.dbc`, which is empty in this server's DBC tables
  (`spellitemenchantment_dbc` = 0 rows). See "The one open datum" below —
  everything else is designed and the hook slot is ready.

## Problem

A freshly-created vanilla character walks out of their spawn inn fully
kitted (148h) and professioned (148q), but their weapon is just... a
weapon. A small, one-time "you sharpened your blade before setting out"
touch makes the character feel *ready* — a tiny bit of ceremony at the
threshold of adventure. Once only, at first login, while they're fresh.

## Intended Behavior

On first login, apply a **temporary weapon enhancement** to the equipped
main-hand — the same kind a sharpening stone or a weapon oil gives —
exactly once. Symmetric by weapon type so *everyone* gets a send-off:

- **Physical weapon** (sword/axe/mace/polearm/dagger/fist/bow/gun/thrown/
  crossbow) → a **sharpening/weightstone**-style temp enchant (+weapon
  damage).
- **Caster weapon** (staff/wand) → a **wizard-oil**-style temp enchant
  (+spell power). "Slather those rods with power spell oil."

It is a temporary enhancement (the normal stone/oil duration), not a
permanent enchant — a fresh edge for the road, not a forever buff.

## Mechanism

In the existing first-login hook (`src/lua-vanilla/auto-equip-starter-kit.lua`),
after `install_equipment`, read the main-hand item's weapon subclass and
apply a temporary enchant to the temp slot:

- `Item:SetEnchantment(enchantId, 6)` — slot 6 is the temporary-enchant
  slot (`TEMP_ENCHANTMENT_SLOT`). Confirmed available in ALE
  (`docs/ale/docs/Item/SetEnchantment.html`).
- Branch `enchantId` on `item_template.subclass`: physical subclasses →
  a sharpening enchant; staff (10) / wand (19) → a wizard-oil enchant.

A `sharpen_starter_weapon(player)` function, wired into `apply_kit`
right after `train_starter_weapon_skills`, mirroring the other
first-login steps. One call, first login only (the hook fires once).

## The one open datum — the enchant ids

`Item:SetEnchantment` takes a **SpellItemEnchantment id**, not a spell or
item id. Those ids are DBC data. In this environment:

- `spellitemenchantment_dbc` is **empty** (server loads it from the client
  `.dbc` at runtime), and `spell_dbc` is a partial subset — so the id
  cannot be resolved or verified from the database.
- The consumable → use-spell chain *is* resolvable and gives good leads
  (verified in `item_template`):
  Rough/Coarse/Heavy Sharpening Stone → spells 2828 / 2829 / 2830;
  Minor/Lesser Wizard Oil → spells 25117 / 25119; Minor Mana Oil → 25118.
  The enchant id is the `EffectMiscValue` of each spell's
  `SPELL_EFFECT_ENCHANT_ITEM_TEMPORARY` effect — which is in the client
  `Spell.dbc` / `SpellItemEnchantment.dbc`, not the server DB.

**Resolution:** pull the enchant ids from a full client's
`SpellItemEnchantment.dbc` (or a Wowhead/DBC reference), drop them into a
small `subclass → enchantId` table in the hook, and the send-off
activates. They are NOT hardcoded from memory here on purpose — an
unverifiable guess would be exactly the from-memory bug 148h and 148j
warn against.

## Implementation Steps

1. Resolve the sharpening-stone and wizard-oil temp-enchant ids from the
   client DBC (see above); pick a modest tier appropriate to a level-20
   send-off (e.g. Coarse Sharpening Stone / Minor Wizard Oil).
2. Add `sharpen_starter_weapon(player)` to the first-login hook: look up
   the main-hand weapon subclass, `SetEnchantment(enchantId, 6)`.
3. Wire the call into `apply_kit` after `train_starter_weapon_skills`.
4. In-client: roll a warrior (blade sharpened), a mage (staff oiled),
   confirm the temp enchant shows on the weapon tooltip and wears off
   normally.

## Open Questions

- Which tier? A modest level-appropriate stone/oil reads better than a
  max-tier one on a fresh character — leaning Coarse Sharpening Stone /
  Minor Wizard Oil.
- Do bow/gun/crossbow/thrown count as "physical" for a sharpen, or should
  ranged weapons be skipped? (Sharpening stones don't apply to ranged in
  retail.) Leaning: skip pure-ranged; sharpen melee, oil casters.
- Should the enhancement persist a bit longer than the default duration
  as a "fresh start" bonus, or match the vanilla stone/oil timer exactly?
