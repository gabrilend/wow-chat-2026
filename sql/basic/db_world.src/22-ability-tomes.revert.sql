-- MARKER_E037_REVERT basic-ability-tomes
-- ============================================================================
-- 22-ability-tomes.sql (issue 155q) — REVERT SOURCE
-- ============================================================================
-- The class books, their two loot pools and every drop row that points at
-- them, removed. Nothing stock was changed, so nothing is restored.
-- ============================================================================

DELETE FROM `creature_loot_template`   WHERE `Reference` IN (1557901, 1557902);
DELETE FROM `gameobject_loot_template` WHERE `Reference` IN (1557901, 1557902);
DELETE FROM `reference_loot_template`  WHERE `Entry`     IN (1557901, 1557902);
DELETE FROM `item_template`            WHERE `entry` BETWEEN 1557001 AND 1557999;
DROP TABLE IF EXISTS `basic_155q_books`;

-- ============================================================================
-- End of 22-ability-tomes.sql (revert)
-- ============================================================================
