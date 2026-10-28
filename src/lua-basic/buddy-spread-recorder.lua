--------------------------------------------------------------------------------
-- buddy-spread-recorder.lua (issue 617e13, step 1: measure first)
--
-- For a general audience: buddies are meant to spread out through the
-- questing sub-zone their owner is in, follow the owner from one sub-zone
-- to the next, and not wander back. The owner, 2026-10-26: "pathfinding is
-- mega bugged. Can you create some tests and do some dynamic measurements
-- to try and get the behavior that we want?". This writes down, every few
-- seconds, where every owner and each of their buddies stands, so what
-- they do can be measured afterwards (scripts/measure-buddy-spread turns
-- the record into numbers). It changes nothing in game.
--
-- Recorded only on a Debug build of the server, and only for owners who
-- are game masters (the owner, 2026-10-27: "we will only record our paths
-- in debug mode. and then, only for GMs"): a Debug build is the one in use
-- while the movement is worked on, and a game master's walk is a test.
-- (Until 2026-10-27 a switch file, tmp/shared-memory/buddy-spread.on,
-- turned it on and off.)
-- One line per character per sample, tab-separated, appended to
-- tmp/shared-memory/buddy-spread.tsv (RAM):
--   unix time (seconds), owner guid, character guid, name, role ("owner"
--   or "buddy"), map, zone, area (sub-zone), x, y, z, fighting (0/1),
--   dead (0/1)
-- A buddy is recorded only while its owner (a game master) is in the world.
--------------------------------------------------------------------------------

local DIR       = "/mnt/kaun/wow-chat-2026"
local LOG_PATH  = DIR .. "/tmp/shared-memory/buddy-spread.tsv"
local EVERY_MS  = 5000                    -- one sample each 5 seconds
local TAG       = "[buddy-spread] "

-- {{{ the build: Debug or not, read once at load
-- The compile writes the installed server's build type beside it
-- (installed-files-<profile>/bin/.build-type: "Debug" for --debug builds).
--   "Debug": recording, for game masters
--   anything else, or no file: nothing is recorded (said once, at load)
local DEBUG_BUILD = false
do
    local pf = io.open(DIR .. "/.profile")
    local profile = pf and pf:read("*l"); if pf then pf:close() end
    local bf = profile and io.open(DIR .. "/installed-files-" .. profile .. "/bin/.build-type")
    DEBUG_BUILD = bf ~= nil and bf:read("*l") == "Debug"
    if bf then bf:close() end
    if not DEBUG_BUILD then print(TAG .. "not a Debug build: buddy paths are not recorded") end
end
-- }}}

-- {{{ local function line_of
-- One character's line (text), for owner `owner_low`.
local function line_of(now, owner_low, p, role)
    local x, y, z = p:GetLocation()
    return string.format("%d\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%.1f\t%.1f\t%.1f\t%d\t%d\n",
        now, owner_low, p:GetGUIDLow(), p:GetName(), role, p:GetMapId(), p:GetZoneId(), p:GetAreaId(),
        x, y, z, p:IsInCombat() and 1 or 0, p:IsDead() and 1 or 0)
end
-- }}}

-- {{{ local function sample
-- Every owner in the world with buddies, and each of their buddies in the
-- world: one line each. The roster is read once a sample (owner -> buddies).
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
        if owner and owner:IsInWorld() and owner:GetGMRank() > 0 then   -- game masters' walks only
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
-- }}}

CreateLuaEvent(sample, EVERY_MS, 0)       -- 0: for ever
