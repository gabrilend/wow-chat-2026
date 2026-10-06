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
--   dealt_in_batch  re-deals into current_valley so far (155d1; see below)
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

-- dealt_in_batch (155d1, 2026-10-05): arrivals in current_valley from the
-- valley Sargobras's "Actually, can I go somewhere else?" since the batch
-- began. The Lua script adds one per deal into the faction's current valley
-- (an atomic +1, never a read-then-write); the creation handler (B028)
-- counts count_in_batch + dealt_in_batch against the batch of 30 and sets
-- this back to 0 when it draws the next valley. A separate column, because
-- B028 keeps count_in_batch in memory and writes it whole, which would
-- overwrite a +1 made beside it.
SET @has_dealt := (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'basic_starting_valley_rotation' AND column_name = 'dealt_in_batch');
SET @add_dealt := IF(@has_dealt = 0,
  'ALTER TABLE `basic_starting_valley_rotation` ADD COLUMN `dealt_in_batch` int unsigned NOT NULL DEFAULT 0 AFTER `count_in_batch`',
  'DO 0');
PREPARE add_dealt FROM @add_dealt;
EXECUTE add_dealt;
DEALLOCATE PREPARE add_dealt;
