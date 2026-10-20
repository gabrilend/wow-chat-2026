-- MARKER_E061_APPLY beta-narrator-reading

CREATE TABLE IF NOT EXISTS `beta_910a_narrator_reading` (
  `guid`     int unsigned NOT NULL,
  `book`     int unsigned NOT NULL,
  `position` int unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 910a: how far each narrator has read';
