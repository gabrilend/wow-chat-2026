-- MARKER_E041_REVERT basic-death-knight-souls
-- ============================================================================
-- 03-death-knight-souls.sql (issue 718) — REVERT SOURCE
-- ============================================================================
-- Every held soul goes back to its own account before the ledger is
-- dropped, so reverting never strands a character on a holding account.
-- The death knights stay (both then exist). Run with the worldserver
-- stopped: it keeps its own cache of which account owns a character.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_718_souls` (`dk` int unsigned NOT NULL, `soul` int unsigned NOT NULL DEFAULT 0, `soul_account` int unsigned NOT NULL DEFAULT 0,
  `holding_account` int unsigned NOT NULL DEFAULT 0, `state` tinyint unsigned NOT NULL DEFAULT 0, `changed` int unsigned NOT NULL DEFAULT 0, PRIMARY KEY (`dk`));
UPDATE `characters` c JOIN `basic_718_souls` s ON s.`soul` = c.`guid`
SET c.`account` = s.`soul_account`
WHERE s.`soul` <> 0 AND s.`state` IN (1, 2) AND c.`account` = s.`holding_account`;
DROP TABLE IF EXISTS `basic_718_maxed`;
DROP TABLE `basic_718_souls`;

-- ============================================================================
-- End of 03-death-knight-souls.sql (revert)
-- ============================================================================
