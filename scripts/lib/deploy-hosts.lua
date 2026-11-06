--------------------------------------------------------------------------------
-- deploy-hosts.lua - reading and checking the roles file (issue 157a)
--
-- For a general audience: config/deploy-hosts.lua says which machine does
-- each of the server's three jobs (database, auth, world): "local" for the
-- development machine itself, or a table naming a machine on the home
-- network. This module loads that file without letting it run anything,
-- lists every mistake in it, and answers one field of one role. The tool
-- scripts/deploy-host is its command-line face, so bash scripts never parse
-- Lua themselves; scripts/test-deploy-hosts tests both.
--------------------------------------------------------------------------------

local Hosts = {}

-- {{{ the rules, in structure
Hosts.LOCAL  = "local"
Hosts.ROLES  = { "database", "auth", "world" }
Hosts.FIELDS = { "lan_address", "ssh_user", "install_dir", "arch" }
Hosts.ARCHES = { x86_64 = true, aarch64 = true, armv7l = true, i686 = true }  -- what `uname -m` says
Hosts.LOCAL_ADDRESS = "127.0.0.1"                -- what a local role's lan_address reads as (157c)
local CHECK = {
    lan_address = function(v)
        if type(v) ~= "string" then return "is not text" end
        local a, b, c, d = v:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
        if not a then return "is not a dotted IPv4 address (four numbers 0-255)" end
        local o = { a, b, c, d }
        for _, n in ipairs(o) do
            if tonumber(n) > 255 or (#n > 1 and n:sub(1, 1) == "0") then     -- no leading zeros: 010 reads as octal to some tools
                return "is not a dotted IPv4 address (four numbers 0-255)"
            end
        end
        if o[1] == "127" then return "is this machine itself: write the role as \"local\"" end
        if o[1] == "0" then return "is no machine's address" end
        return nil
    end,
    ssh_user = function(v)
        if type(v) ~= "string" then return "is not text" end
        if #v > 32 or not v:match("^[a-z_][a-z0-9_%-]*$") then return "is not a user name (lower-case letters, digits, _ and -)" end
        return nil
    end,
    install_dir = function(v)
        if type(v) ~= "string" then return "is not text" end
        if v:sub(1, 1) ~= "/" then return "is not an absolute path" end
        if v == "/" or v:match("^/+$") then return "is the whole disk" end
        if ("/" .. v .. "/"):find("/%.%./") then return "goes up a folder (..)" end
        if v:find("%s") then return "has a space in it" end
        return nil
    end,
    arch = function(v)
        if type(v) ~= "string" then return "is not text" end
        if not Hosts.ARCHES[v] then return "is not a known architecture (x86_64, aarch64, armv7l, i686)" end
        return nil
    end,
}
-- }}}

-- {{{ function Hosts.load
-- The roles file at `path`, run with nothing to call (it can only build its
-- table). Returns the table, or nil and an error naming the file.
function Hosts.load(path)
    local f = io.open(path, "rb")
    if not f then return nil, path .. ": no roles file there" end
    local text = f:read("*a")
    f:close()
    if text:sub(1, 1) == "\27" then return nil, path .. ": is compiled, not text" end
    local chunk, err
    if setfenv then
        chunk, err = loadstring(text, "@" .. path)       -- Lua 5.1 and LuaJIT
        if chunk then setfenv(chunk, {}) end
    else
        chunk, err = load(text, "@" .. path, "t", {})    -- Lua 5.2 and later
    end
    if not chunk then return nil, path .. ": " .. tostring(err) end
    local ok, value = pcall(chunk)
    if not ok then return nil, path .. ": " .. tostring(value) end
    if type(value) ~= "table" then return nil, path .. ": does not return a table of roles" end
    return value
end
-- }}}

-- {{{ function Hosts.problems
-- Every mistake in a roles table, as sentences (empty: none). A role is
-- "local" or a table of exactly the four fields; the three roles are all
-- there and no others; roles sharing an address are one machine, so they
-- must agree on its architecture.
function Hosts.problems(hosts)
    local out, known = {}, {}
    for _, r in ipairs(Hosts.ROLES) do known[r] = true end
    local names = {}
    for k in pairs(hosts) do names[#names + 1] = tostring(k) end
    table.sort(names)
    for _, k in ipairs(names) do
        if not known[k] then out[#out + 1] = "\"" .. k .. "\" is not a role (database, auth, world)" end
    end
    local by_address = {}
    for _, role in ipairs(Hosts.ROLES) do
        local v = hosts[role]
        if v == nil then
            out[#out + 1] = role .. " is missing"
        elseif type(v) == "table" then
            local fields = {}
            for _, f in ipairs(Hosts.FIELDS) do fields[f] = true end
            local extra = {}
            for f in pairs(v) do if not fields[f] then extra[#extra + 1] = tostring(f) end end
            table.sort(extra)
            for _, f in ipairs(extra) do out[#out + 1] = role .. "." .. f .. " is not a field (lan_address, ssh_user, install_dir, arch)" end
            for _, f in ipairs(Hosts.FIELDS) do
                if v[f] == nil then out[#out + 1] = role .. "." .. f .. " is missing"
                else
                    local why = CHECK[f](v[f])
                    if why then out[#out + 1] = role .. "." .. f .. " (" .. tostring(v[f]) .. ") " .. why end
                end
            end
            if type(v.lan_address) == "string" and not CHECK.lan_address(v.lan_address) then
                local first = by_address[v.lan_address]
                if first and type(v.arch) == "string" and type(first.arch) == "string" and first.arch ~= v.arch then
                    out[#out + 1] = role .. " and " .. first.role .. " share " .. v.lan_address
                        .. " (one machine) but say " .. v.arch .. " and " .. first.arch
                end
                if not first then by_address[v.lan_address] = { role = role, arch = v.arch } end
            end
        elseif v ~= Hosts.LOCAL then
            out[#out + 1] = role .. " is neither \"local\" nor a table of its machine"
        end
    end
    return out
end
-- }}}

-- {{{ function Hosts.field
-- One field of one role, as text. `here` describes this machine for a local
-- role: { dir = the project folder, arch = `uname -m` }. Besides the four
-- fields, "local" answers "yes" or "no". A local role's address is
-- 127.0.0.1, its user "" (no ssh). Returns the text, or nil and why.
function Hosts.field(hosts, role, field, here)
    local v = hosts[role]
    if v == nil then return nil, "\"" .. tostring(role) .. "\" is not a role (database, auth, world)" end
    if field == "local" then return v == Hosts.LOCAL and "yes" or "no" end
    local ok = false
    for _, f in ipairs(Hosts.FIELDS) do if f == field then ok = true end end
    if not ok then return nil, "\"" .. tostring(field) .. "\" is not a field (lan_address, ssh_user, install_dir, arch, local)" end
    if v == Hosts.LOCAL then
        local mine = { lan_address = Hosts.LOCAL_ADDRESS, ssh_user = "", install_dir = here.dir, arch = here.arch }
        return mine[field]
    end
    return v[field]
end
-- }}}

return Hosts
