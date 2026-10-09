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

**Stand-ins do the quests.** Stand-ins in the world take, work through
and turn in quests by the playerbots module's questing rules, so the
world still moves: quest monsters thinned, quest givers busy.

## Suggested Implementation Steps

1. List what quests carry that players still need: class abilities and
   items given by quests, dungeon keys and attunements, the death
   knights' story (718), profession quests, riding, and so on, and decide
   each (open question 1).
2. Hide quests from players, keep them for stand-ins (open question 2).
3. Stand-ins questing (617t's stand-ins in the world, with the playerbots
   module's questing turned on for them).
4. Tests: a player finds no quest at a quest giver; a stand-in takes,
   completes and turns one in.

## Open Questions

1. **What players still get from quests:** class quests (abilities,
   totems, pets for hunters, forms), keys and attunements, the death
   knights' story with its skip (718), profession and riding quests:
   removed with the rest, given another way (trainers, vendors), or kept?
2. **How quests leave players but stay for stand-ins:** the stock game
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
