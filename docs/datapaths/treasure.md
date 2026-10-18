# Data path: treasure

*How an item moves on beta: out of a player's hands (sold, or left in a
chest), through the pool, into another player's next chest. Written
2026-10-17. The code is `src/lua-beta/treasure.lua.disabled` (summary:
`treasure.info.md` beside it), switched off until the owner answers
issue 200's open question 3; its offline test is `scripts/test-treasure`.
Issues 402 (the circulation) and 404 (selling).*

## The rule it keeps

An item exists once. It is in a player's bags, in a seller's buyback
tab, on its way through the pool, in someone's queue, in a chest, or
gone for good; never in two of those at once. Every step below is there
to keep that true.

## The path, in order

1. **A sale** (`Treasure.onSellItem`, the sell event 74 that patch B006
   adds). It fires after the item leaves the bags and before the server
   puts it in the vendor's buyback tab. The sale goes on the seller's
   **counter**, marked for recycling if it is uncommon or better, not a
   quest item, and does not stack (`Treasure.isRecycled`). Its level is
   its required level, or its item level when it has none
   (`Treasure.saleLevel`).
2. **The counter** (`Treasure.settleCounter`, at each sale and at
   logout). Anything found back in the seller's bags by its GUID was
   bought back, and leaves without entering the pool. Past 12 entries,
   the oldest was pushed out of the buyback tab and deleted by the
   server: released. At logout, the rest was deleted by the logout save:
   released. Released and marked: into the pool, remembering who sold it.
3. **The pool** (`Treasure.addToPool`). Each item goes at once to a
   player (step 4); if nobody fits, it waits in the global pool, tried
   again at every login (`Treasure.processGlobalPool`).
4. **The choice** (`Treasure.findEligiblePlayer`). Real players only: no
   bots (they never open chests), not a player who is logging out, never
   the item's own seller. Within 3 levels of the item. The shortest queue
   wins; ties take turns in login order (the mancala).
5. **A player's queue** (`Treasure.playerQueues`). Items wait for that
   player's next chest. At their logout the queue goes back through the
   pool to the others.
6. **A chest** (`Treasure.spawnTreasure`, by the `#treasure` command
   today; nothing else spawns chests yet). 20-35 yards from the player,
   the kind chosen from those fitting their level. The player's whole
   queue moves onto it, held back until a second player opens it
   (`chest-vulnerability.lua.disabled`, issue 408; the owner's open
   question).
7. **Looting** (`Treasure.onLootItem`). A looted item is struck from the
   chest's record, so it is not returned.
8. **The chest's end** (`Treasure.expireChest` after 5 minutes, or the
   game removing it with its owner at logout; both reach
   `Treasure.onChestRemove`, the removal event 13). Whatever was not
   looted goes back to step 3, at its own level, with its seller still
   remembered.

## The data it keeps

Every item record has the same shape, wherever it is:
`{ itemId = number, itemLevel = number, count = number, seller = low
GUID (number) or nil }`.

| Where | Name | What (type) |
|---|---|---|
| script | `Treasure.globalPool` | item records nobody fits yet (list) |
| script | `Treasure.playerQueues[guid low]` | item records waiting for that player's next chest (list) |
| script | `Treasure.activeChests[chest guid low]` | `{ chestID, spawnerGUID, spawnTime, queueItems, pendingLoot, lootInjected, mapId, instanceId }` |
| script | `Treasure.counters[seller guid low]` | sales that may still be in the buyback tab, oldest first: item records plus `guid` (the item's full GUID) and `recycle` (boolean) |
| script | `Treasure.leaving[guid low]` | `true` while that player's logout runs |
| player | `"treasureChests"` | chest entries that fit their level, drawn from at random (list of numbers) |

All of it is in memory: a restart empties the pool, the queues and the
counters. Nothing is written to the database.

## What the server decides, and where (read from `source-beta/`)

| Fact | Where |
|---|---|
| The buyback tab holds 12; a 13th sale deletes the oldest | `BUYBACK_SLOT_START`/`END`, `Player.h`; `Player::AddItemToBuyBackSlot` |
| The tab is deleted at the logout save | `Player::_SaveInventory` |
| Buying back returns the same item, same GUID | `WorldSession::HandleBuybackItem` |
| Lua cannot see the tab (position and GUID lookups skip it) | `Player::GetItemByPos`, `Player::GetItemByGuid` |
| The sell event fires after the item leaves the bags | `HandleSellItemOpcode`, patch B006 |

## Known gaps

- A loot event does not say where an item came from, so looting a
  creature can strike a matching item from a chest's record: that item
  is lost from circulation (never duplicated). Issue 402, fault 6.
- An item bought back and then traded or mailed before the next check
  is counted as gone and enters the pool too: a second copy. Issue 404,
  open question 2.
- A recycled sale still pays the vendor price, so an item passed between
  two players makes money each time. Issue 404, open question 1.

## How it came to be

The pool began in April as one shared first-in-first-out list, then
became per-player queues with level matching and the mancala (issue
402's design refinement). It was switched off with every other beta
feature on 10 April for the profile baseline. On 2026-10-17 its faults
were fixed and checked in the toy world, the despawn return was wired
to the game's removal event, and selling was added with the counter,
after reading how the server keeps the buyback tab showed that a sale
cannot go straight into the pool.
