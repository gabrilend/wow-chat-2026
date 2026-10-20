-- MARKER_E011_REVERT beta-dk-class-system

CREATE TABLE IF NOT EXISTS `wow_chat_e011_snapshot_creature_default_trainer` LIKE `creature_default_trainer`;
UPDATE `creature_default_trainer` d JOIN `wow_chat_e011_snapshot_creature_default_trainer` s ON s.`CreatureId` = d.`CreatureId`
    SET d.`TrainerId` = s.`TrainerId`;
DROP TABLE `wow_chat_e011_snapshot_creature_default_trainer`;
DELETE FROM `trainer_spell` WHERE `TrainerId` = 2060001;
DELETE FROM `trainer`       WHERE `Id`        = 2060001;

DELETE FROM `player_class_stats`            WHERE `Class` = 6 AND `Level` BETWEEN 1 AND 54;
DELETE FROM `playercreateinfo_spell_custom` WHERE `classmask` = 32 AND `Spell` = 45902;
DELETE FROM `playercreateinfo_item`         WHERE `class` = 6 AND `race` <> 0 AND `amount` > 0;  -- E058's removal rows (amount -1) are E058's to undo
