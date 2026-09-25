-- MARKER_E033_REVERT basic-gem-supply
-- ============================================================================
-- 18-gem-supply.sql (issue 155p, stage 1) — REVERT SOURCE
-- ============================================================================
-- Remove this file's loot rows and reference tables; put back the Designs'
-- skill, the epic gems' binding and the Ashen Sack's stock contents.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_155p_design_skill` (`entry` int unsigned NOT NULL, `RequiredSkillRank` smallint unsigned NOT NULL, PRIMARY KEY (`entry`));
CREATE TABLE IF NOT EXISTS `basic_155p_bonding` (`entry` int unsigned NOT NULL, `bonding` tinyint unsigned NOT NULL, PRIMARY KEY (`entry`));
CREATE TABLE IF NOT EXISTS `basic_155p_sack` LIKE `item_loot_template`;

UPDATE `item_template` i JOIN `basic_155p_design_skill` b ON b.`entry` = i.`entry` SET i.`RequiredSkillRank` = b.`RequiredSkillRank`;
UPDATE `item_template` i JOIN `basic_155p_bonding` b ON b.`entry` = i.`entry` SET i.`bonding` = b.`bonding`;
DELETE FROM `item_loot_template` WHERE `Entry` = 49294 AND (SELECT COUNT(*) FROM `basic_155p_sack`) > 0;
INSERT IGNORE INTO `item_loot_template` SELECT * FROM `basic_155p_sack`;
-- trainer rows: ours out; the stock rows we replaced back. A row 155n's file
-- had removed is only put back once that file's own revert has run (its
-- backup table is gone), so reverting this file alone leaves 155n's state.
CREATE TABLE IF NOT EXISTS `basic_155p_trainer_added` (`TrainerId` int unsigned NOT NULL, `SpellId` int unsigned NOT NULL, PRIMARY KEY (`TrainerId`, `SpellId`));
CREATE TABLE IF NOT EXISTS `basic_155p_trainer_backup` LIKE `trainer_spell`;
DELETE ts FROM `trainer_spell` ts JOIN `basic_155p_trainer_added` a ON a.`TrainerId` = ts.`TrainerId` AND a.`SpellId` = ts.`SpellId`;
INSERT IGNORE INTO `trainer_spell` SELECT b.* FROM `basic_155p_trainer_backup` b
WHERE b.`ReqSkillRank` <= 300
   OR NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'basic_155n_trainer_spell');
DROP TABLE `basic_155p_trainer_added`;
DROP TABLE `basic_155p_trainer_backup`;
DELETE FROM `creature_loot_template`    WHERE `Item` BETWEEN 1550160 AND 1550200;
DELETE FROM `prospecting_loot_template` WHERE `Item` BETWEEN 1550160 AND 1550200;
DELETE FROM `reference_loot_template`   WHERE `Entry` BETWEEN 1550160 AND 1550173;

DROP TABLE `basic_155p_design_skill`;
DROP TABLE `basic_155p_bonding`;
DROP TABLE `basic_155p_sack`;
DROP TABLE IF EXISTS `tmp_155p_cuts`;     -- working tables, in case an apply stopped part-way
DROP TABLE IF EXISTS `tmp_155p_halves`;
DROP TABLE IF EXISTS `tmp_155p_gems`;
DROP TABLE IF EXISTS `tmp_155p_designs`;
DROP TABLE IF EXISTS `tmp_155p_ladder`;
DROP TABLE IF EXISTS `tmp_155p_loot`;
DROP TABLE IF EXISTS `tmp_155p_bosses`;
DROP TABLE IF EXISTS `tmp_155p_places`;
DROP TABLE IF EXISTS `tmp_155p_teach`;
DROP TABLE IF EXISTS `tmp_155p_ranked`;
DROP TABLE IF EXISTS `tmp_155p_trainers`;

-- ============================================================================
-- End of 18-gem-supply.sql (revert)
-- ============================================================================
