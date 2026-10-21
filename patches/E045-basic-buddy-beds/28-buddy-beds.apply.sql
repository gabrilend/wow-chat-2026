-- MARKER_E045_APPLY basic-buddy-beds
-- ============================================================================
-- 28-buddy-beds.sql (issue 617e4) — APPLY SOURCE
-- ============================================================================
-- Beds the buddies sleep on in towns, placed by hand (owner, 2026-09-27:
-- "proper beds. But we can manually place those, I don't think there's data
-- for them in the game yet"). Inn beds are part of the buildings, not
-- objects the server knows, so each bed is a spot: where a game master
-- stood and faced when typing ".buddy bed add" on it.
--
-- The table is kept, never dropped, by this apply: beds placed in game live
-- in it. They are carried into the project by scripts/export-buddy-beds,
-- which rewrites the rows between the BEDS markers below from the live
-- table; this file then puts them back into any fresh install.
--
-- Columns: id (a number), map, x, y, z (world yards), facing (radians, the
-- way the sleeper lies), area (the named area the bed stands in, so a town's
-- buddies find its beds), note (free text, e.g. the inn's name), and
-- (2026-09-27, owner: "I'd prefer the cot over the rug. But if 3 people
-- wanna sleep, then one's going on the ground"):
--   tier  how comfortable the spot is; a buddy takes the best free one:
--           3 bed (a mattress), 2 cot, 1 floor (a rug, a bedroll, the ground)
--   link  0 for a spot on its own; spots sharing a link number are one bed
--         (a double bed): a buddy may take a spot of a linked bed only when
--         no other clan is using that bed ("clanmembers can sleep together
--         but outsiders wouldn't pick that particular spot")
-- Database: acore_world_basic. Applied by E045. Re-applicable.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `buddy_bed` (
    `id`     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `map`    SMALLINT UNSIGNED NOT NULL,
    `x`      FLOAT NOT NULL,
    `y`      FLOAT NOT NULL,
    `z`      FLOAT NOT NULL,
    `facing` FLOAT NOT NULL,
    `area`   INT UNSIGNED NOT NULL,
    `note`   VARCHAR(100) NOT NULL DEFAULT '',
    `tier`   TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `link`   INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `map_area` (`map`, `area`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='617e4: beds buddies sleep on, placed by hand';

-- A table made before the tiers (2026-09-27) gains the two columns; each
-- change runs only when its column is missing, so re-applying is harmless
-- and placed beds are never touched (they start at tier 1, unlinked).
SET @buddy_bed_sql = (SELECT IF(COUNT(*) = 0,
    'ALTER TABLE `buddy_bed` ADD COLUMN `tier` TINYINT UNSIGNED NOT NULL DEFAULT 1',
    'DO 0') FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'buddy_bed' AND column_name = 'tier');
PREPARE buddy_bed_stmt FROM @buddy_bed_sql;
EXECUTE buddy_bed_stmt;
DEALLOCATE PREPARE buddy_bed_stmt;
SET @buddy_bed_sql = (SELECT IF(COUNT(*) = 0,
    'ALTER TABLE `buddy_bed` ADD COLUMN `link` INT UNSIGNED NOT NULL DEFAULT 0',
    'DO 0') FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'buddy_bed' AND column_name = 'link');
PREPARE buddy_bed_stmt FROM @buddy_bed_sql;
EXECUTE buddy_bed_stmt;
DEALLOCATE PREPARE buddy_bed_stmt;

-- >>> BEDS BEGIN (written by scripts/export-buddy-beds; hand edits here are overwritten)
-- (no beds placed yet)
-- <<< BEDS END

-- ----------------------------------------------------------------------------
-- Boarding recordings (issue 617e9, 2026-10-02): a game master's own walk
-- onto a boat or zeppelin (an embark) or off one (a disembark), made in game
-- with ".buddy record start" / ".buddy record stop" and walked by buddies
-- boarding that ship at that dock. Hand-made world data like the beds, so
-- kept here (same install step, E045) and carried into the project by
-- scripts/export-buddy-boardings, which rewrites the rows between the
-- BOARDINGS markers below.
--
-- buddy_boarding: one row per recording
--   id         a number (the commands name recordings by it)
--   kind       1 embark (dock to deck), 2 disembark (deck to dock)
--   transport  the ship (gameobject_template entry of the boat or zeppelin)
--   stop       which stop of the ship's route: the index among its route's
--              waiting points, in the order the client's flight-path data
--              lists them (buddies_crossing.cpp, the transport routes)
--   map        the map of that stop
--   author     the character that recorded it
--   note       free text given to ".buddy record stop"
-- buddy_boarding_step: one row per kept step, in order
--   boarding   the recording (buddy_boarding.id)
--   seq        0, 1, 2 ... in walking order
--   ms         milliseconds from the start of the recording
--   flags      1 on the deck (x, y, z, o are offsets from the ship, not world
--              yards), 2 a jump left from here, 4 a jump or fall landed
--              here, 8 walking (not running) on the way here
--   x, y, z, o world yards and facing (radians), or deck offsets (flag 1)
--   jump_xy,   the jump's sideways and upward speeds (flag 2), as the
--   jump_z     client reported them
-- Re-applicable: the tables are created only when missing, and the exported
-- rows are inserted with INSERT IGNORE, so recordings made in game since the
-- last export are kept.
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `buddy_boarding` (
    `id`        INT UNSIGNED NOT NULL,
    `kind`      TINYINT UNSIGNED NOT NULL,
    `transport` INT UNSIGNED NOT NULL,
    `stop`      TINYINT UNSIGNED NOT NULL,
    `map`       SMALLINT UNSIGNED NOT NULL,
    `author`    VARCHAR(12) NOT NULL DEFAULT '',
    `note`      VARCHAR(100) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`),
    KEY `ship_stop` (`transport`, `stop`, `kind`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='617e9: boarding recordings, made in game';

CREATE TABLE IF NOT EXISTS `buddy_boarding_step` (
    `boarding`  INT UNSIGNED NOT NULL,
    `seq`       SMALLINT UNSIGNED NOT NULL,
    `ms`        INT UNSIGNED NOT NULL,
    `flags`     TINYINT UNSIGNED NOT NULL,
    `x`         FLOAT NOT NULL,
    `y`         FLOAT NOT NULL,
    `z`         FLOAT NOT NULL,
    `o`         FLOAT NOT NULL,
    `jump_xy`   FLOAT NOT NULL DEFAULT 0,
    `jump_z`    FLOAT NOT NULL DEFAULT 0,
    PRIMARY KEY (`boarding`, `seq`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='617e9: the steps of each boarding recording';

-- >>> BOARDINGS BEGIN (written by scripts/export-buddy-boardings; hand edits here are overwritten)
-- (no boardings recorded yet)
-- <<< BOARDINGS END

-- ============================================================================
-- End of 28-buddy-beds.sql (apply)
-- ============================================================================
