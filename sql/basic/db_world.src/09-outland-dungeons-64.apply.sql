-- MARKER_E024_APPLY basic-outland-dungeons-64
-- ============================================================================
-- 09-outland-dungeons-64.sql (issue 155f) — APPLY SOURCE
-- ============================================================================
-- (The file name is from the first version, which set every creature to a
-- flat level 64. Kept so the install step E024 and the tests keep pointing at
-- it.)
--
-- Every normal-mode Outland dungeon a level 60 may enter on basic, plus the
-- two Caverns of Time dungeons and Magisters' Terrace, gets harder by raising
-- its creatures' levels, each dungeon by its own step, so the dungeons form
-- one ladder (Ritz, 2026-09-24): the first six +4 ("let's make each creature
-- get +4 to their level"), the upper ones less, so that "Sethekk Halls
-- through MGT" land in order and match Naxxramas-40 in difficulty. End-boss
-- levels after the offset: Ramparts 66, Blood Furnace 66–67, Slave Pens 67–68,
-- Underbog 69, Mana-Tombs 70, Auchenai Crypts 70–71, Old Hillsbrad 71,
-- Sethekk Halls 72, Black Morass 72, Shadow Labyrinth 73, Shattered Halls
-- 72–73, Steamvault 74, Mechanar 74, Botanica 75, Arcatraz 75, Magisters'
-- Terrace 75–76, and Kael'thas 78 ("He's the highest level boss").
-- The open world, quests and heroic modes are untouched here.
--
-- Also:
--   * the seven dungeons whose stock entry level is above 60 open at 60;
--   * their normal-mode attunements (Old Hillsbrad: "The Caverns of Time",
--     Black Morass: "Return to Andormu") are removed ("Theoretically yes, if
--     we remove the attunement requirements"); heroic requirements stay;
--   * every weapon or armour piece that drops in these dungeons' normal mode
--     and requires more than 60 requires 60, the rare item-level-100 epics
--     and Kael'thas's epics included.
--
-- Why level alone retunes health and damage: stats are computed at spawn as
-- (class/level/expansion base value from creature_classlevelstats) × (the
-- template's HealthModifier / DamageModifier). Raising the level keeps each
-- creature's own multiplier (elites stay elite, bosses stay bosses).
-- (Creature.cpp: basehp = stats->GenerateHealth(cInfo); health = basehp *
-- healthmod.) Crushing blows from creatures level 64+ are removed by B031.
--
-- Which templates:
--   (a) every template spawned in these dungeons;
--   (b) the creatures these dungeons' C++ scripts name (the GENERATED block,
--       written by scripts/generate-basic-outland-dungeons-sql from the
--       scripts' NPC_/ENTRY_/CREATURE_/MOB_ enum values, one dungeon each);
--   (c) database-scripted summons and summon groups of anything in the set,
--       followed two levels deep, inheriting their summoner's offset.
--   A template spawned in two of these dungeons takes the larger offset.
--   A template that is ALSO spawned anywhere outside these dungeons (the
--   Outland open world included) is left alone: raising it would raise it
--   there too. Heroic templates are never spawned directly, so heroic modes
--   stay stock. Left out on purpose: the Midsummer festival's Ahune
--   encounter in the Slave Pens (holiday content at its own level).
--
-- Idempotent: every value is computed from the saved originals, so running
-- this again (or over the old flat-64 version) gives the same result. The
-- revert restores the originals exactly.
-- Schema note: creature.id, not id1 (renamed upstream in 2026_06_16_00).
-- Database: acore_world_basic. Applied by E024.
-- ============================================================================

-- ---- the dungeons and each one's level offset -------------------------------
DROP TABLE IF EXISTS `basic_155f_maps`;   -- helper; rebuilt every run (the flat-64 version had no offset column)
CREATE TABLE `basic_155f_maps` (
  `map_id`       int unsigned NOT NULL,
  `level_offset` tinyint      NOT NULL,
  PRIMARY KEY (`map_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155f: Outland dungeons open at 60, and how many levels their creatures gain';
INSERT INTO `basic_155f_maps` (`map_id`, `level_offset`) VALUES
  (543, 4),  -- Hellfire Ramparts        bosses 62    -> 66
  (542, 4),  -- The Blood Furnace        62–63 -> 66–67
  (547, 4),  -- The Slave Pens           63–64 -> 67–68
  (546, 4),  -- The Underbog             65    -> 69
  (557, 4),  -- Mana-Tombs               66    -> 70
  (558, 4),  -- Auchenai Crypts          66–67 -> 70–71
  (560, 3),  -- Old Hillsbrad Foothills  68    -> 71   (opens at 60)
  (556, 4),  -- Sethekk Halls            68    -> 72
  (269, 0),  -- The Black Morass         72    -> 72   (opens at 60)
  (555, 1),  -- Shadow Labyrinth         72    -> 73   (opens at 60)
  (540, 1),  -- The Shattered Halls      71–72 -> 72–73
  (545, 2),  -- The Steamvault           72    -> 74
  (554, 2),  -- The Mechanar             72    -> 74   (opens at 60)
  (553, 3),  -- The Botanica             72    -> 75   (opens at 60)
  (552, 3),  -- The Arcatraz             72    -> 75   (opens at 60)
  (585, 5);  -- Magisters' Terrace       70–71 -> 75–76 (opens at 60); Kael'thas set to 78 below

-- ---- entry level 60 for all of them (normal mode) ---------------------------
CREATE TABLE IF NOT EXISTS `basic_155f_access_backup` (
  `map_id`     int unsigned     NOT NULL,
  `difficulty` tinyint unsigned NOT NULL,
  `min_level`  tinyint unsigned NOT NULL,
  PRIMARY KEY (`map_id`, `difficulty`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155f: original entry levels, for the revert';
INSERT IGNORE INTO `basic_155f_access_backup` (`map_id`, `difficulty`, `min_level`)
SELECT a.`map_id`, a.`difficulty`, a.`min_level` FROM `dungeon_access_template` a
WHERE a.`difficulty` = 0 AND a.`min_level` > 60 AND a.`map_id` IN (SELECT `map_id` FROM `basic_155f_maps`);
UPDATE `dungeon_access_template` a
JOIN `basic_155f_access_backup` b ON b.`map_id` = a.`map_id` AND b.`difficulty` = a.`difficulty`
SET a.`min_level` = 60;

-- ---- normal-mode attunements removed (heroic ones stay) ---------------------
CREATE TABLE IF NOT EXISTS `basic_155f_requirement_backup` LIKE `dungeon_access_requirements`;
INSERT IGNORE INTO `basic_155f_requirement_backup`
SELECT r.* FROM `dungeon_access_requirements` r
JOIN `dungeon_access_template` a ON a.`id` = r.`dungeon_access_id`
WHERE a.`difficulty` = 0 AND a.`map_id` IN (SELECT `map_id` FROM `basic_155f_maps`);
DELETE r FROM `dungeon_access_requirements` r
JOIN `basic_155f_requirement_backup` b
  ON b.`dungeon_access_id` = r.`dungeon_access_id` AND b.`requirement_type` = r.`requirement_type` AND b.`requirement_id` = r.`requirement_id`;

-- Working tables are ordinary tables, not TEMPORARY: MySQL refuses to open a
-- temporary table twice in one statement ("Can't reopen table"), and the
-- passes below read the set in several subqueries. All tmp_ tables are
-- dropped at the end of this file.

-- ---- spawns inside / outside the dungeons ----------------------------------
DROP TABLE IF EXISTS `tmp_155f_inside`;
CREATE TABLE `tmp_155f_inside` (`entry` int unsigned NOT NULL, `level_offset` tinyint NOT NULL, PRIMARY KEY (`entry`));
INSERT INTO `tmp_155f_inside` (`entry`, `level_offset`)
SELECT c.`id`, MAX(m.`level_offset`) FROM `creature` c JOIN `basic_155f_maps` m ON m.`map_id` = c.`map`
GROUP BY c.`id`;

DROP TABLE IF EXISTS `tmp_155f_outside`;
CREATE TABLE `tmp_155f_outside` (`entry` int unsigned NOT NULL, PRIMARY KEY (`entry`));
INSERT IGNORE INTO `tmp_155f_outside`
SELECT DISTINCT c.`id` FROM `creature` c
WHERE c.`map` NOT IN (SELECT `map_id` FROM `basic_155f_maps`);

-- ---- the working set, each template with its offset --------------------------
DROP TABLE IF EXISTS `tmp_155f_set`;
CREATE TABLE `tmp_155f_set` (`entry` int unsigned NOT NULL, `level_offset` tinyint NOT NULL, PRIMARY KEY (`entry`));

-- (a) spawned in the dungeons
INSERT INTO `tmp_155f_set` SELECT `entry`, `level_offset` FROM `tmp_155f_inside`;

-- (b) named by the dungeons' C++ scripts: (creature entry, dungeon map)
DROP TABLE IF EXISTS `tmp_155f_script_ids`;
CREATE TABLE `tmp_155f_script_ids` (`entry` int unsigned NOT NULL, `map_id` int unsigned NOT NULL, PRIMARY KEY (`entry`, `map_id`));
-- >>> GENERATED by scripts/generate-basic-outland-dungeons-sql — do not edit by hand
INSERT INTO `tmp_155f_script_ids` (`entry`, `map_id`) VALUES
  -- Outland/HellfireCitadel/HellfireRamparts (5)
  (17307,543),(17309,543),(17517,543),(17536,543),(17537,543),
  -- Outland/HellfireCitadel/BloodFurnace (5)
  (17377,542),(17380,542),(17381,542),(17398,542),(17653,542),
  -- Outland/HellfireCitadel/ShatteredHalls (23)
  (16807,540),(16808,540),(17083,540),(17288,540),(17289,540),(17290,540),(17292,540),(17294,540),(17295,540),(17296,540),(17297,540),(17301,540),(17427,540),(17461,540),(17462,540),(17611,540),(17687,540),(17693,540),(17695,540),(19523,540),(19524,540),(20709,540),(20923,540),
  -- Outland/CoilfangReservoir/SlavePens (17)
  (17941,547),(17942,547),(17991,547),(25697,547),(25740,547),(25745,547),(25754,547),(25865,547),(25961,547),(25964,547),(25965,547),(25966,547),(25971,547),(25972,547),(25973,547),(26120,547),(26121,547),
  -- Outland/CoilfangReservoir/underbog (4)
  (17770,546),(17990,546),(18105,546),(22299,546),
  -- Outland/CoilfangReservoir/SteamVault (6)
  (17796,545),(17798,545),(17917,545),(17951,545),(17954,545),(20926,545),
  -- Outland/Auchindoun/ManaTombs (4)
  (18309,557),(18311,557),(18313,557),(18431,557),
  -- Outland/Auchindoun/AuchenaiCrypts (2)
  (18374,558),(18441,558),
  -- Outland/Auchindoun/SethekkHalls (6)
  (21851,556),(23035,556),(23132,556),(23134,556),(23135,556),(23136,556),
  -- Outland/Auchindoun/ShadowLabyrinth (6)
  (18639,555),(18731,555),(18794,555),(19224,555),(19226,555),(19300,555),
  -- Outland/TempestKeep/Mechanar (6)
  (19168,554),(19220,554),(19510,554),(19735,554),(20988,554),(20990,554),
  -- Outland/TempestKeep/botanica (7)
  (17975,553),(17976,553),(17977,553),(17978,553),(17980,553),(18155,553),(19953,553),
  -- Outland/TempestKeep/arcatraz (13)
  (20885,552),(20886,552),(20904,552),(20905,552),(20906,552),(20908,552),(20909,552),(20910,552),(20911,552),(20912,552),(20977,552),(21436,552),(21466,552),
  -- Kalimdor/CavernsOfTime/EscapeFromDurnholdeKeep (23)
  (17819,560),(17833,560),(17848,560),(17860,560),(17862,560),(17876,560),(18092,560),(18093,560),(18094,560),(18096,560),(18170,560),(18171,560),(18172,560),(18598,560),(18723,560),(18764,560),(18798,560),(18887,560),(18934,560),(20155,560),(23175,560),(23177,560),(23179,560),
  -- Kalimdor/CavernsOfTime/TheBlackMorass (25)
  (15608,269),(17023,269),(17835,269),(17838,269),(17839,269),(17879,269),(17880,269),(17881,269),(17892,269),(17918,269),(18553,269),(18555,269),(18582,269),(18994,269),(18995,269),(21104,269),(21136,269),(21137,269),(21138,269),(21139,269),(21140,269),(21148,269),(21697,269),(21698,269),(21818,269),
  -- EasternKingdoms/MagistersTerrace (8)
  (24552,585),(24560,585),(24664,585),(24674,585),(24675,585),(24708,585),(24722,585),(24844,585);
-- <<< GENERATED END
INSERT INTO `tmp_155f_set` (`entry`, `level_offset`)
SELECT s.`entry`, MAX(m.`level_offset`) FROM `tmp_155f_script_ids` s
JOIN `basic_155f_maps` m ON m.`map_id` = s.`map_id`
JOIN `creature_template` t ON t.`entry` = s.`entry`       -- only ids that are creatures
WHERE s.`entry` NOT IN (25697, 25740, 25745, 25754, 25865, 25961, 25964, 25965, 25966, 25971, 25972, 25973, 26120, 26121)  -- Ahune (Midsummer)
GROUP BY s.`entry`
ON DUPLICATE KEY UPDATE `level_offset` = GREATEST(`tmp_155f_set`.`level_offset`, VALUES(`level_offset`));

-- (c) database-scripted summons (smart_scripts action 12) and summon groups
--     (creature_summon_groups, summonerType 0) of anything in the set; scripts
--     keyed by entry (source_type 0, positive), by a specific spawn in the
--     dungeons (negative = -guid), or timed action lists (source_type 9,
--     id = entry * 100 + n). Each summon takes its summoner's offset. Two passes.
DROP TABLE IF EXISTS `tmp_155f_found`;
CREATE TABLE `tmp_155f_found` (`entry` int unsigned NOT NULL, `level_offset` tinyint NOT NULL, PRIMARY KEY (`entry`));
INSERT INTO `tmp_155f_found` (`entry`, `level_offset`)
SELECT x.`entry`, MAX(x.`level_offset`) FROM (
  SELECT s.`action_param1` AS `entry`, st.`level_offset` FROM `smart_scripts` s
  JOIN `tmp_155f_set` st ON (s.`source_type` = 0 AND s.`entryorguid` > 0 AND s.`entryorguid` = st.`entry`)
                         OR (s.`source_type` = 9 AND s.`entryorguid` DIV 100 = st.`entry`)
  WHERE s.`action_type` = 12
  UNION ALL
  SELECT s.`action_param1`, m.`level_offset` FROM `smart_scripts` s
  JOIN `creature` c ON c.`guid` = -s.`entryorguid` JOIN `basic_155f_maps` m ON m.`map_id` = c.`map`
  WHERE s.`action_type` = 12 AND s.`source_type` = 0 AND s.`entryorguid` < 0
  UNION ALL
  SELECT g.`entry`, st.`level_offset` FROM `creature_summon_groups` g
  JOIN `tmp_155f_set` st ON st.`entry` = g.`summonerId` WHERE g.`summonerType` = 0
) x GROUP BY x.`entry`;
INSERT INTO `tmp_155f_set` SELECT `entry`, `level_offset` FROM `tmp_155f_found`
ON DUPLICATE KEY UPDATE `level_offset` = GREATEST(`tmp_155f_set`.`level_offset`, VALUES(`level_offset`));

DELETE FROM `tmp_155f_found`;
INSERT INTO `tmp_155f_found` (`entry`, `level_offset`)
SELECT x.`entry`, MAX(x.`level_offset`) FROM (
  SELECT s.`action_param1` AS `entry`, st.`level_offset` FROM `smart_scripts` s
  JOIN `tmp_155f_set` st ON (s.`source_type` = 0 AND s.`entryorguid` > 0 AND s.`entryorguid` = st.`entry`)
                         OR (s.`source_type` = 9 AND s.`entryorguid` DIV 100 = st.`entry`)
  WHERE s.`action_type` = 12
  UNION ALL
  SELECT g.`entry`, st.`level_offset` FROM `creature_summon_groups` g
  JOIN `tmp_155f_set` st ON st.`entry` = g.`summonerId` WHERE g.`summonerType` = 0
) x GROUP BY x.`entry`;
INSERT INTO `tmp_155f_set` SELECT `entry`, `level_offset` FROM `tmp_155f_found`
ON DUPLICATE KEY UPDATE `level_offset` = GREATEST(`tmp_155f_set`.`level_offset`, VALUES(`level_offset`));

-- never touch a template that also lives outside these dungeons, or that
-- isn't a creature template at all (summon actions can name ids with no row)
DELETE s FROM `tmp_155f_set` s JOIN `tmp_155f_outside` o ON o.`entry` = s.`entry`;
DELETE s FROM `tmp_155f_set` s LEFT JOIN `creature_template` t ON t.`entry` = s.`entry` WHERE t.`entry` IS NULL;

-- Kael'thas Sunstrider (Magisters' Terrace, normal entry 24664): 72 -> 78
UPDATE `tmp_155f_set` SET `level_offset` = 6 WHERE `entry` = 24664;

-- ---- save originals, then raise ---------------------------------------------
CREATE TABLE IF NOT EXISTS `basic_155f_level_backup` (
  `entry`    int unsigned     NOT NULL,
  `minlevel` tinyint unsigned NOT NULL,
  `maxlevel` tinyint unsigned NOT NULL,
  PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155f: original creature levels, for the revert';
INSERT IGNORE INTO `basic_155f_level_backup` (`entry`, `minlevel`, `maxlevel`)
SELECT t.`entry`, t.`minlevel`, t.`maxlevel`
FROM `creature_template` t JOIN `tmp_155f_set` s ON s.`entry` = t.`entry`;

-- the offsets actually applied, kept for scripts/validate-basic-state
DROP TABLE IF EXISTS `basic_155f_templates`;
CREATE TABLE `basic_155f_templates` (
  `entry`        int unsigned NOT NULL,
  `level_offset` tinyint      NOT NULL,
  PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155f: raised templates and their level offset';
INSERT INTO `basic_155f_templates` SELECT `entry`, `level_offset` FROM `tmp_155f_set`;

-- first every saved template back to its original (so a template that left
-- the set, or the old flat 64, doesn't linger), then original + offset
UPDATE `creature_template` t
JOIN `basic_155f_level_backup` b ON b.`entry` = t.`entry`
SET t.`minlevel` = b.`minlevel`, t.`maxlevel` = b.`maxlevel`;
UPDATE `creature_template` t
JOIN `basic_155f_level_backup` b ON b.`entry` = t.`entry`
JOIN `basic_155f_templates` s ON s.`entry` = t.`entry`
SET t.`minlevel` = b.`minlevel` + s.`level_offset`, t.`maxlevel` = b.`maxlevel` + s.`level_offset`;

-- ---- dungeon gear wearable at 60 (Ritz, 2026-09-23) -------------------------
-- "if any of the gear dropped requires higher than level 60, we should set
-- it's required level to level 60. This includes greens that might drop in
-- those dungeons." Gear = item class 2 (weapons) and 4 (armor), any
-- quality. Sources, all normal mode (heroic loot is untouched, like heroic
-- mode itself):
--   * the loot tables of every creature raised above (creature_template.lootid);
--   * chests spawned in the dungeons (gameobject type 3, loot id in Data1);
--   * reference tables those point at, followed three levels deep.
-- Required level is an item-wide value, so an item that also drops elsewhere
-- becomes wearable at 60 there too. Harmless on basic, where 60 is the cap.
-- Originals saved; the revert restores them. The client shows the new value
-- once its item cache is refreshed, which C025 (issue 160) arranges.
DROP TABLE IF EXISTS `tmp_155f_loot`;
CREATE TABLE `tmp_155f_loot` (`kind` char(1) NOT NULL, `id` int unsigned NOT NULL, PRIMARY KEY (`kind`, `id`));
-- 'c' creature loot table, 'g' gameobject loot table, 'r' reference table
INSERT IGNORE INTO `tmp_155f_loot`
SELECT 'c', t.`lootid` FROM `creature_template` t JOIN `tmp_155f_set` s ON s.`entry` = t.`entry` WHERE t.`lootid` <> 0;
INSERT IGNORE INTO `tmp_155f_loot`
SELECT 'g', g.`Data1` FROM `gameobject` o JOIN `gameobject_template` g ON g.`entry` = o.`id`
WHERE g.`type` = 3 AND g.`Data1` <> 0 AND o.`map` IN (SELECT `map_id` FROM `basic_155f_maps`);
-- references, three levels
INSERT IGNORE INTO `tmp_155f_loot` SELECT 'r', l.`Reference` FROM `creature_loot_template` l JOIN `tmp_155f_loot` k ON k.`kind` = 'c' AND k.`id` = l.`Entry` WHERE l.`Reference` <> 0;
INSERT IGNORE INTO `tmp_155f_loot` SELECT 'r', l.`Reference` FROM `gameobject_loot_template` l JOIN `tmp_155f_loot` k ON k.`kind` = 'g' AND k.`id` = l.`Entry` WHERE l.`Reference` <> 0;
DROP TABLE IF EXISTS `tmp_155f_ref_step`;
CREATE TABLE `tmp_155f_ref_step` (`id` int unsigned NOT NULL, PRIMARY KEY (`id`));
INSERT IGNORE INTO `tmp_155f_ref_step` SELECT l.`Reference` FROM `reference_loot_template` l JOIN `tmp_155f_loot` k ON k.`kind` = 'r' AND k.`id` = l.`Entry` WHERE l.`Reference` <> 0;
INSERT IGNORE INTO `tmp_155f_loot` SELECT 'r', `id` FROM `tmp_155f_ref_step`;
DELETE FROM `tmp_155f_ref_step`;
INSERT IGNORE INTO `tmp_155f_ref_step` SELECT l.`Reference` FROM `reference_loot_template` l JOIN `tmp_155f_loot` k ON k.`kind` = 'r' AND k.`id` = l.`Entry` WHERE l.`Reference` <> 0;
INSERT IGNORE INTO `tmp_155f_loot` SELECT 'r', `id` FROM `tmp_155f_ref_step`;

CREATE TABLE IF NOT EXISTS `basic_155f_item_backup` (
  `entry`         int unsigned     NOT NULL,
  `RequiredLevel` tinyint unsigned NOT NULL,
  PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155f: original required levels of dungeon gear, for the revert';

INSERT IGNORE INTO `basic_155f_item_backup` (`entry`, `RequiredLevel`)
SELECT DISTINCT i.`entry`, i.`RequiredLevel` FROM `item_template` i
WHERE i.`class` IN (2, 4) AND i.`RequiredLevel` > 60
  AND i.`entry` IN (
        SELECT l.`Item` FROM `creature_loot_template`  l JOIN `tmp_155f_loot` k ON k.`kind` = 'c' AND k.`id` = l.`Entry` WHERE l.`Reference` = 0
  UNION SELECT l.`Item` FROM `gameobject_loot_template` l JOIN `tmp_155f_loot` k ON k.`kind` = 'g' AND k.`id` = l.`Entry` WHERE l.`Reference` = 0
  UNION SELECT l.`Item` FROM `reference_loot_template`  l JOIN `tmp_155f_loot` k ON k.`kind` = 'r' AND k.`id` = l.`Entry` WHERE l.`Reference` = 0);

UPDATE `item_template` i JOIN `basic_155f_item_backup` b ON b.`entry` = i.`entry`
SET i.`RequiredLevel` = 60;

DROP TABLE `tmp_155f_ref_step`;
DROP TABLE `tmp_155f_loot`;
DROP TABLE `tmp_155f_found`;
DROP TABLE `tmp_155f_script_ids`;
DROP TABLE `tmp_155f_set`;
DROP TABLE `tmp_155f_outside`;
DROP TABLE `tmp_155f_inside`;

-- ============================================================================
-- End of 09-outland-dungeons-64.sql (apply)
-- ============================================================================
