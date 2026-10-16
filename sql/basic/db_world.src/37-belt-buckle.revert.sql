-- MARKER_E057_REVERT basic-belt-buckle
-- ============================================================================
-- 37-belt-buckle.sql (issue 624) - REVERT SOURCE: the buckle back to level 70
-- ============================================================================
UPDATE `item_template` SET `RequiredLevel` = 70 WHERE `entry` = 41611;
