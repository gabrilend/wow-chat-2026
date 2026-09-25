-- MARKER_E032_REVERT basic-outland-world-levels
-- ============================================================================
-- 17-outland-world-levels.sql (issue 155k) — REVERT SOURCE
-- ============================================================================
-- Put the raised Outland world creatures back to their stock levels.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_155k_level_backup` (`entry` int unsigned NOT NULL, `minlevel` tinyint unsigned NOT NULL, `maxlevel` tinyint unsigned NOT NULL, PRIMARY KEY (`entry`));
UPDATE `creature_template` t JOIN `basic_155k_level_backup` b ON b.`entry` = t.`entry`
SET t.`minlevel` = b.`minlevel`, t.`maxlevel` = b.`maxlevel`;
DROP TABLE `basic_155k_level_backup`;
DROP TABLE IF EXISTS `basic_155k_world_templates`;
DROP TABLE IF EXISTS `tmp_155k_factions`;     -- working table, in case an apply stopped part-way

-- ============================================================================
-- End of 17-outland-world-levels.sql (revert)
-- ============================================================================
