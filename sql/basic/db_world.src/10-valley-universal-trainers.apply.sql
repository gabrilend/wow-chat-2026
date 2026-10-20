-- MARKER_E025_APPLY basic-valley-universal-trainers

CREATE TABLE IF NOT EXISTS `basic_155e_hubs` (
  `hub`        tinyint unsigned  NOT NULL,
  `name`       varchar(32)       NOT NULL,
  `map`        smallint unsigned NOT NULL,
  `x` float NOT NULL, `y` float NOT NULL, `z` float NOT NULL, `o` float NOT NULL,
  `clone_from` int unsigned      NOT NULL,
  `clone_note` varchar(96)       NOT NULL,
  PRIMARY KEY (`hub`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155e: Visiting Mentor sites';
CREATE TABLE IF NOT EXISTS `basic_155e_missing` (
  `hub`   tinyint unsigned NOT NULL,
  `class` tinyint unsigned NOT NULL,
  PRIMARY KEY (`hub`, `class`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155e: classes each site lacks';
DROP TABLE IF EXISTS `basic_155e_valleys`;   -- the valleys-only first version's table

DELETE FROM `basic_155e_hubs`;
INSERT INTO `basic_155e_hubs` (`hub`, `name`, `map`, `x`, `y`, `z`, `o`, `clone_from`, `clone_note`) VALUES
  ( 1, 'Ammen Vale', 530, -4076.080, -13752.800, 78.557, 4.7298, 5165, 'Hulfdan Blackbeard, rogue trainer'),
  ( 2, 'Azure Watch', 530, -4160.230, -12529.500, 49.180, 2.0944, 918, 'Osborne the Night Man, rogue trainer'),
  ( 3, 'Bloodhoof Village', 1, -2286.500, -360.229, -5.658, 2.7053, 3046, 'Father Cobb, priest trainer'),
  ( 4, 'Brill', 0, 2252.920, 308.318, 38.765, 5.2185, 3039, 'Holt Thunderhorn, hunter trainer'),
  ( 5, 'Camp Narache', 1, -2909.630, -244.459, 56.765, 5.2709, 3047, 'Archmage Shymm, mage trainer'),
  ( 6, 'Coldridge Valley', 0, -6188.090, 392.323, 397.086, 4.7473, 17519, 'Hobahken, shaman trainer'),
  ( 7, 'Darnassus', 1, 9999.290, 2285.660, 1345.160, 4.5030, 5173, 'Alexander Calder, warlock trainer'),
  ( 8, 'Deathknell', 0, 1822.940, 1585.590, 99.149, 1.2392, 20406, 'Champion Cyssa Dawnrose, paladin trainer'),
  ( 9, 'Dolanaar', 1, 9856.330, 954.043, 1310.540, 0.7505, 35281, 'Rukua, paladin trainer'),
  (10, 'Falconwing Square', 530, 9547.040, -6812.600, 20.227, 3.4383, 3344, 'Kardris Dreamseeker, shaman trainer'),
  (11, 'Goldshire', 0, -9496.100, 35.965, 60.407, 2.4085, 4138, 'Jeen''ra Nightrunner, hunter trainer'),
  (12, 'Ironforge', 0, -4941.620, -996.549, 505.210, 2.0071, 5504, 'Sheldras Moontree, druid trainer'),
  (13, 'Kharanos', 0, -5575.260, -485.474, 401.292, 1.6406, 17204, 'Farseer Nobundo, shaman trainer'),
  (14, 'Northshire Valley', 0, -8946.190, -158.145, 85.686, 1.6406, 4217, 'Mathrengyl Bearwalker, druid trainer'),
  (15, 'Orgrimmar', 1, 1568.310, -4420.210, 10.915, 4.2586, 16655, 'Harene Plainwalker, druid trainer'),
  (16, 'Razor Hill', 1, 257.529, -4747.890, 13.869, 1.0996, 4566, 'Kaelystia Hatebringer, mage trainer'),
  (17, 'Shadowglen', 1, 10315.700, 852.533, 1334.570, 5.6549, 5147, 'Valgar Highforge, paladin trainer'),
  (18, 'Silvermoon City', 530, 9560.710, -7320.980, 17.892, 4.1190, 3042, 'Sark Ragetotem, warrior trainer'),
  (19, 'Sunstrider Isle', 530, 10377.400, -6400.490, 53.482, 5.9690, 3034, 'Sheal Runetotem, druid trainer'),
  (20, 'The Exodar', 530, -4034.340, -11891.900, 2.159, 4.7996, 461, 'Demisette Cloyce, warlock trainer'),
  (21, 'Thunder Bluff', 1, -1280.320, 87.038, 132.570, 0.6981, 3401, 'Shenthul, rogue trainer'),
  (22, 'Undercity', 0, 1811.610, 194.030, 74.166, 1.6406, 3032, 'Beram Skychaser, shaman trainer'),
  (23, 'Valley of Trials', 1, -622.560, -4220.120, 41.901, 5.6898, 23128, 'Master Pyreanor, paladin trainer');
DELETE FROM `basic_155e_missing`;
INSERT INTO `basic_155e_missing` (`hub`, `class`) VALUES
  (1, 4), (1, 9), (1, 11), (2, 4), (2, 9), (2, 11), (3, 2), (3, 4), (3, 5), (3, 8), (3, 9), (4, 2), (4, 3), (4, 7), (4, 11), (5, 2), (5, 4), (5, 5), (5, 8), (5, 9), (6, 7), (6, 11), (7, 7), (7, 9), (8, 2), (8, 3), (8, 7), (8, 11), (9, 2), (9, 7), (9, 8), (9, 9), (10, 1), (10, 7), (10, 11), (11, 3), (11, 7), (11, 11), (12, 11), (13, 7), (13, 11), (14, 3), (14, 7), (14, 11), (15, 11), (16, 2), (16, 8), (16, 11), (17, 2), (17, 7), (17, 8), (17, 9), (18, 1), (18, 7), (19, 1), (19, 7), (19, 11), (20, 4), (20, 9), (21, 2), (21, 4), (21, 9), (22, 3), (22, 7), (22, 11), (23, 2), (23, 11);

DELETE FROM `creature`                  WHERE `guid`       BETWEEN 15500001 AND 15500024;
DELETE FROM `creature_template_model`   WHERE `CreatureID` BETWEEN 1550001  AND 1550024;
DELETE FROM `creature_template`         WHERE `entry`      BETWEEN 1550001  AND 1550024;
DELETE FROM `gossip_menu_option`        WHERE `MenuID`     BETWEEN 155001   AND 155024;
DELETE FROM `gossip_menu`               WHERE `MenuID`     BETWEEN 155001   AND 155024;
DELETE FROM `npc_text`                  WHERE `ID`         BETWEEN 155001   AND 155024;
DELETE FROM `trainer_spell`             WHERE `TrainerId`  BETWEEN 155101   AND 155111;
DELETE FROM `trainer`                   WHERE `Id`         BETWEEN 155101   AND 155111;

INSERT INTO `trainer` (`Id`, `Type`, `Requirement`, `Greeting`)
SELECT DISTINCT 155100 + m.`class`, 0, m.`class`, 'Here is what I can teach you.'
FROM `basic_155e_missing` m;

INSERT INTO `trainer_spell`
  (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`,
   `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`)
SELECT 155100 + t.`Requirement`, ts.`SpellId`,
       MIN(ts.`MoneyCost`), MIN(ts.`ReqSkillLine`), MIN(ts.`ReqSkillRank`),
       MIN(ts.`ReqAbility1`), MIN(ts.`ReqAbility2`), MIN(ts.`ReqAbility3`), MIN(ts.`ReqLevel`)
FROM `trainer` t
JOIN `trainer_spell` ts ON ts.`TrainerId` = t.`Id`
WHERE t.`Type` = 0
  AND t.`Id` NOT BETWEEN 155101 AND 155111
  AND t.`Requirement` IN (SELECT DISTINCT `class` FROM `basic_155e_missing`)
GROUP BY t.`Requirement`, ts.`SpellId`;

INSERT INTO `npc_text` (`ID`, `text0_0`, `lang0`, `Probability0`)
SELECT 155000 + v.`hub`,
       CONCAT('Not every calling has a teacher in ', v.`name`,
              '. If yours is one of them, I can help. If not, your own trainers are close by.'),
       0, 1
FROM `basic_155e_hubs` v;

INSERT INTO `gossip_menu` (`MenuID`, `TextID`)
SELECT 155000 + v.`hub`, 155000 + v.`hub` FROM `basic_155e_hubs` v;

INSERT INTO `gossip_menu_option`
  (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`,
   `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`)
SELECT 155000 + m.`hub`, m.`class`, 3,
       CONCAT('Can you teach me the ways of the ',
              ELT(m.`class`, 'warrior', 'paladin', 'hunter', 'rogue', 'priest', 'death knight',
                            'shaman', 'mage', 'warlock', '', 'druid'), '?'),
       0, 5, 16, 155100 + m.`class`, 0, 0, 0, '', 0
FROM `basic_155e_missing` m;

DROP TEMPORARY TABLE IF EXISTS `tmp_155e_template`;
CREATE TEMPORARY TABLE `tmp_155e_template` AS
SELECT t.* FROM `creature_template` t JOIN `basic_155e_hubs` v ON v.`clone_from` = t.`entry`;
UPDATE `tmp_155e_template` t JOIN `basic_155e_hubs` v ON v.`clone_from` = t.`entry`
SET t.`entry`              = 1550000 + v.`hub`,
    t.`difficulty_entry_1` = 0, t.`difficulty_entry_2` = 0, t.`difficulty_entry_3` = 0,
    t.`KillCredit1`        = 0, t.`KillCredit2` = 0,
    t.`name`               = 'Visiting Mentor',
    t.`subname`            = 'Class Trainer',
    t.`gossip_menu_id`     = 155000 + v.`hub`,
    t.`npcflag`            = 1 | 16,           -- UNIT_NPC_FLAG_GOSSIP | UNIT_NPC_FLAG_TRAINER
    t.`lootid`             = 0, t.`pickpocketloot` = 0, t.`skinloot` = 0,
    t.`AIName`             = '',
    t.`ScriptName`         = '';
INSERT INTO `creature_template` SELECT * FROM `tmp_155e_template`;
DROP TEMPORARY TABLE `tmp_155e_template`;

DROP TEMPORARY TABLE IF EXISTS `tmp_155e_model`;
CREATE TEMPORARY TABLE `tmp_155e_model` AS
SELECT m.* FROM `creature_template_model` m JOIN `basic_155e_hubs` v ON v.`clone_from` = m.`CreatureID`;
UPDATE `tmp_155e_model` m JOIN `basic_155e_hubs` v ON v.`clone_from` = m.`CreatureID`
SET m.`CreatureID` = 1550000 + v.`hub`;
INSERT INTO `creature_template_model` SELECT * FROM `tmp_155e_model`;
DROP TEMPORARY TABLE `tmp_155e_model`;

CREATE TABLE IF NOT EXISTS `basic_155e_goblin_backup` LIKE `creature`;
INSERT IGNORE INTO `basic_155e_goblin_backup`
SELECT c.* FROM `creature` c
JOIN `basic_155e_hubs` v ON v.`map` = c.`map`
WHERE c.`id` BETWEEN 26324 AND 26332
  AND POW(c.`position_x` - v.`x`, 2) + POW(c.`position_y` - v.`y`, 2) < 60 * 60;   -- a site's stack stands within a few yards
DELETE c FROM `creature` c
JOIN `basic_155e_goblin_backup` b ON b.`guid` = c.`guid`;
CREATE TABLE IF NOT EXISTS `basic_155e_goblin_events` LIKE `game_event_creature`;
INSERT IGNORE INTO `basic_155e_goblin_events`
SELECT e.* FROM `game_event_creature` e WHERE ABS(e.`guid`) IN (SELECT `guid` FROM `basic_155e_goblin_backup`);
DELETE e FROM `game_event_creature` e JOIN `basic_155e_goblin_events` b ON b.`guid` = e.`guid` AND b.`eventEntry` = e.`eventEntry`;

INSERT INTO `creature`
  (`guid`, `id`, `map`, `spawnMask`, `phaseMask`,
   `position_x`, `position_y`, `position_z`, `orientation`,
   `spawntimesecs`, `Comment`)
SELECT 15500000 + v.`hub`, 1550000 + v.`hub`, v.`map`, 1, 1,
       v.`x`, v.`y`, v.`z`, v.`o`,
       300, CONCAT('issue 155e: Visiting Mentor, ', v.`name`, ' (looks like ', v.`clone_note`, ')')
FROM `basic_155e_hubs` v;

