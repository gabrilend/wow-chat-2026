-- MARKER_E021_APPLY vanilla-starting-professions

DELETE FROM playercreateinfo_skills       WHERE comment LIKE 'vanilla-148q-%';
DELETE FROM playercreateinfo_spell_custom WHERE Note    LIKE 'vanilla-148q-%';
DELETE FROM playercreateinfo_item         WHERE Note    LIKE 'vanilla-148q-%';

INSERT INTO playercreateinfo_skills (raceMask, classMask, skill, `rank`, comment) VALUES
(  68,    0, 186, 2, 'vanilla-148q-g-mining'),
( 690,    1, 186, 2, 'vanilla-148q-g-mining-hwar'),
(  40,    0, 182, 2, 'vanilla-148q-g-herbalism'),
( 130,    0, 393, 2, 'vanilla-148q-g-skinning'),
(1101,    8, 393, 2, 'vanilla-148q-g-skinning-arog'),
(1024,    0, 356, 2, 'vanilla-148q-g-fishing'),
( 690,   64, 356, 2, 'vanilla-148q-g-fishing-hsha'),
(   1,    0, 129, 2, 'vanilla-148q-g-firstaid'),
( 690,   16, 129, 2, 'vanilla-148q-g-firstaid-hpri'),
(  16,    0, 197, 2, 'vanilla-148q-g-tailoring'),
(1101,  256, 197, 2, 'vanilla-148q-g-tailoring-awlk'),
( 512,    0, 333, 2, 'vanilla-148q-g-enchanting'),
(1101,  128, 333, 2, 'vanilla-148q-g-enchanting-amag'),
(1101,    1, 164, 2, 'vanilla-148q-p-blacksmithing'),      -- Warrior — Alliance only (Horde Warriors mine)
(   0,    2, 755, 2, 'vanilla-148q-p-jewelcrafting'),      -- Paladin — all
(   0,    4, 165, 2, 'vanilla-148q-p-leatherworking'),     -- Hunter  — all
( 690,    8, 202, 2, 'vanilla-148q-p-engineering'),        -- Rogue   — Horde only (Alliance Rogues skin)
(1101,   16, 773, 2, 'vanilla-148q-p-inscription-apri'),   -- Priest  — Alliance only (Horde Priests do First Aid)
( 690,  128, 773, 2, 'vanilla-148q-p-inscription-hmag'),   -- Mage    — Horde only (Alliance Mages enchant)
(1101,   64, 171, 2, 'vanilla-148q-p-alchemy-asha'),       -- Shaman  — Alliance only (Horde Shamans fish)
( 690,  256, 171, 2, 'vanilla-148q-p-alchemy-hwlk'),       -- Warlock — Horde only (Alliance Warlocks tailor)
(   0, 1024, 185, 2, 'vanilla-148q-p-cooking');            -- Druid   — all

INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT   68,   0, SpellId, 'vanilla-148q-r-mining' FROM trainer_spell WHERE ReqSkillLine=186 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT  690,   1, SpellId, 'vanilla-148q-r-mining' FROM trainer_spell WHERE ReqSkillLine=186 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT   40,   0, SpellId, 'vanilla-148q-r-herbalism' FROM trainer_spell WHERE ReqSkillLine=182 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT  130,   0, SpellId, 'vanilla-148q-r-skinning' FROM trainer_spell WHERE ReqSkillLine=393 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT 1101,   8, SpellId, 'vanilla-148q-r-skinning' FROM trainer_spell WHERE ReqSkillLine=393 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT 1024,   0, SpellId, 'vanilla-148q-r-fishing' FROM trainer_spell WHERE ReqSkillLine=356 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT  690,  64, SpellId, 'vanilla-148q-r-fishing' FROM trainer_spell WHERE ReqSkillLine=356 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT    1,   0, SpellId, 'vanilla-148q-r-firstaid' FROM trainer_spell WHERE ReqSkillLine=129 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT  690,  16, SpellId, 'vanilla-148q-r-firstaid' FROM trainer_spell WHERE ReqSkillLine=129 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT   16,   0, SpellId, 'vanilla-148q-r-tailoring' FROM trainer_spell WHERE ReqSkillLine=197 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT 1101, 256, SpellId, 'vanilla-148q-r-tailoring' FROM trainer_spell WHERE ReqSkillLine=197 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT  512,   0, SpellId, 'vanilla-148q-r-enchanting' FROM trainer_spell WHERE ReqSkillLine=333 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT 1101, 128, SpellId, 'vanilla-148q-r-enchanting' FROM trainer_spell WHERE ReqSkillLine=333 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT 1101,   1, SpellId, 'vanilla-148q-r-blacksmithing' FROM trainer_spell WHERE ReqSkillLine=164 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT    0,   2, SpellId, 'vanilla-148q-r-jewelcrafting' FROM trainer_spell WHERE ReqSkillLine=755 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT    0,   4, SpellId, 'vanilla-148q-r-leatherworking' FROM trainer_spell WHERE ReqSkillLine=165 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT  690,   8, SpellId, 'vanilla-148q-r-engineering' FROM trainer_spell WHERE ReqSkillLine=202 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT 1101,  16, SpellId, 'vanilla-148q-r-inscription' FROM trainer_spell WHERE ReqSkillLine=773 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT  690, 128, SpellId, 'vanilla-148q-r-inscription' FROM trainer_spell WHERE ReqSkillLine=773 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT 1101,  64, SpellId, 'vanilla-148q-r-alchemy' FROM trainer_spell WHERE ReqSkillLine=171 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT  690, 256, SpellId, 'vanilla-148q-r-alchemy' FROM trainer_spell WHERE ReqSkillLine=171 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT    0, 1024, SpellId, 'vanilla-148q-r-cooking' FROM trainer_spell WHERE ReqSkillLine=185 AND ReqSkillRank<=125 GROUP BY SpellId;

INSERT INTO playercreateinfo_item (race, class, itemid, amount, Note)
  SELECT race, class, 2901, 1, 'vanilla-148q-tool-mining' FROM playercreateinfo
  WHERE class<>6 AND race<>9 AND ((race IN (3,7)) OR (race IN (2,5,6,8,10) AND class=1));
INSERT INTO playercreateinfo_item (race, class, itemid, amount, Note)
  SELECT race, class, 7005, 1, 'vanilla-148q-tool-skinning' FROM playercreateinfo
  WHERE class<>6 AND race<>9 AND ((race IN (2,8)) OR (race IN (1,3,4,7,11) AND class=4));
INSERT INTO playercreateinfo_item (race, class, itemid, amount, Note)
  SELECT race, class, 6256, 1, 'vanilla-148q-tool-fishing' FROM playercreateinfo
  WHERE class<>6 AND race<>9 AND ((race=11) OR (race IN (2,5,6,8,10) AND class=7));
INSERT INTO playercreateinfo_item (race, class, itemid, amount, Note)
  SELECT race, class, 6218, 1, 'vanilla-148q-tool-enchanting' FROM playercreateinfo
  WHERE class<>6 AND race<>9 AND ((race=10) OR (race IN (1,3,4,7,11) AND class=8));
INSERT INTO playercreateinfo_item (race, class, itemid, amount, Note)
  SELECT race, class, 5956, 1, 'vanilla-148q-tool-blacksmithing' FROM playercreateinfo
  WHERE class<>6 AND race<>9 AND class=1 AND race IN (1,3,4,7,11);       -- Alliance Warriors
INSERT INTO playercreateinfo_item (race, class, itemid, amount, Note)
  SELECT race, class, 5956, 1, 'vanilla-148q-tool-engineering' FROM playercreateinfo
  WHERE class<>6 AND race<>9 AND class=4 AND race IN (2,5,6,8,10);       -- Horde Rogues
INSERT INTO playercreateinfo_item (race, class, itemid, amount, Note)
  SELECT race, class, 3371, 5, 'vanilla-148q-tool-alchemy' FROM playercreateinfo
  WHERE class<>6 AND race<>9 AND ((class=7 AND race IN (1,3,4,7,11))     -- Alliance Shamans
                               OR (class=9 AND race IN (2,5,6,8,10)));   -- Horde Warlocks

