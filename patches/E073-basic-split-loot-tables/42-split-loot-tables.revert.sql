-- MARKER_E073_REVERT basic-split-loot-tables

DELETE FROM `creature_loot_template` WHERE `Reference` BETWEEN 1840000 AND 1849999;
DELETE FROM `reference_loot_template` WHERE `Reference` BETWEEN 1840000 AND 1849999;
DELETE FROM `gameobject_loot_template` WHERE `Reference` BETWEEN 1840000 AND 1849999;
DELETE FROM `item_loot_template` WHERE `Reference` BETWEEN 1840000 AND 1849999;
DELETE FROM `reference_loot_template` WHERE `Entry` BETWEEN 1840000 AND 1849999;
INSERT IGNORE INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) SELECT `Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment` FROM `basic_181_split_parents` WHERE `src` = 'creature_loot_template';
INSERT IGNORE INTO `reference_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) SELECT `Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment` FROM `basic_181_split_parents` WHERE `src` = 'reference_loot_template';
INSERT IGNORE INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) SELECT `Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment` FROM `basic_181_split_parents` WHERE `src` = 'gameobject_loot_template';
INSERT IGNORE INTO `item_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) SELECT `Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment` FROM `basic_181_split_parents` WHERE `src` = 'item_loot_template';
DROP TABLE IF EXISTS `basic_181_split_parents`;
