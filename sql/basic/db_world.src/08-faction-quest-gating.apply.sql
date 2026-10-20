-- MARKER_E022_APPLY basic-faction-quest-gating

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


INSERT IGNORE INTO `basic_155e_quest_race_backup` (`ID`, `AllowableRaces`)
SELECT `ID`, `AllowableRaces` FROM `quest_template`
WHERE `AllowableRaces` <> 0
  AND ((`AllowableRaces` & ~1101) = 0 AND `AllowableRaces` <> 1101
    OR (`AllowableRaces` & ~690)  = 0 AND `AllowableRaces` <> 690);

UPDATE `quest_template` SET `AllowableRaces` = 1101
WHERE `AllowableRaces` <> 0 AND (`AllowableRaces` & ~1101) = 0 AND `AllowableRaces` <> 1101;

UPDATE `quest_template` SET `AllowableRaces` = 690
WHERE `AllowableRaces` <> 0 AND (`AllowableRaces` & ~690) = 0 AND `AllowableRaces` <> 690;


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

