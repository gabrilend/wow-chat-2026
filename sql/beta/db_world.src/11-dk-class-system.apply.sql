-- MARKER_E011_APPLY beta-dk-class-system

DELETE FROM `player_class_stats` WHERE `Class` = 6 AND `Level` BETWEEN 1 AND 54;
DELETE FROM `playercreateinfo_spell_custom` WHERE `classmask` = 32;  -- class 6 = 2^5 = 32
DELETE FROM `playercreateinfo_item` WHERE `class` = 6 AND `race` <> 0 AND `amount` > 0;  -- this step's own rows (amount 1); the game's race-0 removal row and E058's removal rows (amount -1) stay

INSERT INTO `player_class_stats` (`Class`, `Level`, `BaseHP`, `BaseMana`, `Strength`, `Agility`, `Stamina`, `Intellect`, `Spirit`)
SELECT 6, `Level`, `BaseHP`, `BaseMana`, `Strength`, `Agility`, `Stamina`, `Intellect`, `Spirit`
FROM `player_class_stats`
WHERE `Class` = 1 AND `Level` BETWEEN 1 AND 54;

INSERT INTO `playercreateinfo_spell_custom` (`racemask`, `classmask`, `Spell`)
VALUES (0, 32, 45902);  -- Blood Strike (basic melee attack)

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

CREATE TABLE IF NOT EXISTS `wow_chat_e011_snapshot_creature_default_trainer` LIKE `creature_default_trainer`;
INSERT IGNORE INTO `wow_chat_e011_snapshot_creature_default_trainer`
    SELECT * FROM `creature_default_trainer` WHERE `CreatureId` IN (29194, 29195, 29196);
UPDATE `creature_default_trainer` SET `TrainerId` = 2060001 WHERE `CreatureId` IN (29194, 29195, 29196);


INSERT INTO `playercreateinfo_item` (`race`, `class`, `itemid`, `amount`)
VALUES
    (1,  6, 49778, 1),  -- Human DK - Worn Greatsword
    (3,  6, 49778, 1),  -- Dwarf DK - Worn Greatsword
    (4,  6, 49778, 1),  -- Night Elf DK - Worn Greatsword
    (7,  6, 49778, 1),  -- Gnome DK - Worn Greatsword
    (11, 6, 49778, 1);  -- Draenei DK - Worn Greatsword

INSERT INTO `playercreateinfo_item` (`race`, `class`, `itemid`, `amount`)
VALUES
    (2,  6, 49778, 1),  -- Orc DK - Worn Greatsword
    (5,  6, 49778, 1),  -- Undead DK - Worn Greatsword
    (6,  6, 49778, 1),  -- Tauren DK - Worn Greatsword
    (8,  6, 49778, 1),  -- Troll DK - Worn Greatsword
    (10, 6, 49778, 1);  -- Blood Elf DK - Worn Greatsword

INSERT INTO `playercreateinfo_item` (`race`, `class`, `itemid`, `amount`)
VALUES
    (1, 6, 38, 1),     -- Recruit's Shirt
    (1, 6, 39, 1),     -- Recruit's Pants
    (1, 6, 40, 1),     -- Recruit's Boots
    (3, 6, 6120, 1),   -- Recruit's Shirt
    (3, 6, 6121, 1),   -- Recruit's Pants
    (3, 6, 6122, 1),   -- Recruit's Boots
    (4, 6, 23473, 1),  -- Recruit's Shirt
    (4, 6, 23474, 1),  -- Recruit's Pants
    (4, 6, 23475, 1),  -- Recruit's Boots
    (7, 6, 38, 1),     -- Recruit's Shirt
    (7, 6, 39, 1),     -- Recruit's Pants
    (7, 6, 40, 1),     -- Recruit's Boots
    (11, 6, 23476, 1), -- Squire's Shirt
    (11, 6, 23477, 1), -- Squire's Pants
    (11, 6, 23475, 1); -- Recruit's Boots (shared)

INSERT INTO `playercreateinfo_item` (`race`, `class`, `itemid`, `amount`)
VALUES
    (2, 6, 6125, 1),   -- Brawler's Harness
    (2, 6, 139, 1),    -- Brawler's Pants
    (2, 6, 140, 1),    -- Brawler's Boots
    (5, 6, 2105, 1),   -- Thug Shirt
    (5, 6, 120, 1),    -- Thug Pants
    (5, 6, 121, 1),    -- Thug Boots
    (6, 6, 6125, 1),   -- Brawler's Harness
    (6, 6, 139, 1),    -- Brawler's Pants
    (6, 6, 140, 1),    -- Brawler's Boots
    (8, 6, 6125, 1),   -- Brawler's Harness
    (8, 6, 139, 1),    -- Brawler's Pants
    (8, 6, 140, 1),    -- Brawler's Boots
    (10, 6, 23476, 1), -- Squire's Shirt
    (10, 6, 23477, 1), -- Squire's Pants
    (10, 6, 23475, 1); -- Recruit's Boots (shared)


