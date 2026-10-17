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
- **151** bot population governor (in progress, built on vanilla): beta
  keeps 500 random bots, each ambushed. Choosing how many is a knob,
  recorded in `docs/balance-updates.md`.

### 3. The scheduler

- `periodic_events.lua.disabled` back on: the clock that sends travellers
  and treasure (and, in wow-chat-1, the ambush). The ambush now runs its
  own clock, so the scheduler must not start a second one. A toy-world
  test like the ambush's goes with it.

### 4. Travellers, who carry the trainers and merchants

- `travel.lua.disabled` back on, with its tests.
- **503** dynamic trainer spawning (marked completed, but its trainers
  come from the traveller pool, which is off: complete again once seen in
  game, then move to completed/).
- **504** a traveller sits when the player sits (implemented, needs
  testing). **505** creature-class travellers (open). **501** custom
  merchant system (open).
- With trainers walking again, beta's trainer-spell changes (E013, E014)
  start meaning something, and a new character can learn.

### 5. Treasure

- `treasure.lua.disabled` back on.
- **402** shared chest loot (partial: pool built, per-player queues
  needed), **404** sold items feed the treasure pool (partial; the sell
  hook B006 is in beta's list), **409** empty loot chest templates (E016
  makes them), **407** chest vulnerability, **408** several players at one
  chest, **410** hearthstones bound to chests, **411** no zero-value
  duplicates.

### 6. Tomes and death

- **405** ability tome system (partial: Lua done, recipes and SQL needed;
  its talent-bonus module was set aside, so read it again first).
- **406** death durability (open).

### 7. Companions

- The bot behaviors, one at a time, out of `.behaviors.disabled/`, each
  with its own check: **601** find monsters, **603** avoid monsters,
  **604** sit and rest, **606** orbit the player, **609** gestures and
  convoys, **611** wandering like travellers, **612** dungeon rails,
  **613** orchestrator modes, **614** boredom, **615** ranged help,
  **610** system integration (another session is editing it now).
- **617** buddy bots: built for basic. Which of it beta wants is a choice
  to make here.

### 8. Custom classes on the stock client

- **502** universal class trainers (designed in depth, not built): a
  server setting lets any class train any trainer's spells, gold being the
  only limit, with each borrowed spell re-costed in the learner's own
  resource. This is the trainers approach, and it works on the stock client.
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
assets, so its monsters need records of their own first. No issue holds
that yet (issue 200, open question 2).

## Open questions

Kept in the issue they belong to, asked one at a time:

- 136b: which profile keeps the existing databases; ports; release's
  world; how many realms run at once.
- 200: how many random bots; where "new creature records" lives; whether
  StackTracePlus runs; death knight creation under a cap of 20.
- The group hearthstone: whether beta's should work like the buddies'
  (see the reply of 2026-10-17 in the transcript).
