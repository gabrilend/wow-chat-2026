-- trainer-spell-level-cap.sql
-- Caps trainer spell lists to their assigned level range
-- Issue 157: dynamic-trainer-spawning
-- Issue 167: recreate-missing-sql-files
--
-- Each trainer is assigned a maxLevel from travel.lua.
-- This script removes all spells requiring level > maxLevel from each trainer.
-- This creates a tiered trainer system where different trainers teach different level ranges.
--
-- 20 levels distributed evenly among N trainers per class:
-- - More trainers = finer level granularity
-- - Fewer trainers = coarser granularity
--
-- Run against acore_world database AFTER fresh import

-- {{{ Horde Warrior (9 trainers, ~2 levels each)
DELETE FROM npc_trainer WHERE ID = 3354 AND ReqLevel > 2;   -- level 1-2
DELETE FROM npc_trainer WHERE ID = 3353 AND ReqLevel > 4;   -- level 3-4
DELETE FROM npc_trainer WHERE ID = 3041 AND ReqLevel > 6;   -- level 5-6
DELETE FROM npc_trainer WHERE ID = 3043 AND ReqLevel > 8;   -- level 7-8 (also horde druid!)
DELETE FROM npc_trainer WHERE ID = 3042 AND ReqLevel > 11;  -- level 9-11
DELETE FROM npc_trainer WHERE ID = 4594 AND ReqLevel > 13;  -- level 12-13
DELETE FROM npc_trainer WHERE ID = 3408 AND ReqLevel > 15;  -- level 14-15
DELETE FROM npc_trainer WHERE ID = 4595 AND ReqLevel > 17;  -- level 16-17
DELETE FROM npc_trainer WHERE ID = 4593 AND ReqLevel > 20;  -- level 18-20
-- }}}

-- {{{ Alliance Warrior (11 trainers, ~2 levels each)
DELETE FROM npc_trainer WHERE ID = 5113 AND ReqLevel > 1;   -- level 1
DELETE FROM npc_trainer WHERE ID = 5480 AND ReqLevel > 3;   -- level 2-3
DELETE FROM npc_trainer WHERE ID = 1901 AND ReqLevel > 5;   -- level 4-5
DELETE FROM npc_trainer WHERE ID = 914  AND ReqLevel > 7;   -- level 6-7
DELETE FROM npc_trainer WHERE ID = 5114 AND ReqLevel > 9;   -- level 8-9
DELETE FROM npc_trainer WHERE ID = 17120 AND ReqLevel > 10; -- level 10
DELETE FROM npc_trainer WHERE ID = 5479 AND ReqLevel > 12;  -- level 11-12
DELETE FROM npc_trainer WHERE ID = 4087 AND ReqLevel > 14;  -- level 13-14
DELETE FROM npc_trainer WHERE ID = 4089 AND ReqLevel > 16;  -- level 15-16
DELETE FROM npc_trainer WHERE ID = 16771 AND ReqLevel > 18; -- level 17-18
DELETE FROM npc_trainer WHERE ID = 7315 AND ReqLevel > 20;  -- level 19-20
-- }}}

-- {{{ Horde Paladin (5 trainers, ~4 levels each)
DELETE FROM npc_trainer WHERE ID = 16679 AND ReqLevel > 4;  -- level 1-4
DELETE FROM npc_trainer WHERE ID = 16680 AND ReqLevel > 8;  -- level 5-8
DELETE FROM npc_trainer WHERE ID = 16681 AND ReqLevel > 12; -- level 9-12
DELETE FROM npc_trainer WHERE ID = 20406 AND ReqLevel > 16; -- level 13-16
DELETE FROM npc_trainer WHERE ID = 23128 AND ReqLevel > 20; -- level 17-20
-- }}}

-- {{{ Alliance Paladin (7 trainers, ~3 levels each)
DELETE FROM npc_trainer WHERE ID = 5149 AND ReqLevel > 2;   -- level 1-2
DELETE FROM npc_trainer WHERE ID = 5148 AND ReqLevel > 5;   -- level 3-5
DELETE FROM npc_trainer WHERE ID = 5147 AND ReqLevel > 8;   -- level 6-8
DELETE FROM npc_trainer WHERE ID = 17509 AND ReqLevel > 11; -- level 9-11
DELETE FROM npc_trainer WHERE ID = 928  AND ReqLevel > 14;  -- level 12-14
DELETE FROM npc_trainer WHERE ID = 5492 AND ReqLevel > 17;  -- level 15-17
DELETE FROM npc_trainer WHERE ID = 5491 AND ReqLevel > 20;  -- level 18-20
-- }}}

-- {{{ Horde Hunter (7 trainers, ~3 levels each)
DELETE FROM npc_trainer WHERE ID = 3406 AND ReqLevel > 2;   -- level 1-2
DELETE FROM npc_trainer WHERE ID = 3040 AND ReqLevel > 5;   -- level 3-5
DELETE FROM npc_trainer WHERE ID = 3352 AND ReqLevel > 8;   -- level 6-8
DELETE FROM npc_trainer WHERE ID = 3039 AND ReqLevel > 11;  -- level 9-11
DELETE FROM npc_trainer WHERE ID = 3038 AND ReqLevel > 14;  -- level 12-14
DELETE FROM npc_trainer WHERE ID = 16673 AND ReqLevel > 17; -- level 15-17
DELETE FROM npc_trainer WHERE ID = 3407 AND ReqLevel > 20;  -- level 18-20
-- }}}

-- {{{ Alliance Hunter (8 trainers, ~2-3 levels each)
DELETE FROM npc_trainer WHERE ID = 5117 AND ReqLevel > 2;   -- level 1-2
DELETE FROM npc_trainer WHERE ID = 4146 AND ReqLevel > 5;   -- level 3-5
DELETE FROM npc_trainer WHERE ID = 5515 AND ReqLevel > 7;   -- level 6-7
DELETE FROM npc_trainer WHERE ID = 17505 AND ReqLevel > 10; -- level 8-10
DELETE FROM npc_trainer WHERE ID = 5116 AND ReqLevel > 12;  -- level 11-12
DELETE FROM npc_trainer WHERE ID = 5115 AND ReqLevel > 15;  -- level 13-15
DELETE FROM npc_trainer WHERE ID = 4205 AND ReqLevel > 17;  -- level 16-17
DELETE FROM npc_trainer WHERE ID = 5516 AND ReqLevel > 20;  -- level 18-20
-- }}}

-- {{{ Horde Rogue (6 trainers, ~3-4 levels each)
DELETE FROM npc_trainer WHERE ID = 3327 AND ReqLevel > 3;   -- level 1-3
DELETE FROM npc_trainer WHERE ID = 3401 AND ReqLevel > 6;   -- level 4-6
DELETE FROM npc_trainer WHERE ID = 4582 AND ReqLevel > 10;  -- level 7-10
DELETE FROM npc_trainer WHERE ID = 4583 AND ReqLevel > 13;  -- level 11-13
DELETE FROM npc_trainer WHERE ID = 3328 AND ReqLevel > 16;  -- level 14-16
DELETE FROM npc_trainer WHERE ID = 4584 AND ReqLevel > 20;  -- level 17-20
-- }}}

-- {{{ Alliance Rogue (6 trainers, ~3-4 levels each)
DELETE FROM npc_trainer WHERE ID = 5167 AND ReqLevel > 3;   -- level 1-3
DELETE FROM npc_trainer WHERE ID = 4163 AND ReqLevel > 6;   -- level 4-6
DELETE FROM npc_trainer WHERE ID = 5166 AND ReqLevel > 10;  -- level 7-10
DELETE FROM npc_trainer WHERE ID = 918  AND ReqLevel > 13;  -- level 11-13
DELETE FROM npc_trainer WHERE ID = 5165 AND ReqLevel > 16;  -- level 14-16
DELETE FROM npc_trainer WHERE ID = 13283 AND ReqLevel > 20; -- level 17-20
-- }}}

-- {{{ Horde Priest (9 trainers, ~2 levels each)
DELETE FROM npc_trainer WHERE ID = 4607 AND ReqLevel > 2;   -- level 1-2
DELETE FROM npc_trainer WHERE ID = 16659 AND ReqLevel > 4;  -- level 3-4
DELETE FROM npc_trainer WHERE ID = 3044 AND ReqLevel > 6;   -- level 5-6
DELETE FROM npc_trainer WHERE ID = 6018 AND ReqLevel > 8;   -- level 7-8
DELETE FROM npc_trainer WHERE ID = 4608 AND ReqLevel > 11;  -- level 9-11
DELETE FROM npc_trainer WHERE ID = 6014 AND ReqLevel > 13;  -- level 12-13
DELETE FROM npc_trainer WHERE ID = 3045 AND ReqLevel > 15;  -- level 14-15
DELETE FROM npc_trainer WHERE ID = 5994 AND ReqLevel > 17;  -- level 16-17
DELETE FROM npc_trainer WHERE ID = 4906 AND ReqLevel > 20;  -- level 18-20
-- }}}

-- {{{ Alliance Priest (9 trainers, ~2 levels each)
DELETE FROM npc_trainer WHERE ID = 5143 AND ReqLevel > 2;   -- level 1-2
DELETE FROM npc_trainer WHERE ID = 5142 AND ReqLevel > 4;   -- level 3-4
DELETE FROM npc_trainer WHERE ID = 11406 AND ReqLevel > 6;  -- level 5-6
DELETE FROM npc_trainer WHERE ID = 5489 AND ReqLevel > 8;   -- level 7-8
DELETE FROM npc_trainer WHERE ID = 5484 AND ReqLevel > 11;  -- level 9-11
DELETE FROM npc_trainer WHERE ID = 376  AND ReqLevel > 13;  -- level 12-13
DELETE FROM npc_trainer WHERE ID = 4092 AND ReqLevel > 15;  -- level 14-15
DELETE FROM npc_trainer WHERE ID = 4091 AND ReqLevel > 17;  -- level 16-17
DELETE FROM npc_trainer WHERE ID = 11401 AND ReqLevel > 20; -- level 18-20
-- }}}

-- {{{ Neutral Death Knight (3 trainers, ~7 levels each)
-- Note: DK trainer abilities are ADDED by death-knights.sql, not capped here
-- These trainers already have custom level ranges in death-knights.sql
-- DELETE FROM npc_trainer WHERE ID = 29194 AND ReqLevel > 6;  -- level 1-6
-- DELETE FROM npc_trainer WHERE ID = 29195 AND ReqLevel > 13; -- level 7-13
-- DELETE FROM npc_trainer WHERE ID = 29196 AND ReqLevel > 20; -- level 14-20
-- }}}

-- {{{ Horde Shaman (6 trainers, ~3-4 levels each)
DELETE FROM npc_trainer WHERE ID = 3032 AND ReqLevel > 3;   -- level 1-3
DELETE FROM npc_trainer WHERE ID = 3030 AND ReqLevel > 6;   -- level 4-6
DELETE FROM npc_trainer WHERE ID = 13417 AND ReqLevel > 10; -- level 7-10
DELETE FROM npc_trainer WHERE ID = 3403 AND ReqLevel > 13;  -- level 11-13
DELETE FROM npc_trainer WHERE ID = 3031 AND ReqLevel > 16;  -- level 14-16
DELETE FROM npc_trainer WHERE ID = 3344 AND ReqLevel > 20;  -- level 17-20
-- }}}

-- {{{ Alliance Shaman (5 trainers, ~4 levels each)
DELETE FROM npc_trainer WHERE ID = 17520 AND ReqLevel > 4;  -- level 1-4
DELETE FROM npc_trainer WHERE ID = 17204 AND ReqLevel > 8;  -- level 5-8
DELETE FROM npc_trainer WHERE ID = 17219 AND ReqLevel > 12; -- level 9-12
DELETE FROM npc_trainer WHERE ID = 23127 AND ReqLevel > 16; -- level 13-16
DELETE FROM npc_trainer WHERE ID = 20407 AND ReqLevel > 20; -- level 17-20
-- }}}

-- {{{ Horde Mage (11 trainers, ~2 levels each)
DELETE FROM npc_trainer WHERE ID = 16651 AND ReqLevel > 1;  -- level 1
DELETE FROM npc_trainer WHERE ID = 4568 AND ReqLevel > 3;   -- level 2-3
DELETE FROM npc_trainer WHERE ID = 5885 AND ReqLevel > 5;   -- level 4-5
DELETE FROM npc_trainer WHERE ID = 7311 AND ReqLevel > 7;   -- level 6-7
DELETE FROM npc_trainer WHERE ID = 3047 AND ReqLevel > 9;   -- level 8-9
DELETE FROM npc_trainer WHERE ID = 5883 AND ReqLevel > 10;  -- level 10
DELETE FROM npc_trainer WHERE ID = 4567 AND ReqLevel > 12;  -- level 11-12
DELETE FROM npc_trainer WHERE ID = 4566 AND ReqLevel > 14;  -- level 13-14
DELETE FROM npc_trainer WHERE ID = 5882 AND ReqLevel > 16;  -- level 15-16
DELETE FROM npc_trainer WHERE ID = 3048 AND ReqLevel > 18;  -- level 17-18
DELETE FROM npc_trainer WHERE ID = 3049 AND ReqLevel > 20;  -- level 19-20
-- }}}

-- {{{ Alliance Mage (7 trainers, ~3 levels each)
DELETE FROM npc_trainer WHERE ID = 5144 AND ReqLevel > 2;   -- level 1-2
DELETE FROM npc_trainer WHERE ID = 5497 AND ReqLevel > 5;   -- level 3-5
DELETE FROM npc_trainer WHERE ID = 331  AND ReqLevel > 8;   -- level 6-8
DELETE FROM npc_trainer WHERE ID = 7312 AND ReqLevel > 11;  -- level 9-11
DELETE FROM npc_trainer WHERE ID = 5498 AND ReqLevel > 14;  -- level 12-14
DELETE FROM npc_trainer WHERE ID = 16749 AND ReqLevel > 17; -- level 15-17
DELETE FROM npc_trainer WHERE ID = 5145 AND ReqLevel > 20;  -- level 18-20
-- }}}

-- {{{ Horde Warlock (6 trainers, ~3-4 levels each)
DELETE FROM npc_trainer WHERE ID = 3324 AND ReqLevel > 3;   -- level 1-3
DELETE FROM npc_trainer WHERE ID = 3325 AND ReqLevel > 6;   -- level 4-6
DELETE FROM npc_trainer WHERE ID = 3326 AND ReqLevel > 10;  -- level 7-10
DELETE FROM npc_trainer WHERE ID = 4564 AND ReqLevel > 13;  -- level 11-13
DELETE FROM npc_trainer WHERE ID = 4563 AND ReqLevel > 16;  -- level 14-16
DELETE FROM npc_trainer WHERE ID = 4565 AND ReqLevel > 20;  -- level 17-20
-- }}}

-- {{{ Alliance Warlock (6 trainers, ~3-4 levels each)
DELETE FROM npc_trainer WHERE ID = 5495 AND ReqLevel > 3;   -- level 1-3
DELETE FROM npc_trainer WHERE ID = 5172 AND ReqLevel > 6;   -- level 4-6
DELETE FROM npc_trainer WHERE ID = 5496 AND ReqLevel > 10;  -- level 7-10
DELETE FROM npc_trainer WHERE ID = 461  AND ReqLevel > 13;  -- level 11-13
DELETE FROM npc_trainer WHERE ID = 5171 AND ReqLevel > 16;  -- level 14-16
DELETE FROM npc_trainer WHERE ID = 5173 AND ReqLevel > 20;  -- level 17-20
-- }}}

-- {{{ Horde Druid (3 trainers, ~7 levels each)
-- Note: 3043 is shared with Horde Warrior! Already deleted above with maxLevel 8.
-- This means horde druid trainer at 3043 will have spells capped at 6, not 8.
-- We need to be careful about this collision. For now, use the druid's maxLevel (6).
-- DELETE FROM npc_trainer WHERE ID = 3043 AND ReqLevel > 6;  -- level 1-6 (collision)
DELETE FROM npc_trainer WHERE ID = 3033 AND ReqLevel > 13;  -- level 7-13
DELETE FROM npc_trainer WHERE ID = 3036 AND ReqLevel > 20;  -- level 14-20
-- }}}

-- {{{ Alliance Druid (5 trainers, ~4 levels each)
DELETE FROM npc_trainer WHERE ID = 4218 AND ReqLevel > 4;   -- level 1-4
DELETE FROM npc_trainer WHERE ID = 4219 AND ReqLevel > 8;   -- level 5-8
DELETE FROM npc_trainer WHERE ID = 5505 AND ReqLevel > 12;  -- level 9-12
DELETE FROM npc_trainer WHERE ID = 4217 AND ReqLevel > 16;  -- level 13-16
DELETE FROM npc_trainer WHERE ID = 5504 AND ReqLevel > 20;  -- level 17-20
-- }}}

-- {{{ Trainer Count Reference
-- | Class     | Horde | Alliance |
-- |-----------|-------|----------|
-- | Warrior   | 9     | 11       |
-- | Paladin   | 5     | 7        |
-- | Hunter    | 7     | 8        |
-- | Rogue     | 6     | 6        |
-- | Priest    | 9     | 9        |
-- | DK        | 3     | (neutral)|
-- | Shaman    | 6     | 5        |
-- | Mage      | 11    | 7        |
-- | Warlock   | 6     | 6        |
-- | Druid     | 3     | 5        |
-- }}}

-- {{{ Verification queries (run manually)
-- Check remaining spells for a specific trainer:
-- SELECT * FROM npc_trainer WHERE ID = 5113 ORDER BY ReqLevel;
--
-- Count spells per trainer:
-- SELECT ID, COUNT(*) as spell_count, MAX(ReqLevel) as max_req_level
-- FROM npc_trainer
-- WHERE ID IN (5113, 5480, 1901, 914, 5114, 17120, 5479, 4087, 4089, 16771, 7315)
-- GROUP BY ID;
-- }}}
