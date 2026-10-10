-- MARKER_E056_APPLY basic-buddy-stand-ins
-- ============================================================================
-- 06-buddy-stand-ins.sql (issue 617t1) — APPLY SOURCE
-- ============================================================================
-- Written by hand with the issue (a table, not data). The kept stand-ins:
-- characters that belong to nobody, made by the buddy module
-- (modules/mod-buddies/src/buddies_stand_ins.cpp) when a scene, a dungeon
-- or a game master asks for one, and kept for the next asker (617t).
--
-- buddy_stand_in: one row per stand-in character
--   guid        the character (characters.guid), on a STANDIN<n> account
--   race, class the game's ids
--   role        0 damage, 1 tank, 2 healer (buddy_roster's numbers)
--   tree        0-2: the talent tree it puts every point into
--   level       its level now (only ever goes up, when it is used)
--   track       its levelling track (617t question 7); 0 until decided
--   uses        times brought into the world
--   made        unix time it was made
--   last_used   unix time it was last brought in; 0 never
-- ============================================================================

CREATE TABLE IF NOT EXISTS `buddy_stand_in` (
    `guid`      INT UNSIGNED     NOT NULL,
    `race`      TINYINT UNSIGNED NOT NULL,
    `class`     TINYINT UNSIGNED NOT NULL,
    `role`      TINYINT UNSIGNED NOT NULL,
    `tree`      TINYINT UNSIGNED NOT NULL,
    `level`     TINYINT UNSIGNED NOT NULL,
    `track`     TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `uses`      INT UNSIGNED     NOT NULL DEFAULT 0,
    `made`      INT UNSIGNED     NOT NULL DEFAULT 0,
    `last_used` INT UNSIGNED     NOT NULL DEFAULT 0,
    PRIMARY KEY (`guid`),
    KEY `kind` (`race`, `class`, `role`, `level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='617t1: the kept stand-ins';

-- ============================================================================
-- End of 06-buddy-stand-ins.sql (apply)
-- ============================================================================
