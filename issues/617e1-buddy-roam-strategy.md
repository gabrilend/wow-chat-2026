# 617e1 - The Buddy Roam Strategy

## Status
- Created: 2026-09-27
- Phase: 6
- Parent: 617e
- Blocked by: 617c1 (buddies log in)
- Priority: High (nothing of roaming happens in game without it)

## Current Behavior

**Built 2026-09-27; compile-checked against the last beta build's
settings, not yet run** (`modules/mod-buddies/src/buddies_roam_strategy.cpp`):
- The strategy "buddy roam", its trigger "buddy roam due" (always due)
  and its action "buddy roam step" (relevance 3.0, below attacking's 4.0
  and loot's 5 to 8) are added to all ten class contexts' shared lists in
  the world's start hook. That comes after the bot module builds its lists
  (its before-world-initialised hook, `PlayerbotAIConfig::Initialize` ->
  `AiObjectContext::BuildAllSharedContexts`; the world's start hook runs
  once the world is initialised, `apps/worldserver/Main.cpp`) and before
  any bot can log in (during world updates). A later config reload in the
  bot module re-adds its own lists; ours stay in the same name tables.
- The action: useful for a living buddy out of combat whose owner is
  online on the same map, outside instances and towns, standing in the
  owner's own named area (otherwise "buddy travel", 617e4, walks it there
  first), and not waiting after a failure. On a new area (the owner's area
  id) it looks up the area's middle (617e2, the install-time table) and
  begins the pinwheel from where the buddy stands; its body width is twice
  its bounding radius (0.5 at least). At the end of a path it rolls the
  rest chance, and a rest is a **meal** (below); else it asks the core for
  the next waypoint, with the players within 100 yards (other buddies
  included) for the crowding rule and the monsters within 60 that would
  attack it on sight for the nudge (617e3). It walks in legs: the farthest
  path point within 8 yards, ordered with the bot module's own walking at
  the lowest ("wander") priority, so any other walk it wants goes first.
  **It walks, not runs, unless mounted** (owner, 2026-09-27: "If they
  can't mount, then they shouldn't be running"): the bot module mounts a
  bot itself outdoors when it has a mount and the level (its "mount"
  behaviour, `CheckMountStateAction`); indoors or without a mount the
  buddy walks. A buddy entering combat is set running at once (the
  server's enter-combat hook), since the bot module's chasing moves at
  whatever pace the walk flag says. A failed pick or centre lookup pauses
  that buddy 10 seconds and is logged with where it stood.
- **The meal** (owner, 2026-09-27: "If the food has a well fed buff, they
  should wait until they get it or are interrupted. If not, they should
  eat until their health bars are full and drink until their mana is full
  (if appropriate)."; "they need real food"): the buddy eats if health is
  short and drinks if it uses mana and mana is short. A serving is the best
  usable food or drink it carries (highest item level; food = a "food"
  consumable whose spell regenerates health, drink = mana), used as a
  player uses it, so food that gives Well Fed does. Never the bot module's
  food cheat. Food with Well Fed: done when the buff is on (spell found from
  the food spell's triggered "Well Fed" spell, e.g. 5004 triggers 19705),
  or when the eating stops without it (interrupted). Other food: done at
  full health and mana, a serving that runs out early followed by another.
  A fight ends the meal. A meal past 2 minutes is ended and logged with
  what was short. With nothing to eat there is no meal, logged once per
  buddy per server run (food comes from the starting kit and cooking,
  617a4 and 617k, not built yet).
- The pass (every 3 seconds): for each online buddy under its owner, out
  of instances and alive, the peace-time set is put right where it
  differs: in the open `-follow, +buddy roam, -grind, -food, +loot,
  +gather, +buddy travel, -buddy town`; in a town `-follow, -buddy roam,
  -grind, -food, +buddy travel, +buddy town` (617e4). No grind (owner,
  2026-09-27: "100 yards is a long ways"): fights come from the monster
  nudge, from being attacked, and later from 617e5. No "food": the bot
  module's own eating is its cheat. The strategy file also teaches the bot
  module 617e4's "buddy travel" and "buddy town" (made in
  `buddies_town.cpp`) in the same three lists.
- Each buddy's roaming state sits in a locked table (bots run on their
  maps' threads); a buddy's entry is copied out, worked on and written
  back, so path planning runs outside the lock.

Before: a buddy logs in as its owner's bot (617c1) with playerbots'
defaults for a bot that has a real master: in peace `follow, loot, gather,
food, buff, mount, quest, ...`; in combat its class's strategies. It
follows the owner at a yard and a half; it does not look for fights of its
own (`grind` is given only to random bots).

Found in the playerbots source (2026-09-27, commit 93aaea3d):
- A module can add strategies, actions and triggers without editing
  playerbots: each class's shared lists (`XxxAiObjectContext::
  sharedStrategyContexts`, `sharedActionContexts`,
  `sharedTriggerContexts`) are public, and `SharedNamedObjectContextList::
  Add` merges new creators in; every bot's lists read them by reference.
  They must be added after `AiObjectContext::BuildAllSharedContexts`
  (called in playerbots' before-world-initialised hook) and before any bot
  logs in.
- Strategies are replaced at a bot's login (`PlayerbotMgr::OnBotLogin`:
  reset to the defaults, then the saved set from `playerbots_db_store`), on
  accepting a group invitation (`ResetStrategies` + `+follow`), when a
  revived bot comes back (`+follow,-stay`), and on some other events. So a
  set made once does not last.
- A movement order given from outside (the motion master) is overwritten
  on the bot's next tick by whatever movement action is useful.
- `grind` attacks anything worth experience within 100 yards
  (`AiPlayerbot.SightDistance`) in line of sight, not more than 4 levels
  above the bot, no elites unless strong enough; for a bot with a real
  master it has no leash to the master. In a group it prefers what is
  nearest a group member.
- `loot` and `gather` walk to and open corpses, chests and herb or ore
  nodes within 15 yards (`AiPlayerbot.LootDistance`), with the skill and
  tool checks (mining pick, skinning knife).

## Intended Behavior

- A buddy away from towns runs our own strategy, **"buddy roam"**, in
  place of `follow`: its one action walks the buddy along the roaming
  waypoints of 617e2, using playerbots' own walking (mmap paths), at a
  relevance below fighting and looting, so a fight or a corpse always
  comes first and roaming resumes after.
- Its peace set is `-follow, +buddy roam, +grind, +loot, +gather` on top
  of the defaults; combat stays the class's.
- The module re-applies the set whenever a buddy is found without it (a
  pass every few seconds), so every reset above is undone.
- The set is not saved to `playerbots_db_store`, so a buddy logs in with
  the defaults and the pass sets it again.

### Decisions, 2026-09-27 (Ritz): grind, food, walking

- **Grind off**: "100 yards is a long ways." Playerbots' grind charges
  anything worth experience within 100 yards (its sight distance, one
  setting for everything it sees). Buddies drop `grind`; their fights come
  from the monster nudge (617e3), from being attacked, and from helping
  each other and pulling clusters (617e5).
- **Real food**: "they need real food." Playerbots' food cheat (sit and
  regenerate with no item) is not used by buddies: they drop playerbots'
  own `food` strategy and eat only through the module's meal, from items
  they carry; nothing to eat is logged, not cheated. (The cheat setting is
  shared by all bots, so it is not switched off server-wide.)
- **Walking where they can't ride**: "when exploring enclosed spaces,
  buddy-bots should walk between concerns, not run. If they can't mount,
  then they shouldn't be running. This behavior is turned off in
  dungeons and raids, where they're probably following a player."
  Roaming outside instances: mounted where the game allows a mount, and
  where it doesn't (indoors, too low a level, no mount), walking.

## Suggested Implementation Steps

1. `modules/mod-buddies/src/buddies_roam_strategy.cpp`: a strategy "buddy
   roam" (trigger: always / a short timer; action "buddy roam step"), an
   action that asks 617e2 for the buddy's next point and moves there with
   the bot's `MoveTo`, registered into all ten class contexts at the
   world's startup.
2. A pass (in the same file, or the grouping pass of 617c2) that checks
   each online buddy's peace set and re-applies it.
3. Check it compiles against the last beta build's settings (the module's
   other files are checked the same way).
4. In game: a buddy stops following, walks its waypoints, fights what it
   meets, loots and gathers, and resumes.

## Related Issues

- **617e** parent; **617e2** the waypoints; **617e3** creatures, chests,
  nodes; **617c1**; **617c2** the grouping pass
