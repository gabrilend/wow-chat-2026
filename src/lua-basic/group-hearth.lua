
local src  = debug.getinfo(1, "S").source
local here = (src:sub(1, 1) == "@" and src:sub(2) or src):match("^(.*[/\\])") or "./"
local file = here .. "../lua-beta/hearthstone.lua"
local ok, err = pcall(dofile, file)
if not ok then
    print("[group-hearth] ERROR: basic could not run beta's group hearthstone (" .. file .. "): " .. tostring(err)
        .. "; nobody is invited along on a hearthstone")
else
    function GroupHearth.skip(member, hearther)
        return CharDBQuery("SELECT 1 FROM buddy_roster WHERE buddy = " .. member:GetGUIDLow()) ~= nil
    end
end
