-- MARKER_E011_APPLY beta-dk-class-system
-- death-knights.sql
-- Death Knight Level 1-20 Scaling System
-- Issue 206: death-knight-level-1-scaling
-- Issue 167: recreate-missing-sql-files
--
-- Enables Death Knights to start at level 1 like other classes.
-- Abilities are learned progressively from trainers 29194/29195/29196.
--
-- Rewritten 2026-10-17 onto the current trainer tables. The server reads a
-- trainer's lessons from `trainer_spell` (keyed by a trainer list number in
-- `trainer`) and finds a creature's list through `creature_default_trainer`;
-- the three death knight trainers all point at list 13, the game's own
-- death knight lessons (levels 55-80). Until then this step wrote the kit
-- into `npc_trainer`, a table the server no longer reads, so the kit was
-- never offered. Now the kit is a list of its own, number 2060001 (the first
-- of issue 206's block, docs/custom-id-ranges.md), and the three trainers are pointed at it; their original
-- links are saved in `wow_chat_e011_snapshot_creature_default_trainer` so
-- the revert (11-dk-class-system.revert.sql) points them back. Nothing of
-- list 13 is changed.
-- Starting gear is race-specific (handled by playercreateinfo_item).
--
-- Run against acore_world database
-- Updated 2026-04-08: Fixed column names (Strength/Agility/etc instead of str/agi/etc, added BaseHP/BaseMana)

-- {{{ Clean up existing custom entries
DELETE FROM `player_class_stats` WHERE `Class` = 6 AND `Level` BETWEEN 1 AND 54;
DELETE FROM `playercreateinfo_spell_custom` WHERE `classmask` = 32;  -- class 6 = 2^5 = 32
DELETE FROM `playercreateinfo_item` WHERE `class` = 6 AND `race` <> 0 AND `amount` > 0;  -- this step's own rows (amount 1); the game's race-0 removal row and E058's removal rows (amount -1) stay
-- (The old form's rows in `npc_trainer` are left where they are: the
-- server doesn't read that table, and the game ships rows there under the
-- same numbers, which a cleanup would take with them.)
-- }}}

-- {{{ Death Knight Class Stats (levels 1-54)
-- Copy warrior stats for DK levels 1-54 (DKs normally start at 55)
-- This allows low-level DK play with appropriate stats
INSERT INTO `player_class_stats` (`Class`, `Level`, `BaseHP`, `BaseMana`, `Strength`, `Agility`, `Stamina`, `Intellect`, `Spirit`)
SELECT 6, `Level`, `BaseHP`, `BaseMana`, `Strength`, `Agility`, `Stamina`, `Intellect`, `Spirit`
FROM `player_class_stats`
WHERE `Class` = 1 AND `Level` BETWEEN 1 AND 54;
-- }}}

-- {{{ Starting Ability - Blood Strike (level 1)
-- DKs start with only Blood Strike - diseases learned from trainers
INSERT INTO `playercreateinfo_spell_custom` (`racemask`, `classmask`, `Spell`)
VALUES (0, 32, 45902);  -- Blood Strike (basic melee attack)
-- }}}

-- {{{ The death knight kit, levels 2-20: trainer list 2060001
-- One list for all three trainers (they taught the same kit before too).
-- Its kind and greeting are copied from the game's death knight list (13).
INSERT IGNORE INTO `trainer` (`Id`, `Type`, `Requirement`, `Greeting`, `VerifiedBuild`)
    SELECT 2060001, `Type`, `Requirement`, `Greeting`, 0 FROM `trainer` WHERE `Id` = 13;
DELETE FROM `trainer_spell` WHERE `TrainerId` = 2060001;
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`)
VALUES
    (2060001, 45477, 50 , 0, 0, 0, 0, 0, 2 , 0),  -- Icy Touch (ranged, Frost Fever disease)
    (2060001, 45462, 100, 0, 0, 0, 0, 0, 4 , 0),  -- Plague Strike (melee, Blood Plague disease)
    (2060001, 47541, 150, 0, 0, 0, 0, 0, 6 , 0),  -- Death Coil (shadow damage)
    (2060001, 45470, 200, 0, 0, 0, 0, 0, 8 , 0),  -- Death Strike (healing strike for tanking)
    (2060001, 48263, 250, 0, 0, 0, 0, 0, 10, 0),  -- Blood Presence (DPS stance)
    (2060001, 48266, 250, 0, 0, 0, 0, 0, 10, 0),  -- Frost Presence (tank stance)
    (2060001, 48265, 250, 0, 0, 0, 0, 0, 10, 0),  -- Unholy Presence (speed stance)
    (2060001, 50842, 350, 0, 0, 0, 0, 0, 12, 0),  -- Pestilence (spread diseases)
    (2060001, 48721, 350, 0, 0, 0, 0, 0, 12, 0),  -- Blood Boil (AoE disease damage)
    (2060001, 45524, 450, 0, 0, 0, 0, 0, 14, 0),  -- Chains of Ice (ranged snare)
    (2060001, 56222, 450, 0, 0, 0, 0, 0, 14, 0),  -- Dark Command (taunt for tank role)
    (2060001, 45529, 550, 0, 0, 0, 0, 0, 16, 0),  -- Blood Tap (convert blood rune)
    (2060001, 57330, 550, 0, 0, 0, 0, 0, 16, 0),  -- Horn of Winter (group buff)
    (2060001, 48707, 650, 0, 0, 0, 0, 0, 18, 0),  -- Anti-Magic Shell (magic shield)
    (2060001, 43265, 650, 0, 0, 0, 0, 0, 18, 0),  -- Death and Decay (AoE ground effect)
    (2060001, 46584, 750, 0, 0, 0, 0, 0, 20, 0);  -- Raise Dead (summon ghoul)

-- save the three trainers' original links once, then point them at the kit
CREATE TABLE IF NOT EXISTS `wow_chat_e011_snapshot_creature_default_trainer` LIKE `creature_default_trainer`;
INSERT IGNORE INTO `wow_chat_e011_snapshot_creature_default_trainer`
    SELECT * FROM `creature_default_trainer` WHERE `CreatureId` IN (29194, 29195, 29196);
UPDATE `creature_default_trainer` SET `TrainerId` = 2060001 WHERE `CreatureId` IN (29194, 29195, 29196);
-- }}}

-- {{{ Starting Gear - All races get Worn Greatsword
-- playercreateinfo_item: race, class, itemid, amount
-- All DK races get Worn Greatsword (49778) - level 1 two-handed sword

-- Alliance races (Human=1, Dwarf=3, Night Elf=4, Gnome=7, Draenei=11)
INSERT INTO `playercreateinfo_item` (`race`, `class`, `itemid`, `amount`)
VALUES
    (1,  6, 49778, 1),  -- Human DK - Worn Greatsword
    (3,  6, 49778, 1),  -- Dwarf DK - Worn Greatsword
    (4,  6, 49778, 1),  -- Night Elf DK - Worn Greatsword
    (7,  6, 49778, 1),  -- Gnome DK - Worn Greatsword
    (11, 6, 49778, 1);  -- Draenei DK - Worn Greatsword

-- Horde races (Orc=2, Undead=5, Tauren=6, Troll=8, Blood Elf=10)
INSERT INTO `playercreateinfo_item` (`race`, `class`, `itemid`, `amount`)
VALUES
    (2,  6, 49778, 1),  -- Orc DK - Worn Greatsword
    (5,  6, 49778, 1),  -- Undead DK - Worn Greatsword
    (6,  6, 49778, 1),  -- Tauren DK - Worn Greatsword
    (8,  6, 49778, 1),  -- Troll DK - Worn Greatsword
    (10, 6, 49778, 1);  -- Blood Elf DK - Worn Greatsword
-- }}}

-- {{{ Starting Armor (race-specific)
-- Alliance starting armor
INSERT INTO `playercreateinfo_item` (`race`, `class`, `itemid`, `amount`)
VALUES
    -- Human (1) - Recruit's set
    (1, 6, 38, 1),     -- Recruit's Shirt
    (1, 6, 39, 1),     -- Recruit's Pants
    (1, 6, 40, 1),     -- Recruit's Boots
    -- Dwarf (3) - Recruit's set (Dwarf variant)
    (3, 6, 6120, 1),   -- Recruit's Shirt
    (3, 6, 6121, 1),   -- Recruit's Pants
    (3, 6, 6122, 1),   -- Recruit's Boots
    -- Night Elf (4) - Recruit's set (Night Elf variant)
    (4, 6, 23473, 1),  -- Recruit's Shirt
    (4, 6, 23474, 1),  -- Recruit's Pants
    (4, 6, 23475, 1),  -- Recruit's Boots
    -- Gnome (7) - Same as Human
    (7, 6, 38, 1),     -- Recruit's Shirt
    (7, 6, 39, 1),     -- Recruit's Pants
    (7, 6, 40, 1),     -- Recruit's Boots
    -- Draenei (11) - Squire's set
    (11, 6, 23476, 1), -- Squire's Shirt
    (11, 6, 23477, 1), -- Squire's Pants
    (11, 6, 23475, 1); -- Recruit's Boots (shared)

-- Horde starting armor
INSERT INTO `playercreateinfo_item` (`race`, `class`, `itemid`, `amount`)
VALUES
    -- Orc (2) - Brawler's set
    (2, 6, 6125, 1),   -- Brawler's Harness
    (2, 6, 139, 1),    -- Brawler's Pants
    (2, 6, 140, 1),    -- Brawler's Boots
    -- Undead (5) - Thug set
    (5, 6, 2105, 1),   -- Thug Shirt
    (5, 6, 120, 1),    -- Thug Pants
    (5, 6, 121, 1),    -- Thug Boots
    -- Tauren (6) - Brawler's set
    (6, 6, 6125, 1),   -- Brawler's Harness
    (6, 6, 139, 1),    -- Brawler's Pants
    (6, 6, 140, 1),    -- Brawler's Boots
    -- Troll (8) - Brawler's set
    (8, 6, 6125, 1),   -- Brawler's Harness
    (8, 6, 139, 1),    -- Brawler's Pants
    (8, 6, 140, 1),    -- Brawler's Boots
    -- Blood Elf (10) - Squire's set
    (10, 6, 23476, 1), -- Squire's Shirt
    (10, 6, 23477, 1), -- Squire's Pants
    (10, 6, 23475, 1); -- Recruit's Boots (shared)
-- }}}

-- {{{ Ability Progression Reference
-- Level | Ability | Spell ID | Notes
-- ------|---------|----------|-------
--   1   | Blood Strike | 45902 | Starting ability (melee opener)
--   2   | Icy Touch | 45477 | Ranged, applies Frost Fever
--   4   | Plague Strike | 45462 | Melee, applies Blood Plague
--   6   | Death Coil | 47541 | Shadow damage (spellpower based)
--   8   | Death Strike | 45470 | Healing strike for tanking
--  10   | Blood Presence | 48263 | DPS stance
--  10   | Frost Presence | 48266 | Tank stance
--  10   | Unholy Presence | 48265 | Speed stance
--  12   | Pestilence | 50842 | Spread diseases to nearby enemies
--  12   | Blood Boil | 48721 | AoE disease damage
--  14   | Chains of Ice | 45524 | Ranged snare
--  14   | Dark Command | 56222 | Taunt
--  16   | Blood Tap | 45529 | Convert blood rune
--  16   | Horn of Winter | 57330 | Group buff (like paladin blessings)
--  18   | Anti-Magic Shell | 48707 | Magic shield
--  18   | Death and Decay | 43265 | AoE ground effect
--  20   | Raise Dead | 46584 | Summon ghoul
--
-- Removed abilities (too powerful for low level):
-- - Death Grip (too unique/powerful)
-- - Path of Frost (unnecessary utility)
-- - Mind Freeze (paladins don't get interrupt)
-- - Icebound Fortitude (keep kit streamlined)
-- }}}

-- {{{ Verification queries (run manually)
-- SELECT Class, Level, Strength, Agility, Stamina, Intellect, Spirit FROM player_class_stats WHERE Class = 6 AND Level <= 20;
-- SELECT * FROM playercreateinfo_spell_custom WHERE classmask = 32;
-- SELECT * FROM playercreateinfo_item WHERE class = 6;
-- SELECT d.CreatureId, ts.SpellId, ts.ReqLevel FROM creature_default_trainer d JOIN trainer_spell ts ON ts.TrainerId = d.TrainerId WHERE d.CreatureId IN (29194, 29195, 29196) ORDER BY d.CreatureId, ts.ReqLevel;
-- }}}
