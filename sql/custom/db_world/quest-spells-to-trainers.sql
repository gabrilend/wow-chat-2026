-- quest-spells-to-trainers.sql
-- Adds quest-learned abilities to class trainers
-- Issue 140: quest-spells-to-trainers
-- Issue 167: recreate-missing-sql-files
--
-- Many class abilities in vanilla WoW require quest completion.
-- Since our server has no quest NPCs, we add these abilities to trainers instead.
-- Players can train them at the appropriate level without needing quests.
--
-- Run against acore_world database

-- {{{ Trainer Template IDs Reference
-- Warrior: 200001, 200002
-- Paladin: 200003, 200004, 200020
-- Druid: 200005, 200006
-- Mage: 200007, 200008
-- Warlock: 200009, 200010
-- Priest: 200011, 200012
-- Hunter: 200013, 200014
-- Rogue: 200015, 200016
-- Shaman: 200017, 200018
-- }}}

-- {{{ Clean up existing custom entries if they exist
-- We use negative SpellID values or specific ranges to identify our custom entries
-- Actually, let's delete by specific spell IDs we're adding to avoid conflicts

-- Warrior quest spells
DELETE FROM `npc_trainer` WHERE `ID` IN (200001, 200002) AND `SpellID` IN (71, 355, 7386);

-- Paladin quest spells
DELETE FROM `npc_trainer` WHERE `ID` IN (200003, 200004, 200020) AND `SpellID` IN (7328);

-- Hunter quest spells
DELETE FROM `npc_trainer` WHERE `ID` IN (200013, 200014) AND `SpellID` IN (883, 982, 1515, 6991, 2641);

-- Rogue quest spells
DELETE FROM `npc_trainer` WHERE `ID` IN (200015, 200016) AND `SpellID` IN (2835, 3420);

-- Shaman quest spells
DELETE FROM `npc_trainer` WHERE `ID` IN (200017, 200018) AND `SpellID` IN (8071, 3599, 5394, 8184);

-- Warlock quest spells
DELETE FROM `npc_trainer` WHERE `ID` IN (200009, 200010) AND `SpellID` IN (697, 712);

-- Druid quest spells
DELETE FROM `npc_trainer` WHERE `ID` IN (200005, 200006) AND `SpellID` IN (5487, 6795, 6807, 8998);
-- }}}

-- {{{ Warrior (Level 10 Quest: The Affray / Brutal Armor)
-- Defensive Stance, Taunt, and Sunder Armor are granted through class quests
-- npc_trainer: ID, SpellID, MoneyCost, ReqSkillLine, ReqSkillRank, ReqLevel, ReqSpell

-- Warrior Trainer 1 (Alliance)
INSERT INTO `npc_trainer` (`ID`, `SpellID`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqLevel`, `ReqSpell`)
VALUES
    (200001, 71,   100, 0, 0, 10, 0),   -- Defensive Stance
    (200001, 355,  100, 0, 0, 10, 71),  -- Taunt (requires Defensive Stance)
    (200001, 7386, 100, 0, 0, 10, 71);  -- Sunder Armor (requires Defensive Stance)

-- Warrior Trainer 2 (Horde)
INSERT INTO `npc_trainer` (`ID`, `SpellID`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqLevel`, `ReqSpell`)
VALUES
    (200002, 71,   100, 0, 0, 10, 0),   -- Defensive Stance
    (200002, 355,  100, 0, 0, 10, 71),  -- Taunt (requires Defensive Stance)
    (200002, 7386, 100, 0, 0, 10, 71);  -- Sunder Armor (requires Defensive Stance)
-- }}}

-- {{{ Paladin (Level 12 Quest: The Tome of Valor)
-- Redemption (resurrection) is learned through quest

-- Paladin Trainer 1
INSERT INTO `npc_trainer` (`ID`, `SpellID`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqLevel`, `ReqSpell`)
VALUES (200003, 7328, 200, 0, 0, 12, 0);  -- Redemption

-- Paladin Trainer 2
INSERT INTO `npc_trainer` (`ID`, `SpellID`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqLevel`, `ReqSpell`)
VALUES (200004, 7328, 200, 0, 0, 12, 0);  -- Redemption

-- Paladin Trainer 3 (Blood Elf trainer)
INSERT INTO `npc_trainer` (`ID`, `SpellID`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqLevel`, `ReqSpell`)
VALUES (200020, 7328, 200, 0, 0, 12, 0);  -- Redemption
-- }}}

-- {{{ Hunter (Level 10 Quest Chain: Taming the Beast)
-- All pet abilities are learned through the taming quest chain
-- These are core hunter identity spells

-- Hunter Trainer 1
INSERT INTO `npc_trainer` (`ID`, `SpellID`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqLevel`, `ReqSpell`)
VALUES
    (200013, 883,  100, 0, 0, 10, 0),     -- Call Pet
    (200013, 982,  100, 0, 0, 10, 883),   -- Revive Pet (requires Call Pet)
    (200013, 1515, 100, 0, 0, 10, 0),     -- Tame Beast
    (200013, 6991, 100, 0, 0, 10, 883),   -- Feed Pet (requires Call Pet)
    (200013, 2641, 100, 0, 0, 10, 883);   -- Dismiss Pet (requires Call Pet)

-- Hunter Trainer 2
INSERT INTO `npc_trainer` (`ID`, `SpellID`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqLevel`, `ReqSpell`)
VALUES
    (200014, 883,  100, 0, 0, 10, 0),     -- Call Pet
    (200014, 982,  100, 0, 0, 10, 883),   -- Revive Pet (requires Call Pet)
    (200014, 1515, 100, 0, 0, 10, 0),     -- Tame Beast
    (200014, 6991, 100, 0, 0, 10, 883),   -- Feed Pet (requires Call Pet)
    (200014, 2641, 100, 0, 0, 10, 883);   -- Dismiss Pet (requires Call Pet)
-- }}}

-- {{{ Rogue (Level 20 Quest: The Touch of Zanzil)
-- Poison abilities are learned through the poison quest

-- Rogue Trainer 1
INSERT INTO `npc_trainer` (`ID`, `SpellID`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqLevel`, `ReqSpell`)
VALUES
    (200015, 2835, 500, 0, 0, 20, 0),   -- Deadly Poison
    (200015, 3420, 500, 0, 0, 20, 0);   -- Crippling Poison

-- Rogue Trainer 2
INSERT INTO `npc_trainer` (`ID`, `SpellID`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqLevel`, `ReqSpell`)
VALUES
    (200016, 2835, 500, 0, 0, 20, 0),   -- Deadly Poison
    (200016, 3420, 500, 0, 0, 20, 0);   -- Crippling Poison
-- }}}

-- {{{ Shaman (Totem Quests)
-- Each totem type requires a quest in vanilla
-- Earth Totem @ 4, Fire Totem @ 10, Water Totem @ 10, Air Totem @ 20

-- Shaman Trainer 1
INSERT INTO `npc_trainer` (`ID`, `SpellID`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqLevel`, `ReqSpell`)
VALUES
    (200017, 8071, 50,  0, 0, 4,  0),   -- Stoneskin Totem (Earth quest reward)
    (200017, 3599, 100, 0, 0, 10, 0),   -- Searing Totem (Fire quest reward)
    (200017, 5394, 100, 0, 0, 10, 0),   -- Healing Stream Totem (Water quest reward)
    (200017, 8184, 500, 0, 0, 20, 0);   -- Fire Resistance Totem (Fire quest chain)

-- Shaman Trainer 2
INSERT INTO `npc_trainer` (`ID`, `SpellID`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqLevel`, `ReqSpell`)
VALUES
    (200018, 8071, 50,  0, 0, 4,  0),   -- Stoneskin Totem (Earth quest reward)
    (200018, 3599, 100, 0, 0, 10, 0),   -- Searing Totem (Fire quest reward)
    (200018, 5394, 100, 0, 0, 10, 0),   -- Healing Stream Totem (Water quest reward)
    (200018, 8184, 500, 0, 0, 20, 0);   -- Fire Resistance Totem (Fire quest chain)
-- }}}

-- {{{ Warlock (Demon Quests)
-- Demon summons require quests in vanilla
-- Imp is free at start, Voidwalker @ 10, Succubus @ 20

-- Warlock Trainer 1
INSERT INTO `npc_trainer` (`ID`, `SpellID`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqLevel`, `ReqSpell`)
VALUES
    (200009, 697, 100, 0, 0, 10, 0),    -- Summon Voidwalker
    (200009, 712, 500, 0, 0, 20, 0);    -- Summon Succubus

-- Warlock Trainer 2
INSERT INTO `npc_trainer` (`ID`, `SpellID`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqLevel`, `ReqSpell`)
VALUES
    (200010, 697, 100, 0, 0, 10, 0),    -- Summon Voidwalker
    (200010, 712, 500, 0, 0, 20, 0);    -- Summon Succubus
-- }}}

-- {{{ Druid (Bear Form Quest @ 10)
-- Bear Form and its abilities are learned through the level 10 quest
-- Note: Other forms (Aquatic, Travel, Cat) are either already at trainers or handled separately

-- Druid Trainer 1
INSERT INTO `npc_trainer` (`ID`, `SpellID`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqLevel`, `ReqSpell`)
VALUES
    (200005, 5487, 100, 0, 0, 10, 0),     -- Bear Form
    (200005, 6795, 100, 0, 0, 10, 5487),  -- Growl (requires Bear Form)
    (200005, 6807, 100, 0, 0, 10, 5487),  -- Maul (requires Bear Form)
    (200005, 8998, 500, 0, 0, 20, 5487);  -- Cower (requires Bear Form)

-- Druid Trainer 2
INSERT INTO `npc_trainer` (`ID`, `SpellID`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqLevel`, `ReqSpell`)
VALUES
    (200006, 5487, 100, 0, 0, 10, 0),     -- Bear Form
    (200006, 6795, 100, 0, 0, 10, 5487),  -- Growl (requires Bear Form)
    (200006, 6807, 100, 0, 0, 10, 5487),  -- Maul (requires Bear Form)
    (200006, 8998, 500, 0, 0, 20, 5487);  -- Cower (requires Bear Form)
-- }}}

-- {{{ Spell ID Quick Reference
-- Warrior:
--   71 = Defensive Stance
--   355 = Taunt
--   7386 = Sunder Armor
--
-- Paladin:
--   7328 = Redemption
--
-- Hunter:
--   883 = Call Pet
--   982 = Revive Pet
--   1515 = Tame Beast
--   6991 = Feed Pet
--   2641 = Dismiss Pet
--
-- Rogue:
--   2835 = Deadly Poison
--   3420 = Crippling Poison
--
-- Shaman:
--   8071 = Stoneskin Totem (NOT 3599, that's Searing Totem)
--   3599 = Searing Totem
--   5394 = Healing Stream Totem
--   8184 = Fire Resistance Totem
--
-- Warlock:
--   697 = Summon Voidwalker
--   712 = Summon Succubus
--
-- Druid:
--   5487 = Bear Form
--   6795 = Growl
--   6807 = Maul
--   8998 = Cower
-- }}}

-- {{{ Spells Already at Trainers (no action needed)
-- These were verified to already exist in the trainer tables:
--
-- Shaman:
--   2645 = Ghost Wolf (level 16)
--
-- Druid:
--   99 = Demoralizing Roar
--   1066 = Aquatic Form
--   783 = Travel Form (level 16, but available at 1 in our mod)
--   768 = Cat Form
--   1082 = Claw
--   1079 = Rip
--   1735 = Prowl
--
-- Paladin:
--   5502 = Sense Undead
--   13820 = Summon Warhorse (level 20)
-- }}}

-- {{{ Verification queries (run manually)
-- SELECT * FROM npc_trainer WHERE ID = 200001;  -- Warrior trainer 1
-- SELECT * FROM npc_trainer WHERE ID = 200005;  -- Druid trainer 1
-- SELECT * FROM npc_trainer WHERE ID = 200013;  -- Hunter trainer 1
-- SELECT * FROM npc_trainer WHERE ID = 200017;  -- Shaman trainer 1
-- }}}
