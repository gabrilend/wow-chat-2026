# 617e8 - Following the Owner Across Maps

## Status
- Created: 2026-10-02
- Phase: 6
- Parent: 617e
- Blocked by: 617e4 (the walk to the owner's area, which this extends past
  the edge of a map)
- Priority: High

## Origin

Verbatim, 2026-10-02, on reading that a buddy "won't follow you across
continents or into instances; it logs that once and stays put":

> should re-open this issue file or something because they need to be able
> to walk across continents. Are you talking about like, between Lordaeron
> and Azeroth? The Thandol Span I think it's called? Or do you mean like, to
> Outland? Either way we need both behaviors eventually.

The design it builds was settled in 617e, 2026-09-25 (Ritz): "The
buddy-bot should move toward the mechanism that allowed the distance at
their earliest convenience and attempt to rejoin the player."

## Current Behavior

Not built. A buddy follows its owner only within one **map**: the server's
unit of world, one per continent plus one per instance. Lordaeron and
Azeroth are one map (Eastern Kingdoms, map 0), so the Thandol Span, the
Deeprun Tram's two ends and every road between them are already walked by
617e4's "buddy travel" (the bot module's long walk on the navigation mesh,
re-aimed at the owner each step). What stops a buddy is a change of map:

| Owner goes | Map change | Today |
|---|---|---|
| boat or zeppelin, Eastern Kingdoms ↔ Kalimdor | 0 ↔ 1 | buddy stays, logged once |
| the Dark Portal into Outland (155l: the only door) | 0 → 530 | buddy stays, logged once |
| boat or zeppelin to Northrend (155s, not designed) | 0/1 → 571 | buddy stays, logged once |
| into a dungeon or raid | → instance map | handled apart: the dungeon draw (617c3) takes drawn buddies in; the rest stay out by design (617e: rest, quest, or a graveyard walk) |
| hearthstone | any | designed in 617e (buddies hearth after the owner), not built |

The bot module already holds what a crossing needs: a precomputed graph of
travel nodes whose links are walks, flights, boats and zeppelins
("transport" links, with the transport's id), and portals
(`source-beta/modules/mod-playerbots/src/Mgr/Travel/TravelMgr.*`,
`TravelNode.*`; the owner, 2026-09-29: "travel mesh will come in handy
later, don't lose track of it").

## Intended Behavior

- **Notice the means.** When the owner leaves the buddy's map, the module
  records how: which transport the owner was riding when the map changed
  (boat or zeppelin, by its id), or the area trigger stepped through (the
  Dark Portal), or neither (a summon, a mage's teleport, a hearthstone).
- **Finish, then go.** Each buddy finishes the task it is on (as in towns,
  617h), then walks to that same means on its own map: the dock or tower
  the owner's boat or zeppelin left from, or the Dark Portal.
- **Ride it.** At a dock it waits for the transport, boards when it is
  docked, and rides; at a portal it steps through. Boarding is what a
  player does: standing on the deck as it leaves, never a teleport onto it.
- **Rejoin.** On arrival it resumes 617e4's walk to the owner's area, and
  roaming (617e1) from there.
- **A means it can't use** (a summon, a mage's teleport): it heads for the
  nearest way to the owner's map it can use, chosen on the bot module's
  travel graph (the 617e decision: "it heads for the nearest way there it
  can use"). Hearthstones follow 617e's own design.
- **Owner comes back first**: a buddy still on its way to the dock when the
  owner returns to its map drops the crossing and walks to the owner.
- **Failure is loud**: a buddy that can't find the means, misses three
  sailings, or lands off the navigation mesh logs where it stood, what it
  was waiting for, and what it had done so far, then pauses as other
  failures do.

## Suggested Implementation Steps

1. **The owner's crossing record**: on the owner's map change, note the
   transport they stood on (the player's transport, read before the
   teleport completes) or the area trigger used, and the spot they left
   from. Kept per owner in memory; a new crossing replaces it.
2. **Walking to the means**: extend "buddy travel" (617e4) so that a
   different map with a crossing record walks to the departure spot
   instead of logging and staying.
3. **Boarding**: wait within reach of the dock; when the recorded
   transport is docked there, move onto it. The server's transports are
   map objects that carry passengers standing on them; read how the bot
   module boards in its own transport travel before writing new boarding.
4. **Portals**: walk into the Dark Portal's area trigger like a player.
5. **No crossing record** (summon, teleport): ask the travel graph for the
   cheapest route to the owner's map using walks, transports and portals
   only (no flights: basic has none but the Isle's, 155l).
6. **Tests**: a buddy left in Menethil when its owner sails to Theramore
   rides the next boat and walks to the owner; a buddy in Elwynn follows
   through the Dark Portal; a buddy whose owner is summoned to Kalimdor
   picks the nearest boat or zeppelin.

## Related Issues

- **617e** parent (the 2026-09-25 decision on the owner far away)
- **617e4** buddy travel, which this carries past a map's edge
- **617c3** dungeon draw (instances, kept apart)
- **155l** the Dark Portal as the only door into Outland
- **155s** Northrend at sixty (not designed; its boats come with it)

## Open Questions

- **Portals costing a reagent**: 617e records "we should make portals cost
  a crafting reagent from Jewelcrafting or enchanting". Does that mean the
  Dark Portal itself, the mage portals buddies might use, or portals a
  buddy opens in place of the owner's means?
- **Waiting at the dock with the owner gone**: while waiting, does the
  buddy stand still, sit, or roam the dock town (617h's wandering)?
- **Missed sailings**: three missed sailings before giving up is a first
  guess; should a buddy instead wait forever?
