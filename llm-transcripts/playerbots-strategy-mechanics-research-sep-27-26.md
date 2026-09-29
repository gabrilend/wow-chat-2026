# Conversation Summary: agent-a45d9569dc940fc72

Generated on: 2026-09-27 02:10:26
Models: claude-opus-5-5

--------------------------------------------------------------------------------

### User Request 1

Very thorough research in the mod-playerbots source at
/mnt/mtwo/games/azeroth-core/wow-chat-2026/source-beta/modules/mod-playerbots/
(AzerothCore 3.3.5 playerbots). I am building a C++ module (mod-buddies, at
/mnt/mtwo/games/azeroth-core/wow-chat-2026/modules/mod-buddies/, which already
includes "Playerbots.h" and "PlayerbotMgr.h" and calls
PlayerbotMgr::AddPlayerBot to log in bots owned by a real player = the bot's
"master"). I need these bots to NOT follow their master, but instead roam an
area along waypoints my module computes, while still using playerbots' own
combat (attacking nearby hostile creatures), looting corpses, opening treasure
chests, and gathering herb/mining nodes. Answer each question with file paths,
line numbers, function/class names, and short quoted code where decisive. Do not
write code; report findings.

1. Default strategies for a bot that has a real-player master (not a random
   bot): where are they set (AiFactory::AddDefaultNonCombatStrategies /
   AddDefaultCombatStrategies or similar)? List the non-combat and combat
   strategy names given, and which of them move the bot (follow, stay, grind,
   rpg, travel, new rpg, etc.).
2. How to change a bot's strategies from C++: e.g.
   PlayerbotAI::ChangeStrategy(std::string, BotState), ResetStrategies, and
   whether changes persist (playerbots_db_store / "save strategies"), and
   whether they get reset on login or when the master changes.
3. The "grind" strategy: which trigger/action finds targets (GrindTargetValue or
   similar)? What range does it search (config value names like GrindDistance /
   sightDistance), and does it refuse or change behavior when the bot has a
   master or is in a group (e.g. only attack if master is attacking, or stay
   within some distance of the master)? Is there any "leash" toward the master
   that would pull a bot back?
4. Looting and chests: which strategy/action loots corpses and opens chests
   (LootObjectStack, "loot" strategy, AddAllLootAction, OpenLootAction)? What
   range? Does it require no master or specific config (e.g. sPlayerbotAIConfig
   lootDistance)?
5. Gathering herb and mining nodes: which strategy/action (e.g. "gather",
   "collect")? Conditions (profession skill checks, ranges, config flags)?
6. If my module issues movement directly (Player::GetMotionMaster()->MovePoint,
   or the bot's MovementAction::MoveTo), will playerbots override it every tick?
   Is there an existing mechanism to tell a bot to go to a point and stay/roam
   there (e.g. "stay" strategy with a stay position, "guard" / "position" values
   like PositionValue "stay"/"guard"/"return", MoveToPositionAction, the
   "travel"/TravelTarget system, "rpg" wandering)? Which of these would let an
   external module set a destination the bot walks to on its own and then
   fights/loots near?
7. Can an external module add its own Strategy/Action/Trigger to playerbots
   without editing playerbots sources (a registration hook, or must
   StrategyContext/ActionContext be patched)?
8. Groups: how does a master's bot join/leave the master's group (InviteAction,
   accept invitation, LeaveGroupAction, "leave" command)? Can a group be formed
   purely of bots with a bot as leader (does anything disband it or make bots
   leave it automatically, e.g. a "leave group if master not in group" rule, or
   random bot group logic applying only to random bots)? Anything that makes a
   master's bot auto-invite the master or auto-follow the group leader?
9. Movement pathing: does playerbots' MoveTo use the server PathGenerator
   (mmaps)? Any existing check of terrain height differences or obstacles?
10. Anything that teleports a master's bot back to its master when too far (e.g.
    "teleport to master" when distance > some config, sPlayerbotAIConfig
    farDistance / reactDistance / "summon") that would fight a roaming design.

Be concrete; include config key names from the playerbots .conf.dist where
relevant (path under conf/).

--------------------------------------------------------------------------------

### Assistant Response 1

> Now LootAction.cpp.

> Now MovementActions.cpp Follow() and teleport at 1135/1163, and MoveTo.

I've sent the full report back to your main session; nothing was built, run or
changed. The points below matter most for making bots roam their own waypoints
instead of following you.

1. **Defaults for a bot with a real-player master.** The non-combat set includes
   `follow`, `loot` and `gather`, but not `grind`, `rpg`/`new rpg` or `move
   random`; those are added only for random bots (`AiFactory.cpp:585-631`).
   `follow`, `stay` and `guard` exclude each other, so adding `guard` or `stay`
   drops `follow` automatically.
2. **Strategies you set at login get wiped.** The core login hook fires first.
   `OnBotLogin` then resets the strategies and reloads the saved ones from the
   playerbots database (`PlayerbotMgr.cpp:199-237, 468-536`). Apply yours after
   that step has run.
3. **Strategy changes don't save by themselves.** Calling `ChangeStrategy` from
   C++ stores nothing. Strategies are saved on logout only if the bot is still
   in a group with you. Accepting a group invite resets strategies and adds
   `+follow`.
4. **Login always pulls the bot into your party.** It invites the bot into your
   group, and teleports it to you if it is more than 100 yd away
   (`SummonWhenGroup=1`). If the bot's saved group doesn't contain you and
   `KeepAltsInGroup=0`, it leaves that group on login. While logged in, nothing
   disbands a group of bots led by a bot.
5. **Grinding isn't limited by distance from you.** The grind targeting drops
   the master when it's a real player (`GrindTargetValue.cpp:37-39`). Targets
   are anything valid within 100 yd with line of sight, height difference ≤
   5.5 yd and level ≤ +4. The only thing pulling a bot back is the `follow`
   strategy itself, and it doesn't run during combat.
6. **Looting, chests and gathering need no master or config.** They use the
   `loot` and `gather` strategies within `LootDistance` (15 yd). Gathering
   checks skill level and tools (mining pick, skinning knife). Free-for-all loot
   needs `FreeMethodLoot=1`, and `stay` effectively disables looting.
7. **Your own `MovePoint` calls will be overridden.** Playerbots' movement code
   clears the motion master on the next tick when any movement action wants to
   run. You can delay its own moves by setting the bot's "last movement" value,
   but that doesn't stop `follow`.
8. **The best existing roaming hook is "new rpg".** `botAI->rpgInfo` is public,
   and `ChangeToGoGrind(pos)` makes the bot walk there on mmaps and then wander.
   You need `-follow,+new rpg,+grind`. Two catches:
   - After about 5 minutes of wandering it goes idle and picks a random new
     activity, so your module must keep re-issuing waypoints.
   - It teleports the bot straight to the destination if it makes no progress
     for 90 seconds.
9. **`guard` isn't a good fit.** It pulls the bot back to a set point whenever
   it is more than 1.5 yd away, competing with "attack anything" at the same
   priority. `stay` blocks grinding altogether.
10. **You can add your own strategies without editing playerbots.** Each class's
    AI context keeps its shared lists public, e.g.
    `PriestAiObjectContext::sharedStrategyContexts.Add(...)`. Add to all 10
    classes after playerbots builds them in `OnBeforeWorldInitialized`, and
    before any bot logs in.
11. **Nothing periodically teleports a bot back to you.** The old
    teleport-to-master-when-far code is commented out. Teleports that do exist:
    - the group-join/login summon (set `SummonWhenGroup=0` to stop it)
    - the explicit "summon" command
    - your area-trigger, taxi and LFG packets, which bots copy
    - death and graveyard handling
    - the new-rpg stuck teleport
12. **Pathing uses the server's mmap pathfinder** for all moves. Beyond mmaps,
    the only terrain checks are height-difference filters, line of sight, and
    collision/water checks for random moves; there is no slope check.

--------------------------------------------------------------------------------

