DELETE FROM `npc_vendor` WHERE `entry` = 3074 AND `item` IN (2121, 3599, 2120, 2117, 3600, 2119) AND `ExtendedCost` = 0;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`) VALUES
    (3074, 0, 2121, 0, 0, 0),   -- Thin Cloth Armor
    (3074, 0, 3599, 0, 0, 0),   -- Thin Cloth Belt
    (3074, 0, 2120, 0, 0, 0),   -- Thin Cloth Pants
    (3074, 0, 2117, 0, 0, 0),   -- Thin Cloth Shoes
    (3074, 0, 3600, 0, 0, 0),   -- Thin Cloth Bracers
    (3074, 0, 2119, 0, 0, 0);   -- Thin Cloth Gloves
UPDATE `creature_template` SET `subname` = 'Cloth & Leather Merchant' WHERE `entry` = 3074;
