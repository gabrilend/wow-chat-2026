#!/usr/bin/env luajit

local Header = {}

Header.FIELDS = { id = true, profiles = true, priority = true, kind = true, about = true,
                  carries = false, ["quick-test"] = false }
Header.KINDS  = { source = true, settings = true, install = true, sql = true, test = true }

local function split_lines(text)
    local lines, pos, n = {}, 1, #text
    while pos <= n do
        local nl = text:find("\n", pos, true)
        if nl then lines[#lines + 1] = text:sub(pos, nl - 1); pos = nl + 1
        else lines[#lines + 1] = text:sub(pos); break end
    end
    return lines
end

function Header.parse(text)
    local lines = split_lines(text)
    local r = { state = "absent", fields = {}, problems = {}, lines = #lines }
    local first = (lines[1] and lines[1]:sub(1, 2) == "#!") and 2 or 1
    local opening = lines[first] or ""
    local marker = opening:match("^(#)%s*====%s*header") or opening:match("^(%-%-)%s*====%s*header")
    if not marker then return r end
    r.marker, r.header_first = marker, first
    local function fault(s) r.problems[#r.problems + 1] = s end
    local m = marker:gsub("%-", "%%-")

    local hl, fl = opening:match("^" .. m .. " ==== header: (%d+) lines?, footer: (%d+) lines? ====$")
    hl, fl = tonumber(hl), tonumber(fl)
    if not hl then
        fault("line " .. first .. ": the opening line should read \"" .. marker .. " ==== header: N lines, footer: M lines ====\"")
        r.state = "broken"
        return r
    end
    r.header_len, r.footer_len = hl, fl
    local hlast, ffirst = first + hl - 1, #lines - fl + 1
    if hl < 2 or fl < 2 or hlast >= ffirst then
        fault(string.format("the stated lengths (header %d, footer %d) don't fit a file of %d lines", hl, fl, #lines))
        r.state = "broken"
        return r
    end

    if lines[hlast] ~= marker .. " ==== end of header ====" then
        fault(string.format("line %d: the header's %dth line should be \"%s ==== end of header ====\"", hlast, hl, marker))
    end
    for i = first + 1, hlast - 1 do
        local name, value = lines[i]:match("^" .. m .. " ([%w%-]+):%s*(.-)%s*$")
        if not name then
            fault(string.format("line %d: not a \"name: value\" line", i))
        elseif Header.FIELDS[name] == nil then
            fault(string.format("line %d: unknown field \"%s\"", i, name))
        elseif r.fields[name] then
            fault(string.format("line %d: \"%s\" given twice", i, name))
        else
            r.fields[name] = value
        end
    end
    for name, required in pairs(Header.FIELDS) do
        if required and (r.fields[name] == nil or r.fields[name] == "") then fault("missing field \"" .. name .. "\"") end
    end
    if r.fields.priority and not r.fields.priority:match("^%d+$") then
        fault("priority \"" .. r.fields.priority .. "\" is not a whole number")
    end
    if r.fields.kind and not Header.KINDS[r.fields.kind] then
        fault("kind \"" .. r.fields.kind .. "\" is not one of source, settings, install, sql, test")
    end

    local want_open = marker .. " ==== footer of " .. (r.fields.id or "?") .. " ===="
    if lines[ffirst] ~= want_open then
        fault(string.format("line %d: the footer should open \"%s\" (found \"%s\")", ffirst, want_open, lines[ffirst] or ""))
    end
    if lines[#lines] ~= marker .. " ==== end of footer ====" then
        fault(string.format("line %d: the last line should be \"%s ==== end of footer ====\"", #lines, marker))
    end
    local counted
    for i = ffirst + 1, #lines - 1 do
        local n = lines[i]:match("^" .. m .. " lines:%s*(%d+)%s*$")
        if n then counted = tonumber(n)
        else fault(string.format("line %d: the footer holds only \"lines: N\"", i)) end
    end
    if not counted then
        fault("the footer has no \"lines:\" count")
    elseif counted ~= #lines then
        fault(string.format("the footer says %d lines, the file has %d (cut short, or added to below the footer?)", counted, #lines))
    end
    r.counted = counted

    r.state = #r.problems == 0 and "whole" or "broken"
    return r
end

function Header.read(path)
    local f = io.open(path, "rb")
    if not f then error("patch-header: cannot read " .. path) end
    local text = f:read("*a"); f:close()
    local r = Header.parse(text)
    r.path = path
    return r
end

function Header.fix_lines(path)
    local r = Header.read(path)
    if r.state == "whole" then return false end
    if r.state == "absent" then return false, { "no header" } end
    local others = {}
    for _, p in ipairs(r.problems) do
        if not p:match("^the footer says %d+ lines, the file has %d+") then others[#others + 1] = p end
    end
    if #others > 0 then return false, others end
    local f = io.open(path, "rb"); local text = f:read("*a"); f:close()
    local lines = split_lines(text)
    local m = r.marker:gsub("%-", "%%-")
    for i = #lines - r.footer_len + 2, #lines - 1 do
        if lines[i]:match("^" .. m .. " lines:") then
            lines[i] = lines[i]:gsub("%d+%s*$", tostring(#lines))
        end
    end
    local out = table.concat(lines, "\n") .. (text:sub(-1) == "\n" and "\n" or "")
    f = assert(io.open(path, "wb")); f:write(out); f:close()
    return true
end

return Header
