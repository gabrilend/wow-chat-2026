
local src  = debug.getinfo(1, "S").source
local here = (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
local file = here .. "../lua-basic/buddy-talents.lua"
local ok, err = pcall(dofile, file)
if not ok then
    print("[buddy-talents] ERROR: cc-test could not run basic's talent script (" .. file .. "): " .. tostring(err)
        .. "; stand-ins' and buddies' talent points stay unspent")
end
