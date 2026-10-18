-- MARKER_E013_REVERT beta-quest-spells-to-trainers
-- Undo of 13-quest-spells-to-trainers.apply.sql: removes exactly the
-- (list, lesson) pairs the apply added, as recorded in
-- `wow_chat_e013_added`, so none of the game's own lessons goes. Safe when
-- the apply never ran (the CREATE makes an empty record).
CREATE TABLE IF NOT EXISTS `wow_chat_e013_added` (
    `TrainerId` INT UNSIGNED NOT NULL, `SpellId` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`TrainerId`, `SpellId`));
DELETE ts FROM `trainer_spell` ts
    JOIN `wow_chat_e013_added` a ON a.`TrainerId` = ts.`TrainerId` AND a.`SpellId` = ts.`SpellId`;
DROP TABLE `wow_chat_e013_added`;
