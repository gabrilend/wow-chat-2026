# 617s - The Compass Formation

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617 (buddy bots)
- Priority: High (buddies standing around in dungeons, 2026-10-04)
- Related: 617c3 (inside: the aggro trigger at 110%, the strategy set),
  617o (navigation mesh), 617o4 (steering to moving targets), 617e
  (`lib/buddy-arc.lua`: the ring placement of the game masters' commands)

## Origin

Verbatim, 2026-10-04:

> Can we add a command that uses the same targetting rules to send one bot
> to a location we specify with our mouse?

> Also, can we change their following behavior? They should form a circle
> around the player, using the same method we used for the innkeeper
> hearthstone placement system. Except, the waypoints should update around
> the player. Each buddy-bot should always (depending on group) find
> themselves at the same general "compass" direction, projected onto the
> fewer slots with fewer party members. So if there's 7 buddy bots for a
> total of 8 characters, the player-partner in the middle, then the 7
> buddy-bots might each have a direction like "north" or "west" or
> whatever. They should always move toward this location around the
> player. Also can we add a command that makes this radius slightly farther
> out, and another that brings it in to a minimum? The "farthest out" they
> can be is 40 yards, and it should respect the terrain and doodads and
> such. This is only in follow mode. Also, the tank will displace whoever
> is closest to where the player is facing, and they will adjust to find
> the closest orientation to their anchor spot. This will mean that a tank
> and a character to their side on the compass will switch positions when
> the player-character turns. The goal is to keep the tank directly
> in-front of the player, so when the player moves the tank character close
> enough to the foes... They will charge forward at 110% of the monster's
> aggro radius. We can disable that behavior when the character is in
> combat so we're not attempting to re-orient all the time. And when a
> fight is underway, the playerbots will move around, out of AoE's and
> such... Sometimes just moving to move, getting a different angle on the
> target, usually about 10 or 15% of the arc length of the circle created
> around the target with radius equal to the distance to the target.
> Again, always respecting the terrain pathfinding navmesh.

## Current Behavior

Not built. Following is the bot module's own ("follow" strategy): each
bot trails its leader at a short distance by its own rule, with no fixed
place, and inside a dungeon only fights what the leader attacks or what
attacks the group (617c3 adds the 110% trigger). In a fight a bot stands
where its class's fighting puts it, and moves only to dodge what the bot
module knows to dodge. The bot module's `rtsc` lets a player save spots
by clicking and send bots to them ("rtsc save #", "rtsc go #").

## Intended Behavior

In follow mode, out of combat, an owner's buddies hold a ring round the
owner, each at its own compass place, moving with the owner. In a fight
they shift round their target now and then. Each part is a sub-issue:

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 617s1 | compass-slots | None | Each buddy's own compass direction (by roster slot); the ring's slots for the buddies present, the front slot on the owner's facing; each buddy matched to the slot nearest its direction; geometry only, tested offline and drawn |
| 617s2 | ring-follow | 617s1 | Out of combat in follow mode, each buddy moves toward its slot, recomputed as the owner moves and turns, on the navigation mesh (a slot behind a wall or off a ledge moves in toward the owner until walkable and reachable) |
| 617s3 | tank-at-the-front | 617s1 | The tank takes the slot on the owner's facing, displacing whoever holds it, who takes the free slot nearest its own direction; so turning swaps the tank with a neighbour |
| 617s4 | ring-radius-commands | 617s2 | Two commands: the ring a step wider (up to 40 yards), and back in to the smallest |
| 617s5 | sidesteps-in-a-fight | 617o | In a fight, now and then a buddy moves round its target along the circle of its current distance, by 10-15% of that circle's length, on the mesh |
| 617s6 | send-one-buddy | 617s2 | One buddy, chosen by the bot module's own addressing (its name, @tank, @heal...), sent to a spot the owner clicks; it holds there until told to follow again, and the ring leaves its slot empty meanwhile |

| 617s7 | box-select-in-the-custom-client | 617s6 | In the project's own client, buddies chosen by clicking and dragging a box over them |

Execution order: 617s1 → (617s2, 617s3) → 617s4; 617s5 and 617s6 after
617s2; 617s7 waits for the custom client.

## Suggested Implementation Steps

1. 617s1's geometry offline (Lua beside `lib/buddy-arc.lua`) and drawn as
   an animation (an owner walking and turning, seven buddies) for the
   owner to look at before server code.
2. The rest in `mod-buddies` (C++), each with a stand-in or offline test,
   compiled by the owner.

### Answers, 2026-10-04 (Ritz)

- Radius: "5, 5, 25" (asked: default, step, minimum). Read as the default
  5 yards and the step 5 yards; 25 can't be the smallest when the default
  is 5, so it is held as an open question (below).
- Compass: "yes fixed to the world, but dynamically adjusting. Maybe we
  could talk to Sargobras (or a second, assistant NPC) to enable or
  disable that behavior. Chromie? so that it'd give us config options to
  change for certain server behaviors." The switch is issue 168 (Chromie,
  keeper of settings).
- Only buddies in the owner's group take slots: "yes".
- Commands: `.buddy wider` and `.buddy closer`, any player for their own
  buddies, "ideally with pre-made macros if we can figure out how" (617s4).
- Send one buddy: "let's see both implementations to see what they each do
  differently. Try to distinguish yourself from their implementation in as
  many ways as you can, so we can see the pattern of behavior." (617s6).
- Box selection by click-and-drag: an issue for the custom client (617s7).
- Sidesteps: "melee should do a larger proportion of the circle each time.
  How about 20-35% for melee and 10-20% for ranged? We can also consider
  just scaling it linearly from 0 to 40 yards away" (617s5).

## Open Questions

1. (Answered 2026-10-04) "5, 5, 25": 25 yards is the largest ("yes. And 5
   is the minimum."): default 5, step 5, smallest 5, largest 25.
2. (Answered 2026-10-04) When the sidesteps happen: "inbetween a
   spellcast, when they're casting an instant spell" (617s5).
