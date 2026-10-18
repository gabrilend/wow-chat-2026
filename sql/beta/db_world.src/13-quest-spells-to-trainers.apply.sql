-- MARKER_E013_APPLY beta-quest-spells-to-trainers
-- quest-spells-to-trainers.sql
-- Adds quest-learned abilities to class trainers
-- Issue 701: quest-spells-to-trainers (formerly 140)
-- Issue 167: recreate-missing-sql-files
--
-- Many class abilities in vanilla WoW require quest completion.
-- Since our server has no quest NPCs, we add these abilities to trainers instead.
-- Players can train them at the appropriate level without needing quests.
--
-- Rewritten 2026-10-17 onto the current trainer tables. A class trainer's
-- lessons are rows of `trainer_spell` under a list number in `trainer`
-- (kind 0 = class trainer, `Requirement` = the class). Each lesson below is
-- added to every class list of its class, once. Until then this step wrote
-- `npc_trainer` under old reference numbers (200001-200020), a table the
-- server no longer reads, so none of these lessons was offered.
--
-- Lists numbered 1,000,000 and up are this profile's own copies (E014's
-- per-trainer slices, E011's death knight kit) and are left out: E014 copies
-- from the class lists after this step runs, so its copies get these
-- lessons too, cut at each trainer's slice.
--
-- A lesson the game's list already holds is left as the game has it.
-- `wow_chat_e013_added` records which (list, lesson) pairs this step added,
-- so the revert (13-quest-spells-to-trainers.revert.sql) removes exactly
-- those and never one of the game's own.
--
-- Run against acore_world database

-- (The old form's rows in `npc_trainer` are left where they are: the
-- server doesn't read that table, and the game's own reference lists
-- 200001-200020 hold some of the same lessons, which a cleanup would take.)

-- {{{ the lessons: class (1-11), spell, price in copper, level, the spell
-- it needs first (0 = none)
DROP TEMPORARY TABLE IF EXISTS `_e013_lessons`;
CREATE TEMPORARY TABLE `_e013_lessons` (
    `Class` TINYINT UNSIGNED NOT NULL, `SpellId` INT UNSIGNED NOT NULL, `MoneyCost` INT UNSIGNED NOT NULL,
    `ReqLevel` TINYINT UNSIGNED NOT NULL, `ReqAbility1` INT UNSIGNED NOT NULL);
INSERT INTO `_e013_lessons` (`Class`, `SpellId`, `MoneyCost`, `ReqLevel`, `ReqAbility1`) VALUES
    -- Warrior (level 10 quest: The Affray / Brutal Armor)
    (1,   71,  100, 10,    0),  -- Defensive Stance
    (1,  355,  100, 10,   71),  -- Taunt (requires Defensive Stance)
    (1, 7386,  100, 10,   71),  -- Sunder Armor (requires Defensive Stance)
    -- Paladin (level 12 quest: The Tome of Valor)
    (2, 7328,  200, 12,    0),  -- Redemption
    -- Hunter (level 10 quest chain: Taming the Beast)
    (3,  883,  100, 10,    0),  -- Call Pet
    (3,  982,  100, 10,  883),  -- Revive Pet (requires Call Pet)
    (3, 1515,  100, 10,    0),  -- Tame Beast
    (3, 6991,  100, 10,  883),  -- Feed Pet (requires Call Pet)
    (3, 2641,  100, 10,  883),  -- Dismiss Pet (requires Call Pet)
    -- Rogue (level 20 quest: The Touch of Zanzil)
    (4, 2835,  500, 20,    0),  -- Deadly Poison
    (4, 3420,  500, 20,    0),  -- Crippling Poison
    -- Shaman (totem quests: earth at 4, fire and water at 10)
    (7, 8071,   50,  4,    0),  -- Stoneskin Totem (earth quest reward)
    (7, 3599,  100, 10,    0),  -- Searing Totem (fire quest reward)
    (7, 5394,  100, 10,    0),  -- Healing Stream Totem (water quest reward)
    (7, 8184,  500, 20,    0),  -- Fire Resistance Totem (fire quest chain)
    -- Warlock (demon quests: Voidwalker at 10, Succubus at 20)
    (9,  697,  100, 10,    0),  -- Summon Voidwalker
    (9,  712,  500, 20,    0),  -- Summon Succubus
    -- Druid (bear form quest at 10)
    (11, 5487, 100, 10,    0),  -- Bear Form
    (11, 6795, 100, 10, 5487),  -- Growl (requires Bear Form)
    (11, 6807, 100, 10, 5487),  -- Maul (requires Bear Form)
    (11, 8998, 500, 20, 5487);  -- Cower (requires Bear Form)
-- }}}

-- {{{ add each lesson to every class list of its class, noting which are new
CREATE TABLE IF NOT EXISTS `wow_chat_e013_added` (
    `TrainerId` INT UNSIGNED NOT NULL, `SpellId` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`TrainerId`, `SpellId`));
INSERT IGNORE INTO `wow_chat_e013_added` (`TrainerId`, `SpellId`)
    SELECT t.`Id`, l.`SpellId`
    FROM `_e013_lessons` l
    JOIN `trainer` t ON t.`Type` = 0 AND t.`Requirement` = l.`Class` AND t.`Id` < 1000000
    LEFT JOIN `trainer_spell` ts ON ts.`TrainerId` = t.`Id` AND ts.`SpellId` = l.`SpellId`
    WHERE ts.`SpellId` IS NULL;
INSERT IGNORE INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`)
    SELECT t.`Id`, l.`SpellId`, l.`MoneyCost`, 0, 0, l.`ReqAbility1`, 0, 0, l.`ReqLevel`, 0
    FROM `_e013_lessons` l
    JOIN `trainer` t ON t.`Type` = 0 AND t.`Requirement` = l.`Class` AND t.`Id` < 1000000;
DROP TEMPORARY TABLE `_e013_lessons`;
-- }}}

-- {{{ Spells already at trainers (no action needed; noted in the old form)
-- Shaman: 2645 Ghost Wolf (16). Druid: 99 Demoralizing Roar, 1066 Aquatic
-- Form, 783 Travel Form, 768 Cat Form, 1082 Claw, 1079 Rip, 1735 Prowl.
-- Paladin: 5502 Sense Undead, 13820 Summon Warhorse (20).
-- }}}
