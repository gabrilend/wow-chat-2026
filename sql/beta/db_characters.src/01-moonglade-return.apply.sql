-- MARKER_E060_APPLY beta-moonglade-return
-- ============================================================================
-- 01-moonglade-return.sql (issue 211a) — APPLY SOURCE
-- ============================================================================
-- Each druid's way back from Moonglade: where they stood when they last
-- cast Teleport: Moonglade, or the entrance of the dungeon they cast it in,
-- so a cast inside Moonglade can send them back there. Written and read by
-- src/lua-beta/druid-moonglade.lua; a row is removed when the druid goes
-- back, or when their way back is not known (nothing to return to).
--
--   guid      the druid (characters.guid)
--   map       map number (0, 1, 530 or 571: the open world)
--   x, y, z   position, yards
--   o         facing, radians
--
-- Re-applicable: CREATE IF NOT EXISTS keeps the spots already remembered.
-- Database: acore_characters_beta. Applied by E060.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `beta_211a_moonglade_return` (
  `guid` int unsigned      NOT NULL,
  `map`  smallint unsigned NOT NULL,
  `x`    float             NOT NULL,
  `y`    float             NOT NULL,
  `z`    float             NOT NULL,
  `o`    float             NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 211a: where a druid returns to from Moonglade';

-- The druids' visitors: one row per player a druid brought to the glade,
-- removed when the visitor goes back or leaves on their own. Kept here,
-- not only in the server's memory, so a restart while visitors are in the
-- glade still sends them back (the owner, 2026-10-18: "sure").
--
--   guid        the visitor (characters.guid)
--   druid       the druid who brought them (characters.guid)
--   map, x, y, z, o   where the visitor goes back to
--   left_glade  1 once the druid has left while the visitor was offline:
--               they go back at their next login
CREATE TABLE IF NOT EXISTS `beta_211a_moonglade_visitors` (
  `guid`       int unsigned      NOT NULL,
  `druid`      int unsigned      NOT NULL,
  `map`        smallint unsigned NOT NULL,
  `x`          float             NOT NULL,
  `y`          float             NOT NULL,
  `z`          float             NOT NULL,
  `o`          float             NOT NULL DEFAULT 0,
  `left_glade` tinyint unsigned  NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`),
  KEY `druid` (`druid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 211a: who a druid brought to Moonglade, and their way back';

-- ============================================================================
-- End of 01-moonglade-return.sql (apply)
-- ============================================================================
