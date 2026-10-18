--------------------------------------------------------------------------------
-- data/travel-trainers.lua - which class trainers may wander by as
-- travellers, and for which levels each one teaches.
--
-- For a general audience: on beta the world is empty, so class trainers
-- come to the player as travellers. Each class has several trainers, each
-- covering a slice of levels 1-20, so a level-7 warrior meets a different
-- trainer than a level-15 one. Two readers share this one list:
--   - travel.lua picks a trainer of the player's class whose slice holds
--     the player's level;
--   - scripts/generate-beta-trainer-tiers-sql writes install step E014's
--     SQL, giving each of these trainers its own copy of its class's
--     lessons, cut off at its slice's top level.
-- Moved here from travel.lua on 2026-10-17 so the two can't disagree.
--
-- Fields of each row (all numbers):
--   trainerID  the trainer's creature entry (creature_template.entry)
--   minLevel,  the player levels this trainer is chosen for; maxLevel is
--   maxLevel   also the highest lesson level it teaches (E014)
--   rel        1 = horde, 2 = alliance (travel.lua's faction code)
--   id         the class, negated (the game's class number, 1-11, with a
--              minus sign so travel.lua can tell trainers from other
--              travellers): -1 warrior, -2 paladin, -3 hunter, -4 rogue,
--              -5 priest, -6 death knight, -7 shaman, -8 mage, -9 warlock,
--              -11 druid (the game has no class 10)
--
-- Corrected 2026-10-17, checked against the world database: the last
-- horde priest read 4906 (no such creature; 4606 is Aelthalyste, an
-- Undercity priest trainer no other row used), and the first horde druid
-- read 3043, which is Ker Ragetotem, a warrior trainer already in the
-- warrior rows (3034 is Sheal Runetotem, a Thunder Bluff druid trainer no
-- other row used). Both look like slips of two digits. And the druid rows
-- read -10, but the game numbers druids 11 (10 is unused), so travel.lua's
-- "is this the player's class" never matched a druid: no druid ever met a
-- trainer. They read -11 now.
-- scripts/generate-beta-trainer-tiers-sql checks the class of every row.
--------------------------------------------------------------------------------

-- Normalized to level 1-20 cap using ALL available trainers per class/faction
-- Level ranges distributed evenly: 20 levels / N trainers per class
-- More trainers = finer level granularity, more NPC variety
return {   -- horde warrior (9 trainers)
                      { trainerID =  3354, minLevel =  1, maxLevel =  2, rel = 1, id =  -1 },
                      { trainerID =  3353, minLevel =  3, maxLevel =  4, rel = 1, id =  -1 },
                      { trainerID =  3041, minLevel =  5, maxLevel =  6, rel = 1, id =  -1 },
                      { trainerID =  3043, minLevel =  7, maxLevel =  8, rel = 1, id =  -1 },
                      { trainerID =  3042, minLevel =  9, maxLevel = 11, rel = 1, id =  -1 },
                      { trainerID =  4594, minLevel = 12, maxLevel = 13, rel = 1, id =  -1 },
                      { trainerID =  3408, minLevel = 14, maxLevel = 15, rel = 1, id =  -1 },
                      { trainerID =  4595, minLevel = 16, maxLevel = 17, rel = 1, id =  -1 },
                      { trainerID =  4593, minLevel = 18, maxLevel = 20, rel = 1, id =  -1 },
                        -- alliance warrior (11 trainers)
                      { trainerID =  5113, minLevel =  1, maxLevel =  1, rel = 2, id =  -1 },
                      { trainerID =  5480, minLevel =  2, maxLevel =  3, rel = 2, id =  -1 },
                      { trainerID =  1901, minLevel =  4, maxLevel =  5, rel = 2, id =  -1 },
                      { trainerID =   914, minLevel =  6, maxLevel =  7, rel = 2, id =  -1 },
                      { trainerID =  5114, minLevel =  8, maxLevel =  9, rel = 2, id =  -1 },
                      { trainerID = 17120, minLevel = 10, maxLevel = 10, rel = 2, id =  -1 },
                      { trainerID =  5479, minLevel = 11, maxLevel = 12, rel = 2, id =  -1 },
                      { trainerID =  4087, minLevel = 13, maxLevel = 14, rel = 2, id =  -1 },
                      { trainerID =  4089, minLevel = 15, maxLevel = 16, rel = 2, id =  -1 },
                      { trainerID = 16771, minLevel = 17, maxLevel = 18, rel = 2, id =  -1 },
                      { trainerID =  7315, minLevel = 19, maxLevel = 20, rel = 2, id =  -1 },
                        -- horde paladin (5 trainers)
                      { trainerID = 16679, minLevel =  1, maxLevel =  4, rel = 1, id =  -2 },
                      { trainerID = 16680, minLevel =  5, maxLevel =  8, rel = 1, id =  -2 },
                      { trainerID = 16681, minLevel =  9, maxLevel = 12, rel = 1, id =  -2 },
                      { trainerID = 20406, minLevel = 13, maxLevel = 16, rel = 1, id =  -2 },
                      { trainerID = 23128, minLevel = 17, maxLevel = 20, rel = 1, id =  -2 },
                        -- alliance paladin (7 trainers)
                      { trainerID =  5149, minLevel =  1, maxLevel =  2, rel = 2, id =  -2 },
                      { trainerID =  5148, minLevel =  3, maxLevel =  5, rel = 2, id =  -2 },
                      { trainerID =  5147, minLevel =  6, maxLevel =  8, rel = 2, id =  -2 },
                      { trainerID = 17509, minLevel =  9, maxLevel = 11, rel = 2, id =  -2 },
                      { trainerID =   928, minLevel = 12, maxLevel = 14, rel = 2, id =  -2 },
                      { trainerID =  5492, minLevel = 15, maxLevel = 17, rel = 2, id =  -2 },
                      { trainerID =  5491, minLevel = 18, maxLevel = 20, rel = 2, id =  -2 },
                        -- horde hunter (7 trainers)
                      { trainerID =  3406, minLevel =  1, maxLevel =  2, rel = 1, id =  -3 },
                      { trainerID =  3040, minLevel =  3, maxLevel =  5, rel = 1, id =  -3 },
                      { trainerID =  3352, minLevel =  6, maxLevel =  8, rel = 1, id =  -3 },
                      { trainerID =  3039, minLevel =  9, maxLevel = 11, rel = 1, id =  -3 },
                      { trainerID =  3038, minLevel = 12, maxLevel = 14, rel = 1, id =  -3 },
                      { trainerID = 16673, minLevel = 15, maxLevel = 17, rel = 1, id =  -3 },
                      { trainerID =  3407, minLevel = 18, maxLevel = 20, rel = 1, id =  -3 },
                        -- alliance hunter (8 trainers)
                      { trainerID =  5117, minLevel =  1, maxLevel =  2, rel = 2, id =  -3 },
                      { trainerID =  4146, minLevel =  3, maxLevel =  5, rel = 2, id =  -3 },
                      { trainerID =  5515, minLevel =  6, maxLevel =  7, rel = 2, id =  -3 },
                      { trainerID = 17505, minLevel =  8, maxLevel = 10, rel = 2, id =  -3 },
                      { trainerID =  5116, minLevel = 11, maxLevel = 12, rel = 2, id =  -3 },
                      { trainerID =  5115, minLevel = 13, maxLevel = 15, rel = 2, id =  -3 },
                      { trainerID =  4205, minLevel = 16, maxLevel = 17, rel = 2, id =  -3 },
                      { trainerID =  5516, minLevel = 18, maxLevel = 20, rel = 2, id =  -3 },
                        -- horde rogue (6 trainers)
                      { trainerID =  3327, minLevel =  1, maxLevel =  3, rel = 1, id =  -4 },
                      { trainerID =  3401, minLevel =  4, maxLevel =  6, rel = 1, id =  -4 },
                      { trainerID =  4582, minLevel =  7, maxLevel = 10, rel = 1, id =  -4 },
                      { trainerID =  4583, minLevel = 11, maxLevel = 13, rel = 1, id =  -4 },
                      { trainerID =  3328, minLevel = 14, maxLevel = 16, rel = 1, id =  -4 },
                      { trainerID =  4584, minLevel = 17, maxLevel = 20, rel = 1, id =  -4 },
                        -- alliance rogue (6 trainers)
                      { trainerID =  5167, minLevel =  1, maxLevel =  3, rel = 2, id =  -4 },
                      { trainerID =  4163, minLevel =  4, maxLevel =  6, rel = 2, id =  -4 },
                      { trainerID =  5166, minLevel =  7, maxLevel = 10, rel = 2, id =  -4 },
                      { trainerID =   918, minLevel = 11, maxLevel = 13, rel = 2, id =  -4 },
                      { trainerID =  5165, minLevel = 14, maxLevel = 16, rel = 2, id =  -4 },
                      { trainerID = 13283, minLevel = 17, maxLevel = 20, rel = 2, id =  -4 },
                        -- horde priest (9 trainers)
                      { trainerID =  4607, minLevel =  1, maxLevel =  2, rel = 1, id =  -5 },
                      { trainerID = 16659, minLevel =  3, maxLevel =  4, rel = 1, id =  -5 },
                      { trainerID =  3044, minLevel =  5, maxLevel =  6, rel = 1, id =  -5 },
                      { trainerID =  6018, minLevel =  7, maxLevel =  8, rel = 1, id =  -5 },
                      { trainerID =  4608, minLevel =  9, maxLevel = 11, rel = 1, id =  -5 },
                      { trainerID =  6014, minLevel = 12, maxLevel = 13, rel = 1, id =  -5 },
                      { trainerID =  3045, minLevel = 14, maxLevel = 15, rel = 1, id =  -5 },
                      { trainerID =  5994, minLevel = 16, maxLevel = 17, rel = 1, id =  -5 },
                      { trainerID =  4606, minLevel = 18, maxLevel = 20, rel = 1, id =  -5 },
                        -- alliance priest (9 trainers)
                      { trainerID =  5143, minLevel =  1, maxLevel =  2, rel = 2, id =  -5 },
                      { trainerID =  5142, minLevel =  3, maxLevel =  4, rel = 2, id =  -5 },
                      { trainerID = 11406, minLevel =  5, maxLevel =  6, rel = 2, id =  -5 },
                      { trainerID =  5489, minLevel =  7, maxLevel =  8, rel = 2, id =  -5 },
                      { trainerID =  5484, minLevel =  9, maxLevel = 11, rel = 2, id =  -5 },
                      { trainerID =   376, minLevel = 12, maxLevel = 13, rel = 2, id =  -5 },
                      { trainerID =  4092, minLevel = 14, maxLevel = 15, rel = 2, id =  -5 },
                      { trainerID =  4091, minLevel = 16, maxLevel = 17, rel = 2, id =  -5 },
                      { trainerID = 11401, minLevel = 18, maxLevel = 20, rel = 2, id =  -5 },
                        -- neutral death knight (3 trainers)
                      { trainerID = 29194, minLevel =  1, maxLevel =  6, rel = 3, id =  -6 },
                      { trainerID = 29195, minLevel =  7, maxLevel = 13, rel = 3, id =  -6 },
                      { trainerID = 29196, minLevel = 14, maxLevel = 20, rel = 3, id =  -6 },
                        -- horde shaman (6 trainers)
                      { trainerID =  3032, minLevel =  1, maxLevel =  3, rel = 1, id =  -7 },
                      { trainerID =  3030, minLevel =  4, maxLevel =  6, rel = 1, id =  -7 },
                      { trainerID = 13417, minLevel =  7, maxLevel = 10, rel = 1, id =  -7 },
                      { trainerID =  3403, minLevel = 11, maxLevel = 13, rel = 1, id =  -7 },
                      { trainerID =  3031, minLevel = 14, maxLevel = 16, rel = 1, id =  -7 },
                      { trainerID =  3344, minLevel = 17, maxLevel = 20, rel = 1, id =  -7 },
                        -- alliance shaman (5 trainers)
                      { trainerID = 17520, minLevel =  1, maxLevel =  4, rel = 2, id =  -7 },
                      { trainerID = 17204, minLevel =  5, maxLevel =  8, rel = 2, id =  -7 },
                      { trainerID = 17219, minLevel =  9, maxLevel = 12, rel = 2, id =  -7 },
                      { trainerID = 23127, minLevel = 13, maxLevel = 16, rel = 2, id =  -7 },
                      { trainerID = 20407, minLevel = 17, maxLevel = 20, rel = 2, id =  -7 },
                        -- horde mage (11 trainers)
                      { trainerID = 16651, minLevel =  1, maxLevel =  1, rel = 1, id =  -8 },
                      { trainerID =  4568, minLevel =  2, maxLevel =  3, rel = 1, id =  -8 },
                      { trainerID =  5885, minLevel =  4, maxLevel =  5, rel = 1, id =  -8 },
                      { trainerID =  7311, minLevel =  6, maxLevel =  7, rel = 1, id =  -8 },
                      { trainerID =  3047, minLevel =  8, maxLevel =  9, rel = 1, id =  -8 },
                      { trainerID =  5883, minLevel = 10, maxLevel = 10, rel = 1, id =  -8 },
                      { trainerID =  4567, minLevel = 11, maxLevel = 12, rel = 1, id =  -8 },
                      { trainerID =  4566, minLevel = 13, maxLevel = 14, rel = 1, id =  -8 },
                      { trainerID =  5882, minLevel = 15, maxLevel = 16, rel = 1, id =  -8 },
                      { trainerID =  3048, minLevel = 17, maxLevel = 18, rel = 1, id =  -8 },
                      { trainerID =  3049, minLevel = 19, maxLevel = 20, rel = 1, id =  -8 },
                        -- alliance mage (7 trainers)
                      { trainerID =  5144, minLevel =  1, maxLevel =  2, rel = 2, id =  -8 },
                      { trainerID =  5497, minLevel =  3, maxLevel =  5, rel = 2, id =  -8 },
                      { trainerID =   331, minLevel =  6, maxLevel =  8, rel = 2, id =  -8 },
                      { trainerID =  7312, minLevel =  9, maxLevel = 11, rel = 2, id =  -8 },
                      { trainerID =  5498, minLevel = 12, maxLevel = 14, rel = 2, id =  -8 },
                      { trainerID = 16749, minLevel = 15, maxLevel = 17, rel = 2, id =  -8 },
                      { trainerID =  5145, minLevel = 18, maxLevel = 20, rel = 2, id =  -8 },
                        -- horde warlock (6 trainers)
                      { trainerID =  3324, minLevel =  1, maxLevel =  3, rel = 1, id =  -9 },
                      { trainerID =  3325, minLevel =  4, maxLevel =  6, rel = 1, id =  -9 },
                      { trainerID =  3326, minLevel =  7, maxLevel = 10, rel = 1, id =  -9 },
                      { trainerID =  4564, minLevel = 11, maxLevel = 13, rel = 1, id =  -9 },
                      { trainerID =  4563, minLevel = 14, maxLevel = 16, rel = 1, id =  -9 },
                      { trainerID =  4565, minLevel = 17, maxLevel = 20, rel = 1, id =  -9 },
                        -- alliance warlock (6 trainers)
                      { trainerID =  5495, minLevel =  1, maxLevel =  3, rel = 2, id =  -9 },
                      { trainerID =  5172, minLevel =  4, maxLevel =  6, rel = 2, id =  -9 },
                      { trainerID =  5496, minLevel =  7, maxLevel = 10, rel = 2, id =  -9 },
                      { trainerID =   461, minLevel = 11, maxLevel = 13, rel = 2, id =  -9 },
                      { trainerID =  5171, minLevel = 14, maxLevel = 16, rel = 2, id =  -9 },
                      { trainerID =  5173, minLevel = 17, maxLevel = 20, rel = 2, id =  -9 },
                        -- horde druid (3 trainers)
                      { trainerID =  3034, minLevel =  1, maxLevel =  6, rel = 1, id = -11 },
                      { trainerID =  3033, minLevel =  7, maxLevel = 13, rel = 1, id = -11 },
                      { trainerID =  3036, minLevel = 14, maxLevel = 20, rel = 1, id = -11 },
                        -- alliance druid (5 trainers)
                      { trainerID =  4218, minLevel =  1, maxLevel =  4, rel = 2, id = -11 },
                      { trainerID =  4219, minLevel =  5, maxLevel =  8, rel = 2, id = -11 },
                      { trainerID =  5505, minLevel =  9, maxLevel = 12, rel = 2, id = -11 },
                      { trainerID =  4217, minLevel = 13, maxLevel = 16, rel = 2, id = -11 },
                      { trainerID =  5504, minLevel = 17, maxLevel = 20, rel = 2, id = -11 },
}
