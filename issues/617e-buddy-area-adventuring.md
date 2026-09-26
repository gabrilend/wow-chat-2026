# 617e - Buddy Area Adventuring

## Status
- Created: 2026-09-23
- Phase: 6
- Parent: 617
- Blocked by: 617c
- Priority: Medium

## Origin

Verbatim, 2026-09-23 (617 has the full answers):

> They try and fight the same creatures in the same area that you do, but
> they might be on the other side of the patch of mobs and that's okay. You
> only share exp when you're close, and they don't try to stay near - they
> just attack mobs as if the NPC bot was fighting in that particular area on
> their own.

> yes it comes back to life. It'll move to the areas that the player is in
> when it can.

And for towns, verbatim, 2026-09-23:

> they should stay in the same area as you. So if you're in town, they should
> wander around town and stand in front of random NPCs, do some talking
> animations, then walk to another NPC. Walk, not run. A random NPC in the
> area. When you're in a town or a city, you should be un-grouped with them
> too.

## Current Behavior

Bots in a master's group follow the master by default. Random bots grind
where the module sends them. Neither is "in my area, on its own".

## Intended Behavior

- A buddy's playground is the owner's current **area**: the named place
  shown on screen on entry (e.g. "Fargodeep Mine" inside Elwynn Forest). It
  fights what lives there and doesn't follow the owner. Grouped buddies stay
  inside the owner's experience radius, ungrouped ones outside it (617c).
- **In a town or city** the buddies are ungrouped (617c) and don't fight.
  Each walks (never runs) to an NPC in the area, stands before it and plays
  talking animations, then walks to another. Which NPC is weighted
  (Ritz, 2026-09-23):
  - **merchants**, with priority equal to how full the buddy's bags are
    (half-full bags: 50% priority); at a merchant it sells what the bot
    module already considers junk or surplus;
  - **its class trainer**, first, when it has spells it could learn;
  - otherwise a random NPC.
  In towns with services, this is refined by 617h's errand list (repair,
  trainer, auction house, vendor, in a durability-driven order) and its
  wandering rule (Ritz, 2026-09-24).
- When the owner changes area, buddies travel there on foot, as a player
  would.
- When a buddy dies it resurrects (spirit healer or corpse run, like a
  player) and makes its way back to the owner's area.
- Grouped buddies share experience only when in range (stock rule);
  ungrouped buddies earn their own.

### Decisions, 2026-09-25 (Ritz)

- **Hearthstones.** "buddies will put their hearthstone to the same spot as
  the player. Except, they'll make a ring around the innkeeper, with the
  radius defined by the distance from the innkeeper in the player's bind
  location. Then, when they have a moment (not in combat, not dead, etc)
  they'll hearth after the player does. As soon as a player successfully
  hearths (they cancel if the player cancels, and they can never complete a
  hearthstone teleport faster than the player because the player initiates
  and they take their time) then they have 'use your hearthstone' added to
  their todo list permanently until they complete a hearthstone teleport.
  [...] Worst case scenario, they could just walk to where the player is,
  though that's annoying."
  - When the owner binds, each buddy binds at the same inn, at a point on a
    circle round the innkeeper whose radius is the owner's distance from
    the innkeeper, spread round the circle.
  - A buddy starts its hearthstone only after the owner starts theirs, and
    cancels if the owner cancels; it can't arrive first.
  - Once the owner's hearthstone lands, "use your hearthstone" stays on the
    buddy's to-do list until it has hearthed (after combat, death, a
    cooldown), then it teleports home. Walking there is the fallback.
- **Towns behave by what they have** ("we should dynamically create
  behavior based on what the town has. Some towns don't even have repair
  stations."): a buddy's town to-do list is built from the services the
  town actually offers (repair, trainer, mailbox, auction house, vendor),
  one system for every town, with 617h's order where both apply.

### Decisions, 2026-09-25 (Ritz): the owner dies, or enters an instance

**The owner dies.** "There's two resolutions - either the player resurrects
at their corpse, or they talk to the spirit healer. In either case, the
buddies should continue questing around where the player died. If they pick
the spirit healer, they should move to the player's new location and start
doing their normal activities over there."
- While the owner is dead, buddies keep adventuring where the owner died.
- Corpse run: nothing changes, the owner comes back to them.
- Spirit healer: buddies travel to where the owner rose and carry on there.

**The owner enters an instance while buddies are outside.** "a dynamic group
is created for the player (unless they already have a group, then it has to
be manually created). If it's a manually created group and a buddy-bot is
invited, they'll move to the instance, enter, and join the party. [...] if
they're lower level than the player, they'll quest in the closest
level-approprate area to the dungeon that the player is in. If they're the
same level or higher, then they'll just chill - by that I mean lighting a
fire, hanging out, eating snacks, talking to passerby if they sit at the
fire, etc. If they're near a graveyard, they'll be provided some flowers to
hold and they will wander around to the gravestones and kneel before about
1/4th of them. They might also say some dynamic chat lines depending on
their character."
- An owner with no group gets the dynamic dungeon group (617c's draw bag);
  an owner already in a group invites by hand.
- An invited buddy travels to the instance, enters and joins.
- A buddy left out:
  - **lower level than the owner**: quests in the level-appropriate area
    nearest the owner's dungeon;
  - **same level or higher**: rests. It lights a campfire, sits, eats; near
    a graveyard it is given flowers to hold, walks among the gravestones
    and kneels at about a quarter of them.
- Talking to passers-by at the fire, and in-character chat lines, wait on
  the LLM chat module (issue 916, mod-soren-chat: persona chat 916k,
  emission and rate limits 916l, proximity 916g), which today targets the
  vanilla profile and would need basic added.

### Decision, 2026-09-25 (Ritz): the owner far away

"The buddy-bot should move toward the mechanism that allowed the distance
at their earliest convenience and attempt to rejoin the player."
- When the owner travels by something other than walking (the Dark
  Portal or Isle flight, 155l; a boat or zeppelin; a summon; a mage
  teleport), each buddy, once it has finished what it is doing, goes to
  that same means (the flight master, the dock, the Dark Portal) and uses
  it, then rejoins the owner's area.
- A means a buddy can't use itself (a summon, the mage's own teleport)
  leaves the walk: it heads for the nearest way there it can use.
  Hearthstones are designed above (buddies hearth after the owner).

## Suggested Implementation Steps

1. A bot strategy in mod-buddies: "adventure in owner's area". It
   replaces follow, with a grind target search bounded to creatures inside
   the owner's current area.
2. Area-change travel: path to a point inside the new area.
3. Death handling: the module's existing release-and-resurrect logic, with
   the return trip from step 2.
4. Look at beta's 601 (find monsters) and 611 (wandering) for reusable
   ideas.
5. Test: owner stands at a camp's edge; buddies spread through the camp
   and fight; owner moves to the next area; buddies follow within a minute;
   a buddy that dies comes back.

## Related Issues

- **617**, **617c**; **601**, **611**, **613** (beta's Lua behaviors)

## Open Questions

- (Answered 2026-09-23) Buddies stay in the owner's area; in towns they
  visit NPCs on foot. The level band is whatever lives in that area.
- (Answered 2026-09-23) Towns and cities, not rested areas. The client's
  area table flags capitals and towns (`AreaTable.dbc` flags, readable
  server-side from the server's copy); the flag set to use is checked when
  617e is built.
- (Answered 2026-09-25) Which flags: "the buddies should treat any area with
  the town or city flag as a town, and they should dynamically create their
  todo lists based on the services available in that town." In the server's
  area flags (DBCEnums.h): town (0x00200000, "small towns with Inn"),
  capital (0x00000100) and the capital's subzones (0x00000008).
