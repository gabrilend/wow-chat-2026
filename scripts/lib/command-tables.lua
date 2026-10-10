--------------------------------------------------------------------------------
-- command-tables.lua - read the game server's C++ command tables as data
--
-- For a general audience: every typed command the server knows is declared
-- in C++ as a table of rows like
--     { "add", HandleAdd, SEC_GAMEMASTER, Console::No }
-- (a word, what runs it, who may, and whether the server console may), and
-- a row can point at another table, which nests the words: ".buddy bed add".
-- This reads those tables straight out of the source files and returns one
-- flat list of whole commands, so documentation and tests can be made from
-- the code itself rather than from a copy that drifts.
--
-- Used by scripts/generate-gm-command-reference and
-- scripts/test-gm-command-reference. See command-tables.info.md.
--------------------------------------------------------------------------------

local M = {}

-- who may run a command, as the code names it (AzerothCore AccountTypes);
-- an rbac:: permission number is not a level, so it is kept as text: a
-- `command` row decides the level, or else the auth database's role chain
-- (scripts/generate-gm-command-reference reads it; 2026-10-09)
M.LEVELS = { SEC_PLAYER = 0, SEC_MODERATOR = 1, SEC_GAMEMASTER = 2, SEC_ADMINISTRATOR = 3, SEC_CONSOLE = 4 }

-- {{{ local function strip_comments
-- Comments removed, so a commented-out row is not read as a command.
local function strip_comments(text)
    text = text:gsub("/%*.-%*/", "")
    text = text:gsub("//[^\n]*", "")
    return text
end
-- }}}

-- {{{ local function split_fields
-- A row's fields, split on the commas that are not inside a string.
local function split_fields(row)
    local fields, field, in_string = {}, {}, false
    for ch in row:gmatch(".") do
        if ch == '"' then in_string = not in_string end
        if ch == "," and not in_string then
            fields[#fields + 1] = table.concat(field):match("^%s*(.-)%s*$")
            field = {}
        else
            field[#field + 1] = ch
        end
    end
    fields[#fields + 1] = table.concat(field):match("^%s*(.-)%s*$")
    return fields
end
-- }}}

-- {{{ local function read_tables
-- Every "ChatCommandTable name = { rows }" in a piece of text, by name.
local function read_tables(text, into)
    for name, tbody in text:gmatch("ChatCommandTable%s+([%w_]+)%s*=?%s*(%b{})") do
        local rows = {}
        for row in tbody:sub(2, -2):gmatch("%b{}") do rows[#rows + 1] = split_fields(row:sub(2, -2)) end
        into[name] = rows
    end
    return into
end
-- }}}

-- {{{ local function read_block
-- One GetCommands body: its tables by name, and the one it returns. Tables
-- the file defines elsewhere (cs_account.cpp keeps three as members) are
-- found too; one inside this body wins over a same-named one elsewhere.
local function read_block(body, file_tables, file, out, errors)
    local tables = {}
    for k, v in pairs(file_tables) do tables[k] = v end
    for name, tbody in body:gmatch("ChatCommandTable%s+([%w_]+)%s*=?%s*(%b{})") do
        local rows = {}
        for row in tbody:sub(2, -2):gmatch("%b{}") do rows[#rows + 1] = split_fields(row:sub(2, -2)) end
        tables[name] = rows
    end
    local root = body:match("return%s+([%w_]+)%s*;")
    if not root or not tables[root] then
        errors[#errors + 1] = file .. ": a GetCommands whose returned table could not be read"
        return
    end
    -- flatten: words joined by a space; a row with two fields names a table
    local function walk(tname, prefix, depth)
        if depth > 8 then errors[#errors + 1] = file .. ": tables nest deeper than 8 at " .. prefix; return end
        for _, f in ipairs(tables[tname]) do
            local word = f[1] and f[1]:match('^"(.*)"$')
            if not word then
                errors[#errors + 1] = file .. ": a row in " .. tname .. " has no quoted name: " .. table.concat(f, ", ")
            else
                local full = (prefix .. " " .. word):match("^%s*(.-)%s*$")
                if #f == 2 then
                    -- {"name", subTable}: nested words
                    if tables[f[2]] then walk(f[2], full, depth + 1)
                    else errors[#errors + 1] = file .. ": " .. full .. " points at table " .. f[2] .. ", defined nowhere in the file" end
                else
                    -- {"name", handler, permission, Console::X}: a command; a
                    -- row with five fields carries a help string third
                    -- ({"list", handler, LANG_RBAC_HELP_ACC_LIST, permission,
                    -- Console::Yes}, cs_rbac.cpp)
                    local pf, cf = 3, 4
                    if #f == 5 then pf, cf = 4, 5 end
                    local perm = f[pf] or ""
                    -- Console::Yes runs from the console too; Console::No in game only; no field: unknown
                    local console = nil
                    if f[cf] == "Console::Yes" then console = true elseif f[cf] == "Console::No" then console = false end
                    out[#out + 1] = {
                        name    = full,
                        level   = M.LEVELS[perm],                         -- nil for rbac:: (the command row decides)
                        perm    = perm,
                        console = console,
                        file    = file,
                    }
                end
            end
        end
    end
    walk(root, "", 0)
end
-- }}}

-- {{{ function M.read_file
-- Every command a source file declares. Returns a list of
-- { name, level, perm, console, file } and a list of error strings.
function M.read_file(path, shown_as)
    local h = io.open(path, "r")
    if not h then return {}, { "cannot read " .. path } end
    local text = strip_comments(h:read("*a"))
    h:close()
    local out, errors = {}, {}
    local file_tables = read_tables(text, {})
    -- a GetCommands body: in the class ("GetCommands() const override {")
    -- or out of it ("X::GetCommands() const {")
    for body in text:gmatch("GetCommands%s*%(%s*%)%s*const%s*[%w%s]*(%b{})") do
        read_block(body, file_tables, shown_as or path, out, errors)
    end
    return out, errors
end
-- }}}

-- {{{ function M.read_files
-- The same for many files, joined. Each file's path is shown relative to
-- `root` when given.
function M.read_files(paths, root)
    local all, errors = {}, {}
    for _, p in ipairs(paths) do
        local shown = root and p:sub(1, #root) == root and p:sub(#root + 2) or p
        local cmds, errs = M.read_file(p, shown)
        for _, c in ipairs(cmds) do all[#all + 1] = c end
        for _, e in ipairs(errs) do errors[#errors + 1] = e end
    end
    return all, errors
end
-- }}}

-- {{{ function M.files_with_tables
-- The .cpp files under a folder that declare a command table.
function M.files_with_tables(folder)
    local list = {}
    local p = io.popen("grep -rl --include=*.cpp 'ChatCommandTable' '" .. folder .. "'")
    for line in p:lines() do list[#list + 1] = line end
    p:close()
    table.sort(list)
    return list
end
-- }}}

return M
