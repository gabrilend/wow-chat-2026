-- MARKER_E076_APPLY basic-buddy-solo-record

CREATE TABLE IF NOT EXISTS `buddy_solo_record` (
    `buddy`       INT UNSIGNED     NOT NULL,
    `kind`        TINYINT UNSIGNED NOT NULL,
    `foe_health`  FLOAT            NOT NULL,
    `foe_dps`     FLOAT            NOT NULL,
    `health_lost` FLOAT            NOT NULL,
    `mana_spent`  FLOAT            NOT NULL,
    `seconds`     FLOAT            NOT NULL,
    `gold_cost`   FLOAT            NOT NULL,
    `won`         INT UNSIGNED     NOT NULL DEFAULT 0,
    PRIMARY KEY (`buddy`, `kind`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='623: the hardest fight each buddy has won alone';

