-- MARKER_E029_APPLY basic-inscription-without-glyphs

DROP TABLE IF EXISTS `tmp_155o_glyph_spells`;
CREATE TABLE `tmp_155o_glyph_spells` (`spell_id` int unsigned NOT NULL, PRIMARY KEY (`spell_id`));
DROP TABLE IF EXISTS `tmp_155o_scroll_spells`;
CREATE TABLE `tmp_155o_scroll_spells` (`spell_id` int unsigned NOT NULL, `item_id` int unsigned NOT NULL, PRIMARY KEY (`spell_id`));
INSERT INTO `tmp_155o_glyph_spells` (`spell_id`) VALUES (48121),(56943),(56944),(56945),(56946),(56947),(56948),(56949),(56950),(56951),(56952),(56953),(56954),(56955),(56956),(56957),(56958),(56959),(56960),(56961),(56963),(56965),(56968),(56971),(56972),(56973),(56974),(56975),(56976),(56977),(56978),(56979),(56980),(56981),(56982),(56983),(56984),(56985),(56986),(56987),(56988),(56989),(56990),(56991),(56994),(56995),(56996),(56997),(56998),(56999),(57000),(57001),(57002),(57003),(57004),(57005),(57006),(57007),(57008),(57009),(57010),(57011),(57012),(57013),(57014),(57019),(57020),(57021),(57022),(57023),(57024),(57025),(57026),(57027),(57028),(57029),(57030),(57031),(57032),(57033),(57034),(57035),(57036),(57112),(57113),(57114),(57115),(57116),(57117),(57119),(57120),(57121),(57122),(57123),(57124),(57125),(57126),(57127),(57128),(57129),(57130),(57131),(57132),(57133),(57151),(57152),(57153),(57154),(57155),(57156),(57157),(57158),(57159),(57160),(57161),(57162),(57163),(57164),(57165),(57166),(57167),(57168),(57169),(57170),(57172),(57181),(57183),(57184),(57185),(57186),(57187),(57188),(57189),(57190),(57191),(57192),(57193),(57194),(57195),(57196),(57197),(57198),(57199),(57200),(57201),(57202),(57207),(57208),(57209),(57210),(57211),(57212),(57213),(57214),(57215),(57216),(57217),(57218),(57219),(57220),(57221),(57222),(57223),(57224),(57225),(57226),(57227),(57228),(57229),(57230),(57232),(57233),(57234),(57235),(57236),(57237),(57238),(57239),(57240),(57241),(57242),(57243),(57244),(57245),(57246),(57247),(57248),(57249),(57250),(57251),(57252),(57253),(57257),(57258),(57259),(57260),(57261),(57262),(57263),(57264),(57265),(57266),(57267),(57268),(57269),(57270),(57271),(57272),(57273),(57274),(57275),(57276),(57277),(57719),(58286),(58287),(58288),(58289),(58296),(58297),(58298),(58299),(58300),(58301),(58302),(58303),(58305),(58306),(58307),(58308),(58310),(58311),(58312),(58313),(58314),(58315),(58316),(58317),(58318),(58319),(58320),(58321),(58322),(58323),(58324),(58325),(58326),(58327),(58328),(58329),(58330),(58331),(58332),(58333),(58336),(58337),(58338),(58339),(58340),(58341),(58342),(58343),(58344),(58345),(58346),(58347),(59315),(59326),(59338),(59339),(59340),(59559),(59560),(59561),(61177),(61288),(61677),(62162),(64246),(64247),(64248),(64249),(64250),(64251),(64252),(64253),(64254),(64255),(64256),(64257),(64258),(64259),(64260),(64261),(64262),(64266),(64267),(64268),(64270),(64271),(64273),(64274),(64275),(64276),(64277),(64278),(64279),(64280),(64281),(64282),(64283),(64284),(64285),(64286),(64287),(64288),(64289),(64291),(64294),(64295),(64296),(64297),(64298),(64299),(64300),(64302),(64303),(64304),(64305),(64307),(64308),(64309),(64310),(64311),(64312),(64313),(64314),(64315),(64316),(64317),(64318),(65245),(67600),(68166),(71015),(71101),(71102);
INSERT INTO `tmp_155o_scroll_spells` (`spell_id`, `item_id`) VALUES (45382,1180),(48114,955),(48116,1181),(50598,2290),(50599,4419),(50600,10308),(50601,27499),(50602,33458),(50603,37091),(50604,37092),(50605,1712),(50606,4424),(50607,10306),(50608,27501),(50609,33460),(50610,37097),(50611,37098),(50612,1711),(50614,4422),(50616,10307),(50617,27502),(50618,33461),(50619,37093),(50620,37094),(58472,3012),(58473,1477),(58476,4425),(58478,10309),(58480,27498),(58481,33457),(58482,43463),(58483,43464),(58484,954),(58485,2289),(58486,4426),(58487,10310),(58488,27503),(58489,33462),(58490,43465),(58491,43466),(59500,43145),(59501,43146);

CREATE TABLE IF NOT EXISTS `basic_155o_glyph_trainer_spell` LIKE `trainer_spell`;
INSERT IGNORE INTO `basic_155o_glyph_trainer_spell`
SELECT ts.* FROM `trainer_spell` ts JOIN `tmp_155o_glyph_spells` g ON g.`spell_id` = ts.`SpellId`;
DELETE ts FROM `trainer_spell` ts JOIN `tmp_155o_glyph_spells` g ON g.`spell_id` = ts.`SpellId`;

CREATE TABLE IF NOT EXISTS `basic_155o_scroll_added` (
  `TrainerId` int unsigned NOT NULL,
  `SpellId`   int unsigned NOT NULL,
  PRIMARY KEY (`TrainerId`, `SpellId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155o: scroll and vellum recipe rows this file put back at a trainer, for the revert';

CREATE TABLE IF NOT EXISTS `basic_155o_scroll_rank` (
  `TrainerId`    int unsigned NOT NULL,
  `SpellId`      int unsigned NOT NULL,
  `ReqSkillRank` int unsigned NOT NULL,
  PRIMARY KEY (`TrainerId`, `SpellId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155o: stock skill rank of scroll and vellum recipes still at a trainer, for the revert';
INSERT IGNORE INTO `basic_155o_scroll_rank` (`TrainerId`, `SpellId`, `ReqSkillRank`)
SELECT ts.`TrainerId`, ts.`SpellId`, ts.`ReqSkillRank` FROM `trainer_spell` ts
JOIN `tmp_155o_scroll_spells` s ON s.`spell_id` = ts.`SpellId`
WHERE NOT EXISTS (SELECT 1 FROM `basic_155o_scroll_added` a WHERE a.`TrainerId` = ts.`TrainerId` AND a.`SpellId` = ts.`SpellId`);
CREATE TABLE IF NOT EXISTS `basic_155n_trainer_spell` LIKE `trainer_spell`;   -- exists when E027 ran first
INSERT IGNORE INTO `basic_155o_scroll_added` (`TrainerId`, `SpellId`)
SELECT b.`TrainerId`, b.`SpellId` FROM `basic_155n_trainer_spell` b
JOIN `tmp_155o_scroll_spells` s ON s.`spell_id` = b.`SpellId`
WHERE NOT EXISTS (SELECT 1 FROM `trainer_spell` ts WHERE ts.`TrainerId` = b.`TrainerId` AND ts.`SpellId` = b.`SpellId`);
INSERT IGNORE INTO `trainer_spell`
SELECT b.* FROM `basic_155n_trainer_spell` b
JOIN `basic_155o_scroll_added` a ON a.`TrainerId` = b.`TrainerId` AND a.`SpellId` = b.`SpellId`;
UPDATE `trainer_spell` ts JOIN `basic_155o_scroll_rank` r ON r.`TrainerId` = ts.`TrainerId` AND r.`SpellId` = ts.`SpellId`
SET ts.`ReqSkillRank` = ROUND(r.`ReqSkillRank` * 300 / 425);
UPDATE `trainer_spell` ts
JOIN `basic_155o_scroll_added` a ON a.`TrainerId` = ts.`TrainerId` AND a.`SpellId` = ts.`SpellId`
JOIN `basic_155n_trainer_spell` b ON b.`TrainerId` = ts.`TrainerId` AND b.`SpellId` = ts.`SpellId`
SET ts.`ReqSkillRank` = ROUND(b.`ReqSkillRank` * 300 / 425);

CREATE TABLE IF NOT EXISTS `basic_155o_scroll_items` (
  `entry`         int unsigned     NOT NULL,
  `RequiredLevel` tinyint unsigned NOT NULL,
  PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='issue 155o: stock required level of crafted scrolls and vellums, for the revert';
INSERT IGNORE INTO `basic_155o_scroll_items` (`entry`, `RequiredLevel`)
SELECT i.`entry`, i.`RequiredLevel` FROM `item_template` i JOIN `tmp_155o_scroll_spells` s ON s.`item_id` = i.`entry`;
UPDATE `item_template` i JOIN `basic_155o_scroll_items` b ON b.`entry` = i.`entry`
SET i.`RequiredLevel` = ROUND(b.`RequiredLevel` * 0.75);

CREATE TABLE IF NOT EXISTS `basic_155o_spell_group` LIKE `spell_group`;
INSERT IGNORE INTO `basic_155o_spell_group`
SELECT * FROM `spell_group` WHERE `id` IN (1083, 1084, 1085, 1086, 1088) AND `spell_id` IN (-1066, -1067, -1068, -1069, -1070, -1071);
DELETE FROM `spell_group` WHERE `id` IN (1083, 1084, 1085, 1086, 1088) AND `spell_id` IN (-1066, -1067, -1068, -1069, -1070, -1071);

DROP TABLE `tmp_155o_scroll_spells`;
DROP TABLE `tmp_155o_glyph_spells`;

