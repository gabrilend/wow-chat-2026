require "movement" -- for spawning the chests at specific positions

Treasure = { chests = {} }

-- Register in package.loaded so require() is a no-op after ALE loads this
-- Must be AFTER Treasure table is created so require() returns the module
package.loaded["treasure"] = Treasure

-- {{{ Per-Player Queue System
-- Items are immediately distributed to player queues when added to global pool
-- Each player has a personal queue that injects into their next chest spawn
-- Despawned chest items return to global pool and redistribute

Treasure.globalPool     = {}  -- items awaiting distribution: { {itemId, itemLevel, count}, ... }
Treasure.playerQueues   = {}  -- [playerGUID] = { {itemId, count}, ... }
Treasure.activeChests   = {}  -- [chestGUID] = { queueItems = {}, spawnerGUID = guid, spawnTime = time }
Treasure.distributionIndex = 0  -- mancala rotation counter

-- Level range for item-to-player matching (item level +/- this value matches player)
local ITEM_LEVEL_RANGE = 3

-- {{{ Treasure.getOnlinePlayers
-- Get list of online player GUIDs with their levels
function Treasure.getOnlinePlayers()
    local players = {}
    -- GetPlayersInWorld returns all online players
    local worldPlayers = GetPlayersInWorld()
    if worldPlayers then
        for _, player in ipairs(worldPlayers) do
            local guid = player:GetGUIDLow()
            players[guid] = {
                player = player,
                level  = player:GetLevel(),
                guid   = guid,
            }
        end
    end
    return players
end -- }}}

-- {{{ Treasure.findEligiblePlayer
-- Find a player whose level matches the item level using mancala distribution
-- Prefers players who have received fewer items (fairer distribution)
-- Returns playerGUID or nil if no eligible players
function Treasure.findEligiblePlayer(itemLevel)
    local players = Treasure.getOnlinePlayers()
    local eligible = {}

    for guid, info in pairs(players) do
        local levelDiff = math.abs(info.level - itemLevel)
        if levelDiff <= ITEM_LEVEL_RANGE then
            -- Count items already in this player's queue
            local queueSize = Treasure.playerQueues[guid] and #Treasure.playerQueues[guid] or 0
            table.insert(eligible, { guid = guid, queueSize = queueSize })
        end
    end

    if #eligible == 0 then
        return nil
    end

    -- Sort by queue size (ascending) - players with fewer items first
    table.sort(eligible, function(a, b) return a.queueSize < b.queueSize end)

    -- Find all players tied for lowest queue size
    local minQueueSize = eligible[1].queueSize
    local tied = {}
    for _, entry in ipairs(eligible) do
        if entry.queueSize == minQueueSize then
            table.insert(tied, entry.guid)
        end
    end

    -- Mancala rotation among tied players
    Treasure.distributionIndex = Treasure.distributionIndex + 1
    local selectedIdx = ((Treasure.distributionIndex - 1) % #tied) + 1
    return tied[selectedIdx]
end -- }}}

-- {{{ Treasure.distributeToQueue
-- Distribute a single item to an eligible player's queue
-- Returns true if distributed, false if no eligible player
function Treasure.distributeToQueue(itemId, itemLevel, count)
    local targetGUID = Treasure.findEligiblePlayer(itemLevel)

    if not targetGUID then
        -- No eligible player - item stays in global pool
        return false
    end

    -- Initialize queue if needed
    if not Treasure.playerQueues[targetGUID] then
        Treasure.playerQueues[targetGUID] = {}
    end

    -- Add to player's queue
    table.insert(Treasure.playerQueues[targetGUID], {
        itemId = itemId,
        count  = count or 1,
    })

    local player = GetPlayerByGUID(targetGUID)
    local playerName = player and player:GetName() or "unknown"
    print("[Treasure] Queued item " .. itemId .. " (lvl " .. itemLevel .. ") for " .. playerName)

    return true
end -- }}}

-- {{{ Treasure.processGlobalPool
-- Try to distribute all items in global pool to player queues
-- Called periodically and when new players log in
function Treasure.processGlobalPool()
    local remaining = {}

    for _, item in ipairs(Treasure.globalPool) do
        local distributed = Treasure.distributeToQueue(item.itemId, item.itemLevel, item.count)
        if not distributed then
            -- Keep in global pool for later
            table.insert(remaining, item)
        end
    end

    Treasure.globalPool = remaining

    if #remaining > 0 then
        print("[Treasure] " .. #remaining .. " items waiting in global pool (no eligible players)")
    end
end -- }}}

-- {{{ Treasure.addToPool
-- Add an item to the system - immediately tries to distribute to a player queue
function Treasure.addToPool(itemId, itemLevel, count)
    count = count or 1
    itemLevel = itemLevel or 1  -- default to level 1 if not specified

    -- Try to distribute immediately
    local distributed = Treasure.distributeToQueue(itemId, itemLevel, count)

    if not distributed then
        -- No eligible player online - add to global pool for later
        table.insert(Treasure.globalPool, {
            itemId    = itemId,
            itemLevel = itemLevel,
            count     = count,
        })
        print("[Treasure] Item " .. itemId .. " (lvl " .. itemLevel .. ") added to global pool (no eligible players)")
    end
end -- }}}

-- {{{ Treasure.getPlayerQueue
-- Get items queued for a specific player, then clear the queue
function Treasure.getPlayerQueue(playerGUID)
    local queue = Treasure.playerQueues[playerGUID] or {}
    Treasure.playerQueues[playerGUID] = {}  -- clear after retrieval
    return queue
end -- }}}

-- {{{ Treasure.returnToPool
-- Return items from a despawned chest back to global pool
-- These will be immediately redistributed to player queues
function Treasure.returnToPool(chestGUID)
    local chestData = Treasure.activeChests[chestGUID]
    if not chestData or not chestData.queueItems then
        return
    end

    local returned = 0
    for _, item in ipairs(chestData.queueItems) do
        -- Re-add to pool (will redistribute immediately)
        Treasure.addToPool(item.itemId, item.itemLevel or 1, item.count)
        returned = returned + 1
    end

    if returned > 0 then
        print("[Treasure] Returned " .. returned .. " items from despawned chest to pool")
    end

    -- Clean up object variable data to prevent memory leaks (Issue 332)
    if ObjectVariables and ObjectVariables.cleanupGameObjectByLocation then
        ObjectVariables.cleanupGameObjectByLocation(
            chestData.mapId,
            chestData.instanceId,
            chestGUID
        )
    end

    Treasure.activeChests[chestGUID] = nil
end -- }}}
-- }}}

-- {{{ Chest Templates
-- Using custom empty-loot chest IDs (900001-900037)
-- These have data1=0 so holder sees truly empty chest
-- Loot is injected via Lua when searcher opens
-- See: source-beta/data/sql/custom/db_world/custom-empty-loot-chests.sql

local chests = { { id = 900001, minLevel = 1,  maxLevel = 5  },  -- Battered Chest (was 2843)
                 { id = 900002, minLevel = 3,  maxLevel = 7  },  -- Tattered Chest (was 106318)
                 { id = 900003, minLevel = 6,  maxLevel = 10 },  -- Solid Chest (was 106319)
                 { id = 900004, minLevel = 11, maxLevel = 15 },  -- Large Iron Bound (was 75293)
                 { id = 900005, minLevel = 16, maxLevel = 21 },  -- Large Solid (was 75298)
                 { id = 900006, minLevel = 21, maxLevel = 27 },  -- Large Mithril (was 74448)
                 { id = 900007, minLevel = 27, maxLevel = 31 },  -- Large Darkwood (was 75299)
                 { id = 900008, minLevel = 30, maxLevel = 35 },  -- Large Battered (was 75300)
                 { id = 900009, minLevel = 36, maxLevel = 41 },  -- Captain's Chest (was 142184)
                 { id = 900010, minLevel = 36, maxLevel = 40 },  -- Uldaman (was 141979)
                 { id = 900011, minLevel = 41, maxLevel = 49 },  -- Arena (was 179697)
                 { id = 900012, minLevel = 40, maxLevel = 80 },  -- Vendor Trash (was 190552)
                 { id = 900013, minLevel = 50, maxLevel = 60 },  -- Felwood (was 153464)
                 { id = 900014, minLevel = 54, maxLevel = 59 },  -- Dire Maul (was 179564)
                 { id = 900015, minLevel = 55, maxLevel = 80 },  -- Silithus (was 179528)
                 { id = 900016, minLevel = 57, maxLevel = 62 },  -- Outland 1 (was 181804)
                 { id = 900017, minLevel = 60, maxLevel = 60 },  -- Ramparts (was 185168)
                 { id = 900018, minLevel = 60, maxLevel = 64 },  -- Outland 2 (was 184930)
                 { id = 900019, minLevel = 64, maxLevel = 66 },  -- Outland 3 (was 184933)
                 { id = 900020, minLevel = 66, maxLevel = 68 },  -- Outland 4 (was 184937)
                 { id = 900021, minLevel = 68, maxLevel = 74 },  -- Outland 5 (was 184941)
                 { id = 900022, minLevel = 69, maxLevel = 72 },  -- TBC Green (was 186744)
                 { id = 900023, minLevel = 69, maxLevel = 71 },  -- Mechanar (was 184465)
                 { id = 900024, minLevel = 72, maxLevel = 79 },  -- Zul'Aman (was 186672)
                 { id = 900025, minLevel = 72, maxLevel = 79 },  -- TBC Cloaks (was 187892)
                 { id = 900026, minLevel = 72, maxLevel = 79 },  -- TBC Amulets (was 188191)
                 { id = 900027, minLevel = 76, maxLevel = 79 },  -- HoS Normal (was 190586)
                 { id = 900028, minLevel = 80, maxLevel = 80 },  -- HoS Heroic (was 193996)
                 { id = 900029, minLevel = 78, maxLevel = 80 },  -- CoS (was 190663)
                 { id = 900030, minLevel = 80, maxLevel = 80 },  -- Rusted Footlocker (was 193402)
                 { id = 900031, minLevel = 80, maxLevel = 80 },  -- Oculus (was 193603)
                 { id = 900032, minLevel = 80, maxLevel = 80 },  -- Eye of Eternity (was 193905)
                 { id = 900033, minLevel = 80, maxLevel = 80 },  -- Ulduar 1 (was 194331)
                 { id = 900034, minLevel = 80, maxLevel = 80 },  -- Cache of Winter (was 194308)
                 { id = 900035, minLevel = 80, maxLevel = 80 },  -- Rare Cache (was 194201)
                 { id = 900036, minLevel = 80, maxLevel = 80 },  -- Four Horsemen (was 181366)
                 { id = 900037, minLevel = 1,  maxLevel = 80 },  -- Dinosaur Bone (was 2849)
               }
Treasure.chests = chests
-- }}}

-- public functions
-- used to add a treasure to a player's queue.
function Treasure.addTreasure(playerID, chestID)
    local player = GetPlayerByGUID(playerID)
    local playerQueue = player:GetData("treasureChests")
    table.insert(playerQueue, chestID)
    player:SetData("treasureChests", playerQueue)
end

-- {{{ Treasure.spawnTreasure
-- Spawns a treasure chest for the player and injects their queued items
function Treasure.spawnTreasure(player)
    local treasureMinDist = 20
    local treasureMaxDist = 35
    local chestQueue      = player:GetData("treasureChests")
    local next            = next

    if chestQueue == nil or next(chestQueue) == nil then
        Treasure.regenerateQueue(player)
        Treasure.spawnTreasure(player)
        return
    end

    local chestID   = Treasure.getRandomChestFromQueue(player:GetGUID())
    local playerX, playerY, playerZ, playerO = player:GetLocation()
    local playerMap = player:GetMap()

    -- Try to find valid spawn position
    local x, y, z
    local tries = 0
    repeat
        tries = tries + 1
        x, y = Movement.getPlusSpawnPosition(playerX, playerY, treasureMinDist, treasureMaxDist)
        z = playerMap:GetHeight(x, y)
    until z ~= nil or tries >= 5

    if not z then
        print("[Treasure] Could not find valid terrain for chest spawn")
        return
    end

    local o     = math.random(0, 6.28)
    local chest = player:SummonGameObject(chestID, x, y, z, o, 0)

    if not chest then
        print("[Treasure] Failed to spawn chest " .. chestID)
        return
    end

    player:SendBroadcastMessage("Treasure!")
    print("[Treasure] Spawning chest " .. chestID .. " for " .. player:GetName())

    -- Get this player's queued items but DON'T inject yet
    -- Loot is injected when a SEARCHER opens, not the holder
    local playerGUID  = player:GetGUIDLow()
    local queuedItems = Treasure.getPlayerQueue(playerGUID)
    local chestGUID   = chest:GetGUIDLow()

    -- Track this chest with PENDING loot (not injected yet)
    -- ChestVulnerability system will inject loot when a searcher opens
    Treasure.activeChests[chestGUID] = {
        chestID      = chestID,
        spawnerGUID  = playerGUID,
        spawnTime    = os.time(),
        queueItems   = queuedItems,  -- track for recycling if despawned
        pendingLoot  = queuedItems,  -- loot waiting to be injected by searcher
        lootInjected = false,        -- flag: has loot been injected yet?
        -- Location data for ObjectVariables cleanup (Issue 332)
        mapId        = chest:GetMapId(),
        instanceId   = chest:GetInstanceId(),
    }

    print("[Treasure] Chest spawned with " .. #queuedItems .. " pending items (holder will see empty)")
end -- }}}

-- {{{ Treasure.generateBaseLoot
-- Generate level-appropriate base loot for a chest
-- Called when searcher opens, generates gold + items based on chest level
function Treasure.generateBaseLoot(chest, chestData)
    local loot = {}

    -- Find chest level range from our chest table
    local chestId = chestData.chestID
    local minLevel, maxLevel = 1, 20
    for _, c in ipairs(Treasure.chests) do
        if c.id == chestId then
            minLevel = c.minLevel
            maxLevel = c.maxLevel
            break
        end
    end

    -- Generate gold based on level (copper)
    -- Base: 10-50 copper per level
    local avgLevel  = (minLevel + maxLevel) / 2
    local goldMin   = math.floor(avgLevel * 10)
    local goldMax   = math.floor(avgLevel * 50)
    local goldAmount = math.random(goldMin, goldMax)

    -- Add gold (in copper) - use item 0 for money? Or add via different method
    -- Note: AddLoot doesn't support money directly, would need AddMoney
    -- For now, we'll give a vendor trash item worth the gold
    -- TODO: Find better way to add gold to chest loot

    -- Generate a random green item for higher level chests
    -- For level 1-20, use simple starter items
    -- This is placeholder - in production would query item_template by level
    if avgLevel <= 20 then
        -- Low level: give some basic useful items
        local lowLevelItems = {
            { id = 4496,  name = "Small Brown Pouch" },       -- 6 slot bag
            { id = 117,   name = "Tough Jerky" },             -- food
            { id = 159,   name = "Refreshing Spring Water" }, -- water
            { id = 2589,  name = "Linen Cloth" },             -- crafting
            { id = 2592,  name = "Wool Cloth" },              -- crafting
            { id = 774,   name = "Malachite" },               -- gem
            { id = 818,   name = "Tigerseye" },               -- gem
            { id = 1210,  name = "Shadowgem" },               -- gem
            { id = 2835,  name = "Rough Stone" },             -- crafting
            { id = 2836,  name = "Coarse Stone" },            -- crafting
        }

        -- 50% chance for an item
        if math.random() < 0.5 then
            local item = lowLevelItems[math.random(#lowLevelItems)]
            table.insert(loot, { itemId = item.id, count = math.random(1, 3) })
        end

        -- 30% chance for extra gold via vendor trash
        if math.random() < 0.3 then
            -- Poor quality vendor items
            local vendorTrash = {
                { id = 1179, name = "Ice Cold Milk" },
                { id = 4540, name = "Tough Hunk of Bread" },
            }
            local trash = vendorTrash[math.random(#vendorTrash)]
            table.insert(loot, { itemId = trash.id, count = math.random(1, 5) })
        end
    end

    return loot
end -- }}}

-- {{{ Treasure.injectPendingLoot
-- Called by ChestVulnerability when a searcher opens a tracked chest
-- Injects the pending loot items AND generated base loot into the chest
function Treasure.injectPendingLoot(chest)
    local chestGUID  = chest:GetGUIDLow()
    local chestData  = Treasure.activeChests[chestGUID]

    if not chestData then
        return false  -- not a tracked treasure chest
    end

    if chestData.lootInjected then
        return true  -- already injected
    end

    -- Generate base loot for this chest level
    local baseLoot = Treasure.generateBaseLoot(chest, chestData)
    for _, item in ipairs(baseLoot) do
        chest:AddLoot(item.itemId, item.count)
        print("[Treasure] Generated base loot: item " .. item.itemId .. " x" .. item.count)
    end

    -- Inject pending loot from player queue
    local pendingLoot = chestData.pendingLoot or {}
    for _, item in ipairs(pendingLoot) do
        chest:AddLoot(item.itemId, item.count)
        print("[Treasure] Injected queued item " .. item.itemId .. " x" .. item.count)
    end

    chestData.lootInjected = true
    print("[Treasure] Loot injected for chest " .. chestGUID .. " (" .. #baseLoot .. " base + " .. #pendingLoot .. " queued)")
    return true
end -- }}}

-- {{{ Treasure.isTrackedChest
-- Check if a chest is one we spawned (for holder/searcher logic)
function Treasure.isTrackedChest(chest)
    local chestGUID = chest:GetGUIDLow()
    return Treasure.activeChests[chestGUID] ~= nil
end -- }}}

-- {{{ Treasure.setupTreasure
-- Called on login to set up chest queue and try distributing global pool items
function Treasure.setupTreasure(_event, player)
    local playerQueue = {}
    local playerLevel = player:GetLevel()

    for i, chest in pairs(Treasure.chests) do
        if playerLevel >= chest.minLevel and playerLevel <= chest.maxLevel then
            table.insert(playerQueue, chest.id)
        end
    end
    player:SetData("treasureChests", playerQueue)

    -- Process global pool - new player might be eligible for waiting items
    Treasure.processGlobalPool()
end -- }}}

-- can be used to either create a new queue from scratch
-- or to insert objects into a currently existing queue - quest items?
function Treasure.regenerateQueue(player)
    local playerQueue = player:GetData("treasureChests")
    local playerLevel = player:GetLevel()

    for i, chest in pairs(Treasure.chests) do
        if playerLevel >= chest.minLevel and playerLevel <= chest.maxLevel then
            table.insert(playerQueue, chest.id)
        end
    end
    player:SetData("treasureChests", playerQueue)
end

function Treasure.getRandomChestFromQueue(playerID)
    local player      = GetPlayerByGUID(playerID)
    local playerQueue = player:GetData("treasureChests")
    local chestID     = table.remove(playerQueue, math.random(#playerQueue))
    player:SetData("treasureChests", playerQueue)
    return chestID
end


-- {{{ Treasure.onLootItem
-- Track items looted from chests - remove from chest tracking so they don't recycle
function Treasure.onLootItem(event, player, item, count)
    local itemId   = item:GetEntry()
    local itemName = item:GetName()
    print("[Treasure] " .. player:GetName() .. " looted: " .. itemName .. " (ID: " .. itemId .. ") x" .. count)

    -- Find which active chest this item came from and remove it from queueItems
    -- This prevents looted items from being recycled on despawn
    for chestGUID, chestData in pairs(Treasure.activeChests) do
        if chestData.queueItems then
            for i, queuedItem in ipairs(chestData.queueItems) do
                if queuedItem.itemId == itemId then
                    table.remove(chestData.queueItems, i)
                    print("[Treasure] Removed looted item " .. itemId .. " from chest tracking")
                    break
                end
            end
        end
    end
end -- }}}

-- {{{ Treasure.onPlayerLogout
-- Clean up player queue when they log out (items return to global pool)
function Treasure.onPlayerLogout(event, player)
    local playerGUID = player:GetGUIDLow()
    local queue      = Treasure.playerQueues[playerGUID]

    if queue and #queue > 0 then
        print("[Treasure] Player " .. player:GetName() .. " logged out with " .. #queue .. " queued items, returning to pool")
        for _, item in ipairs(queue) do
            -- Return to global pool (will be redistributed to other players)
            table.insert(Treasure.globalPool, {
                itemId    = item.itemId,
                itemLevel = item.itemLevel or player:GetLevel(),  -- estimate level from player
                count     = item.count,
            })
        end
        Treasure.playerQueues[playerGUID] = nil

        -- Try to redistribute to remaining players
        Treasure.processGlobalPool()
    end
end -- }}}

-- {{{ Treasure.handleChat
-- Test commands for treasure pool
-- #pooladd <itemId> <itemLevel> [count] - add item to pool
-- #poolsize - show pool size and queue info
-- #myqueue - show items in your queue
function Treasure.handleChat(event, player, message)
    if message:sub(1, 8) == "#pooladd" then
        local args = message:sub(10)
        local itemId, itemLevel, count = args:match("(%d+)%s+(%d+)%s*(%d*)")
        itemId    = tonumber(itemId)
        itemLevel = tonumber(itemLevel)
        count     = tonumber(count) or 1
        if itemId and itemLevel then
            Treasure.addToPool(itemId, itemLevel, count)
            player:SendBroadcastMessage("Added item " .. itemId .. " (lvl " .. itemLevel .. ") x" .. count .. " to system")
        else
            player:SendBroadcastMessage("Usage: #pooladd <itemId> <itemLevel> [count]")
        end
        return
    end

    if message == "#poolsize" then
        local globalCount = #Treasure.globalPool
        local queueCount  = 0
        for _, queue in pairs(Treasure.playerQueues) do
            queueCount = queueCount + #queue
        end
        player:SendBroadcastMessage("Global pool: " .. globalCount .. " | Total queued: " .. queueCount)
        return
    end

    if message == "#myqueue" then
        local playerGUID = player:GetGUIDLow()
        local queue      = Treasure.playerQueues[playerGUID] or {}
        if #queue == 0 then
            player:SendBroadcastMessage("Your treasure queue is empty")
        else
            player:SendBroadcastMessage("Your queue has " .. #queue .. " items:")
            for i, item in ipairs(queue) do
                player:SendBroadcastMessage("  " .. i .. ". Item " .. item.itemId .. " x" .. item.count)
            end
        end
        return
    end

    if message == "#treasure" then
        Treasure.spawnTreasure(player)
    end
end -- }}}

PLAYER_EVENT_ON_LOGIN     = 3
PLAYER_EVENT_ON_LOGOUT    = 4
PLAYER_EVENT_ON_LOOT_ITEM = 32
PLAYER_EVENT_ON_CHAT      = 18
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, Treasure.setupTreasure)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGOUT, Treasure.onPlayerLogout)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOOT_ITEM, Treasure.onLootItem)
RegisterPlayerEvent(PLAYER_EVENT_ON_CHAT, Treasure.handleChat)

print("[Treasure] Treasure system loaded with per-player queue distribution")


