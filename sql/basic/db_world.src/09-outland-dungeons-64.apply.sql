-- MARKER_E024_APPLY basic-outland-dungeons-64
-- ============================================================================
-- 09-outland-dungeons-64.sql (issue 155f) — APPLY SOURCE
-- ============================================================================
-- Every Outland dungeon a level-60 character can enter is level 64 inside
-- (owner, 2026-09-23: "anything in Outland that can be reached by a level 60
-- should be scaled to level 64", then: "the open world remains at the default
-- levels. Just the dungeons are modified." and "quests and creatures should
-- be the default level. Only dungeons are affected."). The open world and
-- all quests keep their stock levels. Loot is unchanged; heroic modes are
-- left stock (level 70, keys).
--
-- Why level alone retunes health and damage: stats are computed at spawn as
-- (class/level/expansion base value from creature_classlevelstats) × (the
-- template's HealthModifier / DamageModifier). Raising the level keeps each
-- creature's own multiplier (elites stay elite, bosses stay bosses) at
-- level-64 values. (Creature.cpp: basehp = stats->GenerateHealth(cInfo);
-- health = basehp * healthmod.)
--
-- "Reachable", as data: every Outland instance map whose normal-mode entry
-- (dungeon_access_template, difficulty 0) is level 60 or lower. Stock:
-- Hellfire Ramparts 543, The Blood Furnace 542, The Shattered Halls 540, The
-- Slave Pens 547, The Underbog 546, The Steamvault 545, Mana-Tombs 557,
-- Auchenai Crypts 558, Sethekk Halls 556. Raids and the later dungeons (65+)
-- stay out; the list is computed, not hard-coded.
--
-- Which templates:
--   (a) every template spawned in those dungeons;
--   (b) the creatures those dungeons' C++ instance scripts name, listed below;
--   (c) database-scripted summons and summon groups of anything in the set,
--       followed two levels deep.
--   A template that is ALSO spawned anywhere outside these dungeons (the
--   Outland open world included) is left alone: raising it would raise it
--   there too.
--   Heroic templates are never spawned directly, so they are never picked.
--   Left out on purpose: the Midsummer festival's Ahune encounter in the Slave
--   Pens (holiday content at its own level).
--
-- Originals are saved first; the revert restores them exactly.
-- Schema note: creature.id, not id1 (renamed upstream in 2026_06_16_00).
-- Database: acore_world_basic. Applied by E024.
-- ============================================================================

-- ---- reachable Outland instances ------------------------------------------
CREATE TABLE IF NOT EXISTS `basic_155f_maps` (
  `map_id` int unsigned NOT NULL,
  PRIMARY KEY (`map_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155f: Outland instances a level 60 can enter';
DELETE FROM `basic_155f_maps`;
INSERT INTO `basic_155f_maps` (`map_id`)
SELECT DISTINCT a.`map_id` FROM `dungeon_access_template` a
WHERE a.`difficulty` = 0 AND a.`min_level` <= 60
  AND a.`map_id` IN (540, 542, 543, 544, 545, 546, 547, 548, 550, 552, 553, 554, 555, 556, 557, 558, 564, 565);
  -- ^ every Outland instance map; the level rule picks the reachable ones

-- Working tables are ordinary tables, not TEMPORARY: MySQL refuses to open a
-- temporary table twice in one statement ("Can't reopen table"), and the
-- summon passes below read the set in several subqueries. All are dropped at
-- the end of this file.

-- ---- spawns inside / outside the dungeons ----------------------------------
DROP TABLE IF EXISTS `tmp_155f_inside`;
CREATE TABLE `tmp_155f_inside` (`entry` int unsigned NOT NULL, PRIMARY KEY (`entry`));
INSERT IGNORE INTO `tmp_155f_inside`
SELECT DISTINCT c.`id` FROM `creature` c
WHERE c.`map` IN (SELECT `map_id` FROM `basic_155f_maps`);

DROP TABLE IF EXISTS `tmp_155f_outside`;
CREATE TABLE `tmp_155f_outside` (`entry` int unsigned NOT NULL, PRIMARY KEY (`entry`));
INSERT IGNORE INTO `tmp_155f_outside`
SELECT DISTINCT c.`id` FROM `creature` c
WHERE c.`map` NOT IN (SELECT `map_id` FROM `basic_155f_maps`);

-- ---- the working set --------------------------------------------------------
DROP TABLE IF EXISTS `tmp_155f_set`;
CREATE TABLE `tmp_155f_set` (`entry` int unsigned NOT NULL, PRIMARY KEY (`entry`));

-- (a) spawned in the dungeons
INSERT IGNORE INTO `tmp_155f_set` SELECT `entry` FROM `tmp_155f_inside`;

-- (b) named by the dungeons' C++ scripts (read 2026-09-23 from the nine
--     dungeons' folders under src/server/scripts/Outland).
--     Ahune's Midsummer encounter (25697, 25740, 25745, 25754, 25865, 25961,
--     25964-25966, 25971-25973, 26120, 26121) is deliberately absent.
INSERT IGNORE INTO `tmp_155f_set` (`entry`) VALUES
  -- dungeons
  (16807),(16808),(17083),(17288),(17289),(17290),(17292),(17294),(17295),(17296),
  (17297),(17301),(17307),(17309),(17377),(17380),(17381),(17398),(17427),(17461),
  (17462),(17517),(17536),(17537),(17611),(17653),(17687),(17693),(17695),(17770),
  (17796),(17798),(17917),(17941),(17942),(17951),(17954),(17990),(17991),(18105),
  (18309),(18311),(18313),(18374),(18431),(18441),(19523),(19524),(20709),(20923),
  (20926),(21851),(22299),(23035),(23132),(23134),(23135),(23136);

-- (c) database-scripted summons (smart_scripts action 12) and summon groups
--     (creature_summon_groups, summonerType 0) of anything in the set;
--     scripts keyed by entry (source_type 0, positive), by a specific spawn in
--     the dungeons (negative = -guid), or timed action lists
--     (source_type 9, id = entry * 100 + n). Two passes.
DROP TABLE IF EXISTS `tmp_155f_found`;
CREATE TABLE `tmp_155f_found` (`entry` int unsigned NOT NULL, PRIMARY KEY (`entry`));
INSERT IGNORE INTO `tmp_155f_found`
SELECT s.`action_param1` FROM `smart_scripts` s
WHERE s.`action_type` = 12
  AND (   (s.`source_type` = 0 AND s.`entryorguid` > 0 AND s.`entryorguid` IN (SELECT `entry` FROM `tmp_155f_set`))
       OR (s.`source_type` = 0 AND s.`entryorguid` < 0 AND -s.`entryorguid` IN
              (SELECT c.`guid` FROM `creature` c
               WHERE c.`map` IN (SELECT `map_id` FROM `basic_155f_maps`)))
       OR (s.`source_type` = 9 AND s.`entryorguid` DIV 100 IN (SELECT `entry` FROM `tmp_155f_set`)))
UNION
SELECT g.`entry` FROM `creature_summon_groups` g
WHERE g.`summonerType` = 0 AND g.`summonerId` IN (SELECT `entry` FROM `tmp_155f_set`);
INSERT IGNORE INTO `tmp_155f_set` SELECT `entry` FROM `tmp_155f_found`;

DELETE FROM `tmp_155f_found`;
INSERT IGNORE INTO `tmp_155f_found`
SELECT s.`action_param1` FROM `smart_scripts` s
WHERE s.`action_type` = 12
  AND (   (s.`source_type` = 0 AND s.`entryorguid` > 0 AND s.`entryorguid` IN (SELECT `entry` FROM `tmp_155f_set`))
       OR (s.`source_type` = 9 AND s.`entryorguid` DIV 100 IN (SELECT `entry` FROM `tmp_155f_set`)))
UNION
SELECT g.`entry` FROM `creature_summon_groups` g
WHERE g.`summonerType` = 0 AND g.`summonerId` IN (SELECT `entry` FROM `tmp_155f_set`);
INSERT IGNORE INTO `tmp_155f_set` SELECT `entry` FROM `tmp_155f_found`;

-- never touch a template that also lives outside these dungeons
DELETE s FROM `tmp_155f_set` s JOIN `tmp_155f_outside` o ON o.`entry` = s.`entry`;

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

UPDATE `creature_template` t
JOIN `basic_155f_level_backup` b ON b.`entry` = t.`entry`
SET t.`minlevel` = 64, t.`maxlevel` = 64;

-- ---- dungeon gear wearable at 60 (owner, 2026-09-23) ------------------------
-- "if any of the gear dropped requires higher than level 60, we should set
-- it's required level to level 60. This includes greens that might drop in
-- those dungeons." Gear = item class 2 (weapons) and 4 (armor). Sources, all
-- normal mode (heroic loot is untouched, like heroic mode itself):
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
DROP TABLE `tmp_155f_set`;
DROP TABLE `tmp_155f_outside`;
DROP TABLE `tmp_155f_inside`;

-- ============================================================================
-- End of 09-outland-dungeons-64.sql (apply)
-- ============================================================================
