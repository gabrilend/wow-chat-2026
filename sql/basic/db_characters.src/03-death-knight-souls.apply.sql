-- MARKER_E041_APPLY basic-death-knight-souls

CREATE TABLE IF NOT EXISTS `basic_718_souls` (
  `dk`              int unsigned     NOT NULL,
  `soul`            int unsigned     NOT NULL DEFAULT 0,
  `soul_account`    int unsigned     NOT NULL DEFAULT 0,
  `holding_account` int unsigned     NOT NULL DEFAULT 0,
  `state`           tinyint unsigned NOT NULL DEFAULT 0,
  `changed`         int unsigned     NOT NULL DEFAULT 0,
  PRIMARY KEY (`dk`),
  KEY `idx_soul` (`soul`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 718: death knight souls given to Sargobras';

SET @has_skipped := (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'basic_718_souls' AND column_name = 'skipped');
SET @add_skipped := IF(@has_skipped = 0,
  'ALTER TABLE `basic_718_souls` ADD COLUMN `skipped` tinyint unsigned NOT NULL DEFAULT 0 AFTER `changed`',
  'DO 0');
PREPARE add_skipped FROM @add_skipped;
EXECUTE add_skipped;
DEALLOCATE PREPARE add_skipped;

CREATE TABLE IF NOT EXISTS `basic_718_maxed` (
  `dk`    int unsigned      NOT NULL,
  `skill` smallint unsigned NOT NULL,
  PRIMARY KEY (`dk`, `skill`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 718: professions maxed at training';

