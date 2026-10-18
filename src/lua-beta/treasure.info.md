# treasure.lua (treasure.lua.disabled)

Treasure chests on beta, and the circulation behind them: every item
exists once and keeps moving, from a player's hands (sold, or left in a
chest) through a pool to another player near its level, who finds it in
their next chest. Issues 402 and 404; the whole path is in
`docs/datapaths/treasure.md`. Switched off (the `.disabled` name) until
the owner answers issue 200's open question 3. Checked offline by
`scripts/test-treasure`.

An **item record**, everywhere below: `{ itemId = number, itemLevel =
number, count = number, seller = low GUID (number) or nil }`.

## Settings (top of the file)

| Name | Value | Meaning |
|---|---|---|
| `ITEM_LEVEL_RANGE` | 3 | levels either side of an item that a player may be |
| `CHEST_LIFETIME_MS` | 300000 | how long a chest stays, in milliseconds |
| `RECYCLE_MIN_QUALITY` | 2 | lowest quality recycled when sold (2 uncommon) |
| `QUEST_ITEM_CLASS` | 12 | item class never recycled |
| `BUYBACK_SLOTS` | 12 | the server's buyback tab size |

## The circulation

### `Treasure.getOnlinePlayers() -> list`
The real players who can receive items, in login order:
`{ { player, level (number), guid (low, number) }, ... }`. No bots, no
one whose logout is running.

### `Treasure.findEligiblePlayer(itemLevel, seller) -> entry or nil`
The player an item goes to: within range of its level, not its seller,
the shortest queue, ties in turn. Nil when nobody fits.

### `Treasure.distributeToQueue(itemId, itemLevel, count, seller) -> boolean`
Puts one item on the chosen player's queue; false when nobody fits.

### `Treasure.addToPool(itemId, itemLevel, count, seller)`
Hands an item to a player at once, or keeps it in the global pool.

### `Treasure.processGlobalPool()`
Tries every waiting item again (at each login, and after a logout).

### `Treasure.getPlayerQueue(playerGUIDLow) -> list`
A player's queued item records, emptying the queue.

## Chests

### `Treasure.spawnTreasure(player)`
Summons a chest of a kind fitting the player's level, 20-35 yards away,
moves their queue onto it (held until a second player opens it), and
starts its lifetime. A level no chest fits: logged, nothing spawned.

### `Treasure.injectPendingLoot(chest) -> boolean`
Called by `chest-vulnerability` when a searcher opens a tracked chest:
adds generated base loot and the held queue items, once.

### `Treasure.generateBaseLoot(chest, chestData) -> list`
A little level-appropriate loot for a chest (placeholder items for
levels up to 20).

### `Treasure.isTrackedChest(chest) -> boolean`
Whether a chest is one this script spawned.

### `Treasure.expireChest(eventId, delay, repeats, chest)`
The chest's lifetime timer: takes it out of the world.

### `Treasure.onChestRemove(event, chest)`
The game's removal event for chest entries: returns the unlooted queue
items to the pool (`Treasure.returnToPool`).

### `Treasure.returnToPool(chestGUIDLow)`
Sends a chest's remaining queue items back into circulation and forgets
the chest.

## Selling

### `Treasure.onSellItem(event, player, item, vendor, count)`
The sell event (74, patch B006): puts the sale on the seller's counter.

### `Treasure.settleCounter(player, atLogout)`
Drops sales that were bought back (found in the bags by GUID); releases
those surely deleted (past 12, or all at logout) into the pool when
marked for recycling.

### `Treasure.isRecycled(item) -> boolean`
Uncommon or better, not a quest item, does not stack.

### `Treasure.saleLevel(item) -> number`
Required level, or item level when there is none.

## Players

### `Treasure.setupTreasure(event, player)`
Login: fills the player's list of fitting chest kinds, clears their
leaving mark, tries the waiting items.

### `Treasure.onPlayerLogout(event, player)`
Logout: marks them leaving, settles their counter, returns their queue
to the pool for the others.

### `Treasure.regenerateQueue(player)`, `Treasure.getRandomChestFromQueue(playerGUID)`, `Treasure.addTreasure(playerGUID, chestID)`
The player's list of chest kinds: refill, draw one at random, add one.

### `Treasure.onLootItem(event, player, item, count)`
Strikes a looted item from the chest records (see the known gap in the
data-path page).

### `Treasure.handleChat(event, player, message)`
Test commands: `#pooladd <item> <level> [count]`, `#poolsize`,
`#myqueue`, `#treasure`.
