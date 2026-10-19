# Beta Roadmap — bringing the wow-chat game back

*Written 2026-10-17 from the beta audit and the issue files. The plan's
blueprint is issue 200 (incremental feature restore); this page is the
order to do it in. Each step names the issues behind it and what state
they are in. Counts of done and open issues per phase come from
`/home/ritz/programming/ai-stuff/scripts/progress-dashboard.lua <project> -m`.*

## Where beta stands

Beta is meant to be the wow-chat survival game, a realm of its own beside
the other profiles: an empty world that fills in around each player with
ambushes, treasure and travellers who wander by.

Since April it has run only the danger half. On 10 April every custom
feature was switched off to make a plain baseline for the profile system.
Only the ambush was switched back on (rewritten to run its own clock). The
scheduler, treasure, travellers (who carry the trainers and merchants),
ability tomes, death durability, the custom-class framework and the bot
behaviors stayed off. Beta's install still clears the world of
creatures, so a new character today meets monsters and nothing else, and
can't learn a spell.

The installed beta server dates from 9 April and would boot with no custom
scripts (its link points at a folder renamed in June). Its source patches
still apply and revert cleanly at the current upstream version, so a
reinstall should build. Beta's installs are the owner's to run.

## What was done on 2026-10-17

- Folders meant to be switched off now are (a leading dot). The engine
  skips only names that begin with a dot, so the behaviors folder had been
  read since April (it registered nothing, so play didn't change).
- The leftover engine check that told everyone the time every five seconds
  was removed.
- The Knight definition loads instead of stopping on its first line.
- The ambush got its holds back (not while sitting, dead or swimming, not
  with three chasing, not in a rare's fight). Each monster now counts
  once. A logout or a map border mid-chase no longer breaks it. Retried
  spawns stay near the player and never closer than 30 yards. An empty
  database answer no longer starts a second clock. The clock's drift
  survives a relog.
- Beta's death knights start at level 1 again (issue 206). A settings
  patch had been starting them at the cap since June.
- New checks, run before every build: `scripts/test-ambush` (the ambush in
  a toy world) and `scripts/test-beta-lua-load` (every beta script loaded
  the way the engine loads them). `scripts/test-profile-config-gates <dir>
  beta` checks beta's settings.

## The steps, in order

Each step is switched on only with a check that shows it working, in the
toy world where it can be and in game where it must be. Later steps use
what earlier ones bring: travellers carry the trainers that the class
work needs, and treasure is fed by the selling that merchants allow.

### 1. A realm of its own

- **136b** every profile running at once (new): own databases and
  worldserver port per profile, so beta stops sharing release's world, and
  the realm list shows every realm, online or greyed out. Open: which of
  beta and release keeps the existing databases; the port scheme; how
  release's world goes back to stock; how many realms this machine runs.
- **136a** unified realmlist (open): one login, one realm row per profile;
  136b changes its "one at a time".
- **138** sql-profile-switch-rollback (open): matters less once nothing has
  to be switched off.
- Then the owner reinstalls beta.

### 2. Boot clean, and watch the danger half

- **302** ambush monsters not spawning (in progress since spring): closes
  when an in-game run shows monsters arriving, chasing and holding.
- **306** bots fire the login hook (open, but its patch is B002, in beta's
  list): verify in the run and close.
- **210** per-player ambush queue (built, checked offline): its in-game
  check, two players at different levels.
- **151** bot population governor (in progress, built on vanilla). Beta's
  random bots go from 500 to 200 (owner, 2026-10-17; C035, recorded in
  `docs/balance-updates.md`), each still ambushed.
- **211** group hearthstone by invitation (new): a pop-up to each member
  when someone hearths, moved when the cast completes, standing in a
  circle by group number round the first hearther's arrival.
- **211a** druids hearth by Teleport: Moonglade (new, built offline):
  known from level 1; out to a random spot of the glade's open ground, and
  back to where they cast it (or entered their instance); the group comes
  as visitors and leaves with the druid. Also made 211's invitation follow
  the spell (cast begins, cancelled), so Astral Recall invites too.

### 3. The scheduler

- Done differently (branch beta-homework, 2026-10-17): wow-chat-1's
  scheduler (`periodic_events.lua.disabled`) stays off, because its bot
  half was left mid-way through a crash hunt. Each system keeps its own
  clock instead, as the ambush does, asking the scheduler's questions
  first: travellers now (travel.lua), treasure when it returns, the bot
  behaviors in step 7.

### 4. Travellers, who carry the trainers and merchants

- Done on branch beta-homework (2026-10-17, to be merged): `travel.lua`
  back on, its own clock, five bugs fixed, `scripts/test-travel`
  (every class at every level 1-20 for both factions meets one trainer of
  its class whose slice holds its level). Needs an in-game look.
- **503** dynamic trainer spawning: its level slices are real now (E014
  gives each travelling trainer its own cut copy of its class's lessons).
  Complete once seen in game, then move to completed/.
- **504** a traveller sits when the player sits (implemented, needs
  testing). **505** creature-class travellers (open). **501** custom
  merchant system (open).
- With trainers walking again, a new character can learn: beta's trainer
  steps (E011 death knights, E013 quest spells, E014 slices) now write the
  current `trainer` and `trainer_spell` tables (branch beta-homework); they
  had written `npc_trainer`, which the server ignores.

### 5. Treasure

- `treasure.lua.disabled` back on — **waits on the owner**: a chest shows
  its first opener nothing (issue 200, open question 3).
- **402** shared chest loot and **404** sold items feed the treasure pool
  (2026-10-17, in progress): the circulation is written and checked in a
  toy world by `scripts/test-treasure` (bots and leaving players given
  nothing, levels kept, unlooted chest items returned when a chest
  expires or its owner leaves, a sold item held while it can still be
  bought back, a seller never given their own copy back). Still open:
  the money a recycled sale pays (404). **409** empty loot chest templates (E016
  makes them), **407** chest vulnerability, **408** several players at one
  chest, **410** hearthstones bound to chests, **411** no zero-value
  duplicates.

### 6. Tomes and death

- **405** ability tome system (partial: Lua done, recipes and SQL needed;
  its talent-bonus module was set aside, so read it again first).
- **406** death durability (open).

### 7. Companions

- **First, the calls the behaviors make that the engine lacks.** Found
  2026-10-17 by the treasure session's method-name check
  (`scripts/test-ale-method-names`, branch completed-threads): calls in
  `.behaviors.disabled/` to methods the Lua engine does not have, each a
  failure waiting at the first run, the kind issue 606b met with
  `GetPosition`. `MovementExpired` (convoy, gestures), `SetTarget`
  (find-monsters), `GetPhase` (gestures; the engine has `GetPhaseMask`),
  `GetUnitsInRange` (orbit-player; it has `GetFriendlyUnitsInRange` and
  `GetUnfriendlyUnitsInRange`), `UseItem` (sit-and-rest). Fix each before
  its behavior is switched on. (`IsHostileTo`, which the behaviors also
  call, comes from source patch B007 on beta.)
- The bot behaviors, one at a time, out of `.behaviors.disabled/`, each
  with its own check: **601** find monsters, **603** avoid monsters,
  **604** sit and rest, **606** orbit the player, **609** gestures and
  convoys, **611** wandering like travellers, **612** dungeon rails,
  **613** orchestrator modes, **614** boredom, **615** ranged help,
  **610** system integration (another session is editing it now).
- **617** buddy bots: built for basic. Which of it beta wants is a choice
  to make here.

### 8. Custom classes on the stock client

- **721** class trainers and tomes of any ability (new, the beta design):
  every class, stock or custom, has its own trainer list; its trainers
  arrive as travellers and talk only to their own class; any ability works
  for any class once learned, and is learned only from your class's
  trainer or from a rare tome that teaches any ability.
- **502** any class at any trainer for gold (designed, not built): off for
  beta (owner, 2026-10-17), kept for a realm that wants it, to be renamed.
  Its study of the per-spell class check and the resource wall is what 721
  builds on.
- **705** class selector NPC, **706** the Knight (design complete; its
  definition loads), **709** class file format, **711** configuration
  schema, **712** conditional selector spawn: the framework that turns a
  definition into a class.
- **707** tiered talent trainers and **713** the custom talent window need
  AIO, which no build includes ("will not implement", `docs/roadmap.md`).
  On the stock client, talents come from the normal talent window, and
  tooltips show the stock text until the custom client can change them
  (**719** true ability tooltips).

### 9. Progression and story

- **801** proportional damage rewards, **802** talent tier limit, **803**
  monster accuracy cap (B005, in beta's list), **804** invisible level
  progression, **805** shared daily reset character.
- **901–913**: dungeon room spawns, contextual creatures, portals,
  narrators, lore, the clustered worldserver (913, which also bears on
  running many realms).

## Before release

The ambush announces a monster by its entry number ("here comes 1234!"),
which stays for beta. The release version uses only the project's own
assets, so its monsters need records of their own first: filed in 506
(the gear gallery, whose loop is the template for every generated asset).

## Open questions

Kept in the issue they belong to, asked one at a time:

- 136b: which profile keeps the existing databases; ports; release's
  world; how many realms run at once.
- 200: whether StackTracePlus runs; death knight creation under a cap
  of 20.
- 211: random bots and the hearth pop-up; two hearthers at once; Sargobras's
  pop-up or the game's summon dialog.
- 211a: visitors' ways back through a server restart; a visitor who is
  dead when the druid leaves.
- 617e: the buddies' new hearthstone rule and what it replaces.
- 718: which profile Chromie's death knight story belongs to.
- 721: 502's new name; borrowed spells' cost; talents without AIO.
