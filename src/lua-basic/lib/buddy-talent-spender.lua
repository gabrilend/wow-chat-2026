--------------------------------------------------------------------------------
-- buddy-talent-spender.lua (issue 617g)
--
-- Decides which talents a buddy learns, point by point, inside its fixed
-- talent shape (e.g. two-thirds Holy, one-third Protection), and draws a
-- new buddy's shape. Pure decisions: it touches no server object, so the
-- server script (buddy-talents.lua) and the offline test
-- (scripts/test-buddy-talents) run the very same code.
--
-- The rules, all owner decisions of 2026-09-25/26 recorded in 617g:
--   - a two-thirds / one-third shape: 2:1 odds for the main tree, until
--     the main tree reaches its bottom row or the side tree its mark (the
--     owner, 2026-10-03; two_tree_choice); a third-in-each shape: even
--     odds among the trees short of a third of the level-cap points
--     (thirds_choice); otherwise, and after that,
--     each point goes to the tree furthest below its share of the points
--     spent so far;
--   - inside a tree, a legal one-point talent is taken first, always;
--   - then a talent that already has a point is finished before another
--     is started (only a share running out leaves one partial);
--   - then a talent on a one-pointer's prerequisite chain is started;
--   - then, when the deepest row the tree has opened holds no points, a
--     talent from that row is started; otherwise any legal talent, at
--     random;
--   - legal = basic's cap allows it (data's `allowed`, the 155g rule), its
--     row is open (5 points per row in that tree), its prerequisite holds
--     enough points. The same checks Player::LearnTalent makes;
--   - when every tree with a share is full (an all-in-one-tree shape in a
--     tree smaller than the character's points), the rest goes to a tree
--     without a share: the one already holding such points, else a random
--     one;
--   - a new buddy's shape is drawn from the class's shapes its same-class
--     clan-mates don't hold, limited to a needed role when the caller asks
--     for one and the class has a free shape of that role.
--
-- Loaded with dofile by buddy-talents.lua; ALE's own scan of the scripts
-- directory also runs it once, which only builds and returns this table.
--------------------------------------------------------------------------------

local Spender = {}

-- {{{ local function index_class
-- Built once per class and cached on it: talent by id, the tree (1-3) each
-- talent is in, and which talents sit on a one-point talent's
-- prerequisite chain (those are started as early as the one-pointers).
local function index_class(cls)
    if cls._index then return cls._index end
    local ix = { by_id = {}, tree_of = {}, opens_one_pointer = {} }
    for t, tree in ipairs(cls.trees) do
        for _, tal in ipairs(tree.talents) do
            ix.by_id[tal.id]   = tal
            ix.tree_of[tal.id] = t
        end
    end
    for _, tal in pairs(ix.by_id) do
        if tal.allowed and tal.ranks == 1 then
            local dep = tal.dep
            while dep ~= 0 do
                ix.opens_one_pointer[dep] = true
                dep = ix.by_id[dep].dep
            end
        end
    end
    cls._index = ix
    return ix
end
-- }}}

-- {{{ function Spender.read_held
-- The points a character holds in each talent, from a "does it have this
-- spell" question (the server's HasTalent). A talent's rank k is held when
-- its rank-k spell is; the highest rank found is the count.
-- Returns held: talent id -> points (only talents with points appear).
function Spender.read_held(cls, has_spell)
    local held = {}
    for _, tree in ipairs(cls.trees) do
        for _, tal in ipairs(tree.talents) do
            for k = tal.ranks, 1, -1 do
                if has_spell(tal.spells[k]) then held[tal.id] = k; break end
            end
        end
    end
    return held
end
-- }}}

-- {{{ local function spent_per_tree
local function spent_per_tree(cls, held)
    local ix, spent = index_class(cls), { 0, 0, 0 }
    for id, pts in pairs(held) do
        local t = ix.tree_of[id]
        if t then spent[t] = spent[t] + pts end
    end
    return spent
end
-- }}}

-- {{{ local function legal
-- Could one more point go into this talent right now?
local function legal(cls, tal, held, spent_in_tree)
    local h = held[tal.id] or 0
    if not tal.allowed or h >= tal.ranks then return false end
    if spent_in_tree < tal.row * 5 then return false end        -- row locked
    if tal.dep ~= 0 and (held[tal.dep] or 0) < tal.dep_points then return false end
    return true
end
-- }}}

-- {{{ local function pick_in_tree
-- The talent the next point in tree t goes to, or nil if the tree has no
-- legal talent left. Order:
--   1. a legal one-point talent (random if several): the owner's "the main
--      abilities, the ones that require a single talent point, they should
--      always be chosen". It even comes before finishing a started talent:
--      the first test run (2026-09-26) found about 1 main tree in 20 ending
--      level 60 without its capstone, because the capstone row opened while
--      a 5-rank talent was half done and the tree's share ran out finishing
--      it. A one-pointer is done in one point, so a tree still never holds
--      two unfinished talents.
--   2. the tree's unfinished talent (finish what's started);
--   3. a random starter on a one-pointer's prerequisite chain (the owner's
--      first rule: "if they have pre-requisites, those prerequisites should
--      also always be chosen as well"). It comes before 4: with 4 first,
--      the test found warlock main trees reaching their capstone in only
--      836 of 900 runs, the prerequisite losing out to new-row picks;
--   4. a random talent from a newly opened row: when the deepest row the
--      tree has opened holds no points yet, a legal talent drawn at random
--      from that row (any column, not the leftmost). Owner,
--      2026-09-26: "whenever we unlock a new row, ignoring the 1 point
--      talents, we (after 1 point talents), prioritize that row for one
--      complete talent pick? Then it's random again." Measured before it
--      was adopted (200 runs per class and two-thirds shape): the main
--      tree's deepest row at level 20 went from 0.59 to 0.80 on average,
--      at 50 from 4.27 to 4.67, elsewhere unchanged (the 5-points-per-row
--      rule already forces most of the depth);
--   5. a random legal talent.
local function pick_in_tree(cls, t, held, spent, rand)
    local ix                        = index_class(cls)
    local one_point, chain, open    = {}, {}, {}
    local newest_row, newest_taken  = {}, false
    local deepest                   = math.floor(spent[t] / 5)    -- deepest row the tree has opened
    local started
    for _, tal in ipairs(cls.trees[t].talents) do
        if tal.row == deepest and (held[tal.id] or 0) > 0 then newest_taken = true end
        if legal(cls, tal, held, spent[t]) then
            if tal.ranks == 1 then
                one_point[#one_point + 1] = tal
            elseif (held[tal.id] or 0) > 0 then
                started = started or tal
            else
                open[#open + 1] = tal
                if ix.opens_one_pointer[tal.id] then chain[#chain + 1] = tal end
                if tal.row == deepest          then newest_row[#newest_row + 1] = tal end
            end
        end
    end
    if #one_point  > 0 then return one_point[rand(#one_point)] end
    if started         then return started                     end
    if #chain      > 0 then return chain[rand(#chain)]         end
    if not newest_taken and #newest_row > 0 then return newest_row[rand(#newest_row)] end
    if #open       > 0 then return open[rand(#open)]           end
    return nil
end
-- }}}

-- {{{ local function has_room
local function has_room(cls, t, held, spent)
    for _, tal in ipairs(cls.trees[t].talents) do
        if legal(cls, tal, held, spent[t]) then return true end
    end
    return false
end
-- }}}

-- {{{ local function choose_tree
-- Which tree the next point goes to, or nil if none can take it.
-- Shared trees: the one furthest below its share of the points spent in
-- the shared trees (ties: the bigger share, then the leftmost tree).
-- No shared tree has room: the overflow tree (a tree without a share),
-- the one already holding overflow points, else a random one with room.
local function choose_tree(cls, thirds, held, spent, rand)
    local shared_total = 0
    for t = 1, 3 do if thirds[t] > 0 then shared_total = shared_total + spent[t] end end

    local best, best_deficit
    for t = 1, 3 do
        if thirds[t] > 0 and has_room(cls, t, held, spent) then
            local deficit = thirds[t] * (shared_total + 1) / 3 - spent[t]
            if not best or deficit > best_deficit
               or (deficit == best_deficit and thirds[t] > thirds[best]) then
                best, best_deficit = t, deficit
            end
        end
    end
    if best then return best end

    local fresh = {}
    for t = 1, 3 do
        if thirds[t] == 0 and has_room(cls, t, held, spent) then
            if spent[t] > 0 then return t end                        -- keep overflow together
            fresh[#fresh + 1] = t
        end
    end
    if #fresh > 0 then return fresh[rand(#fresh)] end
    return nil
end
-- }}}

-- {{{ local function two_tree_choice
-- A two-thirds / one-third shape (the owner, 2026-10-03, replacing the
-- even split of 2026-09-26 at its start): "2:1 odds to put them in the
-- main tree vs off tree, until either the main tree has reached the
-- bottom tier, or the side talent tree has reached the number that it
-- would be if the main tree has gotten to that point". So, each point:
--   - while neither has happened: the main tree two times in three, the
--     side tree one in three, at random;
--   - the side tree at its mark (half the points the main tree needs to
--     put one in its bottom row: the side tree's count at that moment, by
--     the 2:1 split) and the main tree not yet at its bottom row: the main
--     tree, until it is;
--   - the main tree at its bottom row (a point in the deepest row basic's
--     cap allows it), the side tree short of its mark: the side tree, up
--     to the mark;
--   - both done: the even split again (choose_tree's deficit rule).
-- A tree with no legal talent left gives its turn to the other.
-- Returns the tree, or nil when this shape isn't two-thirds / one-third
-- (the caller then uses choose_tree).
local function bottom_row(cls, t)
    local deepest = 0
    for _, tal in ipairs(cls.trees[t].talents) do
        if tal.allowed and tal.row > deepest then deepest = tal.row end
    end
    return deepest
end

local function two_tree_choice(cls, thirds, held, spent, rand)
    local main, side
    for t = 1, 3 do
        if thirds[t] == 2 then main = t elseif thirds[t] == 1 then side = t end
    end
    if not main or not side then return nil end
    local row = bottom_row(cls, main)
    local at_bottom = false
    for _, tal in ipairs(cls.trees[main].talents) do
        if tal.row == row and (held[tal.id] or 0) > 0 then at_bottom = true end
    end
    local side_mark = math.floor((row * 5 + 1) / 2)
    local side_done = spent[side] >= side_mark
    local main_room = has_room(cls, main, held, spent)
    local side_room = has_room(cls, side, held, spent)
    if at_bottom and side_done then return nil end              -- both done: the even split
    local want
    if not at_bottom and not side_done then
        want = (rand(3) <= 2) and main or side
    elseif side_done then
        want = main
    else
        want = side
    end
    if want == main and not main_room then want = side_room and side or nil end
    if want == side and not side_room then want = main_room and main or nil end
    return want
end
-- }}}

-- {{{ local function thirds_choice
-- A third-in-each shape, by the same principle (the owner, 2026-10-03:
-- "We should change the 1/3rd in each to follow the same principles,
-- except 1/3rd in each tree until we reach the goal for that tree"): each
-- point to one of the trees still short of its goal, at even odds; a
-- tree's goal is a third of the points a character has at basic's level
-- cap (EACH_GOAL: 51 / 3 = 17, two points into the fourth row). All three
-- at their goal, or no tree short of it with room: the even split
-- (choose_tree). Returns nil for any other shape.
local MAX_POINTS = 51                  -- talent points at level 60, basic's cap (one a level from 10)
local EACH_GOAL  = math.floor(MAX_POINTS / 3)

local function thirds_choice(cls, thirds, held, spent, rand)
    if not (thirds[1] == 1 and thirds[2] == 1 and thirds[3] == 1) then return nil end
    local short = {}
    for t = 1, 3 do
        if spent[t] < EACH_GOAL and has_room(cls, t, held, spent) then short[#short + 1] = t end
    end
    if #short == 0 then return nil end
    return short[rand(#short)]
end
-- }}}

-- {{{ function Spender.plan
-- The talents to learn, in order, for `free` points.
--   cls      the class's entry in buddy-talent-data.lua
--   shape_id 1..#cls.shapes
--   held     talent id -> points already held (read_held); not modified
--   free     free talent points (integer >= 0)
--   rand     function(n) -> integer in 1..n
-- Returns steps, unspent:
--   steps   = { { id, rank (0-based, as Player::LearnTalent takes it),
--                 tree (1-3), name }, ... } one step per point
--   unspent = points no legal talent could take (0 normally; the caller
--             logs anything else, it is never silently dropped)
function Spender.plan(cls, shape_id, held, free, rand)
    local shape = cls.shapes[shape_id]
    if not shape then error("buddy-talent-spender: " .. cls.name .. " has no shape " .. tostring(shape_id)) end

    local h = {}
    for id, pts in pairs(held) do h[id] = pts end
    local spent = spent_per_tree(cls, h)
    local steps = {}

    for _ = 1, free do
        local t = two_tree_choice(cls, shape.thirds, h, spent, rand) or thirds_choice(cls, shape.thirds, h, spent, rand)
            or choose_tree(cls, shape.thirds, h, spent, rand)
        if not t then break end
        local tal = pick_in_tree(cls, t, h, spent, rand)
        h[tal.id] = (h[tal.id] or 0) + 1
        spent[t]  = spent[t] + 1
        steps[#steps + 1] = { id = tal.id, rank = h[tal.id] - 1, tree = t, name = tal.name }
    end
    return steps, free - #steps
end
-- }}}

-- {{{ function Spender.draw_shape
-- A new buddy's shape.
--   taken     shape id -> true for shapes its same-class clan-mates hold
--   need_role "tank", "healer", or nil (the caller asks only at the
--             level-50 and level-60 slots, while the clan lacks the role)
-- Returns shape_id, filled (true when need_role was asked and met), or
-- nil, message when every shape is taken (impossible with seven buddies
-- and ten shapes; reported, never papered over).
function Spender.draw_shape(cls, taken, need_role, rand)
    local free, fitting = {}, {}
    for id, shape in ipairs(cls.shapes) do
        if not taken[id] then
            free[#free + 1] = id
            if need_role and shape.role == need_role then fitting[#fitting + 1] = id end
        end
    end
    if #fitting > 0 then return fitting[rand(#fitting)], true end
    if #free    > 0 then return free[rand(#free)], false      end
    return nil, cls.name .. ": every talent shape is already held by a clan-mate of this class"
end
-- }}}

-- {{{ function Spender.can_fill
-- Whether some shape of this class plays the role ("tank"/"healer").
function Spender.can_fill(cls, role)
    for _, shape in ipairs(cls.shapes) do
        if shape.role == role then return true end
    end
    return false
end
-- }}}

return Spender
