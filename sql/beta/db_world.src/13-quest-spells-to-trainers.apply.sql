-- MARKER_E013_APPLY beta-quest-spells-to-trainers


DROP TEMPORARY TABLE IF EXISTS `_e013_lessons`;
CREATE TEMPORARY TABLE `_e013_lessons` (
    `Class` TINYINT UNSIGNED NOT NULL, `SpellId` INT UNSIGNED NOT NULL, `MoneyCost` INT UNSIGNED NOT NULL,
    `ReqLevel` TINYINT UNSIGNED NOT NULL, `ReqAbility1` INT UNSIGNED NOT NULL);
INSERT INTO `_e013_lessons` (`Class`, `SpellId`, `MoneyCost`, `ReqLevel`, `ReqAbility1`) VALUES
    (1,   71,  100, 10,    0),  -- Defensive Stance
    (1,  355,  100, 10,   71),  -- Taunt (requires Defensive Stance)
    (1, 7386,  100, 10,   71),  -- Sunder Armor (requires Defensive Stance)
    (2, 7328,  200, 12,    0),  -- Redemption
    (3,  883,  100, 10,    0),  -- Call Pet
    (3,  982,  100, 10,  883),  -- Revive Pet (requires Call Pet)
    (3, 1515,  100, 10,    0),  -- Tame Beast
    (3, 6991,  100, 10,  883),  -- Feed Pet (requires Call Pet)
    (3, 2641,  100, 10,  883),  -- Dismiss Pet (requires Call Pet)
    (4, 2835,  500, 20,    0),  -- Deadly Poison
    (4, 3420,  500, 20,    0),  -- Crippling Poison
    (7, 8071,   50,  4,    0),  -- Stoneskin Totem (earth quest reward)
    (7, 3599,  100, 10,    0),  -- Searing Totem (fire quest reward)
    (7, 5394,  100, 10,    0),  -- Healing Stream Totem (water quest reward)
    (7, 8184,  500, 20,    0),  -- Fire Resistance Totem (fire quest chain)
    (9,  697,  100, 10,    0),  -- Summon Voidwalker
    (9,  712,  500, 20,    0),  -- Summon Succubus
    (11, 5487, 100, 10,    0),  -- Bear Form
    (11, 6795, 100, 10, 5487),  -- Growl (requires Bear Form)
    (11, 6807, 100, 10, 5487),  -- Maul (requires Bear Form)
    (11, 8998, 500, 20, 5487);  -- Cower (requires Bear Form)

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

