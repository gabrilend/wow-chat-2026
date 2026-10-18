-- MARKER_E060_APPLY beta-moonglade-return
-- ============================================================================
-- 01-moonglade-return.sql (issue 211a) — APPLY SOURCE
-- ============================================================================
-- Where each druid stood when they last cast Teleport: Moonglade from the
-- open world, so a cast inside Moonglade can send them back there. Written
-- and read by src/lua-beta/druid-moonglade.lua; a row is removed when the
-- druid goes back, or when they cast it from an instance (nothing to
-- return to).
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

-- ============================================================================
-- End of 01-moonglade-return.sql (apply)
-- ============================================================================
