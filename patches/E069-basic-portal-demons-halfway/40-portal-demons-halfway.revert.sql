-- MARKER_E069_REVERT basic-portal-demons-halfway
-- ============================================================================
-- 40-portal-demons-halfway.sql (issue 155z) - REVERT
-- Written by hand on 2026-10-23. Puts back the levels E069 saved and drops
-- its table. A database that never ran the apply has no saved levels:
-- nothing to put back, and the table it creates here is dropped again.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_e069_levels` (
  `entry`    int unsigned     NOT NULL,
  `minlevel` tinyint unsigned NOT NULL,
  `maxlevel` tinyint unsigned NOT NULL,
  PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

UPDATE `creature_template` t JOIN `basic_e069_levels` b ON b.`entry` = t.`entry`
SET t.`minlevel` = b.`minlevel`, t.`maxlevel` = b.`maxlevel`;

DROP TABLE `basic_e069_levels`;
