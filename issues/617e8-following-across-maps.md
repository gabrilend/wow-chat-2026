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
- **The same ship** (built 2026-10-02, the owner's "move the buddy bot to
  the same dock"; `NoteWaiting`, `StepSameShip` in `buddies_crossing.cpp`):
  - an owner within 60 yards (flat) of any ship's stop on its map is
    waiting to sail at once (no dwell, 2026-10-02); aboard a ship that is
    in, it is waiting aboard that ship (its boarding spot and deck spot
    noted); stepping back off before it sails is waiting on the dock again;
    more than 90 yards from every stop, or into an instance, it is not
    waiting. Each of these changes takes a new stamp;
  - its buddies on the same map are then the crossing's ("buddy travel"
    runs it), except one partway through a town errand, which finishes the
    errand first (`BuddyTownErrandUnderway`, `buddies_town.cpp`); pastimes
    (sitting, sleeping, fishing, wandering) give way at once;
  - **the beat**: each buddy answers each stamp only after its own random
    1–3 s (`InBeat`), so a clan doesn't move as one;
  - **owner on the dock**: the dock's ship is the one whose stop is nearest
    the owner (`NearestStop`). Each buddy holds an unheld embark recording
    start of that ship at that stop, walks to it and waits on it facing the
    way it began. With no recording there it waits within 6 yards of the
    owner instead (a "FALLBACK" warning, once per buddy per dock). A buddy
    standing at *another* stop of that same ship (an island dock, such as
    Auberdine and Rut'theran Village, which no walk joins) doesn't walk:
    it takes that ship from where it stands, as a transport trip;
  - **owner aboard**: each buddy boards that same ship from the owner's
    boarding spot; a start it already holds for that very ship is kept, so
    it walks the recording from where it waits (617e9);
  - aboard with the owner aboard too, a buddy stays aboard, even at a dock
    on the owner's map (so a buddy that boarded with its owner doesn't step
    straight back off); the owner stepping off, there or at the far dock,
    is what sends it ashore;
  - **owner jumps off** a ship that isn't at a stop (a zeppelin in the air,
    a boat at sea), seen as leaving the ship while within 40 yards of it:
    each buddy aboard that ship, after its own beat, judges where it could
    land (`PickLanding`, built 2026-10-02 for the owner's "only jump if the
    fall is survivable or they could aim to land in water of a sufficient
    depth"): 25 points out to 32 yards, toward the owner first, each within
    a running jump's carry for its drop. Deep enough water (the server's
    own swimming depth) is aimed for at once; otherwise the survivable
    ground landing with the least damage, judged by the server's own
    fall-damage rule at basic's 10× rate against its current health
    (`FallDamage`, Player::HandleFall's formula and exemptions copied);
    otherwise it stays aboard and rides round, logged with how many
    landings would have killed it (an error when no ground at all was
    found below). Jumping: taken off the passenger list, the server's jump
    move paced so the drop takes as long as a real fall. Nothing else moves
    it until it lands. On landing on ground the server's fall handling is
    run for it by hand (a bot sends no landing report, so without this a
    buddy took no fall damage at all), outside the crossing's lock since a
    fatal fall runs death hooks; in deep water nothing is dealt. Then the
    crossing is over and "buddy travel" walks (the bot module's long walk
    swims through water). A jump older than 30 s is not followed;
    syntax-checked, not yet compiled or tried in game;
  - the owner walking away releases its buddies (any held recording too);
    a ship that sails with the owner and without a buddy is followed as a
    crossing (above), from that same dock.
- **Boarding by recording** (617e9): a dock with embark recordings for the
  ship has the buddy walk to a recording's start (a free one, nearest
  first), wait there facing the way it began, and walk it once the ship is
  in; a stop with disembark recordings has it step off the same way. A dock
  with none uses the straight walk above, logged once per boarding as a
  warning beginning "FALLBACK", naming the ship and dock and how to fix it.
  A ship that sails before the buddy reached its deck is a missed sailing:
  back to the recording's start.
- **Owner comes back first**: a buddy not yet aboard drops the trip and
  walks to the owner.
- **Riding without the owner** ("ride it round", 2026-10-02; `StepAboard`):
  docked on the owner's map, a buddy steps off only at the stop of this
  route nearest the owner, and rides on past any other; docked off the
  owner's map, it rides on while the route reaches the owner's map at all,
  so it usually stays aboard until the ship loops back. A route that never
  reaches the owner's map (the owner went on elsewhere) is left at its
  next stop, and the way is planned afresh from there. Riding on is logged
  once per docking. "Fastest" is read as "the stop nearest the owner":
  route times aren't compared (see Open Questions).
- **Failures** are logged as errors in the house shape (what failed, what
  was done, where the buddy and the owner stood, what to check). The buddy
  is paused a minute, then plans again from the start. They are: no way
  found, a transport's deck spot never learned, no pier known, an area
  trigger missing, three missed sailings, no spot ashore, and (617e9) a
  boarding recording that couldn't be walked (a leg stuck or repeatedly
  short, the ship gone mid-recording, an embark that ended off the deck).
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
- **Same ship as the owner, when possible** (Ritz, 2026-10-02: "how about
  we also detect when you are standing at a dock / on a ship / waiting for
  a zeppelin and move the buddy bot to the same dock? The goal is to get
  them to take the same ship as you if possible."): an owner standing at a
  dock or zeppelin tower (near a stop on a transport's route), or aboard a
  ship, is read as waiting to sail. Each buddy then finishes its task and
  walks to that same dock to board the same sailing, using a boarding
  recording (617e9) when one exists. An owner who walks away from the dock
  without sailing releases them.
- **No dwell, a human beat** (Ritz, 2026-10-02: "8 seconds might be a
  little too long. If you're on a dock, they should go to the dock too. If
  you're on a boat, they should board too. No need to wait, although +/-
  1-3 seconds could be a good way to get them to seem a bit more
  natural."): the owner on a dock sends buddies to it at once, and the
  owner aboard sends them aboard at once; each buddy starts after its own
  random 1–3 seconds, so they don't move as one.
- **Straight to a starting spot** (Ritz, 2026-10-02: "they should move to a
  starting point as soon as you enter the dock. Also, if you leave the
  dock, they do whatever they normally would be doing."): as soon as the
  owner is on the dock, each buddy goes to an unheld recording start for
  that stop (617e9) and waits there, rather than near the owner; the owner
  leaving the dock returns them to whatever they would otherwise do.
- **Jump when the owner jumps** (Ritz, 2026-10-02: "If you jump off the
  zeppelin while it's in mid-air or off of the ship into the water, they
  jump with you."): an owner leaving a moving ship by jumping (off a
  zeppelin in the air, or off a boat into the water) has every buddy
  aboard that ship jump off too, from where it stands, after its own
  1–3 second beat; then it follows as usual from wherever it lands.
- **Missed the window: ride it round** (Ritz, 2026-10-02: "If they missed
  the window and end up sailing to the other side of the world, that's
  fine, they just wait until they're back, attempting to travel to
  whichever zone you're in by the fastest route, which almost always will
  mean just... waiting on the boat until it loops back around again."): a
  buddy aboard a ship its owner is no longer on takes the fastest route to
  the owner's zone, which is usually staying aboard until the ship docks on
  the owner's side again; it gets off there, or wherever the fastest route
  says.
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
- **617e9** boarding recordings, replayed when boarding
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
- (Answered 2026-10-02) **Deck spots before anyone rides**: the owner will
  record boardings at each dock (617e9: "go to each boat and record myself
  embarking and disembarking like 10 times per stop"). A dock with an
  embark recording no longer needs a deck spot learned since startup. A
  ship with no recording at a dock, and nobody seen aboard, is still a
  failure there.
- (Answered 2026-10-02) **How long a ship waits**: buddies go to a
  recording's start as soon as the owner is on the dock (Intended
  Behavior, "Straight to a starting spot").
- (Answered 2026-10-02) **Arriving at a dock without sailing**: the owner
  on a dock is the owner on a dock, arriving or leaving ("If you're on a
  dock, they should go to the dock too"); buddies left on that map head
  for it.
- (Answered 2026-10-02) **Which ship, at a dock that serves two**: the
  nearest stop's ship, "so long as they dynamically re-calculate if you
  move within a certain radius of the other stop" (Ritz). Built: the pick
  is taken from the owner's present spot, and the owner coming within 30
  yards of a different stop than the one picked drops the pick and picks
  again (`DOCK_REPICK_YARDS`, logged as a switch).
- (Answered 2026-10-02) **A landing that leaves a sliver of health**:
  survivable is survivable, 1 health left included: "yeah that's fine."
  (Ritz) The stays-aboard log now reports the gentlest landing's damage
  against the buddy's health, not a count of deadly landings (the owner:
  "won't that answer always be 25?"; nearly so, since the points in reach
  usually share one drop).
- (Answered 2026-10-02) **Fall damage on a jump** (basic has 10× fall
  damage): "only jump if the fall is survivable or they could aim to land
  in water of a sufficient depth" (Ritz). A buddy jumps only when the fall
  to the ground below would leave it alive at its current health, or when
  water deep enough to break the fall lies within its jump's reach, and
  then it aims for that water. Otherwise it stays aboard and follows by
  the ship (riding round).
- (2026-10-02) **Fastest route, read simply**: riding without the owner
  steps off at the stop nearest the owner and otherwise rides on; it
  doesn't compare the ship's timetable against walking or another ship.
  A case where getting off early and walking would be faster is ridden
  round instead. Worth a real comparison (route timings plus walking
  distance), or is "nearest stop" right?
- (2026-10-02) **Island dock, buddy elsewhere**: a buddy at an island dock
  sails to its owner; a buddy on the same map but neither at the owner's
  dock nor at another stop of that ship walks toward the owner's dock,
  which may have no way by land (Rut'theran Village). Should such a buddy
  find the nearest stop of that ship instead?
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
