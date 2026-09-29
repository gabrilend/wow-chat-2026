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
--   - each point goes to the tree furthest below its share of the points
--     spent so far, so the shape's split holds at every level;
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
        local t = choose_tree(cls, shape.thirds, h, spent, rand)
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
