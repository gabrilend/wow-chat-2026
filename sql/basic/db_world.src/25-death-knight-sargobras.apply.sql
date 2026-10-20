-- MARKER_E040_APPLY basic-death-knight-sargobras

DELETE FROM `creature`                WHERE `guid`       BETWEEN 7180001 AND 7180002;
DELETE FROM `creature`                WHERE `guid`       = 71800001;
DELETE FROM `creature_template_model` WHERE `CreatureID` BETWEEN 7180001 AND 7180002;
DELETE FROM `creature_template`       WHERE `entry`      BETWEEN 7180001 AND 7180002;
DELETE FROM `npc_text`                WHERE `ID` BETWEEN 7180001 AND 7180003;

DROP TEMPORARY TABLE IF EXISTS `tmp_718_template`;
CREATE TEMPORARY TABLE `tmp_718_template` AS SELECT * FROM `creature_template` WHERE `entry` = 1754;
UPDATE `tmp_718_template` SET
  `entry` = 7180001, `name` = 'Sargobras', `subname` = '', `npcflag` = 1,
  `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0, `KillCredit1` = 0, `KillCredit2` = 0,
  `faction` = 35, `gossip_menu_id` = 0, `minlevel` = 80, `maxlevel` = 80,
  `lootid` = 0, `pickpocketloot` = 0, `skinloot` = 0, `AIName` = '', `ScriptName` = '',
  `rank` = 3;
INSERT INTO `creature_template` SELECT * FROM `tmp_718_template`;
DROP TEMPORARY TABLE `tmp_718_template`;
DROP TEMPORARY TABLE IF EXISTS `tmp_718_model`;
CREATE TEMPORARY TABLE `tmp_718_model` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` = 1754;
UPDATE `tmp_718_model` SET `CreatureID` = 7180001;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_718_model`;
DROP TEMPORARY TABLE `tmp_718_model`;

DROP TEMPORARY TABLE IF EXISTS `tmp_718_template`;
CREATE TEMPORARY TABLE `tmp_718_template` AS SELECT * FROM `creature_template` WHERE `entry` = 7180001;
UPDATE `tmp_718_template` SET `entry` = 7180002, `npcflag` = 0, `minlevel` = 100, `maxlevel` = 100, `unit_flags` = 256;
INSERT INTO `creature_template` SELECT * FROM `tmp_718_template`;
DROP TEMPORARY TABLE `tmp_718_template`;
DROP TEMPORARY TABLE IF EXISTS `tmp_718_model`;
CREATE TEMPORARY TABLE `tmp_718_model` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` = 7180001;
UPDATE `tmp_718_model` SET `CreatureID` = 7180002;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_718_model`;
DROP TEMPORARY TABLE `tmp_718_model`;

INSERT INTO `npc_text` (`ID`,
  `text0_0`, `text0_1`, `Probability0`, `text1_0`, `text1_1`, `Probability1`,
  `text2_0`, `text2_1`, `Probability2`, `text3_0`, `text3_1`, `Probability3`,
  `text4_0`, `text4_1`, `Probability4`, `text5_0`, `text5_1`, `Probability5`,
  `text6_0`, `text6_1`, `Probability6`, `text7_0`, `text7_1`, `Probability7`) VALUES
  (7180001,
   'You know why you are here.',                                        'You know why you are here.',                                        1,
   'Justice is always forgiven eventually.',                            'Justice is always forgiven eventually.',                            1,
   'One hero for the Lich King, one death knight for the living.',      'One hero for the Lich King, one death knight for the living.',      1,
   'Every soul is a door. Some open both ways.',                        'Every soul is a door. Some open both ways.',                        1,
   'The cold remembers what the living forget.',                        'The cold remembers what the living forget.',                        1,
   'What you were is waiting to be spent.',                             'What you were is waiting to be spent.',                             1,
   'I keep what I take, and I take only what is given.',                'I keep what I take, and I take only what is given.',                1,
   'The Lich King counts in lives. I count in names.',                  'The Lich King counts in lives. I count in names.',                  1);
DROP TEMPORARY TABLE IF EXISTS `tmp_718_text`;
CREATE TEMPORARY TABLE `tmp_718_text` AS SELECT * FROM `npc_text` WHERE `ID` = 7180001;
UPDATE `tmp_718_text` SET `ID` = 7180002;
INSERT INTO `npc_text` SELECT * FROM `tmp_718_text`;
UPDATE `tmp_718_text` SET `ID` = 7180003;
INSERT INTO `npc_text` SELECT * FROM `tmp_718_text`;
DROP TEMPORARY TABLE `tmp_718_text`;

INSERT INTO `creature` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `Comment`) VALUES
  (7180001, 7180001, 0, 1, 4294967295, 2336.2, -5677.9, 382.3, 0.66, 300, 'issue 718: Sargobras at the gate of Acherus'),
  (7180002, 7180001, 609, 1, 4294967295, 2350.6, -5668.3, 426.07, 0.63, 300, 'issue 718: Sargobras before the Lich King, where new death knights arrive');

