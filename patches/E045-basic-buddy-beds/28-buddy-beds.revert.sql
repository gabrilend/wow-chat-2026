-- MARKER_E045_REVERT basic-buddy-beds
-- ============================================================================
-- 28-buddy-beds.sql (issue 617e4) — REVERT SOURCE
-- ============================================================================
-- Removes the beds table and the boarding recordings (617e9). Beds placed
-- and boardings recorded in game since the last scripts/export-buddy-beds
-- and scripts/export-buddy-boardings are lost with them; export first.
-- ============================================================================

DROP TABLE IF EXISTS `buddy_bed`;
DROP TABLE IF EXISTS `buddy_boarding_step`;
DROP TABLE IF EXISTS `buddy_boarding`;

-- ============================================================================
-- End of 28-buddy-beds.sql (revert)
-- ============================================================================
