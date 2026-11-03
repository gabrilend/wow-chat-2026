
local DIR       = "/mnt/kaun/wow-chat-2026"
local LOG_PATH  = DIR .. "/tmp/shared-memory/world-positions.tsv"
local EVERY_MS  = 5000
local KIND_MS   = 60000
local TAG       = "[world-positions] "

local DEBUG_BUILD = false
do
    local pf = io.open(DIR .. "/.profile")
    local profile = pf and pf:read("*l"); if pf then pf:close() end
    local bf = profile and io.open(DIR .. "/installed-files-" .. profile .. "/bin/.build-type")
    DEBUG_BUILD = bf ~= nil and bf:read("*l") == "Debug"
    if bf then bf:close() end
    if not DEBUG_BUILD then print(TAG .. "not a Debug build: positions are not recorded") end
end

local kind_of, owner_of, kinds_read_at = {}, {}, 0
local function read_kinds(now_ms)
    if now_ms - kinds_read_at < KIND_MS and kinds_read_at > 0 then return end
    kinds_read_at = now_ms
    kind_of, owner_of = {}, {}
    local q = CharDBQuery("SELECT buddy, owner FROM buddy_roster WHERE buddy <> 0")
    if q then
        repeat
            kind_of[q:GetUInt32(0)] = "buddy"
            owner_of[q:GetUInt32(0)] = q:GetUInt32(1)
        until not q:NextRow()
    end
    local b = CharDBQuery("SELECT c.guid FROM characters c JOIN acore_auth.account a ON a.id = c.account " ..
                          "WHERE c.online = 1 AND a.username LIKE 'RNDBOT%'")
    if b then
        repeat kind_of[b:GetUInt32(0)] = kind_of[b:GetUInt32(0)] or "bot" until not b:NextRow()
    end
end

local function sample()
    if not DEBUG_BUILD then return end
    local now = os.time()
    read_kinds(now * 1000)
    local out = {}
    for _, p in ipairs(GetPlayersInWorld() or {}) do
        if p:IsInWorld() then
            local low = p:GetGUIDLow()
            local x, y, z = p:GetLocation()
            out[#out + 1] = string.format("%d\t%d\t%s\t%s\t%d\t%d\t%d\t%.1f\t%.1f\t%.1f\t%d\t%d\t%d\n",
                now, low, p:GetName(), kind_of[low] or "player", p:GetMapId(), p:GetZoneId(), p:GetAreaId(),
                x, y, z, p:IsInCombat() and 1 or 0, p:IsDead() and 1 or 0, owner_of[low] or 0)
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
