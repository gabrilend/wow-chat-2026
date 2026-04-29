# 403 - ALE Sell Item Hook

**Phase:** 4 (Economy - Currency & Rewards)
**Effect:** Lua scripts can detect vendor sales via PLAYER_EVENT_ON_SELL_ITEM
**Status:** Completed (2026-04-05, re-implemented 2026-04-09)

---

## The Effect

When a player sells an item to a vendor, Lua scripts are notified immediately. This enables:
- Sold items returning to treasure pool
- Economy tracking and statistics
- Bot behavior responses to sales

```lua
RegisterPlayerEvent(PLAYER_EVENT_ON_SELL_ITEM, function(event, player, item, vendor, count)
    local itemId = item:GetEntry()
    Treasure.addToPool(itemId, count)  -- Recycle sold item
    player:SendBroadcastMessage("Item sold, added to treasure pool!")
end)
```

---

## What This Solved

### Before (No Sell Hook)

**Vendor sale flow (C++ only):**
```
Player → Vendor UI → HandleSellItemOpcode (C++)
                   ↓
              Item destroyed
                   ↓
              Money added
                   ↓
           (Lua never notified)
```

**Result:**
- Lua scripts cannot detect vendor sales
- Sold items data lost (item destroyed before Lua sees it)
- Cannot implement sold-items-to-treasure-pool
- Economy tracking impossible
- Bot behaviors can't react to player sales

**Workarounds considered:**
1. Poll player inventory for missing items (unreliable, expensive)
2. Hook loot events and guess if sale happened (inaccurate)
3. Client-side addon sending custom packets (requires addon, can be spoofed)

All workarounds are fragile or insecure.

### After (PLAYER_EVENT_ON_SELL_ITEM)

**Vendor sale flow with hook:**
```
Player → Vendor UI → HandleSellItemOpcode (C++)
                   ↓
           sALE->OnSellItem(player, item, vendor, count)  ← Hook fires
                   ↓
              Lua event handler
                   ↓
              Item destroyed
                   ↓
              Money added
```

**Result:**
- Lua notified BEFORE item destroyed
- Can capture item data (entry, count, quality)
- Enable sold-items-to-treasure-pool (404)
- Economy statistics possible
- Bot behaviors react to player sales
- Secure (server-side, cannot be spoofed)

**Example usage:**
```lua
RegisterPlayerEvent(PLAYER_EVENT_ON_SELL_ITEM, function(event, player, item, vendor, count)
    -- Track economy statistics
    incrementSoldItemCount(item:GetEntry(), count)

    -- Recycle to treasure pool
    if item:GetQuality() >= 2 then  -- Uncommon+
        Treasure.addToPool(item:GetEntry(), count)
    end

    -- Bot reaction
    notifyNearbyBots(player, "sold_item", item:GetEntry())
end)
```

---

## Why This Matters

**Completing the Item Lifecycle**

Without this hook, items have an incomplete lifecycle:

```
Looted → Equipped → ??? → Deleted
```

With this hook:

```
Looted → Equipped → Sold → Recycled → Appears in treasure pool → Looted again
```

The cycle closes. Items persist.

**Treasure Pool Dependency**

Issue 402 (treasure-chest-shared-loot) defines per-player queues where items circulate. Issue 404 (sold-items-to-treasure-pool) implements vendor sales feeding the pool.

Without this hook, 404 cannot be implemented. The treasure pool remains isolated from vendor economy.

**Server-Side Security**

Client-side addons can send custom packets, but they can be spoofed. Server-side hooks are authoritative. When `HandleSellItemOpcode` runs, the sale definitely happened - item is in player inventory, vendor is valid, transaction verified.

Lua scripts can trust the data.

**Event Timing**

Hook fires BEFORE item destruction. This is critical:

- Lua can query item properties (entry, quality, level)
- Item object still exists in memory
- After hook completes, core destroys item safely

If hook fired AFTER destruction, Lua would receive invalid item pointer.

---

## Implementation

### C++ Patch to ALE

**Patch ID:** B006
**Application:** Automated via build script (`scripts/azerothcore`)
**Phase:** PHASE_BEGIN (pre-compile source modification)

### Files Modified

**1. modules/mod-ale/src/LuaEngine/Hooks.h**

Added event enum:
```cpp
enum PlayerEvents
{
    // ... existing events
    PLAYER_EVENT_ON_SELL_ITEM = 74,  // (event, player, item, vendor, count)
    // ...
};
```

**2. modules/mod-ale/src/LuaEngine/LuaEngine.h**

Added method declaration:
```cpp
class Eluna : public ElunaTemplate<Eluna>
{
public:
    // ... existing methods
    void OnSellItem(Player* player, Item* item, Creature* vendor, uint32 count);
    // ...
};
```

**3. modules/mod-ale/src/LuaEngine/hooks/PlayerHooks.cpp**

Implemented hook:
```cpp
void Eluna::OnSellItem(Player* player, Item* item, Creature* vendor, uint32 count)
{
    if (!PlayerEventBindings->HasBindingsFor(PLAYER_EVENT_ON_SELL_ITEM))
        return;

    LOCK_ELUNA;
    Push(player);
    Push(item);
    Push(vendor);
    Push(count);
    CallAllFunctions(PlayerEventBindings, PLAYER_EVENT_ON_SELL_ITEM);
}
```

**4. src/server/game/Handlers/ItemHandler.cpp**

Added hook calls at sale transaction points:

```cpp
void WorldSession::HandleSellItemOpcode(WorldPacket& recvData)
{
    // ... validation

    // Partial stack sale (line 728)
    if (packet.Count < pItem->GetCount())
    {
        // Create new item with sold count
        pNewItem = pItem->CloneItem(packet.Count, player);

        // HOOK: Notify Lua before destruction
        #ifdef ELUNA
        sALE->OnSellItem(player, pNewItem, pCreature, packet.Count);
        #endif

        // Destroy sold portion
        player->DestroyItem(pNewItem->GetBagSlot(), pNewItem->GetSlot(), true);
    }
    else  // Full item sale (line 740)
    {
        // HOOK: Notify Lua before destruction
        #ifdef ELUNA
        sALE->OnSellItem(player, pItem, pCreature, pItem->GetCount());
        #endif

        // Destroy item
        player->DestroyItem(pItem->GetBagSlot(), pItem->GetSlot(), true);
    }

    // ... money handling
}
```

### Automated Patch Application

**Build script:** `scripts/azerothcore`

**Function:** `patch_B006_ale_sell_item_hook()`

```bash
patch_B006_ale_sell_item_hook() {
    # Patch mod-ale files
    FILE="$SOURCE_DIR/modules/mod-ale/src/LuaEngine/Hooks.h"
    sed -i '/PLAYER_EVENT_ON_LOOT_ITEM/a\    PLAYER_EVENT_ON_SELL_ITEM = 74,' "$FILE"

    FILE="$SOURCE_DIR/modules/mod-ale/src/LuaEngine/LuaEngine.h"
    sed -i '/void OnLootItem/a\        void OnSellItem(Player* player, Item* item, Creature* vendor, uint32 count);' "$FILE"

    FILE="$SOURCE_DIR/modules/mod-ale/src/LuaEngine/hooks/PlayerHooks.cpp"
    # Insert OnSellItem implementation after OnLootItem

    FILE="$SOURCE_DIR/src/server/game/Handlers/ItemHandler.cpp"
    # Insert hook calls at two sale transaction points
}
```

**Idempotent:** Checks if patch already applied before modifying.

**Reversible:** `unpatch_B006_ale_sell_item_hook()` removes changes after build (Issue 334 - patch staleness detection).

### Build Process

```bash
./scripts/azerothcore update
```

Internally:
1. Clones/updates AzerothCore source
2. Applies B006 patch (adds PLAYER_EVENT_ON_SELL_ITEM)
3. Compiles with `-DSCRIPTS=static -DMODULES=static`
4. Installs binaries
5. Reverts patch from source (keeps source clean for next update)

### Verification

After build, test with Lua:

```lua
RegisterPlayerEvent(74, function(event, player, item, vendor, count)
    player:SendBroadcastMessage("SELL HOOK FIRED: " .. item:GetEntry() .. " x" .. count)
end)
```

Sell item to vendor → message appears → hook working.

---

## Technical Details

### Event Signature

```lua
function(event, player, item, vendor, count)
```

**Parameters:**
- `event` (number) - Always 74 (PLAYER_EVENT_ON_SELL_ITEM)
- `player` (Player) - Player selling item
- `item` (Item) - Item being sold (still valid)
- `vendor` (Creature) - Vendor NPC
- `count` (number) - Number of items sold (stack count)

**Return:** None (event cannot be cancelled)

### Timing Critical

Hook must fire BEFORE item destruction:

```cpp
// CORRECT ORDER:
sALE->OnSellItem(player, item, vendor, count);  // Item valid
player->DestroyItem(bag, slot, true);           // Item destroyed

// WRONG ORDER:
player->DestroyItem(bag, slot, true);           // Item destroyed
sALE->OnSellItem(player, item, vendor, count);  // Item pointer invalid!
```

If Lua tries to call `item:GetEntry()` after destruction → crash.

### Two Call Sites

Sale has two code paths:

1. **Partial stack sale:** Player has 10 items, sells 3
   - Create clone with count=3
   - Fire hook with clone
   - Destroy clone
   - Original stack reduced to 7

2. **Full item sale:** Player sells all items in stack
   - Fire hook with original item
   - Destroy original item

Both paths must call hook.

### ALE Integration Pattern

ALE (AzerothCore Lua Engine) uses consistent pattern for player events:

```cpp
void Eluna::On[EventName](Player* player, ...)
{
    if (!PlayerEventBindings->HasBindingsFor(PLAYER_EVENT_ON_[EVENT]))
        return;

    LOCK_ELUNA;
    Push(player);
    Push(...);  // Additional parameters
    CallAllFunctions(PlayerEventBindings, PLAYER_EVENT_ON_[EVENT]);
}
```

OnSellItem follows same pattern. Consistency makes maintenance easier.

---

## Lessons Learned

### Upstream Stability vs Custom Hooks

**Trade-off:** Patching upstream code (ALE, AzerothCore) adds maintenance burden. Updates might conflict with patches.

**Mitigation:**
- Automated patch application during build
- Patch reversal after build (Issue 334)
- Documentation for manual reapplication if needed

**Worth it:** Without this hook, core gameplay feature (treasure pool recycling) cannot be implemented. Some features require core modification.

### Hook Before Destruction

Initial implementation mistake: Hooked after item destruction. Lua scripts crashed when querying item properties.

**Lesson:** When hooking object lifecycle events, fire hooks BEFORE object is freed. Lua needs valid pointers.

### Two Sale Paths

HandleSellItemOpcode has two branches (partial vs full sale). Both must call hook. Initially only patched one branch - full stack sales worked, partial sales didn't trigger hook.

**Lesson:** Read ALL code paths in target function. Edge cases matter.

### Event ID Assignment

Chose ID 74 arbitrarily. Later discovered ALE reserves ranges for event types. Should follow upstream numbering conventions.

**Better approach:** Check latest ALE release, use next sequential ID in player event range.

---

## Phase 4 Contribution

This issue enables **Phase 4: Economy - Currency & Rewards** by providing critical hook for:

> **Issue 404** - sold-items-to-treasure-pool (depends on this hook)
> **Issue 402** - treasure-chest-shared-loot (pool population mechanism)

Without this hook, the treasure pool economy cannot function. Items would only enter pool from chest despawns, never from vendor sales. The economy would be incomplete.

By exposing vendor sales to Lua, we complete the item lifecycle: loot → equip → sell → recycle → loot again.

---

## Related Issues

- 402 - treasure-chest-shared-loot (defines pool system)
- 404 - sold-items-to-treasure-pool (uses this hook)
- 334 - patch-staleness-detection (automated patch reversal)

## Documentation

Full patch specification: `docs/patches/ale-sell-item-hook.md`
