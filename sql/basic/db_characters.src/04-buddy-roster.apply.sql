-- MARKER_E042_APPLY basic-buddy-roster
-- ============================================================================
-- 04-buddy-roster.sql (issue 617a1) — APPLY SOURCE
-- ============================================================================
-- Who each player's buddies are. Written by the buddy module
-- (modules/mod-buddies) and by the Lua scripts in src/lua-basic/.
--
-- buddy_clan: one row per owner character
--   owner              the owner (characters.guid)
--   companion_account  the owner's hidden account holding its buddies (617a2)
--   clan_guild         the clan guild (617l); 0 until then
--
-- buddy_roster: one row per buddy slot an owner is owed or has filled
--   owner              the owner (characters.guid)
--   slot               1 at creation, 2 at level 10, ... 7 at level 60
--   buddy              the buddy (characters.guid); 0 while the slot is owed
--   class, race        chosen at the selector (617b); 0 until chosen
--   profile            talent shape 1-10 (617g; src/lua-basic/data/
--                      buddy-talent-data.lua); 0 until chosen
--   role               0 damage, 1 tank, 2 healer (the shape's role)
--   talents_reroll     1 while a re-roll is owed from an owner respec made
--                      while this buddy was offline (617g)
--   created            unix time the buddy character was made; 0 until then
--   greeting           its entrance gesture (617b1): 0 none yet, 1 wave,
--                      2 salute; an early personality trait, kept for later
--
-- A row moves through three states: owed (class 0), chosen (class set,
-- buddy 0: the module makes the character), filled (buddy set).
-- Re-applicable: CREATE IF NOT EXISTS keeps rows already written.
-- Database: acore_characters_basic. Applied by E042.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `buddy_clan` (
  `owner`             int unsigned NOT NULL,
  `companion_account` int unsigned NOT NULL DEFAULT 0,
  `clan_guild`        int unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`owner`),
  KEY `idx_account` (`companion_account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 617a: each owner''s companion account and clan';

CREATE TABLE IF NOT EXISTS `buddy_roster` (
  `owner`          int unsigned     NOT NULL,
  `slot`           tinyint unsigned NOT NULL,
  `buddy`          int unsigned     NOT NULL DEFAULT 0,
  `class`          tinyint unsigned NOT NULL DEFAULT 0,
  `race`           tinyint unsigned NOT NULL DEFAULT 0,
  `profile`        tinyint unsigned NOT NULL DEFAULT 0,
  `role`           tinyint unsigned NOT NULL DEFAULT 0,
  `talents_reroll` tinyint unsigned NOT NULL DEFAULT 0,
  `created`        int unsigned     NOT NULL DEFAULT 0,
  `greeting`       tinyint unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`owner`, `slot`),
  KEY `idx_buddy` (`buddy`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 617a: each owner''s buddies, owed and filled';

-- the greeting column (617b1, 2026-09-29) for a table made before it
SET @has_greeting := (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'buddy_roster' AND column_name = 'greeting');
SET @add_greeting := IF(@has_greeting = 0,
  'ALTER TABLE `buddy_roster` ADD COLUMN `greeting` tinyint unsigned NOT NULL DEFAULT 0 AFTER `created`', 'DO 0');
PREPARE add_greeting FROM @add_greeting;
EXECUTE add_greeting;
DEALLOCATE PREPARE add_greeting;

-- ============================================================================
-- End of 04-buddy-roster.sql (apply)
-- ============================================================================
