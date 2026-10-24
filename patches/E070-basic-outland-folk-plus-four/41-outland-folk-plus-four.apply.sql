-- MARKER_E070_APPLY basic-outland-folk-plus-four
-- ============================================================================
-- 41-outland-folk-plus-four.sql (issue 155z1) - APPLY
-- Written by hand on 2026-10-23 (one rule; the template list is worked out
-- by the SQL itself from the world database at apply time).
-- ============================================================================
-- Outland's friendly people (guards, vendors, townspeople, the Dark
-- Portal's defenders) get the same raise E032 gave its monsters: +4 levels,
-- +6 on the Isle of Quel'Danas. The owner, 2026-10-04: "can you make the
-- guards and townspeople in Outland be roughly scaled to the threats they
-- are to diminish? It should be an even fight"; asked how (a radius and the
-- median threat near each), 2026-10-23: "just give it +4 like we do with the
-- other creatures." And: "let's scale them all, then" (every Outland town).
--
-- Raised: creature templates that
--   * stand only in Outland or on the Isle (map 530, y > -2000 or x > 11350;
--     the same line E032 draws: nothing in Azeroth or Eversong moves);
--   * were not raised by E032 (basic_155k_world_templates: the monsters);
--   * are not world bosses (rank 3), critters (type 8), invisible spell
--     triggers (flags_extra 128), one of 155f's dungeon templates, one of
--     E069's four Dark Portal demons, or one of the project's own creatures
--     (entries 1000000 and up: they set their own levels).
-- +6 when every spawn of the template is on the Isle, otherwise +4.
-- Health, damage and armor follow the new level as for any creature of it.
--
-- The levels before this step are saved in basic_e070_levels the first
-- time it runs, and the new levels are always worked out from the saved
-- ones, so running it twice changes nothing more. The revert puts them
-- back. Runs after E024 (155f's templates), E032 (its list) and E069.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_e070_levels` (
  `entry`        int unsigned     NOT NULL,
  `minlevel`     tinyint unsigned NOT NULL,
  `maxlevel`     tinyint unsigned NOT NULL,
  `level_offset` tinyint unsigned NOT NULL,
  PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155z1: friendly Outland templates raised by E070, their levels before it and their step';

INSERT IGNORE INTO `basic_e070_levels` (`entry`, `minlevel`, `maxlevel`, `level_offset`)
SELECT t.`entry`, t.`minlevel`, t.`maxlevel`, IF(MIN(c.`position_x`) > 11350, 6, 4)
FROM `creature` c
JOIN `creature_template` t ON t.`entry` = c.`id`
WHERE t.`rank` <> 3 AND t.`type` <> 8 AND (t.`flags_extra` & 128) = 0
  AND t.`entry` < 1000000
  AND t.`entry` NOT IN (SELECT `entry` FROM `basic_155k_world_templates`)
  AND t.`entry` NOT IN (SELECT `entry` FROM `basic_155f_templates`)
  AND t.`entry` NOT IN (18944, 18945, 18946, 19005)      -- E069's demons
GROUP BY t.`entry`
HAVING SUM(NOT (c.`map` = 530 AND (c.`position_y` > -2000 OR c.`position_x` > 11350))) = 0;

UPDATE `creature_template` t JOIN `basic_e070_levels` b ON b.`entry` = t.`entry`
SET t.`minlevel` = b.`minlevel` + b.`level_offset`,
    t.`maxlevel` = b.`maxlevel` + b.`level_offset`;
