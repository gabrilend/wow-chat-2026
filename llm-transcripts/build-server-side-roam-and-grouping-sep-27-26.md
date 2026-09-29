# Conversation Summary: agent-a07d4a3d8d8fc8ed8

Generated on: 2026-09-27 02:20:36
Models: claude-opus-5-5

--------------------------------------------------------------------------------

### User Request 1

Your directive: You are the fork building the server side of issues 617e1 (the
buddy roam strategy), the in-game Ground of 617e2, and 617c2 (the proximity
party with the far buddies' own parties, join 60 / leave 75 / far-party
threshold 74). Another fork is writing
modules/mod-buddies/src/roam/buddy_roam_core.cpp against the header
modules/mod-buddies/src/roam/buddy_roam_core.h — code only against that
header; don't edit it or the core .cpp (if you need a header change, say so in
your report instead).

Build, in /mnt/mtwo/games/azeroth-core/wow-chat-2026/modules/mod-buddies/src/:
1. buddies_roam_ground.cpp (+ declarations in buddies.h or a small new header):
   BuddyRoam::Ground over a Map for a given phase mask and area id: height via
   Map::GetHeight(phaseMask, x, y, zHint + 2, true, some search distance); clear
   = same area id (Map::GetAreaId at x,y,z) and no sharp height step (> the
   planner's step rise, 0.6 yd beyond the slope) on a ring of points at the
   clearance radius; edgeAlong = step outward 1 yd at a time from the centre
   until the area id changes or the ground steps sharply or there is no ground,
   return that distance (cap e.g. 300 yd); seenThrough = every yard along the
   line the area id stays and no sharp step. And the area centre cache: per (map
   id, area id), the average of grid points every 5 yards sharing that area id,
   spreading out (flood fill) from the owner's position, bounded (e.g. 400 yd
   radius / a cell count cap); computed once, remembered.
2. buddies_roam_strategy.cpp: a playerbots Strategy "buddy roam" + Trigger +
   Action registered into all ten class contexts' public shared lists
   (XxxAiObjectContext::sharedStrategyContexts / sharedActionContexts /
   sharedTriggerContexts via SharedNamedObjectContextList::Add) after playerbots
   builds them (find the right hook ordering: playerbots calls
   AiObjectContext::BuildAllSharedContexts from PlayerbotAIConfig::Initialize in
   its OnBeforeWorldInitialized; register after that and before any bot logs in
   — verify in source, e.g. an OnAfterConfigLoad/OnStartup WorldScript, and
   explain the choice in a comment). The action: for a buddy away from towns
   (AreaTable flags town 0x00200000, capital 0x00000100, capital subzone
   0x00000008 — in towns do nothing for now, leisure is later), keep a
   BuddyRoam::Buddy per bot, Begin on first use / area change (area = the
   OWNER's current area id; the buddy roams the owner's area), NextWaypoint when
   the path is done, and walk the next path point with the bot's own
   MovementAction-style MoveTo (look at how playerbots actions move: e.g.
   botAI->... / MovementAction::MoveTo; the action should derive from
   MovementAction if that's how moves are made) at a relevance below grind (4.0)
   and loot (5-8), e.g. 3.0. Rest chance on arrival: if rolled, let playerbots'
   food/drink handle it (they're in the defaults) or just pause the roam for a
   short time — keep it simple, comment the choice. Random numbers:
   urand-based Rng.
   A pass (WorldScript update, every ~3 s) that for each online buddy
   (buddy_roster rows; the bot is GET_PLAYERBOT_AI(bot) non-null and not in an
   instance/battleground) ensures the non-combat set has -follow and +buddy
   roam,+grind,+loot,+gather (check HasStrategy, apply ChangeStrategy only when
   missing, so resets get undone). In towns: +follow back? No — for now in
   towns leave roaming off and keep follow (comment it; town leisure is a later
   issue).
3. buddies_party.cpp (617c2): every 5 s per online owner (not in
   instance/battleground/town): a buddy in the owner's group farther than 75 yd
   leaves it; a buddy not in the owner's group farther than 74 yd is in a far
   party with other far buddies of that owner (form/fill parties of 5, leader =
   lowest guid; create with the core Group API the way playerbots'
   GroupInviteOperation does — read src/Script/WorldThr/PlayerbotOperations.h
   for the safe sequence); a far-party buddy within 74 leaves it (a far party
   left with one member is disbanded); an ungrouped buddy within 60 joins the
   owner's group if it has room (convert nothing to raid; if the owner has no
   group, create one with the owner as leader). Distances are 2D+z world
   distance on the same map. Tell playerbots not to pull buddies out of bot-only
   groups at login: that's the config AiPlayerbot.KeepAltsInGroup = 1 — add a
   C-patch for the basic profile following the existing config/patches/C0xx
   pattern (read C027 and the upstream-patch-system conventions referenced in
   CLAUDE.md; the playerbots conf file path is in how C027 does it) and add its
   expectation to scripts/test-profile-config-gates, then run that test.
4. Register new AddSC_ functions in buddies_loader.cpp.
5. Compile-check every module .cpp with the scratch checker
   /tmp/claude-1000/-mnt-mtwo-games-azeroth-core-wow-chat-2026/f654b718-5d4e-4cda-a776-07b578174b84/scratchpad/syntax-buddies.sh
   (it syntax-checks with the last beta build's flags; include path for roam/
   may need adding — pass -I via editing a copy of the script in your own
   scratch, don't break mine). The core .cpp may not exist yet when you start;
   your files only need the header.

Style: the module's existing files (general-audience header comment, vimfolds, a
comment at each decision saying what each path brings, dispatch tables over
if-chains where natural, errors that say what did and didn't happen). No
fallbacks that hide problems: log errors with what was checked. Absolute paths,
never cd, don't commit, don't build the server. Update issues 617e1 and 617c2
Current Behavior in place when done. Report: files written/changed,
compile-check output, the config-gates test output, the hook-ordering finding,
and open questions.

--------------------------------------------------------------------------------

### Assistant Response 1

> Task: build the server side of 617e1 (roam strategy), the in-game Ground of
> 617e2, and 617c2 (proximity party) in mod-buddies, plus a KeepAltsInGroup
> C-patch.

> Writing the shared header for the server side:

> Writing the strategy, its action and the strategy-keeping pass:

> Writing the party pass:

> All files pass apart from two warnings from upstream headers. Now the config
> patch:

> 23 of 23 config expectations pass. Updating the module README and the two
> issues:

I built the server side of roaming (617e1), the in-game ground for the core
(617e2), and the proximity party (617c2), plus a config patch. Every module file
compiles against the last beta build's settings, and nothing has been built into
the server or run.

**Files written:**
- `modules/mod-buddies/src/buddies_roam.h` — what the roaming and grouping
  files share.
- `modules/mod-buddies/src/buddies_roam_ground.cpp`:
  - The four ground questions over the real map. Heights are searched from 2
    yards above a hint point, not from the sky.
  - An obstacle is a height change that stands out from the previous yard's
    change by more than 0.6 yards.
  - A waypoint is refused if it sits in another area, has no ground, is on a
    slope steeper than 45°, or has a step on an 8-point ring around it.
  - The edge along a line, and whether a line can be walked, are found by
    stepping a yard at a time.
  - Each area's centre comes from a 5-yard grid spreading out from the owner
    (400 yards and 8000 points at most). It is found once, remembered, and
    locked because maps run on separate threads.
  - It also holds the roster list (refreshed every 10 s) and the town check
    (area flags town, capital, capital subzone).
- `modules/mod-buddies/src/buddies_roam_strategy.cpp`:
  - The "buddy roam" strategy, trigger and action, added to all ten class lists
    at startup.
  - The action works at relevance 3.0, below grind and loot. It walks the
    planned path in 8-yard legs using playerbots' own walking at the lowest
    priority, so any other movement goes first.
  - At the end of a path it rolls the rest chance: the buddy sits for 15–25 s.
  - Each buddy's state sits in a locked table and is copied out while planning,
    so planning runs outside the lock.
  - A pass every 3 s puts each buddy's peace-time strategies right. In the open:
    follow off; roam, grind, loot and gather on. In a town: follow on; roam and
    grind off.
- `modules/mod-buddies/src/buddies_party.cpp`, a pass every 5 s:
  - A raid made only of the owner and their own buddies is disbanded. Playerbots
    creates one at login, because it adds every buddy to the owner's group and
    converts it past five.
  - A buddy in the owner's group leaves it past 75 yards.
  - A buddy leaves a far party within 74 yards; the server disbands a group left
    with one member.
  - Ungrouped buddies within 60 yards join the owner's party, nearest first, up
    to five. A new party is made if the owner has none. A raid the owner made
    with other players is never joined.
  - Ungrouped buddies past 74 yards fill existing far parties, then form new
    ones led by the lowest-numbered buddy. A lone far buddy waits for a second.
- `config/patches/C029-basic-buddies-keep-own-parties.sh` sets
  `AiPlayerbot.KeepAltsInGroup = 1`. Without it, playerbots makes a bot leave
  any group its master isn't in at login, which would break up the far parties.

**Files changed:**
- `buddies_loader.cpp` registers the two new scripts.
- `scripts/test-profile-config-gates` gains the C029 expectation.
- `modules/mod-buddies/README.md` lists the new files. I also corrected a stale
  line that said a buddy joins the clan at creation; it joins 5 seconds after
  appearing.
- Issues 617e1 and 617c2 have their Current Behavior rewritten; both pass
  `validate-issues`.
- I recorded the Bash-written files with `claim-own-change`. For
  `test-profile-config-gates` and the loader that claim covers the whole file;
  all of it is this session's work.

**Compile check:** a copy of your checker with `roam/` added to the include
path, run over every module file including the other fork's
`roam/buddy_roam_core.cpp`. No errors. Two warnings remain, both from outside
the module:
- "FMT_CONSTEVAL macro redefined" in every file, caused by the checker leaving
  out the precompiled header.
- A signed/unsigned comparison inside playerbots' `MovementActions.h`.

One real error was found and fixed: `buddies_roam_ground.cpp` needed to include
`QueryResult.h`.

**Config gates test:** 23 passed, 0 failed, including
`AiPlayerbot.KeepAltsInGroup = 1`.

**Where to register the new behaviour** (checked in source):
- Playerbots builds the per-class shared lists in its before-world-initialised
  hook (`PlayerbotAIConfig::Initialize` calls
  `AiObjectContext::BuildAllSharedContexts` at `PlayerbotAIConfig.cpp:750`).
- `World.cpp:1015` fires that hook inside the world's setup, and `OnStartup`
  runs afterwards at `Main.cpp:387`. Bots log in during world updates, which
  start after that.
- So the world's start hook is the safe place to register.
- A playerbots config reload calls `Initialize` again (`PlayerbotMgr.cpp:1038`,
  `RandomPlayerbotMgr.cpp:2400`). That only adds its own lists again; ours stay
  in the name tables because `Add` merges.

**No header change was needed.**

Open questions:
- **Crowding count:** it counts every player within 100 yards, other buddies
  included. Should players standing in another area count?
- **Rest:** it is only sitting for 15–25 s. Should it also make the buddy eat
  or drink explicitly, as "sit down and eat food" suggests?
- **Buddy count after login:** the login raid is disbanded on the first pass. A
  buddy created later, while the owner's party already holds five, makes
  playerbots convert it to a raid again, and the pass then disbands it. That is
  a brief churn once per such login. Acceptable?
- **Merging far parties:** two small far parties (2 + 2) are not merged. Should
  they be?
- **Town rule:** the town check uses the owner's current area only; a buddy
  standing just outside a town while the owner is inside also stops roaming.
  Right, or check each buddy's own area?
- **Area size:** a very large area stops the centre search at 8000 points (about
  200,000 square yards), and then uses the centre of the part nearest where the
  owner first entered. Right?
- **Playerbots mode:** `UpdateAIGroupMaster` and the far parties' bot leaders: a
  bot-led party keeps each buddy's master as the real owner, per the research.
  That needs confirming in game.

--------------------------------------------------------------------------------

