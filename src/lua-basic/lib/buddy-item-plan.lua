--------------------------------------------------------------------------------
-- buddy-item-plan.lua (issue 617h2) - what a buddy means to do with each item
--
-- For a general audience: the moment a buddy picks something up it decides
-- what that item is for - wear it, open it, learn it, keep it to use, keep
-- it for a recipe it knows, feed it to its pet, give it to a clan-mate,
-- disenchant it, put it on the auction house, sell it to a vendor - and
-- keeps that plan with the item. The owner, 2026-10-30: "everytime a
-- buddy-bot picks up an item, they decide immediately what they want to do
-- with it, and only update this plan if a new items plan would change based
-- on whether or not they did something different with it". So plans are not
-- looked at again on a timer: only a pickup (or a login, which works them
-- all out again) can change one, and only when what the new item did
-- (a recipe learned, money that now buys something wanted) changes it.
--
-- Each plan is settled where it can be: some at once (wear, open, learn,
-- disenchant), some at a place (a vendor, the auction house, a mailbox),
-- some never by this module (use, craft, feed: the item waits to be used).
--
-- Pure decisions, no server calls: the facts about the buddy and each item
-- are passed in, so the offline test (scripts/test-buddy-item-plan) runs
-- the same code an ALE script would. Whether to wear an item is not judged
-- here: the caller says (the bot module's item usage and 617e4b's kept
-- weapons already decide it), see `wear` below.
--
-- Facts about a buddy (`buddy`):
--   professions  { [skill id] = skill rank }          e.g. { [333] = 150 }
--   recipes      { [spell id] = { [item id] = n } }   known recipes and their reagents
--   pet_diet     { [food type] = true } or nil        a hunter's pet's diet
--   clan         list of { name, needs = { [item id] = true } }   what clan-mates want
--   money        copper in its purse (only this buys anything: money still
--                in the mailbox, or an auction not yet sold, buys nothing)
--   wants        list of { name, price }              what it is saving for
--   ammo         the ammo its ranged weapon fires: item_template's subclass
--                of projectiles (2 arrows, 3 bullets), or nil for none
--   ammo_stacks  how many stacks of that ammo it keeps: its ammo bag's
--                slots for a buddy that lives by its ranged weapon (a hunter),
--                1 for one that only carries some (a warrior, a rogue). Who
--                counts as the first kind is the owner's open question
--                (617h2), so the caller says.
-- Facts about an item (`item`), most of them item_template's own:
--   id, count, class, subclass, quality, bonding, sell_price
--   bound        true once soulbound (bind-on-pickup items always are)
--   auction      the copper it is expected to fetch (default: 3 x sell_price)
--   use          true when it has an on-use spell ("Use:")
--   openable     true for a bag of coins, a clam, a lockbox it can open
--   tool         true for a profession tool (item_template's TotemCategory)
--   recipe       { skill, rank, teaches = spell id, reagents = { [id] = n } }
--   food_type    item_template's FoodType, for a pet's diet
--   de_skill     the enchanting rank disenchanting it takes (nil: can't be)
--   wear         "now" (an upgrade it puts on), "kept" (a weapon it keeps as
--                a runner-up), or nil
--   material     true when some profession's recipe uses it (the catalogue's,
--                step 1); read for quest items, which are then trade goods
--   ammo_dps     the damage per second a projectile adds (item_template's
--                dmg_min1 and dmg_max1 for ammo): which ammo is best
--------------------------------------------------------------------------------

local Plan = {}

-- {{{ numbers from the game
local HEARTHSTONE        = 6948
local ENCHANTING         = 333          -- the skill line's id
local CLASS_CONSUMABLE   = 0
local CLASS_WEAPON       = 2
local CLASS_PROJECTILE   = 6            -- arrows and bullets
local CLASS_TRADE_GOODS  = 7
local CLASS_RECIPE       = 9
local CLASS_QUEST        = 12
local SUBCLASS_FISHPOLE  = 20           -- of weapons
local BIND_ON_PICKUP     = 1
local QUALITY_WHITE      = 1
local QUALITY_GREEN      = 2
local AUCTION_GUESS      = 3            -- x vendor price, when the caller gives no auction estimate
-- }}}

-- {{{ the plans
-- Each plan: where it is settled ("now" at pickup, a place, or nil: it waits
-- to be used and nothing here settles it), and whether the buddy keeps the
-- item in its bags until then. Configuration in structure: the order the
-- rules are tried in is RULES below; what each plan means is here.
Plan.PLANS = {
    leave      = { at = "ground",  stays = false },   -- not picked up at all: a quest item no vendor pays for (owner, 2026-11-05)
    keep       = { at = nil,       stays = true  },   -- can't spare it: hearthstone, tools, fishing pole, kept weapons, its ammo
    wear       = { at = "now",     stays = false },   -- put on at once
    open       = { at = "now",     stays = false },   -- opened at once (617's question 25, 2026-10-28); what's inside is picked up after
    learn      = { at = "now",     stays = false },   -- learned at once (617's question 25)
    feed       = { at = nil,       stays = true  },   -- kept for its pet
    use        = { at = nil,       stays = true  },   -- kept to use when needed (owner, 2026-10-13)
    craft      = { at = nil,       stays = true  },   -- a reagent of a recipe it knows (the owner's pearl, 2026-10-30)
    give       = { at = "mailbox", stays = true  },   -- a clan-mate wants it
    disenchant = { at = "now",     stays = false },   -- bound, so no auction: dust for its enchanting
    auction    = { at = "auction", stays = true  },   -- unbound greens and better, trade goods, recipes it can't learn
    vendor     = { at = "vendor",  stays = true  },   -- everything else a vendor pays for
    junk       = { at = nil,       stays = true  },   -- nobody pays for it: the first thing full bags (623) let go
}
-- }}}

-- {{{ local helpers
local function knows_reagent(buddy, id)
    for _, reagents in pairs(buddy.recipes or {}) do
        if reagents[id] then return true end
    end
    return false
end

local function can_learn(buddy, r)
    if not r then return false end
    local rank = (buddy.professions or {})[r.skill]
    return rank ~= nil and rank >= (r.rank or 0) and not (buddy.recipes or {})[r.teaches]
end

local function mate_wanting(buddy, item)
    for _, mate in ipairs(buddy.clan or {}) do
        if mate.needs and mate.needs[item.id] then return mate.name end
    end
    return nil
end

local function tradable(item) return not item.bound and item.bonding ~= BIND_ON_PICKUP end

-- Quest items are judged as white items (the owner, 2026-11-05: "treat them
-- like "white" quality items"), and as trade goods when a profession uses
-- them ("then they should treat them like a trade good").
local function quality_of(item)
    if item.class == CLASS_QUEST then return QUALITY_WHITE end
    return item.quality or 0
end
local function trade_good(item)
    return item.class == CLASS_TRADE_GOODS or (item.class == CLASS_QUEST and item.material == true)
end

local function fires(item, buddy) return item.class == CLASS_PROJECTILE and buddy.ammo ~= nil and item.subclass == buddy.ammo end
-- }}}

-- {{{ the rules, tried in order; the first that matches is the plan
-- Order decided 2026-11-06 (617h2): what it can't spare, then what is done
-- at once, then its own uses (pet, itself, its crafts), then a clan-mate's,
-- then the ways of turning it into money, the best paying first. A quest
-- item no vendor pays for is not picked up at all (the owner, 2026-11-05:
-- "buddies shouldn't pick up quest items unless they have a sell price").
-- Ammo it fires is kept here; how many stacks it keeps is the ammo step's
-- (`trim_ammo` below), which sells the worst when better comes.
local RULES = {
    { plan = "leave",      why = "a quest item nobody pays for",   test = function(i)    return i.class == CLASS_QUEST and (i.sell_price or 0) == 0 end },
    { plan = "keep",       why = "the hearthstone",                test = function(i)    return i.id == HEARTHSTONE end },
    { plan = "keep",       why = "a profession tool",              test = function(i)    return i.tool end },
    { plan = "keep",       why = "a fishing pole",                 test = function(i)    return i.class == CLASS_WEAPON and i.subclass == SUBCLASS_FISHPOLE end },
    { plan = "wear",       why = "an upgrade",                     test = function(i)    return i.wear == "now" end },
    { plan = "keep",       why = "a weapon it keeps",              test = function(i)    return i.wear == "kept" end },
    { plan = "keep",       why = "ammo it fires",       ammo = true, test = function(i, b) return fires(i, b) end },
    { plan = "open",       why = "something to open",              test = function(i)    return i.openable end },
    { plan = "learn",      why = "a recipe it can learn",          test = function(i, b) return can_learn(b, i.recipe) end },
    { plan = "feed",       why = "food its pet eats",              test = function(i, b) return i.class == CLASS_CONSUMABLE and i.food_type and b.pet_diet and b.pet_diet[i.food_type] end },
    { plan = "use",        why = "it has a use",                   test = function(i)    return (i.class == CLASS_CONSUMABLE or i.use) and i.class ~= CLASS_RECIPE end },
    { plan = "craft",      why = "a reagent of a recipe it knows", test = function(i, b) return knows_reagent(b, i.id) end },
    { plan = "give",       why = "a clan-mate wants it",           test = function(i, b) return tradable(i) and mate_wanting(b, i) ~= nil end },
    { plan = "disenchant", why = "bound, and it enchants",         test = function(i, b) local e = (b.professions or {})[ENCHANTING]
                                                                                         return not tradable(i) and i.de_skill and e and e >= i.de_skill end },
    { plan = "auction",    why = "worth more at the auction house",test = function(i)    return tradable(i) and (quality_of(i) >= QUALITY_GREEN
                                                                                         or trade_good(i) or i.class == CLASS_RECIPE) end },
    { plan = "vendor",     why = "a vendor pays for it",           test = function(i)    return (i.sell_price or 0) > 0 end },
    { plan = "junk",       why = "nobody pays for it",             test = function()     return true end },
}
Plan.RULES = RULES
-- }}}

-- {{{ function Plan.decide
-- The plan for one item, for this buddy as it is now: plan name, the reason,
-- and for "give" the clan-mate's name. `surplus` true: the item is ammo the
-- ammo step found one stack too many, so the ammo rule is passed over and
-- the plan is what the item would be worth otherwise (sold, mostly).
function Plan.decide(item, buddy, surplus)
    for _, r in ipairs(RULES) do
        if not (surplus and r.ammo) and r.test(item, buddy) then
            return r.plan, r.why, r.plan == "give" and mate_wanting(buddy, item) or nil
        end
    end
end
-- }}}

-- {{{ function Plan.value
-- The copper an item is expected to bring, by its plan: the auction's
-- estimate (or a guess from the vendor price) for "auction", the vendor
-- price for "vendor", nothing for the rest. Whole stacks.
function Plan.value(item, plan)
    local n = item.count or 1
    if plan == "auction" then return (item.auction or (item.sell_price or 0) * AUCTION_GUESS) * n end
    if plan == "vendor"  then return (item.sell_price or 0) * n end
    return 0
end
-- }}}

-- {{{ function Plan.new
-- A buddy's plans: its facts, the items it holds with their plans (in the
-- order picked up), and its wants, each "saving" or "ready".
function Plan.new(buddy)
    if buddy.ammo ~= nil and type(buddy.ammo_stacks) ~= "number" then
        error("buddy-item-plan: a buddy that fires ammo (" .. tostring(buddy.ammo) .. ") needs ammo_stacks, how many stacks it keeps", 2)
    end
    buddy.recipes, buddy.professions = buddy.recipes or {}, buddy.professions or {}
    buddy.clan, buddy.wants, buddy.money = buddy.clan or {}, buddy.wants or {}, buddy.money or 0
    local wants = {}
    for _, w in ipairs(buddy.wants) do wants[#wants + 1] = { name = w.name, price = w.price, state = "saving" } end
    return { buddy = buddy, bag = {}, wants = wants }
end
-- }}}

-- {{{ local function expected
-- Money in the purse plus what every held item planned for sale should
-- bring. Items already on the auction house are out of mind (the owner,
-- 2026-11-05) and count for nothing until their money is in the purse.
local function expected(state)
    local sum = state.buddy.money
    for _, e in ipairs(state.bag) do sum = sum + Plan.value(e.item, e.plan) end
    return sum
end
-- }}}

-- {{{ local function settle_wants
-- A want is "ready" once the money and the sales already planned cover it,
-- cheapest want first (each one counted against what is left). Returns
-- the wants that changed.
local function settle_wants(state)
    local changes, left = {}, expected(state)
    local order = {}
    for i, w in ipairs(state.wants) do order[i] = w end
    table.sort(order, function(a, b)
        if a.price ~= b.price then return a.price < b.price end
        return a.name < b.name
    end)
    for _, w in ipairs(order) do
        local now = (left >= w.price) and "ready" or "saving"
        if now == "ready" then left = left - w.price end
        if now ~= w.state then changes[#changes + 1] = { want = w, from = w.state, to = now }; w.state = now end
    end
    return changes
end
-- }}}

-- {{{ local function apply_now
-- What a plan settled at once does to the buddy: a recipe learned joins
-- what it knows. (Wearing, opening and disenchanting change nothing this
-- module reads: what comes out of them is picked up as new items.)
local function apply_now(state, item, plan)
    if plan == "learn" then state.buddy.recipes[item.recipe.teaches] = item.recipe.reagents or {} end
end
-- }}}

-- {{{ local function replan
-- Works the held plans out again (after a recipe is learned). Which of them
-- came out differently is told by `changed`, after the ammo step has had
-- its say too.
local function replan(state)
    for _, e in ipairs(state.bag) do
        e.plan, e.why, e.to = Plan.decide(e.item, state.buddy)
    end
end
-- }}}

-- {{{ local function trim_ammo
-- The ammo it fires, kept: the best `ammo_stacks` stacks (the owner,
-- 2026-11-05: "always keep it full of the best ammo we can get our hands
-- on. If we can get better ammo, we can sell the lowest quality one to
-- replace it"; others "just need one stack"). Best is the most damage per
-- second, then the fuller stack, then the one held longest. Every stack
-- past them is planned as what it is worth otherwise (sold, mostly). A
-- spare stack still in the bags is ranked again each time, so a bigger
-- ammo bag (a larger `ammo_stacks`) keeps it at the next pickup.
local function trim_ammo(state)
    local b = state.buddy
    if b.ammo == nil then return end
    local mine = {}
    for n, e in ipairs(state.bag) do
        if fires(e.item, b) and (e.plan == "keep" or e.surplus) then
            if type(e.item.ammo_dps) ~= "number" then
                error("buddy-item-plan: ammo " .. tostring(e.item.id) .. " has no ammo_dps, so which ammo is best can't be told", 3)
            end
            mine[#mine + 1] = { e = e, n = n }
        end
    end
    table.sort(mine, function(x, y)
        if x.e.item.ammo_dps ~= y.e.item.ammo_dps then return x.e.item.ammo_dps > y.e.item.ammo_dps end
        local cx, cy = x.e.item.count or 1, y.e.item.count or 1
        if cx ~= cy then return cx > cy end
        return x.n < y.n
    end)
    for k, x in ipairs(mine) do
        local e = x.e
        if k <= b.ammo_stacks then
            e.surplus = nil
            e.plan, e.why, e.to = Plan.decide(e.item, b)
        else
            e.surplus = true
            e.plan, e.why, e.to = Plan.decide(e.item, b, true)
        end
    end
end
-- }}}

-- {{{ local function changed
-- The held plans that differ from `before` ({ [entry] = plan }), each
-- { entry, from, to }: the owner's "only update this plan if ...", told.
local function changed(state, before)
    local changes = {}
    for _, e in ipairs(state.bag) do
        local was = before[e]
        if was ~= nil and was ~= e.plan then changes[#changes + 1] = { entry = e, from = was, to = e.plan } end
    end
    return changes
end
-- }}}

-- {{{ function Plan.pickup
-- A buddy picked `item` up: its plan, decided now. A plan settled at once
-- is done here (the caller does the deed in the game and is told so by
-- `now`); a plan that keeps the item adds it to the bag; "leave" (a quest
-- item nobody pays for) is not taken at all, and the caller leaves it
-- where it lies. Then, only when the new item changed something a held plan
-- reads, the held plans are worked out again: a recipe learned (its
-- reagents), or better ammo (the worst stack is sold). The wants are
-- checked against the purse and the sales planned. Returns entry, changes
-- (held plans), wants (wants that changed), now (true when the plan is
-- settled at once).
function Plan.pickup(state, item)
    local before = {}
    for _, e in ipairs(state.bag) do before[e] = e.plan end
    local plan, why, to = Plan.decide(item, state.buddy)
    local entry = { item = item, plan = plan, why = why, to = to }
    local now   = Plan.PLANS[plan].at == "now"
    if now then
        apply_now(state, item, plan)
        if plan == "learn" then replan(state) end
    elseif plan ~= "leave" then
        state.bag[#state.bag + 1] = entry
    end
    trim_ammo(state)
    return entry, changed(state, before), settle_wants(state), now
end
-- }}}

-- {{{ function Plan.login
-- A buddy logged in: every held item's plan is worked out again from the
-- buddy's facts (its plans aren't kept across a restart; the bags are).
-- `items` is what its bags hold, in any order. Returns the new state; plans
-- settled at once (an item it can now learn or open) are done first, as at
-- pickup, and listed in the second result.
function Plan.login(buddy, items)
    local state, done = Plan.new(buddy), {}
    for _, item in ipairs(items) do
        local entry, _, _, now = Plan.pickup(state, item)
        if now then done[#done + 1] = entry end
    end
    return state, done
end
-- }}}

-- {{{ function Plan.settle
-- The buddy is at `place` ("vendor", "auction" or "mailbox"): every held
-- item planned for it is settled there and leaves the bag. A vendor pays at
-- once, so its money goes into the purse. An item put up at the auction
-- house is out of mind (the owner, 2026-11-05: "We should count them as
-- "sold", as in, we're not actively thinking about them"): no money yet;
-- what it fetches comes by mail, and an item nobody bought comes back by
-- mail and is planned again there (`Plan.mailbox`). At the auction house the
-- wants are then bought in their list's order, each one the purse covers
-- (the owner: "How could we buy something with money we don't have?").
-- Returns the deeds, each { act, entry } or { act = "buy", want }.
function Plan.settle(state, place)
    local deeds, kept = {}, {}
    for _, e in ipairs(state.bag) do
        if Plan.PLANS[e.plan].at == place then
            deeds[#deeds + 1] = { act = e.plan, entry = e }
            if place == "vendor" then state.buddy.money = state.buddy.money + Plan.value(e.item, e.plan) end
        else
            kept[#kept + 1] = e
        end
    end
    state.bag = kept
    if place == "auction" then
        local still = {}
        for _, w in ipairs(state.wants) do
            if state.buddy.money >= w.price then
                state.buddy.money = state.buddy.money - w.price
                deeds[#deeds + 1] = { act = "buy", want = w }
            else
                still[#still + 1] = w
            end
        end
        state.wants = still
    end
    settle_wants(state)
    return deeds
end
-- }}}

-- {{{ the mailbox
-- Which mail a buddy takes, by what the town around the mailbox has (the
-- owner, 2026-11-05, word for word in 617h2): money always, even from a
-- letter whose items it leaves; each item by the plan it would get, as if
-- picked up. An item to auction is taken where there is an auction house,
-- one to sell where there is a vendor (so at a mailbox with no vendor near,
-- as in the death knights' starting land, none of them); a profession item
-- (a reagent of a recipe it knows, a recipe it can learn, a bound item to
-- disenchant) only when its to-do list holds a profession errand (617e4's
-- list, made on entering a town and wiped on leaving it). What it keeps,
-- wears, opens, uses, feeds its pet or gives on is always taken; what
-- nobody pays for is left. What is taken is picked up like any item.
Plan.MAIL_TAKES = {
    leave = false, junk = false,
    vendor = "vendor", auction = "auction",
    craft = "crafting", learn = "crafting", disenchant = "crafting",
    keep = true, wear = true, open = true, use = true, feed = true, give = true,
}

-- {{{ function Plan.mailbox
-- `letters`: list of { money = copper, items = { item, ... } }. `town`:
-- { vendor = bool, auction = bool, crafting = bool (a profession errand is
-- on its to-do list) }. Returns money (copper taken), taken (the entries
-- picked up, in order), left (list of { item, plan }: stays in the mail).
function Plan.mailbox(state, letters, town)
    local money, taken, left = 0, {}, {}
    for _, letter in ipairs(letters) do
        money = money + (letter.money or 0)
    end
    state.buddy.money = state.buddy.money + money
    for _, letter in ipairs(letters) do
        for _, item in ipairs(letter.items or {}) do
            local plan  = Plan.decide(item, state.buddy)
            local takes = Plan.MAIL_TAKES[plan]
            if takes == true or (type(takes) == "string" and town[takes] == true) then
                taken[#taken + 1] = (Plan.pickup(state, item))
            else
                left[#left + 1] = { item = item, plan = plan }
            end
        end
    end
    settle_wants(state)
    return money, taken, left
end
-- }}}
-- }}}

-- {{{ function Plan.drop_want
-- Prunes a want from the list (the owner, 2026-11-05: "So long as we can
-- prune the list when needed"). Returns how many wants of that name went.
function Plan.drop_want(state, name)
    local still, gone = {}, 0
    for _, w in ipairs(state.wants) do
        if w.name == name then gone = gone + 1 else still[#still + 1] = w end
    end
    state.wants = still
    settle_wants(state)
    return gone
end
-- }}}

return Plan
