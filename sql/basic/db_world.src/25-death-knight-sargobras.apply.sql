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
-- Creature 7180001, spawn 71800001, texts 7180001-7180003. Re-applicable:
-- each apply first removes what an earlier one added.
-- Database: acore_world_basic. Applied by E040.
-- ============================================================================

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

-- 7180001: to a death knight who still owes a soul; 7180002: to one who
-- has paid; 7180003: to anyone else
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `Probability0`) VALUES
  (7180001, 'One hero for the Lich King, one death knight for the living. Name the soul you came from, and the way out is yours.',
            'One hero for the Lich King, one death knight for the living. Name the soul you came from, and the way out is yours.', 1),
  (7180002, 'A fair trade, and the Lich King keeps his half. Changed your mind? I keep what I take, but I have been known to give it back.',
            'A fair trade, and the Lich King keeps his half. Changed your mind? I keep what I take, but I have been known to give it back.', 1),
  (7180003, 'Just passing through? So am I. So is everyone, eventually.',
            'Just passing through? So am I. So is everyone, eventually.', 1);

-- between the Ebon Hold's portals to Stormwind (2324, -5660) and Orgrimmar
-- (2348, -5696), facing the way they face; every phase (4294967295)
INSERT INTO `creature` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `Comment`) VALUES
  (71800001, 7180001, 0, 1, 4294967295, 2336.2, -5677.9, 382.3, 0.66, 300, 'issue 718: Sargobras at the gate of Acherus');

-- ============================================================================
-- End of 25-death-knight-sargobras.sql (apply)
-- ============================================================================
