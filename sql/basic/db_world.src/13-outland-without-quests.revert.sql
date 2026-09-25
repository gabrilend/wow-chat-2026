-- MARKER_E028_REVERT basic-outland-without-quests
-- ============================================================================
-- 13-outland-without-quests.sql (issue 155l) — REVERT SOURCE
-- ============================================================================
-- Delete exactly the disables rows the apply added, put the Shattrath portal
-- back, drop the helper tables.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_155l_disabled` (`entry` int unsigned NOT NULL, PRIMARY KEY (`entry`));
CREATE TABLE IF NOT EXISTS `basic_155l_gameobject` LIKE `gameobject`;

DELETE d FROM `disables` d JOIN `basic_155l_disabled` b ON b.`entry` = d.`entry` WHERE d.`sourceType` = 1;
INSERT IGNORE INTO `gameobject` SELECT * FROM `basic_155l_gameobject`;

DROP TABLE `basic_155l_disabled`;
DROP TABLE `basic_155l_gameobject`;
DROP TABLE IF EXISTS `tmp_155l_quests`;   -- working tables, in case an apply stopped part-way
DROP TABLE IF EXISTS `tmp_155l_maps`;
DROP TABLE IF EXISTS `tmp_155l_areas`;

-- ============================================================================
-- End of 13-outland-without-quests.sql (revert)
-- ============================================================================
