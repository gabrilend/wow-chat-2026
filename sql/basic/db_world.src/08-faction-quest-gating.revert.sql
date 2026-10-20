-- MARKER_E022_REVERT basic-faction-quest-gating

UPDATE `quest_template` q
JOIN `basic_155e_quest_race_backup` b ON b.`ID` = q.`ID`
SET q.`AllowableRaces` = b.`AllowableRaces`;

UPDATE `conditions` c
JOIN `basic_155e_condition_race_backup` b
  ON  b.`SourceTypeOrReferenceId`  = c.`SourceTypeOrReferenceId`
  AND b.`SourceGroup`              = c.`SourceGroup`
  AND b.`SourceEntry`              = c.`SourceEntry`
  AND b.`SourceId`                 = c.`SourceId`
  AND b.`ElseGroup`                = c.`ElseGroup`
  AND b.`ConditionTypeOrReference` = c.`ConditionTypeOrReference`
  AND b.`ConditionTarget`          = c.`ConditionTarget`
  AND b.`ConditionValue2`          = c.`ConditionValue2`
  AND b.`ConditionValue3`          = c.`ConditionValue3`
SET c.`ConditionValue1` = b.`ConditionValue1_orig`
WHERE c.`ConditionValue1` IN (1101, 690);

DROP TABLE IF EXISTS `basic_155e_quest_race_backup`;
DROP TABLE IF EXISTS `basic_155e_condition_race_backup`;

