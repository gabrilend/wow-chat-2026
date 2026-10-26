#!/usr/bin/env luajit

local ffi = require("ffi")
local SpellData = {}

local function read_dbc(path)
    local f = io.open(path, "rb")
    if not f then error("spell-data: cannot open " .. path .. " (is the server's data folder there?)") end
    local d = f:read("*a"); f:close()
    if d:sub(1, 4) ~= "WDBC" then error("spell-data: " .. path .. " is not a WDBC file") end
    local function u32(o) local a, b, c, e = d:byte(o + 1, o + 4); return a + b * 256 + c * 65536 + e * 16777216 end
    local n, fields, size = u32(4), u32(8), u32(12)
    local strs = 20 + n * size
    local t = { n = n, fields = fields, by_id = {} }
    function t.u(row, i) return u32(20 + row * size + i * 4) end
    function t.i(row, i) local v = t.u(row, i); if v >= 2 ^ 31 then v = v - 2 ^ 32 end; return v end
    function t.f(row, i) local v = ffi.new("uint32_t[1]", t.u(row, i)); return ffi.cast("float*", v)[0] end
    function t.s(row, i) local o = t.u(row, i); local e = d:find("\0", strs + o + 1, true); return d:sub(strs + o + 1, e - 1) end
    for r = 0, n - 1 do t.by_id[t.u(r, 0)] = r end
    return t
end

function SpellData.open(dir, mysql)
    local dbc = read_dbc(dir .. "/data-files/dbc/Spell.dbc")
    local over = {}
    if mysql then
        local p = io.popen(mysql .. ' -e "SELECT * FROM spell_dbc" 2>&1')
        for l in p:lines() do
            if not l:match("^mysql: %[Warning%]") then
                local v, i = {}, 0
                for x in (l .. "\t"):gmatch("([^\t]*)\t") do v[i] = x; i = i + 1 end
                if i ~= dbc.fields then error("spell-data: spell_dbc has " .. i .. " columns, Spell.dbc " .. dbc.fields .. "; MySQL said: " .. l) end
                over[tonumber(v[0])] = v
            end
        end
        p:close()
    end

    local durs = read_dbc(dir .. "/data-files/dbc/SpellDuration.dbc")

    local R = {}
    local function field(id, i, kind)
        local o = over[id]
        if o then return kind == "s" and o[i] or tonumber(o[i]) end
        local row = dbc.by_id[id]
        if not row then return nil end
        return dbc[kind](row, i)
    end

    function R.exists(id) return over[id] ~= nil or dbc.by_id[id] ~= nil end
    function R.name(id) return field(id, 136, "s") end
    function R.school(id) return field(id, 225, "u") end
    function R.replaced(id) return over[id] ~= nil end
    function R.duration(id)
        local idx = field(id, 40, "u")
        if not idx or idx == 0 then return nil end
        local row = durs.by_id[idx]
        return row and durs.i(row, 1) or nil
    end
    function R.levels(id) return { base = field(id, 38, "u") or 0, spell = field(id, 39, "u") or 0, max = field(id, 37, "u") or 0 } end

    function R.effects(id)
        if not R.exists(id) then return nil end
        local list = {}
        for k = 0, 2 do
            local e = field(id, 71 + k, "u")
            if e and e ~= 0 then
                local dice = field(id, 74 + k, "i")
                list[#list + 1] = {
                    effect = e,
                    aura   = field(id, 95 + k, "u"),
                    base   = field(id, 80 + k, "i") + 1,
                    dice   = dice > 1 and dice - 1 or 0,
                    misc   = field(id, 110 + k, "i"),
                    target = field(id, 86 + k, "u"),
                    radius = field(id, 92 + k, "u"),
                    period = field(id, 98 + k, "u"),
                    per_level = field(id, 77 + k, "f"),
                    trigger = field(id, 116 + k, "u"),
                }
            end
        end
        return list
    end
    return R
end

return SpellData
