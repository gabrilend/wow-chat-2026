-- MARKER_E020_REVERT vanilla-mount-level-requirements

UPDATE `trainer_spell` SET `ReqLevel` = 20 WHERE `SpellId` = 33388;
UPDATE `trainer_spell` SET `ReqLevel` = 40 WHERE `SpellId` = 33391;

