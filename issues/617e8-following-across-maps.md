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

**Built 2026-10-02, syntax-checked, not yet compiled or tried in game**
(`modules/mod-buddies/src/buddies_crossing.cpp` and `.h`; wired into
"buddy travel" in `buddies_town.cpp`; roaming and the town visit stand
aside while a buddy is aboard).

A map is the server's unit of world, one per continent plus one per
instance. Lordaeron and Azeroth are one map (Eastern Kingdoms, map 0), so
the Thandol Span and every road between them were already walked by
617e4's "buddy travel". This issue covers a change of continent.

- **Watching owners** (every real player, bots skipped):
  - Twice a second the player's footing is noted: the last ground it
    stood on, and on first being seen aboard a boat or zeppelin, the
    ground it boarded from and where on the deck it stood. That deck spot
    is also kept per transport, for buddies taking it without their owner.
    Elevators are ignored.
  - At a map change between two continents (the server's before-teleport
    hook, which fires while the player is still a passenger on the old
    map), the means is recorded: the transport it rode, with its boarding
    spot and deck spot; or the portal, found as the area trigger whose
    destination is exactly where the teleport lands. Anything else (a
    summon, a teleport spell, a hearthstone) erases the record. Into or
    out of an instance records nothing.
  - On first being seen ashore on the far side, the landing spot is noted.
- **The buddy's way**, chosen when the owner is on another continent:
  1. a mage buddy with a Rune of Teleportation casts its own Teleport
     spell whose destination (read from the server's spell-destination
     table) is on the owner's map, nearest the owner; never a Portal; a
     refused or interrupted cast is not tried again that trip;
  2. the owner's own recorded means, when it left from the buddy's map;
  3. the nearest portal on the buddy's map whose destination is the
     owner's map;
  4. the nearest stop of a boat or zeppelin whose route reaches the
     owner's map. The routes are read once from the transport templates
     and their flight paths (each wait on the route is a stop). Its pier
     is the nearest walking node of the bot module's travel graph within
     80 yards of the stop. Its deck spot is the one learned from any
     player seen aboard; when none is known, that is a failure (below).
- **Doing it**:
  - walking is the bot module's long walk to the dock or portal;
  - at a portal, inside its trigger, the buddy steps through by handing
    the server the "entered an area trigger" message, as the bot module
    does for its own bots;
  - at the dock it waits standing; when the transport is in (within 8
    yards of one of its route's stops, since the transport's own moving
    flag is private to it), it walks straight onto the deck spot and is
    put on the passenger list once there (what a client's report of
    standing on a deck ends in), then holds still while carried;
  - docked on the owner's map, it is taken off the list and walks
    straight ashore: to where the owner stepped off, else back to where it
    boarded (the owner came back first), else the travel graph's pier;
    then "buddy travel"'s usual walk goes on.
  - three sailings leaving without it is a failure.
- **Owner comes back first**: a buddy not yet aboard drops the trip and
  walks to the owner; one already aboard rides on and steps off when the
  transport is next in on the owner's map.
- **Failures** are logged as errors in the house shape (what failed, what
  was done, where the buddy and the owner stood, what to check). The buddy
  is paused a minute, then plans again from the start. They are: no way
  found, a transport's deck spot never learned, no pier known, an area
  trigger missing, three missed sailings, no spot ashore.
- Numbers: the tuning block of `buddies_crossing.cpp`, logged in
  `docs/balance-updates.md` (2026-10-02).

**Not built:** hearthstones (designed in 617e), Northrend (155s, not
designed; its boats would be found by the same route reading once
designed), the unstuck rule on the walk to a dock (617e4's applies only on
the owner's map), and anything for instances (617c3).

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
- **Mage buddies teleport, never portal** (Ritz, 2026-10-02: "they can
  only teleport, not create portals"): a mage buddy that knows a Teleport
  spell landing on the owner's new map, and carries its rune, may cast it
  instead of walking to a dock; it never casts a Portal, so other buddies
  still take the boat.
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

- (Answered 2026-10-02) **Portals costing a reagent**: "just mage portals"
  (Ritz), so the Dark Portal and the boats are free. The reagent itself was
  already considered and dropped in 617e (2026-09-27: a spell's reagent is
  client data, so the tooltip would keep naming the old one); it waits on
  the custom client. Ritz also recalled "they can only teleport, not create
  portals": a mage buddy may use its own Teleport spells but never opens a
  Portal for others. No earlier record of that rule was found, so it is
  recorded here as of 2026-10-02.
- (Answered 2026-10-02) **Waiting at the dock with the owner gone**: "yeah
  it can just wait at the dock, that's fine." (Ritz) It stands near the
  departure spot.
- (Answered 2026-10-02) **Missed sailings**: "um yeah sure 3 missed boats is
  fine." (Ritz) Three, then a loud failure.
- **Deck spots before anyone rides**: a boat or zeppelin nobody has been
  seen aboard since the server started has no known deck spot, so a buddy
  finding its own way (its owner summoned or teleported) can't take it
  until someone rides it once. Record every transport's deck spot ahead of
  time (a small table, or one measured at startup from the transport's
  shape), or accept the gap?
- **Mage teleport first**: a mage buddy teleports whenever it can, even
  when its owner took a boat it could follow. Is that wanted, or should
  the owner's own means come first and the teleport only replace a summon
  or a teleport?
- **Unstuck on the way to a dock**: 617e4's stuck rule (no 10-yard gain
  in 90 s) measures progress toward the owner, so it is off while walking
  to a dock or portal on another continent; the bot module's own
  teleport-to-destination is kept off too. Should the stuck rule measure
  progress toward the dock instead?
- **Off the deck in a straight line**: stepping aboard and ashore walks a
  straight line, since the navigation mesh has no deck. A gangway with a
  bend, or a zeppelin tower's platform, may need more than one straight
  leg. To be seen in game.
