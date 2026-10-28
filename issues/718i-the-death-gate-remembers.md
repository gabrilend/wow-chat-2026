# 718i - The Death Gate Remembers

## Status
- Created: 2026-10-27
- Phase: 7
- Parent: 718 (the death knight's sacrifice, Acherus open)
- Related: `src/lua-basic/buddy-hearth.lua` (buddies following a
  hearthstone, by the same arc), `lib/buddy-arc.lua`, 718e (the fall)
- Priority: Medium
- State: plan only; nothing built

## Origin

The owner, 2026-10-27, after Gabrubre's Death Gate took her to the flight
master:

> We should never lose the location where a Death Knight last cast Death
> Gate, and by that I mean the last time out in the world. While cast in
> Acherus, it should always warp you to that location, and any party members
> who walk through as well. Except. if they aren't death knights, it takes
> them to their hearthstone location. Then, the next time the Death Knight
> casts Death Gate (or hearths away) it creates a death gate near all of her
> party members (if they took her most recent death gate pathway summons)
> and they can click it to return to where they came from when they entered
> the death knight's gate, which took them to their hearthstone location.

## Current Behavior

Death Gate (50977) works as in the stock game: cast outside Acherus it
takes the death knight to Acherus; cast in Acherus it takes the death
knight to a fixed spot (the stock destination: by the flight master), not
where it was. Nothing is remembered, and party members are not part of it.

## Intended Behavior

1. **Remembered**: each time a death knight casts Death Gate out in the
   world (not in Acherus), the spot (map, position, facing) is kept, in the
   database, for good: a restart or a logout does not lose it.
2. **From Acherus, back there**: Death Gate is not cast in Acherus (the
   owner, 2026-10-27: "the death knight doesn't cast death gate in Acherus
   anymore, but instead it should trigger when they click the permanent
   death gate where the flight master was, or when they hearth away from
   Acherus"); the standing gate (6), or a hearthstone used in Acherus, takes
   the death knight to the remembered spot (the stock destination only when
   none is kept yet).
3. **The party through the gate**: party members who go through with the
   death knight when it leaves Acherus (by the standing gate or its
   hearthstone) go with it:
   - a death knight: to the same remembered spot, placed on the arc round
     the caster (`lib/buddy-arc.lua`, as the hearthstone places buddies);
   - anyone else: to their own hearthstone's place.
4. **The way back**: when the death knight next casts Death Gate or uses its
   hearthstone, a death gate appears beside each party member who went
   through the last one to their hearthstone; clicking it takes them back
   to where they stood when they stepped through the death knight's gate.
   Each of those return points is kept per member until used.
5. **Buddies through the gate** (the owner, 2026-10-27: "clan member
   buddy-bots all will walk to the portal if it's within 15 yards, otherwise
   they will just automatically use it at a distance. One per second until
   they all walk through. Well, 1-3 seconds, evaluated each time one is
   teleported."): the caster's clan's buddies go through one at a time, a
   new wait of 1 to 3 seconds drawn after each; one within 15 yards of the
   gate walks into it, one farther is moved through it where it stands.
6. **A standing gate in Acherus** (the owner, 2026-10-27: "maybe in Acherus
   we have a permanent one and we don't allow players to summon their own?
   Maybe where the flight master used to be"): a permanent Death Gate stands
   where Acherus's flight master was, and takes a death knight who uses it
   to its remembered spot; Death Gate is not cast inside Acherus.

## Suggested Implementation Steps

1. A table (characters database): per death knight, the last world spot of
   its Death Gate; per party member, the spot they left from through a gate
   and whose gate it was.
2. A Lua script (ALE): on the death knight's Death Gate cast, outside
   Acherus: store the spot; inside: after the cast, move the death knight to
   it (as buddy-hearth.lua moves buddies after a cast).
3. The gate in Acherus: a game object the members can click (or the walk
   through it detected); each member's own spot stored, then moved as in
   Intended 3.
4. The way back: on the death knight's next Death Gate or hearthstone, a
   return gate spawned beside each stored member (a temporary game object,
   clickable only by that member), which moves them back and clears their
   spot.
5. Tests in the pretend world (`scripts/lib/toy-world.lua`): the spot kept
   across a pretend logout; a death knight and a mage through the gate;
   the return gate only for the one who used it.

## Open Questions

1. (Answered 2026-10-27, Intended 5) Buddies walk into the portal within
   15 yards, and are moved through it beyond; one every 1-3 seconds. Players
   in the party: the same walk, or a prompt?
2. (Answered 2026-10-27, Intended 6, for the gate in Acherus: a standing
   one.) How long a return gate beside a member lasts: the game's own
   portal duration, from its data.
3. (Answered 2026-10-27: yes) A member who moved on by other means since
   (rode off from their hearthstone's town, say) still gets their return
   gate, wherever they are, back to where they stepped through.
