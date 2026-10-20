-- MARKER_E038_REVERT basic-outland-one-door

CREATE TABLE IF NOT EXISTS `basic_155l_portals` LIKE `gameobject`;
INSERT IGNORE INTO `gameobject` SELECT * FROM `basic_155l_portals`;
DROP TABLE `basic_155l_portals`;

