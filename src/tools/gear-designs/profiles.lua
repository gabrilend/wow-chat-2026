-- profiles.lua - gear designs, generated from open questions and
-- steered by the developer's votes (issue 506a)
--
-- For a general audience: a gear set's design is a list of open questions
-- (assets/gear-designs/design-questions.lua), with the subject who wears
-- it named there too. This library makes
-- "profiles": one gear piece each, with an answer to every question that
-- applies, and reads the developer's up and down votes on earlier profiles
-- to decide what to try next. The owner's rules:
--   "Higher priority given to various designs of questions that haven't
--    been answered yet"       -> each profile explores one or two questions,
--                                 drawn mostly from the unanswered ones;
--   "and variability when persistence is downvoted"
--                              -> the rest of its answers carry the option
--                                 that is winning (persistence), but the
--                                 more carried designs get voted down, the
--                                 more often a random option is tried.
-- Pure: no files are read or written here (the scripts do that).

local P = {}

-- {{{ tuning
-- Every number the owner might turn, in one place (docs/balance-updates.md
-- when changed).
P.ANSWERED_NET      = 3     -- net votes the leading option needs ...
P.ANSWERED_MARGIN   = 2     -- ... and its lead over the next, for "answered"
P.WEIGHT_OPEN       = 1.0   -- how likely an unanswered question is explored
P.WEIGHT_ANSWERED   = 0.15  -- ... and an answered one (never 0: answers can be revisited)
P.TWO_FOCUS_CHANCE  = 0.5   -- a profile explores two questions this often, else one
P.KEEP_BASE         = 0.85  -- chance a non-focus answer carries the leading option ...
P.KEEP_PER_DOWN     = 0.10  -- ... less this for each downvote on profiles that carried it
P.KEEP_FLOOR        = 0.20  -- ... never below this
P.SHIELD_WEIGHT     = 0.3   -- the shield is an off-piece for a Retribution Paladin
-- }}}

-- {{{ P.rng
-- A seeded random source (the same seed makes the same round again):
-- s = (s * 1103515245 + 12345) mod 2^31, returned as 0 <= r < 1.
function P.rng(seed)
    local s = seed % 2147483648
    return function()
        s = (s * 1103515245 + 12345) % 2147483648
        return s / 2147483648
    end
end
-- }}}

-- {{{ local function pick_weighted
-- One item of `items` by `weight(item)`; nil when every weight is 0.
local function pick_weighted(items, weight, r)
    local total = 0
    for _, it in ipairs(items) do total = total + weight(it) end
    if total <= 0 then return nil end
    local x = r() * total
    for _, it in ipairs(items) do
        x = x - weight(it)
        if x < 0 then return it end
    end
    return items[#items]
end
-- }}}

-- {{{ local function applies
-- Whether a question applies to a piece.
local function applies(q, piece)
    if q.pieces == "all" then return true end
    for _, p in ipairs(q.pieces) do if p == piece then return true end end
    return false
end
-- }}}

-- {{{ function P.id
-- A profile's stable id: FNV-1a (32-bit) over its piece and its answers in
-- question order, as 8 hex digits. Two profiles with the same piece and
-- answers are the same design, so they share an id (and its votes).
function P.id(piece, answers, questions)
    local text = piece
    for _, q in ipairs(questions) do
        if answers[q.id] then text = text .. "|" .. q.id .. "=" .. answers[q.id] end
    end
    local h = 2166136261
    for i = 1, #text do
        h = bit.bxor(h, text:byte(i))
        h = (h * 16777619) % 4294967296
    end
    return string.format("%08x", h)
end
-- }}}

-- {{{ function P.tally
-- The votes read against the profiles they were cast on.
--   profiles  every profile of every earlier round (list)
--   votes     { [profile id] = { up = n, down = n } }
-- Returns, per question id and option id:
--   score[q][o]   net votes (ups - downs) of the profiles that used o
--   carried[q][o] downvotes of profiles that carried o (not their focus)
--   uses[q][o]    how many profiles used o
-- and per question: leader[q] (option id or nil) and answered[q] (bool).
function P.tally(questions, profiles, votes)
    local t = { score = {}, carried = {}, uses = {}, leader = {}, answered = {} }
    for _, q in ipairs(questions) do
        t.score[q.id], t.carried[q.id], t.uses[q.id] = {}, {}, {}
        for _, o in ipairs(q.options) do t.score[q.id][o.id], t.carried[q.id][o.id], t.uses[q.id][o.id] = 0, 0, 0 end
    end
    for _, pr in ipairs(profiles) do
        local v = votes[pr.id] or { up = 0, down = 0 }
        for qid, oid in pairs(pr.answers) do
            if t.score[qid] and t.score[qid][oid] then
                t.score[qid][oid] = t.score[qid][oid] + v.up - v.down
                t.uses[qid][oid] = t.uses[qid][oid] + 1
                if pr.how[qid] == "carried" then t.carried[qid][oid] = t.carried[qid][oid] + v.down end
            end
        end
    end
    -- the leader: highest net score above 0 (none while nothing is liked);
    -- answered: the leader clear of the next by the margin, with enough votes
    for _, q in ipairs(questions) do
        -- best and runner-up in one pass; a tie leaves the first as best
        -- and the runner-up equal to it, so a tied question is never answered
        local best, lead, second = nil, -math.huge, -math.huge
        for _, o in ipairs(q.options) do
            local s = t.score[q.id][o.id]
            if s > lead then
                best, second, lead = o.id, lead, s
            elseif s > second then
                second = s
            end
        end
        t.leader[q.id] = lead > 0 and best or nil
        t.answered[q.id] = lead >= P.ANSWERED_NET and lead - second >= P.ANSWERED_MARGIN
    end
    return t
end
-- }}}

-- {{{ function P.keep_chance
-- How likely a non-focus answer carries its question's leader: high at
-- first, lower with each downvote on profiles that carried it.
function P.keep_chance(t, qid)
    local leader = t.leader[qid]
    if not leader then return 0 end
    return math.max(P.KEEP_FLOOR, P.KEEP_BASE - P.KEEP_PER_DOWN * t.carried[qid][leader])
end
-- }}}

-- {{{ function P.make
-- One profile. Returns { id, piece, answers = {q = o}, how = {q = "focus" |
-- "carried" | "random"}, focus = {q, ...} }.
function P.make(Q, t, r)
    local piece = pick_weighted(Q.pieces, function(p) return p == "shield" and P.SHIELD_WEIGHT or 1 end, r)
    local open = {}
    for _, q in ipairs(Q.questions) do if applies(q, piece) then open[#open + 1] = q end end
    -- the focus: one or two questions, weighted toward the unanswered
    local focus, chosen = {}, {}
    local want = r() < P.TWO_FOCUS_CHANCE and 2 or 1
    for _ = 1, math.min(want, #open) do
        local q = pick_weighted(open, function(q)
            if chosen[q.id] then return 0 end
            return t.answered[q.id] and P.WEIGHT_ANSWERED or P.WEIGHT_OPEN
        end, r)
        chosen[q.id] = true
        focus[#focus + 1] = q.id
    end
    local answers, how = {}, {}
    for _, q in ipairs(open) do
        if chosen[q.id] then
            -- explore: the least-tried options first (weight 1 / (1 + uses))
            local o = pick_weighted(q.options, function(o) return 1 / (1 + t.uses[q.id][o.id]) end, r)
            answers[q.id], how[q.id] = o.id, "focus"
        elseif t.leader[q.id] and r() < P.keep_chance(t, q.id) then
            answers[q.id], how[q.id] = t.leader[q.id], "carried"        -- persistence
        else
            local o = q.options[1 + math.floor(r() * #q.options)]
            answers[q.id], how[q.id] = o.id, "random"                   -- variation
        end
    end
    return { id = P.id(piece, answers, Q.questions), piece = piece, answers = answers, how = how, focus = focus }
end
-- }}}

-- {{{ function P.prompt
-- The image prompt for a profile: the piece, who wears it (Q.subject, a string), then each answer's
-- words (the focus answers first, so they weigh most in the prompt).
P.NEGATIVE = "character, person, face, body, text, watermark, signature, blurry, lowres, cropped, extra objects, busy background"
function P.prompt(Q, pr)
    local says = {}
    local byq = {}
    for _, q in ipairs(Q.questions) do
        byq[q.id] = {}
        for _, o in ipairs(q.options) do byq[q.id][o.id] = o.says end
    end
    for _, qid in ipairs(pr.focus) do says[#says + 1] = byq[qid][pr.answers[qid]] end
    for _, q in ipairs(Q.questions) do
        local oid = pr.answers[q.id]
        if oid and pr.how[q.id] ~= "focus" then says[#says + 1] = byq[q.id][oid] end
    end
    return "fantasy concept art of a single " .. Q.piece_words[pr.piece]
        .. " for " .. Q.subject .. ", " .. table.concat(says, ", ")
        .. ", isolated on a plain soft background, full view, highly detailed, game asset"
end
-- }}}

-- {{{ function P.round
-- A round of `count` profiles, none repeating an earlier profile or each
-- other (a repeat is redrawn, up to 20 times, then kept with a warning
-- note: the design space may be nearly used up for that piece).
function P.round(Q, earlier, votes, count, seed)
    local t = P.tally(Q.questions, earlier, votes)
    local r = P.rng(seed)
    local seen, out, notes = {}, {}, {}
    for _, pr in ipairs(earlier) do seen[pr.id] = true end
    for i = 1, count do
        local pr
        for try = 1, 21 do
            pr = P.make(Q, t, r)
            if not seen[pr.id] then break end
            if try == 21 then notes[#notes + 1] = "profile " .. i .. " repeats " .. pr.id .. " after 20 redraws" end
        end
        seen[pr.id] = true
        pr.prompt = P.prompt(Q, pr)
        out[#out + 1] = pr
    end
    return out, t, notes
end
-- }}}

return P
