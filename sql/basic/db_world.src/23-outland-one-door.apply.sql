-- MARKER_E038_APPLY basic-outland-one-door
-- ============================================================================
-- 23-outland-one-door.sql (issue 155l) — APPLY SOURCE
-- ============================================================================
-- The Dark Portal is the only door between Outland and the rest of the
-- world. Ritz, 2026-09-25: "we should disable all portals to and from
-- Outland, except the Dark Portal. Yes it's a long walk, but I think that's
-- part of it." / on the capitals' portals to the Blasted Lands: "yeah they
-- should go".
--
-- Removed (every spawn of each; read from the stock world database
-- 2026-09-25, clickable portals):
--   Shattrath's eight portals to the capitals;
--   the two on the Stair of Destiny back to Stormwind and Orgrimmar;
--   Dalaran's two portals to Shattrath (Northrend is closed on basic, 155s;
--     removed anyway so opening Northrend later opens no back door);
--   the capitals' portals to the Blasted Lands (four spawns each), which
--     stay in Azeroth but skip the walk to the Dark Portal.
-- Kept on purpose: hearthstones bound in Outland, and the mage's Teleport:
-- Shattrath ("actually this one can stay"). The Shattrath portal to the
-- Isle was removed earlier (E028). None of these spawns has addon or event
-- rows. Spawns saved (basic_155l_portals) for the revert; re-applying finds
-- them already gone. Database: acore_world_basic. Applied by E038.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_155l_portals` LIKE `gameobject`;
INSERT IGNORE INTO `basic_155l_portals` SELECT * FROM `gameobject` WHERE `id` IN (
  183317, 183321, 183322, 183323, 183324, 183325, 183326, 183327,  -- Shattrath Portal to Darnassus, Exodar, Ironforge, Orgrimmar, Silvermoon, Stormwind, Thunder Bluff, Undercity
  195139, 195140,                                                  -- Portal to Stormwind, Portal to Orgrimmar (Stair of Destiny)
  191013, 191014,                                                  -- Dalaran Portal to Shattrath (Alliance, Horde)
  195141, 195142);                                                 -- Portal to Blasted Lands (Alliance capitals, Horde capitals)
DELETE g FROM `gameobject` g JOIN `basic_155l_portals` p ON p.`guid` = g.`guid`;

-- ============================================================================
-- End of 23-outland-one-door.sql (apply)
-- ============================================================================
