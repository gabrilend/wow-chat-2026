-- MARKER_E048_REVERT basic-buddy-kit-required-level
-- Restores the saved required levels, then drops the saved copy.
-- Retired 2026-10-05 (617r2): buddies are dressed from gearsets whose items
-- already fit their level, so the level-20 tier's lowered items are put
-- back. Install step E048 now applies this file on every install. Written by
-- scripts/generate-buddy-kit-tiers until then; kept by hand since (the
-- generator is removed). The CREATE makes it safe on a database the apply
-- never touched: an empty saved copy restores nothing.
CREATE TABLE IF NOT EXISTS `basic_617a4_kit_originals` (
    `entry`         INT UNSIGNED     NOT NULL PRIMARY KEY,
    `RequiredLevel` TINYINT UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='617a4: required levels before the buddy kit tiers lowered them';
UPDATE item_template it JOIN basic_617a4_kit_originals o ON o.entry = it.entry SET it.RequiredLevel = o.RequiredLevel;
DROP TABLE IF EXISTS basic_617a4_kit_originals;
