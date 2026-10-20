-- MARKER_E024_REVERT basic-outland-dungeons-64

UPDATE `creature_template` t
JOIN `basic_155f_level_backup` b ON b.`entry` = t.`entry`
SET t.`minlevel` = b.`minlevel`, t.`maxlevel` = b.`maxlevel`;

UPDATE `item_template` i
JOIN `basic_155f_item_backup` b ON b.`entry` = i.`entry`
SET i.`RequiredLevel` = b.`RequiredLevel`;

CREATE TABLE IF NOT EXISTS `basic_155f_access_backup` (
  `map_id` int unsigned NOT NULL, `difficulty` tinyint unsigned NOT NULL, `min_level` tinyint unsigned NOT NULL,
  PRIMARY KEY (`map_id`, `difficulty`));
UPDATE `dungeon_access_template` a
JOIN `basic_155f_access_backup` b ON b.`map_id` = a.`map_id` AND b.`difficulty` = a.`difficulty`
SET a.`min_level` = b.`min_level`;

CREATE TABLE IF NOT EXISTS `basic_155f_requirement_backup` LIKE `dungeon_access_requirements`;
INSERT IGNORE INTO `dungeon_access_requirements` SELECT * FROM `basic_155f_requirement_backup`;

DROP TABLE IF EXISTS `basic_155f_level_backup`;
DROP TABLE IF EXISTS `basic_155f_item_backup`;
DROP TABLE IF EXISTS `basic_155f_access_backup`;
DROP TABLE IF EXISTS `basic_155f_requirement_backup`;
DROP TABLE IF EXISTS `basic_155f_templates`;
DROP TABLE IF EXISTS `tmp_155f_script_ids`;
DROP TABLE IF EXISTS `tmp_155f_loot`;
DROP TABLE IF EXISTS `tmp_155f_ref_step`;
DROP TABLE IF EXISTS `tmp_155f_found`;     -- working tables, in case an apply stopped part-way
DROP TABLE IF EXISTS `tmp_155f_set`;
DROP TABLE IF EXISTS `tmp_155f_outside`;
DROP TABLE IF EXISTS `tmp_155f_inside`;
DROP TABLE IF EXISTS `basic_155f_maps`;

