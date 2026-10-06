# 617r - Gearset Profiles (the first: "elite", the bannermen; the vanilla starter kit)

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
- Related files: `src/lua-basic/data/gearsets/*.lua` (the profiles: `elite`,
  `vanilla-starter`), `src/lua-basic/lib/gearsets.lua` (finds a
  character's record), `src/lua-basic/gearset-command.lua` (puts them on),
  `scripts/generate-vanilla-starting-equipment-sql` (the starter kit's
  SQL from its profile), `scripts/test-gearsets` (checks every item
  against the world database and runs the command offline)

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

**Gearset profiles, built 2026-10-05; not yet run in game.** Two
profiles, each a data file in `src/lua-basic/data/gearsets/`, written
from the earlier lists by `scripts/convert-to-gearsets` (one-off):

- `elite` (keyed by spec): the seven outfits below, each filed under the
  spec its checklist names (Arms 161, Protection 163, Balance 283, Frost
  61, Elemental 261, Restoration 262, Retribution 381) and race.
- `vanilla-starter` (keyed by class): the level-20 starter kit for all
  52 races and classes, moved out of the bash generator's matrix. Each
  item sits in its slot by its own inventory type; a dual-wield pair is
  the same item in main and off hand; three linen bags (and a quiver for
  hunters) in `bags`; hunters' arrows in `ammo`. The generator, now Lua,
  reads the profile and writes the same 581 rows (race, class, item,
  amount) as before; only the rows' notes changed (still starting
  "vanilla-148h-"), and nothing reads those beyond the prefix. The first-
  login hook (148k) and the bot gearing patch (B025) read the database
  rows, so they are unchanged.

A character's spec is the talent tree holding most of its points, read
from the talents it has (`lib/gearsets.lua`, ties to the leftmost tree);
a character with no points has no spec, and a spec-keyed profile names it
rather than guessing. `.gearset <profile> <character>`, `.gearset
<profile> buddies <partner>`, and `.elite <partner>` (short for the
second) put a record on; bags go only into empty bag slots, ammunition is
added. `scripts/test-gearsets` (855 checks): the elite rule on every elite
item; every starter item exists, fits its slot and suits its class in the
vanilla world database; the starter SQL on disk is exactly what the
generator makes; the command in a stand-in world, with talents deciding
each buddy's spec. Not yet: the selected creature as a target (the mirror
image, 617f); seeing it work in game.

**Before that, 2026-10-04 (the first profile):** **Built and worn, 2026-10-04.** Seven outfit profiles, one per buddy type
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
| profile | name, keyed_by | text, "spec" or "class" | what the records are filed under |
| spec (or class) | talent tree id (TalentTab), or class id | integer | the races |
| race | race id | integer | the record: `items` (equipment slot integer to item id integer), `bags` (list of item ids), `ammo` (`item` integer, `count` integer) |

Owner, 2026-10-05: "it has to be *spec* profile and race. Not class,
though that is self-apparent" (a spec names its class), and bags, quiver
and ammo are part of a gearset ("sure"). A profile worn before talents
exist (the starter kit) is keyed by class instead; each profile says which.

Applied by chat command (game master): `.gearset <profile> <character>`,
`.gearset <profile> buddies <partner>`, and later the selected creature
(the mirror image). `.elite <partner>` stays as the short form of
`.gearset elite buddies <partner>`.

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

## Sub-issues (2026-10-05)

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 617r1 | shape-keyed-gearsets | None | Records found by class and talent shape (thirds per tree), race, level: a Ret paladin leaning Holy and one leaning Protection wear different gear |
| 617r2 | buddy-kit-from-a-gearset | 617r1 | A translator writes today's buddy gear rules as the `buddy-white` profile; profiles become a database table; the buddy module dresses new buddies from it; the live chooser goes |
| 617r3 | players-sorted-into-a-shape | 617r1 | Each character's nearest shape stored, updated at login and at each talent point; shape 7 (thirds) before level 10 or with no points |
| 617r4 | gearsets-on-creatures | None | The selected creature dressed in a record through the mirror image (617f) |
| 617r5 | gearset-gallery | 617r1, 173k | Pictures of every record on its race's model (random sex), to curate fashionable sets fast |

Execution order: `617r1 → 617r2 → (617r3 ∥ 617r5)`; 617r4 any time.

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

1. (Done) The profiles as data, keyed by spec (or class) then race, from
   the earlier lists by a one-off converter; one reader
   (`lib/gearsets.lua`) with the spec found from talents.
2. (Done) `gearset-command.lua`: `.gearset <profile> <character>`,
   `.gearset <profile> buddies <partner>`, `.elite <partner>`.
3. (Done) The starter-kit matrix moved into `vanilla-starter`; the
   generator (now Lua) reads it; the item rows are unchanged (compared
   row for row with the last bash output; the notes changed, so the file
   is not byte-identical).
4. The selected creature as a target (the mirror image, 617f).
5. In game: `.elite Growth` again; a new vanilla character still gets its
   kit (install E009 on vanilla).

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
4. (Answered 2026-10-05) Spec, then race (quote above).
5. (Answered 2026-10-05) Bags, quiver and ammo are part of a gearset.
6. A buddy's spec is read from its talents; a buddy whose points aren't
   spent yet (just made) has none and is skipped with a message. Should
   it use its talent plan (the roster's shape) instead until its points
   are spent?
2. Should a buddy's outfit come back after it is remade (617a6), or is it
   a one-time gift?
3. Do world drops that also fall in Molten Core (Lady Maye's Pendant)
   count as Molten Core?
