-- MARKER_E046_APPLY basic-world-boss-respawn

CREATE TABLE IF NOT EXISTS `basic_155j_world_bosses` (
    `guid`                INT UNSIGNED NOT NULL,
    `entry`               INT UNSIGNED NOT NULL,
    `stock_spawntimesecs` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='155j: world bosses respawned by hand (world-boss-respawn.lua)';

INSERT IGNORE INTO `basic_155j_world_bosses` (`guid`, `entry`, `stock_spawntimesecs`)
SELECT `guid`, `id`, `spawntimesecs` FROM `creature`
WHERE `id` IN (18728, 17711, 6109, 14887, 14888, 14889, 14890);

UPDATE `creature` c JOIN `basic_155j_world_bosses` b ON b.`guid` = c.`guid`
SET c.`spawntimesecs` = 31536000;   -- a year: never, in practice

CREATE TABLE IF NOT EXISTS `basic_155j_kazzak_stock` (
    `id`             TINYINT UNSIGNED NOT NULL,
    `DisplayScale`   FLOAT NOT NULL,
    `speed_walk`     FLOAT NOT NULL,
    `speed_run`      FLOAT NOT NULL,
    `BoundingRadius` FLOAT NOT NULL,
    `CombatReach`    FLOAT NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='155j: Doom Lord Kazzak''s stock size and speeds, for the revert';

INSERT IGNORE INTO `basic_155j_kazzak_stock` (`id`, `DisplayScale`, `speed_walk`, `speed_run`, `BoundingRadius`, `CombatReach`)
SELECT 1, m.`DisplayScale`, t.`speed_walk`, t.`speed_run`, i.`BoundingRadius`, i.`CombatReach`
FROM `creature_template` t
JOIN `creature_template_model` m ON m.`CreatureID` = t.`entry` AND m.`Idx` = 0
JOIN `creature_model_info` i ON i.`DisplayID` = m.`CreatureDisplayID`
WHERE t.`entry` = 18728;

UPDATE `creature_template_model` m JOIN `basic_155j_kazzak_stock` s ON s.`id` = 1
SET m.`DisplayScale` = s.`DisplayScale` * 4
WHERE m.`CreatureID` = 18728 AND m.`Idx` = 0;
UPDATE `creature_template` t JOIN `basic_155j_kazzak_stock` s ON s.`id` = 1
SET t.`speed_walk` = s.`speed_walk` * 2, t.`speed_run` = s.`speed_run` * 2
WHERE t.`entry` = 18728;
UPDATE `creature_model_info` i JOIN `basic_155j_kazzak_stock` s ON s.`id` = 1
SET i.`BoundingRadius` = s.`BoundingRadius` / 4, i.`CombatReach` = s.`CombatReach` / 4
WHERE i.`DisplayID` = 17887;

