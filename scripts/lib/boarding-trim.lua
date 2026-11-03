
local Trim = {}

Trim.IDLE_YARDS = 0.5
Trim.PAUSE_MS   = 1500
Trim.SHORT_MS   = 250

local DECK, JUMP, LAND = 1, 2, 4

local function bit(v, b) return math.floor(v / b) % 2 == 1 end
local function still(a, b)
    if bit(a.flags, DECK) ~= bit(b.flags, DECK) then return false end
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz) < Trim.IDLE_YARDS
end
local function marked(s) return bit(s.flags, JUMP) or bit(s.flags, LAND) end
local function copy(s)
    local c = {}
    for k, v in pairs(s) do c[k] = v end
    return c
end

function Trim.trim(steps)
    local report = { head_steps = 0, head_ms = 0, tail_steps = 0, pauses = 0, pause_ms = 0 }
    local n = #steps
    if n < 2 then
        local out = {}
        for i, s in ipairs(steps) do out[i] = copy(s) end
        return out, report
    end

    local first = 1
    while first < n and still(steps[first], steps[first + 1]) and not marked(steps[first]) and not marked(steps[first + 1]) do
        first = first + 1
    end
    report.head_steps = first - 1
    report.head_ms    = steps[first].ms - steps[1].ms

    local last = n
    while last > first and still(steps[last], steps[last - 1]) and not marked(steps[last]) and not marked(steps[last - 1]) do
        last = last - 1
    end
    report.tail_steps = n - last

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

return Trim
