-- MARKER_E038_REVERT basic-outland-one-door
-- ============================================================================
-- 23-outland-one-door.sql (issue 155l) — REVERT SOURCE
-- ============================================================================
-- The portals between Outland and the rest of the world, and the capitals'
-- portals to the Blasted Lands, back where they stood.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_155l_portals` LIKE `gameobject`;
INSERT IGNORE INTO `gameobject` SELECT * FROM `basic_155l_portals`;
DROP TABLE `basic_155l_portals`;

-- ============================================================================
-- End of 23-outland-one-door.sql (revert)
-- ============================================================================
