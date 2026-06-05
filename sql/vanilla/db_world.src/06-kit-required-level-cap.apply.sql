-- MARKER_E018_APPLY vanilla-kit-required-level-cap
-- Apply-form: lower RequiredLevel on every item that appears in the
-- vanilla 148h starter kit so a level-20 character can actually
-- equip the kit. The kit was tuned for level-22 items (Cuirboulli
-- armor, etc.) but vanilla's StartPlayerLevel is 20 (C007c). Without
-- this, ALE's auto-equip-starter-kit hook drops items into the bag
-- but EquipItem returns ERR_CANT_EQUIP_LEVEL_I and the character
-- spawns "stripped + bagful of unequippable kit" — naked, basically.
--
-- Vanilla-DB scope only (acore_world_vanilla). Doesn't affect
-- release/beta because they read a different world DB. Items are
-- still tagged with their original ItemLevel (visible in tooltip);
-- only the *required-to-wear* level moves.
UPDATE `item_template`
   SET `RequiredLevel` = 20
 WHERE `entry` IN (
           SELECT DISTINCT `itemid`
             FROM `playercreateinfo_item`
            WHERE `Note` LIKE 'vanilla-148h-%'
       )
   AND `RequiredLevel` > 20;
