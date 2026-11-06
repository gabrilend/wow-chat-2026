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
--   money        copper on hand
--   wants        list of { name, price }              what it is saving for
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
--   stack        how many make a full stack (item_template's stackable; default 1)
--   need_won     true for an item won with a need roll (617j4: always gets room)
--------------------------------------------------------------------------------

local Plan = {}

-- {{{ numbers from the game
local HEARTHSTONE        = 6948
local ENCHANTING         = 333          -- the skill line's id
local CLASS_CONSUMABLE   = 0
local CLASS_WEAPON       = 2
local CLASS_TRADE_GOODS  = 7
local CLASS_RECIPE       = 9
local CLASS_QUEST        = 12
local SUBCLASS_FISHPOLE  = 20           -- of weapons
local BIND_ON_PICKUP     = 1
local QUALITY_GREEN      = 2
local QUALITY_WHITE      = 1
local AUCTION_GUESS      = 3            -- x vendor price, when the caller gives no auction estimate
-- }}}

-- {{{ the plans
-- Each plan: where it is settled ("now" at pickup, a place, or nil: it waits
-- to be used and nothing here settles it), and whether the buddy keeps the
-- item in its bags until then. Configuration in structure: the order the
-- rules are tried in is RULES below; what each plan means is here.
Plan.PLANS = {
    keep       = { at = nil,       stays = true  },   -- can't spare it: hearthstone, tools, fishing pole, kept weapons
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
-- }}}

-- {{{ the rules, tried in order; the first that matches is the plan
-- Order decided 2026-11-06 (617h2): what it can't spare, then what is done
-- at once, then its own uses (pet, itself, its crafts), then a clan-mate's,
-- then the ways of turning it into money, the best paying first.
local RULES = {
    { plan = "keep",       why = "the hearthstone",                test = function(i)    return i.id == HEARTHSTONE end },
    { plan = "keep",       why = "a profession tool",              test = function(i)    return i.tool end },
    { plan = "keep",       why = "a fishing pole",                 test = function(i)    return i.class == CLASS_WEAPON and i.subclass == SUBCLASS_FISHPOLE end },
    { plan = "wear",       why = "an upgrade",                     test = function(i)    return i.wear == "now" end },
    { plan = "keep",       why = "a weapon it keeps",              test = function(i)    return i.wear == "kept" end },
    { plan = "open",       why = "something to open",              test = function(i)    return i.openable end },
    { plan = "learn",      why = "a recipe it can learn",          test = function(i, b) return can_learn(b, i.recipe) end },
    { plan = "feed",       why = "food its pet eats",              test = function(i, b) return i.class == CLASS_CONSUMABLE and i.food_type and b.pet_diet and b.pet_diet[i.food_type] end },
    { plan = "use",        why = "it has a use",                   test = function(i)    return (i.class == CLASS_CONSUMABLE or i.use) and i.class ~= CLASS_RECIPE end },
    { plan = "craft",      why = "a reagent of a recipe it knows", test = function(i, b) return knows_reagent(b, i.id) end },
    { plan = "give",       why = "a clan-mate wants it",           test = function(i, b) return tradable(i) and mate_wanting(b, i) ~= nil end },
    { plan = "disenchant", why = "bound, and it enchants",         test = function(i, b) local e = (b.professions or {})[ENCHANTING]
                                                                                         return not tradable(i) and i.de_skill and e and e >= i.de_skill end },
    { plan = "auction",    why = "worth more at the auction house",test = function(i)    return tradable(i) and ((i.quality or 0) >= QUALITY_GREEN
                                                                                         or i.class == CLASS_TRADE_GOODS or i.class == CLASS_RECIPE) end },
    { plan = "vendor",     why = "a vendor pays for it",           test = function(i)    return (i.sell_price or 0) > 0 end },
    { plan = "junk",       why = "nobody pays for it",             test = function()     return true end },
}
Plan.RULES = RULES
-- }}}

-- {{{ function Plan.decide
-- The plan for one item, for this buddy as it is now: plan name, the reason,
-- and for "give" the clan-mate's name.
function Plan.decide(item, buddy)
    for _, r in ipairs(RULES) do
        if r.test(item, buddy) then
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
    buddy.recipes, buddy.professions = buddy.recipes or {}, buddy.professions or {}
    buddy.clan, buddy.wants, buddy.money = buddy.clan or {}, buddy.wants or {}, buddy.money or 0
    local wants = {}
    for _, w in ipairs(buddy.wants) do wants[#wants + 1] = { name = w.name, price = w.price, state = "saving" } end
    return { buddy = buddy, bag = {}, wants = wants }
end
-- }}}

-- {{{ local function expected
-- Money on hand plus what every held item planned for sale should bring.
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
-- Works the held plans out again and changes only those that come out
-- differently (the owner's "only update this plan if ..."). Returns the
-- changes, each { entry, from, to }.
local function replan(state)
    local changes = {}
    for _, e in ipairs(state.bag) do
        local plan, why, to = Plan.decide(e.item, state.buddy)
        if plan ~= e.plan then
            changes[#changes + 1] = { entry = e, from = e.plan, to = plan }
            e.plan, e.why, e.to = plan, why, to
        end
    end
    return changes
end
-- }}}

-- {{{ function Plan.pickup
-- A buddy picked `item` up: its plan, decided now. A plan settled at once
-- is done here (the caller does the deed in the game and is told so by
-- `now`); a plan that keeps the item adds it to the bag. Then, only when
-- the new item changed something a held plan reads (a recipe learned), the
-- held plans are worked out again; the wants are checked against the money
-- the sales will bring. Returns entry, changes (held plans), wants (wants
-- that changed), now (true when the plan is settled at once).
function Plan.pickup(state, item)
    local plan, why, to = Plan.decide(item, state.buddy)
    local entry = { item = item, plan = plan, why = why, to = to }
    local now   = Plan.PLANS[plan].at == "now"
    local changes = {}
    if now then
        apply_now(state, item, plan)
        if plan == "learn" then changes = replan(state) end
    else
        state.bag[#state.bag + 1] = entry
    end
    return entry, changes, settle_wants(state), now
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
-- item planned for it is settled there and leaves the bag, and at the
-- auction house a ready want is bought. Sales are counted into its money
-- (the auction's estimate stands in for a sale that hasn't happened yet).
-- Returns the deeds, each { act, entry } or { act = "buy", want }.
function Plan.settle(state, place)
    local deeds, kept = {}, {}
    for _, e in ipairs(state.bag) do
        if Plan.PLANS[e.plan].at == place then
            deeds[#deeds + 1] = { act = e.plan, entry = e }
            state.buddy.money = state.buddy.money + Plan.value(e.item, e.plan)
        else
            kept[#kept + 1] = e
        end
    end
    state.bag = kept
    if place == "auction" then
        local still = {}
        for _, w in ipairs(state.wants) do
            if w.state == "ready" and state.buddy.money >= w.price then
                state.buddy.money = state.buddy.money - w.price
                deeds[#deeds + 1] = { act = "buy", want = w }
            else
                still[#still + 1] = w
            end
        end
        state.wants = still
    end
    return deeds
end
-- }}}

-- {{{ making room (617j4)
-- When a buddy must take an item and has no free slot, it destroys the
-- least worth item it carries. The owner's order (617j4), first to go to
-- last: grey junk; then common trade goods and food it has plenty of; then
-- anything else. Never: what it can't spare (a "keep" plan), a gear
-- upgrade, a need-won item, a quest item. Within a tier, part-stacks go
-- before full stacks (owner, 2026-10-28: "One or two of a thing is less
-- valuable than 20."), then the cheapest (vendor price times the stack).
-- In the last tier the plans go in this order (decided 2026-11-06): what
-- would only be sold first, what is kept for a use last.
Plan.ROOM_PLAN_ORDER = { junk = 1, vendor = 2, auction = 3, give = 4, feed = 5, craft = 6, use = 7 }

-- {{{ local function full_stack
local function full_stack(item) return (item.count or 1) >= (item.stack or 1) end
-- }}}

-- {{{ local function holds_full
-- Whether the bag holds a full stack of item `id` ("plenty", decided
-- 2026-11-06). Only part-stacks are judged by it, so the one judged never
-- counts itself.
local function holds_full(state, id)
    for _, e in ipairs(state.bag) do
        if e.item.id == id and full_stack(e.item) then return true end
    end
    return false
end
-- }}}

-- {{{ local function room_key
-- An entry's place in the order, as { tier, plan rank, part (0) or full
-- (1), worth }, or nil when it may never go. (A gear upgrade is never in
-- the bag: it is worn at once.)
local function room_key(state, e)
    local i = e.item
    if e.plan == "keep" or i.need_won or i.class == CLASS_QUEST then return nil end
    local q, plain = i.quality or 0, i.class == CLASS_TRADE_GOODS or (i.class == CLASS_CONSUMABLE and i.food_type ~= nil)
    local tier = 3
    if q == 0 then
        tier = 1
    elseif q <= QUALITY_WHITE and plain and not full_stack(i) and holds_full(state, i.id) then
        tier = 2
    end
    return { tier, tier == 3 and (Plan.ROOM_PLAN_ORDER[e.plan] or 0) or 0,
             full_stack(i) and 1 or 0, (i.sell_price or 0) * (i.count or 1) }
end
-- }}}

-- {{{ local function before
local function before(a, b)
    for k = 1, 4 do if a[k] ~= b[k] then return a[k] < b[k] end end
    return false
end
-- }}}

-- {{{ function Plan.room_order
-- The held items that may go, least worth first: a list of entries. Ties
-- keep the bag's order (the one picked up first goes first).
function Plan.room_order(state)
    local list = {}
    for n, e in ipairs(state.bag) do
        local key = room_key(state, e)
        if key then list[#list + 1] = { e = e, key = key, n = n } end
    end
    table.sort(list, function(a, b)
        if before(a.key, b.key) then return true end
        if before(b.key, a.key) then return false end
        return a.n < b.n
    end)
    local out = {}
    for k, x in ipairs(list) do out[k] = x.e end
    return out
end
-- }}}

-- {{{ function Plan.make_room
-- The buddy must take `item` and has no free slot (the caller knows its
-- slots, and that the item stacks onto nothing). Returns the entry it
-- destroys (already gone from the bag), or nil and why: nothing may go, or
-- the new item is worth less than everything that may (it is left where it
-- is). An item settled at once (a gear upgrade worn, a clam opened, a
-- recipe learned, an item disenchanted) and one that may never go (a
-- need-won item, what it can't spare) always get room when anything may.
function Plan.make_room(state, item)
    local order = Plan.room_order(state)
    if #order == 0 then return nil, "nothing it carries may go" end
    local plan = Plan.decide(item, state.buddy)
    if Plan.PLANS[plan].at ~= "now" then
        local key = room_key(state, { item = item, plan = plan })   -- nil: it may never go, so it gets room
        if key and not before(room_key(state, order[1]), key) then
            return nil, "worth no more than anything it carries"
        end
    end
    local gone = order[1]
    for n, e in ipairs(state.bag) do
        if e == gone then table.remove(state.bag, n); break end
    end
    return gone
end
-- }}}
-- }}}

return Plan
