# 617u - Buddy Errands in Lua

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617 (buddy bots)
- Blocked by: None
- Priority: Medium

## Origin

Verbatim, 2026-10-04: "can we actually handle buddy-bot inventories in
lua, and just fake talking to the NPCs in the town? Same for their spell
learning."

## Current Behavior

Not built. Buddies' town errands (selling, repairing, training: 617e4,
617h, 617n) are C++ in the buddy module and walk to the real NPCs and use
their windows the bot module's way.

## Intended Behavior

Buddies' inventories (selling, buying, repairing) and spell learning are
done by Lua scripts: the buddy still walks to the vendor or trainer and
stands there a moment (a pretend conversation), and the script makes the
trade itself: items sold for their price, repairs paid, spells taught and
paid for, by the same rules as now.

## Suggested Implementation Steps

1. The errand list as now, its effects moved to Lua (the Lua engine can
   sell, add and remove items, take money and teach spells).
2. The C++ errands kept for the walking and standing.

## Open Questions

1. Why Lua: easier to change while the server runs (reload), or something more?
