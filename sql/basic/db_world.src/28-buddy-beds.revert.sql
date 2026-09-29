-- MARKER_E045_REVERT basic-buddy-beds
-- ============================================================================
-- 28-buddy-beds.sql (issue 617e4) — REVERT SOURCE
-- ============================================================================
-- Removes the beds table. Beds placed in game since the last
-- scripts/export-buddy-beds are lost with it; export first.
-- ============================================================================

DROP TABLE IF EXISTS `buddy_bed`;

-- ============================================================================
-- End of 28-buddy-beds.sql (revert)
-- ============================================================================
