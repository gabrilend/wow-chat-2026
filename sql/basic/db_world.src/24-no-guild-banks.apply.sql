-- MARKER_E039_APPLY basic-no-guild-banks
-- ============================================================================
-- 24-no-guild-banks.sql (issue 617l) — APPLY SOURCE
-- ============================================================================
-- No guild banks on basic. Ritz, 2026-09-25: "guild banks are disabled and
-- you can't leave your guild" / "let's remove the objects". The stock
-- server has no setting to switch guild banks off; a guild bank is only
-- reachable through a Guild Vault object, so every spawn of one (every
-- gameobject of the guild bank type, 34; 44 spawns in the stock world
-- database, none with addon, event or pool rows) is removed. Spawns saved
-- (basic_617l_guild_vaults) for the revert; re-applying finds them already
-- gone. Database: acore_world_basic. Applied by E039.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_617l_guild_vaults` LIKE `gameobject`;
INSERT IGNORE INTO `basic_617l_guild_vaults`
SELECT g.* FROM `gameobject` g JOIN `gameobject_template` t ON t.`entry` = g.`id` WHERE t.`type` = 34;   -- GAMEOBJECT_TYPE_GUILD_BANK
DELETE g FROM `gameobject` g JOIN `basic_617l_guild_vaults` v ON v.`guid` = g.`guid`;

-- ============================================================================
-- End of 24-no-guild-banks.sql (apply)
-- ============================================================================
