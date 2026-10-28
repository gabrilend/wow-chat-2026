--------------------------------------------------------------------------------
-- data/gearsets/travel-bags.lua - a gearset profile of bags only
--
-- Four Mageweave Bags (10050, 12 slots, no level) into a character's empty
-- bag slots, whatever its class; nothing worn is touched (no items). Made
-- 2026-10-27 for Feldowinn's buddies, whose bag slots were all empty (their
-- kit gives bags like their owner's, and she wore none), so their
-- backpacks filled and a won pair of bracers had nowhere to go (the owner:
-- "can you give them all 4 12 slot backs and equip them please?"). Put on
-- with ".gearset travel-bags buddies <partner>" or
-- ".gearset travel-bags <character>". Shape: lib/gearsets.info.md.
--------------------------------------------------------------------------------

local FOUR = { 10050, 10050, 10050, 10050 }   -- Mageweave Bag x4

return {
    name     = "travel-bags",
    keys     = { "class" },
    records  = {
        [ 1] = { items = {}, bags = FOUR },   -- warrior
        [ 2] = { items = {}, bags = FOUR },   -- paladin
        [ 3] = { items = {}, bags = FOUR },   -- hunter
        [ 4] = { items = {}, bags = FOUR },   -- rogue
        [ 5] = { items = {}, bags = FOUR },   -- priest
        [ 6] = { items = {}, bags = FOUR },   -- death knight
        [ 7] = { items = {}, bags = FOUR },   -- shaman
        [ 8] = { items = {}, bags = FOUR },   -- mage
        [ 9] = { items = {}, bags = FOUR },   -- warlock
        [11] = { items = {}, bags = FOUR },   -- druid
    },
}
