-- MARKER_E030_REVERT basic-darkmoon-cards
-- ============================================================================
-- 15-darkmoon-cards.sql (issue 155o) — REVERT SOURCE
-- ============================================================================
-- Restore the Darkmoon items' stock binding; remove the Burning Crusade card
-- drops (the boss rows and the reference table 1550155, both this file's own).
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_155o_darkmoon_bonding` (`entry` int unsigned NOT NULL, `Bonding` tinyint unsigned NOT NULL, PRIMARY KEY (`entry`));
UPDATE `item_template` i JOIN `basic_155o_darkmoon_bonding` b ON b.`entry` = i.`entry` SET i.`Bonding` = b.`Bonding`;
DELETE FROM `creature_loot_template` WHERE `Item` = 1550155 AND `Reference` = 1550155;
DELETE FROM `reference_loot_template` WHERE `Entry` = 1550155;
DROP TABLE `basic_155o_darkmoon_bonding`;
DROP TABLE IF EXISTS `tmp_155o_bosses`;     -- working tables, in case an apply stopped part-way
DROP TABLE IF EXISTS `tmp_155o_darkmoon`;

-- ============================================================================
-- End of 15-darkmoon-cards.sql (revert)
-- ============================================================================
