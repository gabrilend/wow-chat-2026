-- MARKER_E060_APPLY beta-moonglade-return

CREATE TABLE IF NOT EXISTS `beta_211a_moonglade_return` (
  `guid` int unsigned      NOT NULL,
  `map`  smallint unsigned NOT NULL,
  `x`    float             NOT NULL,
  `y`    float             NOT NULL,
  `z`    float             NOT NULL,
  `o`    float             NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 211a: where a druid returns to from Moonglade';

CREATE TABLE IF NOT EXISTS `beta_211a_moonglade_visitors` (
  `guid`       int unsigned      NOT NULL,
  `druid`      int unsigned      NOT NULL,
  `map`        smallint unsigned NOT NULL,
  `x`          float             NOT NULL,
  `y`          float             NOT NULL,
  `z`          float             NOT NULL,
  `o`          float             NOT NULL DEFAULT 0,
  `came_dead`  tinyint unsigned  NOT NULL DEFAULT 0,
  `left_glade` tinyint unsigned  NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`),
  KEY `druid` (`druid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 211a: who a druid brought to Moonglade, and their way back';

