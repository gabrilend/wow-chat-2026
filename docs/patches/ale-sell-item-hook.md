# ALE Sell Item Hook Patch

**Status:** Implemented as `patches/B006-ale-sell-item-hook.sh`

Adds `PLAYER_EVENT_ON_SELL_ITEM` to AzerothCore Lua Engine (ALE).

## Overview

When a player sells an item to a vendor, this hook fires BEFORE the item
is removed, allowing Lua scripts to capture item data for recycling into
treasure pools, economy tracking, or other custom behavior.

## Files to Modify

### 1. `modules/mod-ale/src/LuaEngine/Hooks.h`

Add new event to `PlayerEvents` enum (after line 240):

```cpp
        PLAYER_EVENT_ON_RELEASED_GHOST                      =     73,       // (event, player)
        PLAYER_EVENT_ON_SELL_ITEM                           =     74,       // (event, player, item, vendor, count)

        PLAYER_EVENT_COUNT
```

---

### 2. `modules/mod-ale/src/LuaEngine/LuaEngine.h`

Add method declaration (around line 380, with other item-related hooks):

```cpp
    void OnQuestRewardItem(Player* player, Item* item, uint32 count);
    void OnCreateItem(Player* player, Item* item, uint32 count);
    void OnStoreNewItem(Player* player, Item* item, uint32 count);
    void OnSellItem(Player* player, Item* item, Creature* vendor, uint32 count);  // NEW
```

---

### 3. `modules/mod-ale/src/LuaEngine/hooks/PlayerHooks.cpp`

Add implementation (at end of file, before closing):

```cpp
void ALE::OnSellItem(Player* pPlayer, Item* pItem, Creature* pVendor, uint32 count)
{
    START_HOOK(PLAYER_EVENT_ON_SELL_ITEM);
    Push(pPlayer);
    Push(pItem);
    Push(pVendor);
    Push(count);
    CallAllFunctions(PlayerEventBindings, key);
}
```

---

### 4. `src/server/game/Handlers/ItemHandler.cpp`

Add ALE include at top (if not already present):

```cpp
#ifdef ALE
#include "LuaEngine.h"
#endif
```

Add hook call in `HandleSellItemOpcode` function. Insert BEFORE `AddItemToBuyBackSlot`:

**For partial stack sale (around line 722):**

```cpp
                    pItem->SetState(ITEM_CHANGED, _player);

#ifdef ALE
                    sALE->OnSellItem(_player, pNewItem, creature, packet.Count);
#endif
                    _player->AddItemToBuyBackSlot(pNewItem, money);
```

**For full item sale (around line 731):**

```cpp
                    _player->RemoveItem(pItem->GetBagSlot(), pItem->GetSlot(), true);
                    pItem->RemoveFromUpdateQueueOf(_player);

#ifdef ALE
                    sALE->OnSellItem(_player, pItem, creature, pItem->GetCount());
#endif
                    _player->AddItemToBuyBackSlot(pItem, money);
```

---

## Lua Usage

After applying this patch, Lua scripts can register for the event:

```lua
PLAYER_EVENT_ON_SELL_ITEM = 74

function onSellItem(event, player, item, vendor, count)
    local itemId = item:GetEntry()
    local itemName = item:GetName()
    print(player:GetName() .. " sold " .. itemName .. " x" .. count)

    -- Add to treasure pool
    Treasure.addToPool(itemId, count)
end

RegisterPlayerEvent(PLAYER_EVENT_ON_SELL_ITEM, onSellItem)
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| event | number | Event ID (74) |
| player | Player | Player selling the item |
| item | Item | The item being sold (still exists at this point) |
| vendor | Creature | The vendor NPC |
| count | number | Number of items being sold |

## Notes

- Hook fires BEFORE item is moved to buyback slot
- Item object is still valid at hook time
- Hook fires for both partial stack and full item sales
- Hook fires for player-initiated sales only (not bot auto-sell)

## Build Instructions

Patch is applied automatically by `scripts/apply-patches` (driven by
B006) before each build. A normal `./scripts/update` picks it up.

## Related

- `patches/B006-ale-sell-item-hook.sh` — the live B-patch and its inverse
- The treasure-pool consumer in `src/lua/treasure.lua` registers for
  `PLAYER_EVENT_ON_SELL_ITEM = 74`
