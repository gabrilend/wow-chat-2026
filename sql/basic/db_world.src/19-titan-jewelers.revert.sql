-- MARKER_E034_REVERT basic-titan-jewelers

DELETE FROM `game_event_creature`      WHERE `eventEntry` IN (201, 202, 203);
DELETE FROM `game_event`               WHERE `eventEntry` IN (201, 202, 203);
DELETE FROM `creature`                 WHERE `guid` BETWEEN 15501011 AND 15501020;
DELETE FROM `creature_default_trainer` WHERE `CreatureId` IN (1550210, 1550211);
DELETE FROM `trainer_spell`            WHERE `TrainerId` = 155300;
DELETE FROM `trainer`                  WHERE `Id` = 155300;
DELETE FROM `creature_template_model`  WHERE `CreatureID` IN (1550210, 1550211);
DELETE FROM `creature_template`        WHERE `entry` IN (1550210, 1550211);
DELETE FROM `npc_text`                 WHERE `ID` = 1553000;
DROP TABLE IF EXISTS `tmp_155p_spots`;       -- working table, in case an apply stopped part-way

