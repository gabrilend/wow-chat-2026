# 404 - Sold Items Return to Treasure Pool

**Phase:** 4 (Economy - Currency & Rewards)
**Effect:** Items sold to vendors enter treasure pool and reappear in chests
**Status:** In progress (2026-10-17). The sell hook (B006, issue 403) is in beta's patch list; the handler is being written into `treasure.lua.disabled`, which stays off until issue 200's open question 3 is answered.

---

## The Effect

When you sell a sword to a vendor, it doesn't disappear. It enters the treasure pool, gets assigned to an appropriate-level player's queue, and eventually appears in their next chest. Items cycle through the economy - nothing destroyed, only moved.

```
Player finds sword in chest
        ↓
Player equips sword while leveling
        ↓
Player sells old sword to vendor
        ↓
Sword enters global pool
        ↓
System assigns to appropriate-level player queue
        ↓
Sword appears in that player's next chest
        ↓
Another player finds the same sword
```

---

## What This Solved

### Before (Vendor Gold Sink)

**Traditional WoW economy:**
```
Player sells item → Item deleted from database
                   ↓
                  Gold created from nothing
```

**Result:**
- Items disappear permanently
- Vendor gold is pure creation (inflationary)
- No item circulation
- Economy is create → destroy, not circulate
- Selling feels wasteful ("Where did my sword go?")

**Example:**
- Player finds Steel Sword in chest (item created from loot template)
- Uses sword for 3 levels
- Sells sword to vendor for 50 copper
- Sword deleted from database, 50 copper created
- Another player's chest spawns with different Steel Sword (created from template)

No connection. Two independent Steel Swords, both created from template, no circulation.

### After (Treasure Pool Recycling)

**Treasure pool economy:**
```
Player sells item → Item enters treasure pool
                   ↓
                  Assigned to appropriate-level player queue
                   ↓
                  Appears in that player's next chest
                   ↓
                  Another player finds it
```

**Result:**
- Items persist (one copy moving through economy)
- Vendor gold balanced by item circulation
- Economy is circulate, not create/destroy
- Selling feels meaningful ("Someone else will use this")
- NPCs "prepare" chests with sold items

**Example:**
- Player A finds Steel Sword #1729 in chest (from pool)
- Uses sword for 3 levels
- Sells sword to vendor for 50 copper
- Sword #1729 enters pool, assigned to Player B (level 14)
- Player B's next chest contains Sword #1729 + other queue items
- Player B finds THE SAME sword Player A sold

ONE sword, circulating. The exact item Player A sold is now Player B's loot.

---

## Why This Matters

**Tangible Item Persistence**

In standard WoW, items are database entries that spawn and delete. They feel ephemeral, disposable.

With treasure pool recycling, items are tangible objects that move:
- You can trace an item's history
- Items have "previous owners" (not really tracked, but conceptually true)
- Selling means "passing on" not "destroying"

**Economic Balance**

Traditional vendor gold is pure inflation:
- Items created → Gold created
- Items destroyed → Gold remains
- Net result: Infinite gold generation

Treasure pool recycling creates balance:
- Items circulated → Gold circulated
- One player's sale is another's loot
- Net result: Stable item count, gold acts as exchange medium

**Mancala Distribution**

Items don't randomly appear in any chest. They're assigned to appropriate-level players via mancala rotation (Issue 402):

- Sold level 15 item → Finds level 14-16 player
- Player with smallest queue gets priority
- Fair distribution ensures everyone receives items

**NPCs as Scavengers**

"NPCs prepare treasure chests with sold items."

The narrative: vendors stock chests with items players sell them. Guards find abandoned equipment, add it to treasure caches. The world responds to player economy.

---

## Design

### What Goes Into Pool

**Vendor sales:**
- Items sold by players → pool
- Items sold by bots → pool
- Captured via `PLAYER_EVENT_ON_SELL_ITEM` hook (Issue 403)

**Chest despawns:**
- Leftover items when chest despawns → pool (Issue 402)
- NPCs "find" what players didn't loot

**Corpse despawns:**
- Items on corpses when no player nearby → pool
- Equipment left on battlefield

### What Doesn't Go Into Pool

**Destroyed items:**
- Player explicitly destroys item (trash icon) → deleted forever
- Clear distinction: sell = recycle, destroy = delete

**Traded items:**
- Player-to-player trades keep item with new owner
- Direct exchange, no pool involvement

**Quest items:**
- Quest-specific items don't recycle
- Would break quest flow

### Implementation Hook

Requires `PLAYER_EVENT_ON_SELL_ITEM` from Issue 403:

```lua
RegisterPlayerEvent(PLAYER_EVENT_ON_SELL_ITEM, function(event, player, item, vendor, count)
    local itemId = item:GetEntry()
    local itemLevel = item:GetItemLevel()

    -- Filter: only recycle quality items
    if item:GetQuality() >= 2 then  -- Uncommon+
        Treasure.addToPool(itemId, itemLevel, count)
        player:SendBroadcastMessage("Item sold - entering treasure pool")
    else
        -- Common items (gray/white) just sold normally
        player:SendBroadcastMessage("Item sold for " .. formatMoney(item:GetSellPrice()))
    end
end)
```

### Pool Integration

Items from vendor sales follow same flow as chest despawn items (Issue 402):

1. Item enters global pool momentarily
2. System finds eligible player (level matching)
3. Item assigned to player's personal queue
4. Player's next chest spawns → queue injected
5. Player loots item (or doesn't, and it recycles)

### Quality Filtering

**Uncommon+ items recycle:**
- Green, blue, purple items → treasure pool
- Worth passing on to other players
- Maintains item value

**Common items don't recycle:**
- Gray/white vendor trash → deleted on sale
- Would flood pool with junk
- Players wouldn't want them in chests

This creates economy tiering:
- Quality items circulate (valuable)
- Junk items delete (vendor gold sink)

---

## Current Behavior (2026-10-17)

Written and checked in a toy world; not running in game, because
`treasure.lua.disabled` stays off until issue 200's open question 3 is
answered.

B006 adds the sell event to the Lua engine (event 74: player, item,
vendor, count), fired inside the server's sell handling after the item
leaves the bags and **just before it is put in the vendor's buyback
tab**. The treasure script now listens for it (`Treasure.onSellItem`):

- Every sale goes on the seller's counter (below). An item is marked to
  be recycled when it is uncommon or better, not a quest item, and does
  not stack (`Treasure.isRecycled`).
- Its level for matching is its required level, or its item level when
  it has none (`Treasure.saleLevel`).
- Leaving the counter, a marked item enters the pool and goes to a real
  player near its level — **never back to its seller** (see the open
  question).
- Bots' sales recycle like players'; bots never receive (402).

Checked by `scripts/test-treasure`: a sold sword waits; bought back, it
never enters; kept sold, it enters at the seller's logout, once; the
13th sale releases the first; a sold copy whose only fitting player is
its seller waits in the pool for the next one; white, stacking and quest
items never enter; an item sold, bought back and sold again enters
once; a bot's sale reaches a real player; the required level decides.

## The Buyback Problem (found 2026-10-17)

A sold item is not gone when the sale fires. It sits in the seller's
buyback tab, and the seller can buy it back. If the sale put it straight
into the pool, buying it back would leave two copies — the one thing this
design forbids ("ONE sword, circulating"). What the server does, read
from `source-beta/`:

- The buyback tab holds **12** items (`BUYBACK_SLOT_START` 74 to
  `BUYBACK_SLOT_END` 86, `Player.h`). A 13th sale pushes out the oldest,
  which is deleted (`Player::AddItemToBuyBackSlot`).
- The tab is **not saved**: at the save that comes with logging out,
  items still in it are deleted (`Player::_SaveInventory`).
- Buying back moves the **same item, with the same GUID**, back into the
  bags (`WorldSession::HandleBuybackItem`, `StoreItem`).
- Lua cannot read the buyback slots: the position lookup returns nothing
  for slots 74–85 (`Player::GetItemByPos`), and the lookup by GUID
  searches bags, bank and equipment but not buyback
  (`Player::GetItemByGuid`).
- No event fires on a buyback.

So the handler keeps a sold item **on the counter** — a per-seller list,
oldest first, of { GUID, item, level, count, recycle } — until it surely
cannot come back. Every sale goes on the counter, recycled or not,
because every sale takes a buyback slot and so pushes the others along;
only entries marked `recycle` enter the pool when they leave:

- At every sale and at logout, any counter item found in the seller's
  bags by its GUID was bought back: it leaves the counter and never
  enters the pool.
- When the counter holds more than 12, the oldest has been pushed out of
  the tab and deleted by the server: it enters the pool.
- At logout, everything left on the counter was deleted by the logout
  save: it all enters the pool.

The GUID check fails if a bought-back item merges into a stack (it then
has no GUID of its own), so **only items that do not stack** are
recycled. With "uncommon or better" that is nearly all equipment.

Remaining gap, recorded: an item bought back and then traded, mailed or
destroyed before the next check is not in the bags, so it is counted as
gone and also enters the pool — a duplicate in the trade or mail case.
Rare, and visible in the log; closing it needs a buyback event in the
engine (a B-patch beside B006).

## Open Questions (2026-10-17)

1. **A recycled sale still pays.** The vendor pays the usual price, and
   the item is not destroyed: it comes back in someone's chest, and they
   can sell it again, for the same price. So every turn of the circle
   makes money from nothing — the opposite of "Vendor gold balanced by
   item circulation" above. The test found the shortest loop (a player
   finding their own sold sword in their next chest) and the script now
   never gives a seller their own copy back. Two players can still pass
   an item between them, each selling it for gold. Should a recycled
   sale pay nothing, pay less, or pay as usual and accept the loop?
2. **Bought back, then traded or mailed.** As in the buyback problem
   above: such an item is counted as gone and also enters the pool, a
   second copy. Close it with a buyback event in the engine (a B-patch
   beside B006, the owner's build), or accept the gap?

## Suggested Implementation Steps (remaining)

1. Answer the open questions; if a recycled sale should pay less or
   nothing, take the difference back in the sell handler (the event
   carries the vendor and the count).
2. Switch treasure on with 402, and in game: sell a green to a vendor,
   log out, see it reach another player's chest.

The configuration lines suggested below (`WowChat2.TreasurePool.*`) are
not used: these scripts keep their settings in the script, per the
project's style (configuration in structure).

## Implementation

### Lua Script

**File:** `src/lua/treasure.lua` (existing from 402)

**Add handler:**
```lua
local PLAYER_EVENT_ON_SELL_ITEM = 74

RegisterPlayerEvent(PLAYER_EVENT_ON_SELL_ITEM, function(event, player, item, vendor, count)
    local itemId = item:GetEntry()
    local itemLevel = item:GetItemLevel()
    local quality = item:GetQuality()

    -- Only recycle uncommon+ items
    if quality >= 2 then
        -- Add to global pool (immediately redistributes to player queue)
        Treasure.addToPool(itemId, itemLevel, count)

        -- Notify player
        local qualityName = getQualityName(quality)
        player:SendBroadcastMessage(string.format(
            "Sold %s item - entering treasure pool",
            qualityName
        ))
    end
end)
```

**Existing functions from 402:**
- `Treasure.addToPool(itemId, level, count)` - Already implemented
- Pool → queue redistribution - Already implemented
- Queue → chest injection - Already implemented

This issue just adds the vendor sale input source.

### Configuration

```conf
WowChat2.TreasurePool.RecycleSoldItems = 1
WowChat2.TreasurePool.MinQualityRecycle = 2  # 0=poor, 1=common, 2=uncommon, 3=rare, 4=epic
```

### Testing

**Test flow:**
1. Create character, level to 15
2. Find uncommon item in chest
3. Sell item to vendor
4. Check treasure pool size: `#poolsize` → should increase
5. Spawn another chest: `#treasure`
6. Loot chest → sold item should appear (if assigned to your queue)

**Without Issue 403:**
Cannot test - no sell hook available. Must use manual `#pooladd` command instead.

---

## Dependencies

### Issue 403 - ale-sell-item-hook (REQUIRED)

Without `PLAYER_EVENT_ON_SELL_ITEM`, this issue cannot be implemented. The hook provides:
- Item data before destruction
- Vendor context
- Sell count (partial stacks)

**Status:** Completed (2026-04-05)

### Issue 402 - treasure-chest-shared-loot (REQUIRED)

Provides treasure pool infrastructure:
- Global pool structure
- Per-player queue distribution
- Level matching algorithm
- Queue injection on chest spawn

**Status:** Partial (global pool done, queue distribution needed)

### Combined Flow

```
Player sells item (403 hook fires)
        ↓
Lua adds to treasure pool (404 implementation)
        ↓
Pool redistributes to player queue (402 redistribution)
        ↓
Chest spawns with queue items (402 injection)
        ↓
Another player loots
```

Three issues working together to complete the cycle.

---

## Design Philosophy

### "Nothing Destroyed"

Items aren't consumed, they circulate. This creates:
- **Scarcity** - Fixed number of each item (no template spawning)
- **Tangibility** - Items feel real, trackable
- **Connection** - Your actions affect others' loot

### "Transceived"

"Each item exists as ONE copy, transceived (transmitted + received as one action)."

Items don't duplicate, they move. Selling transmits to another player's queue, they receive it in their chest. One atomic action, one item.

### "NPCs as Scavengers"

The narrative: NPCs prepare chests by gathering what heroes leave behind:
- Vendors stock chests with sold items
- Guards find abandoned equipment
- The world responds to player economy

This makes the economy feel alive, not scripted.

---

## Lessons Learned

### Quality Filtering is Essential

Initial concept: All sold items recycle. Problem:
- Players sell tons of gray/white vendor trash
- Pool floods with worthless items
- Chests fill with junk nobody wants

Solution: Only recycle uncommon+ items. Creates natural tiering.

### Dependency Chain

This issue sits in middle of dependency chain:
- Requires 403 (hook)
- Requires 402 (pool infrastructure)
- Enables complete circulation economy

Can't implement in isolation. Must complete dependencies first.

### Manual Testing Workaround

Without Issue 403, testing used `#pooladd` command:
```
#pooladd 12345 5  # Manually add item to pool
```

This allowed testing pool→chest flow before sell hook existed. Good development pattern: build infrastructure, add input sources later.

---

## Phase 4 Contribution

This issue completes the **Phase 4: Economy - Currency & Rewards** circulation system:

> **Issue 402** - Treasure pool infrastructure (queues, distribution)
> **Issue 403** - Sell item hook (detection mechanism)
> **Issue 404** - Sold items to pool (input source)

Together, these three issues create a complete item circulation economy where:
- Items persist as single copies
- Vendor sales feed treasure pools
- Treasure pools feed chests via player queues
- Items cycle indefinitely

The economy shifts from create/destroy to circulate. Items feel tangible, actions matter, the world responds.

---

## Related Issues

- 402 - treasure-chest-shared-loot (pool infrastructure)
- 403 - ale-sell-item-hook (C++ hook required)
- 401 - bounty-board-currency-system (complementary economy mechanic)

## Related Documents

- `docs/datapaths/treasure.md`: the whole path an item takes, selling included
- `src/lua-beta/treasure.info.md`: the script's functions
- `scripts/test-treasure`: the toy-world check
