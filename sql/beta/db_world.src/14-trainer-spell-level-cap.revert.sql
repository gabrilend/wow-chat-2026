-- MARKER_E014_REVERT beta-trainer-spell-level-cap

CREATE TABLE IF NOT EXISTS `wow_chat_e014_snapshot_creature_default_trainer` LIKE `creature_default_trainer`;
UPDATE `creature_default_trainer` d JOIN `wow_chat_e014_snapshot_creature_default_trainer` s ON s.`CreatureId` = d.`CreatureId`
    SET d.`TrainerId` = s.`TrainerId`;
DELETE FROM `trainer_spell` WHERE `TrainerId` BETWEEN 5030001 AND 5039999;
DELETE FROM `trainer`       WHERE `Id`        BETWEEN 5030001 AND 5039999;
DROP TABLE `wow_chat_e014_snapshot_creature_default_trainer`;
