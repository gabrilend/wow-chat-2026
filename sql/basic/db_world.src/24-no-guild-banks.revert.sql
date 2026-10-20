-- MARKER_E039_REVERT basic-no-guild-banks

CREATE TABLE IF NOT EXISTS `basic_617l_guild_vaults` LIKE `gameobject`;
INSERT IGNORE INTO `gameobject` SELECT * FROM `basic_617l_guild_vaults`;
DROP TABLE `basic_617l_guild_vaults`;

