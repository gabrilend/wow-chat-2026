-- MARKER_E018_REVERT_V3 vanilla-kit-in-place-tune
-- Revert-form (148v reversal, 2026-08-07): restore every kit item entry
-- to the values captured before V3 first touched it, then clear the
-- snapshot. Also cleans up any residual V2 clone state, so this file
-- returns the world DB to "as if E018 never existed" from either
-- generation of the patch.
--
-- This is the deterministic unpatch V1 never had. 148h records that the
-- V1 unpatch "re-floored to RL=22" from a hand-typed table because no
-- snapshot existed, and was known imperfect. The V3 apply's step 1
-- writes _vanilla_kit_original_values before making any edit, so this
-- revert restores measured values rather than guessed ones.
--
-- Idempotent: with no snapshot table present, step 1 no-ops. With no
-- clones present, step 3 no-ops. Running twice changes nothing.
--
-- LIMITATION worth knowing: the snapshot is only as pristine as the
-- database was when V3 first applied. If V1's in-place edits were ever
-- live and V2's step 5 restored them from its hand-typed canonical
-- table, then those hand-typed values are what got snapshotted. Damage
-- fields are genuinely pristine (neither V1 nor V2 ever wrote damage to
-- an original entry); RequiredLevel on the ~19 items V1 touched is
-- second-hand. A pristine reference for those comes only from a fresh
-- world-DB import.

START TRANSACTION;

-- {{{ step_1_restore_originals_from_the_snapshot
-- The JOIN restricts the restore to exactly the entries that were
-- captured, so an item added to the kit after the snapshot was taken is
-- left alone rather than being reset to something arbitrary.

UPDATE item_template it
  JOIN _vanilla_kit_original_values s ON s.entry = it.entry
   SET it.RequiredLevel = s.RequiredLevel,
       it.dmg_min1      = s.dmg_min1,
       it.dmg_max1      = s.dmg_max1,
       it.stat_type1    = s.stat_type1,
       it.stat_value1   = s.stat_value1;
-- }}}

-- {{{ step_2_drop_the_snapshot
-- The snapshot's whole purpose is spent. Leaving it behind would mean a
-- later re-apply finds a populated table, skips its INSERT IGNORE, and
-- carries a stale baseline forward.

DROP TABLE IF EXISTS _vanilla_kit_original_values;
-- }}}

-- {{{ step_3_legacy_v2_clone_cleanup
-- Defensive. The V3 apply already folds the V2 undo into its step 0, so
-- on a database that has run V3 these are all no-ops. They exist so
-- that reverting a database still sitting in V2 state — clones present,
-- world references pointed at them — lands in the same clean place.
--
-- Keyed on the clone-ID convention (clone = original + 2000000), same
-- as the apply form, so there is no second copy of the entry list to
-- keep in sync.

UPDATE creature_loot_template      SET Item = Item - 2000000 WHERE Item BETWEEN 2000000 AND 2099999;
UPDATE gameobject_loot_template    SET Item = Item - 2000000 WHERE Item BETWEEN 2000000 AND 2099999;
UPDATE disenchant_loot_template    SET Item = Item - 2000000 WHERE Item BETWEEN 2000000 AND 2099999;
UPDATE reference_loot_template     SET Item = Item - 2000000 WHERE Item BETWEEN 2000000 AND 2099999;
UPDATE item_loot_template          SET Item = Item - 2000000 WHERE Item BETWEEN 2000000 AND 2099999;
UPDATE mail_loot_template          SET Item = Item - 2000000 WHERE Item BETWEEN 2000000 AND 2099999;
UPDATE pickpocketing_loot_template SET Item = Item - 2000000 WHERE Item BETWEEN 2000000 AND 2099999;
UPDATE skinning_loot_template      SET Item = Item - 2000000 WHERE Item BETWEEN 2000000 AND 2099999;
UPDATE fishing_loot_template       SET Item = Item - 2000000 WHERE Item BETWEEN 2000000 AND 2099999;
UPDATE prospecting_loot_template   SET Item = Item - 2000000 WHERE Item BETWEEN 2000000 AND 2099999;
UPDATE milling_loot_template       SET Item = Item - 2000000 WHERE Item BETWEEN 2000000 AND 2099999;

UPDATE npc_vendor SET item = item - 2000000 WHERE item BETWEEN 2000000 AND 2099999;

UPDATE quest_template SET RewardItem1         = RewardItem1         - 2000000 WHERE RewardItem1         BETWEEN 2000000 AND 2099999;
UPDATE quest_template SET RewardItem2         = RewardItem2         - 2000000 WHERE RewardItem2         BETWEEN 2000000 AND 2099999;
UPDATE quest_template SET RewardItem3         = RewardItem3         - 2000000 WHERE RewardItem3         BETWEEN 2000000 AND 2099999;
UPDATE quest_template SET RewardItem4         = RewardItem4         - 2000000 WHERE RewardItem4         BETWEEN 2000000 AND 2099999;
UPDATE quest_template SET RewardChoiceItemID1 = RewardChoiceItemID1 - 2000000 WHERE RewardChoiceItemID1 BETWEEN 2000000 AND 2099999;
UPDATE quest_template SET RewardChoiceItemID2 = RewardChoiceItemID2 - 2000000 WHERE RewardChoiceItemID2 BETWEEN 2000000 AND 2099999;
UPDATE quest_template SET RewardChoiceItemID3 = RewardChoiceItemID3 - 2000000 WHERE RewardChoiceItemID3 BETWEEN 2000000 AND 2099999;
UPDATE quest_template SET RewardChoiceItemID4 = RewardChoiceItemID4 - 2000000 WHERE RewardChoiceItemID4 BETWEEN 2000000 AND 2099999;
UPDATE quest_template SET RewardChoiceItemID5 = RewardChoiceItemID5 - 2000000 WHERE RewardChoiceItemID5 BETWEEN 2000000 AND 2099999;
UPDATE quest_template SET RewardChoiceItemID6 = RewardChoiceItemID6 - 2000000 WHERE RewardChoiceItemID6 BETWEEN 2000000 AND 2099999;

UPDATE playercreateinfo_item SET itemid = itemid - 2000000 WHERE itemid BETWEEN 2000000 AND 2099999;

DELETE FROM item_template WHERE entry BETWEEN 2000000 AND 2099999;
-- }}}

COMMIT;
