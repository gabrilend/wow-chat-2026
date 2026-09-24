-- MARKER_E024_REVERT basic-outland-dungeons-64
-- ============================================================================
-- 09-outland-dungeons-64.sql (issue 155f) — REVERT SOURCE
-- ============================================================================
-- Restore every creature level the apply form changed, from the backup it
-- filled first, then drop the helper tables.
-- ============================================================================

UPDATE `creature_template` t
JOIN `basic_155f_level_backup` b ON b.`entry` = t.`entry`
SET t.`minlevel` = b.`minlevel`, t.`maxlevel` = b.`maxlevel`;

UPDATE `item_template` i
JOIN `basic_155f_item_backup` b ON b.`entry` = i.`entry`
SET i.`RequiredLevel` = b.`RequiredLevel`;

DROP TABLE IF EXISTS `basic_155f_level_backup`;
DROP TABLE IF EXISTS `basic_155f_item_backup`;
DROP TABLE IF EXISTS `tmp_155f_loot`;
DROP TABLE IF EXISTS `tmp_155f_ref_step`;
DROP TABLE IF EXISTS `tmp_155f_found`;     -- working tables, in case an apply stopped part-way
DROP TABLE IF EXISTS `tmp_155f_set`;
DROP TABLE IF EXISTS `tmp_155f_outside`;
DROP TABLE IF EXISTS `tmp_155f_inside`;
DROP TABLE IF EXISTS `basic_155f_maps`;
-- (basic_155f_access_backup existed only in the first, heroic-mode draft of
-- this file, which never reached a database.)

-- ============================================================================
-- End of 09-outland-dungeons-64.sql (revert)
-- ============================================================================
