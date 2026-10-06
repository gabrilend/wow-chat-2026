# 617r - Elites: Bannermen's Outfits

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617 (buddy bots)
- Priority: Medium
- Related: 617a4 (buddy starting kit; its tiers are race-and-class lists),
  617f (selector appearance; the mirror-image outfits Sargobras wears),
  617g (talent plans; a buddy's plan and role pick its elite)
- Related files: `src/lua-basic/data/elite-outfit-profiles.lua` (the profiles),
  `src/lua-basic/elite-outfits.lua` (puts them on buddies),
  `scripts/test-elite-outfits` (checks every item against the world database)

## Origin

Verbatim, 2026-10-04:

> hi can you equip Growth's buddy-bots with gear that is roughly
> equivalent? They can be from any previous tier, but nothing beyond Molten
> Core. No Onyxia or Zul'gurub either. Just MC and dungeons and previous
> stuff. No PvP gear either.

> make profiles that are for each buddy-bot type. Name them "elites". For
> now, just do the ones for Growth. But this should be an issue file.
> Include a checklist of each character, with roughly the same type of
> equipment as Growth has now. They represent the power of the Horde and
> Alliance, and are bannermen. For now, Growth's party is orcs, tauren, and
> trolls. So create profiles for them, and that'll be fine. Later on, we
> will develop more outfits for NPCs and apply the mirror-image trick like
> we did with Sargobras.

## Current Behavior

**Built and worn, 2026-10-04.** Seven outfit profiles, one per buddy type
in Growth's party (Talriah, the blood elf paladin, added the same day:
"can you also equip Talriah, Growth's newest buddy-bot?"), are plain data
in `src/lua-basic/data/elite-outfit-profiles.lua` (not `elite-outfits.lua`:
the Lua engine refuses two files of one name, and the clash kept the
command from loading; `scripts/test-lua-unique-names` now guards that).
`scripts/test-elite-outfits` checks every item against the world database
and runs the command in a stand-in world (849 checks). `.elite Growth`
(run from the server console) dressed all seven: the warriors had no Plate
Mail, bows or guns, Kilta no Mail and Ecaexo no one-handed swords (a gap in
how buddies made at a high level learn, now in 617n); the command teaches
a missing proficiency before equipping and reports it, skips a dead buddy
(Ecaexo was dead and was revived first), and puts the old item back on a
slot that refuses the new one.

**What "elite" means, settled after this was built** (owner, 2026-10-04):
"an elite doesn't get buddy-bots. They are just NPCs that help fight at
the dark portal. They don't belong to a player." Elites proper are the
hero NPCs of 155z6, with gear specialised in an off-best stat. What this
issue built is a partner's buddies dressed in full Tier 1 sets, in the
format the elites will use; its name is an open question below.

## Intended Behavior

An **elite** is an outfit profile for one buddy type: race, class and role
(the talent plan's main tree: damage, tank or healer). Elites are the
bannermen of the Horde and the Alliance, so each one is worn as a full set:
its class's Tier 1 set and Molten Core or dungeon pieces in every other
slot, about as strong as their partner's own gear.

**The rule** (checked by the test, never by hand): every item exists in the
world database; drops in Molten Core or a classic dungeon (found through
the loot tables, including shared loot lists and chests, from where the
creatures and chests stand); never comes only from Onyxia's Lair,
Zul'Gurub, Blackwing Lair, Ahn'Qiraj or Naxxramas; needs no honor rank (no
PvP gear); needs level 60 or less; fits the slot it is listed for; can be
worn by the class (the item's class list); and is not listed twice in a
profile when the item is unique.

**Profile shape** (one entry per elite, keyed by name):

| Field | Type | Meaning |
|---|---|---|
| race | integer | race id (2 orc, 6 tauren, 8 troll, ...) |
| class | integer | class id (1 warrior, 7 shaman, 8 mage, 11 druid, ...) |
| role | integer | 0 damage, 1 tank, 2 healer (as the buddy roster holds it) |
| items | table | equipment slot number (integer, 0 head ... 17 ranged) to item id (integer) |

Shirt and tabard slots are never listed; a buddy keeps its own.

**Putting it on.** `.elite <partner name>` (game master only): for each of
the partner's buddies in the world, finds the elite with the buddy's race,
class and role, removes what it wears in each listed slot, and equips the
elite's item. A buddy with no matching elite is reported by name, never
given a near match. Live: the Lua engine reloads the script without a
restart or a compile.

**Later: NPCs.** The same profiles are meant to dress NPCs through the
mirror-image route (617f): the creature looks like a player of the
profile's race wearing the profile's items.

## Checklist: Growth's party

- [x] Pozeta: tauren warrior, Arms (damage). Elite "Tauren Warrior (damage)":
  Might set; Emberfury Talisman; Cape of the Black Baron; Quick Strike
  Ring, Painweaver Band; Hand of Justice, Heart of Wyrmthalak; Obsidian
  Edged Blade; Striker's Mark.
- [x] Xazian: troll warrior, Protection (tank). Elite "Troll Warrior (tank)":
  Might set; Medallion of Steadfast Might; Stoneskin Gargoyle Cape; Heavy
  Dark Iron Ring, Naglering; Force of Will, Vigilance Charm; Brutality
  Blade, Drillborer Disk; Blastershot Launcher.
- [x] Shauzhi: tauren druid, Balance (damage). Elite "Tauren Druid
  (damage)": Cenarion set; Choker of Enlightenment; Cloak of the Cosmos;
  Ring of Spell Power, Magus Ring; Talisman of Ephemeral Power, Draconic
  Infused Emblem; Staff of Dominance; Idol of the Moon.
- [x] Ecaexo: troll mage, Frost (damage). Elite "Troll Mage (damage)":
  Arcanist set; Choker of Enlightenment; Fireproof Cloak; Ring of Spell
  Power, Seal of the Archmagus; Talisman of Ephemeral Power, Briarwood
  Reed; Azuresong Mageblade, Fire Runed Grimoire; Crimson Shocker.
- [x] Kilta: orc shaman, Elemental (damage). Elite "Orc Shaman (damage)":
  Earthfury set; Choker of Enlightenment; Fireproof Cloak; Ring of Spell
  Power, Seal of the Archmagus; Talisman of Ephemeral Power, Briarwood
  Reed; Staff of Dominance; Totem of the Storm.
- [x] Muspo: tauren shaman, Restoration (healer). Elite "Tauren Shaman
  (healer)": Earthfury set; Lady Maye's Pendant; Fireproof Cloak;
  Cauterizing Band, Maiden's Circle; Second Wind, Mindtap Talisman;
  Aurastone Hammer, Observer's Shield; Totem of Sustaining.
- [x] Talriah: blood elf paladin, Retribution (damage). "Blood Elf Paladin
  (damage)": Lawbringer set; Emberfury Talisman; Cape of the Black Baron;
  Quick Strike Ring, Painweaver Band; Hand of Justice, Heart of
  Wyrmthalak; Obsidian Edged Blade (Spinal Reaper, first chosen, drops
  nowhere in the rule and the test refused it); Libram of Fervor.
- [x] Equipped in game with `elite Growth` (2026-10-04): 7 of 7 fully dressed.
- [ ] Each buddy inspected in game by the owner.

## Suggested Implementation Steps

1. Write the profiles as data (`src/lua-basic/data/elite-outfit-profiles.lua`).
2. Write the test: for each profile item, run the rule's checks against
   the world database, with the loot-source search done once per run.
3. Write the command script (`src/lua-basic/elite-outfits.lua`).
4. Reload the Lua engine, run `.elite Growth`, inspect each buddy.
5. Later: more elites (Alliance races, other classes and roles), and the
   NPC outfits through 617f.

## Open Questions

1. Elites are now the Dark Portal's hero NPCs (155z6). Should this tool
   and its data be renamed (say "buddy outfits", `.outfit <partner>`) so
   "elite" means only those heroes, or keep the name?
2. Should a buddy's outfit come back after it is remade (617a6), or is it
   a one-time gift?
3. Do world drops that also fall in Molten Core (Lady Maye's Pendant)
   count as Molten Core?
