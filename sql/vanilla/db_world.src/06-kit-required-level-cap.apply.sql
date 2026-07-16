-- MARKER_E018_APPLY_V2 vanilla-kit-clones-and-tune
-- Apply-form (148h redesign 2026-06-12): clone every kit item to a new
-- entry (original + 2000000), tune the clones to DPS=15 (weapons) or
-- DPS=20 (wands) with RL=20, restore originals to canonical RL, and
-- sweep every world reference (loot tables, npc_vendor, quest_template)
-- so the vanilla profile world consistently uses the clones rather
-- than the originals.
--
-- Replaces the original E018 in-place RequiredLevel UPDATE which had
-- two problems:
--   1. It leaked: lowering RL on shared items affected every drop,
--      vendor listing, and quest reward of those items in the world.
--   2. The unpatch was a soft revert (floor everything to RL=22)
--      because no snapshot existed.
--
-- The clone-to-new-ID approach sidesteps both. Originals stay
-- canonically correct as Wowhead/Wowdb references; clones carry the
-- server-tuned values; the world uses clones; revert is deterministic
-- (DELETE WHERE entry BETWEEN 2000000 AND 2099999 + revert sweeps).
--
-- Idempotent: re-running detects existing clones via INSERT IGNORE,
-- sweeps any new references, and re-applies tuning without harm.

START TRANSACTION;

-- {{{ step_1_clone_all_kit_items
-- Snapshot every kit-referenced original into a temp table, bump the
-- entry ID by 2000000, and INSERT IGNORE so re-application leaves
-- existing clones untouched.
--
-- The 2000000 offset clears the entire vanilla item range (max ~64000
-- in 3.3.5a + ~30000 for WotLK additions) with no collision risk and
-- makes clone IDs immediately recognisable.

CREATE TEMPORARY TABLE _kit_clone_src AS
    SELECT * FROM item_template WHERE entry IN (
        -- Weapons in current kit
         922, 924, 925, 926, 3027, 5211, 15810,
        1198, 2027, 3445, 23923,
        1197, 5580, 853, 1292,
        2030, 1159, 5210,
        -- Weapons present in original kit, no longer used but cloned
        -- so the original tuning patch's RL=20 leak gets reverted on
        -- the originals (see step 5 below).
         923, 927, 928, 2209,
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
        -- Accessories
        3422, 19295, 46978,
        -- Bag / quiver / hearthstone / ammo
        4238, 11362, 6948, 2515
    );

UPDATE _kit_clone_src SET entry = entry + 2000000;

INSERT IGNORE INTO item_template SELECT * FROM _kit_clone_src;

DROP TEMPORARY TABLE _kit_clone_src;
-- }}}

-- {{{ step_2_tune_clones_required_level
-- Every clone lands at RequiredLevel = 20 — the vanilla profile's
-- StartPlayerLevel (C007c). Single UPDATE keyed by the clone-ID range.
UPDATE item_template
   SET RequiredLevel = 20
 WHERE entry BETWEEN 2000000 AND 2099999;
-- }}}

-- {{{ step_3_tune_weapon_damage_to_15_dps
-- Per-weapon DPS normalization. Formula: new_dmg = old_dmg × (15/old_DPS).
-- delay preserved from original. Original DPS computed (dmg_min+dmg_max)/2/(delay/1000).
-- See 148h "Damage Normalization" section for the full table.

-- Claymore clone (1198 → 2001198) delay 3.2s, was 23-35 / 9.06 DPS
UPDATE item_template SET dmg_min1 = 38, dmg_max1 = 58 WHERE entry = 2001198;

-- Scimitar clone (2027 → 2002027) delay 2.3s, was 14-26 / 8.70 DPS
UPDATE item_template SET dmg_min1 = 24, dmg_max1 = 45 WHERE entry = 2002027;

-- Ceremonial Knife clone (3445 → 2003445) delay 1.4s, was 5-10 / 5.36 DPS
UPDATE item_template SET dmg_min1 = 14, dmg_max1 = 28 WHERE entry = 2003445;

-- Amani Sacrificial Dagger clone (23923 → 2023923) delay 2.0s, was 10-20 / 7.50 DPS
-- Also: +1 Spell Power (stat_type 45 = ITEM_MOD_SPELL_POWER in 3.3.5a)
UPDATE item_template
   SET dmg_min1 = 20, dmg_max1 = 40,
       stat_type1 = 45, stat_value1 = 1
 WHERE entry = 2023923;

-- Maul clone (924 → 2000924) delay 2.9s, was 37-56 / 16.03 DPS
UPDATE item_template SET dmg_min1 = 35, dmg_max1 = 52 WHERE entry = 2000924;

-- Flail clone (925 → 2000925) delay 2.2s, was 18-34 / 11.82 DPS
UPDATE item_template SET dmg_min1 = 23, dmg_max1 = 43 WHERE entry = 2000925;

-- Giant Mace clone (1197 → 2001197) delay 3.5s, was 25-38 / 9.00 DPS
UPDATE item_template SET dmg_min1 = 42, dmg_max1 = 63 WHERE entry = 2001197;

-- Militia Hammer clone (5580 → 2005580) delay 2.3s, was 3-6 / 1.96 DPS
-- Biggest scale factor in the kit (7.65×). Loses joke-tier feel per 148h.
UPDATE item_template SET dmg_min1 = 23, dmg_max1 = 46 WHERE entry = 2005580;

-- Battle Axe clone (926 → 2000926) delay 3.8s, was 46-70 / 15.26 DPS
UPDATE item_template SET dmg_min1 = 45, dmg_max1 = 69 WHERE entry = 2000926;

-- Hatchet clone (853 → 2000853) delay 2.5s, was 12-24 / 7.20 DPS
UPDATE item_template SET dmg_min1 = 25, dmg_max1 = 50 WHERE entry = 2000853;

-- Butcher's Cleaver clone (1292 → 2001292) delay 1.7s, was 23-32 / 16.18 DPS
UPDATE item_template SET dmg_min1 = 21, dmg_max1 = 30 WHERE entry = 2001292;

-- Short Spear clone (15810 → 2015810) delay 3.3s, was 40-60 / 15.15 DPS
UPDATE item_template SET dmg_min1 = 40, dmg_max1 = 59 WHERE entry = 2015810;

-- Dacian Falx clone (922 → 2000922) delay 3.1s, was 39-60 / 15.97 DPS
UPDATE item_template SET dmg_min1 = 37, dmg_max1 = 56 WHERE entry = 2000922;

-- Gnarled Staff clone (2030 → 2002030) delay 2.9s, was 27-42 / 11.90 DPS
UPDATE item_template SET dmg_min1 = 34, dmg_max1 = 53 WHERE entry = 2002030;

-- Militia Quarterstaff clone (1159 → 2001159) delay 2.8s, was 6-9 / 2.68 DPS
-- Second-biggest scale factor (5.60×). Like Militia Hammer, loses joke-tier.
UPDATE item_template SET dmg_min1 = 34, dmg_max1 = 50 WHERE entry = 2001159;

-- Heavy Recurve Bow clone (3027 → 2003027) delay 2.4s, was 21-40 / 12.71 DPS
UPDATE item_template SET dmg_min1 = 25, dmg_max1 = 47 WHERE entry = 2003027;
-- }}}

-- {{{ step_4_tune_wand_damage_to_20_dps
-- Wands land at 20 DPS, not 15 — the kit's wand-DPS placeholder pending
-- the proper rebalance in 148p. Wand-spell parity at L20 wants ~30 DPS;
-- 20 is the modest interim bump over vanilla's ~17-18.

-- Dusk Wand clone (5211 → 2005211) delay 1.7s, was 21-39 / 17.65 DPS
UPDATE item_template SET dmg_min1 = 24, dmg_max1 = 44 WHERE entry = 2005211;

-- Burning Wand clone (5210 → 2005210) delay 1.4s, was 17-32 / 17.50 DPS
UPDATE item_template SET dmg_min1 = 19, dmg_max1 = 37 WHERE entry = 2005210;
-- }}}

-- {{{ step_5_restore_originals_to_canonical_required_level
-- The original E018 patch lowered RequiredLevel in-place on every kit
-- item with RL > 20. Restore those originals to their canonical pre-
-- E018 values so external references (Wowhead, Wowdb) match the DB.
--
-- Per-entry hardcoded lookup since the ItemLevel-derived formula
-- doesn't perfectly match all items. Items at RL ≤ 20 originally
-- (Kris 19, Double Axe 19, Battle Axe 20, accessories at 0) are not
-- touched.

-- IL 26 weapons → canonical RL 22
UPDATE item_template SET RequiredLevel = 22 WHERE entry = 922;  -- Dacian Falx
UPDATE item_template SET RequiredLevel = 22 WHERE entry = 923;  -- Longsword
UPDATE item_template SET RequiredLevel = 22 WHERE entry = 924;  -- Maul

-- IL 25 weapons → canonical RL 21
UPDATE item_template SET RequiredLevel = 21 WHERE entry = 925;   -- Flail
UPDATE item_template SET RequiredLevel = 21 WHERE entry = 928;   -- Long Staff
UPDATE item_template SET RequiredLevel = 21 WHERE entry = 3027;  -- Heavy Recurve Bow
UPDATE item_template SET RequiredLevel = 21 WHERE entry = 15810; -- Short Spear

-- IL 25 wand → canonical RL 22 (wands have a slightly higher RL curve)
UPDATE item_template SET RequiredLevel = 22 WHERE entry = 5211;  -- Dusk Wand

-- Battle Axe (926) original RL was 20, not touched by E018. No restore.

-- IL 27 armor sets → canonical RL 22 (all six pieces per set)
UPDATE item_template SET RequiredLevel = 22 WHERE entry IN (
    2141, 2142, 2143, 2144, 2145, 2146,  -- Cuirboulli (leather)
    2148, 2149, 2150, 2151, 2152, 2153,  -- Polished Scale (mail)
    2156, 2158, 2159, 2160, 3591, 3592,  -- Padded (cloth)
    2442                                  -- Reinforced Targe (shield)
);
-- }}}

-- {{{ step_6_sweep_world_references_to_clones
-- Build a clone-ID map in a temp table, then JOIN-UPDATE every loot
-- table, vendor, and quest reward in the vanilla profile world DB.
-- Originals retain their canonical stats as Wowhead references, but
-- the live world consistently drops/sells/rewards the server-tuned
-- clones.

CREATE TEMPORARY TABLE _kit_clone_map (
    old_id INT NOT NULL PRIMARY KEY,
    new_id INT NOT NULL
);

INSERT INTO _kit_clone_map (old_id, new_id) VALUES
    -- Weapons currently in the kit
    (922,2000922),(924,2000924),(925,2000925),(926,2000926),
    (3027,2003027),(5211,2005211),(15810,2015810),
    (1198,2001198),(2027,2002027),(3445,2003445),(23923,2023923),
    (1197,2001197),(5580,2005580),(853,2000853),(1292,2001292),
    (2030,2002030),(1159,2001159),(5210,2005210),
    -- Weapons retired from the kit (kept cloned so loot still drops
    -- the original-tier vanilla item via the clone — same stats, but
    -- the clone IS the server-canonical version now)
    (923,2000923),(927,2000927),(928,2000928),(2209,2002209),
    -- Shields
    (2441,2002441),(2445,2002445),(2442,2002442),
    -- Mail
    (2148,2002148),(2149,2002149),(2150,2002150),
    (2151,2002151),(2152,2002152),(2153,2002153),
    -- Leather
    (2141,2002141),(2142,2002142),(2143,2002143),
    (2144,2002144),(2145,2002145),(2146,2002146),
    -- Cloth
    (2156,2002156),(2158,2002158),(2159,2002159),
    (2160,2002160),(3591,2003591),(3592,2003592),
    -- Cape
    (2240,2002240),
    -- Accessories
    (3422,2003422),(19295,2019295),(46978,2046978),
    -- Bag / quiver / hearthstone / ammo
    (4238,2004238),(11362,2011362),(6948,2006948),(2515,2002515);

-- Loot tables — every drop source. Each table keyed on `Item`.
UPDATE creature_loot_template     ct  JOIN _kit_clone_map m ON ct.Item  = m.old_id SET ct.Item  = m.new_id;
UPDATE gameobject_loot_template   gt  JOIN _kit_clone_map m ON gt.Item  = m.old_id SET gt.Item  = m.new_id;
UPDATE disenchant_loot_template   dt  JOIN _kit_clone_map m ON dt.Item  = m.old_id SET dt.Item  = m.new_id;
UPDATE reference_loot_template    rt  JOIN _kit_clone_map m ON rt.Item  = m.old_id SET rt.Item  = m.new_id;
UPDATE item_loot_template         it  JOIN _kit_clone_map m ON it.Item  = m.old_id SET it.Item  = m.new_id;
UPDATE mail_loot_template         ml  JOIN _kit_clone_map m ON ml.Item  = m.old_id SET ml.Item  = m.new_id;
UPDATE pickpocketing_loot_template pp JOIN _kit_clone_map m ON pp.Item  = m.old_id SET pp.Item  = m.new_id;
UPDATE skinning_loot_template     sk  JOIN _kit_clone_map m ON sk.Item  = m.old_id SET sk.Item  = m.new_id;
UPDATE fishing_loot_template      fl  JOIN _kit_clone_map m ON fl.Item  = m.old_id SET fl.Item  = m.new_id;
UPDATE prospecting_loot_template  pr  JOIN _kit_clone_map m ON pr.Item  = m.old_id SET pr.Item  = m.new_id;
UPDATE milling_loot_template      ml2 JOIN _kit_clone_map m ON ml2.Item = m.old_id SET ml2.Item = m.new_id;

-- Vendor stock — column is lowercase `item`.
UPDATE npc_vendor nv JOIN _kit_clone_map m ON nv.item = m.old_id SET nv.item = m.new_id;

-- Quest rewards — four fixed-reward slots and six choice-reward slots.
-- Each column needs its own UPDATE since the temp-table JOIN can only
-- match one column at a time.
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardItem1 = m.old_id SET qt.RewardItem1 = m.new_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardItem2 = m.old_id SET qt.RewardItem2 = m.new_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardItem3 = m.old_id SET qt.RewardItem3 = m.new_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardItem4 = m.old_id SET qt.RewardItem4 = m.new_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardChoiceItemID1 = m.old_id SET qt.RewardChoiceItemID1 = m.new_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardChoiceItemID2 = m.old_id SET qt.RewardChoiceItemID2 = m.new_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardChoiceItemID3 = m.old_id SET qt.RewardChoiceItemID3 = m.new_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardChoiceItemID4 = m.old_id SET qt.RewardChoiceItemID4 = m.new_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardChoiceItemID5 = m.old_id SET qt.RewardChoiceItemID5 = m.new_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardChoiceItemID6 = m.old_id SET qt.RewardChoiceItemID6 = m.new_id;

DROP TEMPORARY TABLE _kit_clone_map;
-- }}}

COMMIT;
