# 617r - Gearset Profiles (the first: "elite", the bannermen)

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617 (buddy bots)
- Priority: Medium
- Related: 617a4 (buddy starting kit; its tiers are race-and-class lists),
  617f (selector appearance; the mirror-image outfits Sargobras wears),
  617g (talent plans; a buddy's plan and role pick its elite),
  617t (dungeon stand-ins wear a profile), 155z6 (the Portal's hero NPCs
  wear one), 148h / 148k / 148s (the vanilla level-20 starter kit, which
  moves into this system)
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

**Gearset profiles** (owner, 2026-10-05): "we're just going to have
several different 'outfits' that can be applied to buddy-bots,
player-characters, stand-ins, or NPCs via the mirror image trick.
Essentially it should just be a list of gear, sorted by class and then
race. We should make these profiles very abstract, and able to be
referenced by certain chat commands. The 'elite' group is just the first
profile we made. Note how it's one profile: 'elite', and it has records
for every race/class. We should also transition the old 'level 20
starting gear' patch from... I wanna say the Vanilla profile? To this
profile system, and ensure that the patch is updated to use it correctly.
We will create additional 'gearset profiles' later on."

So a **gearset profile** is one named list of gear (`elite`,
`vanilla-starter`, later others), holding one record per class and, under
each class, per race. Nothing in a profile knows who will wear it: the
same record dresses a buddy, a player character, a stand-in (617t) or an
NPC (through the mirror image, 617f). One data file per profile, one
reader shared by every command and hook, one test that holds every
profile's items to that profile's own rule (the elite rule below is the
first such rule; the starter kit's is "white quality, level 20 or less").

| Level | Key | Type | Holds |
|---|---|---|---|
| profile | name | text | the gearset's rule name and its classes |
| class | class id | integer | the races of that class |
| race | race id | integer | the record: `items` (equipment slot integer to item id integer), and for the starter kit also `bags` (list of item ids), `ammo` (item id and count) |

Applied by chat command (game master): `.gearset <profile> <target>`,
where the target is a partner's name (all their buddies), one character's
name, or the selected creature (the mirror image). `.elite <partner>`
stays as the short form of `.gearset elite <partner>`.

**The vanilla starter kit moves in.** Today the level-20 kit is a matrix
inside a bash generator (`scripts/generate-vanilla-starting-equipment-sql`)
that stamps rows into the stock "items a new character gets" table
(`playercreateinfo_item`); the first-login hook (148k) and the bot gearing
patch (B025) both read those rows. After the move the matrix is the
`vanilla-starter` profile's data file, and the generator reads the profile
to write the same rows, so the creation step, the hook and B025 keep their
one source in the database while the gear itself lives in the profile
system. A test checks that the SQL the generator writes matches the
profile record for record.

### The first profile, "elite"

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

Gearset profiles (2026-10-05):

1. Reshape `elite-outfit-profiles.lua` into the profile shape (profile,
   class, race), keeping role where one class and race needs two records
   (see the open question); one reader both commands use.
2. `.gearset <profile> <target>`, with `.elite` kept as its short form;
   targets: a partner's buddies, one character, a selected creature.
3. Move the starter-kit matrix out of the bash generator into the
   `vanilla-starter` profile; the generator reads it and writes the same
   SQL (byte-identical output is the test that the move lost nothing).
4. Re-check B025 and the first-login hook against the regenerated rows.

The elite profile, as first built:

1. Write the profiles as data (`src/lua-basic/data/elite-outfit-profiles.lua`).
2. Write the test: for each profile item, run the rule's checks against
   the world database, with the loot-source search done once per run.
3. Write the command script (`src/lua-basic/elite-outfits.lua`).
4. Reload the Lua engine, run `.elite Growth`, inspect each buddy.
5. Later: more elites (Alliance races, other classes and roles), and the
   NPC outfits through 617f.

## Open Questions

1. (Answered 2026-10-05) The tool becomes gearset profiles; "elite" is
   the name of its first profile, not of the tool (quote above).
4. Role: "sorted by class and then race" leaves no place for two records
   of one class and race (a troll warrior tank and a troll warrior damage
   dealer). Add role as an optional third level, or make a role its own
   profile (`elite-tank`)?
5. The starter kit carries bags, a quiver and ammo as well as worn gear.
   Are those part of a gearset, or does the starter kit keep them outside
   the profile?
2. Should a buddy's outfit come back after it is remade (617a6), or is it
   a one-time gift?
3. Do world drops that also fall in Molten Core (Lady Maye's Pendant)
   count as Molten Core?
