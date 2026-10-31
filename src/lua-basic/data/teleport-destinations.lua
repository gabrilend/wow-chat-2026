-- teleport-destinations.lua - made by scripts/generate-teleport-destinations
-- from data-files/dbc/{Spell,AreaTable}.dbc, so the way-back rule (issue 723,
-- buddy-hearth.lua) knows where each mage teleport lands. Do not edit: run
-- the generator again.
--   spell -> { area = the AreaTable id, map, zone = true when the area is a
--              whole zone (a city: matched by the caster's zone), false when
--              it is a town inside a zone (matched by area and nearness) }
return {
    [ 3561] = { area = 1519, map =   0, zone = true  },   -- Teleport: Stormwind
    [ 3562] = { area = 1537, map =   0, zone = true  },   -- Teleport: Ironforge
    [ 3563] = { area = 1497, map =   0, zone = true  },   -- Teleport: Undercity
    [ 3565] = { area = 1657, map =   1, zone = true  },   -- Teleport: Darnassus
    [ 3566] = { area = 1638, map =   1, zone = true  },   -- Teleport: Thunder Bluff
    [ 3567] = { area = 1637, map =   1, zone = true  },   -- Teleport: Orgrimmar
    [32271] = { area = 3557, map = 530, zone = true  },   -- Teleport: Exodar
    [32272] = { area = 3487, map = 530, zone = true  },   -- Teleport: Silvermoon
    [33690] = { area = 3703, map = 530, zone = true  },   -- Teleport: Shattrath
    [35715] = { area = 3703, map = 530, zone = true  },   -- Teleport: Shattrath
    [49358] = { area =   75, map =   0, zone = false },   -- Teleport: Stonard
    [49359] = { area =  513, map =   1, zone = false },   -- Teleport: Theramore
    [53140] = { area = 4395, map = 571, zone = true  },   -- Teleport: Dalaran
}
