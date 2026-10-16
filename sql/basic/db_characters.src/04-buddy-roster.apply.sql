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
--   stage              (617a6) 0 with its owner; 1 waiting: its slot is
--                      above the owner's level, so it stays out of the
--                      world until the owner reaches the buddy's own level;
--                      4 recording: its slot is kept but it is above the
--                      owner's level, so it is recorded first; 3 remake:
--                      made again at the owner's level at its next login,
--                      then 0; 5 set aside (718): a death knight owner's
--                      buddy waiting for its death-knight level (55, 57,
--                      59, 60), moved to 3 by sargobras.lua when the
--                      owner reaches it; the buddy module neither logs
--                      in nor re-stages a 5
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

-- the stage column (617a6, 2026-10-03), the same way
SET @has_stage := (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'buddy_roster' AND column_name = 'stage');
SET @add_stage := IF(@has_stage = 0,
  'ALTER TABLE `buddy_roster` ADD COLUMN `stage` tinyint unsigned NOT NULL DEFAULT 0 AFTER `greeting`',
  'DO 0');
PREPARE add_stage FROM @add_stage;
EXECUTE add_stage;
DEALLOCATE PREPARE add_stage;

-- The stage record (617a6): a buddy as it was when its owner's level went
-- below it (whether it then waits or is made again), kept for the later
-- level-scaling
-- (the owner, 2026-10-03: "we *wouldn't* want to re-instantiate the
-- buddy-bots, hence why we're recording their equipment and such at the
-- time of the player character's de-levelling"). One record per buddy, the
-- newest; written by the buddy module (buddies_stage.cpp) in one
-- transaction, a few seconds after the buddy's logout save.
--   buddy_stage_record   level, experience (xp), money (copper), recorded
--                        (unix time)
--   buddy_stage_item     every item it wore or carried: item (its id as it
--                        was), bag (the id of the bag it sat in, 0 for the
--                        body and backpack; that bag is in the record too),
--                        slot, entry, count, enchantments (enchants and
--                        gems, as item_instance keeps them), random
--                        (its random suffix, "of the Bear"), durability
--   buddy_stage_spell    every spell it knew
--   buddy_stage_talent   every talent it had, and in which spec (specMask)
CREATE TABLE IF NOT EXISTS `buddy_stage_record` (
  `buddy`    int unsigned     NOT NULL,
  `level`    tinyint unsigned NOT NULL,
  `xp`       int unsigned     NOT NULL,
  `money`    int unsigned     NOT NULL,
  `recorded` int unsigned     NOT NULL,
  PRIMARY KEY (`buddy`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 617a6: a stored buddy as it was';

CREATE TABLE IF NOT EXISTS `buddy_stage_item` (
  `buddy`        int unsigned      NOT NULL,
  `item`         int unsigned      NOT NULL,
  `bag`          int unsigned      NOT NULL,
  `slot`         tinyint unsigned  NOT NULL,
  `entry`        int unsigned      NOT NULL,
  `count`        int unsigned      NOT NULL,
  `enchantments` text              NOT NULL,
  `random`       int               NOT NULL,
  `durability`   smallint unsigned NOT NULL,
  PRIMARY KEY (`buddy`, `item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 617a6: a stored buddy''s items';

CREATE TABLE IF NOT EXISTS `buddy_stage_spell` (
  `buddy` int unsigned NOT NULL,
  `spell` int unsigned NOT NULL,
  PRIMARY KEY (`buddy`, `spell`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 617a6: a stored buddy''s spells';

CREATE TABLE IF NOT EXISTS `buddy_stage_talent` (
  `buddy`    int unsigned     NOT NULL,
  `spell`    int unsigned     NOT NULL,
  `specMask` tinyint unsigned NOT NULL,
  PRIMARY KEY (`buddy`, `spell`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 617a6: a stored buddy''s talents';

-- buddy_draw (617c3, 2026-09-29): the dungeon draw's bag, a row per owner
-- and buddy; had_turn 1 once drawn into a dungeon party, all back to 0 when
-- too few are left to draw
CREATE TABLE IF NOT EXISTS `buddy_draw` (
  `owner`    int unsigned     NOT NULL,
  `buddy`    int unsigned     NOT NULL,
  `had_turn` tinyint unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`owner`, `buddy`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 617c3: the dungeon draw bag';

-- buddy_price (617h, 2026-09-30): the auction house's rising-price memory,
-- shared by every buddy selling at the same house (pool: the auction house's
-- id, 2 Alliance, 6 Horde, 7 neutral). steps: unsold expiries in a row;
-- last_price: copper per unit, the last listing's, raised by half the vendor
-- price per expiry; a sale puts steps back to 0.
CREATE TABLE IF NOT EXISTS `buddy_price` (
  `pool`       tinyint unsigned NOT NULL,
  `item`       int unsigned     NOT NULL,
  `steps`      tinyint unsigned NOT NULL DEFAULT 0,
  `last_price` int unsigned     NOT NULL DEFAULT 0,
  `updated`    int unsigned     NOT NULL DEFAULT 0,
  PRIMARY KEY (`pool`, `item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 617h: rising auction prices';

-- buddy_fixed_price (617h): the owner's hand-kept prices, copper per unit,
-- for items with no vendor price (rare items); an item without a row is
-- not auctioned. Filled by hand. Kept here with the other buddy tables
-- (617a's data model placed it in the world database).
CREATE TABLE IF NOT EXISTS `buddy_fixed_price` (
  `item`  int unsigned NOT NULL,
  `price` int unsigned NOT NULL,
  `note`  varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 617h: fixed auction prices';

-- buddy_retired_node (617e3, 2026-10-02): herb and ore spawn spots no
-- walking path reaches within 3 yards of, found by a buddy about to walk to
-- one. Every spawn at the spot (each ore or herb variant there) gets a row;
-- the buddy module keeps them out of their pools from then on, for
-- everyone (buddies_nodes.cpp). Written by the module; deleting a row
-- returns its spot at the next restart.
--   spawn    the game-object spawn (acore_world.gameobject.guid)
--   entry    its template, map and x, y, z: where it stood, for reading
--   retired  unix time it was retired
--   buddy    the buddy that found it (characters.guid)
CREATE TABLE IF NOT EXISTS `buddy_retired_node` (
  `spawn`   int unsigned      NOT NULL,
  `entry`   int unsigned      NOT NULL,
  `map`     smallint unsigned NOT NULL,
  `x`       float             NOT NULL,
  `y`       float             NOT NULL,
  `z`       float             NOT NULL,
  `retired` int unsigned      NOT NULL,
  `buddy`   int unsigned      NOT NULL,
  PRIMARY KEY (`spawn`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 617e3: unreachable gathering spots';

-- buddy_stowed_weapon (617e4b, 2026-10-15): the weapons a buddy put in its
-- bags on entering a town, to wear again on leaving it (bare-handed in
-- town, sheathed in the wilds, drawn in danger). Kept here rather than in
-- memory so a restart in town forgets nothing. Written by the buddy module
-- (buddies_arms.cpp); a row is removed when its weapon is worn again.
--   buddy  the buddy (characters.guid)
--   slot   15 main hand, 16 off hand, 17 ranged
--   item   the item (item_instance.guid)
CREATE TABLE IF NOT EXISTS `buddy_stowed_weapon` (
  `buddy` int unsigned     NOT NULL,
  `slot`  tinyint unsigned NOT NULL,
  `item`  int unsigned     NOT NULL,
  PRIMARY KEY (`buddy`, `slot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 617e4b: weapons put away in town';

-- ============================================================================
-- End of 04-buddy-roster.sql (apply)
-- ============================================================================
