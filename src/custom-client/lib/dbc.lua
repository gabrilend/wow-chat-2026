--------------------------------------------------------------------------------
-- lib/dbc.lua (issue 173d) - the game's own tables (DBFilesClient/*.dbc)
--
-- For a general audience: the client keeps its lists (which skin colours a
-- race has, which hair styles, which texture each uses) in simple tables:
-- a header, then rows of equal width, then one block of all the text the
-- rows point into. This reads one into Lua rows.
--
-- Layout (little-endian): "WDBC", uint32 rows, uint32 fields a row,
-- uint32 bytes a row, uint32 bytes of text; then the rows; then the text.
-- Every field here is 4 bytes; which are numbers and which are text
-- offsets is the caller's to say.
--------------------------------------------------------------------------------

local Dbc = {}

-- {{{ local function u32
local function u32(s, at)
    local a, b, c, d = s:byte(at + 1, at + 4)
    return a + b * 256 + c * 65536 + d * 16777216
end
-- }}}

-- {{{ function Dbc.read
-- Rows of table data `s` (string) as a list; each row a list of its
-- fields (1-based). Fields named in `text_fields` (a set of 1-based field
-- numbers) are read as text; the others as unsigned 32-bit integers.
function Dbc.read(s, text_fields, name)
    if type(s) ~= "string" then error((name or "table") .. ": no data (the archives don't hold this table)") end
    if s:sub(1, 4) ~= "WDBC" then error((name or "table") .. " is not a WDBC table") end
    local nrows, nfields, rowlen = u32(s, 4), u32(s, 8), u32(s, 12)
    local text_at = 20 + nrows * rowlen
    local rows = {}
    for r = 0, nrows - 1 do
        local row, base = {}, 20 + r * rowlen
        for f = 1, nfields do
            local v = u32(s, base + (f - 1) * 4)
            if text_fields and text_fields[f] then
                local from = text_at + v + 1
                row[f] = s:sub(from, s:find("\0", from, true) - 1)
            else
                row[f] = v
            end
        end
        rows[#rows + 1] = row
    end
    return rows
end
-- }}}

return Dbc
