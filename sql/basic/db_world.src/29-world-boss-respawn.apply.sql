-- MARKER_E046_APPLY basic-world-boss-respawn
-- ============================================================================
-- 29-world-boss-respawn.sql (issue 155j) — APPLY SOURCE
-- ============================================================================
-- The world bosses stop respawning on the server's own timer. Their return
-- is decided by src/lua-basic/world-boss-respawn.lua (a countdown of about
-- 2.5 hours that runs slower while players are in the boss's area) and
-- carried out by src/cpp-basic/basic_rules.cpp (".basic worldboss respawn").
-- Owner, 2026-09-27: "Can we change their respawn time to 2.5 hours? +/-
-- some percentage, slower if players are in the area" / "1% slower per
-- player, recalculated every increment (5s or so) manual spawning through
-- lua".
--
-- basic_155j_world_bosses: the list, one row per spawn (both scripts read
-- it; the one place a world boss is named):
--   guid                 the spawn (creature.guid)
--   entry                its creature (creature.id)
--   stock_spawntimesecs  the stock respawn delay, kept for the revert
--
-- Which bosses: the open-world raid bosses the server itself treats as
-- world bosses (boss flag, fought as 3 levels above their target):
-- Doom Lord Kazzak (18728), Doomwalker (17711), Azuregos (6109) and the
-- four Emerald Dragons Ysondre, Lethon, Emeriss, Taerar (14887-14890).
-- Each has one fixed spawn in the stock world database (the dragons do
-- not rotate between spots there; each has its own spot and ~10-day
-- timer), so each keeps its own countdown. The Fel Reaver is not one yet:
-- its rework into a world boss is 155j's later step 2.
--
-- The stock delay is set to a year, so the server never brings one back by
-- itself; the Lua countdown does.
--
-- Doom Lord Kazzak made four times his size (owner, 2026-09-27: "Can we
-- scale up his model 4x and have him take steps that have an animation
-- speed proportional to how 'right' it feels when his legs move a step
-- forward at his immense size? Large enough to be 6 people tall, at
-- least."):
--   size    his model's scale (creature_template_model.DisplayScale) 1 -> 4,
--           on top of the 4.5 his display already carries;
--   reach   the server multiplies his melee reach and body radius by that
--           scale (Creature::SetObjectScale), which would let him hit, and
--           be hit, from 64 yards; his display's model row (17887, used by
--           him alone) is divided by 4, so after the scale both stay stock
--           (reach 15.75, radius 9): players still hit him standing where
--           they did. A hitbox that fits his new size waits for the custom
--           client (owner: "gotta design a new kind of hitbox for him, but
--           we'll figure that out later");
--   steps   the client plays his walk and run at the speed that keeps his
--           feet planted (movement speed / (the animation's own speed x his
--           size)), so the speed sets how fast his legs cycle. Twice his
--           speeds: large walkers keep the same gait when speed grows with
--           the square root of their size (4x size -> 2x speed), which keeps
--           his step rate what a creature four times smaller would feel
--           like at half the speed. Walk 5 -> 10 yards a second, run 10 ->
--           20. To be judged in game.
-- basic_155j_kazzak_stock keeps the stock values for the revert. Re-applicable: INSERT IGNORE keeps the
-- first saved (stock) delay, so a second apply does not save the year.
-- Database: acore_world_basic. Applied by E046.
-- ============================================================================

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

-- from the saved stock values, so a second apply does not grow him again
UPDATE `creature_template_model` m JOIN `basic_155j_kazzak_stock` s ON s.`id` = 1
SET m.`DisplayScale` = s.`DisplayScale` * 4
WHERE m.`CreatureID` = 18728 AND m.`Idx` = 0;
UPDATE `creature_template` t JOIN `basic_155j_kazzak_stock` s ON s.`id` = 1
SET t.`speed_walk` = s.`speed_walk` * 2, t.`speed_run` = s.`speed_run` * 2
WHERE t.`entry` = 18728;
UPDATE `creature_model_info` i JOIN `basic_155j_kazzak_stock` s ON s.`id` = 1
SET i.`BoundingRadius` = s.`BoundingRadius` / 4, i.`CombatReach` = s.`CombatReach` / 4
WHERE i.`DisplayID` = 17887;

-- ============================================================================
-- End of 29-world-boss-respawn.sql (apply)
-- ============================================================================
