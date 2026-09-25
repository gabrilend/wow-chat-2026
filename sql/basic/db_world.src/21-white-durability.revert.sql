-- MARKER_E036_REVERT basic-white-durability
-- ============================================================================
-- 21-white-durability.sql (issue 155p) — REVERT SOURCE
-- ============================================================================
-- White gear's stock maximum durability back.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_155p_durability` (`entry` int unsigned NOT NULL, `MaxDurability` smallint unsigned NOT NULL, PRIMARY KEY (`entry`));
UPDATE `item_template` i JOIN `basic_155p_durability` b ON b.`entry` = i.`entry` SET i.`MaxDurability` = b.`MaxDurability`;
DROP TABLE `basic_155p_durability`;

-- ============================================================================
-- End of 21-white-durability.sql (revert)
-- ============================================================================
