# 617r6 - Spec Profiles Choose the Gems

## Status
- Created: 2026-10-05
- Phase: 6
- Parent: 617r (gearset profiles)
- Related: 617j2 (buddies gem their gear), 617j (stat weights by plan), 617r4 (creatures dressed), 155z6 (the Portal's heroes)
- Priority: Medium

## Origin

Verbatim, 2026-10-05, asked how gear profiles handle gemstones:

> the nice thing about buddy-bots is that they can use gems to profile
> themselves, and we can pretty much just give them gear of the correct
> type and it'll be fine. I'm thinking... We probably don't need to keep
> gemstone records in the gear profiles. I think that should be in the
> *spec profiles*, listed as desired stat weights. Then, when we
> instantiate a bot through Sargobras, or perhaps apply a gearset to an
> NPC some other way (like the Dark Portal thing?) we could use the spec
> profile's stat weights to determine which gems to socket into the gear.

## Current Behavior

Gearsets hold no gems. A buddy's gems are already chosen when it is made
or remade (`BuddyGemKit`, `buddies_gems.cpp`, 617j2): for every socket of
what it wears, the gem of the item's gem tier that scores best by the
bot module's stat weights for each tree of its talent plan, blended by
the plan's thirds (the same weights it scores loot by), plus the socket
bonus where the gems earn it. The weights live in the bot module's
database tables (`playerbots_weightscale*`, one scale per spec), not in
the project's own files. The gearset command (`.gearset`, Lua) puts no
gems in; creatures aren't dressed yet (617r4).

## Intended Behavior

**Spec profiles** become the project's own data: for each class and
talent shape (the gearsets' shape key), the desired stat weights (stat
name to weight, as the bot module's fields: str, agi, sta, int, spi,
splpwr, hitrtng, critstrkrtng, hastertng, exprtng, armorpenrtng, atkpwr,
defrtng, dodgertng, parryrtng, blockrtng, block, armor, manargn, mledps,
rgddps), one data file the owner can edit, first written from the bot
module's tables blended by thirds (as the gem chooser does today). Gear
is given by gearset (right type, right look); **gems are chosen at the
moment of dressing from the spec profile's weights**, for every way of
dressing:

- a buddy made or remade at Sargobras (the buddy module, as now, but
  reading the spec profile instead of the bot module's tables);
- the gearset command on a character;
- a creature dressed through the mirror image (617r4), such as the Dark
  Portal's heroes (155z6), whose "spec" is the shape its record is under.

So a gearset says what someone wears; the spec profile says what they
want from it; the gems make the difference.

## Suggested Implementation Steps

1. A tool writes `data/spec-profiles.lua` (class x 100 + shape -> stat
   weights) from the bot module's scales blended by thirds.
2. Into the database beside the gearsets (the same SQL generator), so
   the buddy module's gem chooser reads it.
3. The gem chooser in Lua for the gearset command and creatures, the
   same rule as `BuddyGemKit` (best gem per socket by weight, socket bonus
   when earned).
4. Tests: for a few shapes, the gem chosen is the one the weights favour.

## Open Questions

1. (Answered 2026-10-05: "yep") The loot scoring (617j: upgrades,
   need or greed, quest rewards) reads the spec profile too, so one set of
   weights decides gems, upgrades and rolls alike. The bot module asks the
   buddy module for a buddy's weights (B046 today passes the plan), so the
   spec profile reaches it through the buddy module.
