-- MARKER_E023_APPLY basic-starting-valley-rotation

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

SET @has_dealt := (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'basic_starting_valley_rotation' AND column_name = 'dealt_in_batch');
SET @add_dealt := IF(@has_dealt = 0,
  'ALTER TABLE `basic_starting_valley_rotation` ADD COLUMN `dealt_in_batch` int unsigned NOT NULL DEFAULT 0 AFTER `count_in_batch`',
  'DO 0');
PREPARE add_dealt FROM @add_dealt;
EXECUTE add_dealt;
DEALLOCATE PREPARE add_dealt;
