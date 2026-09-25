-- MARKER_E026_APPLY basic-creature-multipliers
-- ============================================================================
-- 11-creature-multipliers.sql (issue 155i) — APPLY SOURCE
-- ============================================================================
-- The table basic's compiled rules (src/cpp-basic/basic_rules.cpp) read at
-- startup, and on ".basic reload multipliers", to scale a creature's damage,
-- healing and health. Tuning a boss is one row here, not a recompile.
--
-- One row per creature template (entry <> 0, map_id = 0), or per instance
-- map (entry = 0, map_id <> 0) as a convenience for "everything in this
-- dungeon". A creature's own row wins over its map's row; a creature with
-- neither is untouched. Players, and anything a player controls, are never
-- scaled.
--
--   melee   its melee hits (after its own bonuses, before the target's armor)
--   spell   its direct spell damage and damage-over-time ticks
--   heal    healing it does or receives (so a boss healing itself is scaled)
--   health  its maximum health, set when it spawns (creature rows only; a
--           map row's health is ignored, because a creature's map is not
--           reliably known at the moment its health is chosen)
--
-- A creature's summons and pets without a row of their own use their
-- owner's row. Values are multipliers: 1 = stock, 0.5 = half, 2 = double.
-- Every change of a value is logged in docs/balance-updates.md with why.
--
-- Rows start empty (Ritz, 2026-09-24, on the world bosses: "I'm not sure if
-- we'll need to scale them. They are raid bosses, after all."); they are
-- filled as fights are tried. Re-applying keeps the table's rows.
-- Database: acore_world_basic. Applied by E026.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_creature_multipliers` (
  `entry`   int unsigned NOT NULL DEFAULT 0 COMMENT 'creature template, or 0 for a map row',
  `map_id`  int unsigned NOT NULL DEFAULT 0 COMMENT 'instance map for a map row, else 0',
  `melee`   float        NOT NULL DEFAULT 1,
  `spell`   float        NOT NULL DEFAULT 1,
  `heal`    float        NOT NULL DEFAULT 1,
  `health`  float        NOT NULL DEFAULT 1,
  `comment` varchar(255) DEFAULT NULL COMMENT 'who, and why this value',
  PRIMARY KEY (`entry`, `map_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155i: per-creature and per-map damage, healing and health multipliers (basic)';

-- ============================================================================
-- End of 11-creature-multipliers.sql (apply)
-- ============================================================================
