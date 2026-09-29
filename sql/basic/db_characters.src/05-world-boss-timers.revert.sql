-- MARKER_E047_REVERT basic-world-boss-timers
-- ============================================================================
-- 05-world-boss-timers.sql (issue 155j) — REVERT SOURCE
-- ============================================================================
-- The countdowns dropped. Note: a boss dead at the time keeps the respawn
-- time the server saved at its death (death + one year, the delay E046
-- set), even after E046's revert restores the stock delay; bring it back
-- by hand (a game master's respawn at the spot) or clear its row in
-- creature_respawn before reverting.
-- ============================================================================

DROP TABLE IF EXISTS `basic_world_boss_timer`;

-- ============================================================================
-- End of 05-world-boss-timers.sql (revert)
-- ============================================================================
