-- MARKER_E060_REVERT beta-moonglade-return
-- ============================================================================
-- 01-moonglade-return.sql (issue 211a) — REVERT SOURCE
-- ============================================================================
-- Drops the remembered spots. Druids keep Teleport: Moonglade (a known
-- spell); it simply goes to Nighthaven every time again.
-- ============================================================================

DROP TABLE IF EXISTS `beta_211a_moonglade_return`;

-- ============================================================================
-- End of 01-moonglade-return.sql (revert)
-- ============================================================================
