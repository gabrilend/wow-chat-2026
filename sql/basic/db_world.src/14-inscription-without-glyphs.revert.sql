-- MARKER_E029_REVERT basic-inscription-without-glyphs
-- ============================================================================
-- 14-inscription-without-glyphs.sql (issue 155o) — REVERT SOURCE
-- ============================================================================
-- Put glyph recipes back, restore scroll and vellum recipe ranks (removing
-- the rows this file put back; 12-outland-without-tradeskills's revert
-- restores those itself), restore scroll required levels and the stacking
-- groups, then drop the backups. Runs before E027's revert.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_155o_glyph_trainer_spell` LIKE `trainer_spell`;
CREATE TABLE IF NOT EXISTS `basic_155o_scroll_rank` (`TrainerId` int unsigned NOT NULL, `SpellId` int unsigned NOT NULL, `ReqSkillRank` int unsigned NOT NULL, PRIMARY KEY (`TrainerId`, `SpellId`));
CREATE TABLE IF NOT EXISTS `basic_155o_scroll_added` (`TrainerId` int unsigned NOT NULL, `SpellId` int unsigned NOT NULL, PRIMARY KEY (`TrainerId`, `SpellId`));
CREATE TABLE IF NOT EXISTS `basic_155o_scroll_items` (`entry` int unsigned NOT NULL, `RequiredLevel` tinyint unsigned NOT NULL, PRIMARY KEY (`entry`));
CREATE TABLE IF NOT EXISTS `basic_155o_spell_group` LIKE `spell_group`;

INSERT IGNORE INTO `trainer_spell` SELECT * FROM `basic_155o_glyph_trainer_spell`;
DELETE ts FROM `trainer_spell` ts JOIN `basic_155o_scroll_added` a ON a.`TrainerId` = ts.`TrainerId` AND a.`SpellId` = ts.`SpellId`;
UPDATE `trainer_spell` ts JOIN `basic_155o_scroll_rank` r ON r.`TrainerId` = ts.`TrainerId` AND r.`SpellId` = ts.`SpellId`
SET ts.`ReqSkillRank` = r.`ReqSkillRank`;
UPDATE `item_template` i JOIN `basic_155o_scroll_items` b ON b.`entry` = i.`entry` SET i.`RequiredLevel` = b.`RequiredLevel`;
INSERT IGNORE INTO `spell_group` SELECT * FROM `basic_155o_spell_group`;

DROP TABLE `basic_155o_glyph_trainer_spell`;
DROP TABLE `basic_155o_scroll_rank`;
DROP TABLE `basic_155o_scroll_added`;
DROP TABLE `basic_155o_scroll_items`;
DROP TABLE `basic_155o_spell_group`;
DROP TABLE IF EXISTS `tmp_155o_glyph_spells`;   -- working tables, in case an apply stopped part-way
DROP TABLE IF EXISTS `tmp_155o_scroll_spells`;

-- ============================================================================
-- End of 14-inscription-without-glyphs.sql (revert)
-- ============================================================================
