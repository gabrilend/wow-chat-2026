#!/usr/bin/env luajit
-- patch-header.lua - read the header and footer every patch carries (issue 189a)
--
-- For a general audience: every patch (a source edit, a setting, an install
-- step, an SQL file) and every quick test says what it is in a few lines at
-- its top and confirms it at its bottom: its id, which profiles take it,
-- its priority (its place on the one number line all patches share, issue
-- 189), its kind, and a line about it; the bottom repeats the id and the
-- file's line count, so a file cut short, or added to below its footer, no
-- longer checks out. This reads those lines and says, for one file, whether
-- the header is whole (the file is a patch), broken (it starts like one but
-- something is wrong: every fault is named), or absent (a helper or a note,
-- not a patch). It also mends the footer's line count, the one field that
-- every edit changes.
--
-- The shape (the owner, 2026-10-20: "Sure."), in the file's own comment
-- marker ("#" or "--"), after a "#!" line if there is one:
--
--   # ==== header: 7 lines, footer: 3 lines ====
--   # id:        E062
--   # profiles:  beta
--   # priority:  1620
--   # kind:      install
--   # about:     trade across the factions, on beta's realm
--   # ==== end of header ====
--     ... the patch ...
--   # ==== footer of E062 ====
--   # lines:     148
--   # ==== end of footer ====
--
-- Returns its table (no globals): local Header = dofile(".../patch-header.lua")

local Header = {}

-- {{{ the fields
-- required (true) or optional (false); any other name is a fault, so a
-- misspelt field is never quietly ignored
Header.FIELDS = { id = true, profiles = true, priority = true, kind = true, about = true,
                  carries = false, ["quick-test"] = false }
Header.KINDS  = { source = true, settings = true, install = true, sql = true, test = true }
-- }}}

-- {{{ local function split_lines
-- The file's lines, and their count as an editor counts them (a last line
-- with no newline still counts; a final newline does not add an empty one).
-- A plain walk from newline to newline: a pattern anchored at the end
-- ("[^\n]+$") re-scans from every position and took minutes on SQL files
-- whose lines run to megabytes (found 2026-10-20).
local function split_lines(text)
    local lines, pos, n = {}, 1, #text
    while pos <= n do
        local nl = text:find("\n", pos, true)
        if nl then lines[#lines + 1] = text:sub(pos, nl - 1); pos = nl + 1
        else lines[#lines + 1] = text:sub(pos); break end
    end
    return lines
end
-- }}}

-- {{{ function Header.parse
-- From a file's text: { state = "whole" | "broken" | "absent",
--   fields = { name = value (text) }, problems = { text, ... },
--   marker = "#" | "--", lines = count (integer),
--   header_first, header_len, footer_len (integers, line numbers and sizes) }
--   absent: the first line (after a "#!" line) does not open with
--           "<marker> ==== header"
--   broken: it does, but a length, a closing line, the footer, a field or
--           the line count is wrong; problems names each
--   whole:  nothing is wrong
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

    -- the header: fields between its first and last lines
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

    -- the footer: the file's last fl lines
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
-- }}}

-- {{{ function Header.read
-- Header.parse of a file; a file that can't be read is an error.
function Header.read(path)
    local f = io.open(path, "rb")
    if not f then error("patch-header: cannot read " .. path) end
    local text = f:read("*a"); f:close()
    local r = Header.parse(text)
    r.path = path
    return r
end
-- }}}

-- {{{ function Header.fix_lines
-- Rewrites a file's footer "lines:" count to the file's line count, when
-- that is the header's only fault. Returns true if it changed the file,
-- false if there was nothing to mend; a file with any other fault is left
-- as it is and its faults returned as the second value.
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
-- }}}

return Header
