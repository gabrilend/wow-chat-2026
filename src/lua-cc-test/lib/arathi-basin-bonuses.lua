
local Bonuses = {}

Bonuses.KIND = {
    ["Gold Mine"]   = "armour",
    ["Lumber Mill"] = "ranged damage",
    ["Blacksmith"]  = "melee damage",
    ["Stables"]     = "movement speed",
    ["Farm"]        = "health",
}
Bonuses.STEP_RESOURCES = 100
Bonuses.STEP_PERCENT   = 5
Bonuses.MAX_RESOURCES  = 1600

function Bonuses.new()
    local s = { bases = {} }
    for base in pairs(Bonuses.KIND) do
        s.bases[base] = { holder = nil, contested = false, counted = 0 }
    end
    return s
end

function Bonuses.captured(s, base, side)
    local b = assert(s.bases[base], "unknown base " .. tostring(base))
    b.holder, b.contested, b.counted = side, false, 0
end

function Bonuses.assaulted(s, base, side)
    local b = assert(s.bases[base], "unknown base " .. tostring(base))
    if b.holder and b.holder ~= side then b.contested = true end
end

function Bonuses.defended(s, base)
    local b = assert(s.bases[base], "unknown base " .. tostring(base))
    b.contested = false
end

function Bonuses.income(s, side, amount)
    for _, b in pairs(s.bases) do
        if b.holder == side and not b.contested then b.counted = b.counted + amount end
    end
end

function Bonuses.steps(s, base)
    local b = s.bases[base]
    return math.min(math.floor(b.counted / Bonuses.STEP_RESOURCES), Bonuses.MAX_RESOURCES / Bonuses.STEP_RESOURCES)
end

function Bonuses.active(s, side)
    local out = {}
    for base, b in pairs(s.bases) do
        if b.holder == side and not b.contested then
            local pct = Bonuses.steps(s, base) * Bonuses.STEP_PERCENT
            if pct > 0 then out[Bonuses.KIND[base]] = pct end
        end
    end
    return out
end

return Bonuses
