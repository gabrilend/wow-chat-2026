-- MARKER_E043_APPLY basic-buddy-selector
-- ============================================================================
-- 26-buddy-selector.sql (issue 617b) — APPLY SOURCE
-- ============================================================================
-- Sargobras, the buddy selector. Two creatures share his look (Lord Gregor
-- Lescovar's stand-in, like the Sargobras at Acherus, until 617f chooses):
--
--   6170001  the valley Sargobras: one stands a few steps in front of where
--            new characters arrive in each of the eight starting valleys,
--            for the first buddy (every new character owes one; 617a2).
--   6170002  the wandering Sargobras: never spawned from the database; the
--            Lua script (src/lua-basic/sargobras.lua) summons one near an
--            owner who is owed a buddy, at each tenth level and at login.
--
-- Both talk through the Lua script (gossip hooks on these entries). Texts:
--   6170001  greeting to someone owed a buddy
--   6170002  the wandering Sargobras, to someone who isn't his owner
--   6170003  to someone owed nothing
--
-- Creatures 6170001-6170002, valley spawns 6170001-6170008, texts
-- 6170001-6170003. Re-applicable: each apply first removes what an earlier
-- one added. Database: acore_world_basic. Applied by E043.
-- ============================================================================

DELETE FROM `creature`                WHERE `guid`       BETWEEN 6170001  AND 6170099;
-- the old spawn range, past the server's 16777215 spawn-id cap (it stopped at
-- startup); cleared so a database that holds it is repaired on re-apply
DELETE FROM `creature`                WHERE `guid`       BETWEEN 61700001 AND 61700099;
DELETE FROM `creature_template_model` WHERE `CreatureID` BETWEEN 6170001  AND 6170002;
DELETE FROM `creature_template`       WHERE `entry`      BETWEEN 6170001  AND 6170002;
DELETE FROM `npc_text`                WHERE `ID`         BETWEEN 6170001  AND 6170003;

-- two copies of Lord Gregor Lescovar (1754): gossip only, friendly to all
DROP TEMPORARY TABLE IF EXISTS `tmp_617b_template`;
CREATE TEMPORARY TABLE `tmp_617b_template` AS SELECT * FROM `creature_template` WHERE `entry` = 1754;
UPDATE `tmp_617b_template` SET
  `entry` = 6170001, `name` = 'Sargobras', `subname` = '', `npcflag` = 1,
  `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0, `KillCredit1` = 0, `KillCredit2` = 0,
  `faction` = 35, `gossip_menu_id` = 0, `minlevel` = 80, `maxlevel` = 80,
  `lootid` = 0, `pickpocketloot` = 0, `skinloot` = 0, `AIName` = '', `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM `tmp_617b_template`;
UPDATE `tmp_617b_template` SET `entry` = 6170002;
INSERT INTO `creature_template` SELECT * FROM `tmp_617b_template`;
DROP TEMPORARY TABLE `tmp_617b_template`;
DROP TEMPORARY TABLE IF EXISTS `tmp_617b_model`;
CREATE TEMPORARY TABLE `tmp_617b_model` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` = 1754;
UPDATE `tmp_617b_model` SET `CreatureID` = 6170001;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_617b_model`;
UPDATE `tmp_617b_model` SET `CreatureID` = 6170002;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_617b_model`;
DROP TEMPORARY TABLE `tmp_617b_model`;

-- He only speaks in riddles (Ritz, 2026-09-29: "Sargobras should just say
-- cryptic things like 'You know why you are here.' and 'Justice is always
-- forgiven eventually.' and 'The kind mind, to the future is aligned.' and
-- such"). The first three lines are the owner's, kept word for word; the
-- other five follow them. One pool for all three texts: the menu's own
-- options say what can be done, so the greeting needn't. The client picks
-- one of the eight at random, each equally likely.
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

-- >>> GENERATED by scripts/generate-basic-buddy-selector-sql
-- one per starting valley: 4 yards ahead of the arrival point, facing it
INSERT INTO `creature` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `Comment`) VALUES
  (6170001, 6170001, 0, 1, 1, -6236.3, 331.0, 382.8, 3.14, 300, 'issue 617b: valley Sargobras, zone 1 (races 3,7)'),
  (6170002, 6170001, 0, 1, 1, -8946.0, -132.5, 83.5, 3.14, 300, 'issue 617b: valley Sargobras, zone 12 (races 1)'),
  (6170003, 6170001, 0, 1, 1, 1673.1, 1680.0, 121.7, 5.85, 300, 'issue 617b: valley Sargobras, zone 85 (races 5)'),
  (6170004, 6170001, 1, 1, 1, -614.5, -4251.7, 38.7, 3.14, 300, 'issue 617b: valley Sargobras, zone 14 (races 2,8)'),
  (6170005, 6170001, 1, 1, 1, 10314.6, 830.2, 1326.4, 2.55, 300, 'issue 617b: valley Sargobras, zone 141 (races 4)'),
  (6170006, 6170001, 1, 1, 1, -2913.6, -258.0, 53.0, 3.14, 300, 'issue 617b: valley Sargobras, zone 215 (races 6)'),
  (6170007, 6170001, 530, 1, 1, 10351.9, -6360.6, 33.4, 2.17, 300, 'issue 617b: valley Sargobras, zone 3431 (races 10)'),
  (6170008, 6170001, 530, 1, 1, -3963.6, -13927.7, 100.6, 5.23, 300, 'issue 617b: valley Sargobras, zone 3526 (races 11)');
-- <<< GENERATED END

-- ============================================================================
-- End of 26-buddy-selector.sql (apply)
-- ============================================================================
