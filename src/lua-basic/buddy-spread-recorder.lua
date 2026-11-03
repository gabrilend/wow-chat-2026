
local DIR       = "/mnt/kaun/wow-chat-2026"
local LOG_PATH  = DIR .. "/tmp/shared-memory/buddy-spread.tsv"
local EVERY_MS  = 5000
local TAG       = "[buddy-spread] "

local DEBUG_BUILD = false
do
    local pf = io.open(DIR .. "/.profile")
    local profile = pf and pf:read("*l"); if pf then pf:close() end
    local bf = profile and io.open(DIR .. "/installed-files-" .. profile .. "/bin/.build-type")
    DEBUG_BUILD = bf ~= nil and bf:read("*l") == "Debug"
    if bf then bf:close() end
    if not DEBUG_BUILD then print(TAG .. "not a Debug build: buddy paths are not recorded") end
end

local function line_of(now, owner_low, p, role)
    local x, y, z = p:GetLocation()
    return string.format("%d\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%.1f\t%.1f\t%.1f\t%d\t%d\n",
        now, owner_low, p:GetGUIDLow(), p:GetName(), role, p:GetMapId(), p:GetZoneId(), p:GetAreaId(),
        x, y, z, p:IsInCombat() and 1 or 0, p:IsDead() and 1 or 0)
end

local function sample()
    if not DEBUG_BUILD then return end
    local q = CharDBQuery("SELECT owner, buddy FROM buddy_roster WHERE buddy <> 0 ORDER BY owner, slot")
    if not q then return end
    local by_owner = {}
    repeat
        local owner, buddy = q:GetUInt32(0), q:GetUInt32(1)
        by_owner[owner] = by_owner[owner] or {}
        table.insert(by_owner[owner], buddy)
    until not q:NextRow()
    local now, out = os.time(), {}
    for owner_low, buddies in pairs(by_owner) do
        local owner = GetPlayerByGUID(GetPlayerGUID(owner_low))
        if owner and owner:IsInWorld() and owner:GetGMRank() > 0 then
            out[#out + 1] = line_of(now, owner_low, owner, "owner")
            for _, low in ipairs(buddies) do
                local b = GetPlayerByGUID(GetPlayerGUID(low))
                if b and b:IsInWorld() then out[#out + 1] = line_of(now, owner_low, b, "buddy") end
            end
        end
    end
    if #out == 0 then return end
    local f = io.open(LOG_PATH, "a")
    if not f then
        print(TAG .. "ERROR: cannot open " .. LOG_PATH .. " (is tmp/shared-memory linked?); this sample is lost")
        return
    end
    f:write(table.concat(out))
    f:close()
end

CreateLuaEvent(sample, EVERY_MS, 0)
