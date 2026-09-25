-- MARKER_E026_REVERT basic-creature-multipliers
-- ============================================================================
-- 11-creature-multipliers.sql (issue 155i) — REVERT SOURCE
-- ============================================================================
-- Drop the multiplier table. Its rows are tuning values; anyone reverting
-- who wants to keep them should dump the table first
-- (SELECT * FROM basic_creature_multipliers).
-- ============================================================================

DROP TABLE IF EXISTS `basic_creature_multipliers`;

-- ============================================================================
-- End of 11-creature-multipliers.sql (revert)
-- ============================================================================
