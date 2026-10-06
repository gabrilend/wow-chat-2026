-- MARKER_E051_APPLY acherus-choice-vendors
-- ============================================================================
-- 32-acherus-choice-vendors (issue 718) — APPLY SOURCE
-- ============================================================================
-- A death knight who skips the story at Sargobras gets the item the server
-- picks where a story quest offers a choice. The other choices are sold in
-- Acherus instead (owner, 2026-10-04: "we should just sell those quest items
-- at a vendor in Acherus. They should be unsellable, nobody wants to handle
-- them because they know that Acherus wants them back." and "Pick someone
-- noble for the capes, and someone vicious for the weapons").
--
--   Lady Alistra (28471, a death knight trainer in the upper hall):
--     the three cloaks of Tonight We Dine In Havenshire (12679)
--   Instructor Razuvious (28357, the drillmaster beside the Lich King):
--     the two two-handers of The Light of Dawn (12801)
--
-- Price 1 gold each (BuyPrice 10000 copper), and they sell for nothing
-- (SellPrice 0: the client offers no sale for an item worth nothing, and
-- the server refuses one). Owner: "1g each, they sell for no gold."
--
-- npcflag 128 is the vendor flag; it is added with OR so whatever else the
-- creature does (Alistra trains, both give quests) stays.
-- Re-applicable: the vendor rows are cleared and rewritten; flags and
-- prices are set, not added to.
-- Database: acore_world_basic. Applied by E051 via AC's UpdateFetcher.
-- ============================================================================

UPDATE `creature_template` SET `npcflag` = `npcflag` | 128 WHERE `entry` IN (28471, 28357);

DELETE FROM `npc_vendor` WHERE `entry` IN (28471, 28357);
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
  (28471, 0, 39320, 0, 0, 0, 0),   -- Sky Darkener's Shroud of Blood
  (28471, 1, 38664, 0, 0, 0, 0),   -- Sky Darkener's Shroud of the Unholy
  (28471, 2, 39322, 0, 0, 0, 0),   -- Shroud of the North Wind
  (28357, 0, 38632, 0, 0, 0, 0),   -- Greatsword of the Ebon Blade
  (28357, 1, 38633, 0, 0, 0, 0);   -- Greataxe of the Ebon Blade

UPDATE `item_template` SET `BuyPrice` = 10000, `SellPrice` = 0
 WHERE `entry` IN (39320, 38664, 39322, 38632, 38633);
