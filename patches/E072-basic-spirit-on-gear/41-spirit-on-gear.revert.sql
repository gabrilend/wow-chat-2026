-- MARKER_E072_REVERT basic-spirit-on-gear


UPDATE `item_template` i JOIN `basic_155k2_backup` b ON b.`entry` = i.`entry` SET i.`stat_type1` = b.`stat_type1`, i.`stat_value1` = b.`stat_value1`, i.`stat_type2` = b.`stat_type2`, i.`stat_value2` = b.`stat_value2`, i.`stat_type3` = b.`stat_type3`, i.`stat_value3` = b.`stat_value3`, i.`stat_type4` = b.`stat_type4`, i.`stat_value4` = b.`stat_value4`, i.`stat_type5` = b.`stat_type5`, i.`stat_value5` = b.`stat_value5`, i.`stat_type6` = b.`stat_type6`, i.`stat_value6` = b.`stat_value6`, i.`stat_type7` = b.`stat_type7`, i.`stat_value7` = b.`stat_value7`, i.`stat_type8` = b.`stat_type8`, i.`stat_value8` = b.`stat_value8`, i.`stat_type9` = b.`stat_type9`, i.`stat_value9` = b.`stat_value9`, i.`stat_type10` = b.`stat_type10`, i.`stat_value10` = b.`stat_value10`;

DROP TABLE IF EXISTS `basic_155k2_backup`;
