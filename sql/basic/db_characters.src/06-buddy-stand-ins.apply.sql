-- MARKER_E056_APPLY basic-buddy-stand-ins

CREATE TABLE IF NOT EXISTS `buddy_stand_in` (
    `guid`      INT UNSIGNED     NOT NULL,
    `race`      TINYINT UNSIGNED NOT NULL,
    `class`     TINYINT UNSIGNED NOT NULL,
    `role`      TINYINT UNSIGNED NOT NULL,
    `profile`   TINYINT UNSIGNED NOT NULL,
    `level`     TINYINT UNSIGNED NOT NULL,
    `track`     TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `uses`      INT UNSIGNED     NOT NULL DEFAULT 0,
    `made`      INT UNSIGNED     NOT NULL DEFAULT 0,
    `last_used` INT UNSIGNED     NOT NULL DEFAULT 0,
    PRIMARY KEY (`guid`),
    KEY `kind` (`race`, `class`, `role`, `level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='617t1: the kept stand-ins';

