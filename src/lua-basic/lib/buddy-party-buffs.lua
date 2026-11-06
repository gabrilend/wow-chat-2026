--------------------------------------------------------------------------------
-- buddy-party-buffs.lua (issue 617c5) - one plan per party for its buffs
--
-- For a general audience: a party's paladins each keep up an aura, put a
-- blessing on every member and judge their target; its shamans each put
-- down one totem of each element; a hunter can give the party nature
-- resistance with an aspect, a priest shadow resistance with a prayer.
-- Left alone, every buddy chooses the same things. This module shares them
-- out for the whole party as a checklist (the owner, 2026-11-05: "we should
-- treat each buff type as a separate category, and keep a checklist to see
-- when we're missing one. if we can apply one, we should."): each category
-- is one kind of effect, whoever gives it, so two buffs the game doesn't
-- let stack are one line on the list (a paladin's fire resistance aura and
-- a shaman's fire resistance totem; a Mana Spring Totem and a Blessing of
-- Wisdom). The plan ticks off what players already give, then fills every
-- missing line it can, most needed first, with whoever can, a giver whose
-- talents improve that buff first (the owner, 2026-11-05: "one player might
-- have the talent that buffs that buff, in which case they should have
-- priority for placing it").
--
-- Which buffs share a category is the game's own stacking table
-- (`spell_group` and `spell_group_stack_rules` in the world database: Mana
-- Spring with Blessing of Wisdom in "MP5 Buffs", Totem of Wrath with
-- Flametongue Totem in "Spell Power Buffs"; Devotion Aura and Stoneskin
-- Totem are in different groups, so both count) and its spell data
-- (resistance auras, totems, Aspect of the Wild and Shadow Protection are
-- all "exclusive resistance": only the strongest of a school counts).
--
-- Resistances go up only when their school's damage is enough to matter
-- (the owner, 2026-11-05: "Significant not as in "a lot" but rather
-- "enough to matter" which we can assess using the dynamic combat system
-- we're developing"): that judgement is the combat system's, and comes in
-- as `party.resist`. What a giver loses by putting one up (a hunter its
-- damage aspect, a shaman another totem of that element) is accepted
-- ("a shaman also loses utility from using that particular totem, so it's
-- okay").
--
-- Players are part of the plan (the owner, 2026-10-28: "Buddies plan around
-- any player in the group"): what a player already gives is read and left
-- alone, and the buddies fill around it.
--
-- The Lua model of the party plan (617c5's step 2), pure decisions on plain
-- tables, no server calls; the offline test is scripts/test-buddy-party-buffs.
-- Nothing in the game asks it yet.
--
-- The party (`party`):
--   givers     list of { name, class = "paladin" | "shaman" | "hunter" | "priest",
--                        player = bool,
--                        knows = { [buff] = true },        -- what it can give (names below)
--                        improved = { [buff] = true },     -- what its talents improve
--                        aura = current aura,              -- a paladin's, for the announcements
--                        gives = { ... } }                 -- a player's own choices, kept as they are:
--                          paladin { aura, blessings = { [receiver] = blessing }, judgement }
--                          shaman  { earth, fire, water, air }   (a totem each)
--                          hunter  { aspect }
--                          priest  { prayer = "shadow protection" }
--   receivers  list of { name, role = "tank" | "healer" | "caster" | "melee" | "ranged",
--                        mana = 0..1 (nil: uses none), health = 0..1,
--                        wish = blessing, avoid = { [blessing] = true } }
--   resist     { [school] = true } for each school whose damage is enough to
--              matter (fire, frost, shadow, nature): the combat system's call
--   enemy      "casters" when the foes are mostly casters, else nil
-- A paladin knows judgements as "judgement of light", "judgement of wisdom"
-- and "judgement of justice" (a blessing of the same name is "wisdom").
--------------------------------------------------------------------------------

local Buffs = {}

-- {{{ the numbers
Buffs.LOW_MANA = 0.35       -- below this a mana user wants Wisdom first, until the next plan
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
-- only role that can use it. (In the game Sanctuary's strength and stamina
-- don't add to Kings' (stacking group 1038, "All Stats Percentage with
-- Sanctuary"), but its damage taken and mana do, and Kings' agility,
-- intellect and spirit do, so a tank still gets both.)
Buffs.USUAL = {
    healer = { "kings",     "wisdom" },
    caster = { "kings",     "wisdom" },
    melee  = { "might",     "kings"  },
    ranged = { "might",     "kings",  "wisdom" },
    tank   = { "sanctuary", "kings",  "might"  },
}
Buffs.BLESSING_ORDER = { "kings", "might", "wisdom", "sanctuary" }  -- improved ones are tried in this order
-- A blessing whose effect a party-wide buff already gives (the same
-- stacking group): Wisdom's mana is Mana Spring's (group 1105, "MP5 Buffs").
Buffs.BLESSING_CATEGORY = { wisdom = "mana regeneration" }
-- }}}

-- {{{ the party-wide categories: the checklist
-- Each line: the category's name; who can give it (class, the slot it takes,
-- the spell's name in `knows`), best first; and when the party wants it:
-- `resist` a school (only when `party.resist` says that school matters),
-- `wants` a kind of party (nil: any), `not_vs` an enemy it doesn't help
-- against, `vs` the only enemy it helps against. The list's order is the
-- order the checklist is filled in after the resistances. Slots: a
-- paladin's "aura", a shaman's "earth", "fire", "water", "air", a hunter's
-- "aspect", a priest's "prayer"; each slot gives one thing.
Buffs.CATEGORIES = {
    { name = "fire resistance",   resist = "fire",   by = { { "paladin", "aura", "fire resistance" },   { "shaman", "water", "fire resistance" } } },
    { name = "frost resistance",  resist = "frost",  by = { { "paladin", "aura", "frost resistance" },  { "shaman", "fire",  "frost resistance" } } },
    { name = "shadow resistance", resist = "shadow", by = { { "paladin", "aura", "shadow resistance" }, { "priest", "prayer", "shadow protection" } } },
    { name = "nature resistance", resist = "nature", by = { { "shaman", "air", "nature resistance" },   { "hunter", "aspect", "aspect of the wild" } } },
    { name = "armor",             not_vs = "casters", by = { { "paladin", "aura", "devotion" } } },
    { name = "concentration",     wants  = "casters", by = { { "paladin", "aura", "concentration" } } },
    { name = "retribution",                           by = { { "paladin", "aura", "retribution" } } },
    { name = "strength and agility", wants = "weapons", by = { { "shaman", "earth", "strength of earth" } } },
    { name = "stoneskin",         not_vs = "casters", by = { { "shaman", "earth", "stoneskin" } } },
    { name = "spell power",       wants  = "casters", by = { { "shaman", "fire", "totem of wrath" }, { "shaman", "fire", "flametongue" } } },
    { name = "searing",                               by = { { "shaman", "fire", "searing" } } },
    { name = "mana regeneration", wants  = "mana",    by = { { "shaman", "water", "mana spring" } } },
    { name = "healing stream",                        by = { { "shaman", "water", "healing stream" } } },
    { name = "melee haste",       wants  = "weapons", by = { { "shaman", "air", "windfury" } } },
    { name = "spell haste",       wants  = "casters", by = { { "shaman", "air", "wrath of air" } } },
    { name = "grounding",         vs     = "casters", by = { { "shaman", "air", "grounding" } } },
}
Buffs.SLOTS = { paladin = { "aura" }, shaman = { "earth", "fire", "water", "air" }, hunter = { "aspect" }, priest = { "prayer" } }
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

-- The checklist's lines this party wants, most needed first: the
-- resistances whose school matters (`party.resist[school]` true, or a
-- number saying how much: the larger first, then the list's order), then
-- the rest that help this party.
local function wanted(party)
    local resist, rest, how = {}, {}, {}
    for k, c in ipairs(Buffs.CATEGORIES) do
        if c.resist then
            local m = (party.resist or {})[c.resist]
            if m == true or (type(m) == "number" and m > 0) then
                resist[#resist + 1] = c
                how[c] = { m == true and 1 or m, k }
            end
        elseif (not c.wants or WANTS[c.wants](party))
           and (not c.not_vs or party.enemy ~= c.not_vs)
           and (not c.vs or party.enemy == c.vs) then
            rest[#rest + 1] = c
        end
    end
    table.sort(resist, function(a, b)
        if how[a][1] ~= how[b][1] then return how[a][1] > how[b][1] end
        return how[a][2] < how[b][2]
    end)
    for _, c in ipairs(rest) do resist[#resist + 1] = c end
    return resist
end
-- }}}

-- {{{ local function hand_out
-- The best way to fill a ranked list of lines from a list of slots: every
-- line that can be filled while all the lines above it that can be are
-- filled too (filled in rank order, each kept if the slots can still cover
-- all chosen so far), and, among the ways of doing that, the one with the
-- most lines given by a slot whose giver's talents improve what it gives,
-- and then the most given with a line's best spell (Totem of Wrath before
-- Flametongue). `fits(line, slot)` gives the spell that slot would use for
-- that line (nil: it can't), whether it is improved, and whether it is the
-- line's best. Returns { [slot index] = { line, spell } }.
--
-- How: a minimum-cost flow, source -> lines -> slots -> sink, each edge
-- carrying one. A line's edge from the source pays a large reward, larger
-- for a higher line, so that one higher line outweighs every line below it
-- together (that is the rank order); an improved slot pays a middle reward
-- that outweighs every best-spell reward together, a best spell one. The
-- cheapest flow is found by sending one unit at a time along the cheapest
-- path (Bellman-Ford over the leftovers, which may hold negative costs),
-- stopping when no path pays. Few lines and slots, so it is quick.
local function hand_out(lines, slots, fits)
    local nl, ns = #lines, #slots
    local S, T = 1, 2 + nl + ns
    local edges, from = {}, {}
    local function add(a, b, cost, data)
        edges[#edges + 1] = { to = b, cap = 1, cost = cost, data = data }
        edges[#edges + 1] = { to = a, cap = 0, cost = -cost }
        from[a] = from[a] or {}; from[a][#from[a] + 1] = #edges - 1
        from[b] = from[b] or {}; from[b][#from[b] + 1] = #edges
    end
    local step = ns + 1                                   -- an improved slot: more than every best spell together
    local unit = step * (ns + 1)                          -- a line: more than every improved slot and best spell together
    for k = 1, nl do add(S, 1 + k, -unit * 2 ^ (nl - k)) end
    for k, line in ipairs(lines) do
        for j, slot in ipairs(slots) do
            local spell, improved, best = fits(line, slot)
            if spell then
                add(1 + k, 1 + nl + j, -((improved and step or 0) + (best and 1 or 0)), { k = k, j = j, spell = spell })
            end
        end
    end
    for j = 1, ns do add(1 + nl + j, T, 0) end
    while true do
        local dist, via = {}, {}
        dist[S] = 0
        for _ = 1, T do
            local moved = false
            for v = 1, T do
                if dist[v] then
                    for _, e in ipairs(from[v] or {}) do
                        local ed = edges[e]
                        if ed.cap > 0 and (dist[ed.to] == nil or dist[v] + ed.cost < dist[ed.to]) then
                            dist[ed.to], via[ed.to], moved = dist[v] + ed.cost, e, true
                        end
                    end
                end
            end
            if not moved then break end
        end
        if dist[T] == nil or dist[T] >= 0 then break end
        local v = T
        while v ~= S do
            local e = via[v]
            edges[e].cap = edges[e].cap - 1
            local back = (e % 2 == 1) and e + 1 or e - 1
            edges[back].cap = edges[back].cap + 1
            v = edges[back].to
        end
    end
    local out = {}
    for _, ed in ipairs(edges) do
        if ed.data and ed.cap == 0 then out[ed.data.j] = { line = lines[ed.data.k], spell = ed.data.spell } end
    end
    return out
end
-- }}}

-- {{{ local function by_class
local function by_class(party)
    local players, buddies = {}, {}
    for _, g in ipairs(party.givers or {}) do
        if g.player then players[#players + 1] = g else buddies[#buddies + 1] = g end
    end
    return players, buddies
end
-- }}}

-- {{{ function Buffs.wishes
-- A receiver's blessings, most wanted first, by the owner's order: its
-- stated wish (always first, usable or not); then a blessing a buddy
-- paladin's talents improve that it can properly use; then Wisdom when it
-- is low on mana; then the usual for its role (every blessing it can use).
-- What it said no to is left out, and so is a blessing whose effect the
-- party already has from elsewhere (`covered`, e.g. Wisdom beside a Mana
-- Spring Totem), unless it is the wish.
function Buffs.wishes(receiver, paladins, covered)
    local out, seen, avoid, covered = {}, {}, receiver.avoid or {}, covered or {}
    local function add(b)
        if b and not seen[b] and not avoid[b] then
            seen[b] = true
            if b == receiver.wish or not covered[Buffs.BLESSING_CATEGORY[b] or ""] then out[#out + 1] = b end
        end
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
-- The party's plan: { auras = { [paladin] = aura }, totems = { [shaman] =
-- { [element] = totem } }, aspects = { [hunter] = aspect }, prayers =
-- { [priest] = prayer }, blessings = { [receiver] = { [paladin] = blessing } },
-- judgements = { [paladin] = judgement }, checklist = { { category, by =
-- giver's name or nil } }, said = { lines } }, for buddies only (a player's
-- own choices are read, not planned). A hunter with no aspect in the plan
-- keeps its own. `checklist`: every line the party wants, most needed
-- first, and who gives it (nil: nobody can, so it is missing). `said`: what
-- the buddies tell the party (the owner, 2026-10-28: "send each other a
-- message if they have an improved version of the aura, and ... if a buddy
-- will switch to a different one").
function Buffs.plan(party)
    local plan = { auras = {}, totems = {}, aspects = {}, prayers = {}, blessings = {}, judgements = {}, checklist = {}, said = {} }
    local players, buddies = by_class(party)
    local OUT = { aura = plan.auras, aspect = plan.aspects, prayer = plan.prayers }

    -- the checklist: ticked off by what players give, then filled by buddies
    local lines = wanted(party)
    local held = {}
    for _, p in ipairs(players) do
        for _, slot in ipairs(Buffs.SLOTS[p.class] or {}) do
            local spell = p.gives and p.gives[slot]
            if spell then
                for _, c in ipairs(lines) do
                    for _, w in ipairs(c.by) do
                        if w[1] == p.class and w[2] == slot and w[3] == spell and not held[c] then held[c] = p.name end
                    end
                end
            end
        end
    end
    local missing = {}
    for _, c in ipairs(lines) do if not held[c] then missing[#missing + 1] = c end end
    local slots = {}
    for _, g in ipairs(buddies) do
        if g.class == "shaman" then plan.totems[g.name] = {} end
        for _, slot in ipairs(Buffs.SLOTS[g.class] or {}) do slots[#slots + 1] = { giver = g, slot = slot } end
    end
    local filled = hand_out(missing, slots, function(c, s)
        for k, w in ipairs(c.by) do
            if w[1] == s.giver.class and w[2] == s.slot and s.giver.knows and s.giver.knows[w[3]] then
                local best = true                         -- no spell before it in the line could this slot's class give
                for b = 1, k - 1 do if c.by[b][1] == w[1] and c.by[b][2] == w[2] then best = false end end
                return w[3], s.giver.improved and s.giver.improved[w[3]] == true, best
            end
        end
    end)
    local by = {}
    for j, f in pairs(filled) do
        local s = slots[j]
        by[f.line] = s.giver.name
        if s.giver.class == "shaman" then plan.totems[s.giver.name][s.slot] = f.spell else OUT[s.slot][s.giver.name] = f.spell end
    end
    local covered = {}
    for _, c in ipairs(lines) do
        local who = held[c] or by[c]
        plan.checklist[#plan.checklist + 1] = { category = c.name, by = who }
        if who then covered[c.name] = true end
    end
    for _, p in ipairs(players) do                       -- a player's blessing-like buff counts too (a player shaman's Mana Spring)
        if p.class == "shaman" and p.gives and p.gives.water == "mana spring" then covered["mana regeneration"] = true end
    end

    -- what the paladins say about their auras
    for _, g in ipairs(buddies) do
        local a = plan.auras[g.name]
        if a then
            if g.improved and g.improved[a] then plan.said[#plan.said + 1] = g.name .. ": I have the improved " .. a .. " aura; I'll keep it up." end
            if g.aura and g.aura ~= a then plan.said[#plan.said + 1] = g.name .. ": switching to " .. a .. " aura." end
        end
    end

    -- blessings: per receiver, around what players already give it
    local pals = {}
    for _, g in ipairs(buddies) do if g.class == "paladin" then pals[#pals + 1] = g end end
    local pslots = {}
    for _, g in ipairs(pals) do pslots[#pslots + 1] = { giver = g } end
    for _, r in ipairs(party.receivers or {}) do
        local given = {}
        for _, p in ipairs(players) do
            local b = p.class == "paladin" and p.gives and p.gives.blessings and p.gives.blessings[r.name]
            if b then given[b] = true end
        end
        local list = {}
        for _, b in ipairs(Buffs.wishes(r, pals, covered)) do if not given[b] then list[#list + 1] = b end end
        local mine = {}
        local got = hand_out(list, pslots, function(b, s)
            if s.giver.knows and s.giver.knows[b] then return b, s.giver.improved and s.giver.improved[b] == true end
        end)
        for j, f in pairs(got) do mine[pslots[j].giver.name] = f.spell end
        plan.blessings[r.name] = mine
    end

    -- judgements: each buddy paladin one the target lacks, and one it knows
    local taken = {}
    for _, p in ipairs(players) do
        if p.class == "paladin" and p.gives and p.gives.judgement then taken[p.gives.judgement] = true end
    end
    local js = hand_out(Buffs.judgements(party, taken), pslots, function(j, s)
        if s.giver.knows and s.giver.knows["judgement of " .. j] then return j, false end
    end)
    for j, f in pairs(js) do plan.judgements[pslots[j].giver.name] = f.spell end
    return plan
end
-- }}}

-- {{{ function Buffs.parse_wish
-- A blessing asked for in chat, said the way players say it (the owner,
-- 2026-11-05: "the paladin [picks] a buff and if the receiver wants
-- something else they say something like "kings" or "can you do might
-- instead?" or similar ... they'll say it in party / raid instead like "can
-- I get wisdom" and then the paladins figure it out"). Whispered to a buddy
-- paladin or said in party or raid chat, by the receiver; which paladin
-- gives it is the plan's. Until the custom client's language model reads
-- what a message means, a message is a wish only when it is plainly one, so
-- that "you might want to heal" or "I need a new bow" are not:
--   - the blessing alone, perhaps with "please", "blessing of", "?" ("kings",
--     "Wisdom please", "BoW?"), or a message ending with it and "please"
--     ("not now, kings please");
--   - a request right before its name: "can you do might (instead)", "can I
--     get/have wisdom", "could I get ...", "I'd like ...", "give me ...",
--     "switch to ...", or "... instead";
--   - the short forms (BoK, BoM, BoW, BoS, Sanc) count in those places only
--     (so "bow" is a blessing in "can I have BoW?" but not in "I need a new
--     bow");
--   - "no", "not", "don't give me" or "no more" right before a name, as the
--     whole message ("no might", "please don't give me sanctuary"), says no
--     to it;
--   - "no preference", "anything" or "whatever", said alone, clears both.
-- Returns { wish = b } or { avoid = b } or { clear = true }, or nil.
local FULL  = { kings = "kings", might = "might", wisdom = "wisdom", sanctuary = "sanctuary" }
local SHORT = { bok = "kings", bom = "might", bow = "wisdom", bos = "sanctuary", sanc = "sanctuary" }
local LEADS = { "can you do", "can you give me", "can you switch to", "could you do", "could you give me",
                "can i get", "can i have", "could i get", "could i have", "i'd like", "i would like",
                "give me", "switch to" }
local CLEAR = { ["no preference"] = true, ["anything"] = true, ["whatever"] = true, ["anything is fine"] = true }
local NO    = { "no", "not", "no more", "don't give me", "do not give me", "dont give me" }
function Buffs.parse_wish(text)
    local t = text:lower():gsub("\226\128\153", "'")                         -- a typed curly apostrophe
    t = t:gsub("[^%a' ]", " "):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    local bare = t:gsub(" ?please$", ""):gsub(" ?pls$", ""):gsub(" ?thanks$", ""):gsub("^please ", "")
    bare = bare:gsub("^blessing of ", ""):gsub("^greater blessing of ", "")
    local function name_of(w) return w and (FULL[w] or SHORT[w]) end
    if CLEAR[bare] then return { clear = true } end
    if name_of(bare) then return { wish = name_of(bare) } end
    for _, no in ipairs(NO) do
        local w = bare:match("^" .. no .. " (%a+)$")
        if name_of(w) then return { avoid = name_of(w) } end
    end
    local padded = " " .. t .. " "
    for _, lead in ipairs(LEADS) do
        local at = padded:find(" " .. lead .. " ", 1, true)
        if at then
            local rest = padded:sub(at + #lead + 2):gsub("^blessing of ", ""):gsub("^greater blessing of ", "")
            local b = name_of(rest:match("^'?(%a+)"))      -- "can I get 'kings'"
            if b then
                local pre = padded:sub(1, at)                -- "don't give me might, thanks": a no, not a wish
                if pre:match("don't $") or pre:match("dont $") or pre:match("do not $") then return { avoid = b } end
                return { wish = b }
            end
        end
    end
    local last = t:match("(%a+) please$") or t:match("(%a+) instead$") or t:match("(%a+) instead please$")
    if last and FULL[last] then return { wish = FULL[last] } end   -- full names only: "a new bow please" is no wish
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
