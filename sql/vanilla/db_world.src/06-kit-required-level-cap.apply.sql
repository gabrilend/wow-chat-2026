-- MARKER_E018_APPLY_V3 vanilla-kit-in-place-tune

START TRANSACTION;


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


CREATE TABLE IF NOT EXISTS _vanilla_kit_original_values (
    entry         INT UNSIGNED     NOT NULL PRIMARY KEY,
    RequiredLevel TINYINT UNSIGNED NOT NULL,
    dmg_min1      FLOAT            NOT NULL,
    dmg_max1      FLOAT            NOT NULL,
    stat_type1    TINYINT UNSIGNED NOT NULL,
    stat_value1   INT              NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO _vanilla_kit_original_values
    (entry, RequiredLevel, dmg_min1, dmg_max1, stat_type1, stat_value1)
SELECT entry, RequiredLevel, dmg_min1, dmg_max1, stat_type1, stat_value1
  FROM item_template
 WHERE entry IN (
     922,  924,  925,  926, 3027, 5211, 15810,
    1198, 2027, 3445, 23923,
    1197, 5580,  853, 1292,
    2030, 1159, 5210,
    2441, 2445, 2442,
    2148, 2149, 2150, 2151, 2152, 2153,
    2141, 2142, 2143, 2144, 2145, 2146,
    2156, 2158, 2159, 2160, 3591, 3592,
    2240,
    3422, 19295, 46978,
    4238, 11362, 6948, 2515
 );



UPDATE item_template
   SET RequiredLevel = 20
 WHERE RequiredLevel > 20
   AND entry IN (
     922,  924,  925,  926, 3027, 5211, 15810,
    1198, 2027, 3445, 23923,
    1197, 5580,  853, 1292,
    2030, 1159, 5210,
    2441, 2445, 2442,
    2148, 2149, 2150, 2151, 2152, 2153,
    2141, 2142, 2143, 2144, 2145, 2146,
    2156, 2158, 2159, 2160, 3591, 3592,
    2240,
    3422, 19295, 46978,
    4238, 11362, 6948, 2515
 );


UPDATE item_template SET dmg_min1 = 38, dmg_max1 = 58 WHERE entry = 1198;

UPDATE item_template SET dmg_min1 = 24, dmg_max1 = 45 WHERE entry = 2027;

UPDATE item_template SET dmg_min1 = 14, dmg_max1 = 28 WHERE entry = 3445;

UPDATE item_template
   SET dmg_min1 = 20, dmg_max1 = 40,
       stat_type1 = 45, stat_value1 = 1
 WHERE entry = 23923;

UPDATE item_template SET dmg_min1 = 35, dmg_max1 = 52 WHERE entry = 924;

UPDATE item_template SET dmg_min1 = 23, dmg_max1 = 43 WHERE entry = 925;

UPDATE item_template SET dmg_min1 = 42, dmg_max1 = 63 WHERE entry = 1197;

UPDATE item_template SET dmg_min1 = 23, dmg_max1 = 46 WHERE entry = 5580;

UPDATE item_template SET dmg_min1 = 45, dmg_max1 = 69 WHERE entry = 926;

UPDATE item_template SET dmg_min1 = 25, dmg_max1 = 50 WHERE entry = 853;

UPDATE item_template SET dmg_min1 = 21, dmg_max1 = 30 WHERE entry = 1292;

UPDATE item_template SET dmg_min1 = 40, dmg_max1 = 59 WHERE entry = 15810;

UPDATE item_template SET dmg_min1 = 37, dmg_max1 = 56 WHERE entry = 922;

UPDATE item_template SET dmg_min1 = 34, dmg_max1 = 53 WHERE entry = 2030;

UPDATE item_template SET dmg_min1 = 34, dmg_max1 = 50 WHERE entry = 1159;

UPDATE item_template SET dmg_min1 = 25, dmg_max1 = 47 WHERE entry = 3027;


UPDATE item_template SET dmg_min1 = 24, dmg_max1 = 44 WHERE entry = 5211;

UPDATE item_template SET dmg_min1 = 19, dmg_max1 = 37 WHERE entry = 5210;

COMMIT;
