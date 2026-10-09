# 180 - Quests Go to the Stand-ins

## Status
- Created: 2026-10-08
- Phase: 1
- Profile: basic
- Related: 178 (experience counted in kills), 155l (Outland without
  quests: the same removal done once, for one continent), 617t
  (stand-ins), 155e (quests open to the whole faction), 718 (the death
  knights' story, played as quests), 155 (the basic profile)
- Priority: Medium

## Origin

The owner, 2026-10-08:

> can we remove all the quest-givers from the game? Or rather, remove all
> of the quests? Then, we should have stand-ins completing them, using the
> same player-bots questing rules. players are incentivized to fight
> higher level monsters, but they walk slower so it's more time to get to
> them. less time spent fighting, same amount of progression.

### Decisions, 2026-10-08 (owner)

- **Class quest rewards on the trainers** ("let's put them on the
  trainers. I think there's a patch that does that, you can see how it's
  implemented."): totems, forms, hunter pets and the rest taught by
  trainers. Beta's install step E013 does this
  (`sql/beta/db_world.src/13-quest-spells-to-trainers.apply.sql`, and
  `scripts/generate-buddy-quest-spells` lists quest-given spells for the
  buddies); basic gets the same.
- **Every door unlocked**: dungeon keys and attunements no longer needed.
- **Riding**: no quests involved, nothing to do.
- **The death knights' story**: "if enabled on a server, the sargobras
  option to skip the story is auto-selected, and cannot be undone." On a
  server with quests removed, a new death knight's skip (718) is chosen
  for it, and the option to take it back is not offered.
- **Stand-ins' errands, not the game's quests**: "stand-in errands are to
  pick a monster-spawning zone who's centroid is closer to the town-hub
  that they're at (as determined by flightpath master) and to go and slay
  monsters there for ~20 kills. Then come back to town, or visit another
  nearby (ideally, orbiting the town) monster spawning zone." So quests
  are removed (as 155l did for Outland); a stand-in's errand is: from its
  town (the town with that flight master), the monster area whose middle
  is nearest, about 20 kills there, then back to town or on to another
  area near the town, circling it.

## Current Behavior

Not built. Players take and turn in quests as stock, open to their whole
faction (155e). Outland already has none (155l: every quest starter and
ender there removed by install step E028, kept for the revert). Bots
played by the playerbots module quest by its own rules.

## Intended Behavior

**No quests for players.** Quest givers offer players nothing to take or
turn in: progression comes from kills (178), where a harder monster is
worth many more kills, and players walk slower (basic's 80% speed), so
more time goes to reaching the right monsters and less to fighting.

**Stand-ins run errands in place of quests.** Quests are removed from
the world, as Outland's were (155l). Stand-ins keep the world moving:
from a town (the one with its flight master), each goes to the monster
area whose middle is nearest, kills about 20 there, and comes back, or
goes on to another area near the town, circling it (decisions above).

## Suggested Implementation Steps

1. List what quests carry that players still need: class abilities and
   items given by quests, dungeon keys and attunements, the death
   knights' story (718), profession quests, riding, and so on, and decide
   each (open question 1).
2. Remove every quest starter and ender (155l's install step, for the
   whole world), kept for the revert; class quest spells onto trainers
   (beta's E013 for basic); every dungeon door and attunement open; the
   death knights' skip chosen for them, with no way back.
3. Stand-ins' errands: towns by flight master, monster areas by middle
   (617e2's area centres, or 617e12's drawn areas), about 20 kills, back
   or on round the town.
4. Tests: no quest at any quest giver; a stand-in's errand picks the
   nearest monster area to its town and returns after its kills.

## Open Questions

1. (Answered 2026-10-08, above) **What players still get from quests:** class quests (abilities,
   totems, pets for hunters, forms), keys and attunements, the death
   knights' story with its skip (718), profession and riding quests:
   removed with the rest, given another way (trainers, vendors), or kept?
2. (Answered 2026-10-08: removed; stand-ins run errands) **How quests leave players but stay for stand-ins:** the stock game
   has no "these quests are for bots only". Either quests stay in the
   world and a rule refuses them to players (a Lua check at accepting a
   quest, or a source patch), or quests are removed (as 155l did for
   Outland) and stand-ins quest some other way (their own errands, not
   the game's quests). Which?
3. **Quest items and quest monsters:** monsters and objects that exist
   only for quests (collect-this, kill-that) stay, for stand-ins and as
   ordinary monsters for players?
4. **The quest rewards' gear:** much of the levelling gear comes from
   quests. With quests gone for players ("with as minimal of gear as you
   can", 178), is that gone too, or does it reach players another way
   (vendors, drops)?
5. **Stand-ins in the open world:** today stand-ins are planned for
   dungeons and battlegrounds (617t). Questing ones walk the world all the
   time: how many, where, and do they join the buddy pool's levelling
   tracks?
