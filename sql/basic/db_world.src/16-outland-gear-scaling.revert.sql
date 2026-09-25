-- MARKER_E031_REVERT basic-outland-gear-scaling
-- ============================================================================
-- 16-outland-gear-scaling.sql (issues 155k, 155f) — REVERT SOURCE
-- ============================================================================
-- Put every scaled item's saved columns back. Required level only where this
-- file lowered it (saved value > 60); the dungeon gear 155f lowered is saved
-- here as 60 and put back by 155f's own revert, whichever runs first.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_155k_item_backup` (PRIMARY KEY (`entry`))
SELECT `entry`, `ItemLevel`, `RequiredLevel`, `bonding`, `armor`, `block`,
       `dmg_min1`, `dmg_max1`, `dmg_min2`, `dmg_max2`,
       `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`,
       `stat_value1`, `stat_value2`, `stat_value3`, `stat_value4`, `stat_value5`,
       `stat_value6`, `stat_value7`, `stat_value8`, `stat_value9`, `stat_value10`
FROM `item_template` LIMIT 0;

UPDATE `item_template` i JOIN `basic_155k_item_backup` b ON b.`entry` = i.`entry`
SET i.`ItemLevel` = b.`ItemLevel`, i.`bonding` = b.`bonding`, i.`armor` = b.`armor`, i.`block` = b.`block`,
    i.`dmg_min1` = b.`dmg_min1`, i.`dmg_max1` = b.`dmg_max1`, i.`dmg_min2` = b.`dmg_min2`, i.`dmg_max2` = b.`dmg_max2`,
    i.`holy_res` = b.`holy_res`, i.`fire_res` = b.`fire_res`, i.`nature_res` = b.`nature_res`,
    i.`frost_res` = b.`frost_res`, i.`shadow_res` = b.`shadow_res`, i.`arcane_res` = b.`arcane_res`,
    i.`stat_value1` = b.`stat_value1`, i.`stat_value2` = b.`stat_value2`, i.`stat_value3` = b.`stat_value3`,
    i.`stat_value4` = b.`stat_value4`, i.`stat_value5` = b.`stat_value5`, i.`stat_value6` = b.`stat_value6`,
    i.`stat_value7` = b.`stat_value7`, i.`stat_value8` = b.`stat_value8`, i.`stat_value9` = b.`stat_value9`,
    i.`stat_value10` = b.`stat_value10`;
UPDATE `item_template` i JOIN `basic_155k_item_backup` b ON b.`entry` = i.`entry`
SET i.`RequiredLevel` = b.`RequiredLevel` WHERE b.`RequiredLevel` > 60;

DROP TABLE `basic_155k_item_backup`;
DROP TABLE IF EXISTS `basic_155k_items`;
DROP TABLE IF EXISTS `basic_155k_dungeon_targets`;
DROP TABLE IF EXISTS `tmp_155f_script_ids`;   -- working tables, in case an apply stopped part-way
DROP TABLE IF EXISTS `tmp_155k_dsrc`;
DROP TABLE IF EXISTS `tmp_155k_step`;
DROP TABLE IF EXISTS `tmp_155k_ditems`;
DROP TABLE IF EXISTS `tmp_155k_wsrc`;
DROP TABLE IF EXISTS `tmp_155k_wstep`;
DROP TABLE IF EXISTS `tmp_155k_witems`;

-- ============================================================================
-- End of 16-outland-gear-scaling.sql (revert)
-- ============================================================================
