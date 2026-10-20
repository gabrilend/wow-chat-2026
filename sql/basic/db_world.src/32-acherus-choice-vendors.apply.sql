-- MARKER_E051_APPLY acherus-choice-vendors

UPDATE `creature_template` SET `npcflag` = `npcflag` | 128 WHERE `entry` IN (28471, 28357);

DELETE FROM `npc_vendor` WHERE `entry` IN (28471, 28357);
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
  (28471, 0, 39320, 0, 0, 0, 0),   -- Sky Darkener's Shroud of Blood
  (28471, 1, 38664, 0, 0, 0, 0),   -- Sky Darkener's Shroud of the Unholy
  (28471, 2, 39322, 0, 0, 0, 0),   -- Shroud of the North Wind
  (28357, 0, 38632, 0, 0, 0, 0),   -- Greatsword of the Ebon Blade
  (28357, 1, 38633, 0, 0, 0, 0);   -- Greataxe of the Ebon Blade

UPDATE `item_template` SET `BuyPrice` = 10000, `SellPrice` = 0
 WHERE `entry` IN (39320, 38664, 39322, 38632, 38633);
