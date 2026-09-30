-- MARKER_E042_REVERT basic-buddy-roster
-- ============================================================================
-- 04-buddy-roster.sql (issue 617a1) — REVERT SOURCE
-- ============================================================================
-- Drops both tables. The buddy characters and companion accounts they
-- point at are left as they are (ordinary characters on ordinary
-- accounts): deleting characters is not something a revert should do on
-- its own. To remove them first, with the worldserver running: list the
-- companion accounts in the auth database (SELECT id, username FROM account
-- WHERE username LIKE 'BUDDY%') and delete each with the console command
-- ".account delete BUDDY<n>", which deletes its buddies too (617a2).
-- ============================================================================

DROP TABLE IF EXISTS `buddy_fixed_price`;
DROP TABLE IF EXISTS `buddy_price`;
DROP TABLE IF EXISTS `buddy_draw`;
DROP TABLE IF EXISTS `buddy_roster`;
DROP TABLE IF EXISTS `buddy_clan`;

-- ============================================================================
-- End of 04-buddy-roster.sql (revert)
-- ============================================================================
