-- MARKER_E025_REVERT basic-valley-universal-trainers
-- ============================================================================
-- 10-valley-universal-trainers.sql (issue 155e) — REVERT SOURCE
-- ============================================================================
-- Remove every row the apply form owns (fixed id ranges), put the goblin
-- placeholder spawns back from their backup, and drop the helper tables.
-- ============================================================================

DELETE FROM `creature`                  WHERE `guid`       BETWEEN 15500001 AND 15500024;
DELETE FROM `creature_template_model`   WHERE `CreatureID` BETWEEN 1550001  AND 1550024;
DELETE FROM `creature_template`         WHERE `entry`      BETWEEN 1550001  AND 1550024;
DELETE FROM `gossip_menu_option`        WHERE `MenuID`     BETWEEN 155001   AND 155024;
DELETE FROM `gossip_menu`               WHERE `MenuID`     BETWEEN 155001   AND 155024;
DELETE FROM `npc_text`                  WHERE `ID`         BETWEEN 155001   AND 155024;
DELETE FROM `trainer_spell`             WHERE `TrainerId`  BETWEEN 155101   AND 155111;
DELETE FROM `trainer`                   WHERE `Id`         BETWEEN 155101   AND 155111;

-- The first draft of this file (never applied to a database) used a
-- creature_default_trainer row and trainer ids 155001-155008; clear them in
-- case a hand-run left them.
DELETE FROM `creature_default_trainer`  WHERE `CreatureId` BETWEEN 1550001  AND 1550024;
DELETE FROM `trainer_spell`             WHERE `TrainerId`  BETWEEN 155001   AND 155008;
DELETE FROM `trainer`                   WHERE `Id`         BETWEEN 155001   AND 155008;

INSERT IGNORE INTO `creature` SELECT * FROM `basic_155e_goblin_backup`;

DROP TABLE IF EXISTS `basic_155e_goblin_backup`;
DROP TABLE IF EXISTS `basic_155e_missing`;
DROP TABLE IF EXISTS `basic_155e_hubs`;
DROP TABLE IF EXISTS `basic_155e_valleys`;

-- ============================================================================
-- End of 10-valley-universal-trainers.sql (revert)
-- ============================================================================
