-- MARKER_E036_APPLY basic-white-durability
-- ============================================================================
-- 21-white-durability.sql (issue 155p) — APPLY SOURCE
-- ============================================================================
-- White (common-quality) weapons and armor last twice as long on basic, and
-- are never repaired (the repair refusal is source patch B033). Ritz,
-- 2026-09-25: "Is it possible to make it so that white quality items have
-- doubled durability, but can never be repaired?" / "This is a separate
-- patch by the way."
-- Every white weapon and armor piece that has durability: maximum doubled.
-- Stock values saved (basic_155p_durability); each apply first restores
-- them, so re-applying is exact. Database: acore_world_basic. Applied by
-- E036.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_155p_durability` (
  `entry`         int unsigned      NOT NULL,
  `MaxDurability` smallint unsigned NOT NULL,
  PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155p: stock maximum durability of white gear, for the revert';
UPDATE `item_template` i JOIN `basic_155p_durability` b ON b.`entry` = i.`entry` SET i.`MaxDurability` = b.`MaxDurability`;
DELETE FROM `basic_155p_durability`;

INSERT INTO `basic_155p_durability` (`entry`, `MaxDurability`)
SELECT `entry`, `MaxDurability` FROM `item_template`
WHERE `Quality` = 1 AND `class` IN (2, 4) AND `MaxDurability` > 0;
UPDATE `item_template` i JOIN `basic_155p_durability` b ON b.`entry` = i.`entry`
SET i.`MaxDurability` = LEAST(65535, b.`MaxDurability` * 2);

-- ============================================================================
-- End of 21-white-durability.sql (apply)
-- ============================================================================
