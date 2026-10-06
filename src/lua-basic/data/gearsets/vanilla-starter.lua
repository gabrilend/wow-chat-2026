--------------------------------------------------------------------------------
-- data/gearsets/vanilla-starter.lua (issue 617r) - a gearset profile
--
-- The vanilla profile's level-20 starter kit (issue 148h): white armour by
-- class, a cape, the race-and-class weapons, three linen bags, a quiver and
-- arrows for hunters. Keyed by class (a new character has no spec yet), then
-- race. scripts/generate-vanilla-starting-equipment-sql turns it into the
-- rows every new vanilla character is given (adding the hearthstone).
--
-- Made from the earlier lists by scripts/convert-to-gearsets (2026-10-05);
-- edited by hand from here on. Shape: lib/gearsets.info.md.
--------------------------------------------------------------------------------

return {
    name     = "vanilla-starter",
    keyed_by = "class",
    records  = {
        [1] = {   -- Warrior
            [1] = {   -- Human
                items = {
                    [ 4] =  2153,   -- chest     Polished Scale Vest
                    [ 5] =  2148,   -- waist     Polished Scale Belt
                    [ 6] =  2152,   -- legs      Polished Scale Leggings
                    [ 7] =  2149,   -- feet      Polished Scale Boots
                    [ 8] =  2150,   -- wrists    Polished Scale Bracers
                    [ 9] =  2151,   -- hands     Polished Scale Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  1198,   -- main hand Claymore
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [2] = {   -- Orc
                items = {
                    [ 4] =  2153,   -- chest     Polished Scale Vest
                    [ 5] =  2148,   -- waist     Polished Scale Belt
                    [ 6] =  2152,   -- legs      Polished Scale Leggings
                    [ 7] =  2149,   -- feet      Polished Scale Boots
                    [ 8] =  2150,   -- wrists    Polished Scale Bracers
                    [ 9] =  2151,   -- hands     Polished Scale Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =   853,   -- main hand Hatchet
                    [16] =  2441,   -- off hand  Ringed Buckler
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [3] = {   -- Dwarf
                items = {
                    [ 4] =  2153,   -- chest     Polished Scale Vest
                    [ 5] =  2148,   -- waist     Polished Scale Belt
                    [ 6] =  2152,   -- legs      Polished Scale Leggings
                    [ 7] =  2149,   -- feet      Polished Scale Boots
                    [ 8] =  2150,   -- wrists    Polished Scale Bracers
                    [ 9] =  2151,   -- hands     Polished Scale Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] = 15810,   -- main hand Short Spear
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [4] = {   -- Night Elf
                items = {
                    [ 4] =  2153,   -- chest     Polished Scale Vest
                    [ 5] =  2148,   -- waist     Polished Scale Belt
                    [ 6] =  2152,   -- legs      Polished Scale Leggings
                    [ 7] =  2149,   -- feet      Polished Scale Boots
                    [ 8] =  2150,   -- wrists    Polished Scale Bracers
                    [ 9] =  2151,   -- hands     Polished Scale Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] = 15810,   -- main hand Short Spear
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [5] = {   -- Undead
                items = {
                    [ 4] =  2153,   -- chest     Polished Scale Vest
                    [ 5] =  2148,   -- waist     Polished Scale Belt
                    [ 6] =  2152,   -- legs      Polished Scale Leggings
                    [ 7] =  2149,   -- feet      Polished Scale Boots
                    [ 8] =  2150,   -- wrists    Polished Scale Bracers
                    [ 9] =  2151,   -- hands     Polished Scale Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =   926,   -- main hand Battle Axe
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [6] = {   -- Tauren
                items = {
                    [ 4] =  2153,   -- chest     Polished Scale Vest
                    [ 5] =  2148,   -- waist     Polished Scale Belt
                    [ 6] =  2152,   -- legs      Polished Scale Leggings
                    [ 7] =  2149,   -- feet      Polished Scale Boots
                    [ 8] =  2150,   -- wrists    Polished Scale Bracers
                    [ 9] =  2151,   -- hands     Polished Scale Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] = 15810,   -- main hand Short Spear
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [7] = {   -- Gnome
                items = {
                    [ 4] =  2153,   -- chest     Polished Scale Vest
                    [ 5] =  2148,   -- waist     Polished Scale Belt
                    [ 6] =  2152,   -- legs      Polished Scale Leggings
                    [ 7] =  2149,   -- feet      Polished Scale Boots
                    [ 8] =  2150,   -- wrists    Polished Scale Bracers
                    [ 9] =  2151,   -- hands     Polished Scale Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  2027,   -- main hand Scimitar
                    [16] =  2027,   -- off hand  Scimitar
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [8] = {   -- Troll
                items = {
                    [ 4] =  2153,   -- chest     Polished Scale Vest
                    [ 5] =  2148,   -- waist     Polished Scale Belt
                    [ 6] =  2152,   -- legs      Polished Scale Leggings
                    [ 7] =  2149,   -- feet      Polished Scale Boots
                    [ 8] =  2150,   -- wrists    Polished Scale Bracers
                    [ 9] =  2151,   -- hands     Polished Scale Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =   926,   -- main hand Battle Axe
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [11] = {   -- Draenei
                items = {
                    [ 4] =  2153,   -- chest     Polished Scale Vest
                    [ 5] =  2148,   -- waist     Polished Scale Belt
                    [ 6] =  2152,   -- legs      Polished Scale Leggings
                    [ 7] =  2149,   -- feet      Polished Scale Boots
                    [ 8] =  2150,   -- wrists    Polished Scale Bracers
                    [ 9] =  2151,   -- hands     Polished Scale Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  5580,   -- main hand Militia Hammer
                    [16] =  2445,   -- off hand  Large Metal Shield
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
        },
        [2] = {   -- Paladin
            [1] = {   -- Human
                items = {
                    [ 4] =  2153,   -- chest     Polished Scale Vest
                    [ 5] =  2148,   -- waist     Polished Scale Belt
                    [ 6] =  2152,   -- legs      Polished Scale Leggings
                    [ 7] =  2149,   -- feet      Polished Scale Boots
                    [ 8] =  2150,   -- wrists    Polished Scale Bracers
                    [ 9] =  2151,   -- hands     Polished Scale Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =   924,   -- main hand Maul
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [3] = {   -- Dwarf
                items = {
                    [ 4] =  2153,   -- chest     Polished Scale Vest
                    [ 5] =  2148,   -- waist     Polished Scale Belt
                    [ 6] =  2152,   -- legs      Polished Scale Leggings
                    [ 7] =  2149,   -- feet      Polished Scale Boots
                    [ 8] =  2150,   -- wrists    Polished Scale Bracers
                    [ 9] =  2151,   -- hands     Polished Scale Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =   925,   -- main hand Flail
                    [16] =  2445,   -- off hand  Large Metal Shield
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [10] = {   -- Blood Elf
                items = {
                    [ 4] =  2153,   -- chest     Polished Scale Vest
                    [ 5] =  2148,   -- waist     Polished Scale Belt
                    [ 6] =  2152,   -- legs      Polished Scale Leggings
                    [ 7] =  2149,   -- feet      Polished Scale Boots
                    [ 8] =  2150,   -- wrists    Polished Scale Bracers
                    [ 9] =  2151,   -- hands     Polished Scale Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  1198,   -- main hand Claymore
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [11] = {   -- Draenei
                items = {
                    [ 4] =  2153,   -- chest     Polished Scale Vest
                    [ 5] =  2148,   -- waist     Polished Scale Belt
                    [ 6] =  2152,   -- legs      Polished Scale Leggings
                    [ 7] =  2149,   -- feet      Polished Scale Boots
                    [ 8] =  2150,   -- wrists    Polished Scale Bracers
                    [ 9] =  2151,   -- hands     Polished Scale Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =   924,   -- main hand Maul
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
        },
        [3] = {   -- Hunter
            [2] = {   -- Orc
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  1292,   -- main hand Butcher's Cleaver
                    [16] =  1292,   -- off hand  Butcher's Cleaver
                    [17] =  3027,   -- ranged    Heavy Recurve Bow
                },
                bags  = { 11362, 4238, 4238, 4238 },   -- Medium Quiver, Linen Bag, Linen Bag, Linen Bag
                ammo  = { item = 2515, count = 200 },   -- Sharp Arrow
            },
            [3] = {   -- Dwarf
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =   926,   -- main hand Battle Axe
                    [17] =  3027,   -- ranged    Heavy Recurve Bow
                },
                bags  = { 11362, 4238, 4238, 4238 },   -- Medium Quiver, Linen Bag, Linen Bag, Linen Bag
                ammo  = { item = 2515, count = 200 },   -- Sharp Arrow
            },
            [4] = {   -- Night Elf
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =   922,   -- main hand Dacian Falx
                    [17] =  3027,   -- ranged    Heavy Recurve Bow
                },
                bags  = { 11362, 4238, 4238, 4238 },   -- Medium Quiver, Linen Bag, Linen Bag, Linen Bag
                ammo  = { item = 2515, count = 200 },   -- Sharp Arrow
            },
            [6] = {   -- Tauren
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  2030,   -- main hand Gnarled Staff
                    [17] =  3027,   -- ranged    Heavy Recurve Bow
                },
                bags  = { 11362, 4238, 4238, 4238 },   -- Medium Quiver, Linen Bag, Linen Bag, Linen Bag
                ammo  = { item = 2515, count = 200 },   -- Sharp Arrow
            },
            [8] = {   -- Troll
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  1292,   -- main hand Butcher's Cleaver
                    [16] =  1292,   -- off hand  Butcher's Cleaver
                    [17] =  3027,   -- ranged    Heavy Recurve Bow
                },
                bags  = { 11362, 4238, 4238, 4238 },   -- Medium Quiver, Linen Bag, Linen Bag, Linen Bag
                ammo  = { item = 2515, count = 200 },   -- Sharp Arrow
            },
            [10] = {   -- Blood Elf
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] = 15810,   -- main hand Short Spear
                    [17] =  3027,   -- ranged    Heavy Recurve Bow
                },
                bags  = { 11362, 4238, 4238, 4238 },   -- Medium Quiver, Linen Bag, Linen Bag, Linen Bag
                ammo  = { item = 2515, count = 200 },   -- Sharp Arrow
            },
            [11] = {   -- Draenei
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  1198,   -- main hand Claymore
                    [17] =  3027,   -- ranged    Heavy Recurve Bow
                },
                bags  = { 11362, 4238, 4238, 4238 },   -- Medium Quiver, Linen Bag, Linen Bag, Linen Bag
                ammo  = { item = 2515, count = 200 },   -- Sharp Arrow
            },
        },
        [4] = {   -- Rogue
            [1] = {   -- Human
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  3445,   -- main hand Ceremonial Knife
                    [16] =  3445,   -- off hand  Ceremonial Knife
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [2] = {   -- Orc
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =   925,   -- main hand Flail
                    [16] =  3445,   -- off hand  Ceremonial Knife
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [3] = {   -- Dwarf
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  3445,   -- main hand Ceremonial Knife
                    [16] =  3445,   -- off hand  Ceremonial Knife
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [4] = {   -- Night Elf
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  2027,   -- main hand Scimitar
                    [16] =  2027,   -- off hand  Scimitar
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [5] = {   -- Undead
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  2027,   -- main hand Scimitar
                    [16] =  3445,   -- off hand  Ceremonial Knife
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [7] = {   -- Gnome
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  3445,   -- main hand Ceremonial Knife
                    [16] =  3445,   -- off hand  Ceremonial Knife
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [8] = {   -- Troll
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  3445,   -- main hand Ceremonial Knife
                    [16] =  3445,   -- off hand  Ceremonial Knife
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [10] = {   -- Blood Elf
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  2027,   -- main hand Scimitar
                    [16] =  2027,   -- off hand  Scimitar
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
        },
        [5] = {   -- Priest
            [1] = {   -- Human
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  5580,   -- main hand Militia Hammer
                    [16] =  3422,   -- off hand  Beautiful Wildflowers
                    [17] =  5211,   -- ranged    Dusk Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [3] = {   -- Dwarf
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  5580,   -- main hand Militia Hammer
                    [16] =  3422,   -- off hand  Beautiful Wildflowers
                    [17] =  5211,   -- ranged    Dusk Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [4] = {   -- Night Elf
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  2030,   -- main hand Gnarled Staff
                    [17] =  5211,   -- ranged    Dusk Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [5] = {   -- Undead
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] = 23923,   -- main hand Amani Sacrificial Dagger
                    [16] =  3422,   -- off hand  Beautiful Wildflowers
                    [17] =  5211,   -- ranged    Dusk Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [8] = {   -- Troll
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =   925,   -- main hand Flail
                    [16] =  3422,   -- off hand  Beautiful Wildflowers
                    [17] =  5211,   -- ranged    Dusk Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [10] = {   -- Blood Elf
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] = 23923,   -- main hand Amani Sacrificial Dagger
                    [16] =  3422,   -- off hand  Beautiful Wildflowers
                    [17] =  5211,   -- ranged    Dusk Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [11] = {   -- Draenei
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  5580,   -- main hand Militia Hammer
                    [16] =  3422,   -- off hand  Beautiful Wildflowers
                    [17] =  5211,   -- ranged    Dusk Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
        },
        [7] = {   -- Shaman
            [2] = {   -- Orc
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  1197,   -- main hand Giant Mace
                    [17] = 46978,   -- ranged    Totem of the Earthen Ring
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [6] = {   -- Tauren
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  1197,   -- main hand Giant Mace
                    [17] = 46978,   -- ranged    Totem of the Earthen Ring
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [8] = {   -- Troll
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =   926,   -- main hand Battle Axe
                    [17] = 46978,   -- ranged    Totem of the Earthen Ring
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [11] = {   -- Draenei
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =   853,   -- main hand Hatchet
                    [16] =  2445,   -- off hand  Large Metal Shield
                    [17] = 46978,   -- ranged    Totem of the Earthen Ring
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
        },
        [8] = {   -- Mage
            [1] = {   -- Human
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  1159,   -- main hand Militia Quarterstaff
                    [17] =  5210,   -- ranged    Burning Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [5] = {   -- Undead
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  2030,   -- main hand Gnarled Staff
                    [17] =  5210,   -- ranged    Burning Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [7] = {   -- Gnome
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  2030,   -- main hand Gnarled Staff
                    [17] =  5210,   -- ranged    Burning Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [8] = {   -- Troll
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] = 23923,   -- main hand Amani Sacrificial Dagger
                    [16] = 19295,   -- off hand  Darkmoon Flower
                    [17] =  5210,   -- ranged    Burning Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [10] = {   -- Blood Elf
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  2027,   -- main hand Scimitar
                    [16] = 19295,   -- off hand  Darkmoon Flower
                    [17] =  5210,   -- ranged    Burning Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [11] = {   -- Draenei
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  2030,   -- main hand Gnarled Staff
                    [17] =  5210,   -- ranged    Burning Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
        },
        [9] = {   -- Warlock
            [1] = {   -- Human
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  2027,   -- main hand Scimitar
                    [16] = 19295,   -- off hand  Darkmoon Flower
                    [17] =  5211,   -- ranged    Dusk Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [2] = {   -- Orc
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  1159,   -- main hand Militia Quarterstaff
                    [17] =  5210,   -- ranged    Burning Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [5] = {   -- Undead
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  2027,   -- main hand Scimitar
                    [16] = 19295,   -- off hand  Darkmoon Flower
                    [17] =  5210,   -- ranged    Burning Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [7] = {   -- Gnome
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  2027,   -- main hand Scimitar
                    [16] = 19295,   -- off hand  Darkmoon Flower
                    [17] =  5211,   -- ranged    Dusk Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [10] = {   -- Blood Elf
                items = {
                    [ 4] =  2160,   -- chest     Padded Armor
                    [ 5] =  3591,   -- waist     Padded Belt
                    [ 6] =  2159,   -- legs      Padded Pants
                    [ 7] =  2156,   -- feet      Padded Boots
                    [ 8] =  3592,   -- wrists    Padded Bracers
                    [ 9] =  2158,   -- hands     Padded Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] = 23923,   -- main hand Amani Sacrificial Dagger
                    [16] = 19295,   -- off hand  Darkmoon Flower
                    [17] =  5210,   -- ranged    Burning Wand
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
        },
        [11] = {   -- Druid
            [4] = {   -- Night Elf
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  1159,   -- main hand Militia Quarterstaff
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
            [6] = {   -- Tauren
                items = {
                    [ 4] =  2141,   -- chest     Cuirboulli Vest
                    [ 5] =  2142,   -- waist     Cuirboulli Belt
                    [ 6] =  2146,   -- legs      Cuirboulli Pants
                    [ 7] =  2143,   -- feet      Cuirboulli Boots
                    [ 8] =  2144,   -- wrists    Cuirboulli Bracers
                    [ 9] =  2145,   -- hands     Cuirboulli Gloves
                    [14] =  2240,   -- back      Rugged Cape
                    [15] =  1159,   -- main hand Militia Quarterstaff
                },
                bags  = { 4238, 4238, 4238 },   -- Linen Bag, Linen Bag, Linen Bag
            },
        },
    },
}
