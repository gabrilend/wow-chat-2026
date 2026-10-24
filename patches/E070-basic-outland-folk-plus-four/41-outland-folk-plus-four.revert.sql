-- MARKER_E070_REVERT basic-outland-folk-plus-four
-- ============================================================================
-- 41-outland-folk-plus-four.sql (issue 155z1) - REVERT
-- Written by hand on 2026-10-23. Puts back the levels E070 saved and drops
-- its table. A database that never ran the apply has nothing saved: the
-- table made here is empty and dropped again.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_e070_levels` (
  `entry`        int unsigned     NOT NULL,
  `minlevel`     tinyint unsigned NOT NULL,
  `maxlevel`     tinyint unsigned NOT NULL,
  `level_offset` tinyint unsigned NOT NULL,
  PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

UPDATE `creature_template` t JOIN `basic_e070_levels` b ON b.`entry` = t.`entry`
SET t.`minlevel` = b.`minlevel`, t.`maxlevel` = b.`maxlevel`;

DROP TABLE `basic_e070_levels`;
