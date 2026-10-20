-- MARKER_E047_APPLY basic-world-boss-timers

CREATE TABLE IF NOT EXISTS `basic_world_boss_timer` (
    `guid`    INT UNSIGNED NOT NULL,
    `alive`   TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `elapsed` INT UNSIGNED NOT NULL DEFAULT 0,
    `tokens`  INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='155j: world boss countdowns (world-boss-respawn.lua, basic_rules.cpp)';

