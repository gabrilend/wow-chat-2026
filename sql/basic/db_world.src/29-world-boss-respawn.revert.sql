-- MARKER_E046_REVERT basic-world-boss-respawn
-- ============================================================================
-- 29-world-boss-respawn.sql (issue 155j) — REVERT SOURCE
-- ============================================================================
-- The world bosses' stock respawn delays back; the list dropped. A table
-- already gone (never applied) is made empty first, so the revert runs.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_155j_world_bosses` (
    `guid`                INT UNSIGNED NOT NULL,
    `entry`               INT UNSIGNED NOT NULL,
    `stock_spawntimesecs` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

UPDATE `creature` c JOIN `basic_155j_world_bosses` b ON b.`guid` = c.`guid`
SET c.`spawntimesecs` = b.`stock_spawntimesecs`;

DROP TABLE `basic_155j_world_bosses`;

-- Doom Lord Kazzak back to his stock size, speeds and reach
CREATE TABLE IF NOT EXISTS `basic_155j_kazzak_stock` (
    `id`             TINYINT UNSIGNED NOT NULL,
    `DisplayScale`   FLOAT NOT NULL,
    `speed_walk`     FLOAT NOT NULL,
    `speed_run`      FLOAT NOT NULL,
    `BoundingRadius` FLOAT NOT NULL,
    `CombatReach`    FLOAT NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
UPDATE `creature_template_model` m JOIN `basic_155j_kazzak_stock` s ON s.`id` = 1
SET m.`DisplayScale` = s.`DisplayScale` WHERE m.`CreatureID` = 18728 AND m.`Idx` = 0;
UPDATE `creature_template` t JOIN `basic_155j_kazzak_stock` s ON s.`id` = 1
SET t.`speed_walk` = s.`speed_walk`, t.`speed_run` = s.`speed_run` WHERE t.`entry` = 18728;
UPDATE `creature_model_info` i JOIN `basic_155j_kazzak_stock` s ON s.`id` = 1
SET i.`BoundingRadius` = s.`BoundingRadius`, i.`CombatReach` = s.`CombatReach` WHERE i.`DisplayID` = 17887;
DROP TABLE `basic_155j_kazzak_stock`;

-- ============================================================================
-- End of 29-world-boss-respawn.sql (revert)
-- ============================================================================
