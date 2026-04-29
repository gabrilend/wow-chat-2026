# 402 - Treasure Chest Shared Loot System

**Phase:** 4 (Economy - Currency & Rewards)
**Effect:** Items cycle through player queues - sold gear reappears in chests
**Status:** Partial (pool system implemented, per-player queues needed)

---

## The Effect

Items exist as ONE copy in the world. When you sell a sword to a vendor, it doesn't disappear - it enters a treasure pool and eventually appears in another player's chest. NPCs find items left behind when heroes move on.

Each player has a personal treasure queue. Items from the pool are assigned to appropriate-level players. When your next chest spawns, your queue empties into it. If you don't loot everything before the chest despawns, items return to the pool and redistribute to other players.

---

## What This Solved

### Before (Standard Loot Tables)

**Traditional WoW loot:**
- Creatures drop items from fixed loot tables
- Items spawn from nothing when killed
- Leftover items in chests disappear on despawn
- Sold items vanish into vendor buyback (temporary)
- No item persistence or circulation

**Result:**
- Items feel disposable, not tangible
- Economy is pure item creation/destruction
- Chests are isolated - no connection between them
- Selling vendor trash feels wasteful

**Example:**
- Kill wolf → Wolf Pelt drops (created from template)
- Loot chest → Find sword (created from template)
- Sell sword to vendor → Sword disappears after 2 hours
- Another player's chest → Different sword (created from template)

No connection. Items don't move, they spawn and delete.

### After (Shared Treasure Pool)

**Per-player queue circulation:**
```
Player sells sword → Global pool (momentarily)
                   ↓
            Level matching finds eligible player
                   ↓
            Item assigned to player's personal queue
                   ↓
            Player's next chest spawns → Queue items injected
                   ↓
            Player loots some items, leaves others
                   ↓
            Chest despawns → Remaining items back to pool
                   ↓
            Redistribute to another player's queue
```

**Result:**
- Items persist as single copies moving between players
- Selling sword means someone else finds it later
- Chests connected through shared pool
- NPCs "find" what heroes left behind
- Fair distribution via per-player queues

**Example:**
- Player A (level 15) sells steel sword
- System finds Player B (level 14-16)
- Sword assigned to Player B's queue
- Player B's next chest contains sword + their queue items
- Player B takes sword, leaves boots
- Chest despawns → Boots return to pool
- Boots assigned to Player C's queue

ONE sword, moving through the economy. Tangible.

---

## Why This Matters

**One Copy, Transceived**

The core principle: each item exists as ONE copy in the world. Items are not duplicated, only moved. This creates:

- **Scarcity** - Limited number of each item type
- **Persistence** - Items you sell continue existing
- **Connection** - Your actions affect other players' loot
- **Tangibility** - Items feel real, not spawned from templates

**Mancala Distribution**

The "mancala" metaphor: items circulate among players like stones in a mancala board. Items distribute round-robin among eligible players, preferring those with fewer queued items. Fair, but not identical.

**Level Matching**

Level 15 sword sold → assigned to level 14-16 player. Not random distribution - items find appropriate recipients. Creates natural economy flow:

- Low-level players find low-level gear
- High-level players find high-level gear
- No level 1 getting endgame items by luck

**NPCs Finding Leftovers**

"NPCs prepare chests by pulling from the shared pool."

The narrative: NPCs scavenge what heroes leave behind. You sell a sword to a vendor, they stock it in a chest somewhere. Another NPC finds abandoned boots, adds them to a different chest. The world responds to player actions.

**Item Lifecycle Clarity**

```
TRASH (gone forever)     RECYCLE (back to pool)
        ^                        ^
        |                        |
   destroyed              sold to vendor
   by player              OR chest despawns (no loot nearby)
                          OR corpse despawns (no loot nearby)
```

Clear distinction: delete vs recycle. Destroying items (trashing) removes them. Selling or abandoning recycles them.

---

## Design

### Per-Player Queue Model

**Global pool is transient:**
- Items enter global pool when sold or despawned
- Immediately distributed to player queues based on level matching
- Global pool only holds items during redistribution (brief)

**Player queues are persistent:**
- Each player has personal treasure queue
- Items assigned based on level compatibility
- Queue empties into next chest spawn
- If chest despawns with items remaining → back to pool → redistribute

**No floating items:**
- Items are either in a player's queue, in an active chest, or looted
- Global pool is just the redistribution layer

### Level Matching Algorithm

```lua
function findEligiblePlayer(itemLevel)
    local eligible = {}

    for _, player in ipairs(GetPlayersOnline()) do
        local pLevel = player:GetLevel()
        if math.abs(pLevel - itemLevel) <= 2 then  -- ±2 level range
            table.insert(eligible, player)
        end
    end

    if #eligible == 0 then return nil end  -- Item waits in global pool

    -- Mancala: prefer players with fewer queued items
    table.sort(eligible, function(a, b)
        return getQueueSize(a) < getQueueSize(b)
    end)

    return eligible[1]  -- Player with smallest queue
end
```

### Queue Injection on Chest Spawn

```lua
function Treasure.spawnTreasure(player, x, y, z, mapId)
    local chest = SummonGameObject(chestEntry, mapId, x, y, z, orientation, respawnTime)

    -- Inject all items from player's queue
    local queue = Treasure.playerQueues[player:GetGUID()] or {}
    for _, item in ipairs(queue) do
        chest:AddLoot(item.itemId, item.count)
    end

    -- Clear queue after injection
    Treasure.playerQueues[player:GetGUID()] = {}

    -- Track chest for despawn recycling
    Treasure.activeChests[chest:GetGUID()] = {
        queueItems = queue,  -- Remember which came from queue
        spawnerGUID = player:GetGUID(),
        spawnTime = os.time()
    }

    return chest
end
```

### Despawn Recycling

```lua
function Treasure.onChestDespawn(chest)
    local chestData = Treasure.activeChests[chest:GetGUID()]
    if not chestData then return end

    -- Get remaining items (ALE limitation: can't query GameObject loot directly)
    -- Workaround: track what was added, subtract what was looted
    local remaining = getRemainingItems(chest, chestData.queueItems)

    -- Return remaining items to global pool
    for _, item in ipairs(remaining) do
        Treasure.addToPool(item.itemId, item.count)
    end

    -- Clean up tracking
    Treasure.activeChests[chest:GetGUID()] = nil
end
```

---

## Implementation

### Current Status (2026-04-04)

**Implemented:**
- Global treasure pool (`Treasure.pool`)
- FIFO queue: first items added are first pulled
- `Treasure.addToPool(itemId, count)` - Add items to pool
- `Treasure.pullFromPool(count)` - Pull items from pool for chest
- Pool items added to chests on spawn (up to 2 items)
- Chest spawn tracking (`Treasure.spawnedChests`)
- Test commands: `#pooladd`, `#poolsize`, `#treasure`

**Partially Implemented:**
- Item loot tracking (`PLAYER_EVENT_ON_LOOT_ITEM` hook)
- Foundation for detecting unclaimed items

**Not Yet Implemented:**
- Per-player queue distribution (currently global FIFO)
- Level-based item-to-player matching
- Queue injection on chest spawn
- Despawn recycling (items back to pool)
- Multi-player chest access (implemented separately in 408)

### Needed Changes

**1. Convert Global Pool to Per-Player Queues**

```lua
-- OLD: Global FIFO pool
Treasure.pool = {}  -- array of {itemId, count}

-- NEW: Per-player queues
Treasure.globalPool = {}  -- Brief holding during redistribution
Treasure.playerQueues = {}  -- [playerGUID] = { {itemId, count}, ... }
```

**2. Implement Redistribution Logic**

When items enter global pool:
1. Find eligible players (level matching)
2. Select player with smallest queue (mancala)
3. Assign item to their personal queue
4. If no eligible players → item waits in global pool

**3. Implement Queue Injection**

When chest spawns for player:
1. Get player's queue items
2. Add all queue items to chest via `AddLoot()`
3. Clear player's queue
4. Track which items came from queue (for despawn recycling)

**4. Implement Despawn Recycling**

When chest despawns:
1. Determine remaining items (not looted)
2. Return remaining to global pool
3. Trigger redistribution immediately

### Data Structures

```lua
-- Global pool: items awaiting distribution (briefly held)
Treasure.globalPool = {}  -- array of {itemId, itemLevel, count}

-- Per-player queues: items assigned to specific players
Treasure.playerQueues = {}  -- [playerGUID] = { {itemId, count}, ... }

-- Active chest tracking
Treasure.activeChests = {}  -- [chestGUID] = {
                            --   queueItems = {},  -- items from player queue
                            --   baseItems = {},   -- items from loot template
                            --   spawnerGUID = playerGUID,
                            --   spawnTime = timestamp
                            -- }
```

### Files

- **src/lua/treasure.lua** - Core treasure system (partial implementation)
- **src/lua/chest-vulnerability.lua** - Multi-player chest access (separate issue 408)

### ALE Limitation

**Problem:** ALE doesn't expose the Loot object from GameObject, so we can't query remaining items directly.

**Workaround:** Track items added to chest, listen to `PLAYER_EVENT_ON_LOOT_ITEM`, subtract what was taken, remaining = what's left.

**Better solution:** Add ALE hook for `GAMEOBJECT_EVENT_ON_LOOT_DEPLETED` or expose `GetLoot()` method.

---

## Design Refinement (2026-04-05)

The original "Mancala distribution" concept was correct but incomplete. Items ARE distributed mancala-style (round-robin among eligible players), but they go to per-player queues rather than directly to active chests:

1. Items go to appropriate-level players (level matching)
2. Mancala rotation: prefer players with fewer queued items
3. Each player builds up a personal treasure queue
4. Queue empties into their next chest spawn
5. Despawned chest items return to pool and re-distribute

The mancala principle ensures fair distribution - if player A got an item and players B, C, D haven't, the next item goes to one of B/C/D.

---

## Lessons Learned

### One Copy vs Many Copies

Treating items as unique objects (one copy each) creates different dynamics than template-spawning:

- **Scarcity matters** - Limited supply creates value
- **Circulation visible** - Players notice items moving
- **Actions have consequences** - Selling affects others' loot

### Queue vs Direct Distribution

Initial design distributed items directly to active chests. Problems:

- Uneven distribution (players with more chests get more items)
- Timing issues (item enters pool when no chests active)
- No fairness guarantee

Per-player queues solve this:

- Fair distribution (each player gets items regardless of chest spawn rate)
- Items always have a destination (player queue)
- Mancala rotation ensures balance

### ALE API Gaps

Limitation: Can't query remaining loot in GameObject. This forces workarounds (track added items, subtract looted items). Better solution would be ALE exposing:

```lua
local loot = gameobject:GetLoot()
local remaining = loot:GetRemainingItems()
```

Or event hook:
```lua
RegisterGameObjectEvent(GAMEOBJECT_EVENT_ON_LOOT_DEPLETED, function(event, go, lootedItems, remainingItems)
    -- Recycle remaining items
end)
```

---

## Phase 4 Contribution

This issue defines core mechanics for **Phase 4: Economy - Currency & Rewards**:

> **Item persistence** - Items circulate, don't just spawn/delete
> **Per-player queues** - Fair distribution via mancala rotation
> **Level matching** - Items find appropriate recipients
> **Despawn recycling** - NPCs find what heroes leave behind

The treasure chest system transforms loot from "random template spawns" into a living economy where items persist, circulate, and respond to player actions. This creates tangible connection between player choices and world state.

---

## Related Issues

- 404 - sold-items-to-treasure-pool (implements vendor sale → pool flow)
- 403 - ale-sell-item-hook (C++ hook needed for sale detection)
- 408 - multiplayer-chest-access (multiple players looting same chest)
- 407 - chest-vulnerability-mechanic (daze interrupt, defenseless while looting)
- 405 - ability-tome-system (chest loot enhancement)
