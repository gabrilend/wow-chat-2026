-- MARKER_E069_APPLY basic-portal-demons-halfway
-- ============================================================================
-- 40-portal-demons-halfway.sql (issue 155z, a stopgap before the front) - APPLY
-- Written by hand on 2026-10-23 (four rows; no generator needed).
-- ============================================================================
-- The Dark Portal's stock event sends waves of demons up the Stair of
-- Destiny at level 70 to 76, all elite (Fel Soldier 70, Infernal
-- Siegebreaker 70, Wrath Master 75 and Pit Commander 76 on basic, the last
-- two raised four levels by E032), against players arriving at 58 to 60.
-- The owner, 2026-10-23, offered "bring the wave demons down to the
-- player's level (around 58-62)": "let's bring them down halfway." So each
-- moves halfway from its level before this step toward 60:
--   Fel Soldier, Infernal Siegebreaker  70 -> 65
--   Wrath Master                        75 -> 68 (67.5, rounded up)
--   Pit Commander                       76 -> 68
-- They stay elite. They give no experience and drop nothing (the server's
-- "no experience" flag is set on all four, and they have no loot), as
-- stock; only their levels change.
--
-- The levels before this step are saved in basic_e069_levels the first
-- time it runs, and the new levels are always worked out from the saved
-- ones, so running it twice changes nothing more. The revert puts the
-- saved levels back and drops the table. Must run after E032 (Outland
-- world levels), whose +4 it builds on: its priority is higher.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_e069_levels` (
  `entry`    int unsigned     NOT NULL,
  `minlevel` tinyint unsigned NOT NULL,
  `maxlevel` tinyint unsigned NOT NULL,
  PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155z: the Stair of Destiny demons'' levels before E069';

INSERT IGNORE INTO `basic_e069_levels` (`entry`, `minlevel`, `maxlevel`)
SELECT `entry`, `minlevel`, `maxlevel` FROM `creature_template`
WHERE `entry` IN (18944, 18945, 18946, 19005);   -- Fel Soldier, Pit Commander, Infernal Siegebreaker, Wrath Master

UPDATE `creature_template` t JOIN `basic_e069_levels` b ON b.`entry` = t.`entry`
SET t.`minlevel` = CEIL((b.`minlevel` + 60) / 2),
    t.`maxlevel` = CEIL((b.`maxlevel` + 60) / 2);
