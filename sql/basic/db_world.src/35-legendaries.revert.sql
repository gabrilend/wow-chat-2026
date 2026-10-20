-- MARKER_E054_REVERT
DELETE FROM `item_template` WHERE `entry` BETWEEN 1820001 AND 1829999;
DELETE FROM `reference_loot_template` WHERE `Entry` = 1820000;
DELETE FROM `creature_loot_template` WHERE `Reference` = 1820000;
DELETE FROM `spell_dbc` WHERE `ID` IN (41435, 71904, 71905, 73422);
