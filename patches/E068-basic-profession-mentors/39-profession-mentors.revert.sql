-- MARKER_E068_REVERT basic-profession-mentors
DELETE FROM `creature`                WHERE `guid`       BETWEEN 15500031 AND 15500038;
DELETE FROM `creature_template_model` WHERE `CreatureID` BETWEEN 1550031  AND 1550038;
DELETE FROM `creature_template`       WHERE `entry`      BETWEEN 1550031  AND 1550038;
DELETE FROM `gossip_menu_option`      WHERE `MenuID`     BETWEEN 155031   AND 155038;
DELETE FROM `gossip_menu`             WHERE `MenuID`     BETWEEN 155031   AND 155038;
DELETE FROM `npc_text`                WHERE `ID`         BETWEEN 155031   AND 155038;
DELETE FROM `trainer_spell`           WHERE `TrainerId`  BETWEEN 155201   AND 155214;
DELETE FROM `trainer`                 WHERE `Id`         BETWEEN 155201   AND 155214;
CREATE TABLE IF NOT EXISTS `basic_155e1_jewelcrafter_backup` LIKE `creature`;
INSERT IGNORE INTO `creature` SELECT * FROM `basic_155e1_jewelcrafter_backup`;
DROP TABLE IF EXISTS `basic_155e1_jewelcrafter_backup`;
DROP TABLE IF EXISTS `basic_155e1_missing`;
DROP TABLE IF EXISTS `basic_155e1_mentors`;
