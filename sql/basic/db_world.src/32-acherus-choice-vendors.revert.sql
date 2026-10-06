-- MARKER_E051_REVERT acherus-choice-vendors
-- 32-acherus-choice-vendors revert (issue 718): the two vendors close and the
-- five items go back to their stock prices (read from the stock world
-- database, 2026-10-05: cloaks buy 42 sell 8, two-handers buy 184 sell 36,
-- in copper). Neither creature sold anything in stock, so its rows go whole.
UPDATE `creature_template` SET `npcflag` = `npcflag` & ~128 WHERE `entry` IN (28471, 28357);
DELETE FROM `npc_vendor` WHERE `entry` IN (28471, 28357);
UPDATE `item_template` SET `BuyPrice` =  42, `SellPrice` =  8 WHERE `entry` IN (39320, 38664, 39322);
UPDATE `item_template` SET `BuyPrice` = 184, `SellPrice` = 36 WHERE `entry` IN (38632, 38633);
