-- MARKER_E031_APPLY basic-outland-gear-scaling
-- ============================================================================
-- 16-outland-gear-scaling.sql (issues 155k, 155f) — APPLY SOURCE
-- ============================================================================
-- Brings Outland's gear onto basic's level-60 ladder by rescaling each item's
-- numbers (same item, same look, same loot table; Ritz, 2026-09-24: "scale
-- the drops according to ilevel, and try to keep them proportionally at the
-- same position in the new range that they were in the old range").
--
-- Scale used throughout: an item's stat budget by quality and item level L
--   green (L - 4) / 2     blue (L - 1.84) / 1.6     epic (L - 1.3) / 1.3
-- and "≈ epic" = the epic item level with the same budget.
--
-- Which items (weapons and armor, item level 80+, Burning Crusade gear):
--   * the open world: loot of creatures standing in Outland or on the Isle of
--     Quel'Danas (map 530, y > -2000 or x > 11350), world bosses (rank 3)
--     left out (155j: they stay stock), reference tables three levels deep;
--   * the sixteen dungeons of 155f, normal mode only (spawn mask bit 1):
--     loot of their raised templates spawned there or named by the dungeon's
--     script (the GENERATED list below), and of the chests spawned there.
--
-- Rules, one per item (the first that fits):
--   g  every green: ≈ epic 47 at item level 84 ... 72 at 116, linear
--      (Hellfire Peninsula's greens ≈ level-60 dungeon blues, the Isle's ≈
--      the Emerald Dragons). Extends past the ends the same way.
--   w  a blue from the open world (also if it drops in a dungeon: "they
--      should be scaled according to how they are scaled in the world"):
--      ≈ epic 60 at 85 ... 83 at 115, linear; and it becomes bind on pickup.
--   d  a blue only from dungeons, dropping in an upper dungeon: its budget
--      times target ÷ top, where top is the budget of that dungeon's best
--      stock blue (item level 115 in most, 103 in Old Hillsbrad) and target
--      the budget of the dungeon's ≈ epic on the ladder
--      (basic_155k_dungeon_targets). So each dungeon's best blue lands on
--      its target and the rest keep their distance below it. In several
--      upper dungeons: the smallest of their scales.
--   k  Kael'thas's item-level-110 epics (normal Magisters' Terrace): item
--      level 100, the same as the rare world epics.
--   r  everything else in those sets (the lower six dungeons' blues, the
--      rare item-level-100 epics): budget unchanged.
-- Then, for every rule:
--   * stats × new budget ÷ old budget; rating stats (types 12–37 and 44)
--     also × 0.6335 — the Burning Crusade rating discount (155f: 14 crit
--     rating is 1% at 60, 22.1 at 70; "Sounds good");
--   * armor, shield block and weapon damage × new item level ÷ old;
--   * required level 60 where it was higher.
-- Not scaled, by design or because they live in the client:
--   * random-suffix stats ("of the Invoker"): the server derives them from
--     the item level when the item drops, so they follow the new item level
--     by themselves (without the rating discount);
--   * equip and proc spells (their numbers are in the client's Spell.dbc);
--   * sockets and socket bonuses (open question in 155k; kept as they are).
-- Every changed column is saved (basic_155k_item_backup); each apply first
-- restores them and computes from the stock values, so re-applying and a
-- changed item set are both exact. Required level is restored only where
-- this file lowered it (stock > 60), so the order this revert and 155f's run
-- in doesn't matter.
-- Database: acore_world_basic. Applied by E031, after E024 (155f), whose
-- template list it reads.
-- ============================================================================

-- ---- 0. put back what an earlier apply changed ----------------------------------
CREATE TABLE IF NOT EXISTS `basic_155k_item_backup` (PRIMARY KEY (`entry`))
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155k: stock values of every column the gear scaler changes, for the revert'
SELECT `entry`, `ItemLevel`, `RequiredLevel`, `bonding`, `armor`, `block`,
       `dmg_min1`, `dmg_max1`, `dmg_min2`, `dmg_max2`,
       `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`,
       `stat_value1`, `stat_value2`, `stat_value3`, `stat_value4`, `stat_value5`,
       `stat_value6`, `stat_value7`, `stat_value8`, `stat_value9`, `stat_value10`
FROM `item_template` LIMIT 0;

UPDATE `item_template` i JOIN `basic_155k_item_backup` b ON b.`entry` = i.`entry`
SET i.`ItemLevel` = b.`ItemLevel`, i.`bonding` = b.`bonding`, i.`armor` = b.`armor`, i.`block` = b.`block`,
    i.`dmg_min1` = b.`dmg_min1`, i.`dmg_max1` = b.`dmg_max1`, i.`dmg_min2` = b.`dmg_min2`, i.`dmg_max2` = b.`dmg_max2`,
    i.`holy_res` = b.`holy_res`, i.`fire_res` = b.`fire_res`, i.`nature_res` = b.`nature_res`,
    i.`frost_res` = b.`frost_res`, i.`shadow_res` = b.`shadow_res`, i.`arcane_res` = b.`arcane_res`,
    i.`stat_value1` = b.`stat_value1`, i.`stat_value2` = b.`stat_value2`, i.`stat_value3` = b.`stat_value3`,
    i.`stat_value4` = b.`stat_value4`, i.`stat_value5` = b.`stat_value5`, i.`stat_value6` = b.`stat_value6`,
    i.`stat_value7` = b.`stat_value7`, i.`stat_value8` = b.`stat_value8`, i.`stat_value9` = b.`stat_value9`,
    i.`stat_value10` = b.`stat_value10`;
UPDATE `item_template` i JOIN `basic_155k_item_backup` b ON b.`entry` = i.`entry`
SET i.`RequiredLevel` = b.`RequiredLevel` WHERE b.`RequiredLevel` > 60;
DELETE FROM `basic_155k_item_backup`;

-- ---- 1. the ladder's targets for the upper dungeons ------------------------------
-- ≈ epic item level of each upper dungeon's blues (155f's ladder, Ritz,
-- 2026-09-24). The lower six (Ramparts to Auchenai Crypts) keep their budgets.
DROP TABLE IF EXISTS `basic_155k_dungeon_targets`;
CREATE TABLE `basic_155k_dungeon_targets` (
  `map_id`      smallint unsigned NOT NULL,
  `target_epic` tinyint unsigned  NOT NULL,
  `name`        varchar(32)       NOT NULL,
  `stock_top`   smallint          NULL     COMMENT 'item level of the dungeon''s best stock blue',
  `scale`       double            NULL     COMMENT 'target budget / budget of stock_top',
  PRIMARY KEY (`map_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155k: ≈ epic item level each upper dungeon''s blues are scaled to';
INSERT INTO `basic_155k_dungeon_targets` (`map_id`, `target_epic`, `name`) VALUES
  (560, 83, 'Old Hillsbrad'),   (556, 84, 'Sethekk Halls'),      (269, 85, 'Black Morass'),
  (555, 86, 'Shadow Labyrinth'),(540, 87, 'Shattered Halls'),    (545, 88, 'Steamvault'),
  (554, 89, 'Mechanar'),        (553, 90, 'Botanica'),           (552, 91, 'Arcatraz'),
  (585, 92, 'Magisters'' Terrace');

-- ---- 2. the dungeons' normal-mode loot, by dungeon ------------------------------
DROP TABLE IF EXISTS `tmp_155f_script_ids`;
CREATE TABLE `tmp_155f_script_ids` (`entry` int unsigned NOT NULL, `map_id` smallint unsigned NOT NULL, PRIMARY KEY (`entry`, `map_id`));
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

-- 'c' creature loot table, 'g' chest loot table, 'r' reference table; per map
DROP TABLE IF EXISTS `tmp_155k_dsrc`;
CREATE TABLE `tmp_155k_dsrc` (`kind` char(1) NOT NULL, `id` int unsigned NOT NULL, `map_id` smallint unsigned NOT NULL, PRIMARY KEY (`kind`, `id`, `map_id`));
INSERT IGNORE INTO `tmp_155k_dsrc`
SELECT 'c', t.`lootid`, c.`map` FROM `creature` c
JOIN `creature_template` t ON t.`entry` = c.`id` JOIN `basic_155f_templates` s ON s.`entry` = t.`entry`
WHERE t.`lootid` <> 0 AND (c.`spawnMask` & 1) AND c.`map` IN (SELECT `map_id` FROM `basic_155f_maps`);
INSERT IGNORE INTO `tmp_155k_dsrc`
SELECT 'c', t.`lootid`, x.`map_id` FROM `tmp_155f_script_ids` x
JOIN `creature_template` t ON t.`entry` = x.`entry` JOIN `basic_155f_templates` s ON s.`entry` = t.`entry`
WHERE t.`lootid` <> 0;
INSERT IGNORE INTO `tmp_155k_dsrc`
SELECT 'g', g.`Data1`, o.`map` FROM `gameobject` o JOIN `gameobject_template` g ON g.`entry` = o.`id`
WHERE g.`type` = 3 AND g.`Data1` <> 0 AND (o.`spawnMask` & 1) AND o.`map` IN (SELECT `map_id` FROM `basic_155f_maps`);
INSERT IGNORE INTO `tmp_155k_dsrc` SELECT 'r', l.`Reference`, k.`map_id` FROM `creature_loot_template` l   JOIN `tmp_155k_dsrc` k ON k.`kind` = 'c' AND k.`id` = l.`Entry` WHERE l.`Reference` <> 0;
INSERT IGNORE INTO `tmp_155k_dsrc` SELECT 'r', l.`Reference`, k.`map_id` FROM `gameobject_loot_template` l JOIN `tmp_155k_dsrc` k ON k.`kind` = 'g' AND k.`id` = l.`Entry` WHERE l.`Reference` <> 0;
DROP TABLE IF EXISTS `tmp_155k_step`;
CREATE TABLE `tmp_155k_step` (`id` int unsigned NOT NULL, `map_id` smallint unsigned NOT NULL, PRIMARY KEY (`id`, `map_id`));
INSERT IGNORE INTO `tmp_155k_step` SELECT l.`Reference`, k.`map_id` FROM `reference_loot_template` l JOIN `tmp_155k_dsrc` k ON k.`kind` = 'r' AND k.`id` = l.`Entry` WHERE l.`Reference` <> 0;
INSERT IGNORE INTO `tmp_155k_dsrc` SELECT 'r', `id`, `map_id` FROM `tmp_155k_step`;
DELETE FROM `tmp_155k_step`;
INSERT IGNORE INTO `tmp_155k_step` SELECT l.`Reference`, k.`map_id` FROM `reference_loot_template` l JOIN `tmp_155k_dsrc` k ON k.`kind` = 'r' AND k.`id` = l.`Entry` WHERE l.`Reference` <> 0;
INSERT IGNORE INTO `tmp_155k_dsrc` SELECT 'r', `id`, `map_id` FROM `tmp_155k_step`;

DROP TABLE IF EXISTS `tmp_155k_ditems`;
CREATE TABLE `tmp_155k_ditems` (`item` int unsigned NOT NULL, `map_id` smallint unsigned NOT NULL, PRIMARY KEY (`item`, `map_id`));
INSERT IGNORE INTO `tmp_155k_ditems` SELECT l.`Item`, k.`map_id` FROM `creature_loot_template` l   JOIN `tmp_155k_dsrc` k ON k.`kind` = 'c' AND k.`id` = l.`Entry` WHERE l.`Reference` = 0;
INSERT IGNORE INTO `tmp_155k_ditems` SELECT l.`Item`, k.`map_id` FROM `gameobject_loot_template` l JOIN `tmp_155k_dsrc` k ON k.`kind` = 'g' AND k.`id` = l.`Entry` WHERE l.`Reference` = 0;
INSERT IGNORE INTO `tmp_155k_ditems` SELECT l.`Item`, k.`map_id` FROM `reference_loot_template` l  JOIN `tmp_155k_dsrc` k ON k.`kind` = 'r' AND k.`id` = l.`Entry` WHERE l.`Reference` = 0;

-- ---- 3. the open world's loot ---------------------------------------------------
DROP TABLE IF EXISTS `tmp_155k_wsrc`;
CREATE TABLE `tmp_155k_wsrc` (`kind` char(1) NOT NULL, `id` int unsigned NOT NULL, PRIMARY KEY (`kind`, `id`));
INSERT IGNORE INTO `tmp_155k_wsrc`
SELECT 'c', t.`lootid` FROM `creature` c JOIN `creature_template` t ON t.`entry` = c.`id`
WHERE t.`lootid` <> 0 AND t.`rank` <> 3
  AND c.`map` = 530 AND (c.`position_y` > -2000 OR c.`position_x` > 11350);
INSERT IGNORE INTO `tmp_155k_wsrc` SELECT 'r', l.`Reference` FROM `creature_loot_template` l JOIN `tmp_155k_wsrc` k ON k.`kind` = 'c' AND k.`id` = l.`Entry` WHERE l.`Reference` <> 0;
DROP TABLE IF EXISTS `tmp_155k_wstep`;
CREATE TABLE `tmp_155k_wstep` (`id` int unsigned NOT NULL, PRIMARY KEY (`id`));
INSERT IGNORE INTO `tmp_155k_wstep` SELECT l.`Reference` FROM `reference_loot_template` l JOIN `tmp_155k_wsrc` k ON k.`kind` = 'r' AND k.`id` = l.`Entry` WHERE l.`Reference` <> 0;
INSERT IGNORE INTO `tmp_155k_wsrc` SELECT 'r', `id` FROM `tmp_155k_wstep`;
DELETE FROM `tmp_155k_wstep`;
INSERT IGNORE INTO `tmp_155k_wstep` SELECT l.`Reference` FROM `reference_loot_template` l JOIN `tmp_155k_wsrc` k ON k.`kind` = 'r' AND k.`id` = l.`Entry` WHERE l.`Reference` <> 0;
INSERT IGNORE INTO `tmp_155k_wsrc` SELECT 'r', `id` FROM `tmp_155k_wstep`;

DROP TABLE IF EXISTS `tmp_155k_witems`;
CREATE TABLE `tmp_155k_witems` (`item` int unsigned NOT NULL, PRIMARY KEY (`item`));
INSERT IGNORE INTO `tmp_155k_witems` SELECT l.`Item` FROM `creature_loot_template` l  JOIN `tmp_155k_wsrc` k ON k.`kind` = 'c' AND k.`id` = l.`Entry` WHERE l.`Reference` = 0;
INSERT IGNORE INTO `tmp_155k_witems` SELECT l.`Item` FROM `reference_loot_template` l JOIN `tmp_155k_wsrc` k ON k.`kind` = 'r' AND k.`id` = l.`Entry` WHERE l.`Reference` = 0;

-- each upper dungeon's best stock blue of its own (weapons and armor; world
-- blues that also drop there follow the world rule, so they don't count),
-- and its scale
UPDATE `basic_155k_dungeon_targets` t SET `stock_top` =
  (SELECT MAX(i.`ItemLevel`) FROM `tmp_155k_ditems` x JOIN `item_template` i ON i.`entry` = x.`item`
   LEFT JOIN `tmp_155k_witems` w ON w.`item` = x.`item`
   WHERE x.`map_id` = t.`map_id` AND i.`Quality` = 3 AND i.`class` IN (2, 4) AND w.`item` IS NULL);
UPDATE `basic_155k_dungeon_targets` SET `scale` = ((`target_epic` - 1.3) / 1.3) / ((`stock_top` - 1.84) / 1.6);

-- ---- 4. one rule per item, and its new item level --------------------------------
DROP TABLE IF EXISTS `basic_155k_items`;
CREATE TABLE `basic_155k_items` (
  `entry`     int unsigned      NOT NULL,
  `rule`      char(1)           NOT NULL COMMENT 'g green, w world blue, d dungeon blue, k Kael''thas epic, r rating discount only',
  `Quality`   tinyint unsigned  NOT NULL,
  `old_ilvl`  smallint          NOT NULL,
  `new_ilvl`  smallint          NOT NULL,
  `scale`     double            NULL     COMMENT 'rule d: the dungeon''s budget scale (smallest if several)',
  `factor`    double            NOT NULL DEFAULT 1 COMMENT 'new budget / old budget',
  `ratio`     double            NOT NULL DEFAULT 1 COMMENT 'new item level / old',
  PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155k: every scaled item, its rule and factors (read by scripts/validate-basic-state)';

INSERT INTO `basic_155k_items` (`entry`, `rule`, `Quality`, `old_ilvl`, `new_ilvl`, `scale`)
SELECT i.`entry`,
       CASE WHEN i.`Quality` = 2                                          THEN 'g'
            WHEN i.`Quality` = 3 AND w.`item` IS NOT NULL                 THEN 'w'
            WHEN i.`Quality` = 3 AND d.`scale` IS NOT NULL                THEN 'd'
            WHEN i.`Quality` = 4 AND i.`ItemLevel` = 110 AND d.`kael` = 1 THEN 'k'
            ELSE 'r' END,
       i.`Quality`, i.`ItemLevel`, i.`ItemLevel`, d.`scale`
FROM `item_template` i
LEFT JOIN `tmp_155k_witems` w ON w.`item` = i.`entry`
LEFT JOIN (SELECT x.`item`, MIN(t.`scale`) AS `scale`, MAX(x.`map_id` = 585) AS `kael`
           FROM `tmp_155k_ditems` x LEFT JOIN `basic_155k_dungeon_targets` t ON t.`map_id` = x.`map_id`
           GROUP BY x.`item`) d ON d.`item` = i.`entry`
WHERE i.`class` IN (2, 4) AND i.`Quality` IN (2, 3, 4) AND i.`ItemLevel` >= 80
  AND (w.`item` IS NOT NULL OR d.`item` IS NOT NULL);

UPDATE `basic_155k_items` SET `new_ilvl` = CASE `rule`
    WHEN 'g' THEN ROUND(2   * ((47 + (`old_ilvl` - 84) * 25 / 32) - 1.3) / 1.3 + 4)
    WHEN 'w' THEN ROUND(1.6 * ((60 + (`old_ilvl` - 85) * 23 / 30) - 1.3) / 1.3 + 1.84)
    WHEN 'd' THEN ROUND((`old_ilvl` - 1.84) * `scale` + 1.84)
    WHEN 'k' THEN 100
    ELSE `old_ilvl` END;
UPDATE `basic_155k_items` SET
  `ratio`  = `new_ilvl` / `old_ilvl`,
  `factor` = CASE `Quality`
    WHEN 2 THEN (`new_ilvl` - 4)    / (`old_ilvl` - 4)
    WHEN 3 THEN (`new_ilvl` - 1.84) / (`old_ilvl` - 1.84)
    ELSE        (`new_ilvl` - 1.3)  / (`old_ilvl` - 1.3) END;

-- ---- 5. save, then scale -----------------------------------------------------------
INSERT INTO `basic_155k_item_backup`
SELECT i.`entry`, i.`ItemLevel`, i.`RequiredLevel`, i.`bonding`, i.`armor`, i.`block`,
       i.`dmg_min1`, i.`dmg_max1`, i.`dmg_min2`, i.`dmg_max2`,
       i.`holy_res`, i.`fire_res`, i.`nature_res`, i.`frost_res`, i.`shadow_res`, i.`arcane_res`,
       i.`stat_value1`, i.`stat_value2`, i.`stat_value3`, i.`stat_value4`, i.`stat_value5`,
       i.`stat_value6`, i.`stat_value7`, i.`stat_value8`, i.`stat_value9`, i.`stat_value10`
FROM `item_template` i JOIN `basic_155k_items` p ON p.`entry` = i.`entry`;

-- a stat keeps its sign and never scales to zero; ratings take the discount
UPDATE `item_template` i JOIN `basic_155k_items` p ON p.`entry` = i.`entry` SET
  i.`stat_value1`  = IF(i.`stat_value1`  = 0, 0, SIGN(i.`stat_value1`)  * GREATEST(1, ROUND(ABS(i.`stat_value1`)  * p.`factor` * IF(i.`stat_type1`  BETWEEN 12 AND 37 OR i.`stat_type1`  = 44, 0.6335, 1)))),
  i.`stat_value2`  = IF(i.`stat_value2`  = 0, 0, SIGN(i.`stat_value2`)  * GREATEST(1, ROUND(ABS(i.`stat_value2`)  * p.`factor` * IF(i.`stat_type2`  BETWEEN 12 AND 37 OR i.`stat_type2`  = 44, 0.6335, 1)))),
  i.`stat_value3`  = IF(i.`stat_value3`  = 0, 0, SIGN(i.`stat_value3`)  * GREATEST(1, ROUND(ABS(i.`stat_value3`)  * p.`factor` * IF(i.`stat_type3`  BETWEEN 12 AND 37 OR i.`stat_type3`  = 44, 0.6335, 1)))),
  i.`stat_value4`  = IF(i.`stat_value4`  = 0, 0, SIGN(i.`stat_value4`)  * GREATEST(1, ROUND(ABS(i.`stat_value4`)  * p.`factor` * IF(i.`stat_type4`  BETWEEN 12 AND 37 OR i.`stat_type4`  = 44, 0.6335, 1)))),
  i.`stat_value5`  = IF(i.`stat_value5`  = 0, 0, SIGN(i.`stat_value5`)  * GREATEST(1, ROUND(ABS(i.`stat_value5`)  * p.`factor` * IF(i.`stat_type5`  BETWEEN 12 AND 37 OR i.`stat_type5`  = 44, 0.6335, 1)))),
  i.`stat_value6`  = IF(i.`stat_value6`  = 0, 0, SIGN(i.`stat_value6`)  * GREATEST(1, ROUND(ABS(i.`stat_value6`)  * p.`factor` * IF(i.`stat_type6`  BETWEEN 12 AND 37 OR i.`stat_type6`  = 44, 0.6335, 1)))),
  i.`stat_value7`  = IF(i.`stat_value7`  = 0, 0, SIGN(i.`stat_value7`)  * GREATEST(1, ROUND(ABS(i.`stat_value7`)  * p.`factor` * IF(i.`stat_type7`  BETWEEN 12 AND 37 OR i.`stat_type7`  = 44, 0.6335, 1)))),
  i.`stat_value8`  = IF(i.`stat_value8`  = 0, 0, SIGN(i.`stat_value8`)  * GREATEST(1, ROUND(ABS(i.`stat_value8`)  * p.`factor` * IF(i.`stat_type8`  BETWEEN 12 AND 37 OR i.`stat_type8`  = 44, 0.6335, 1)))),
  i.`stat_value9`  = IF(i.`stat_value9`  = 0, 0, SIGN(i.`stat_value9`)  * GREATEST(1, ROUND(ABS(i.`stat_value9`)  * p.`factor` * IF(i.`stat_type9`  BETWEEN 12 AND 37 OR i.`stat_type9`  = 44, 0.6335, 1)))),
  i.`stat_value10` = IF(i.`stat_value10` = 0, 0, SIGN(i.`stat_value10`) * GREATEST(1, ROUND(ABS(i.`stat_value10`) * p.`factor` * IF(i.`stat_type10` BETWEEN 12 AND 37 OR i.`stat_type10` = 44, 0.6335, 1)))),
  i.`holy_res`   = ROUND(i.`holy_res`   * p.`factor`), i.`fire_res`   = ROUND(i.`fire_res`   * p.`factor`),
  i.`nature_res` = ROUND(i.`nature_res` * p.`factor`), i.`frost_res`  = ROUND(i.`frost_res`  * p.`factor`),
  i.`shadow_res` = ROUND(i.`shadow_res` * p.`factor`), i.`arcane_res` = ROUND(i.`arcane_res` * p.`factor`),
  i.`armor`    = ROUND(i.`armor` * p.`ratio`),
  i.`block`    = ROUND(i.`block` * p.`ratio`),
  i.`dmg_min1` = ROUND(i.`dmg_min1` * p.`ratio`), i.`dmg_max1` = ROUND(i.`dmg_max1` * p.`ratio`),
  i.`dmg_min2` = ROUND(i.`dmg_min2` * p.`ratio`), i.`dmg_max2` = ROUND(i.`dmg_max2` * p.`ratio`),
  i.`ItemLevel`     = p.`new_ilvl`,
  i.`RequiredLevel` = LEAST(i.`RequiredLevel`, 60),
  -- world blues become bind on pickup (tradeable inside the clan: 617j, C++, later)
  i.`bonding`       = IF(p.`rule` = 'w' AND i.`bonding` = 2, 1, i.`bonding`);

DROP TABLE `tmp_155k_witems`;
DROP TABLE `tmp_155k_wstep`;
DROP TABLE `tmp_155k_wsrc`;
DROP TABLE `tmp_155k_ditems`;
DROP TABLE `tmp_155k_step`;
DROP TABLE `tmp_155k_dsrc`;
DROP TABLE `tmp_155f_script_ids`;

-- ============================================================================
-- End of 16-outland-gear-scaling.sql (apply)
-- ============================================================================
