-- MARKER_E008_APPLY vanilla-remove-flight-paths
-- SHARED: the basic profile (issue 155c) reads this file too (E-patches.sh,
-- _shared_sql_src) and applies it to its own databases. Edits land on both
-- vanilla and basic; if basic ever needs different content, give it its
-- own file under sql/basic/ and drop it from the sharing table.
-- ============================================================================
-- 03-remove-flight-paths.sql (148i) — APPLY SOURCE
-- ============================================================================
-- Apply-form SOURCE for E008. The E-patch (apply direction) cp's this
-- file to ${DIR}/sql/vanilla/db_world/03-remove-flight-paths.sql, which
-- AC's UpdateFetcher picks up on next worldserver boot via the include
-- row registered by _register_vanilla_world_dir_once. The unpatch
-- direction overwrites the active file with an inline revert heredoc;
-- this source file stays intact so the next apply can re-stage it.
-- ============================================================================
-- Removes the flightmaster function from every NPC and replaces gossip with
-- a unique 2-sentence flavor line per NPC for Eastern Kingdoms and Kalimdor
-- flightmasters. Outland and Northrend flightmasters have their function
-- cleared but no dialogue assigned — vanilla's level-40 cap means players
-- cannot reach those continents.
--
-- Database: acore_world_vanilla
--
-- Application: AzerothCore's UpdateFetcher discovers this file via an
-- `updates_include` row pointing at this file's parent directory. The
-- E008 patch (patches/E-patches.sh) idempotently inserts that row in
-- acore_world_vanilla.updates_include so the worldserver auto-applies
-- this file on next boot. AC tracks application via the `updates` table
-- with content hashing — edits here are auto-detected and re-applied
-- (Updates.Redundancy = 1).
--
-- The DELETE-then-INSERT pattern below is what AC's data/sql/custom/
-- docs call "re-applicable SQL" — safe to run any number of times.
-- ID range 90000–90999 is reserved for vanilla profile gossip/text
-- injections; do not collide from other vanilla migrations.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Clear the flightmaster bit (UNIT_NPC_FLAG_FLIGHTMASTER = 0x2000 = 8192)
--    from every creature_template that currently has it set. Covers EK,
--    Kalimdor, Outland, and Northrend. This is the load-bearing mechanic —
--    even if a player reaches Outland somehow, they still can't take a taxi.
-- ----------------------------------------------------------------------------

UPDATE creature_template
SET npcflag = npcflag & ~8192
WHERE npcflag & 8192;

-- ----------------------------------------------------------------------------
-- 2. Clean prior runs of this migration so re-applying is idempotent.
--    The 90000-range gossip_menu and npc_text rows are owned by this script.
-- ----------------------------------------------------------------------------

DELETE FROM gossip_menu WHERE MenuID BETWEEN 90000 AND 90999;
DELETE FROM npc_text WHERE ID BETWEEN 90000 AND 90999;

-- ----------------------------------------------------------------------------
-- 3. Insert unique flavor text per Eastern Kingdoms + Kalimdor flightmaster.
--    Each NPC gets its own npc_text row (IDs 90001..90069) and a matching
--    gossip_menu row (same IDs), then the creature_template gossip_menu_id
--    is repointed to the new menu. The text is in text0_0.
-- ----------------------------------------------------------------------------

-- ---------- Eastern Kingdoms — Alliance Gryphon Masters (Stormwind area) ----

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90001, 'The royal aviary stands silent by Crown decree. Even longdrinks taste flatter when the gryphons do not wing overhead.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90001, 90001);
UPDATE creature_template SET gossip_menu_id = 90001 WHERE entry = 352;   -- Dungar Longdrink (Stormwind)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90002, 'Defias scouts spook the gryphons something fierce. Until I can convince them to fly through bandit country, you will be walking the King''s Road like everyone else.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90002, 90002);
UPDATE creature_template SET gossip_menu_id = 90002 WHERE entry = 523;   -- Thor (Sentinel Hill, Westfall)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90003, 'A black dragon scared off my flock last week. Until they return, the orcs of Stonewatch Keep have free reign of these skies.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90003, 90003);
UPDATE creature_template SET gossip_menu_id = 90003 WHERE entry = 931;   -- Ariena Stormfeather (Lakeshire)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90004, 'The Wildhammer keep their gryphons grounded these days. We trust the road more than we trust the wind.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90004, 90004);
UPDATE creature_template SET gossip_menu_id = 90004 WHERE entry = 1571;  -- Shellei Brondir (Aerie Peak)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90005, 'Worgen tore the wings off two gryphons last month. Find your own way through the dark woods — the rest of mine stay caged.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90005, 90005);
UPDATE creature_template SET gossip_menu_id = 90005 WHERE entry = 2409;  -- Felicia Maline (Darkshire, Duskwood)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90006, 'Argent Dawn business keeps the gryphons sworn to other duties. You will walk to Tyr''s Hand on your own feet, paladin.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90006, 90006);
UPDATE creature_template SET gossip_menu_id = 90006 WHERE entry = 2432;  -- Darla Harris (Light's Hope, EPL)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90007, 'The Scourge still lurks beyond the fences and I will not lose another gryphon to them. The dead will not catch you afoot if you keep moving.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90007, 90007);
UPDATE creature_template SET gossip_menu_id = 90007 WHERE entry = 2835;  -- Cedrik Prose (Chillwind Camp, WPL)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90008, 'The harbor master commands all gryphons grounded while the new docks are built. The boats run still, if you can stomach the salt.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90008, 90008);
UPDATE creature_template SET gossip_menu_id = 90008 WHERE entry = 8609;  -- Alexandra Constantine (Stormwind Harbor)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90009, 'Black dragons own these skies now. I will not send a single feather into the Searing Gorge until that changes.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90009, 90009);
UPDATE creature_template SET gossip_menu_id = 90009 WHERE entry = 12596; -- Bibilfaz Featherwhistle (Morgan's Vigil, Burning Steppes)

-- ---------- Eastern Kingdoms — Horde Wind Rider Masters ---------------------

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90010, 'The Forsaken plague-master has need of the wyverns this season. None to spare for travel — walk north along the Lordamere Lake if you must.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90010, 90010);
UPDATE creature_template SET gossip_menu_id = 90010 WHERE entry = 1387;  -- Thysta (Tarren Mill)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90011, 'The swamp itself drinks any wyvern brave enough to land. Take the marsh roads with your eyes open, troll.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90011, 90011);
UPDATE creature_template SET gossip_menu_id = 90011 WHERE entry = 2851;  -- Urda (Stonard, Swamp of Sorrows)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90012, 'The Wildhammer poison our wyverns from their own peaks. We keep the flock penned until that war ends — and that war will not end.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90012, 90012);
UPDATE creature_template SET gossip_menu_id = 90012 WHERE entry = 2858;  -- Gringer (Revantusk, Hinterlands)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90013, 'The wyverns hate the dust as much as I do. They will fly again when something worth flying for lives out here.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90013, 90013);
UPDATE creature_template SET gossip_menu_id = 90013 WHERE entry = 2861;  -- Gorrik (Kargath, Badlands)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90014, 'Drakes from the volcano have eaten three of mine. The path to Searing Gorge is yours to walk.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90014, 90014);
UPDATE creature_template SET gossip_menu_id = 90014 WHERE entry = 3305;  -- Grisha (Flame Crest, Burning Steppes)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90015, 'Trolls have shot the last two wyverns out of the canopy. Walk to Booty Bay if you want passage — the jungle takes who it wants either way.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90015, 90015);
UPDATE creature_template SET gossip_menu_id = 90015 WHERE entry = 4314;  -- Gorkas (Grom'gol, STV)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90016, 'The wyverns have grown old and the young ones will not take riders yet. Wait a season, or two, and we will see.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90016, 90016);
UPDATE creature_template SET gossip_menu_id = 90016 WHERE entry = 6026;  -- Breyk (Karazhan/STV outpost)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90017, 'Hammerfall''s wyverns stand grounded by ogre attacks on the roost. The road south is no kinder, but at least you can fight what comes at you.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90017, 90017);
UPDATE creature_template SET gossip_menu_id = 90017 WHERE entry = 13177; -- Vahgruk (Hammerfall, Arathi)

-- ---------- Eastern Kingdoms — Argent Dawn / Misc ---------------------------

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90018, 'Light''s Hope keeps the skies clear for paladin processions only. Even gold does not buy a wing this month.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90018, 90018);
UPDATE creature_template SET gossip_menu_id = 90018 WHERE entry = 37888; -- Frax Bucketdrop (Argent)

-- ---------- Eastern Kingdoms — Ironforge / Dwarven Gryphon Masters ----------

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90019, 'Magni Bronzebeard himself ordered the gryphons stabled. The Deeprun Tram still runs, if you have a copper for the fare.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90019, 90019);
UPDATE creature_template SET gossip_menu_id = 90019 WHERE entry = 1572;  -- Thorgrum Borrelson (Ironforge)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90020, 'The dam needs every spare hand watching it. Even the gryphon keepers stand vigil on the wall.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90020, 90020);
UPDATE creature_template SET gossip_menu_id = 90020 WHERE entry = 1573;  -- Gryth Thurden (Loch Modan dam)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90021, 'Trogg scouts spook the flock at dawn. Until the dwarves clear them, the gryphons stay penned.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90021, 90021);
UPDATE creature_template SET gossip_menu_id = 90021 WHERE entry = 2299;  -- Borgus Stoutarm (Thelsamar)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90022, 'Syndicate raiders run the roads but they have no answer for a sharp pickaxe. Take the road and trust your boots, dwarf.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90022, 90022);
UPDATE creature_template SET gossip_menu_id = 90022 WHERE entry = 2859;  -- Gyll (Refuge Pointe, Arathi)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90023, 'Dark Iron raids have grounded the flock for the third week running. The walls hold; the skies do not.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90023, 90023);
UPDATE creature_template SET gossip_menu_id = 90023 WHERE entry = 2941;  -- Lanie Reed (Morgan's Vigil)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90024, 'The dragonkin have made these skies their own. Until the Reds patrol again, the gryphons stay grounded.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90024, 90024);
UPDATE creature_template SET gossip_menu_id = 90024 WHERE entry = 12617; -- Khaelyn Steelwing (Menethil)

-- ---------- Eastern Kingdoms — Forsaken Bat Handlers ------------------------

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90025, 'The plague-bats hunger for fresher meat than yours, traveler. Walk the King''s Road instead — it is haunted, but it is quicker.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90025, 90025);
UPDATE creature_template SET gossip_menu_id = 90025 WHERE entry = 2226;  -- Karos Razok

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90026, 'The bats refuse to fly past the wall of trees the elves have raised. Even the Forsaken respect the wood, in a manner.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90026, 90026);
UPDATE creature_template SET gossip_menu_id = 90026 WHERE entry = 2389;  -- Zarise (Sepulcher)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90027, 'Undercity''s roost is empty. The Apothecary Society needs every bat for plague trials — speak with them if you want one in flight again.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90027, 90027);
UPDATE creature_template SET gossip_menu_id = 90027 WHERE entry = 4551;  -- Michael Garrett (Undercity)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90028, 'The bats sleep through the day and refuse to wake. Try the road, friend; the night will find you either way.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90028, 90028);
UPDATE creature_template SET gossip_menu_id = 90028 WHERE entry = 12636; -- Georgia

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90029, 'The Argent Dawn keeps the woods south of here, and the bats sense their wards. None will fly while the paladins burn the dead.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90029, 90029);
UPDATE creature_template SET gossip_menu_id = 90029 WHERE entry = 37915; -- Timothy Cunningham

-- ---------- Eastern Kingdoms — Misc factions --------------------------------

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90030, 'Stormpike business in Alterac keeps every gryphon needed for the campaign. The pass through the Hillsbrad foothills is your road.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90030, 90030);
UPDATE creature_template SET gossip_menu_id = 90030 WHERE entry = 8018;  -- Guthrum Thunderfist (Stormpike)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90031, 'The cartel charges by the hour and the rates have gone up. Come back when you have got gold to lose.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90031, 90031);
UPDATE creature_template SET gossip_menu_id = 90031 WHERE entry = 24366; -- Nizzle (goblin)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90032, 'These wings do not fly today. Take the south road; it favors travelers willing to whistle as they walk.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90032, 90032);
UPDATE creature_template SET gossip_menu_id = 90032 WHERE entry = 29480; -- Grimwing

-- ---------- Kalimdor — Alliance Gryphon Masters -----------------------------

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90033, 'Lady Proudmoore has grounded the flock pending word from Stormwind. Until the seas calm and the king answers, the boats are your only passage.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90033, 90033);
UPDATE creature_template SET gossip_menu_id = 90033 WHERE entry = 7823;  -- Bera Stonehammer (Theramore)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90034, 'Lady Proudmoore''s orders: every gryphon stays harnessed against the next storm. There is always a next storm here.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90034, 90034);
UPDATE creature_template SET gossip_menu_id = 90034 WHERE entry = 4321;  -- Baldruc (Theramore)

-- ---------- Kalimdor — Horde Wind Rider Masters -----------------------------

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90035, 'Centaur raiders have shot down four wyverns this week. Walk the road south, but watch the dust clouds — they ride fast.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90035, 90035);
UPDATE creature_template SET gossip_menu_id = 90035 WHERE entry = 3310;  -- Doras (Crossroads)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90036, 'Thrall''s command: no wyverns leave the city. The harbingers of war keep their mounts close in case the war comes today.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90036, 90036);
UPDATE creature_template SET gossip_menu_id = 90036 WHERE entry = 3615;  -- Devrak (Orgrimmar)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90037, 'The marsh swallows wyverns whole. Even the bog beasts know better than to fly low here.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90037, 90037);
UPDATE creature_template SET gossip_menu_id = 90037 WHERE entry = 7824;  -- Bulkrek Ragefist (Brackenwall)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90038, 'The wyverns rest while the elements churn south. We respect the storm, even in Horde lands.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90038, 90038);
UPDATE creature_template SET gossip_menu_id = 90038 WHERE entry = 8610;  -- Kroum

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90039, 'The night elves shoot any wyvern in sight near the rampart. Walk the road or wait for nightfall — neither is safe, but one is quieter.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90039, 90039);
UPDATE creature_template SET gossip_menu_id = 90039 WHERE entry = 11139; -- Yugrek (Mor'shan)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90040, 'Cairne Bloodhoof prefers we walk these plains. The bluffs respect those who travel by foot.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90040, 90040);
UPDATE creature_template SET gossip_menu_id = 90040 WHERE entry = 11899; -- Shardi (Mulgore area)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90041, 'Centaur raids closed the wyvern paths to Desolace. South or west, all on hoof now.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90041, 90041);
UPDATE creature_template SET gossip_menu_id = 90041 WHERE entry = 11900; -- Brakkar

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90042, 'The naga of Zoram Strand strike anything that lifts above the trees. Walk the coast or take the ship — your call.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90042, 90042);
UPDATE creature_template SET gossip_menu_id = 90042 WHERE entry = 11901; -- Andruk (Zoram'gar)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90043, 'The wyvern roost is empty until the supply caravans return from Razor Hill. Walk; it is a Horde road, it will see you safe.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90043, 90043);
UPDATE creature_template SET gossip_menu_id = 90043 WHERE entry = 12616; -- Vhulgra

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90044, 'Quilboar attacks on the wyvern pens. We are rebuilding — come back when the noise stops.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90044, 90044);
UPDATE creature_template SET gossip_menu_id = 90044 WHERE entry = 12740; -- Faustron (Camp Taurajo)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90045, 'I have already told you — the centaur have grounded us. Do not make me repeat myself, brother.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90045, 90045);
UPDATE creature_template SET gossip_menu_id = 90045 WHERE entry = 31426; -- Doras (duplicate spawn — gruffer reply)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90046, 'The fel taint poisons even the air. The wyverns refuse to breathe it — and I will not ask them to.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90046, 90046);
UPDATE creature_template SET gossip_menu_id = 90046 WHERE entry = 22931; -- Gorrim (Emerald Circle, Felwood)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90047, 'The Steamwheedle paid me to ground the flock during their new shipping contract. Walk to Booty Bay if you must — same difference.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90047, 90047);
UPDATE creature_template SET gossip_menu_id = 90047 WHERE entry = 16227; -- Bragok (Ratchet)

-- ---------- Kalimdor — Night Elf Hippogryph Masters -------------------------

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90048, 'The Cenarion Circle has grounded all hippogryphs while we heal the corrupted groves. Walk softly, druid; the woods are watching.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90048, 90048);
UPDATE creature_template SET gossip_menu_id = 90048 WHERE entry = 3838;  -- Vesprystus

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90049, 'Auberdine still mourns its dead, and the hippogryphs sense the grief. They will not fly until the wounds close — and they may never close.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90049, 90049);
UPDATE creature_template SET gossip_menu_id = 90049 WHERE entry = 3841;  -- Caylais Moonfeather (Auberdine)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90050, 'The Horde watches every flight path with hidden archers. Until the war calms, you walk under Elune''s eye, not on Her winds.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90050, 90050);
UPDATE creature_template SET gossip_menu_id = 90050 WHERE entry = 4267;  -- Daelyshia (Astranaar)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90051, 'The corruption fouls the wind currents. The hippogryphs cough and circle; they will not bear riders through poisoned air.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90051, 90051);
UPDATE creature_template SET gossip_menu_id = 90051 WHERE entry = 4319;  -- Thyssiana (Talonbranch Glade)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90052, 'The earth elementals stir below us. The hippogryphs will not fly while the ground itself worries them.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90052, 90052);
UPDATE creature_template SET gossip_menu_id = 90052 WHERE entry = 4407;  -- Teloren (Stardust Spire)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90053, 'Teldrassil''s branches sway with bad omens. Until the World Tree is calm, no hippogryph will leave its branches.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90053, 90053);
UPDATE creature_template SET gossip_menu_id = 90053 WHERE entry = 6706;  -- Baritanas Skyriver (Rut'theran)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90054, 'The naga have brought storms from the sea. The hippogryphs sense danger in every gust.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90054, 90054);
UPDATE creature_template SET gossip_menu_id = 90054 WHERE entry = 8019;  -- Fyldren Moonfeather

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90055, 'The Furbolg have warned of bad spirits in the wind. The hippogryphs heed warnings older than your concerns, traveler.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90055, 90055);
UPDATE creature_template SET gossip_menu_id = 90055 WHERE entry = 10897; -- Sindrayl

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90056, 'The Horde scouts have been seen with poisoned arrows. The hippogryphs will not risk a tainted wound for any rider.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90056, 90056);
UPDATE creature_template SET gossip_menu_id = 90056 WHERE entry = 11138; -- Maethrya

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90057, 'The satyrs have grown bold in our woods. The hippogryphs hunt them now — when they return to perch, perhaps we will talk again.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90057, 90057);
UPDATE creature_template SET gossip_menu_id = 90057 WHERE entry = 12577; -- Jarrodenus

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90058, 'The moon is dark tonight and the hippogryphs will not fly without Her light. Patience, traveler, and walk by lantern.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90058, 90058);
UPDATE creature_template SET gossip_menu_id = 90058 WHERE entry = 12578; -- Mishellena

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90059, 'Moonglade keeps her own peace. No hippogryph leaves the sanctuary while the Cenarion Council deliberates — and they will deliberate forever.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90059, 90059);
UPDATE creature_template SET gossip_menu_id = 90059 WHERE entry = 15177; -- Cloud Skydancer (Nighthaven)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90060, 'Forest Song stands close to the front. Every hippogryph is needed for scouts, not couriers — speak to a sentinel if you need urgent passage.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90060, 90060);
UPDATE creature_template SET gossip_menu_id = 90060 WHERE entry = 22935; -- Suralais Farwind (Forest Song)

-- ---------- Kalimdor — Tauren Wind Rider Masters ----------------------------

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90061, 'Cairne Bloodhoof has spoken: the wyverns rest while we mourn. The lifts of the bluff still work — that is the Earth Mother''s gift.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90061, 90061);
UPDATE creature_template SET gossip_menu_id = 90061 WHERE entry = 2995;  -- Tal (Thunder Bluff)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90062, 'The Feralas mists hide too much. The wyverns will not fly into clouds that hide death — and these clouds do.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90062, 90062);
UPDATE creature_template SET gossip_menu_id = 90062 WHERE entry = 4312;  -- Tharm (Feralas)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90063, 'The Quilboar raids have taken three wyverns this moon. I will not send a fourth into the same fate.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90063, 90063);
UPDATE creature_template SET gossip_menu_id = 90063 WHERE entry = 4317;  -- Nyse (Camp Taurajo)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90064, 'The corruption stains the Felwood air. No wyvern with self-respect will breathe it.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90064, 90064);
UPDATE creature_template SET gossip_menu_id = 90064 WHERE entry = 6726;  -- Thalon (Bloodvenom Post, Felwood)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90065, 'The Galak centaur have closed the canyon to wing-flight. We descend by lift, like the elders before us.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90065, 90065);
UPDATE creature_template SET gossip_menu_id = 90065 WHERE entry = 8020;  -- Shyn (Freewind Post, Thousand Needles)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90066, 'The earth speaks of unrest below. The wyverns sense it and refuse the air.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90066, 90066);
UPDATE creature_template SET gossip_menu_id = 90066 WHERE entry = 10378; -- Omusa Thunderhorn (Camp Mojache)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90067, 'The winds themselves are angry. Even a tamer cannot ask wyverns to ride them.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90067, 90067);
UPDATE creature_template SET gossip_menu_id = 90067 WHERE entry = 15178; -- Runk Windtamer

-- ---------- Kalimdor — Goblin / Misc ----------------------------------------

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90068, 'The cartel hiked the gryph-tax. Pay it or walk it, your choice — and the road has the better view anyway.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90068, 90068);
UPDATE creature_template SET gossip_menu_id = 90068 WHERE entry = 10583; -- Gryfe (Gadgetzan goblin)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90069, 'The silithid swarm any wing that crosses the wasteland. I will not lose another flight to that hive.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90069, 90069);
UPDATE creature_template SET gossip_menu_id = 90069 WHERE entry = 23612; -- Dyslix Silvergrub (Silithus)

-- ---------- Outland map (530): draenei and blood elf home zones, then Outland --
-- Added 2026-09-23 (issue 155c). The basic profile leaves Outland open at
-- its level-60 cap, and the draenei / blood elf zones share map 530, so these
-- 35 had no flavor line. Outland lines avoid naming the NPC's outpost: which
-- outpost each one serves was not verified, so no place is claimed.

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90070, 'The hippogryphs will not cross water the crash has poisoned. The isle is small, friend; your legs will learn it quickly.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90070, 90070);
UPDATE creature_template SET gossip_menu_id = 90070 WHERE entry = 17555; -- Stephanos (The Exodar)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90071, 'The red crystals have soured the air over Bloodmyst. No rider of mine flies through it until the Watch says it is clean.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90071, 90071);
UPDATE creature_template SET gossip_menu_id = 90071 WHERE entry = 17554; -- Laando (Blood Watch, Bloodmyst)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90072, 'The Magisters have grounded every dragonhawk until the leylines steady. The roads of Eversong are still beautiful. Walk them.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90072, 90072);
UPDATE creature_template SET gossip_menu_id = 90072 WHERE entry = 16189; -- Skymaster Sunwing (Silvermoon)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90073, 'The Scourge shoot anything that flies over the Dead Scar. I will not send a dragonhawk to die for an errand.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90073, 90073);
UPDATE creature_template SET gossip_menu_id = 90073 WHERE entry = 16192; -- Skymistress Gloaming (Tranquillien)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90074, 'Troll drums spook the birds, and troll spears finish the job. Rotor''s in pieces. Come back never, maybe.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90074, 90074);
UPDATE creature_template SET gossip_menu_id = 90074 WHERE entry = 24851; -- Kiz Coilspanner (Zul'Aman)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90075, 'The Sunwell''s light blinds the dragonhawks on approach. What comes to this isle comes by boat, and what leaves it walks.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90075, 90075);
UPDATE creature_template SET gossip_menu_id = 90075 WHERE entry = 26560; -- Ohura (Isle of Quel'Danas)

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90076, 'The sky over this land is full of burning things that are not stars. My flock stays on the ground, and so should you.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90076, 90076);
UPDATE creature_template SET gossip_menu_id = 90076 WHERE entry = 21766; -- Alieshor

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90077, 'Gryphons were bred for Azeroth''s winds. These ones howl with fel. I will not take them up.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90077, 90077);
UPDATE creature_template SET gossip_menu_id = 90077 WHERE entry = 18939; -- Brubeck Stormfoot

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90078, 'Our patrons ask much of us, and a clear sky is not among what they can give. No flights.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90078, 90078);
UPDATE creature_template SET gossip_menu_id = 90078 WHERE entry = 19581; -- Maddix

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90079, 'Wind riders do not fly under a green sky. Walk, and keep your weapon in your hand.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90079, 90079);
UPDATE creature_template SET gossip_menu_id = 90079 WHERE entry = 19317; -- Drek'Gol

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90080, 'Arakkoa shoot at anything with feathers they do not own. The road is slower. The road is also alive.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90080, 90080);
UPDATE creature_template SET gossip_menu_id = 90080 WHERE entry = 18809; -- Furnan Skysoar

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90081, 'The hippogryphs will not leave the ground while the ogres keep their fires lit on every hill.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90081, 90081);
UPDATE creature_template SET gossip_menu_id = 90081 WHERE entry = 18789; -- Furgu

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90082, 'The trees here drink shadow. My riders came back pale and silent. No more.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90082, 90082);
UPDATE creature_template SET gossip_menu_id = 90082 WHERE entry = 18807; -- Kerna

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90083, 'Refugees fill every roost in the city. I have beds for birds or beds for people, and people win.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90083, 90083);
UPDATE creature_template SET gossip_menu_id = 90083 WHERE entry = 18940; -- Nutral

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90084, 'Fel reavers walk the plains below. A wind rider''s shadow is enough to turn their heads.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90084, 90084);
UPDATE creature_template SET gossip_menu_id = 90084 WHERE entry = 19558; -- Amilya Airheart

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90085, 'The wind here carries the smell of the old clans. The wyverns remember it and will not go.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90085, 90085);
UPDATE creature_template SET gossip_menu_id = 90085 WHERE entry = 18808; -- Gursha

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90086, 'Every gryphon I had is flying supply to the front. You want the front? Start walking toward the fire.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90086, 90086);
UPDATE creature_template SET gossip_menu_id = 90086 WHERE entry = 16822; -- Flightmaster Krill Bitterhue

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90087, 'The Legion''s fliers own the air here. On the ground you might be one of a hundred targets. Up there you are the only one.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90087, 90087);
UPDATE creature_template SET gossip_menu_id = 90087 WHERE entry = 18942; -- Innalia

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90088, 'Came through the Portal with twelve birds. Have four. The other eight flew one route each.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90088, 90088);
UPDATE creature_template SET gossip_menu_id = 90088 WHERE entry = 18931; -- Amish Wildhammer

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90089, 'The Portal is at our backs and the Legion is in front. Nobody here has time to fly tourists.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90089, 90089);
UPDATE creature_template SET gossip_menu_id = 90089 WHERE entry = 18930; -- Vlagga Freyfeather

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90090, 'Something in the mountains eats wind riders. I stopped counting, and I stopped sending them.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90090, 90090);
UPDATE creature_template SET gossip_menu_id = 90090 WHERE entry = 20762; -- Gur'zil

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90091, 'Spores in the air rot the feathers. My hippogryphs stay dry, and you walk through the marsh.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90091, 90091);
UPDATE creature_template SET gossip_menu_id = 90091 WHERE entry = 18785; -- Kuma

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90092, 'The giants of the bog swat fliers like flies. Take the boardwalks, and step lightly.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90092, 90092);
UPDATE creature_template SET gossip_menu_id = 90092 WHERE entry = 18788; -- Munci

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90093, 'The broken land here has no safe place to land. A wind rider that cannot land does not come home.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90093, 90093);
UPDATE creature_template SET gossip_menu_id = 90093 WHERE entry = 18791; -- Du'ga

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90094, 'The Horde needs every rider for the war. What is left for travellers is a road and good boots.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90094, 90094);
UPDATE creature_template SET gossip_menu_id = 90094 WHERE entry = 16587; -- Barley

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90095, 'Storms off the rift knock gryphons out of the sky. I''ve buried enough good birds. Go on foot.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90095, 90095);
UPDATE creature_template SET gossip_menu_id = 90095 WHERE entry = 20234; -- Runetog Wildhammer

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90096, 'The Cenarion Circle asked us to keep the hippogryphs grounded while the land heals. We keep our promises.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90096, 90096);
UPDATE creature_template SET gossip_menu_id = 90096 WHERE entry = 22485; -- Halu

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90097, 'Nether storms scrambled my compass and my gryphons'' heads. Neither points north anymore.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90097, 90097);
UPDATE creature_template SET gossip_menu_id = 90097 WHERE entry = 21107; -- Rip Pedalslam

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90098, 'The ridge winds tear the netherwings apart. They will not fly for me, and I do not blame them.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90098, 90098);
UPDATE creature_template SET gossip_menu_id = 90098 WHERE entry = 22455; -- Sky-Master Maxxor

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90099, 'The marsh is sick, and the hippogryphs feel it in their wings. We wait for it to heal.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90099, 90099);
UPDATE creature_template SET gossip_menu_id = 90099 WHERE entry = 18937; -- Amerun Leafshade

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90100, 'The earth spirits here are angry. A wind rider flies into that anger and does not come back.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90100, 90100);
UPDATE creature_template SET gossip_menu_id = 90100 WHERE entry = 18953; -- Unoke Tenderhoof

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90101, 'Mana-storms. Every day, mana-storms. My birds glow now. I am not sending glowing birds anywhere.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90101, 90101);
UPDATE creature_template SET gossip_menu_id = 90101 WHERE entry = 20515; -- Harpax

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90102, 'The Circle has asked every rider to stay grounded. Tread softly; you are walking on a healing land.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90102, 90102);
UPDATE creature_template SET gossip_menu_id = 90102 WHERE entry = 22216; -- Fhyn Leafshadow

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90103, 'The netherwing drakes chase anything in their sky. You would be lunch before you were halfway.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90103, 90103);
UPDATE creature_template SET gossip_menu_id = 90103 WHERE entry = 18938; -- Krexcil

INSERT INTO npc_text (ID, text0_0, lang0, Probability0) VALUES
(90104, 'Goblin engineering built this tower. Goblin engineering also can''t keep a bird aloft in a nether storm. Walk, pal.', 0, 1.0);
INSERT INTO gossip_menu (MenuID, TextID) VALUES (90104, 90104);
UPDATE creature_template SET gossip_menu_id = 90104 WHERE entry = 19583; -- Grennik

-- ----------------------------------------------------------------------------
-- Re-enable the GOSSIP npcflag (bit 1) on every grounded flightmaster that
-- received a flavor menu above. The npcflag clear at the top only stripped the
-- flightmaster bit (8192); without the GOSSIP bit the assigned 90xxx menu can
-- never open, and the core logs "has assigned gossip menu ... but npcflag does
-- not include UNIT_NPC_FLAG_GOSSIP" once per NPC. Keyed on the 90000-90999
-- menu range so only our authored dialogues get the flag — de-flighted masters
-- without a flavor line stay silent.
-- ----------------------------------------------------------------------------
UPDATE creature_template SET npcflag = npcflag | 1 WHERE gossip_menu_id BETWEEN 90000 AND 90999;

-- ============================================================================
-- End of 03-remove-flight-paths.sql
-- 69 unique dialogues authored for EK + Kalimdor flightmasters, plus 35 for
-- every flightmaster spawned on map 530 (draenei and blood elf home zones and
-- Outland; added 2026-09-23 for the basic profile, which reaches Outland).
-- The remaining flightmasters (Northrend, and templates never spawned) keep
-- their original gossip: no basic or vanilla character reaches Northrend.
-- The npcflag clear at the top of this file still applies to them.
-- ============================================================================
