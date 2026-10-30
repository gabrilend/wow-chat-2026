--------------------------------------------------------------------------------
-- boarding-trim.lua - cuts what isn't the way out of a boarding recording
-- (issue 617e8, the owner's answer of 2026-10-30).
--
-- For a general audience: a game master records the way aboard a boat or
-- zeppelin by walking it (".buddy record start" / "stop", 617e9). A
-- recording also holds what isn't the way: standing still at the start
-- before setting off, standing at the end after arriving, a pause in the
-- middle. The owner: "run it through a manual LLM scrutiny test to clean up
-- things like "standing still at the start of the routine" and such, to
-- clarify the result to just the specificly needed waypoints." This finds
-- those stretches by a plain rule and proposes the cut; a person (or an
-- agent reading the printed steps) looks before it is kept
-- (scripts/trim-buddy-boardings shows it, and writes it with --apply).
--
-- A step is a table: ms (number: milliseconds from the start), flags
-- (number: the recorder's bits, 1 on deck, 2 a jump left here, 4 landed
-- here, 8 walking), x, y, z, o (numbers: world yards and facing, or the
-- ship-relative offset when on deck), jump_xy, jump_z (numbers).
--
-- Pure: no database, no server. Tested offline by scripts/test-boarding-trim.
--------------------------------------------------------------------------------

local Trim = {}

-- {{{ the levers
Trim.IDLE_YARDS = 0.5     -- steps closer than this to each other count as standing still
Trim.PAUSE_MS   = 1500    -- a stand longer than this in the middle is shortened to SHORT_MS
Trim.SHORT_MS   = 250     -- what is left of a shortened pause
-- }}}

local DECK, JUMP, LAND = 1, 2, 4

-- {{{ local helpers
local function bit(v, b) return math.floor(v / b) % 2 == 1 end
local function still(a, b)
    -- only comparable on the same footing: both ashore, or both on deck
    if bit(a.flags, DECK) ~= bit(b.flags, DECK) then return false end
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz) < Trim.IDLE_YARDS
end
-- a step that matters whatever its place: a jump leaving, a landing
local function marked(s) return bit(s.flags, JUMP) or bit(s.flags, LAND) end
local function copy(s)
    local c = {}
    for k, v in pairs(s) do c[k] = v end
    return c
end
-- }}}

-- {{{ function Trim.trim
-- Takes a recording's steps in order; returns the steps kept (copies, ms
-- re-based) and a report table:
--   head_steps, head_ms   - standing at the start, cut (the last of the
--                           stand is kept as the start)
--   tail_steps            - standing at the end, cut (the first of the
--                           stand is kept as the end)
--   pauses, pause_ms      - stands in the middle shortened, and the time taken out
-- A recording of fewer than two steps is returned as it is.
-- Never cut: a jump or a landing step, and the step where the deck is
-- stepped onto or off (a change of footing is never "still").
function Trim.trim(steps)
    local report = { head_steps = 0, head_ms = 0, tail_steps = 0, pauses = 0, pause_ms = 0 }
    local n = #steps
    if n < 2 then
        local out = {}
        for i, s in ipairs(steps) do out[i] = copy(s) end
        return out, report
    end

    -- the start: the last step of the opening stand
    local first = 1
    while first < n and still(steps[first], steps[first + 1]) and not marked(steps[first]) and not marked(steps[first + 1]) do
        first = first + 1
    end
    report.head_steps = first - 1
    report.head_ms    = steps[first].ms - steps[1].ms

    -- the end: the first step of the closing stand
    local last = n
    while last > first and still(steps[last], steps[last - 1]) and not marked(steps[last]) and not marked(steps[last - 1]) do
        last = last - 1
    end
    report.tail_steps = n - last

    -- between them, a stand longer than PAUSE_MS is shortened: the steps
    -- of a stand collapse to its first, and later times move earlier
    -- Each path at a step:
    --   a stand from here longer than PAUSE_MS: keep this step and the
    --     stand's last (where it sets off again), SHORT_MS apart; skip the rest
    --   otherwise: keep this step, go on to the next
    local out, shift = {}, steps[first].ms
    local i = first
    while i <= last do
        local s = copy(steps[i])
        s.ms = s.ms - shift
        out[#out + 1] = s
        local j = i
        while j < last and still(steps[i], steps[j + 1]) and not marked(steps[j + 1]) do j = j + 1 end
        local stood = steps[j].ms - steps[i].ms
        if j > i and stood > Trim.PAUSE_MS then
            report.pauses   = report.pauses + 1
            report.pause_ms = report.pause_ms + (stood - Trim.SHORT_MS)
            shift = shift + (stood - Trim.SHORT_MS)
            local e = copy(steps[j])
            e.ms = e.ms - shift
            out[#out + 1] = e
            i = j + 1
        else
            i = i + 1
        end
    end
    return out, report
end
-- }}}

return Trim
