-- MARKER_E018_APPLY_V3 vanilla-kit-in-place-tune
-- Apply-form (148v reversal, 2026-08-07): tune the ORIGINAL kit item
-- entries in place. No clones. The V2 clone-to-new-ID design is undone
-- by step 0 below if it is still live in the database.
--
-- Why the reversal (full reasoning in 148v):
--   Entries at original+2000000 are ones no WoW client has ever cached.
--   The client only requests item data when an event prompts it, and a
--   server-side first-login equip is not such an event — so the model
--   was built with no display IDs and never redrawn. Kit gear rendered
--   as an invisible body with red "?" icons until the player manually
--   unequipped and re-equipped every piece.
--
--   There is no server-side fix for that. Using entries every client
--   already has cached from retail data is correct by construction.
--
-- What V2's clone design was protecting against, and why it did not:
--   The stated fear was that in-place edits "leak" — a retuned Polished
--   Scale Vest is retuned for every drop, vendor, and quest reward in
--   the world. True. But V2's own step 6 swept all thirteen reference
--   tables onto the clones, so the retuned values already applied
--   world-wide. The clone bought a different entry number for an
--   identical outcome, and that number is precisely the unreadable
--   part. Accepted deliberately per user direction 2026-08-07: a
--   handful of white items carry a level-20 required level and 15-DPS
--   damage across the vanilla world, which nobody notices past their
--   starting kit. Vanilla reads its own acore_world_vanilla, so
--   release and beta are untouched either way.
--
-- Reversibility — the one thing V2 did better, now fixed properly:
--   In-place edits have no natural undo, and 148h records that the V1
--   unpatch was "a soft revert (re-floored to RL=22) and known
--   imperfect" because no snapshot existed. Step 1 below takes a real
--   snapshot into _vanilla_kit_original_values before touching
--   anything, and the revert-form restores from it exactly.
--
-- Idempotence:
--   Step 0 no-ops when no clones exist. Step 1 uses INSERT IGNORE so a
--   re-apply never overwrites the pristine snapshot with already-tuned
--   values. Steps 2-4 are absolute SETs, so re-running converges.
--
--   HAZARD: dropping _vanilla_kit_original_values by hand and then
--   re-applying would snapshot the TUNED values and render the revert
--   a no-op. Do not drop that table except through the revert-form.

START TRANSACTION;

-- {{{ step_0_undo_v2_clone_state_if_present
-- The V2 apply is live in the database as of this rewrite: 51 clones
-- exist and every loot/vendor/quest reference points at them. Bring the
-- world home to the originals and delete the clones before tuning, so
-- this file converges from a V2 database, a V3 database, or a fresh
-- import alike.
--
-- The reverse sweep is keyed on the clone-ID convention (clone =
-- original + 2000000) rather than a hand-typed map, so it cannot drift
-- out of sync with the entry list the way a second copy of the map
-- would.

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

-- The kit itself. 02-starting-equipment.sql now emits original IDs, but
-- a database carrying V2 kit rows needs them brought home too, and this
-- migration runs before that one re-applies.
UPDATE playercreateinfo_item SET itemid = itemid - 2000000 WHERE itemid BETWEEN 2000000 AND 2099999;

-- Only now that nothing references them.
DELETE FROM item_template WHERE entry BETWEEN 2000000 AND 2099999;
-- }}}

-- {{{ step_1_snapshot_originals_before_touching_them
-- The undo of last resort. Captures every field steps 2-4 write, for
-- every entry they write it to, exactly once.
--
-- Taken AFTER step 0 so the captured values are the originals in their
-- untuned state — V2 never modified original damage, and its step 5
-- had already returned original RequiredLevel to canonical.

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
    -- Weapons in the current kit (all 18 are damage-tuned below)
     922,  924,  925,  926, 3027, 5211, 15810,
    1198, 2027, 3445, 23923,
    1197, 5580,  853, 1292,
    2030, 1159, 5210,
    -- Shields
    2441, 2445, 2442,
    -- Mail (Polished Scale set)
    2148, 2149, 2150, 2151, 2152, 2153,
    -- Leather (Cuirboulli set)
    2141, 2142, 2143, 2144, 2145, 2146,
    -- Cloth (Padded set)
    2156, 2158, 2159, 2160, 3591, 3592,
    -- Cape
    2240,
    -- Off-hand frills
    3422, 19295, 46978,
    -- Bag / quiver / hearthstone / ammo
    4238, 11362, 6948, 2515
 );

-- Deliberately NOT snapshotted and NOT touched: 923 Longsword,
-- 927 Double Axe, 928 Long Staff, 2209 Kris. V2 cloned these purely so
-- the V1 in-place leak could be reverted on the originals. They are no
-- longer in the kit, so V3 leaves them entirely alone — step 0 has
-- already returned the world's references to them.
-- }}}

-- {{{ step_2_cap_required_level_at_the_starting_level
-- Vanilla starts characters at level 20 (C007c). Kit items whose
-- canonical RequiredLevel sits at 21 or 22 are unequippable by a
-- brand-new character, so they come down to 20.
--
-- The `RequiredLevel > 20` guard is what keeps the accepted taint
-- small: items already at or below 20 (Hearthstone at 0, Battle Axe at
-- 20, the bags, the arrows, the flowers) are left exactly as upstream
-- shipped them. Only the handful that actually block equipping move.

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
-- }}}

-- {{{ step_3_normalise_weapon_damage_to_15_dps
-- Formula: new_dmg = old_dmg × (15 / old_DPS), delay preserved.
-- Old DPS is (dmg_min + dmg_max) / 2 / (delay / 1000).
-- Values carried over unchanged from the V2 clone tuning — the numbers
-- were never the problem, only which entry they were written to.
-- See 148h "Damage Normalization" for the derivation.

-- Claymore (1198) delay 3.2s, was 23-35 / 9.06 DPS
UPDATE item_template SET dmg_min1 = 38, dmg_max1 = 58 WHERE entry = 1198;

-- Scimitar (2027) delay 2.3s, was 14-26 / 8.70 DPS
UPDATE item_template SET dmg_min1 = 24, dmg_max1 = 45 WHERE entry = 2027;

-- Ceremonial Knife (3445) delay 1.4s, was 5-10 / 5.36 DPS
UPDATE item_template SET dmg_min1 = 14, dmg_max1 = 28 WHERE entry = 3445;

-- Amani Sacrificial Dagger (23923) delay 2.0s, was 10-20 / 7.50 DPS
-- Also: +1 Spell Power (stat_type 45 = ITEM_MOD_SPELL_POWER in 3.3.5a)
UPDATE item_template
   SET dmg_min1 = 20, dmg_max1 = 40,
       stat_type1 = 45, stat_value1 = 1
 WHERE entry = 23923;

-- Maul (924) delay 2.9s, was 37-56 / 16.03 DPS
UPDATE item_template SET dmg_min1 = 35, dmg_max1 = 52 WHERE entry = 924;

-- Flail (925) delay 2.2s, was 18-34 / 11.82 DPS
UPDATE item_template SET dmg_min1 = 23, dmg_max1 = 43 WHERE entry = 925;

-- Giant Mace (1197) delay 3.5s, was 25-38 / 9.00 DPS
UPDATE item_template SET dmg_min1 = 42, dmg_max1 = 63 WHERE entry = 1197;

-- Militia Hammer (5580) delay 2.3s, was 3-6 / 1.96 DPS
-- Biggest scale factor in the kit (7.65×). Loses joke-tier feel per 148h.
UPDATE item_template SET dmg_min1 = 23, dmg_max1 = 46 WHERE entry = 5580;

-- Battle Axe (926) delay 3.8s, was 46-70 / 15.26 DPS
UPDATE item_template SET dmg_min1 = 45, dmg_max1 = 69 WHERE entry = 926;

-- Hatchet (853) delay 2.5s, was 12-24 / 7.20 DPS
UPDATE item_template SET dmg_min1 = 25, dmg_max1 = 50 WHERE entry = 853;

-- Butcher's Cleaver (1292) delay 1.7s, was 23-32 / 16.18 DPS
UPDATE item_template SET dmg_min1 = 21, dmg_max1 = 30 WHERE entry = 1292;

-- Short Spear (15810) delay 3.3s, was 40-60 / 15.15 DPS
UPDATE item_template SET dmg_min1 = 40, dmg_max1 = 59 WHERE entry = 15810;

-- Dacian Falx (922) delay 3.1s, was 39-60 / 15.97 DPS
UPDATE item_template SET dmg_min1 = 37, dmg_max1 = 56 WHERE entry = 922;

-- Gnarled Staff (2030) delay 2.9s, was 27-42 / 11.90 DPS
UPDATE item_template SET dmg_min1 = 34, dmg_max1 = 53 WHERE entry = 2030;

-- Militia Quarterstaff (1159) delay 2.8s, was 6-9 / 2.68 DPS
-- Second-biggest scale factor (5.60×). Like Militia Hammer, loses joke-tier.
UPDATE item_template SET dmg_min1 = 34, dmg_max1 = 50 WHERE entry = 1159;

-- Heavy Recurve Bow (3027) delay 2.4s, was 21-40 / 12.71 DPS
UPDATE item_template SET dmg_min1 = 25, dmg_max1 = 47 WHERE entry = 3027;
-- }}}

-- {{{ step_4_normalise_wand_damage_to_20_dps
-- Wands land at 20 DPS, not 15 — the kit's wand-DPS placeholder pending
-- the proper rebalance in 148p. Wand-spell parity at L20 wants ~30 DPS;
-- 20 is the modest interim bump over vanilla's ~17-18.

-- Dusk Wand (5211) delay 1.7s, was 21-39 / 17.65 DPS
UPDATE item_template SET dmg_min1 = 24, dmg_max1 = 44 WHERE entry = 5211;

-- Burning Wand (5210) delay 1.4s, was 17-32 / 17.50 DPS
UPDATE item_template SET dmg_min1 = 19, dmg_max1 = 37 WHERE entry = 5210;
-- }}}

COMMIT;
