
local M = {}
local PLAYER_TEMPLATES = { 1, 2 }

function M.friendly_to_a_side(dir)
    local ffi = require("ffi")
    local path = dir .. "/data-files/dbc/FactionTemplate.dbc"
    local fh = io.open(path, "rb") or error("monster-factions: cannot open " .. path)
    local d = fh:read("*a"); fh:close()
    local p = ffi.cast("const uint8_t*", d)
    local h = ffi.cast("const uint32_t*", p)
    local recs, size = h[1], h[3]
    local function u(r, i) return ffi.cast("const uint32_t*", p + 20 + r * size + i * 4)[0] end
    local rows = {}
    for r = 0, recs - 1 do
        rows[u(r, 0)] = { faction = u(r, 1), our = u(r, 3), friendly = u(r, 4),
                          enemies = { u(r, 6), u(r, 7), u(r, 8), u(r, 9) }, friends = { u(r, 10), u(r, 11), u(r, 12), u(r, 13) } }
    end
    local function friendly(e, pl)
        for i = 1, 4 do if e.enemies[i] ~= 0 and e.enemies[i] == pl.faction then return false end end
        for i = 1, 4 do if e.friends[i] ~= 0 and e.friends[i] == pl.faction then return true end end
        return bit.band(e.friendly, pl.our) ~= 0 or bit.band(e.our, pl.friendly) ~= 0
    end
    local out = {}
    for id, e in pairs(rows) do
        for _, t in ipairs(PLAYER_TEMPLATES) do
            if rows[t] and friendly(e, rows[t]) then out[id] = true end
        end
    end
    return out
end

return M
