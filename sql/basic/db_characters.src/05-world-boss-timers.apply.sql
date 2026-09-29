-- MARKER_E047_APPLY basic-world-boss-timers
-- ============================================================================
-- 05-world-boss-timers.sql (issue 155j) — APPLY SOURCE
-- ============================================================================
-- Each world boss's state and countdown, kept here so a restart doesn't
-- lose them (the characters database holds the realm's running state; the
-- world database holds content). The bosses are listed in the world table
-- basic_155j_world_bosses (E046).
--
-- basic_world_boss_timer: one row per boss spawn
--   guid     the spawn (creature.guid in the world database)
--   alive    1 alive (or due to load alive), 0 dead and counting down.
--            Written by basic_rules.cpp: 0 when the boss dies, 1 when it is
--            brought back.
--   elapsed  seconds since it died, counted in the Lua's passes (5 s each).
--            Written by world-boss-respawn.lua.
--   tokens   "moment tokens": each pass deposits one per player present in
--            the boss's area (owner, 2026-09-27). The boss is due when
--            elapsed >= 2.5 hours + tokens x 5 s / 100, so each player
--            present holds it back 1% of every pass, and 100 present hold it
--            forever. Written by the Lua.
-- A boss with no row is taken as alive (basic_rules.cpp adds the row at
-- startup).
-- Re-applicable: CREATE IF NOT EXISTS keeps rows already written.
-- Database: acore_characters_basic. Applied by E047.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_world_boss_timer` (
    `guid`    INT UNSIGNED NOT NULL,
    `alive`   TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `elapsed` INT UNSIGNED NOT NULL DEFAULT 0,
    `tokens`  INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='155j: world boss countdowns (world-boss-respawn.lua, basic_rules.cpp)';

-- ============================================================================
-- End of 05-world-boss-timers.sql (apply)
-- ============================================================================
