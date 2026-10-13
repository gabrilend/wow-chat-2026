# 617h1 - The Selling Trip: Full Bags Send a Buddy to a Vendor

## Status
- Created: 2026-10-03
- Phase: 6
- Parent: 617h
- Blocked by: 617e4 (the town visit's selling), 617o1 (walking on the mesh)
- Priority: High (seen live: a full buddy whispers its owner over and over)

## Origin

Seen live, 2026-10-03: Marvaria (Maroon's buddy) had full bags "and she
keeps spamming her owner about it instead of going home to sell". The
owner: "I think we should build that behavior into them - they should
move to the nearest town / vendor and sell what they need to."

## Current Behavior

**Waits for "go sell", 2026-10-12 (617y; syntax-checked, not yet built).**
A buddy past full no longer sets off by itself: it says "My bags are full."
where its owner sees it, and goes when a player in its owner's group says
"go sell" (`BuddyTakeSellOrder`, at the trip's start). The owner: "we need
the whisper to know when we should send them".


**The selling trip: written 2026-10-03, syntax-checked, not yet built or
run** (see the steps). Before it: a buddy sells only on a town visit,
which happens only when its owner is in a town (`buddies_town.cpp`: junk,
the auction rules' leftovers, and, past 90% full with no auction house in
town, the three-round clearance). Out in the country a full buddy keeps
looting, each failed pickup making the bot module whisper the owner "My
bags are full" (`InventoryChangeFailureAction`), though buddies never
chat.

**Full bags in a dungeon: written 2026-10-03, syntax-checked, not yet
built or run** (`buddies_dungeon_bags.cpp`, step 4). Two loot items that
each fit alone but not together get room made for the first only; the
second stays on the body until the buddy looks again.

## Intended Behavior

(The selling trip, out in the world; then full bags inside a dungeon,
where no vendor can be walked to.)

- **When**: a roaming buddy whose bags are 90% full or more (the town
  visit's own threshold) and that isn't fighting.
- **Where**: the nearest vendor, as the crow flies, on the same map: any
  creature that sells, read once from the world database (its spawn
  spot). A vendor given up on is skipped for 10 minutes.
- **The walk**: toward the vendor's spot, a stretch at a time on the mesh
  (617o1's rules); near it, the vendor itself is found and approached.
  Not there within 3 minutes: given up.
- **The sale**: what the town visit sells (junk, the auction rules'
  leftovers, and the clearance past 90%), silently, then it buys its
  meals as the town visit does.
- **After**: roaming resumes; being in another area than its owner, the
  buddy's travel brings it back.
- **No more whispers**: the bot module's "My bags are full" (and its
  other failed-item lines) are not sent for buddies (source patch B048,
  on B044's list of companion accounts).
- **Full bags in a dungeon** (the owner, 2026-10-03: "if a buddy-bot's
  inventory is full while in a dungeon, they should try and give their
  most valuable item (that they would otherwise sell to a vendor or
  auction) to a clan mate. Failing that, they should destroy their least
  valuable item unless the item they're trying to loot is less valuable,
  in which case they will just leave it on the body or chest or
  whatever."): when a buddy in a dungeon opens a body or chest, each item
  it may take that its bags can't hold is made room for, in order:
  1. its most valuable disposable item (one it would sell to a vendor or
     auction: grey, or judged "vendor" or "auction" by the bot module) is
     given to a clan-mate (another of its owner's buddies, alive, in the
     same dungeon) whose bags hold it;
  2. failing that, its least valuable disposable item is destroyed,
     unless the item it is trying to loot is worth less, in which case
     the loot is left where it lies;
  3. with nothing disposable, the loot is left.
  "Value" is the vendor's price for the whole stack (the auction rules
  start from that price too, 617h).

## Suggested Implementation Steps

1. `buddies_town.cpp`: the selling a vendor visit does, callable from
   elsewhere (`BuddySellAtVendor`), and the bag share (`BuddyBagFullness`).
2. `buddies_roam_strategy.cpp`: the trip (the vendor list, the walk, the
   sale), ahead of the monster approach, with trace lines.
3. `patches/B048-playerbots-buddies-quiet-inventory.sh`: the bot module's
   failed-item whisper skipped for companion accounts.
4. `buddies_dungeon_bags.cpp`: the dungeon rule, on the server's "before
   a loot window is sent" moment (a stock script hook): which items the
   buddy may take, the disposables (`buddies_town.cpp` names them, as
   its selling does), the hand-over and the destroying, with trace and
   log lines.

## Related Issues

- **617h** parent; blocked by **617e4**, **617o1**; **617a5** (B044's
  list of companion accounts)
