-- MARKER_E061_REVERT beta-narrator-reading
-- ============================================================================
-- 02-narrator-reading.sql (issue 910a) — REVERT SOURCE
-- ============================================================================
-- Drops the narrators' saved places; the narrators start their books over.
-- Database: acore_characters_beta. Reverted by E061.
-- ============================================================================

DROP TABLE IF EXISTS `beta_910a_narrator_reading`;
