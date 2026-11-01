-- MARKER_E076_REVERT basic-buddy-solo-record
-- ============================================================================
-- 07-buddy-solo-record.sql (issue 623) — REVERT SOURCE
-- ============================================================================
-- Drops the table: every buddy's solo records are forgotten. Nothing else is
-- touched.
-- ============================================================================

DROP TABLE IF EXISTS `buddy_solo_record`;

-- ============================================================================
-- End of 07-buddy-solo-record.sql (revert)
-- ============================================================================
