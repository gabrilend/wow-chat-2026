--------------------------------------------------------------------------------
-- data/gearsets/elite.lua (issue 617r) - a gearset profile
--
-- The bannermen of the Horde and the Alliance: full Tier 1 and Molten Core
-- or classic-dungeon outfits, first made for Growth's party (owner,
-- 2026-10-04). Nothing from Onyxia, Zul'Gurub, Blackwing Lair or later, and no
-- PvP gear: scripts/test-gearsets holds every item to that rule against the
-- world database. Keyed by spec (talent tree id), then race.
--
-- Made from the earlier lists by scripts/convert-to-gearsets (2026-10-05);
-- edited by hand from here on. Shape: lib/gearsets.info.md.
--------------------------------------------------------------------------------

return {
    name     = "elite",
    keyed_by = "spec",
    records  = {
        [61] = {   -- Mage: Frost
            [8] = {   -- Troll
                items = {
                    [ 0] = 16795,   -- head      Arcanist Crown
                    [ 1] = 17109,   -- neck      Choker of Enlightenment
                    [ 2] = 16797,   -- shoulders Arcanist Mantle
                    [ 4] = 16798,   -- chest     Arcanist Robes
                    [ 5] = 16802,   -- waist     Arcanist Belt
                    [ 6] = 16796,   -- legs      Arcanist Leggings
                    [ 7] = 16800,   -- feet      Arcanist Boots
                    [ 8] = 16799,   -- wrists    Arcanist Bindings
                    [ 9] = 16801,   -- hands     Arcanist Gloves
                    [10] = 19147,   -- finger    Ring of Spell Power
                    [11] = 17110,   -- finger    Seal of the Archmagus
                    [12] = 18820,   -- trinket   Talisman of Ephemeral Power
                    [13] = 12930,   -- trinket   Briarwood Reed
                    [14] = 18811,   -- back      Fireproof Cloak
                    [15] = 17103,   -- main hand Azuresong Mageblade
                    [16] = 19142,   -- off hand  Fire Runed Grimoire
                    [17] = 17077,   -- ranged    Crimson Shocker
                },
            },
        },
        [161] = {   -- Warrior: Arms
            [6] = {   -- Tauren
                items = {
                    [ 0] = 16866,   -- head      Helm of Might
                    [ 1] = 12929,   -- neck      Emberfury Talisman
                    [ 2] = 16868,   -- shoulders Pauldrons of Might
                    [ 4] = 16865,   -- chest     Breastplate of Might
                    [ 5] = 16864,   -- waist     Belt of Might
                    [ 6] = 16867,   -- legs      Legplates of Might
                    [ 7] = 16862,   -- feet      Sabatons of Might
                    [ 8] = 16861,   -- wrists    Bracers of Might
                    [ 9] = 16863,   -- hands     Gauntlets of Might
                    [10] = 18821,   -- finger    Quick Strike Ring
                    [11] = 13098,   -- finger    Painweaver Band
                    [12] = 11815,   -- trinket   Hand of Justice
                    [13] = 22321,   -- trinket   Heart of Wyrmthalak
                    [14] = 13340,   -- back      Cape of the Black Baron
                    [15] = 18822,   -- main hand Obsidian Edged Blade
                    [17] = 17069,   -- ranged    Striker's Mark
                },
            },
        },
        [163] = {   -- Warrior: Protection
            [8] = {   -- Troll
                items = {
                    [ 0] = 16866,   -- head      Helm of Might
                    [ 1] = 17065,   -- neck      Medallion of Steadfast Might
                    [ 2] = 16868,   -- shoulders Pauldrons of Might
                    [ 4] = 16865,   -- chest     Breastplate of Might
                    [ 5] = 16864,   -- waist     Belt of Might
                    [ 6] = 16867,   -- legs      Legplates of Might
                    [ 7] = 16862,   -- feet      Sabatons of Might
                    [ 8] = 16861,   -- wrists    Bracers of Might
                    [ 9] = 16863,   -- hands     Gauntlets of Might
                    [10] = 18879,   -- finger    Heavy Dark Iron Ring
                    [11] = 11669,   -- finger    Naglering
                    [12] = 11810,   -- trinket   Force of Will
                    [13] = 18370,   -- trinket   Vigilance Charm
                    [14] = 13397,   -- back      Stoneskin Gargoyle Cape
                    [15] = 18832,   -- main hand Brutality Blade
                    [16] = 17066,   -- off hand  Drillborer Disk
                    [17] = 17072,   -- ranged    Blastershot Launcher
                },
            },
        },
        [261] = {   -- Shaman: Elemental
            [2] = {   -- Orc
                items = {
                    [ 0] = 16842,   -- head      Earthfury Helmet
                    [ 1] = 17109,   -- neck      Choker of Enlightenment
                    [ 2] = 16844,   -- shoulders Earthfury Epaulets
                    [ 4] = 16841,   -- chest     Earthfury Vestments
                    [ 5] = 16838,   -- waist     Earthfury Belt
                    [ 6] = 16843,   -- legs      Earthfury Legguards
                    [ 7] = 16837,   -- feet      Earthfury Boots
                    [ 8] = 16840,   -- wrists    Earthfury Bracers
                    [ 9] = 16839,   -- hands     Earthfury Gauntlets
                    [10] = 19147,   -- finger    Ring of Spell Power
                    [11] = 17110,   -- finger    Seal of the Archmagus
                    [12] = 18820,   -- trinket   Talisman of Ephemeral Power
                    [13] = 12930,   -- trinket   Briarwood Reed
                    [14] = 18811,   -- back      Fireproof Cloak
                    [15] = 18842,   -- main hand Staff of Dominance
                    [17] = 23199,   -- ranged    Totem of the Storm
                },
            },
        },
        [262] = {   -- Shaman: Restoration
            [6] = {   -- Tauren
                items = {
                    [ 0] = 16842,   -- head      Earthfury Helmet
                    [ 1] = 14558,   -- neck      Lady Maye's Pendant
                    [ 2] = 16844,   -- shoulders Earthfury Epaulets
                    [ 4] = 16841,   -- chest     Earthfury Vestments
                    [ 5] = 16838,   -- waist     Earthfury Belt
                    [ 6] = 16843,   -- legs      Earthfury Legguards
                    [ 7] = 16837,   -- feet      Earthfury Boots
                    [ 8] = 16840,   -- wrists    Earthfury Bracers
                    [ 9] = 16839,   -- hands     Earthfury Gauntlets
                    [10] = 19140,   -- finger    Cauterizing Band
                    [11] = 13001,   -- finger    Maiden's Circle
                    [12] = 11819,   -- trinket   Second Wind
                    [13] = 18371,   -- trinket   Mindtap Talisman
                    [14] = 18811,   -- back      Fireproof Cloak
                    [15] = 17105,   -- main hand Aurastone Hammer
                    [16] = 18485,   -- off hand  Observer's Shield
                    [17] = 23200,   -- ranged    Totem of Sustaining
                },
            },
        },
        [283] = {   -- Druid: Balance
            [6] = {   -- Tauren
                items = {
                    [ 0] = 16834,   -- head      Cenarion Helm
                    [ 1] = 17109,   -- neck      Choker of Enlightenment
                    [ 2] = 16836,   -- shoulders Cenarion Spaulders
                    [ 4] = 16833,   -- chest     Cenarion Vestments
                    [ 5] = 16828,   -- waist     Cenarion Belt
                    [ 6] = 16835,   -- legs      Cenarion Leggings
                    [ 7] = 16829,   -- feet      Cenarion Boots
                    [ 8] = 16830,   -- wrists    Cenarion Bracers
                    [ 9] = 16831,   -- hands     Cenarion Gloves
                    [10] = 19147,   -- finger    Ring of Spell Power
                    [11] = 13283,   -- finger    Magus Ring
                    [12] = 18820,   -- trinket   Talisman of Ephemeral Power
                    [13] = 22268,   -- trinket   Draconic Infused Emblem
                    [14] = 18389,   -- back      Cloak of the Cosmos
                    [15] = 18842,   -- main hand Staff of Dominance
                    [17] = 23197,   -- ranged    Idol of the Moon
                },
            },
        },
        [381] = {   -- Paladin: Retribution
            [10] = {   -- Blood Elf
                items = {
                    [ 0] = 16854,   -- head      Lawbringer Helm
                    [ 1] = 12929,   -- neck      Emberfury Talisman
                    [ 2] = 16856,   -- shoulders Lawbringer Spaulders
                    [ 4] = 16853,   -- chest     Lawbringer Chestguard
                    [ 5] = 16858,   -- waist     Lawbringer Belt
                    [ 6] = 16855,   -- legs      Lawbringer Legplates
                    [ 7] = 16859,   -- feet      Lawbringer Boots
                    [ 8] = 16857,   -- wrists    Lawbringer Bracers
                    [ 9] = 16860,   -- hands     Lawbringer Gauntlets
                    [10] = 18821,   -- finger    Quick Strike Ring
                    [11] = 13098,   -- finger    Painweaver Band
                    [12] = 11815,   -- trinket   Hand of Justice
                    [13] = 22321,   -- trinket   Heart of Wyrmthalak
                    [14] = 13340,   -- back      Cape of the Black Baron
                    [15] = 18822,   -- main hand Obsidian Edged Blade
                    [17] = 23203,   -- ranged    Libram of Fervor
                },
            },
        },
    },
}
