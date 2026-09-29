-- MARKER_E040_APPLY basic-death-knight-sargobras
-- ============================================================================
-- 25-death-knight-sargobras.sql (issue 718) — APPLY SOURCE
-- ============================================================================
-- Sargobras at the gate of Acherus. Ritz, 2026-09-25: "Can we have a static
-- Sargobras who offers to help them leave Acherus in exchange for a powerful
-- soul? One hero for the Lich King, one death knight for the living..."
--
-- He stands in the Ebon Hold (map 0, area 4281), between its two portals to
-- the capitals: the last step out of Acherus, and where Death Gate brings a
-- death knight home. Visible in every phase. His menu is Lua
-- (src/lua-basic/death-knight-souls.lua). His model is a stand-in, Lord
-- Gregor Lescovar's (a Stormwind noble), until his outfit is chosen (617f).
--
-- Creature 7180001, spawns 7180001-7180002, texts 7180001-7180003. Re-applicable:
-- each apply first removes what an earlier one added.
-- Database: acore_world_basic. Applied by E040.
-- ============================================================================

DELETE FROM `creature`                WHERE `guid`       BETWEEN 7180001 AND 7180002;
-- the old spawn id, past the server's 16777215 spawn-id cap (it stopped at
-- startup); cleared so a database that holds it is repaired on re-apply
DELETE FROM `creature`                WHERE `guid`       = 71800001;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 7180001;
DELETE FROM `creature_template`       WHERE `entry`      = 7180001;
DELETE FROM `npc_text`                WHERE `ID` BETWEEN 7180001 AND 7180003;

-- a copy of Lord Gregor Lescovar (1754): gossip only, friendly to all
DROP TEMPORARY TABLE IF EXISTS `tmp_718_template`;
CREATE TEMPORARY TABLE `tmp_718_template` AS SELECT * FROM `creature_template` WHERE `entry` = 1754;
UPDATE `tmp_718_template` SET
  `entry` = 7180001, `name` = 'Sargobras', `subname` = '', `npcflag` = 1,
  `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0, `KillCredit1` = 0, `KillCredit2` = 0,
  `faction` = 35, `gossip_menu_id` = 0, `minlevel` = 80, `maxlevel` = 80,
  `lootid` = 0, `pickpocketloot` = 0, `skinloot` = 0, `AIName` = '', `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM `tmp_718_template`;
DROP TEMPORARY TABLE `tmp_718_template`;
DROP TEMPORARY TABLE IF EXISTS `tmp_718_model`;
CREATE TEMPORARY TABLE `tmp_718_model` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` = 1754;
UPDATE `tmp_718_model` SET `CreatureID` = 7180001;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_718_model`;
DROP TEMPORARY TABLE `tmp_718_model`;

-- He only speaks in riddles (Ritz, 2026-09-29: "yes. The options the player
-- can pick should explain."): the menu's own options say what the trade
-- and the undo are, so his greeting needn't. One pool of eight for all
-- three texts; the client picks one at random, each equally likely. The
-- first two lines are the owner's, given for the valley Sargobras; the
-- third is the owner's design line for this one (2026-09-25); the rest
-- follow them.
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

-- 7180002: in the Heart of Acherus (map 609), halfway between where a new
-- death knight appears (2356, -5664) and the Lich King (2345, -5672), facing
-- the newcomer: he is met before the first quest, which the Lich King
-- withholds until the soul is paid (death-knight-souls.lua). 7180001:
-- between the Ebon Hold's portals to Stormwind (2324, -5660) and Orgrimmar
-- (2348, -5696), facing the way they face; every phase (4294967295)
INSERT INTO `creature` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `Comment`) VALUES
  (7180001, 7180001, 0, 1, 4294967295, 2336.2, -5677.9, 382.3, 0.66, 300, 'issue 718: Sargobras at the gate of Acherus'),
  (7180002, 7180001, 609, 1, 4294967295, 2350.6, -5668.3, 426.07, 0.63, 300, 'issue 718: Sargobras before the Lich King, where new death knights arrive');

-- ============================================================================
-- End of 25-death-knight-sargobras.sql (apply)
-- ============================================================================
