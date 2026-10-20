-- MARKER_E051_REVERT acherus-choice-vendors
UPDATE `creature_template` SET `npcflag` = `npcflag` & ~128 WHERE `entry` IN (28471, 28357);
DELETE FROM `npc_vendor` WHERE `entry` IN (28471, 28357);
UPDATE `item_template` SET `BuyPrice` =  42, `SellPrice` =  8 WHERE `entry` IN (39320, 38664, 39322);
UPDATE `item_template` SET `BuyPrice` = 184, `SellPrice` = 36 WHERE `entry` IN (38632, 38633);
