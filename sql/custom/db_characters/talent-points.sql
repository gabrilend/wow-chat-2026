-- talent-points.sql
-- Adds total_talent_points column to characters table
-- Issue 120: talent-points-level-20-cap
--
-- This column tracks the total talent points a character has earned.
-- Used by levelling.lua to persist talent point state across sessions.
--
-- Run against acore_characters database

-- {{{ Add column if it doesn't exist
-- ALTER TABLE doesn't support IF NOT EXISTS for columns in MySQL
-- Use a procedure to check first

DELIMITER //
DROP PROCEDURE IF EXISTS add_talent_points_column //
CREATE PROCEDURE add_talent_points_column()
BEGIN
    IF NOT EXISTS (
        SELECT * FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name = 'characters'
          AND column_name = 'total_talent_points'
    ) THEN
        ALTER TABLE `characters`
        ADD COLUMN `total_talent_points` INT UNSIGNED NOT NULL DEFAULT 0
        AFTER `talentGroupsCount`;
    END IF;
END //
DELIMITER ;

CALL add_talent_points_column();
DROP PROCEDURE IF EXISTS add_talent_points_column;
-- }}}

-- {{{ Verification query (run manually)
-- DESCRIBE characters total_talent_points;
-- SELECT guid, name, level, total_talent_points FROM characters LIMIT 10;
-- }}}
