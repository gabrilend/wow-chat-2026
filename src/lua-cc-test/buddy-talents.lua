--------------------------------------------------------------------------------
-- buddy-talents.lua (cc-test) - runs basic's talent script, in place
--
-- For a general audience: buddies and stand-ins spend their talent points by
-- their shape through src/lua-basic/buddy-talents.lua (issues 617g, 617t1).
-- cc-test needs the same for its test scenes' stand-ins, so this runs that
-- very file rather than a copy: the two profiles can never drift apart.
--
-- How it finds it: install step E001 links this folder into the server's
-- lua_scripts as custom/. A path through that link and then ".." climbs from
-- the link's target (this folder, src/lua-cc-test/), so
-- "<this folder>/../lua-basic/" is basic's folder however the link is named.
-- Basic's script then finds its data and helpers beside itself.
-- (Links in git were tried first, 2026-10-09; the project's commit tool
-- carries no links, so a file it is.)
--------------------------------------------------------------------------------

local src  = debug.getinfo(1, "S").source
local here = (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
local file = here .. "../lua-basic/buddy-talents.lua"
local ok, err = pcall(dofile, file)
if not ok then
    print("[buddy-talents] ERROR: cc-test could not run basic's talent script (" .. file .. "): " .. tostring(err)
        .. "; stand-ins' and buddies' talent points stay unspent")
end
