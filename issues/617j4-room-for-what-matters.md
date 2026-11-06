# 617j4 - Room for What Matters

## Status
- Created: 2026-10-27
- Phase: 6
- Parent: 617j (buddy loot rolls and upgrades)
- Related: 617j1 (loot turns), 617h1 (the selling trip: what empties
  bags today), 617a4 (the starting kit: bags), B046 (the playerbots
  module's loot judgement for buddies), `buddies_loot.cpp`
- Priority: High (a won upgrade was lost, 2026-10-26)
- State: step 2 (the worth order) built 2026-11-06 in Lua
  (`src/lua-basic/lib/buddy-item-plan.lua`); steps 1, 3, 4 and 5 not

## Origin

The owner, 2026-10-27, after Matis won green bracers with a need roll
and never had them (his backpack was full and he had no bags):

> buddies shouldn't always get bags. They should find them. Though, they
> should be spawned from Sargobras with the same number of slots that the
> player has.
>
> also, buddy-bots should destroy items if they need to loot something. I
> don't see buddy-bots looting anything, so we should make sure that their
> functionality there is fixed. For this case, a full inventory prevented
> the looting of a green - which is more important than plenty of items in
> inventory, presumably. Especially because it was "need"ed. Buddy-bots
> should prioritize almost anything lower than a gear upgrade. Gear
> upgrades are precious and beloved and cherished and celebrated.
> Sometimes, they are posted to guild chat to celebrate. But the bot
> should be HAPPY if they do.

## Current Behavior

- **Bags**: a buddy is made with bags like its owner's (617a4; "the same
  number of slots that the player has", as the owner wants); an owner with
  none gives buddies none. On 2026-10-27 Feldowinn and her six buddies had
  none; four Mageweave Bags each were given by hand (and the `travel-bags`
  gearset profile now does it in game).
- **Looting**: the owner sees buddies loot nothing. Their trace shows the
  loot actions ("add all loot", "loot roll") tried and failing every tick
  (`Playerbots.log`, "A:loot roll - FAILED"); why is not yet known.
- **Full bags**: a buddy that wins a roll with no room loses the item
  (Matis, 2026-10-26: a need-rolled green, gone).

## Intended Behavior

1. **Bags are found, not given**: none beyond the starting kit's (its
   owner's slot count, at its making by Sargobras); new bags come from
   loot, vendors and the owner, as for a player.
2. **Buddies loot**: corpses and chests they kill or open, as the owner
   expects to see.
3. **Room is made for what matters**: when a buddy must take an item and
   has no room, it destroys the least worth item it carries to make room.
   What may go, first to last: grey junk, then common trade goods and food
   it has plenty of, then anything else that is not a gear upgrade, its
   ammo or soulbound gear it wears. Quest items go as white items do (the
   owner, 2026-11-05: "treat them like "white" quality items"; one nobody
   pays for is never picked up, 617h2). A gear upgrade is never what goes, and
   a gear upgrade (or anything won with a need roll) always gets its room.
4. **Upgrades are celebrated**: a buddy that loots or wins an upgrade puts
   it on, and is happy about it: an emote (cheer, dance), and sometimes (a
   chance, not every time) a line in guild chat naming the item.

## Suggested Implementation Steps

1. Find why the loot actions fail for buddies: the playerbots module's loot
   strategy and the buddy module's changes to it (B046, `buddies_loot.cpp`),
   with the movement trace (`.buddy trace <name>`) while killing near a
   corpse. Fix that first; nothing else matters while nothing is looted.
2. A worth order for a buddy's items (a pure function with a test): given
   what it carries (quality, sell price, stack, kind, soulbound, an
   upgrade by its own gear scoring), the order in which they may be
   destroyed; an upgrade or a need-won item never in the list.
3. Before taking an item (loot, a won roll) with no free slot: destroy the
   first of that order; a log line names it.
4. On an upgrade worn: an emote, and a guild-chat line now and then.
5. Seen in game: a buddy with full bags wins a green, destroys a grey,
   wears the green, cheers.

## Open Questions

Gathered 2026-10-28 into 617's own list (question 26), merged with the
same questions from other sub-issues; answers are written back here.

- **Answered 2026-10-28** (617's question 26): "It's the opposite actually,
  you should prioritize full stacks over partial. One or two of a thing is
  less valuable than 20." When room is short, small part-stacks go first;
  full stacks are kept.
- **Answered 2026-10-28** (the upgrade line): "When it's a big upgrade. If
  they are congratulated they should say what they're replacing too. Each
  buddy-bot has a 10% chance to congratulate them." A big upgrade is
  announced in the guild; each other buddy has a one-in-ten chance to
  congratulate; a congratulated buddy answers with what it replaced.

1. **"Plenty of"**: when is a stack of trade goods or food "plenty" (to be
   destroyed before other items), and is selling it next time in town
   better than destroying it now?
2. **How often a guild line**: every upgrade of rare quality or better,
   one in five of the uncommon ones, or something else? And its words:
   fixed lines, or the chat layer's (920)?
3. (Answered 2026-10-27: "yes") **Need rolls with full bags**: a buddy
   with no room and nothing it may destroy passes the roll.

## Decisions, 2026-11-06 (an agent, answering what was still open)

Built: step 2, the worth order, as `Plan.room_order` and `Plan.make_room`
in `src/lua-basic/lib/buddy-item-plan.lua` (617h2's per-item plans, as
617u's 2026-10-28 answer puts a buddy's item lists in Lua), tested in
`scripts/test-buddy-item-plan` (the owner's scene: full bags, a won green,
a grey goes; stacks; what never goes; quest items as white ones; 400
random bags against a referee; 24 of 24 mutants caught, and 2 of 2 for
the quest-item change). Not built: step 1 (why buddies don't loot: needs
the game and the trace), step 3 (calling it before a loot or a won roll:
`buddies_loot.cpp`, needs the server), steps 4 and 5 (the cheer and the
guild line, seen in game).

1. **"Plenty of"** (question 1): a part-stack of a common (white or grey)
   trade good or food is "plenty" when the buddy also holds a full stack
   of the same item; such part-stacks go right after grey junk. Destroying
   happens only when an item must be taken now with no free slot, so
   selling it next time in town is not an option at that moment; the
   vendor still gets everything else (617h).
2. **The rest, in plan order**: what would only be sold goes first (junk,
   vendor), then what would be auctioned or given away, then food for its
   pet, reagents, and last what it keeps to use; within each, part-stacks
   before full stacks (the owner's 2026-10-28 answer), then the cheapest
   by vendor price times the stack.
3. **Never destroyed**: what 617h2 says it can't spare (hearthstone,
   tools, fishing pole, kept weapons, the stacks of ammo it fires and
   keeps: the owner, 2026-11-05, "ammo needs to be kept"), need-won items.
   A gear upgrade is worn at once, so never sits in the bags. Quest items
   (changed 2026-11-05, from "never destroyed"): the owner's answer in
   617h2 makes them white items, so one with a price is ranked as a white
   item (a trade good when a profession uses it), and one nobody pays for
   is never in the bags, nor given room.
4. **An item worth no more than the least it carries is left behind**
   rather than swapped for it; an upgrade, a need-won item, something to
   open or learn, and anything that may never go always get room when
   anything may go (with nothing that may go, a need roll is passed: the
   2026-10-27 answer).
5. **Question 2** (how often a guild line, and its words) is left open:
   step 4 isn't built, and the 2026-10-28 answer already says "when it's a
   big upgrade".
