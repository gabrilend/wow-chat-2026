-- MARKER_E023_APPLY basic-starting-valley-rotation
-- ============================================================================
-- 02-starting-valley-rotation.sql (issue 155d) — APPLY SOURCE
-- ============================================================================
-- Rotation state for the basic profile's faction starting valleys, read and
-- advanced by the character-creation handler (source patch B028).
--
--   team            0 = Alliance, 1 = Horde (the core's TeamId values)
--   current_valley  index into that faction's four valleys, or 255 = none
--                   drawn yet (the first creation draws one)
--                     Alliance: 0 Northshire, 1 Coldridge, 2 Shadowglen, 3 Ammen Vale
--                     Horde:    0 Valley of Trials, 1 Deathknell, 2 Camp Narache, 3 Sunstrider Isle
--   count_in_batch  characters placed in current_valley so far (batch = 30)
--   bag             comma-separated valleys not yet used in this cycle
--
-- Re-applicable: CREATE IF NOT EXISTS + INSERT IGNORE, so re-running never
-- resets a rotation already in progress.
-- Database: acore_characters_basic. Applied by E023 via AC's UpdateFetcher.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_starting_valley_rotation` (
  `team`           tinyint unsigned NOT NULL,
  `current_valley` tinyint unsigned NOT NULL DEFAULT 255,
  `count_in_batch` int unsigned     NOT NULL DEFAULT 0,
  `bag`            varchar(16)      NOT NULL DEFAULT '',
  PRIMARY KEY (`team`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155d: rotating faction starting valleys';

INSERT IGNORE INTO `basic_starting_valley_rotation` (`team`, `current_valley`, `count_in_batch`, `bag`) VALUES
  (0, 255, 0, ''),
  (1, 255, 0, '');
