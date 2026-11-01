-- MARKER_E077_REVERT basic-teleport-way-back
-- ============================================================================
-- 08-teleport-way-back.sql (issue 723) — REVERT SOURCE
-- ============================================================================
-- Drops the table: every remembered way back is forgotten. Nothing else is
-- touched.
-- ============================================================================

DROP TABLE IF EXISTS `teleport_way_back`;

-- ============================================================================
-- End of 08-teleport-way-back.sql (revert)
-- ============================================================================
