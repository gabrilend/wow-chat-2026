# 723 - Teleport There, and Back to Where You Were

## Status
- Created: 2026-10-22
- Phase: 7
- Related: 718 (death knights on basic, Death Gate), 617 (buddies follow
  their owner), 155s (Northrend closed on basic: Teleport: Dalaran is left
  out of the ability tomes)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-22:

> also, the DK death knight is supposed to take them to/from the place
> where they cast it last, like the druid teleport moonglade spell. It
> should be the same. Also Mages should get one that's "Teleport Dalaran"
> and "Teleport Shattrath" oh wait they already do... But, critically, if
> they teleport to Dalaran while in Dalaran, or anyplace while in that
> place, it takes them to where they were before they first teleported in.
> Mages, DKs, and Druids, I think are the only ones who can do it.
> Buddy-bots come along, and party-members can too.

## Current Behavior

Stock 3.3.5a:

- **Death Gate** (death knight, 50977): opens a gate to the Ebon Hold.
  It goes one way; walking back out is by the Ebon Hold's portals or a
  hearthstone.
- **Teleport: Moonglade** (druid, 18960): to Moonglade, and remembers where
  it was cast. In Moonglade, casting it again returns the druid to that
  spot. This is the behaviour wanted for the others.
- **Mage teleports** (Stormwind, Ironforge, Darnassus, Exodar, Orgrimmar,
  Undercity, Thunder Bluff, Silvermoon, Shattrath, Theramore, Stonard,
  Dalaran): one way, to the city. Teleport: Dalaran is left out on basic
  (Northrend is closed, 155s), so on basic it is the others.
- A teleport takes only the caster. Buddies follow their owner across
  maps by the buddy module's own crossing (`buddies_crossing.cpp`); party
  members don't follow.

## Intended Behavior

For death knights (Death Gate), druids (Teleport: Moonglade) and mages
(each Teleport: city):

- Cast anywhere but its destination: it goes to the destination, as now,
  and remembers where it was cast (the first time only, open question 2).
- Cast at its destination: it returns the caster to where it was before
  it first teleported in, as Teleport: Moonglade does.
- The caster's buddies come along (both ways), and party members may
  (open question 1).

## Suggested Implementation Steps

1. Answer the open questions.
2. A remembered spot per character and spell (or per destination): a
   characters-database table (character, destination, map, x, y, z,
   facing), written when one of these spells is cast away from its
   destination.
3. On cast at the destination: the stock spell's own effect replaced by a
   teleport to the remembered spot (a spell script on the server, as
   Moonglade's own return works; or the Lua engine's cast event, which
   can't cancel a spell, so the C++ way). No remembered spot: nothing
   happens and the caster is told why.
4. "At its destination": the destination's zone (Dalaran, Moonglade, the
   city) for mages and druids; the Ebon Hold's area for Death Gate.
5. Buddies: teleported with their owner the moment it arrives. Party
   members: as open question 1 says.
6. Tests: cast away, cast at the destination, arrive back at the spot;
   buddies beside you both times; a second trip inside the destination
   doesn't overwrite the spot.

## Open Questions

1. **Party members:** "party-members can too": every party member near
   the caster goes along at once, or each is offered it (a summon-style
   "accept" box), or only the caster's own buddies are taken automatically?
2. **"Before they first teleported in":** if a mage teleports to
   Stormwind, then to Ironforge, then casts Teleport: Ironforge in
   Ironforge, does it go back to Stormwind (where it was before this
   trip), or to where it was before the first teleport of the chain?
3. **Mage portals** (Portal: city, for the group): the same two-way rule?
4. **Cooldowns:** the return costs the spell's cooldown like any cast?
