# 155z16 - Outland Enchanting, From Drops

## Status
- Created: 2026-10-27
- Phase: 1
- Parent: 155 (the basic profile)
- Related: 155n (Outland without tradeskills: no profession past 300,
  install step E027), 155f (Outland dungeons at 64), 155k (basic's loot)
- Priority: Medium
- State: plan only; nothing built

## Origin

The owner, 2026-10-27:

> can you tell me, what can she do with Outland enchanting mats?
>
> we should be able to disenchant anything that drops, up to ilevel 120.
>
> maybe, we make any TK dungeon boss drop an enchanting recipe, and any TK
> raid boss drop a rare one? And Kael'Thas can drop the epic ones. If any.
> Oh also sunwell dungeons can drop them too.

## Current Behavior

In basic no profession goes past 300 (155n). Of the 78 enchanting recipes
that use Outland's materials (Arcane Dust, Lesser and Greater Planar
Essence, Small and Large Prismatic Shards, Void Crystal), 12 can be learned
at 300 (2026-10-27, read from the client's Spell.dbc and SkillLineAbility.dbc
against the world database's trainers and recipe items): from a trainer,
Enchant Bracer - Assault and Enchant Chest - Restore Mana Prime; from
recipe items, the cloak's Dodge, Stealth, Greater Fire and Nature
Resistance, and the gloves' Fire, Frost, Shadow and Healing Power,
Superior Agility and Threat. The rest need more than 300, or have no
trainer or recipe left. Items above the disenchanting skill a 300
enchanter has (most Outland greens and blues ask for 300-325) cannot be
disenchanted.

## Intended Behavior

1. **Disenchanting to item level 120**: any item that drops, up to item
   level 120, can be disenchanted by a 300 enchanter (its required
   disenchanting skill at most 300), giving its usual materials.
2. **Recipes from Tempest Keep and Sunwell**:
   - each boss of the Tempest Keep dungeons (the Mechanar, the Botanica,
     the Arcatraz) and of the Sunwell's dungeon (Magisters' Terrace) drops
     an enchanting recipe (uncommon);
   - each boss of Tempest Keep's raid (the Eye) drops a rare one;
   - Kael'thas Sunstrider drops the epic ones, if there are any.
   Each recipe usable at 300, so a basic enchanter can learn it.

## Suggested Implementation Steps

1. List the enchanting recipes by quality (the recipe items' own quality),
   their materials, and the skill they ask (a generator reading the client's
   files and the world database, as the answer above was read).
2. An install step (basic): the disenchanting skill of items up to level
   120 capped at 300 (`item_template.RequiredDisenchantSkill`).
3. An install step: the recipes' skill requirements lowered to 300, and
   each named boss given a loot entry of its quality's recipes (one drop
   from the list, by a reference loot table), with the chances below.
4. A quick test: every Tempest Keep and Magisters' Terrace boss has its
   recipe table; every recipe in them can be learned at 300; nothing up to
   level 120 asks more than 300 to disenchant.

## Open Questions

1. **The chance**: how often does a boss drop its recipe (every kill, or
   one in five)?
2. **Which recipes**: all enchanting recipes that use Outland materials,
   or only the ones with no other source in basic?
3. **Other professions**: enchanting only, or also other crafts' Outland
   recipes (tailoring, blacksmithing...)?
