-- MARKER_E041_APPLY basic-death-knight-souls
-- ============================================================================
-- 03-death-knight-souls.sql (issue 718) — APPLY SOURCE
-- ============================================================================
-- The soul ledger: one row per death knight created on basic, written at its
-- first login by src/lua-basic/death-knight-souls.lua.
--
--   dk               the death knight (characters.guid)
--   soul             the character it was made from (0 while still owed)
--   soul_account     the account the soul belonged to, to return it to
--   holding_account  the hidden account the soul is held on meanwhile
--   state            0 owed (can't leave Acherus), 1 given, 2 being returned
--   changed          unix time of the last change
--
-- A death knight with no row (made before this rule) is never held.
-- Re-applicable: CREATE IF NOT EXISTS keeps souls already given.
-- Database: acore_characters_basic. Applied by E041.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_718_souls` (
  `dk`              int unsigned     NOT NULL,
  `soul`            int unsigned     NOT NULL DEFAULT 0,
  `soul_account`    int unsigned     NOT NULL DEFAULT 0,
  `holding_account` int unsigned     NOT NULL DEFAULT 0,
  `state`           tinyint unsigned NOT NULL DEFAULT 0,
  `changed`         int unsigned     NOT NULL DEFAULT 0,
  PRIMARY KEY (`dk`),
  KEY `idx_soul` (`soul`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 718: death knight souls given to Sargobras';

-- basic_718_maxed (2026-09-30): the primary professions a death knight
-- player trained that were raised to Artisan 300 at once (owner: "DK players
-- [...] should have maxed professions too, but only for the first ones they
-- train"); at most two rows per death knight, so dropping one and training
-- another doesn't max it again. Professions carried from the soul are not
-- trained and never counted. Written by death-knight-souls.lua.
CREATE TABLE IF NOT EXISTS `basic_718_maxed` (
  `dk`    int unsigned      NOT NULL,
  `skill` smallint unsigned NOT NULL,
  PRIMARY KEY (`dk`, `skill`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 718: professions maxed at training';

-- ============================================================================
-- End of 03-death-knight-souls.sql (apply)
-- ============================================================================
