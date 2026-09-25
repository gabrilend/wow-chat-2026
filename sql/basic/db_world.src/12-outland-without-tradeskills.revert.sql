-- MARKER_E027_REVERT basic-outland-without-tradeskills
-- ============================================================================
-- 12-outland-without-tradeskills.sql (issue 155n) — REVERT SOURCE
-- ============================================================================
-- Put back every row the apply form saved and removed, restore skinning
-- loot and fishing skill, then drop the backups. Each backup is created if
-- missing, so the revert also runs on a database the apply never reached.
-- Order: pools and spawns before the rows that point at them.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_155n_gameobject` LIKE `gameobject`;
CREATE TABLE IF NOT EXISTS `basic_155n_gameobject_addon` LIKE `gameobject_addon`;
CREATE TABLE IF NOT EXISTS `basic_155n_game_event_gameobject` LIKE `game_event_gameobject`;
CREATE TABLE IF NOT EXISTS `basic_155n_pool_gameobject` LIKE `pool_gameobject`;
CREATE TABLE IF NOT EXISTS `basic_155n_creature` LIKE `creature`;
CREATE TABLE IF NOT EXISTS `basic_155n_creature_addon` LIKE `creature_addon`;
CREATE TABLE IF NOT EXISTS `basic_155n_game_event_creature` LIKE `game_event_creature`;
CREATE TABLE IF NOT EXISTS `basic_155n_pool_creature` LIKE `pool_creature`;
CREATE TABLE IF NOT EXISTS `basic_155n_pool_template` LIKE `pool_template`;
CREATE TABLE IF NOT EXISTS `basic_155n_pool_pool` LIKE `pool_pool`;
CREATE TABLE IF NOT EXISTS `basic_155n_game_event_pool` LIKE `game_event_pool`;
CREATE TABLE IF NOT EXISTS `basic_155n_skinloot` (`entry` int unsigned NOT NULL, `skinloot` int unsigned NOT NULL, PRIMARY KEY (`entry`));
CREATE TABLE IF NOT EXISTS `basic_155n_fishing_skill` (`entry` int unsigned NOT NULL, `skill` smallint DEFAULT NULL, PRIMARY KEY (`entry`));
CREATE TABLE IF NOT EXISTS `basic_155n_fishing_loot` LIKE `fishing_loot_template`;
CREATE TABLE IF NOT EXISTS `basic_155n_trainer_spell` LIKE `trainer_spell`;
CREATE TABLE IF NOT EXISTS `basic_155n_creature_loot` LIKE `creature_loot_template`;
CREATE TABLE IF NOT EXISTS `basic_155n_reference_loot` LIKE `reference_loot_template`;
CREATE TABLE IF NOT EXISTS `basic_155n_gameobject_loot` LIKE `gameobject_loot_template`;
CREATE TABLE IF NOT EXISTS `basic_155n_item_loot` LIKE `item_loot_template`;
CREATE TABLE IF NOT EXISTS `basic_155n_npc_vendor` LIKE `npc_vendor`;

INSERT IGNORE INTO `pool_template`          SELECT * FROM `basic_155n_pool_template`;
INSERT IGNORE INTO `pool_pool`              SELECT * FROM `basic_155n_pool_pool`;
INSERT IGNORE INTO `game_event_pool`        SELECT * FROM `basic_155n_game_event_pool`;
INSERT IGNORE INTO `gameobject`             SELECT * FROM `basic_155n_gameobject`;
INSERT IGNORE INTO `gameobject_addon`       SELECT * FROM `basic_155n_gameobject_addon`;
INSERT IGNORE INTO `game_event_gameobject`  SELECT * FROM `basic_155n_game_event_gameobject`;
INSERT IGNORE INTO `pool_gameobject`        SELECT * FROM `basic_155n_pool_gameobject`;
INSERT IGNORE INTO `creature`               SELECT * FROM `basic_155n_creature`;
INSERT IGNORE INTO `creature_addon`         SELECT * FROM `basic_155n_creature_addon`;
INSERT IGNORE INTO `game_event_creature`    SELECT * FROM `basic_155n_game_event_creature`;
INSERT IGNORE INTO `pool_creature`          SELECT * FROM `basic_155n_pool_creature`;

UPDATE `creature_template` t JOIN `basic_155n_skinloot` b ON b.`entry` = t.`entry` SET t.`skinloot` = b.`skinloot`;

DELETE f FROM `skill_fishing_base_level` f JOIN `basic_155n_fishing_skill` b ON b.`entry` = f.`entry` WHERE b.`skill` IS NULL;
UPDATE `skill_fishing_base_level` f JOIN `basic_155n_fishing_skill` b ON b.`entry` = f.`entry` SET f.`skill` = b.`skill` WHERE b.`skill` IS NOT NULL;
INSERT IGNORE INTO `fishing_loot_template`  SELECT * FROM `basic_155n_fishing_loot`;

INSERT IGNORE INTO `trainer_spell`          SELECT * FROM `basic_155n_trainer_spell`;
INSERT IGNORE INTO `creature_loot_template` SELECT * FROM `basic_155n_creature_loot`;
INSERT IGNORE INTO `reference_loot_template` SELECT * FROM `basic_155n_reference_loot`;
INSERT IGNORE INTO `gameobject_loot_template` SELECT * FROM `basic_155n_gameobject_loot`;
INSERT IGNORE INTO `item_loot_template`     SELECT * FROM `basic_155n_item_loot`;
INSERT IGNORE INTO `npc_vendor`             SELECT * FROM `basic_155n_npc_vendor`;

DROP TABLE `basic_155n_gameobject`;
DROP TABLE `basic_155n_gameobject_addon`;
DROP TABLE `basic_155n_game_event_gameobject`;
DROP TABLE `basic_155n_pool_gameobject`;
DROP TABLE `basic_155n_creature`;
DROP TABLE `basic_155n_creature_addon`;
DROP TABLE `basic_155n_game_event_creature`;
DROP TABLE `basic_155n_pool_creature`;
DROP TABLE `basic_155n_pool_template`;
DROP TABLE `basic_155n_pool_pool`;
DROP TABLE `basic_155n_game_event_pool`;
DROP TABLE `basic_155n_skinloot`;
DROP TABLE `basic_155n_fishing_skill`;
DROP TABLE `basic_155n_fishing_loot`;
DROP TABLE `basic_155n_trainer_spell`;
DROP TABLE `basic_155n_creature_loot`;
DROP TABLE `basic_155n_reference_loot`;
DROP TABLE `basic_155n_gameobject_loot`;
DROP TABLE `basic_155n_item_loot`;
DROP TABLE `basic_155n_npc_vendor`;
-- working tables, in case an apply stopped part-way
DROP TABLE IF EXISTS `tmp_155n_locks`;
DROP TABLE IF EXISTS `tmp_155n_areas`;
DROP TABLE IF EXISTS `tmp_155n_rank_spells`;
DROP TABLE IF EXISTS `tmp_155n_zones`;
DROP TABLE IF EXISTS `tmp_155n_maps`;
DROP TABLE IF EXISTS `tmp_155n_go`;
DROP TABLE IF EXISTS `tmp_155n_cr`;
DROP TABLE IF EXISTS `tmp_155n_pools`;
DROP TABLE IF EXISTS `tmp_155n_empty`;
DROP TABLE IF EXISTS `tmp_155n_recipes`;

-- ============================================================================
-- End of 12-outland-without-tradeskills.sql (revert)
-- ============================================================================
