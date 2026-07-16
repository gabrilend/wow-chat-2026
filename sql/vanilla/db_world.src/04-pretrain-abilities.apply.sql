-- ============================================================================
-- 04-pretrain-abilities.sql (148j)
-- ============================================================================
-- Grants every newly-created vanilla character the full set of class-trainer
-- spells they would normally have learned by level 20. Without this file, a
-- level-20 starting character (per C007c) wakes up knowing only their level-1
-- starter abilities — no Dual Wield for rogues, no Frostbolt rank 4 for
-- mages, no Charge for warriors. With it, the spellbook matches what a
-- retail-leveled level-20 character would carry.
--
-- Database: acore_world_vanilla
--
-- Generation: produced by scripts/generate-148j-pretrain-sql. Do not edit
-- by hand — re-run the generator after upstream AzerothCore trainer data
-- shifts and re-commit the output. The query joins the trainer-system
-- tables filtered to Type=0 (class trainer) with ReqLevel<=20, deduplicates
-- by (class, spell), and emits one INSERT per row.
--
-- Application: discovered and applied by AzerothCore's UpdateFetcher via
-- the updates_include registration that E008 installs in
-- acore_world_vanilla.updates_include. AC handles hashing, change
-- detection, and the updates-table accounting — this file just sits in
-- sql/vanilla/db_world.src and gets picked up on each worldserver boot.
--
-- Re-applicability: the DELETE-then-INSERT pattern below scopes its
-- cleanup to rows tagged with the Note prefix "vanilla-148j-", so
-- re-running this file produces the same end state without disturbing
-- inserts from other vanilla migrations.
--
-- Pair count: 287 (class, spell) rows. DK (class 6) excluded
-- per 148a; the remaining nine classes are represented.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Clear prior rows from this migration so re-applying is safe. The Note
--    prefix is the migration's signature; only rows it owns are touched.
-- ----------------------------------------------------------------------------

DELETE FROM playercreateinfo_spell_custom WHERE Note LIKE 'vanilla-148j-%';

-- ----------------------------------------------------------------------------
-- 2. Insert one row per (class, spell). race=0 means "every race that can
--    play this class" — the engine fans out at character creation. The
--    Note column carries a per-row tag identifying class + spell so a
--    future SELECT can audit what 148j granted.
-- ----------------------------------------------------------------------------

INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 72, 'vanilla-148j-c1-s72');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 100, 'vanilla-148j-c1-s100');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 284, 'vanilla-148j-c1-s284');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 285, 'vanilla-148j-c1-s285');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 674, 'vanilla-148j-c1-s674');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 676, 'vanilla-148j-c1-s676');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 694, 'vanilla-148j-c1-s694');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 772, 'vanilla-148j-c1-s772');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 845, 'vanilla-148j-c1-s845');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 1160, 'vanilla-148j-c1-s1160');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 1715, 'vanilla-148j-c1-s1715');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 2565, 'vanilla-148j-c1-s2565');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 2687, 'vanilla-148j-c1-s2687');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 3127, 'vanilla-148j-c1-s3127');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 5242, 'vanilla-148j-c1-s5242');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 6343, 'vanilla-148j-c1-s6343');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 6546, 'vanilla-148j-c1-s6546');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 6547, 'vanilla-148j-c1-s6547');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 6572, 'vanilla-148j-c1-s6572');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 6673, 'vanilla-148j-c1-s6673');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 7384, 'vanilla-148j-c1-s7384');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 8198, 'vanilla-148j-c1-s8198');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 12678, 'vanilla-148j-c1-s12678');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 20230, 'vanilla-148j-c1-s20230');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1, 34428, 'vanilla-148j-c1-s34428');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 465, 'vanilla-148j-c2-s465');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 498, 'vanilla-148j-c2-s498');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 633, 'vanilla-148j-c2-s633');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 639, 'vanilla-148j-c2-s639');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 643, 'vanilla-148j-c2-s643');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 647, 'vanilla-148j-c2-s647');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 853, 'vanilla-148j-c2-s853');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 879, 'vanilla-148j-c2-s879');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 1022, 'vanilla-148j-c2-s1022');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 1044, 'vanilla-148j-c2-s1044');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 1152, 'vanilla-148j-c2-s1152');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 3127, 'vanilla-148j-c2-s3127');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 5502, 'vanilla-148j-c2-s5502');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 7294, 'vanilla-148j-c2-s7294');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 10290, 'vanilla-148j-c2-s10290');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 10321, 'vanilla-148j-c2-s10321');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 13820, 'vanilla-148j-c2-s13820');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 19740, 'vanilla-148j-c2-s19740');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 19742, 'vanilla-148j-c2-s19742');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 19750, 'vanilla-148j-c2-s19750');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 19834, 'vanilla-148j-c2-s19834');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 20217, 'vanilla-148j-c2-s20217');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 25780, 'vanilla-148j-c2-s25780');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 26573, 'vanilla-148j-c2-s26573');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 31789, 'vanilla-148j-c2-s31789');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 34768, 'vanilla-148j-c2-s34768');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 53408, 'vanilla-148j-c2-s53408');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 2, 62124, 'vanilla-148j-c2-s62124');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 136, 'vanilla-148j-c3-s136');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 674, 'vanilla-148j-c3-s674');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 781, 'vanilla-148j-c3-s781');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 1002, 'vanilla-148j-c3-s1002');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 1130, 'vanilla-148j-c3-s1130');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 1494, 'vanilla-148j-c3-s1494');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 1495, 'vanilla-148j-c3-s1495');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 1499, 'vanilla-148j-c3-s1499');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 1513, 'vanilla-148j-c3-s1513');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 1978, 'vanilla-148j-c3-s1978');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 2643, 'vanilla-148j-c3-s2643');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 2974, 'vanilla-148j-c3-s2974');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 3044, 'vanilla-148j-c3-s3044');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 3111, 'vanilla-148j-c3-s3111');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 3127, 'vanilla-148j-c3-s3127');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 5116, 'vanilla-148j-c3-s5116');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 5118, 'vanilla-148j-c3-s5118');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 6197, 'vanilla-148j-c3-s6197');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 13163, 'vanilla-148j-c3-s13163');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 13165, 'vanilla-148j-c3-s13165');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 13549, 'vanilla-148j-c3-s13549');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 13550, 'vanilla-148j-c3-s13550');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 13795, 'vanilla-148j-c3-s13795');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 14260, 'vanilla-148j-c3-s14260');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 14261, 'vanilla-148j-c3-s14261');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 14281, 'vanilla-148j-c3-s14281');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 14282, 'vanilla-148j-c3-s14282');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 14318, 'vanilla-148j-c3-s14318');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 19883, 'vanilla-148j-c3-s19883');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 19884, 'vanilla-148j-c3-s19884');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 20736, 'vanilla-148j-c3-s20736');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 4, 34074, 'vanilla-148j-c3-s34074');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 53, 'vanilla-148j-c4-s53');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 674, 'vanilla-148j-c4-s674');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 703, 'vanilla-148j-c4-s703');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 921, 'vanilla-148j-c4-s921');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 1757, 'vanilla-148j-c4-s1757');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 1758, 'vanilla-148j-c4-s1758');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 1766, 'vanilla-148j-c4-s1766');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 1776, 'vanilla-148j-c4-s1776');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 1784, 'vanilla-148j-c4-s1784');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 1804, 'vanilla-148j-c4-s1804');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 1943, 'vanilla-148j-c4-s1943');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 1966, 'vanilla-148j-c4-s1966');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 2589, 'vanilla-148j-c4-s2589');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 2590, 'vanilla-148j-c4-s2590');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 2983, 'vanilla-148j-c4-s2983');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 3127, 'vanilla-148j-c4-s3127');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 5171, 'vanilla-148j-c4-s5171');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 5277, 'vanilla-148j-c4-s5277');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 6760, 'vanilla-148j-c4-s6760');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 6761, 'vanilla-148j-c4-s6761');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 6770, 'vanilla-148j-c4-s6770');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 8647, 'vanilla-148j-c4-s8647');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 8676, 'vanilla-148j-c4-s8676');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 8, 51722, 'vanilla-148j-c4-s51722');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 17, 'vanilla-148j-c5-s17');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 139, 'vanilla-148j-c5-s139');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 453, 'vanilla-148j-c5-s453');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 527, 'vanilla-148j-c5-s527');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 528, 'vanilla-148j-c5-s528');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 586, 'vanilla-148j-c5-s586');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 588, 'vanilla-148j-c5-s588');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 589, 'vanilla-148j-c5-s589');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 591, 'vanilla-148j-c5-s591');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 592, 'vanilla-148j-c5-s592');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 594, 'vanilla-148j-c5-s594');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 598, 'vanilla-148j-c5-s598');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 600, 'vanilla-148j-c5-s600');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 970, 'vanilla-148j-c5-s970');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 1243, 'vanilla-148j-c5-s1243');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 1244, 'vanilla-148j-c5-s1244');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 2006, 'vanilla-148j-c5-s2006');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 2052, 'vanilla-148j-c5-s2052');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 2053, 'vanilla-148j-c5-s2053');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 2054, 'vanilla-148j-c5-s2054');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 2061, 'vanilla-148j-c5-s2061');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 2944, 'vanilla-148j-c5-s2944');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 6074, 'vanilla-148j-c5-s6074');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 6075, 'vanilla-148j-c5-s6075');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 6346, 'vanilla-148j-c5-s6346');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 7128, 'vanilla-148j-c5-s7128');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 8092, 'vanilla-148j-c5-s8092');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 8102, 'vanilla-148j-c5-s8102');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 8122, 'vanilla-148j-c5-s8122');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 9484, 'vanilla-148j-c5-s9484');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 14914, 'vanilla-148j-c5-s14914');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 16, 15237, 'vanilla-148j-c5-s15237');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 324, 'vanilla-148j-c7-s324');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 325, 'vanilla-148j-c7-s325');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 332, 'vanilla-148j-c7-s332');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 370, 'vanilla-148j-c7-s370');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 526, 'vanilla-148j-c7-s526');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 529, 'vanilla-148j-c7-s529');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 547, 'vanilla-148j-c7-s547');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 548, 'vanilla-148j-c7-s548');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 913, 'vanilla-148j-c7-s913');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 915, 'vanilla-148j-c7-s915');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 1535, 'vanilla-148j-c7-s1535');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 2008, 'vanilla-148j-c7-s2008');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 2484, 'vanilla-148j-c7-s2484');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 2645, 'vanilla-148j-c7-s2645');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 5730, 'vanilla-148j-c7-s5730');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 6363, 'vanilla-148j-c7-s6363');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 6390, 'vanilla-148j-c7-s6390');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 8004, 'vanilla-148j-c7-s8004');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 8017, 'vanilla-148j-c7-s8017');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 8018, 'vanilla-148j-c7-s8018');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 8019, 'vanilla-148j-c7-s8019');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 8024, 'vanilla-148j-c7-s8024');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 8027, 'vanilla-148j-c7-s8027');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 8033, 'vanilla-148j-c7-s8033');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 8042, 'vanilla-148j-c7-s8042');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 8044, 'vanilla-148j-c7-s8044');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 8045, 'vanilla-148j-c7-s8045');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 8050, 'vanilla-148j-c7-s8050');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 8052, 'vanilla-148j-c7-s8052');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 8056, 'vanilla-148j-c7-s8056');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 8075, 'vanilla-148j-c7-s8075');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 8143, 'vanilla-148j-c7-s8143');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 8154, 'vanilla-148j-c7-s8154');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 52127, 'vanilla-148j-c7-s52127');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 64, 57994, 'vanilla-148j-c7-s57994');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 10, 'vanilla-148j-c8-s10');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 116, 'vanilla-148j-c8-s116');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 118, 'vanilla-148j-c8-s118');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 122, 'vanilla-148j-c8-s122');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 130, 'vanilla-148j-c8-s130');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 143, 'vanilla-148j-c8-s143');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 145, 'vanilla-148j-c8-s145');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 205, 'vanilla-148j-c8-s205');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 475, 'vanilla-148j-c8-s475');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 543, 'vanilla-148j-c8-s543');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 587, 'vanilla-148j-c8-s587');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 597, 'vanilla-148j-c8-s597');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 604, 'vanilla-148j-c8-s604');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 837, 'vanilla-148j-c8-s837');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 1008, 'vanilla-148j-c8-s1008');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 1449, 'vanilla-148j-c8-s1449');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 1459, 'vanilla-148j-c8-s1459');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 1460, 'vanilla-148j-c8-s1460');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 1463, 'vanilla-148j-c8-s1463');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 1953, 'vanilla-148j-c8-s1953');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 2120, 'vanilla-148j-c8-s2120');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 2136, 'vanilla-148j-c8-s2136');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 2137, 'vanilla-148j-c8-s2137');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 3140, 'vanilla-148j-c8-s3140');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 3561, 'vanilla-148j-c8-s3561');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 3562, 'vanilla-148j-c8-s3562');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 3563, 'vanilla-148j-c8-s3563');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 3567, 'vanilla-148j-c8-s3567');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 5143, 'vanilla-148j-c8-s5143');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 5144, 'vanilla-148j-c8-s5144');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 5504, 'vanilla-148j-c8-s5504');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 5505, 'vanilla-148j-c8-s5505');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 5506, 'vanilla-148j-c8-s5506');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 7300, 'vanilla-148j-c8-s7300');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 7301, 'vanilla-148j-c8-s7301');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 7322, 'vanilla-148j-c8-s7322');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 12051, 'vanilla-148j-c8-s12051');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 12824, 'vanilla-148j-c8-s12824');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 32271, 'vanilla-148j-c8-s32271');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 32272, 'vanilla-148j-c8-s32272');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 49358, 'vanilla-148j-c8-s49358');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 128, 49359, 'vanilla-148j-c8-s49359');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 172, 'vanilla-148j-c9-s172');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 348, 'vanilla-148j-c9-s348');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 688, 'vanilla-148j-c9-s688');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 689, 'vanilla-148j-c9-s689');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 693, 'vanilla-148j-c9-s693');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 695, 'vanilla-148j-c9-s695');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 696, 'vanilla-148j-c9-s696');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 698, 'vanilla-148j-c9-s698');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 702, 'vanilla-148j-c9-s702');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 705, 'vanilla-148j-c9-s705');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 706, 'vanilla-148j-c9-s706');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 707, 'vanilla-148j-c9-s707');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 755, 'vanilla-148j-c9-s755');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 980, 'vanilla-148j-c9-s980');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 1014, 'vanilla-148j-c9-s1014');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 1088, 'vanilla-148j-c9-s1088');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 1094, 'vanilla-148j-c9-s1094');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 1108, 'vanilla-148j-c9-s1108');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 1120, 'vanilla-148j-c9-s1120');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 1454, 'vanilla-148j-c9-s1454');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 1455, 'vanilla-148j-c9-s1455');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 1710, 'vanilla-148j-c9-s1710');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 3698, 'vanilla-148j-c9-s3698');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 5676, 'vanilla-148j-c9-s5676');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 5697, 'vanilla-148j-c9-s5697');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 5740, 'vanilla-148j-c9-s5740');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 5782, 'vanilla-148j-c9-s5782');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 6201, 'vanilla-148j-c9-s6201');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 256, 6222, 'vanilla-148j-c9-s6222');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 99, 'vanilla-148j-c11-s99');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 339, 'vanilla-148j-c11-s339');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 467, 'vanilla-148j-c11-s467');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 768, 'vanilla-148j-c11-s768');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 770, 'vanilla-148j-c11-s770');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 774, 'vanilla-148j-c11-s774');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 779, 'vanilla-148j-c11-s779');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 782, 'vanilla-148j-c11-s782');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 783, 'vanilla-148j-c11-s783');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 1058, 'vanilla-148j-c11-s1058');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 1062, 'vanilla-148j-c11-s1062');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 1066, 'vanilla-148j-c11-s1066');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 1079, 'vanilla-148j-c11-s1079');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 1082, 'vanilla-148j-c11-s1082');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 1126, 'vanilla-148j-c11-s1126');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 1430, 'vanilla-148j-c11-s1430');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 1735, 'vanilla-148j-c11-s1735');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 2637, 'vanilla-148j-c11-s2637');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 2912, 'vanilla-148j-c11-s2912');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 5177, 'vanilla-148j-c11-s5177');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 5178, 'vanilla-148j-c11-s5178');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 5186, 'vanilla-148j-c11-s5186');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 5187, 'vanilla-148j-c11-s5187');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 5188, 'vanilla-148j-c11-s5188');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 5211, 'vanilla-148j-c11-s5211');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 5215, 'vanilla-148j-c11-s5215');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 5229, 'vanilla-148j-c11-s5229');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 5232, 'vanilla-148j-c11-s5232');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 6756, 'vanilla-148j-c11-s6756');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 6808, 'vanilla-148j-c11-s6808');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 8921, 'vanilla-148j-c11-s8921');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 8924, 'vanilla-148j-c11-s8924');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 8925, 'vanilla-148j-c11-s8925');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 8936, 'vanilla-148j-c11-s8936');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 8938, 'vanilla-148j-c11-s8938');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 16689, 'vanilla-148j-c11-s16689');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 16810, 'vanilla-148j-c11-s16810');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 16857, 'vanilla-148j-c11-s16857');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 20484, 'vanilla-148j-c11-s20484');
INSERT INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note) VALUES (0, 1024, 50769, 'vanilla-148j-c11-s50769');

-- ============================================================================
-- End of 04-pretrain-abilities.sql
-- ============================================================================
