-- MARKER_E045_APPLY basic-buddy-beds

CREATE TABLE IF NOT EXISTS `buddy_bed` (
    `id`     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `map`    SMALLINT UNSIGNED NOT NULL,
    `x`      FLOAT NOT NULL,
    `y`      FLOAT NOT NULL,
    `z`      FLOAT NOT NULL,
    `facing` FLOAT NOT NULL,
    `area`   INT UNSIGNED NOT NULL,
    `note`   VARCHAR(100) NOT NULL DEFAULT '',
    `tier`   TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `link`   INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `map_area` (`map`, `area`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='617e4: beds buddies sleep on, placed by hand';

SET @buddy_bed_sql = (SELECT IF(COUNT(*) = 0,
    'ALTER TABLE `buddy_bed` ADD COLUMN `tier` TINYINT UNSIGNED NOT NULL DEFAULT 1',
    'DO 0') FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'buddy_bed' AND column_name = 'tier');
PREPARE buddy_bed_stmt FROM @buddy_bed_sql;
EXECUTE buddy_bed_stmt;
DEALLOCATE PREPARE buddy_bed_stmt;
SET @buddy_bed_sql = (SELECT IF(COUNT(*) = 0,
    'ALTER TABLE `buddy_bed` ADD COLUMN `link` INT UNSIGNED NOT NULL DEFAULT 0',
    'DO 0') FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'buddy_bed' AND column_name = 'link');
PREPARE buddy_bed_stmt FROM @buddy_bed_sql;
EXECUTE buddy_bed_stmt;
DEALLOCATE PREPARE buddy_bed_stmt;



CREATE TABLE IF NOT EXISTS `buddy_boarding` (
    `id`        INT UNSIGNED NOT NULL,
    `kind`      TINYINT UNSIGNED NOT NULL,
    `transport` INT UNSIGNED NOT NULL,
    `stop`      TINYINT UNSIGNED NOT NULL,
    `map`       SMALLINT UNSIGNED NOT NULL,
    `author`    VARCHAR(12) NOT NULL DEFAULT '',
    `note`      VARCHAR(100) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`),
    KEY `ship_stop` (`transport`, `stop`, `kind`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='617e9: boarding recordings, made in game';

CREATE TABLE IF NOT EXISTS `buddy_boarding_step` (
    `boarding`  INT UNSIGNED NOT NULL,
    `seq`       SMALLINT UNSIGNED NOT NULL,
    `ms`        INT UNSIGNED NOT NULL,
    `flags`     TINYINT UNSIGNED NOT NULL,
    `x`         FLOAT NOT NULL,
    `y`         FLOAT NOT NULL,
    `z`         FLOAT NOT NULL,
    `o`         FLOAT NOT NULL,
    `jump_xy`   FLOAT NOT NULL DEFAULT 0,
    `jump_z`    FLOAT NOT NULL DEFAULT 0,
    PRIMARY KEY (`boarding`, `seq`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='617e9: the steps of each boarding recording';


