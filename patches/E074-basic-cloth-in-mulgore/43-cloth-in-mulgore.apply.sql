-- E074 basic-cloth-in-mulgore (issue 617a4a): Camp Narache's armour merchant sells cloth too.
-- Written by hand, 2026-10-27. Basic's starting valleys take any race of the side
-- (155d), and Mulgore alone sold no cloth: tauren could not be priests, mages or
-- warlocks, so its leather merchant was enough. Varia Hardhide (3074) gets the
-- Thin Cloth set every other zone's cloth and leather merchant sells at level 1,
-- and the title to say so (the owner: "let's change her to say "cloth and leather
-- merchant" instead"; the wording of Eversong's Vara, 16186).
-- Re-runnable: the rows are put in place whether or not they were there.
DELETE FROM `npc_vendor` WHERE `entry` = 3074 AND `item` IN (2121, 3599, 2120, 2117, 3600, 2119) AND `ExtendedCost` = 0;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`) VALUES
    (3074, 0, 2121, 0, 0, 0),   -- Thin Cloth Armor
    (3074, 0, 3599, 0, 0, 0),   -- Thin Cloth Belt
    (3074, 0, 2120, 0, 0, 0),   -- Thin Cloth Pants
    (3074, 0, 2117, 0, 0, 0),   -- Thin Cloth Shoes
    (3074, 0, 3600, 0, 0, 0),   -- Thin Cloth Bracers
    (3074, 0, 2119, 0, 0, 0);   -- Thin Cloth Gloves
UPDATE `creature_template` SET `subname` = 'Cloth & Leather Merchant' WHERE `entry` = 3074;
