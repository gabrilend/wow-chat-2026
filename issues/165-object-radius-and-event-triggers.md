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
toolbox."

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
