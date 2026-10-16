-- MARKER_E057_APPLY basic-belt-buckle
-- ============================================================================
-- 37-belt-buckle.sql (issue 624) - APPLY SOURCE
-- ============================================================================
-- The Eternal Belt Buckle (item 41611: "Use: adds a prismatic socket to a
-- belt") usable from level 60 instead of 70, so it exists within basic's
-- level cap (owner, 2026-10-15: "can we lower it to level 60ish?").
--
-- Not here yet: where it comes from. Its stock recipe (spell 55656) is on
-- no trainer and takes Northrend materials (4 Saronite Bars, Eternal
-- Earth, Water and Shadow), which basic doesn't have; the stock game client
-- draws the craft window from its own copy of the recipe, so a server-side
-- change of reagents would still ask for Saronite. A source (the buckle
-- itself as a drop from a world battle, or a recipe once the custom client
-- carries it) is the owner's open choice in 624.
--
-- Database: acore_world_basic. Applied by E057. Re-applicable.
-- ============================================================================

UPDATE `item_template` SET `RequiredLevel` = 60 WHERE `entry` = 41611;
