-- MARKER_E036_APPLY basic-white-durability

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

