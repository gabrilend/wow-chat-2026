-- MARKER_E042_APPLY basic-buddy-roster

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

SET @has_greeting := (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'buddy_roster' AND column_name = 'greeting');
SET @add_greeting := IF(@has_greeting = 0,
  'ALTER TABLE `buddy_roster` ADD COLUMN `greeting` tinyint unsigned NOT NULL DEFAULT 0 AFTER `created`', 'DO 0');
PREPARE add_greeting FROM @add_greeting;
EXECUTE add_greeting;
DEALLOCATE PREPARE add_greeting;

SET @has_stage := (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'buddy_roster' AND column_name = 'stage');
SET @add_stage := IF(@has_stage = 0,
  'ALTER TABLE `buddy_roster` ADD COLUMN `stage` tinyint unsigned NOT NULL DEFAULT 0 AFTER `greeting`',
  'DO 0');
PREPARE add_stage FROM @add_stage;
EXECUTE add_stage;
DEALLOCATE PREPARE add_stage;

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

CREATE TABLE IF NOT EXISTS `buddy_draw` (
  `owner`    int unsigned     NOT NULL,
  `buddy`    int unsigned     NOT NULL,
  `had_turn` tinyint unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`owner`, `buddy`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 617c3: the dungeon draw bag';

CREATE TABLE IF NOT EXISTS `buddy_price` (
  `pool`       tinyint unsigned NOT NULL,
  `item`       int unsigned     NOT NULL,
  `steps`      tinyint unsigned NOT NULL DEFAULT 0,
  `last_price` int unsigned     NOT NULL DEFAULT 0,
  `updated`    int unsigned     NOT NULL DEFAULT 0,
  PRIMARY KEY (`pool`, `item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 617h: rising auction prices';

CREATE TABLE IF NOT EXISTS `buddy_fixed_price` (
  `item`  int unsigned NOT NULL,
  `price` int unsigned NOT NULL,
  `note`  varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 617h: fixed auction prices';

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

