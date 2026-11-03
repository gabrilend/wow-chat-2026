-- MARKER_E074_REVERT basic-cloth-in-mulgore
DELETE FROM `npc_vendor` WHERE `entry` = 3074 AND `item` IN (2121, 3599, 2120, 2117, 3600, 2119) AND `ExtendedCost` = 0;
UPDATE `creature_template` SET `subname` = 'Leather Armor Merchant' WHERE `entry` = 3074;
