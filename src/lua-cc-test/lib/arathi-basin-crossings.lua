
local NW, SE = "north-west home", "south-east home"
local ST, BS, FA, GM, LM = "Stables", "Blacksmith", "Farm", "Gold Mine", "Lumber Mill"

local Crossings = {}

Crossings.shared = {
    name  = "shared",
    about = "Forks offering the same places are one crossing; each home has one road, to its near base.",
    roads = {
        { NW, ST }, { SE, FA },
        { ST, "crossing D" },
        { ST, "Stables right fork" }, { "Stables right fork", "crossing C" }, { "Stables right fork", LM },
        { "crossing D", BS }, { "crossing D", GM }, { "crossing D", "Farm right fork" },
        { "crossing C", BS }, { "crossing C", LM }, { "crossing C", FA },
        { FA, "Farm right fork" }, { "Farm right fork", GM }, { "Farm right fork", "crossing C" },
        { GM, FA }, { LM, ST },
    },
}

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

function Crossings.as_roads(map)
    local out = {}
    for _, r in ipairs(map.roads) do out[#out + 1] = { from = r[1], to = r[2], length = 1 } end
    return out
end

Crossings.BASES = { ST, BS, FA, GM, LM }
Crossings.HOMES = { NW, SE }

return Crossings
