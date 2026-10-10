-- MARKER_E056_REVERT basic-buddy-stand-ins
-- ============================================================================
-- 06-buddy-stand-ins.sql (issue 617t1) — REVERT SOURCE
-- ============================================================================
-- Drops the table. The stand-in characters and their STANDIN<n> accounts are
-- left as they are (deleting characters is not something a revert should do
-- on its own). To remove them first, with the worldserver running: list the
-- accounts in the auth database (SELECT id, username FROM account WHERE
-- username LIKE 'STANDIN%') and delete each with the console command
-- ".account delete STANDIN<n>", which deletes its characters too.
-- ============================================================================

DROP TABLE IF EXISTS `buddy_stand_in`;

-- ============================================================================
-- End of 06-buddy-stand-ins.sql (revert)
-- ============================================================================
