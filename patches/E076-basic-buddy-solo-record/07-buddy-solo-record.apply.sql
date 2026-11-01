-- MARKER_E076_APPLY basic-buddy-solo-record
-- ============================================================================
-- 07-buddy-solo-record.sql (issue 623) — APPLY SOURCE
-- ============================================================================
-- Written by hand with the issue (a table, not data). The solo record: for
-- each buddy, the hardest fight it has won entirely alone, one per kind of
-- foe (the creature's own class: warrior, paladin, rogue, mage). Written by
-- the buddy module (modules/mod-buddies/src/buddies_solo.cpp) when a solo
-- win is more in every number than the one kept (roam/buddy_solo_core.h),
-- read when it weighs a foe it might face.
--
-- buddy_solo_record: one row per buddy and kind
--   buddy        the buddy (characters.guid)
--   kind         0 warrior, 1 paladin, 2 rogue, 3 mage (BuddySolo::Kind)
--   foe_health   the foe's health at the start (points)
--   foe_dps      the damage per second it dealt the buddy
--   health_lost  health the buddy lost (points)
--   mana_spent   mana or its resource spent (points)
--   seconds      how long the fight took
--   gold_cost    consumables used, in copper
--   won          unix time the record was set
-- ============================================================================

CREATE TABLE IF NOT EXISTS `buddy_solo_record` (
    `buddy`       INT UNSIGNED     NOT NULL,
    `kind`        TINYINT UNSIGNED NOT NULL,
    `foe_health`  FLOAT            NOT NULL,
    `foe_dps`     FLOAT            NOT NULL,
    `health_lost` FLOAT            NOT NULL,
    `mana_spent`  FLOAT            NOT NULL,
    `seconds`     FLOAT            NOT NULL,
    `gold_cost`   FLOAT            NOT NULL,
    `won`         INT UNSIGNED     NOT NULL DEFAULT 0,
    PRIMARY KEY (`buddy`, `kind`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='623: the hardest fight each buddy has won alone';

-- ============================================================================
-- End of 07-buddy-solo-record.sql (apply)
-- ============================================================================
