#!/usr/bin/env luajit
-- aligned-table.lua - Markdown tables whose numbers line up by place value
--
-- For a general audience: a table of numbers is easiest to read when every
-- number's ones digit sits in the same column, and its decimal point too
-- when there is one, so a glance down the column compares sizes. This
-- writes Markdown tables that way in the raw text, not only once rendered
-- (the owner, 2026-10-19: "we need to keep all the digits in the same
-- "position" in terms of their X coordinate"; CLAUDE.md, Vertical
-- Alignment). Text cells are padded on the right so the column borders
-- line up too.
--
-- Used by scripts/compare-wow-chat-1-settings and
-- scripts/report-intuition-copy. Returns its table (no globals).

local Table = {}

-- {{{ local function split_number
-- A cell that is a number: its whole part (with sign), its fraction, and
-- whether it has a decimal point; nil for any other text. Thousands
-- separators are not numbers here: write the digits only.
local function split_number(s)
    local sign, whole, frac = s:match("^(%-?)(%d+)%.?(%d*)$")
    if not whole then return nil end
    return sign .. whole, frac, s:find("%.") ~= nil
end
-- }}}

-- {{{ function Table.lines
-- header: list of column names (text); rows: list of lists of cells (text
-- or numbers; numbers are written with tostring). Returns the table as a
-- list of lines: header, separator, rows.
--   a number cell: whole part padded on the left to the column's widest,
--                  then the point and the fraction padded on the right
--   a text cell:   padded on the right to the column's width
function Table.lines(header, rows)
    local cols = #header
    local whole_w, frac_w, has_dot, width = {}, {}, {}, {}
    for c = 1, cols do whole_w[c], frac_w[c], has_dot[c], width[c] = 0, 0, false, #header[c] end
    local text = {}
    for r, row in ipairs(rows) do
        text[r] = {}
        for c = 1, cols do
            local s = row[c] == nil and "" or tostring(row[c])
            text[r][c] = s
            local w, f, dot = split_number(s)
            if w then
                whole_w[c] = math.max(whole_w[c], #w)
                frac_w[c]  = math.max(frac_w[c], #f)
                has_dot[c] = has_dot[c] or dot
            end
        end
    end
    local cells = {}
    for r = 1, #text do
        cells[r] = {}
        for c = 1, cols do
            local s = text[r][c]
            local w, f, dot = split_number(s)
            if w then
                s = string.rep(" ", whole_w[c] - #w) .. w
                if has_dot[c] then s = s .. (dot and "." or " ") .. f .. string.rep(" ", frac_w[c] - #f) end
            end
            cells[r][c] = s
            width[c] = math.max(width[c], #s)
        end
    end
    local function line(list)
        local t = {}
        for c = 1, cols do t[c] = list[c] .. string.rep(" ", width[c] - #list[c]) end
        return "| " .. table.concat(t, " | ") .. " |"
    end
    local out = { line(header) }
    local sep = {} for c = 1, cols do sep[c] = string.rep("-", width[c]) end
    out[#out + 1] = line(sep)
    for r = 1, #cells do out[#out + 1] = line(cells[r]) end
    return out
end
-- }}}

return Table
