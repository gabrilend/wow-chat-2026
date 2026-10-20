-- MARKER_E039_APPLY basic-no-guild-banks

CREATE TABLE IF NOT EXISTS `basic_617l_guild_vaults` LIKE `gameobject`;
INSERT IGNORE INTO `basic_617l_guild_vaults`
SELECT g.* FROM `gameobject` g JOIN `gameobject_template` t ON t.`entry` = g.`id` WHERE t.`type` = 34;   -- GAMEOBJECT_TYPE_GUILD_BANK
DELETE g FROM `gameobject` g JOIN `basic_617l_guild_vaults` v ON v.`guid` = g.`guid`;

