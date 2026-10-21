--------------------------------------------------------------------------------
-- data/starting-valleys.lua (issues 155d, 155d1) -- GENERATED, do not edit.
--
-- Written by scripts/generate-starting-valleys-lua from the VALLEYS table in
-- patches/B028-basic-starting-valley-rotation.sh, the one list of the
-- starting valleys. Edit B028, then re-run the generator.
--
-- Shape: [team][index], team 0 Alliance and 1 Horde (the core's TeamId),
-- index 0-3 as the rotation table's current_valley holds it. Each valley:
--   name  text     the valley's name
--   map   integer  map id
--   zone  integer  area id, as the hearthstone binding stores it
--   x y z number   the stock arrival position
--   o     number   facing, radians
--------------------------------------------------------------------------------

return {
    [0] = {
        [0] = { name = "Northshire Valley", map =   0, zone =   12, x =   -8949.95, y =   -132.493, z =  83.5312, o =     0.0 },
        [1] = { name = "Coldridge Valley",  map =   0, zone =    1, x =   -6240.32, y =    331.033, z =  382.758, o = 6.17716 },
        [2] = { name = "Shadowglen",        map =   1, zone =  141, x =    10311.3, y =    832.463, z =  1326.41, o = 5.69632 },
        [3] = { name = "Ammen Vale",        map = 530, zone = 3526, x =   -3961.64, y =   -13931.2, z =  100.615, o = 2.08364 },
    },
    [1] = {
        [0] = { name = "Valley of Trials",  map =   1, zone =   14, x =   -618.518, y =   -4251.67, z =   38.718, o =     0.0 },
        [1] = { name = "Deathknell",        map =   0, zone =   85, x =    1676.71, y =    1678.31, z =   121.67, o = 2.70526 },
        [2] = { name = "Camp Narache",      map =   1, zone =  215, x =   -2917.58, y =    -257.98, z =  52.9968, o =     0.0 },
        [3] = { name = "Sunstrider Isle",   map = 530, zone = 3431, x =    10349.6, y =   -6357.29, z =  33.4026, o = 5.31605 },
    },
}
