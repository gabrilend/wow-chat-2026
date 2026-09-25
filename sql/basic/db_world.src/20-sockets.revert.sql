-- MARKER_E035_REVERT basic-sockets
-- ============================================================================
-- 20-sockets.sql (issue 155p, stage 3) — REVERT SOURCE
-- ============================================================================
-- Put every socketed item's saved sockets, bonus and stats back.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_155p_socket_backup` (PRIMARY KEY (`entry`))
SELECT `entry`, `socketColor_1`, `socketColor_2`, `socketColor_3`, `socketBonus`,
       `stat_value1`, `stat_value2`, `stat_value3`, `stat_value4`, `stat_value5`,
       `stat_value6`, `stat_value7`, `stat_value8`, `stat_value9`, `stat_value10`
FROM `item_template` LIMIT 0;
UPDATE `item_template` i JOIN `basic_155p_socket_backup` b ON b.`entry` = i.`entry` SET
  i.`socketColor_1` = b.`socketColor_1`, i.`socketColor_2` = b.`socketColor_2`, i.`socketColor_3` = b.`socketColor_3`,
  i.`socketBonus` = b.`socketBonus`,
  i.`stat_value1` = b.`stat_value1`, i.`stat_value2` = b.`stat_value2`, i.`stat_value3` = b.`stat_value3`,
  i.`stat_value4` = b.`stat_value4`, i.`stat_value5` = b.`stat_value5`, i.`stat_value6` = b.`stat_value6`,
  i.`stat_value7` = b.`stat_value7`, i.`stat_value8` = b.`stat_value8`, i.`stat_value9` = b.`stat_value9`,
  i.`stat_value10` = b.`stat_value10`;
DROP TABLE `basic_155p_socket_backup`;
DROP TABLE IF EXISTS `basic_155p_socketed`;
-- working tables, in case an apply stopped part-way
DROP TABLE IF EXISTS `tmp_155p_bonus`;
DROP TABLE IF EXISTS `tmp_155p_dungeons`;
DROP TABLE IF EXISTS `tmp_155p_capitals`;
DROP TABLE IF EXISTS `tmp_155p_slot`;
DROP TABLE IF EXISTS `tmp_155p_green`;
DROP TABLE IF EXISTS `tmp_155p_items`;
DROP TABLE IF EXISTS `tmp_155p_src`;
DROP TABLE IF EXISTS `tmp_155p_step`;
DROP TABLE IF EXISTS `tmp_155p_loot`;
DROP TABLE IF EXISTS `tmp_155p_table`;
DROP TABLE IF EXISTS `tmp_155p_stats`;
DROP TABLE IF EXISTS `tmp_155p_ranked`;
DROP TABLE IF EXISTS `tmp_155p_sockets`;
DROP TABLE IF EXISTS `tmp_155p_turn`;
DROP TABLE IF EXISTS `tmp_155p_pick`;

-- ============================================================================
-- End of 20-sockets.sql (revert)
-- ============================================================================
