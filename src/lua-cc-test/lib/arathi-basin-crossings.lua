--------------------------------------------------------------------------------
-- arathi-basin-crossings.lua (issue 176a2c) - the owner's map of Arathi
-- Basin's crossings, in two readings
--
-- For a general audience: the owner drew the roads as each base having two
-- exits, each exit reaching a fork with its own choices (2026-10-08):
--
--   Stables     left: Gold Mine, Farm (along the cliff), Blacksmith
--               right: the Blacksmith-Farm crossing, Lumber Mill
--   Farm        left: Lumber Mill, Stables, Blacksmith
--               right: Gold Mine, the Blacksmith-Farm crossing
--   Gold Mine   left: Farm                right: Blacksmith, Stables
--   Lumber Mill left: Stables             right: Blacksmith, Farm
--   Blacksmith  one way: Gold Mine, Stables
--               the other: Lumber Mill, Farm
--
-- Four things in it are open (176a2c questions 6a-6d): where the "cliff"
-- road runs, whether the Farm's exits reach the same crossing, whether
-- forks that offer the same places are one crossing, and which roads the
-- homes have. Rather than guess, this holds two whole readings, each a
-- complete map the route rule (arathi-basin-routes.lua) can walk:
--
--   "shared"  forks naming the same places are one crossing: the
--             Blacksmith's "one way" fork is the Gold Mine's right fork
--             (crossing D: Blacksmith, Gold Mine, Stables); its "other
--             way" fork is the Lumber Mill's right fork and the
--             Blacksmith-Farm crossing (crossing C: Blacksmith, Lumber
--             Mill, Farm). The Farm's left exit reaches C; the Stables'
--             left exit reaches D, whose "cliff road" runs on to the
--             Farm's right fork. Each home has one road, to its own near
--             base (north-west to the Stables, south-east to the Farm).
--   "literal" every exit's fork is its own crossing, exactly as the table
--             reads, except that "the Blacksmith-Farm crossing" is the
--             Blacksmith's "other way" fork (it is the only fork between
--             those two). Each home keeps the bot module's three roads:
--             its near base, the Gold Mine and the Lumber Mill.
--
-- A map is { name, about, roads = { { from, to } } }: names of places and
-- crossings, no positions yet. The roads between crossings are to be
-- walked and recorded in game (176a2c), which will give them their
-- lengths and points; until then only the order of choices matters.
--------------------------------------------------------------------------------

local NW, SE = "north-west home", "south-east home"
local ST, BS, FA, GM, LM = "Stables", "Blacksmith", "Farm", "Gold Mine", "Lumber Mill"

local Crossings = {}

-- {{{ shared: the fewest crossings
Crossings.shared = {
    name  = "shared",
    about = "Forks offering the same places are one crossing; each home has one road, to its near base.",
    roads = {
        { NW, ST }, { SE, FA },
        -- the Stables: left to crossing D (Blacksmith, Gold Mine, and on along the cliff to the Farm's right fork)
        { ST, "crossing D" },
        -- right to its own fork: the Blacksmith-Farm crossing (C) or the Lumber Mill
        { ST, "Stables right fork" }, { "Stables right fork", "crossing C" }, { "Stables right fork", LM },
        -- crossing D: Blacksmith, Gold Mine, Stables, and the cliff road
        { "crossing D", BS }, { "crossing D", GM }, { "crossing D", "Farm right fork" },
        -- crossing C: Blacksmith, Lumber Mill, Farm (the Farm's left exit)
        { "crossing C", BS }, { "crossing C", LM }, { "crossing C", FA },
        -- the Farm's right exit: the Gold Mine, or crossing C
        { FA, "Farm right fork" }, { "Farm right fork", GM }, { "Farm right fork", "crossing C" },
        -- the Gold Mine's left road to the Farm; the Lumber Mill's left road to the Stables
        { GM, FA }, { LM, ST },
    },
}
-- }}}

-- {{{ literal: every exit its own fork
Crossings.literal = {
    name  = "literal",
    about = "Every exit's fork is its own crossing, as the table reads; each home keeps the bot module's three roads.",
    roads = {
        { NW, ST }, { NW, GM }, { NW, LM },
        { SE, FA }, { SE, GM }, { SE, LM },
        { ST, "Stables left fork" },  { "Stables left fork", GM }, { "Stables left fork", FA }, { "Stables left fork", BS },
        { ST, "Stables right fork" }, { "Stables right fork", "Blacksmith other fork" }, { "Stables right fork", LM },
        { FA, "Farm left fork" },     { "Farm left fork", LM }, { "Farm left fork", ST }, { "Farm left fork", BS },
        { FA, "Farm right fork" },    { "Farm right fork", GM }, { "Farm right fork", "Blacksmith other fork" },
        { GM, FA },
        { GM, "Gold Mine right fork" }, { "Gold Mine right fork", BS }, { "Gold Mine right fork", ST },
        { LM, ST },
        { LM, "Lumber Mill right fork" }, { "Lumber Mill right fork", BS }, { "Lumber Mill right fork", FA },
        { BS, "Blacksmith one fork" },   { "Blacksmith one fork", GM }, { "Blacksmith one fork", ST },
        { BS, "Blacksmith other fork" }, { "Blacksmith other fork", LM }, { "Blacksmith other fork", FA },
    },
}
-- }}}

-- {{{ function Crossings.as_roads
-- A map's roads in the shape arathi-basin-routes.lua's graph takes: each
-- { from, to, length }. Unrecorded roads all count length 1: only which
-- roads meet where matters to the rule.
function Crossings.as_roads(map)
    local out = {}
    for _, r in ipairs(map.roads) do out[#out + 1] = { from = r[1], to = r[2], length = 1 } end
    return out
end
-- }}}

Crossings.BASES = { ST, BS, FA, GM, LM }
Crossings.HOMES = { NW, SE }

return Crossings
