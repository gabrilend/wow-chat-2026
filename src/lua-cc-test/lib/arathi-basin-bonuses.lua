--------------------------------------------------------------------------------
-- arathi-basin-bonuses.lua (issue 176a2e) - each base's growing bonus
--
-- For a general audience: a base a side holds grows a bonus for every unit
-- of that side, anywhere on the map: the Gold Mine armour, the Lumber Mill
-- ranged damage, the Blacksmith melee damage, the Stables movement speed,
-- the Farm health. Each base keeps its own count, from its own capture
-- (the owner, 2026-10-08: "if you capture the BS while you have 165
-- resources, then at 265 the BS bonus will increment. The Stables could
-- have been capped at 35 resources, which means it'll increment at 135,
-- then 235, etc."): every 100 resources the side gains while that base is
-- held and not under attack, +5% ("let's try 5%"). While the enemy is
-- taking it (its banner clicked, the 60 seconds running) the bonus is off
-- and nothing counts; won back, it returns at exactly the steps it had.
-- Taken by the enemy, it is gone, and the new holders start from zero.
-- A side never gains more than 1,600 resources, so a base can't pass 16
-- steps (+80%).
--
-- Plain data and arithmetic: the match tells it what happened (a resource
-- tick, a banner clicked, a capture), and it answers what bonus each side
-- has now. scripts/test-arathi-basin-rules runs it without a server.
--------------------------------------------------------------------------------

local Bonuses = {}

-- what one step of each base gives
Bonuses.KIND = {
    ["Gold Mine"]   = "armour",
    ["Lumber Mill"] = "ranged damage",
    ["Blacksmith"]  = "melee damage",
    ["Stables"]     = "movement speed",
    ["Farm"]        = "health",
}
Bonuses.STEP_RESOURCES = 100                         -- a step every 100 the side gains while the base works
Bonuses.STEP_PERCENT   = 5                           -- +5% a step
Bonuses.MAX_RESOURCES  = 1600                        -- the stock win (BG_AB_MAX_TEAM_SCORE): 16 steps at most

-- {{{ function Bonuses.new
-- A match's bases, all neutral.
function Bonuses.new()
    local s = { bases = {} }
    for base in pairs(Bonuses.KIND) do
        s.bases[base] = { holder = nil, contested = false, counted = 0 }
    end
    return s
end
-- }}}

-- {{{ events from the match
-- A side fully captured a base (from neutral or from the enemy): the
-- count starts from zero for the new holder.
function Bonuses.captured(s, base, side)
    local b = assert(s.bases[base], "unknown base " .. tostring(base))
    b.holder, b.contested, b.counted = side, false, 0
end

-- A side clicked a base's banner. On a base the other side holds: under
-- attack, the bonus off, nothing counting, the count kept. On a neutral
-- base, or the clicking side's own: nothing changes here.
function Bonuses.assaulted(s, base, side)
    local b = assert(s.bases[base], "unknown base " .. tostring(base))
    if b.holder and b.holder ~= side then b.contested = true end
end

-- The holders clicked their banner back in time: the bonus returns at
-- the steps it had, and counting goes on.
function Bonuses.defended(s, base)
    local b = assert(s.bases[base], "unknown base " .. tostring(base))
    b.contested = false
end

-- A resource tick: `amount` more for `side`. Every base that side holds
-- and that isn't under attack counts it.
function Bonuses.income(s, side, amount)
    for _, b in pairs(s.bases) do
        if b.holder == side and not b.contested then b.counted = b.counted + amount end
    end
end
-- }}}

-- {{{ answers
-- The steps a base has reached (kept while under attack).
function Bonuses.steps(s, base)
    local b = s.bases[base]
    return math.min(math.floor(b.counted / Bonuses.STEP_RESOURCES), Bonuses.MAX_RESOURCES / Bonuses.STEP_RESOURCES)
end

-- What `side` has in force now: { [kind] = percent }, from every base it
-- holds that isn't under attack. Kinds with no bonus are left out.
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
-- }}}

return Bonuses
