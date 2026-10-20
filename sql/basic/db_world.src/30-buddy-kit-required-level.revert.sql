-- MARKER_E048_REVERT basic-buddy-kit-required-level
CREATE TABLE IF NOT EXISTS `basic_617a4_kit_originals` (
    `entry`         INT UNSIGNED     NOT NULL PRIMARY KEY,
    `RequiredLevel` TINYINT UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='617a4: required levels before the buddy kit tiers lowered them';
UPDATE item_template it JOIN basic_617a4_kit_originals o ON o.entry = it.entry SET it.RequiredLevel = o.RequiredLevel;
DROP TABLE IF EXISTS basic_617a4_kit_originals;
