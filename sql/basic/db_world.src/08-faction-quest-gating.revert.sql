-- MARKER_E022_REVERT basic-faction-quest-gating
-- ============================================================================
-- 08-faction-quest-gating.sql (issue 155e) — REVERT SOURCE
-- ============================================================================
-- Restore every quest race mask and quest race condition the apply form
-- widened, from the backup tables the apply form filled before changing
-- anything, then drop the backups. Exact: no mask is guessed.
--
-- The conditions restore matches on every primary-key column except the
-- mask itself, which the apply form changed (ConditionValue1 is part of
-- the conditions table's primary key). Two race conditions differing only
-- by mask in one ElseGroup would collide on apply and fail loudly there;
-- stock data has none.
-- ============================================================================

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

-- ============================================================================
-- End of 08-faction-quest-gating.sql (revert)
-- ============================================================================
