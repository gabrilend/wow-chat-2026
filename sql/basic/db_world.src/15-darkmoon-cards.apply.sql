-- MARKER_E030_APPLY basic-darkmoon-cards

DROP TABLE IF EXISTS `tmp_155o_darkmoon`;
CREATE TABLE `tmp_155o_darkmoon` (`entry` int unsigned NOT NULL, PRIMARY KEY (`entry`));
INSERT IGNORE INTO `tmp_155o_darkmoon` SELECT `entry` FROM `item_template`
WHERE `name` REGEXP '^(Ace|Two|Three|Four|Five|Six|Seven|Eight) of (Beasts|Warlords|Elementals|Portals|Blessings|Storms|Furies|Lunacy|Prisms|Chaos|Nobles|Undeath|Rogues|Swords|Mages|Demons)$'
   OR `name` IN ('Mysterious Tarot', 'Strange Tarot', 'Arcane Tarot', 'Shadowy Tarot', 'Darkmoon Card');
INSERT IGNORE INTO `tmp_155o_darkmoon`
SELECT d.`entry` FROM `item_template` d JOIN `quest_template` q ON q.`RequiredItemId1` = d.`entry` WHERE d.`name` LIKE '% Deck';
INSERT IGNORE INTO `tmp_155o_darkmoon`
SELECT x.`item` FROM (
  SELECT q.`RewardItem1` AS `item`, q.`RequiredItemId1` AS `deck` FROM `quest_template` q
  UNION ALL SELECT q.`RewardChoiceItemID1`, q.`RequiredItemId1` FROM `quest_template` q
  UNION ALL SELECT q.`RewardChoiceItemID2`, q.`RequiredItemId1` FROM `quest_template` q
  UNION ALL SELECT q.`RewardChoiceItemID3`, q.`RequiredItemId1` FROM `quest_template` q
) x JOIN `item_template` d ON d.`entry` = x.`deck`
WHERE d.`name` LIKE '% Deck' AND x.`item` <> 0;

CREATE TABLE IF NOT EXISTS `basic_155o_darkmoon_bonding` (
  `entry`   int unsigned     NOT NULL,
  `Bonding` tinyint unsigned NOT NULL,
  PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155o: stock binding of Darkmoon cards, decks and deck rewards, for the revert';
INSERT IGNORE INTO `basic_155o_darkmoon_bonding` (`entry`, `Bonding`)
SELECT i.`entry`, i.`Bonding` FROM `item_template` i JOIN `tmp_155o_darkmoon` t ON t.`entry` = i.`entry`;
UPDATE `item_template` i JOIN `basic_155o_darkmoon_bonding` b ON b.`entry` = i.`entry` SET i.`Bonding` = 0;

DELETE FROM `reference_loot_template` WHERE `Entry` = 1550155;
INSERT INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 1550155, `entry`, 0, 0, 0, 1, 1, 1, 1, CONCAT('basic 155o: ', `name`) FROM `item_template`
WHERE `name` REGEXP '^(Ace|Two|Three|Four|Five|Six|Seven|Eight) of (Blessings|Storms|Furies|Lunacy)$';

DROP TABLE IF EXISTS `tmp_155o_bosses`;
CREATE TABLE `tmp_155o_bosses` (`lootid` int unsigned NOT NULL, `rolls` tinyint unsigned NOT NULL, PRIMARY KEY (`lootid`));
INSERT IGNORE INTO `tmp_155o_bosses` (`lootid`, `rolls`)
SELECT DISTINCT t.`lootid`, IF(c.`map` = 585, 2, 1) FROM `creature` c JOIN `creature_template` t ON t.`entry` = c.`id`
WHERE c.`map` IN (552, 553, 554, 585) AND t.`ScriptName` LIKE 'boss\_%' AND t.`lootid` <> 0;
INSERT IGNORE INTO `tmp_155o_bosses` (`lootid`, `rolls`)
SELECT `lootid`, 1 FROM `creature_template` WHERE `entry` = 20912 AND `lootid` <> 0;      -- Harbinger Skyriss (summoned)
INSERT INTO `tmp_155o_bosses` (`lootid`, `rolls`)
SELECT `lootid`, 3 FROM `creature_template` WHERE `entry` = 24664 AND `lootid` <> 0       -- Kael'thas Sunstrider
ON DUPLICATE KEY UPDATE `rolls` = 3;

DELETE FROM `creature_loot_template` WHERE `Item` = 1550155 AND `Reference` = 1550155;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT `lootid`, 1550155, 1550155, 100, 0, 1, 0, `rolls`, `rolls`, 'basic 155o: Burning Crusade Darkmoon cards'
FROM `tmp_155o_bosses`;

DROP TABLE `tmp_155o_bosses`;
DROP TABLE `tmp_155o_darkmoon`;

