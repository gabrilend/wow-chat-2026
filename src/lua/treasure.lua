require "movement" -- for spawning the chests at specific positions

Treasure = { chests = {} }

-- {{{ Global Treasure Pool
-- Items cycle through the world - sold items and unclaimed loot flow here
-- then reappear in future chests. Nothing destroyed, just transceived.
Treasure.pool = {}  -- array of {itemId, count} entries
Treasure.spawnedChests = {}  -- track chests we spawned, keyed by GUID

-- Maximum items to pull from pool per chest spawn
local POOL_ITEMS_PER_CHEST = 2

-- {{{ Treasure.addToPool
-- Add an item to the global treasure pool
function Treasure.addToPool(itemId, count)
    count = count or 1
    table.insert(Treasure.pool, { itemId = itemId, count = count })
    print("[Treasure] Added to pool: item " .. itemId .. " x" .. count .. " (pool size: " .. #Treasure.pool .. ")")
end -- }}}

-- {{{ Treasure.pullFromPool
-- Pull items from pool to add to a chest
-- Returns array of {itemId, count} or empty table
function Treasure.pullFromPool(maxItems)
    local items = {}
    local pulled = 0
    while pulled < maxItems and #Treasure.pool > 0 do
        local item = table.remove(Treasure.pool, 1)  -- FIFO: first in, first out
        table.insert(items, item)
        pulled = pulled + 1
    end
    if pulled > 0 then
        print("[Treasure] Pulled " .. pulled .. " items from pool (remaining: " .. #Treasure.pool .. ")")
    end
    return items
end -- }}}
-- }}}

local chests = { { id = 2843,   minLevel = 1,  maxLevel = 5  },
                 { id = 106318, minLevel = 3,  maxLevel = 7  },
                 { id = 106319, minLevel = 6,  maxLevel = 10 },
                 -- { id = 152608, minLevel = 11, maxLevel = 15 }, -- kolkar's booty, req key
                 { id = 75293,  minLevel = 11, maxLevel = 15 },
                 { id = 75298,  minLevel = 16, maxLevel = 21 },
                 { id = 74448,  minLevel = 21, maxLevel = 27 },
                 { id = 75299,  minLevel = 27, maxLevel = 31 },
                 { id = 75300,  minLevel = 30, maxLevel = 35 },
                 { id = 142184, minLevel = 36, maxLevel = 41 }, -- captain's chest
                 { id = 141979, minLevel = 36, maxLevel = 40 }, -- uldaman chest
                 { id = 179697, minLevel = 41, maxLevel = 49 }, -- arena chest (blue bracers)
                 { id = 190552, minLevel = 40, maxLevel = 80 }, -- chest with vendor trash, sells for gold
                 { id = 153464, minLevel = 50, maxLevel = 60 },
                 { id = 179564, minLevel = 54, maxLevel = 59 }, -- dire maul chest
                 { id = 179528, minLevel = 55, maxLevel = 80 },
                 { id = 181804, minLevel = 57, maxLevel = 62 },
                 { id = 185168, minLevel = 60, maxLevel = 60 }, -- ramparts chest
                 { id = 184930, minLevel = 60, maxLevel = 64 },
                 { id = 184933, minLevel = 64, maxLevel = 66 },
                 { id = 184937, minLevel = 66, maxLevel = 68 },
                 { id = 184941, minLevel = 68, maxLevel = 74 },
                 { id = 186744, minLevel = 69, maxLevel = 72 }, -- random lvl 70 greens
                 { id = 184465, minLevel = 69, maxLevel = 71 }, -- mechanar normal mode
                 { id = 186672, minLevel = 72, maxLevel = 79 }, -- zul'aman rings (level 70)
                 { id = 187892, minLevel = 72, maxLevel = 79 }, -- tbc cloaks
                 { id = 188191, minLevel = 72, maxLevel = 79 }, -- tbc amulets
                 { id = 190586, minLevel = 76, maxLevel = 79 }, -- halls of stone normal mode
                 { id = 193996, minLevel = 80, maxLevel = 80 }, -- halls of stone heroic mode
                 { id = 190663, minLevel = 78, maxLevel = 80 }, -- culling of stratholme - Mal'Ganis
                 { id = 193402, minLevel = 80, maxLevel = 80 }, -- rusted prisoner's footlocker
                 { id = 193603, minLevel = 80, maxLevel = 80 }, -- oculus dungeon gear
                 { id = 193905, minLevel = 80, maxLevel = 80 }, -- eye of eternity raid gear
                 { id = 194331, minLevel = 80, maxLevel = 80 }, -- ulduar raid gear
                 { id = 194308, minLevel = 80, maxLevel = 80 }, --      cache of winter - Ulduar
                 { id = 194201, minLevel = 80, maxLevel = 80 }, -- rare cache of winter - Ulduar
                 { id = 181366, minLevel = 80, maxLevel = 80 }, -- four horseman chest (lvl 80)

                 { id = 2849,   minLevel = 1,  maxLevel = 80 }, -- dinosaur bone
               }
Treasure.chests = chests

-- public functions
-- used to add a treasure to a player's queue.
function Treasure.addTreasure(playerID, chestID)
    local player = GetPlayerByGUID(playerID)
    local playerQueue = player:GetData("treasureChests")
    table.insert(playerQueue, chestID)
    player:SetData("treasureChests", playerQueue)
end

-- makes treasure for the player!
function Treasure.spawnTreasure(player)
    local treasureMinDist = 20
    local treasureMaxDist = 35
    local playerQueue = player:GetData("treasureChests")
    local next = next
    if playerQueue == nil or next(playerQueue) == nil then
        Treasure.regenerateQueue(player)
        Treasure.spawnTreasure(player)
        return
    else
        local chestID = Treasure.getRandomChestFromQueue(player:GetGUID())
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

        local o = math.random(0, 6.28)
        player:SendBroadcastMessage("Treasure!")
        print("[Treasure] Spawning chest " .. chestID)
        local chest = player:SummonGameObject(chestID, x, y, z, o, 0)

        -- Add items from pool to this chest
        if chest then
            local poolItems = Treasure.pullFromPool(POOL_ITEMS_PER_CHEST)
            for _, item in ipairs(poolItems) do
                chest:AddLoot(item.itemId, item.count)
                print("[Treasure] Added pool item " .. item.itemId .. " to chest")
            end

            -- Track this chest so we know it's one of ours
            local chestGUID = chest:GetGUID()
            Treasure.spawnedChests[chestGUID] = {
                chestID = chestID,
                spawnTime = os.time(),
                poolItemsAdded = #poolItems
            }
        end
    end
end

-- private functions
-- used only when logging in to set up the initial tables
function Treasure.setupTreasure(_event, player)
    local playerQueue = {}
    local playerLevel = player:GetLevel()

    for i, chest in pairs(Treasure.chests) do
        if playerLevel >= chest.minLevel and playerLevel <= chest.maxLevel then
            table.insert(playerQueue, chest.id)
        end
    end
    player:SetData("treasureChests", playerQueue)

end

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
-- Track items looted from chests - these complete the cycle
-- For now, just logging. Later: could track what wasn't taken.
function Treasure.onLootItem(event, player, item, count)
    local itemId = item:GetEntry()
    local itemName = item:GetName()
    print("[Treasure] " .. player:GetName() .. " looted: " .. itemName .. " (ID: " .. itemId .. ") x" .. count)
end -- }}}

-- {{{ Treasure.handleChat
-- Test commands for treasure pool
-- #pooladd <itemId> [count] - add item to pool
-- #poolsize - show pool size
function Treasure.handleChat(event, player, message)
    if message:sub(1, 8) == "#pooladd" then
        local args = message:sub(10)
        local itemId, count = args:match("(%d+)%s*(%d*)")
        itemId = tonumber(itemId)
        count = tonumber(count) or 1
        if itemId then
            Treasure.addToPool(itemId, count)
            player:SendBroadcastMessage("Added item " .. itemId .. " x" .. count .. " to treasure pool")
        else
            player:SendBroadcastMessage("Usage: #pooladd <itemId> [count]")
        end
        return
    end

    if message == "#poolsize" then
        player:SendBroadcastMessage("Treasure pool size: " .. #Treasure.pool .. " items")
        return
    end

    if message == "#treasure" then
        Treasure.spawnTreasure(player)
    end
end -- }}}

PLAYER_EVENT_ON_LOGIN     = 3
PLAYER_EVENT_ON_LOOT_ITEM = 32
PLAYER_EVENT_ON_CHAT      = 18
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, Treasure.setupTreasure)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOOT_ITEM, Treasure.onLootItem)
RegisterPlayerEvent(PLAYER_EVENT_ON_CHAT, Treasure.handleChat)


