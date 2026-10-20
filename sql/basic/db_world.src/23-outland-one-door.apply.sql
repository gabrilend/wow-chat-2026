-- MARKER_E038_APPLY basic-outland-one-door

CREATE TABLE IF NOT EXISTS `basic_155l_portals` LIKE `gameobject`;
INSERT IGNORE INTO `basic_155l_portals` SELECT * FROM `gameobject` WHERE `id` IN (
  183317, 183321, 183322, 183323, 183324, 183325, 183326, 183327,  -- Shattrath Portal to Darnassus, Exodar, Ironforge, Orgrimmar, Silvermoon, Stormwind, Thunder Bluff, Undercity
  195139, 195140,                                                  -- Portal to Stormwind, Portal to Orgrimmar (Stair of Destiny)
  191013, 191014,                                                  -- Dalaran Portal to Shattrath (Alliance, Horde)
  195141, 195142);                                                 -- Portal to Blasted Lands (Alliance capitals, Horde capitals)
DELETE g FROM `gameobject` g JOIN `basic_155l_portals` p ON p.`guid` = g.`guid`;

