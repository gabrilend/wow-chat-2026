-- MARKER_E022_APPLY basic-faction-quest-gating
-- ============================================================================
-- 08-faction-quest-gating.sql (issue 155e) — APPLY SOURCE
-- ============================================================================
-- Quests on the basic profile are gated by faction, never by race within a
-- faction. A character can be born in any of its faction's four starting
-- valleys (155d), so it has to be able to take that valley's quests.
--
-- Race masks (quest_template.AllowableRaces, one bit per race):
--   human 1, orc 2, dwarf 4, night elf 8, undead 16, tauren 32, gnome 64,
--   troll 128, blood elf 512, draenei 1024
--   Alliance = 1+4+8+64+1024 = 1101      Horde = 2+16+32+128+512 = 690
--
-- Rule, per quest:
--   mask 0                          → every race; untouched
--   mask names only Alliance races  → 1101
--   mask names only Horde races     → 690
--   mask names races of both sides  → untouched (deliberately cross-faction)
--   mask already 1101 / 690         → untouched (no row written)
--
-- Written as set-based statements against whatever the database holds,
-- not as a precomputed list of quest ids, so upstream updates that add or
-- change quests are covered on the next apply. Every row this changes has
-- its original mask saved first in basic_155e_quest_race_backup, and the
-- revert restores from that table, so the revert is exact.
--
-- Quest-availability conditions (conditions table, source types 19/20 with
-- condition type 16 = race) get the same widening. Stock source-beta has
-- none of these today (checked 2026-09-23); the statements are here so an
-- upstream addition cannot quietly re-introduce a race gate.
--
-- Gossip race conditions (source types 14/15) are NOT widened: they gate
-- dialogue and trainer/vendor options, not quests. See 155e's open
-- questions.
--
-- Database: acore_world_basic. Re-applicable: backup uses INSERT IGNORE, the
-- UPDATEs are no-ops once masks are widened.
-- Applied by the E022 patch (patches/E-patches.sh) via AC's UpdateFetcher.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `basic_155e_quest_race_backup` (
  `ID`             int unsigned NOT NULL,
  `AllowableRaces` int unsigned NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155e: original quest race masks, for the revert';

CREATE TABLE IF NOT EXISTS `basic_155e_condition_race_backup` (
  `SourceTypeOrReferenceId` int NOT NULL,
  `SourceGroup`             int unsigned NOT NULL,
  `SourceEntry`             int NOT NULL,
  `SourceId`                int NOT NULL,
  `ElseGroup`               int unsigned NOT NULL,
  `ConditionTypeOrReference` int NOT NULL,
  `ConditionTarget`         tinyint unsigned NOT NULL,
  `ConditionValue1_orig`    int unsigned NOT NULL,
  `ConditionValue2`         int unsigned NOT NULL,
  `ConditionValue3`         int unsigned NOT NULL,
  PRIMARY KEY (`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue2`,`ConditionValue3`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155e: original race-condition masks, for the revert';

-- ---- quests ---------------------------------------------------------------

-- save originals of every row about to change
INSERT IGNORE INTO `basic_155e_quest_race_backup` (`ID`, `AllowableRaces`)
SELECT `ID`, `AllowableRaces` FROM `quest_template`
WHERE `AllowableRaces` <> 0
  AND ((`AllowableRaces` & ~1101) = 0 AND `AllowableRaces` <> 1101
    OR (`AllowableRaces` & ~690)  = 0 AND `AllowableRaces` <> 690);

-- Alliance-only subsets → whole Alliance
UPDATE `quest_template` SET `AllowableRaces` = 1101
WHERE `AllowableRaces` <> 0 AND (`AllowableRaces` & ~1101) = 0 AND `AllowableRaces` <> 1101;

-- Horde-only subsets → whole Horde
UPDATE `quest_template` SET `AllowableRaces` = 690
WHERE `AllowableRaces` <> 0 AND (`AllowableRaces` & ~690) = 0 AND `AllowableRaces` <> 690;

-- ---- quest-availability race conditions -----------------------------------

INSERT IGNORE INTO `basic_155e_condition_race_backup`
SELECT `SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,
       `ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,`ConditionValue3`
FROM `conditions`
WHERE `SourceTypeOrReferenceId` IN (19, 20) AND `ConditionTypeOrReference` = 16 AND `NegativeCondition` = 0
  AND `ConditionValue1` <> 0
  AND ((`ConditionValue1` & ~1101) = 0 AND `ConditionValue1` <> 1101
    OR (`ConditionValue1` & ~690)  = 0 AND `ConditionValue1` <> 690);

UPDATE `conditions` SET `ConditionValue1` = 1101
WHERE `SourceTypeOrReferenceId` IN (19, 20) AND `ConditionTypeOrReference` = 16 AND `NegativeCondition` = 0
  AND `ConditionValue1` <> 0 AND (`ConditionValue1` & ~1101) = 0 AND `ConditionValue1` <> 1101;

UPDATE `conditions` SET `ConditionValue1` = 690
WHERE `SourceTypeOrReferenceId` IN (19, 20) AND `ConditionTypeOrReference` = 16 AND `NegativeCondition` = 0
  AND `ConditionValue1` <> 0 AND (`ConditionValue1` & ~690) = 0 AND `ConditionValue1` <> 690;

-- ============================================================================
-- End of 08-faction-quest-gating.sql (apply)
-- ============================================================================
