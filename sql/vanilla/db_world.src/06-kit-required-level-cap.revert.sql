-- MARKER_E018_REVERT_V3 vanilla-kit-in-place-tune

START TRANSACTION;


UPDATE item_template it
  JOIN _vanilla_kit_original_values s ON s.entry = it.entry
   SET it.RequiredLevel = s.RequiredLevel,
       it.dmg_min1      = s.dmg_min1,
       it.dmg_max1      = s.dmg_max1,
       it.stat_type1    = s.stat_type1,
       it.stat_value1   = s.stat_value1;


DROP TABLE IF EXISTS _vanilla_kit_original_values;


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

COMMIT;
