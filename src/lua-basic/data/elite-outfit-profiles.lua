--------------------------------------------------------------------------------
-- data/elite-outfit-profiles.lua (issue 617r)
--
-- Not named elite-outfits.lua: the Lua engine loads every .lua file under
-- lua_scripts/ and refuses a second file with the same name in another
-- folder, so a data file sharing the command script's name kept the
-- command from loading (2026-10-04; scripts/test-lua-unique-names).
--
-- Elites: the bannermen of the Horde and the Alliance. One outfit profile
-- per buddy type (race, class, role), worn as a full set: the class's Tier 1
-- set and Molten Core or classic-dungeon pieces everywhere else. Nothing
-- from Onyxia, Zul'Gurub, Blackwing Lair or later, and no PvP gear (owner,
-- 2026-10-04). scripts/test-elite-outfits holds every item here to that
-- rule against the world database; change an item, run the test.
--
-- Shape, per elite (keyed by its name):
--   race   integer  race id (2 orc, 6 tauren, 8 troll, 10 blood elf)
--   class  integer  class id (1 warrior, 2 paladin, 7 shaman, 8 mage, 11 druid)
--   role   integer  0 damage, 1 tank, 2 healer (buddy_roster.role)
--   items  table    equipment slot (integer) -> item id (integer)
--
-- Equipment slots: 0 head, 1 neck, 2 shoulders, 4 chest, 5 waist, 6 legs,
-- 7 feet, 8 wrists, 9 hands, 10 and 11 fingers, 12 and 13 trinkets, 14 back,
-- 15 main hand, 16 off hand, 17 ranged or relic. 3 (shirt) and 18 (tabard)
-- are never listed: a buddy keeps its own.
--
-- First made for Growth's party (orcs, tauren, trolls), roughly matching
-- Growth's own Tier 1 and Molten Core gear. Later these also dress NPCs
-- through the mirror-image route (617f).
--------------------------------------------------------------------------------

-- the Tier 1 sets, shared by every elite of the class: slot -> item
local MIGHT     = { [0] = 16866, [2] = 16868, [4] = 16865, [5] = 16864, [6] = 16867, [7] = 16862, [8] = 16861, [9] = 16863 }
local CENARION  = { [0] = 16834, [2] = 16836, [4] = 16833, [5] = 16828, [6] = 16835, [7] = 16829, [8] = 16830, [9] = 16831 }
local ARCANIST  = { [0] = 16795, [2] = 16797, [4] = 16798, [5] = 16802, [6] = 16796, [7] = 16800, [8] = 16799, [9] = 16801 }
local LAWBRINGER = { [0] = 16854, [2] = 16856, [4] = 16853, [5] = 16858, [6] = 16855, [7] = 16859, [8] = 16857, [9] = 16860 }
local EARTHFURY = { [0] = 16842, [2] = 16844, [4] = 16841, [5] = 16838, [6] = 16843, [7] = 16837, [8] = 16840, [9] = 16839 }

-- {{{ local function outfit
-- A Tier 1 set plus the rest, as one slot -> item table.
local function outfit(set, rest)
    local items = {}
    for slot, item in pairs(set)  do items[slot] = item end
    for slot, item in pairs(rest) do items[slot] = item end
    return items
end
-- }}}

return {
    ["Tauren Warrior (damage)"] = { race = 6, class = 1, role = 0, items = outfit(MIGHT, {
        [1]  = 12929,   -- Emberfury Talisman
        [14] = 13340,   -- Cape of the Black Baron
        [10] = 18821,   -- Quick Strike Ring
        [11] = 13098,   -- Painweaver Band
        [12] = 11815,   -- Hand of Justice
        [13] = 22321,   -- Heart of Wyrmthalak
        [15] = 18822,   -- Obsidian Edged Blade (two-handed sword)
        [17] = 17069,   -- Striker's Mark (bow)
    }) },

    -- Talriah, Growth's slot-4 buddy (owner, 2026-10-04: "can you also
    -- equip Talriah, Growth's newest buddy-bot?"); Retribution plan
    ["Blood Elf Paladin (damage)"] = { race = 10, class = 2, role = 0, items = outfit(LAWBRINGER, {
        [1]  = 12929,   -- Emberfury Talisman
        [14] = 13340,   -- Cape of the Black Baron
        [10] = 18821,   -- Quick Strike Ring
        [11] = 13098,   -- Painweaver Band
        [12] = 11815,   -- Hand of Justice
        [13] = 22321,   -- Heart of Wyrmthalak
        [15] = 18822,   -- Obsidian Edged Blade (two-handed sword; Spinal Reaper drops nowhere in the rule)
        [17] = 23203,   -- Libram of Fervor
    }) },

    ["Troll Warrior (tank)"] = { race = 8, class = 1, role = 1, items = outfit(MIGHT, {
        [1]  = 17065,   -- Medallion of Steadfast Might
        [14] = 13397,   -- Stoneskin Gargoyle Cape
        [10] = 18879,   -- Heavy Dark Iron Ring
        [11] = 11669,   -- Naglering
        [12] = 11810,   -- Force of Will
        [13] = 18370,   -- Vigilance Charm
        [15] = 18832,   -- Brutality Blade (one-handed sword)
        [16] = 17066,   -- Drillborer Disk (shield)
        [17] = 17072,   -- Blastershot Launcher (gun)
    }) },

    ["Tauren Druid (damage)"] = { race = 6, class = 11, role = 0, items = outfit(CENARION, {
        [1]  = 17109,   -- Choker of Enlightenment
        [14] = 18389,   -- Cloak of the Cosmos
        [10] = 19147,   -- Ring of Spell Power
        [11] = 13283,   -- Magus Ring
        [12] = 18820,   -- Talisman of Ephemeral Power
        [13] = 22268,   -- Draconic Infused Emblem
        [15] = 18842,   -- Staff of Dominance
        [17] = 23197,   -- Idol of the Moon
    }) },

    ["Troll Mage (damage)"] = { race = 8, class = 8, role = 0, items = outfit(ARCANIST, {
        [1]  = 17109,   -- Choker of Enlightenment
        [14] = 18811,   -- Fireproof Cloak
        [10] = 19147,   -- Ring of Spell Power
        [11] = 17110,   -- Seal of the Archmagus
        [12] = 18820,   -- Talisman of Ephemeral Power
        [13] = 12930,   -- Briarwood Reed
        [15] = 17103,   -- Azuresong Mageblade (main-hand sword)
        [16] = 19142,   -- Fire Runed Grimoire (held in off hand)
        [17] = 17077,   -- Crimson Shocker (wand)
    }) },

    ["Orc Shaman (damage)"] = { race = 2, class = 7, role = 0, items = outfit(EARTHFURY, {
        [1]  = 17109,   -- Choker of Enlightenment
        [14] = 18811,   -- Fireproof Cloak
        [10] = 19147,   -- Ring of Spell Power
        [11] = 17110,   -- Seal of the Archmagus
        [12] = 18820,   -- Talisman of Ephemeral Power
        [13] = 12930,   -- Briarwood Reed
        [15] = 18842,   -- Staff of Dominance
        [17] = 23199,   -- Totem of the Storm
    }) },

    ["Tauren Shaman (healer)"] = { race = 6, class = 7, role = 2, items = outfit(EARTHFURY, {
        [1]  = 14558,   -- Lady Maye's Pendant
        [14] = 18811,   -- Fireproof Cloak
        [10] = 19140,   -- Cauterizing Band
        [11] = 13001,   -- Maiden's Circle
        [12] = 11819,   -- Second Wind
        [13] = 18371,   -- Mindtap Talisman
        [15] = 17105,   -- Aurastone Hammer (main-hand mace)
        [16] = 18485,   -- Observer's Shield
        [17] = 23200,   -- Totem of Sustaining
    }) },
}
