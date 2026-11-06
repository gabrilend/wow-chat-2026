--------------------------------------------------------------------------------
-- buddy-party-buffs.lua (issue 617c5) - one plan per party for its buffs
--
-- For a general audience: a party's paladins each keep up an aura, put a
-- blessing on every member and judge their target; its shamans each put
-- down one totem of each element. Left alone, every paladin buddy chooses
-- the same things. This module shares them out for the whole party: no
-- two give the same aura, blessing or totem while another is missing, and
-- each goes to whoever needs it most, in the owner's order (617c5): what a
-- member asked for, then a buff a giver's talents improve (to members who
-- can use it), then what a member needs right now (Wisdom for a healer low
-- on mana), then the usual for its role. Auras and totems answer the
-- threats the party has met (a fire resistance aura when fire is what hurts
-- it; no Stoneskin Totem against casters).
--
-- Players are part of the plan (the owner, 2026-10-28: "Buddies plan around
-- any player in the group"): what a player paladin already gives is read
-- and left alone, and the buddies fill around it.
--
-- This is the Lua model of the party plan (617c5's step 2), pure decisions
-- on plain tables, no server calls; the offline test is
-- scripts/test-buddy-party-buffs. Nothing in the game asks it yet.
--
-- The party (`party`):
--   givers     list of { name, class = "paladin" | "shaman", player = bool,
--                        knows = { [buff] = true },        -- what it can give
--                        improved = { [buff] = true },     -- its talents improve
--                        aura = current aura,              -- for the announcements
--                        gives = { aura, blessings = { [receiver] = blessing }, judgement } }
--                        -- `gives`: a player's own choices, kept as they are
--   receivers  list of { name, role = "tank" | "healer" | "caster" | "melee" | "ranged",
--                        mana = 0..1 (nil: uses none), health = 0..1,
--                        wish = blessing, avoid = { [blessing] = true } }
--   damage     { [school] = share of the damage taken lately, 0..1 }
--   enemy      "casters" when the foes are mostly casters, else nil
--------------------------------------------------------------------------------

local Buffs = {}

-- {{{ the numbers
Buffs.LOW_MANA     = 0.35       -- below this a mana user wants Wisdom first, until the next plan
Buffs.RESIST_SHARE = 0.40       -- a school this share of the damage taken calls for its resistance
-- }}}

-- {{{ the blessings: who can properly use each, and the usual by role
-- Might is attack power (weapon users, hunters included); Wisdom is mana
-- (mana users); Sanctuary, a protection talent, is a tank's; Kings, anyone.
Buffs.BLESSINGS = {
    kings     = { tank = true, healer = true, caster = true, melee = true, ranged = true },
    might     = { tank = true,                                melee = true, ranged = true },
    wisdom    = {              healer = true, caster = true,                ranged = true },
    sanctuary = { tank = true },
}
-- The owner's "usual by role" (617c5), every blessing a role can use, in
-- order. Sanctuary, rare (a protection talent), is first in a tank's: the
-- only role that can use it.
Buffs.USUAL = {
    healer = { "kings",     "wisdom" },
    caster = { "kings",     "wisdom" },
    melee  = { "might",     "kings"  },
    ranged = { "might",     "kings",  "wisdom" },
    tank   = { "sanctuary", "kings",  "might"  },
}
Buffs.BLESSING_ORDER = { "kings", "might", "wisdom", "sanctuary" }  -- improved ones are tried in this order
-- }}}

-- {{{ auras and totems: what each answers
-- `resist`: the school it guards against (first when that school's share
-- reaches RESIST_SHARE); `wants`: the party it helps (nil: any party);
-- `not_vs`: an enemy it doesn't help against. Listed in the order they are
-- tried after the resistances.
Buffs.AURAS = {
    { name = "devotion",          not_vs = "casters" },
    { name = "concentration",     wants  = "casters" },     -- a party with a healer or a caster
    { name = "retribution" },
    { name = "fire resistance",   resist = "fire"   },
    { name = "frost resistance",  resist = "frost"  },
    { name = "shadow resistance", resist = "shadow" },
}
Buffs.TOTEMS = {
    earth = { { name = "strength of earth", wants = "weapons" },
              { name = "stoneskin",         not_vs = "casters" } },
    fire  = { { name = "totem of wrath",    wants = "casters" },
              { name = "flametongue",       wants = "casters" },
              { name = "frost resistance",  resist = "frost" },
              { name = "searing" } },
    water = { { name = "mana spring",       wants = "mana" },
              { name = "healing stream" },
              { name = "fire resistance",   resist = "fire" } },
    air   = { { name = "windfury",          wants = "weapons" },
              { name = "wrath of air",      wants = "casters" },
              { name = "nature resistance", resist = "nature" },
              { name = "grounding",         vs = "casters" } },
}
Buffs.ELEMENTS = { "earth", "fire", "water", "air" }
Buffs.JUDGEMENTS = { "light", "wisdom", "justice" }
-- }}}

-- {{{ local helpers
local function has_role(party, roles)
    for _, r in ipairs(party.receivers or {}) do if roles[r.role] then return true end end
    return false
end

local WANTS = {
    casters = function(p) return has_role(p, { healer = true, caster = true }) end,
    weapons = function(p) return has_role(p, { tank = true, melee = true, ranged = true }) end,
    mana    = function(p) for _, r in ipairs(p.receivers or {}) do if r.mana then return true end end return false end,
}

-- Whether a buff (aura or totem) helps this party, and how it ranks: the
-- resistances that are called for come first, by share; then the others in
-- their listed order; the rest of the resistances are left out.
local function ranked(party, list)
    local damage, resist, rest = party.damage or {}, {}, {}
    for k, b in ipairs(list) do
        if b.resist then
            local share = damage[b.resist] or 0
            if share >= Buffs.RESIST_SHARE then resist[#resist + 1] = { b = b, share = share, k = k } end
        elseif (not b.wants or WANTS[b.wants](party))
           and (not b.not_vs or party.enemy ~= b.not_vs)
           and (not b.vs or party.enemy == b.vs) then
            rest[#rest + 1] = b.name
        end
    end
    table.sort(resist, function(a, c) if a.share ~= c.share then return a.share > c.share end return a.k < c.k end)
    local out = {}
    for _, x in ipairs(resist) do out[#out + 1] = x.b.name end
    for _, n in ipairs(rest) do out[#out + 1] = n end
    return out
end

-- Every way to hand `buffs` (a list) to distinct `givers`, each knowing
-- its buff: calls `f(assignment)` with { [giver index] = buff } for each.
local function each_matching(givers, buffs, f)
    local used, pick = {}, {}
    local function go(k)
        if k > #buffs then f(pick); return end
        for g, giver in ipairs(givers) do
            if not used[g] and giver.knows and giver.knows[buffs[k]] then
                used[g], pick[g] = true, buffs[k]
                go(k + 1)
                used[g], pick[g] = nil, nil
            end
        end
    end
    go(1)
end

-- From a ranked list, the buffs the givers hand out: the best that can all
-- be given at once (each giver one, knowing it), taken in rank order; then
-- of the ways to give them, the one that hands the most to givers whose
-- talents improve them. Returns { [giver index] = buff }.
local function share_out(givers, list)
    local chosen = {}
    for _, b in ipairs(list) do
        if #chosen >= #givers then break end
        local try, ok = {}, false
        for k, c in ipairs(chosen) do try[k] = c end
        try[#try + 1] = b
        each_matching(givers, try, function() ok = true end)
        if ok then chosen = try end
    end
    local best, best_n = {}, -1
    each_matching(givers, chosen, function(pick)
        local n = 0
        for g, b in pairs(pick) do if givers[g].improved and givers[g].improved[b] then n = n + 1 end end
        if n > best_n then
            best_n, best = n, {}
            for g, b in pairs(pick) do best[g] = b end
        end
    end)
    return best
end

local function of_class(party, class)
    local players, buddies = {}, {}
    for _, g in ipairs(party.givers or {}) do
        if g.class == class then
            if g.player then players[#players + 1] = g else buddies[#buddies + 1] = g end
        end
    end
    return players, buddies
end
-- }}}

-- {{{ function Buffs.wishes
-- A receiver's blessings, most wanted first, by the owner's order: its
-- stated wish (always first, usable or not); then a blessing a buddy
-- paladin's talents improve that it can properly use; then Wisdom when it
-- is low on mana; then the usual for its role (every blessing it can use).
-- What it said no to is left out.
function Buffs.wishes(receiver, paladins)
    local out, seen, avoid = {}, {}, receiver.avoid or {}
    local function add(b)
        if b and not seen[b] and not avoid[b] then seen[b] = true; out[#out + 1] = b end
    end
    local usable = function(b) return Buffs.BLESSINGS[b] and Buffs.BLESSINGS[b][receiver.role] end
    add(receiver.wish)
    for _, b in ipairs(Buffs.BLESSING_ORDER) do
        for _, p in ipairs(paladins) do
            if usable(b) and p.knows and p.knows[b] and p.improved and p.improved[b] then add(b) end
        end
    end
    if receiver.mana and receiver.mana < Buffs.LOW_MANA and usable("wisdom") then add("wisdom") end
    for _, b in ipairs(Buffs.USUAL[receiver.role] or {}) do add(b) end
    return out
end
-- }}}

-- {{{ function Buffs.judgements
-- The judgements on one target, in the order paladins take them (the owner,
-- 2026-10-28: "Light if the party needs health, wisdom if the party needs
-- mana"): the larger of the party's health and mana shortfall first, then
-- the other, then Justice. `taken`: judgements already on it (a player's).
function Buffs.judgements(party, taken)
    local hurt, hn, dry, mn = 0, 0, 0, 0
    for _, r in ipairs(party.receivers or {}) do
        if r.health then hurt, hn = hurt + (1 - r.health), hn + 1 end
        if r.mana   then dry,  mn = dry  + (1 - r.mana),   mn + 1 end
    end
    hurt, dry = hn > 0 and hurt / hn or 0, mn > 0 and dry / mn or 0
    local order = dry > hurt and { "wisdom", "light", "justice" } or { "light", "wisdom", "justice" }
    local out = {}
    for _, j in ipairs(order) do if not (taken or {})[j] then out[#out + 1] = j end end
    return out
end
-- }}}

-- {{{ function Buffs.plan
-- The party's plan: { auras = { [paladin] = aura }, blessings = { [receiver]
-- = { [paladin] = blessing } }, judgements = { [paladin] = judgement },
-- totems = { [shaman] = { [element] = totem } }, said = { lines } }, for
-- buddies only (a player's own choices are read, not planned). `said`: what
-- the buddies tell the party (the owner, 2026-10-28: "send each other a
-- message if they have an improved version of the aura, and ... if a buddy
-- will switch to a different one").
function Buffs.plan(party)
    local plan = { auras = {}, blessings = {}, judgements = {}, totems = {}, said = {} }
    local players, pals = of_class(party, "paladin")

    -- auras: one paladin each, around what players keep up
    local held = {}
    for _, p in ipairs(players) do if p.gives and p.gives.aura then held[p.gives.aura] = true end end
    local auras = {}
    for _, a in ipairs(ranked(party, Buffs.AURAS)) do if not held[a] then auras[#auras + 1] = a end end
    for g, a in pairs(share_out(pals, auras)) do
        local p = pals[g]
        plan.auras[p.name] = a
        if p.improved and p.improved[a] then plan.said[#plan.said + 1] = p.name .. ": I have the improved " .. a .. " aura; I'll keep it up." end
        if p.aura and p.aura ~= a then plan.said[#plan.said + 1] = p.name .. ": switching to " .. a .. " aura." end
    end

    -- blessings: per receiver, around what players already give it
    for _, r in ipairs(party.receivers or {}) do
        local given = {}
        for _, p in ipairs(players) do
            local b = p.gives and p.gives.blessings and p.gives.blessings[r.name]
            if b then given[b] = true end
        end
        local list = {}
        for _, b in ipairs(Buffs.wishes(r, pals)) do if not given[b] then list[#list + 1] = b end end
        local mine = {}
        for g, b in pairs(share_out(pals, list)) do mine[pals[g].name] = b end
        plan.blessings[r.name] = mine
    end

    -- judgements: each buddy paladin one the target lacks
    local taken = {}
    for _, p in ipairs(players) do if p.gives and p.gives.judgement then taken[p.gives.judgement] = true end end
    local js = Buffs.judgements(party, taken)
    for k, p in ipairs(pals) do plan.judgements[p.name] = js[k] end

    -- totems: per element, the shamans put down different ones
    local splayers, shamans = of_class(party, "shaman")
    for _, s in ipairs(shamans) do plan.totems[s.name] = {} end
    for _, el in ipairs(Buffs.ELEMENTS) do
        local down = {}
        for _, s in ipairs(splayers) do if s.gives and s.gives[el] then down[s.gives[el]] = true end end
        local list = {}
        for _, t in ipairs(ranked(party, Buffs.TOTEMS[el])) do if not down[t] then list[#list + 1] = t end end
        for g, t in pairs(share_out(shamans, list)) do plan.totems[shamans[g].name][el] = t end
    end
    return plan
end
-- }}}

-- {{{ function Buffs.parse_wish
-- A blessing asked for in a whisper (decided 2026-11-06, 617c5's question
-- 2): a blessing's name or its usual short form names the wish ("kings
-- please", "BoW"); "no", "not" or "don't" before it says no to it; "no
-- preference" or "anything" clears both. Returns { wish = b } or { avoid =
-- b } or { clear = true }, or nil when the words name no blessing.
local WORDS = { kings = "kings", bok = "kings", might = "might", bom = "might",
                wisdom = "wisdom", bow = "wisdom", sanctuary = "sanctuary", bos = "sanctuary", sanc = "sanctuary" }
function Buffs.parse_wish(text)
    local t = " " .. text:lower():gsub("[^%a' ]", " ") .. " "
    if t:find(" no preference ") or t:find(" anything ") then return { clear = true } end
    local no = false
    for w in t:gmatch("[%a']+") do
        if w == "no" or w == "not" or w == "don't" or w == "dont" then no = true
        elseif WORDS[w] then
            if no then return { avoid = WORDS[w] } end
            return { wish = WORDS[w] }
        end
    end
    return nil
end
-- }}}

-- {{{ function Buffs.hear
-- Applies a parsed wish to a receiver (it holds until logout or a new
-- wish, 2026-10-28): a wish replaces the last one and is no longer said no
-- to; a "no" drops that wish if it was the one asked for.
function Buffs.hear(receiver, w)
    if not w then return end
    receiver.avoid = receiver.avoid or {}
    if w.clear then receiver.wish, receiver.avoid = nil, {} end
    if w.wish  then receiver.wish = w.wish; receiver.avoid[w.wish] = nil end
    if w.avoid then receiver.avoid[w.avoid] = true; if receiver.wish == w.avoid then receiver.wish = nil end end
end
-- }}}

return Buffs
