-- MARKER_E021_APPLY vanilla-starting-professions
-- ===========================================================================
-- 07-starting-professions.sql (148q) — APPLY SOURCE
-- ===========================================================================
-- Grants every level-20 vanilla character exactly TWO professions at
-- Journeyman (skill cap 150), knowing every trainer recipe usable at skill
-- <= 125 and carrying each profession's tool — so professions are playable on
-- first login without a trainer trip. Slot 1 is a race gathering; slot 2 is a
-- class production — UNLESS the class is a faction-diversity override, in which
-- case slot 2 holds a second gathering instead (so each faction still covers
-- all seven gatherings). Overrides: Alliance Rogue->Skinning, Warlock->
-- Tailoring, Mage->Enchanting; Horde Warrior->Mining, Shaman->Fishing,
-- Priest->First Aid. Never three professions.
--
-- SKILL VALUE (125) is set by the first-login ALE hook via SetSkill: the
-- playercreateinfo path can only grant the TIER (rank = a step index, whose
-- SkillTier value is the cap — NOT a skill value), so the rows below establish
-- "known at Journeyman, cap 150" and the hook bumps the value to 125. This is
-- the rank-is-a-tier-step lesson 148h learned (rank=100 was rejected there).
--
-- Keying: playercreateinfo_skills / playercreateinfo_spell_custom take
-- BITMASKS (raceMask/classMask, 0 = all; mask = OR of 1<<(id-1)). But
-- playercreateinfo_item takes SPECIFIC race+class ids (PK is race+class+itemid,
-- no wildcard), so tools are inserted via SELECT over playercreateinfo with a
-- membership predicate instead of a mask.
--   Race bits: Human 1, Orc 2, Dwarf 4, NightElf 8, Undead 16, Tauren 32,
--     Gnome 64, Troll 128, BloodElf 512, Draenei 1024.
--     Alliance mask = 1101, Horde mask = 690.
--   Class bits: War 1, Pal 2, Hun 4, Rog 8, Pri 16, Sha 64, Mag 128,
--     Wlk 256, Dru 1024.
--
-- Database: acore_world_vanilla. Applied by the E021 patch via UpdateFetcher.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1. Idempotence: clear any prior 148q rows (tagged on comment / Note).
-- ---------------------------------------------------------------------------
DELETE FROM playercreateinfo_skills       WHERE comment LIKE 'vanilla-148q-%';
DELETE FROM playercreateinfo_spell_custom WHERE Note    LIKE 'vanilla-148q-%';
DELETE FROM playercreateinfo_item         WHERE Note    LIKE 'vanilla-148q-%';

-- ---------------------------------------------------------------------------
-- 2. Profession skill lines at Journeyman (rank/step 2 -> cap 150).
--    Gathering: race defaults + faction-scoped class overrides (additive).
--    Production: one row per class.
-- ---------------------------------------------------------------------------
INSERT INTO playercreateinfo_skills (raceMask, classMask, skill, `rank`, comment) VALUES
-- Mining (186): Dwarf+Gnome default; Horde Warrior override
(  68,    0, 186, 2, 'vanilla-148q-g-mining'),
( 690,    1, 186, 2, 'vanilla-148q-g-mining-hwar'),
-- Herbalism (182): NightElf+Tauren default
(  40,    0, 182, 2, 'vanilla-148q-g-herbalism'),
-- Skinning (393): Orc+Troll default; Alliance Rogue override
( 130,    0, 393, 2, 'vanilla-148q-g-skinning'),
(1101,    8, 393, 2, 'vanilla-148q-g-skinning-arog'),
-- Fishing (356): Draenei default; Horde Shaman override
(1024,    0, 356, 2, 'vanilla-148q-g-fishing'),
( 690,   64, 356, 2, 'vanilla-148q-g-fishing-hsha'),
-- First Aid (129): Human default; Horde Priest override
(   1,    0, 129, 2, 'vanilla-148q-g-firstaid'),
( 690,   16, 129, 2, 'vanilla-148q-g-firstaid-hpri'),
-- Tailoring (197): Undead default; Alliance Warlock override
(  16,    0, 197, 2, 'vanilla-148q-g-tailoring'),
(1101,  256, 197, 2, 'vanilla-148q-g-tailoring-awlk'),
-- Enchanting (333): BloodElf default; Alliance Mage override
( 512,    0, 333, 2, 'vanilla-148q-g-enchanting'),
(1101,  128, 333, 2, 'vanilla-148q-g-enchanting-amag'),
-- Production (the CLASS slot) — granted only where the class is NOT a
-- faction-override on that faction. The six override (faction,class) pairs get
-- the override GATHERING above in this slot instead, so every character lands
-- exactly TWO professions total (a race gathering + one class slot). The
-- overrides: Alliance Rogue/Warlock/Mage, Horde Warrior/Shaman/Priest.
(1101,    1, 164, 2, 'vanilla-148q-p-blacksmithing'),      -- Warrior — Alliance only (Horde Warriors mine)
(   0,    2, 755, 2, 'vanilla-148q-p-jewelcrafting'),      -- Paladin — all
(   0,    4, 165, 2, 'vanilla-148q-p-leatherworking'),     -- Hunter  — all
( 690,    8, 202, 2, 'vanilla-148q-p-engineering'),        -- Rogue   — Horde only (Alliance Rogues skin)
(1101,   16, 773, 2, 'vanilla-148q-p-inscription-apri'),   -- Priest  — Alliance only (Horde Priests do First Aid)
( 690,  128, 773, 2, 'vanilla-148q-p-inscription-hmag'),   -- Mage    — Horde only (Alliance Mages enchant)
(1101,   64, 171, 2, 'vanilla-148q-p-alchemy-asha'),       -- Shaman  — Alliance only (Horde Shamans fish)
( 690,  256, 171, 2, 'vanilla-148q-p-alchemy-hwlk'),       -- Warlock — Horde only (Alliance Warlocks tailor)
(   0, 1024, 185, 2, 'vanilla-148q-p-cooking');            -- Druid   — all

-- ---------------------------------------------------------------------------
-- 3. Recipes: every trainer-taught spell for the profession usable at
--    skill <= 125, keyed the same way as the skill grant. Computed live from
--    trainer_spell so the set tracks the data. INSERT IGNORE guards the rare
--    case where a spell is shared with another migration's rows under the same
--    (racemask, classmask) PK — the tag-scoped DELETE above only clears our
--    own rows. (A few rank-up spells may ride along; harmless.)
-- ---------------------------------------------------------------------------
-- Mining (186)
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT   68,   0, SpellId, 'vanilla-148q-r-mining' FROM trainer_spell WHERE ReqSkillLine=186 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT  690,   1, SpellId, 'vanilla-148q-r-mining' FROM trainer_spell WHERE ReqSkillLine=186 AND ReqSkillRank<=125 GROUP BY SpellId;
-- Herbalism (182)
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT   40,   0, SpellId, 'vanilla-148q-r-herbalism' FROM trainer_spell WHERE ReqSkillLine=182 AND ReqSkillRank<=125 GROUP BY SpellId;
-- Skinning (393)
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT  130,   0, SpellId, 'vanilla-148q-r-skinning' FROM trainer_spell WHERE ReqSkillLine=393 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT 1101,   8, SpellId, 'vanilla-148q-r-skinning' FROM trainer_spell WHERE ReqSkillLine=393 AND ReqSkillRank<=125 GROUP BY SpellId;
-- Fishing (356)
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT 1024,   0, SpellId, 'vanilla-148q-r-fishing' FROM trainer_spell WHERE ReqSkillLine=356 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT  690,  64, SpellId, 'vanilla-148q-r-fishing' FROM trainer_spell WHERE ReqSkillLine=356 AND ReqSkillRank<=125 GROUP BY SpellId;
-- First Aid (129)
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT    1,   0, SpellId, 'vanilla-148q-r-firstaid' FROM trainer_spell WHERE ReqSkillLine=129 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT  690,  16, SpellId, 'vanilla-148q-r-firstaid' FROM trainer_spell WHERE ReqSkillLine=129 AND ReqSkillRank<=125 GROUP BY SpellId;
-- Tailoring (197)
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT   16,   0, SpellId, 'vanilla-148q-r-tailoring' FROM trainer_spell WHERE ReqSkillLine=197 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT 1101, 256, SpellId, 'vanilla-148q-r-tailoring' FROM trainer_spell WHERE ReqSkillLine=197 AND ReqSkillRank<=125 GROUP BY SpellId;
-- Enchanting (333)
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT  512,   0, SpellId, 'vanilla-148q-r-enchanting' FROM trainer_spell WHERE ReqSkillLine=333 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT 1101, 128, SpellId, 'vanilla-148q-r-enchanting' FROM trainer_spell WHERE ReqSkillLine=333 AND ReqSkillRank<=125 GROUP BY SpellId;
-- Blacksmithing (164) — Alliance Warrior
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT 1101,   1, SpellId, 'vanilla-148q-r-blacksmithing' FROM trainer_spell WHERE ReqSkillLine=164 AND ReqSkillRank<=125 GROUP BY SpellId;
-- Jewelcrafting (755) — Paladin (all)
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT    0,   2, SpellId, 'vanilla-148q-r-jewelcrafting' FROM trainer_spell WHERE ReqSkillLine=755 AND ReqSkillRank<=125 GROUP BY SpellId;
-- Leatherworking (165) — Hunter (all)
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT    0,   4, SpellId, 'vanilla-148q-r-leatherworking' FROM trainer_spell WHERE ReqSkillLine=165 AND ReqSkillRank<=125 GROUP BY SpellId;
-- Engineering (202) — Horde Rogue
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT  690,   8, SpellId, 'vanilla-148q-r-engineering' FROM trainer_spell WHERE ReqSkillLine=202 AND ReqSkillRank<=125 GROUP BY SpellId;
-- Inscription (773) — Alliance Priest + Horde Mage
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT 1101,  16, SpellId, 'vanilla-148q-r-inscription' FROM trainer_spell WHERE ReqSkillLine=773 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT  690, 128, SpellId, 'vanilla-148q-r-inscription' FROM trainer_spell WHERE ReqSkillLine=773 AND ReqSkillRank<=125 GROUP BY SpellId;
-- Alchemy (171) — Alliance Shaman + Horde Warlock
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT 1101,  64, SpellId, 'vanilla-148q-r-alchemy' FROM trainer_spell WHERE ReqSkillLine=171 AND ReqSkillRank<=125 GROUP BY SpellId;
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT  690, 256, SpellId, 'vanilla-148q-r-alchemy' FROM trainer_spell WHERE ReqSkillLine=171 AND ReqSkillRank<=125 GROUP BY SpellId;
-- Cooking (185) — Druid (all)
INSERT IGNORE INTO playercreateinfo_spell_custom (racemask, classmask, Spell, Note)
  SELECT    0, 1024, SpellId, 'vanilla-148q-r-cooking' FROM trainer_spell WHERE ReqSkillLine=185 AND ReqSkillRank<=125 GROUP BY SpellId;

-- ---------------------------------------------------------------------------
-- 4. Tools: the one item each tooled profession needs, keyed per (race,class)
--    via SELECT over playercreateinfo (the table takes specific ids, not
--    masks). The membership predicate mirrors each profession's skill keying.
--    Mining -> Mining Pick (2901), Skinning -> Skinning Knife (7005),
--    Fishing -> Fishing Pole (6256), Blacksmithing/Engineering -> Blacksmith
--    Hammer (5956), Enchanting -> Runed Copper Rod (6218), Alchemy -> a stack
--    of Empty Vials (3371 x5). Herbalism/Tailoring/Jewelcrafting/Inscription/
--    Cooking/First Aid/Leatherworking need no tool.
-- ---------------------------------------------------------------------------
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

-- ===========================================================================
-- End of 07-starting-professions.sql (apply)
-- ===========================================================================
