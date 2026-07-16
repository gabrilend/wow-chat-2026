-- MARKER_E018_REVERT_V2 vanilla-kit-clones-and-tune
-- Revert-form (148h redesign 2026-06-12): cleanly back out the V2 apply
-- (clone + tune + sweep + restore). Restores the world DB to a state
-- "as if E018 never existed" — clones removed, loot tables pointing
-- at originals, originals at their canonical RL.
--
-- Unlike the V1 unpatch, this revert is deterministic. No snapshot
-- needed because the procedure works from the clone-ID convention
-- (clone = original + 2000000). The clone-map table below is the
-- single source of truth for the reverse sweep.
--
-- Idempotent: re-running silently no-ops on already-reverted rows.

START TRANSACTION;

-- {{{ step_1_build_clone_map_for_reverse_sweep
-- Same map shape as the apply form's step 6 — read in reverse to
-- restore loot tables to originals.
CREATE TEMPORARY TABLE _kit_clone_map (
    old_id INT NOT NULL PRIMARY KEY,
    new_id INT NOT NULL
);

INSERT INTO _kit_clone_map (old_id, new_id) VALUES
    (922,2000922),(924,2000924),(925,2000925),(926,2000926),
    (3027,2003027),(5211,2005211),(15810,2015810),
    (1198,2001198),(2027,2002027),(3445,2003445),(23923,2023923),
    (1197,2001197),(5580,2005580),(853,2000853),(1292,2001292),
    (2030,2002030),(1159,2001159),(5210,2005210),
    (923,2000923),(927,2000927),(928,2000928),(2209,2002209),
    (2441,2002441),(2445,2002445),(2442,2002442),
    (2148,2002148),(2149,2002149),(2150,2002150),
    (2151,2002151),(2152,2002152),(2153,2002153),
    (2141,2002141),(2142,2002142),(2143,2002143),
    (2144,2002144),(2145,2002145),(2146,2002146),
    (2156,2002156),(2158,2002158),(2159,2002159),
    (2160,2002160),(3591,2003591),(3592,2003592),
    (2240,2002240),
    (3422,2003422),(19295,2019295),(46978,2046978),
    (4238,2004238),(11362,2011362),(6948,2006948),(2515,2002515);
-- }}}

-- {{{ step_2_reverse_sweep_world_references_to_originals
-- Mirror of apply step 6, but JOIN keyed on new_id and SET to old_id.
UPDATE creature_loot_template     ct  JOIN _kit_clone_map m ON ct.Item  = m.new_id SET ct.Item  = m.old_id;
UPDATE gameobject_loot_template   gt  JOIN _kit_clone_map m ON gt.Item  = m.new_id SET gt.Item  = m.old_id;
UPDATE disenchant_loot_template   dt  JOIN _kit_clone_map m ON dt.Item  = m.new_id SET dt.Item  = m.old_id;
UPDATE reference_loot_template    rt  JOIN _kit_clone_map m ON rt.Item  = m.new_id SET rt.Item  = m.old_id;
UPDATE item_loot_template         it  JOIN _kit_clone_map m ON it.Item  = m.new_id SET it.Item  = m.old_id;
UPDATE mail_loot_template         ml  JOIN _kit_clone_map m ON ml.Item  = m.new_id SET ml.Item  = m.old_id;
UPDATE pickpocketing_loot_template pp JOIN _kit_clone_map m ON pp.Item  = m.new_id SET pp.Item  = m.old_id;
UPDATE skinning_loot_template     sk  JOIN _kit_clone_map m ON sk.Item  = m.new_id SET sk.Item  = m.old_id;
UPDATE fishing_loot_template      fl  JOIN _kit_clone_map m ON fl.Item  = m.new_id SET fl.Item  = m.old_id;
UPDATE prospecting_loot_template  pr  JOIN _kit_clone_map m ON pr.Item  = m.new_id SET pr.Item  = m.old_id;
UPDATE milling_loot_template      ml2 JOIN _kit_clone_map m ON ml2.Item = m.new_id SET ml2.Item = m.old_id;

UPDATE npc_vendor nv JOIN _kit_clone_map m ON nv.item = m.new_id SET nv.item = m.old_id;

UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardItem1 = m.new_id SET qt.RewardItem1 = m.old_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardItem2 = m.new_id SET qt.RewardItem2 = m.old_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardItem3 = m.new_id SET qt.RewardItem3 = m.old_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardItem4 = m.new_id SET qt.RewardItem4 = m.old_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardChoiceItemID1 = m.new_id SET qt.RewardChoiceItemID1 = m.old_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardChoiceItemID2 = m.new_id SET qt.RewardChoiceItemID2 = m.old_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardChoiceItemID3 = m.new_id SET qt.RewardChoiceItemID3 = m.old_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardChoiceItemID4 = m.new_id SET qt.RewardChoiceItemID4 = m.old_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardChoiceItemID5 = m.new_id SET qt.RewardChoiceItemID5 = m.old_id;
UPDATE quest_template qt JOIN _kit_clone_map m ON qt.RewardChoiceItemID6 = m.new_id SET qt.RewardChoiceItemID6 = m.old_id;

DROP TEMPORARY TABLE _kit_clone_map;
-- }}}

-- {{{ step_3_delete_all_clones_from_item_template
-- The 2000000-2099999 range is reserved for our kit clones (per 148h's
-- Entry ID convention), so a single range DELETE is safe and complete.
DELETE FROM item_template WHERE entry BETWEEN 2000000 AND 2099999;
-- }}}

-- {{{ step_4_note_on_originals
-- Originals are left at their canonical RequiredLevel from the apply
-- form's step 5. The revert restores the world to the "as if E018
-- never existed" state — originals at canonical, clones gone, world
-- pointing at originals.
--
-- Items that the original E018 had NOT touched (Kris 2209 at RL 19,
-- Double Axe 927 at RL 19, Battle Axe 926 at RL 20, accessories at
-- RL 0) are likewise correct.
-- }}}

COMMIT;
