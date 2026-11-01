-- MARKER_E077_APPLY basic-teleport-way-back
-- ============================================================================
-- 08-teleport-way-back.sql (issue 723) — APPLY SOURCE
-- ============================================================================
-- Written by hand with the issue (a table, not data). The way back from a
-- mage's city teleport: where the caster stood just before their latest
-- cast of that teleport away from its city (one step back, the owner,
-- 2026-10-30: "the most recent place they were at"). Written and read by
-- src/lua-basic/buddy-hearth.lua; a cast inside the city sends the caster
-- there.
--
-- teleport_way_back: one row per caster and teleport spell
--   guid         the caster (characters.guid)
--   spell        the teleport's spell id (data/teleport-destinations.lua)
--   map, x, y, z, o   where they stood when they cast it
-- ============================================================================

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

-- ============================================================================
-- End of 08-teleport-way-back.sql (apply)
-- ============================================================================
