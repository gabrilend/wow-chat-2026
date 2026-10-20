
local M = {}

M.LEVELS = { SEC_PLAYER = 0, SEC_MODERATOR = 1, SEC_GAMEMASTER = 2, SEC_ADMINISTRATOR = 3, SEC_CONSOLE = 4 }

local function strip_comments(text)
    text = text:gsub("/%*.-%*/", "")
    text = text:gsub("//[^\n]*", "")
    return text
end

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

local function read_tables(text, into)
    for name, tbody in text:gmatch("ChatCommandTable%s+([%w_]+)%s*=?%s*(%b{})") do
        local rows = {}
        for row in tbody:sub(2, -2):gmatch("%b{}") do rows[#rows + 1] = split_fields(row:sub(2, -2)) end
        into[name] = rows
    end
    return into
end

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
    local function walk(tname, prefix, depth)
        if depth > 8 then errors[#errors + 1] = file .. ": tables nest deeper than 8 at " .. prefix; return end
        for _, f in ipairs(tables[tname]) do
            local word = f[1] and f[1]:match('^"(.*)"$')
            if not word then
                errors[#errors + 1] = file .. ": a row in " .. tname .. " has no quoted name: " .. table.concat(f, ", ")
            else
                local full = (prefix .. " " .. word):match("^%s*(.-)%s*$")
                if #f == 2 then
                    if tables[f[2]] then walk(f[2], full, depth + 1)
                    else errors[#errors + 1] = file .. ": " .. full .. " points at table " .. f[2] .. ", defined nowhere in the file" end
                else
                    local pf, cf = 3, 4
                    if #f == 5 then pf, cf = 4, 5 end
                    local perm = f[pf] or ""
                    local console = nil
                    if f[cf] == "Console::Yes" then console = true elseif f[cf] == "Console::No" then console = false end
                    out[#out + 1] = {
                        name    = full,
                        level   = M.LEVELS[perm],
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

function M.read_file(path, shown_as)
    local h = io.open(path, "r")
    if not h then return {}, { "cannot read " .. path } end
    local text = strip_comments(h:read("*a"))
    h:close()
    local out, errors = {}, {}
    local file_tables = read_tables(text, {})
    for body in text:gmatch("GetCommands%s*%(%s*%)%s*const%s*[%w%s]*(%b{})") do
        read_block(body, file_tables, shown_as or path, out, errors)
    end
    return out, errors
end

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

function M.files_with_tables(folder)
    local list = {}
    local p = io.popen("grep -rl --include=*.cpp 'ChatCommandTable' '" .. folder .. "'")
    for line in p:lines() do list[#list + 1] = line end
    p:close()
    table.sort(list)
    return list
end

return M
