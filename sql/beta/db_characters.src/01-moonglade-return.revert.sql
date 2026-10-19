-- MARKER_E060_REVERT beta-moonglade-return
-- ============================================================================
-- 01-moonglade-return.sql (issue 211a) — REVERT SOURCE
-- ============================================================================
-- Drops the remembered ways back and the visitors. Druids keep Teleport:
-- Moonglade (a known spell); it simply goes to Nighthaven every time again.
-- Visitors still in the glade stay there (they have their own Hearthstone).
-- ============================================================================

DROP TABLE IF EXISTS `beta_211a_moonglade_visitors`;
DROP TABLE IF EXISTS `beta_211a_moonglade_return`;

-- ============================================================================
-- End of 01-moonglade-return.sql (revert)
-- ============================================================================
