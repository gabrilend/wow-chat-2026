-- MARKER_E043_APPLY basic-buddy-selector

DELETE FROM `creature`                WHERE `guid`       BETWEEN 6170001  AND 6170099;
DELETE FROM `creature`                WHERE `guid`       BETWEEN 61700001 AND 61700099;
DELETE FROM `creature_template_model` WHERE `CreatureID` BETWEEN 6170001  AND 6170003;
DELETE FROM `creature_template`       WHERE `entry`      BETWEEN 6170001  AND 6170003;
DELETE FROM `npc_text`                WHERE `ID`         BETWEEN 6170001  AND 6170003;

DROP TEMPORARY TABLE IF EXISTS `tmp_617b_template`;
CREATE TEMPORARY TABLE `tmp_617b_template` AS SELECT * FROM `creature_template` WHERE `entry` = 1754;
UPDATE `tmp_617b_template` SET
  `entry` = 6170001, `name` = 'Sargobras', `subname` = '', `npcflag` = 1,
  `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0, `KillCredit1` = 0, `KillCredit2` = 0,
  `faction` = 35, `gossip_menu_id` = 0, `minlevel` = 80, `maxlevel` = 80,
  `lootid` = 0, `pickpocketloot` = 0, `skinloot` = 0, `AIName` = '', `ScriptName` = '',
  `rank` = 3;
INSERT INTO `creature_template` SELECT * FROM `tmp_617b_template`;
UPDATE `tmp_617b_template` SET `entry` = 6170002, `rank` = 0;
INSERT INTO `creature_template` SELECT * FROM `tmp_617b_template`;
UPDATE `tmp_617b_template` SET `entry` = 6170003;
INSERT INTO `creature_template` SELECT * FROM `tmp_617b_template`;
DROP TEMPORARY TABLE `tmp_617b_template`;
DROP TEMPORARY TABLE IF EXISTS `tmp_617b_model`;
CREATE TEMPORARY TABLE `tmp_617b_model` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` = 1754;
UPDATE `tmp_617b_model` SET `CreatureID` = 6170001;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_617b_model`;
UPDATE `tmp_617b_model` SET `CreatureID` = 6170002;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_617b_model`;
UPDATE `tmp_617b_model` SET `CreatureID` = 6170003;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_617b_model`;
DROP TEMPORARY TABLE `tmp_617b_model`;

INSERT INTO `npc_text` (`ID`,
  `text0_0`, `text0_1`, `Probability0`, `text1_0`, `text1_1`, `Probability1`,
  `text2_0`, `text2_1`, `Probability2`, `text3_0`, `text3_1`, `Probability3`,
  `text4_0`, `text4_1`, `Probability4`, `text5_0`, `text5_1`, `Probability5`,
  `text6_0`, `text6_1`, `Probability6`, `text7_0`, `text7_1`, `Probability7`) VALUES
  (6170001,
   'You know why you are here.',                                  'You know why you are here.',                                  1,
   'Justice is always forgiven eventually.',                      'Justice is always forgiven eventually.',                      1,
   'The kind mind, to the future is aligned.',                    'The kind mind, to the future is aligned.',                    1,
   'Every road you did not take still remembers your footsteps.', 'Every road you did not take still remembers your footsteps.', 1,
   'Company is a debt that pays itself.',                         'Company is a debt that pays itself.',                         1,
   'The fire keeps no secrets. I keep the rest.',                 'The fire keeps no secrets. I keep the rest.',                 1,
   'What walks beside you was waiting before you arrived.',       'What walks beside you was waiting before you arrived.',       1,
   'Ask, and the answer will already have left.',                 'Ask, and the answer will already have left.',                 1);
DROP TEMPORARY TABLE IF EXISTS `tmp_617b_text`;
CREATE TEMPORARY TABLE `tmp_617b_text` AS SELECT * FROM `npc_text` WHERE `ID` = 6170001;
UPDATE `tmp_617b_text` SET `ID` = 6170002;
INSERT INTO `npc_text` SELECT * FROM `tmp_617b_text`;
UPDATE `tmp_617b_text` SET `ID` = 6170003;
INSERT INTO `npc_text` SELECT * FROM `tmp_617b_text`;
DROP TEMPORARY TABLE `tmp_617b_text`;

INSERT INTO `creature` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `Comment`) VALUES
  (6170001, 6170001, 0, 1, 1, -6241.4, 327.1, 382.5, 1.31, 300, 'issue 617b: valley Sargobras, zone 1 (races 3,7)'),
  (6170002, 6170001, 0, 1, 1, -8951.0, -136.4, 83.5, 1.31, 300, 'issue 617b: valley Sargobras, zone 12 (races 1)'),
  (6170003, 6170001, 0, 1, 1, 1677.1, 1682.3, 121.9, 4.63, 300, 'issue 617b: valley Sargobras, zone 85 (races 5)'),
  (6170004, 6170001, 1, 1, 1, -615.2, -4249.4, 39.0, 3.75, 300, 'issue 617b: valley Sargobras, zone 14 (races 2,8)'),
  (6170005, 6170001, 1, 1, 1, 10314.5, 834.8, 1326.4, 3.78, 300, 'issue 617b: valley Sargobras, zone 141 (races 4)'),
  (6170006, 6170001, 1, 1, 1, -2916.2, -261.7, 53.4, 1.92, 300, 'issue 617b: valley Sargobras, zone 215 (races 6)'),
  (6170007, 6170001, 530, 1, 1, 10352.2, -6354.2, 32.8, 4.01, 300, 'issue 617b: valley Sargobras, zone 3431 (races 10)'),
  (6170008, 6170001, 530, 1, 1, -3965.6, -13931.9, 100.6, 0.16, 300, 'issue 617b: valley Sargobras, zone 3526 (races 11)');

