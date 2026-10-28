--------------------------------------------------------------------------------
-- world-positions-recorder.lua (issue 617e14a)
--
-- For a general audience: the owner wants to watch the whole world from
-- above, a picture per zone with a dot for every character (617e14: "dots
-- for where all the players are ... We should watch the pattern of bots").
-- This writes down, every five seconds, where every character in the world
-- stands, people and bots alike; scripts/render-zone draws it. It changes
-- nothing in game.
--
-- Recorded only on a Debug build of the server, as the buddy spread record
-- is (the owner, 2026-10-27: "we will only record our paths in debug
-- mode"); everyone, not only game masters, so bots with no player can be
-- watched (617e14a's first open question asks if that is right).
-- One line per character per sample, tab-separated, appended to
-- tmp/shared-memory/world-positions.tsv (RAM):
--   unix time (seconds), character guid, name, kind, map, zone, area
--   (sub-zone), x, y, z, fighting (0/1), dead (0/1), owner guid (a buddy's
--   owner; 0 for anyone else)
-- kind: "player" (a person's character), "buddy" (on the buddy roster),
-- "bot" (a random bot: an account named RNDBOT...).
--------------------------------------------------------------------------------

local DIR       = "/mnt/kaun/wow-chat-2026"
local LOG_PATH  = DIR .. "/tmp/shared-memory/world-positions.tsv"
local EVERY_MS  = 5000                    -- one sample each 5 seconds
local KIND_MS   = 60000                   -- who is a buddy or a bot, read again this often
local TAG       = "[world-positions] "

-- {{{ the build: Debug or not, read once at load
-- The compile writes the installed server's build type beside it
-- (installed-files-<profile>/bin/.build-type: "Debug" for --debug builds).
--   "Debug": recording
--   anything else, or no file: nothing is recorded (said once, at load)
local DEBUG_BUILD = false
do
    local pf = io.open(DIR .. "/.profile")
    local profile = pf and pf:read("*l"); if pf then pf:close() end
    local bf = profile and io.open(DIR .. "/installed-files-" .. profile .. "/bin/.build-type")
    DEBUG_BUILD = bf ~= nil and bf:read("*l") == "Debug"
    if bf then bf:close() end
    if not DEBUG_BUILD then print(TAG .. "not a Debug build: positions are not recorded") end
end
-- }}}

-- {{{ who is what
-- kind_of[guid] = "buddy" or "bot"; owner_of[buddy guid] = owner guid.
-- Anyone not in it is a person's character. Read every KIND_MS.
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
-- }}}

-- {{{ local function sample
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
-- }}}

CreateLuaEvent(sample, EVERY_MS, 0)       -- 0: for ever
