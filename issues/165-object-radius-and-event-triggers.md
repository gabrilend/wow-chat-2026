# 165 - Object Triggers: Run Listed Actions When Something Enters a Radius

## Status
- Created: 2026-10-04
- Phase: 1 (server infrastructure: a backend tool other features build on)
- Blocked by: None
- Related: 164 (per-player unselectable creatures, another backend tool),
  617c2 (buddies joining their partner's group by distance, today a
  5-second look), 617j2 (item arrivals routed through a table, the same
  "data, not if-chains" shape), 916g (proximity gating for the chat
  module, which polls)
- Priority: Medium

## Origin

The owner, 2026-10-03, asking how buddies notice distance: "Can we make
like, custom hook triggers or something for when a character enters a zone
/ radius from another creature? Or are we polling periodically? I could see
that being a performance drain. Much better, in general, to follow a
stream of data rather than ask for it." Then: "We register a particular
game-object as having a radius. This radius is the kind of radius that
triggers when another gameobject enters it's field. It runs these
functions, A, B, and C, with these arguments, 1, 2, and 3, every time an
object enters the radius. Could do other such things like 'when a spell is
cast on this item' or whatever. Do you think that would be performant?"
2026-10-04: "yes please. expanding the server's backend capability
toolbox." Asked again 2026-10-30 whether to plan it, so the buddies'
5-second distance look (617c2) can go: "yes, but, why were we checking
every 5 seconds? What is it used for?" (answered in conversation: the
proximity party's seating, below in Current Behavior and in 617c2).

## Current Behavior

There is no way to say "when something comes within N yards of this
object, run these actions". Features that care about distance look on a
timer: the buddies' grouping every 5 seconds per player (617c2), the
roaming's monster look every second (617o4), the people-noticing every 5
seconds (617p). The server itself does have the mechanism: whenever a
unit moves far enough, a relocation pass tells every creature around it
(`GridNotifiers.h`: `PlayerRelocationNotifier`, `CreatureRelocationNotifier`,
`AIRelocationNotifier`, run from the unit's delayed relocation event in
`Unit.cpp`), and each creature's brain gets "this unit moved within my
sight" (`MoveInLineOfSight`), which is how a monster notices a player
entering its aggro radius. Nothing outside a creature's own brain can
listen to it, and game objects and players have no such brain.

## Intended Behavior

- **Registering a trigger**: a world object (creature, game object or
  player) can be given one or more triggers, each: a kind ("enters the
  radius", "leaves the radius"; later "a spell lands on it" and others),
  a radius for the radius kinds, an optional filter of what counts (any
  unit, players only, buddies only, a creature entry, a faction), and a
  list of actions, each an action and its arguments, run in order. Like
  617j2's item arrivals, the choice of what to do is made by looking up
  a table, not by a chain of tests.
- **Firing**: "enters" fires once when a unit that passes the filter is
  first seen within the radius, "leaves" once when it is next seen beyond
  it (a few yards of slack against flicker on the edge, as the buddies'
  60/75-yard grouping has).
- **Riding on the server's own pass**: the check is made where the server
  already tells creatures that a unit moved, so it costs something only
  when something moves near a registered object, and nothing at all for
  objects with no trigger. No timer.
- **Where actions come from**: actions are named functions in C++ (other
  modules register theirs by name), and Lua can register triggers and
  receive them as an event, so either side can use it.
- **Gone with their object**: a trigger is removed when its object leaves
  the world; a trigger can also be removed by name.
- **A buddy's bulletin board** (the owner, 2026-10-30, word for word:
  "buddies should be aware of everything within 70 yards of them. They
  should all be on the concern list. So, radius triggers only to put
  things up on the mental bulletin board, or remove them if they're far
  enough away. Though certain bosses might have more important issues
  and flag carriers in PvP should be entirely line-of-sight based (from
  the bot's head, not their feet)"). The first user: each buddy (and
  bot) carries a 70-yard trigger whose only actions are to pin what
  enters onto its concern list and unpin what leaves (with the slack
  above). What the buddy does about what is pinned is decided from the
  list, not by the trigger. Two exceptions: a boss may be marked as
  mattering beyond the usual (on the board whatever its distance while
  the fight lasts); and in PvP a flag carrier is always on the board,
  with its place known only as well as the buddy has seen it (line of
  sight measured from the buddy's head height, not its feet).
- **The flag carrier, where it probably is** (the owner, 2026-10-30,
  correcting an earlier reading of the line above, word for word: "no
  the flag carrier is always on the list, we just only know it's
  location if we can see it or if we can see it recently. Allies might
  also say things like "flag on roof" or "flag in the flag room" or
  something that, while ambiguous, might be helpful in updating our
  expected location of the flag carrier. Otherwise it's just where we
  last saw them. At a distance, a flag carrier entering the tunnel might
  be planning to move elsewhere, perhaps to the roof, possibly to the
  flag room, or otherwise. There's the graveyard, there's the ledge,
  there's a lot of places they can hide. So, when we lose sight of the
  flag carrier, we should project our idea of where they might be along
  all of the route lines they can take (just one per path, so one for
  tunnel, one for out the front, etc, branching like the AB paths) and
  then try to intercept by guessing one of those paths and trying to cut
  them off by moving where we expect them to be, not where they currently
  are. If we catch sight of them of course we know the real number, and
  we can more perfectly intercept them - sometimes, leaving combat and
  mounting up is a better way to catch them than just by walking
  forward. But the system should be able to route through multiple paths
  - for example "I could walk, and it'd take X amount of time. Or I could
  back off and mount up, which might be faster because of a/b/c
  parameters or whatever.""). For the battlegrounds (629, and the Arathi
  Basin route charts, 176a2c):
  - seen (or seen a moment ago): its true place;
  - out of sight: its last seen place, moved forward along every route
    it could have taken from there, one guess per branch (the tunnel,
    out the front, the roof, the flag room, the graveyard, the ledge),
    the branches drawn like Arathi Basin's path chart; allies' callouts
    ("flag on roof", "flag in the flag room") weight the guesses;
  - intercepting: a buddy picks one branch and heads for where the
    carrier would be on it, not where it was last seen; on sight it
    corrects to the real place;
  - the way there is chosen among ways of travelling (walking on, or
    stepping out of combat to mount), by the time each would take, with
    the same route search as the rest of travel (617e8).

## Suggested Implementation Steps

1. A small registry in the core (a new header beside 164's
   `PerPlayerCreatures.h`): object -> its triggers; action name ->
   function; inside-sets per trigger, so "enters" and "leaves" know who
   was inside.
2. A source patch (the patch system's way: marker-wrapped, exact revert)
   at the relocation notifiers: after the stock work, objects near the
   moved unit that have triggers are asked. Measure before choosing the
   exact spot: the notifiers run for every moved unit, so the "has any
   trigger" test must be one lookup.
3. Lua: a register call and an event (`mod-ale` bindings, as 164 added
   `SetCreatureSpawnHidden`).
4. The first user: 617c2's "a buddy came within 60 yards of its partner"
   as a trigger on each player, replacing that part of the 5-second look.
5. A test: a game master command that registers a trigger with a log
   action on the targeted object; walking in and out logs once each way.
6. Then the other kinds ("a spell lands on it": the spell hit hook,
   `OnSpellHit`, already exists for creatures; game objects and players
   need the same treatment).

## Open Questions

- (Open) A trigger on a player that moves (the partner): the check is
  then from both sides, the partner moving and the buddy moving. The
  relocation pass covers both, since each move notifies the other's
  surroundings; to be confirmed by the test in step 5.
- (Open) Which actions should exist from the start besides logging and
  calling a Lua event?

## Related Issues

- **164**, **617c2**, **617j2**, **916g**
