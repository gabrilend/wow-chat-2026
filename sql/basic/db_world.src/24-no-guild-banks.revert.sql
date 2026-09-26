-- MARKER_E039_REVERT basic-no-guild-banks
-- ============================================================================
-- 24-no-guild-banks.sql (issue 617l) — REVERT SOURCE
-- ============================================================================
-- The Guild Vaults back where they stood.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_617l_guild_vaults` LIKE `gameobject`;
INSERT IGNORE INTO `gameobject` SELECT * FROM `basic_617l_guild_vaults`;
DROP TABLE `basic_617l_guild_vaults`;

-- ============================================================================
-- End of 24-no-guild-banks.sql (revert)
-- ============================================================================
