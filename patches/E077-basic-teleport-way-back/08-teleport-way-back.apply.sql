-- MARKER_E077_APPLY basic-teleport-way-back

CREATE TABLE IF NOT EXISTS `teleport_way_back` (
    `guid`  INT UNSIGNED      NOT NULL,
    `spell` INT UNSIGNED      NOT NULL,
    `map`   SMALLINT UNSIGNED NOT NULL,
    `x`     FLOAT             NOT NULL,
    `y`     FLOAT             NOT NULL,
    `z`     FLOAT             NOT NULL,
    `o`     FLOAT             NOT NULL,
    PRIMARY KEY (`guid`, `spell`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='723: the way back from a city teleport';

