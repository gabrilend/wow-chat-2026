--------------------------------------------------------------------------------
-- scripts/lib/toy-world.lua - a pretend game world for testing beta's Lua
-- scripts without a server.
--
-- For a general audience: beta's scripts (the ambush, travellers) call a
-- few dozen game functions: where is the player, is there ground here,
-- spawn a creature, run this again in a second. This module gives them
-- pretend versions of exactly those, on plain tables, with a clock that a
-- test winds forward by hand. A test loads it, loads the real script, and
-- plays scenes. It checks a script's own decisions, not how the game would
-- carry them out. Used by scripts/test-ambush and scripts/test-travel.
-- Moved out of test-ambush on 2026-10-17 when the traveller test needed
-- the same world.
--
-- Time is in milliseconds (number). Every object keeps its SetData values
-- in its own table, and a player's are wiped at logout, as the
-- object-variables extension does in the game.
--
-- Returns a table:
--   World            { now, events, players, nextGuid, answer }
--   schedule(owner, fn, delay), advance(ms), pending(owner, fn)
--   new_map(id, height, water), FLAT
--   new_creature(entry, map, x, y, z), new_player(name, guidLow)
--   login(p), logout(p), handlers (event number -> list of functions)
-- and installs the game functions the scripts call as globals.
--------------------------------------------------------------------------------

local Toy = {}

local World = { now = 0, events = {}, players = {}, nextGuid = 1, log = {} }

-- {{{ local function schedule
-- One pending timed call: { at = ms (number), fn = function, owner = object }.
local function schedule(owner, fn, delay)
    World.events[#World.events + 1] = { at = World.now + delay, fn = fn, owner = owner }
end
-- }}}

-- {{{ local function advance
-- Runs every pending call due within `ms`, in time order, skipping calls
-- whose owner has left the world (a despawned monster, a logged-out
-- player), as the game drops an object's timers with the object.
local function advance(ms)
    local stop = World.now + ms
    while true do
        table.sort(World.events, function(a, b) return a.at < b.at end)
        local e = World.events[1]
        if not e or e.at > stop then break end
        table.remove(World.events, 1)
        World.now = e.at
        if not e.owner.gone then e.fn(0, 0, 1, e.owner) end
    end
    World.now = stop
end
-- }}}

-- {{{ local function pending
-- How many calls of `fn` are waiting for `owner`.
local function pending(owner, fn)
    local n = 0
    for _, e in ipairs(World.events) do
        if e.owner == owner and (fn == nil or e.fn == fn) then n = n + 1 end
    end
    return n
end
-- }}}

-- {{{ local function data_methods
-- GetData/SetData on a plain table, as ObjectVariables.ext gives objects.
local function data_methods(obj)
    obj.store = {}
    function obj:GetData(k) if k == nil then return self.store end return self.store[k] end
    function obj:SetData(k, v) self.store[k] = v end
end
-- }}}

-- {{{ local function new_map
-- A map: `height(x, y)` gives the ground (a number, or nil for none);
-- `water(x, y)` says whether a spot is water (boolean).
local function new_map(id, height, water)
    local map = { id = id, height = height, water = water or function() return false end }
    function map:GetHeight(x, y) return self.height(x, y) end
    function map:GetMapId() return self.id end
    return map
end
-- }}}

local FLAT = new_map(0, function() return 0 end)

-- {{{ local function new_creature
local function new_creature(entry, map, x, y, z)
    local c = { entry = entry, map = map, x = x, y = y, z = z, dead = false, combat = false, gone = false }
    data_methods(c)
    World.nextGuid = World.nextGuid + 1
    c.guid = World.nextGuid
    function c:GetEntry() return self.entry end
    function c:GetLevel() return 10 end
    function c:GetMap() return self.map end
    function c:GetLocation() return self.x, self.y, self.z, 0 end
    function c:GetX() return self.x end
    function c:GetY() return self.y end
    function c:IsInWater() return self.map.water(self.x, self.y) end
    function c:NearTeleport(nx, ny, nz) self.x, self.y, self.z = nx, ny, nz end
    function c:DespawnOrUnsummon() self.gone = true end
    function c:IsDead() return self.dead end
    function c:IsInCombat() return self.combat end
    function c:RegisterEvent(fn, delay) schedule(self, fn, delay) end
    function c:MoveTo(_, nx, ny, nz) self.x, self.y, self.z = nx, ny, nz end
    function c:MoveRandom() end
    function c:MoveClear() self.moveCleared = (self.moveCleared or 0) + 1 end
    function c:MoveHome() end
    function c:AttackStop() end
    function c:AttackStart() self.combat = true end
    function c:ClearInCombat() self.combat = false end
    function c:SetAggroEnabled(v) self.aggro = v end
    function c:CanAggro() return false end
    function c:SetHomePosition() end
    function c:GetSpeed() return 1 end
    return c
end
-- }}}

-- {{{ local function new_player
local function new_player(name, guidLow)
    local p = { name = name, low = guidLow, map = FLAT, x = 0, y = 0, z = 0, o = 0,
                standing = true, dead = false, wet = false, moving = false,
                spawned = {}, gone = true, level = 10 }
    data_methods(p)
    function p:GetName() return self.name end
    function p:GetGUIDLow() return self.low end
    function p:GetGUID() return "player-" .. self.low end
    function p:GetLevel() return self.level end
    function p:IsStandState() return self.standing end
    function p:IsDead() return self.dead end
    function p:IsInWater() return self.wet end
    function p:IsMoving() return self.moving end
    function p:IsInGroup() return false end
    function p:GetLocation() return self.x, self.y, self.z, self.o end
    function p:GetZ() return self.z end
    function p:GetMap() return self.map end
    function p:GetMapId() return self.map.id end
    function p:SendBroadcastMessage() end
    function p:RegisterEvent(fn, delay) schedule(self, fn, delay) end
    function p:SpawnCreature(entry, x, y, z)
        local c = new_creature(entry, self.map, x, y, z)
        self.spawned[#self.spawned + 1] = c
        return c
    end
    return p
end
-- }}}

-- The game calls the script reaches for, by name, as globals.
local handlers = {}
-- {{{ engine globals
function RegisterPlayerEvent(event, fn) handlers[event] = handlers[event] or {}; table.insert(handlers[event], fn) end
function GetPlayerByGUID(guid)
    for _, p in pairs(World.players) do if p:GetGUID() == guid and not p.gone then return p end end
    return nil
end
function GetPlayerByName(name)
    for _, p in pairs(World.players) do if p.name == name and not p.gone then return p end end
    return nil
end
-- The ambush's database question: which creatures fit this level and
-- rank. World.answer[rank] is a list of { entry, min, max } or nil (no rows).
World.answer = {}
function WorldDBQueryAsync(sql, callback)
    local rank = tonumber(sql:match("`rank` = (%d+)"))
    local rows = World.answer[rank]
    if not rows or #rows == 0 then callback(nil) return end
    local i = 1
    local q = {}
    function q:GetUInt32(col)
        local r = rows[i]
        if col == 0 then return r[1] elseif col == 1 then return r[2] elseif col == 2 then return r[3] end
        return rank
    end
    function q:NextRow() i = i + 1; return i <= #rows end
    callback(q)
end
-- }}}

-- {{{ local function login
local function login(p)
    p.gone = false
    World.players[p.low] = p
    for _, fn in ipairs(handlers[3] or {}) do fn(3, p) end
end
-- }}}

-- {{{ local function logout
-- The extension's wipe first, as its handler was registered first.
local function logout(p)
    for _, fn in ipairs(handlers[4] or {}) do fn(4, p) end
    p.store = {}
    p.gone = true
end
-- }}}

-- {{{ extra methods the traveller script uses
-- Creatures: names, walking, facing, sitting, timers removed at despawn,
-- and the nearest player within a range. Players: faction, class, bot-ness.
local base_creature = new_creature
new_creature = function(entry, map, x, y, z)
    local c = base_creature(entry, map, x, y, z)
    c.o, c.stand, c.walking = 0, 0, false
    function c:GetName() return "creature " .. self.entry end
    function c:GetO() return self.o end
    function c:SetSpeed() end
    function c:SetWalk(v) self.walking = v end
    function c:GetStandState() return self.stand end
    function c:SetStandState(s) self.stand = s end
    function c:GetMapId() return self.map.id end
    function c:RemoveEvents()
        for i = #World.events, 1, -1 do if World.events[i].owner == self then table.remove(World.events, i) end end
    end
    function c:GetNearestPlayer(range)
        local best, bestD
        for _, p in pairs(World.players) do
            if not p.gone and p.map == self.map then
                local d = math.sqrt((p.x - self.x) ^ 2 + (p.y - self.y) ^ 2)
                if d <= range and (not bestD or d < bestD) then best, bestD = p, d end
            end
        end
        return best
    end
    return c
end
local base_player = new_player
new_player = function(name, guidLow)
    local p = base_player(name, guidLow)
    p.class, p.horde, p.bot = 1, true, false
    function p:GetClass() return self.class end
    function p:IsHorde() return self.horde end
    function p:IsBot() return self.bot end
    function p:GetO() return self.o end
    function p:SpawnCreature(entry, x, y, z, o, kind, timer)
        local c = new_creature(entry, self.map, x, y, z)
        c.o, c.summonKind, c.summonTimer = o or 0, kind, timer
        self.spawned[#self.spawned + 1] = c
        return c
    end
    return p
end
-- every map in the toy world is found by its number
Toy.maps = { [0] = FLAT }
function GetMapById(id) return Toy.maps[id] or FLAT end
function bit_and(a, b) return bit.band(a, b) end
-- }}}

-- {{{ extra pieces the treasure script uses (added 2026-10-17, issues 402/404)
-- The online list in login order; game objects (chests) with their own
-- timers and the game's removal event; items with the fields the sale
-- rules read; a player's bags and the vendor's buyback tab as the server
-- keeps it (12 slots, the oldest pushed out by a 13th sale, the same item
-- returned by a buyback, everything in it gone at logout; read from
-- Player::AddItemToBuyBackSlot, HandleBuybackItem and _SaveInventory).
World.order = {}              -- players in the order they logged in
local goHandlers = {}         -- [entry] = { [event] = { functions } }
function GetPlayersInWorld()
    local list = {}
    for _, p in ipairs(World.order) do if not p.gone then list[#list + 1] = p end end
    return list
end
function RegisterGameObjectEvent(entry, event, fn)
    goHandlers[entry] = goHandlers[entry] or {}
    goHandlers[entry][event] = goHandlers[entry][event] or {}
    table.insert(goHandlers[entry][event], fn)
end

-- {{{ local function new_gameobject
-- A summoned object: its loot is a list of { itemId, count } as AddLoot
-- received them; RemoveFromWorld fires the removal event (13) once.
local function new_gameobject(entry, map, x, y, z)
    World.nextGuid = World.nextGuid + 1
    local g = { entry = entry, map = map, x = x, y = y, z = z, gone = false, loot = {}, low = World.nextGuid }
    function g:GetEntry() return self.entry end
    function g:GetGUIDLow() return self.low end
    function g:GetMapId() return self.map.id end
    function g:GetInstanceId() return 0 end
    function g:AddLoot(itemId, count) self.loot[#self.loot + 1] = { itemId = itemId, count = count } end
    function g:RegisterEvent(fn, delay) schedule(self, fn, delay) end
    function g:RemoveFromWorld()
        if self.gone then return end
        self.gone = true
        for _, fn in ipairs((goHandlers[self.entry] or {})[13] or {}) do fn(13, self) end
    end
    return g
end
-- }}}

-- {{{ local function new_item
-- An item: entry (number) and the fields the sale rules read, each with a
-- plain default: quality 2 (uncommon), required level 0, item level 10,
-- maximum stack 1, class 2 (weapon), count 1. Its GUID is unique.
local function new_item(entry, f)
    f = f or {}
    World.nextGuid = World.nextGuid + 1
    local it = { entry = entry, quality = f.quality or 2, required = f.required or 0, ilvl = f.ilvl or 10,
                 stack = f.stack or 1, class = f.class or 2, count = f.count or 1, guid = "item-" .. World.nextGuid }
    function it:GetEntry() return self.entry end
    function it:GetGUID() return self.guid end
    function it:GetName() return "item " .. self.entry end
    function it:GetQuality() return self.quality end
    function it:GetRequiredLevel() return self.required end
    function it:GetItemLevel() return self.ilvl end
    function it:GetMaxStackCount() return self.stack end
    function it:GetClass() return self.class end
    function it:GetCount() return self.count end
    return it
end
-- }}}

local player_before_treasure = new_player
new_player = function(name, guidLow)
    local p = player_before_treasure(name, guidLow)
    p.bags, p.buyback, p.objects = {}, {}, {}
    function p:GetItemByGUID(guid)
        for _, it in ipairs(self.bags) do if it.guid == guid then return it end end
        return nil   -- the buyback tab is not searched, as in the game
    end
    function p:SummonGameObject(entry, x, y, z)
        local g = new_gameobject(entry, self.map, x, y, z)
        self.objects[#self.objects + 1] = g
        return g
    end
    return p
end

-- {{{ local function give / sell / buy_back
-- give: an item into the bags. sell: out of the bags, the sell event (74),
-- then into the buyback tab, the oldest pushed out past 12 (the event fires
-- between the two, as patch B006 places it). buy_back: from the tab to the
-- bags, the same item; no event, as in the game.
local function give(p, it) p.bags[#p.bags + 1] = it; return it end
local function sell(p, it)
    for i, b in ipairs(p.bags) do if b == it then table.remove(p.bags, i) break end end
    for _, fn in ipairs(handlers[74] or {}) do fn(74, p, it, nil, it.count) end
    p.buyback[#p.buyback + 1] = it
    if #p.buyback > 12 then table.remove(p.buyback, 1) end
end
local function buy_back(p, it)
    for i, b in ipairs(p.buyback) do
        if b == it then table.remove(p.buyback, i); p.bags[#p.bags + 1] = it; return true end
    end
    return false
end
-- }}}

-- login keeps the order; logout, after the handlers, removes the player's
-- summoned objects and empties the buyback tab, as the game does
local login_before_treasure, logout_before_treasure = login, logout
login = function(p)
    local listed = false
    for _, q in ipairs(World.order) do if q == p then listed = true end end
    if not listed then World.order[#World.order + 1] = p end
    login_before_treasure(p)
end
logout = function(p)
    logout_before_treasure(p)
    for _, g in ipairs(p.objects or {}) do g:RemoveFromWorld() end
    p.objects, p.buyback = {}, {}
end
Toy.new_gameobject, Toy.new_item = new_gameobject, new_item
Toy.give, Toy.sell, Toy.buy_back = give, sell, buy_back
-- }}}

Toy.World, Toy.handlers = World, handlers
Toy.schedule, Toy.advance, Toy.pending = schedule, advance, pending
Toy.new_map, Toy.FLAT = new_map, FLAT
Toy.new_creature, Toy.new_player = function(...) return new_creature(...) end, function(...) return new_player(...) end
Toy.login, Toy.logout = login, logout
return Toy
