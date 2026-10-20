# Basic Profile

**One-line summary:** The ordinary level 1–60 game with AI companion
playerbots and the quality-of-life layer, Outland open to anyone. It is
the baseline new features, starting with custom classes, are developed
against.

Named for the OSR Dungeons & Dragons Basic Set: complete by itself,
covering the early levels. **Expert** (levels 61–80, starting at 60) will
continue it; it is not built yet (issue 156).

Design and build record: issue 155 and its sub-issues 155a–155f.

## What you get

- **Level 1 start, level 60 cap.** No head-start: no starter kit, no
  pretrained abilities, no starting professions.
- **A rotating starting valley.** New characters are not sent to their
  race's own valley. Each faction has four level-1 valleys (Alliance:
  Northshire, Coldridge, Shadowglen, Ammen Vale; Horde: Valley of Trials,
  Deathknell, Camp Narache, Sunstrider Isle), and the faction's current
  valley changes after every 30 new characters, in a shuffled order that
  visits each valley once per cycle. Your hearthstone is bound where you
  begin. Bots are not part of the rotation.
- **Quests open to your whole faction.** Any Alliance character can do any
  Alliance quest, whichever race it was meant for; the same for the Horde.
  Racial mounts stay racial.
- **Visiting Mentors wherever new characters train.** At every starting
  valley, first town and capital, one mentor (dressed as a trainer of another
  race, e.g. a tauren druid on Sunstrider Isle) offers "Can you teach me the
  ways of the <class>?" for each class that has no trainer there. Stormwind
  trains everything and has none; 23 places have one.
- **No flight paths.** Every former flight master has a line explaining why
  the birds aren't flying, including those in Outland and in the draenei
  and blood elf home zones.
- **Classic riding levels.** Apprentice Riding (60% mount) at 40,
  Journeyman Riding (100% mount) at 60.
- **Outland open to anyone, as a hunting ground.** No level gate is known on
  the Dark Portal (to be confirmed in game; 155l). Outland has no quests, no gathering nodes
  or special fishing spots, and no professions past 300. Two flights
  exist: the Dark Portal to Honor Hold or Thrallmar and back, and Light's
  Hope Chapel to the Isle of Quel'Danas and back (the only way onto the
  Isle; the Shattrath portal is gone). Its monsters are four levels higher than
  stock (six on the Isle), friendly folk and world bosses unchanged.
- **Outland dungeons are raid-hard, in a ladder.** Sixteen dungeons admit
  level 60: the nine stock ones plus Old Hillsbrad, Black Morass, Shadow
  Labyrinth, the three Tempest Keep dungeons and Magisters' Terrace (their
  attunement quests removed). Each dungeon's creatures gain levels by that
  dungeon's step, so end bosses climb from 66 (Hellfire Ramparts) to 76
  (Magisters' Terrace), with Kael'thas at 78; health and damage follow the
  level. Heroic modes are stock (and closed). The full ladder, and how its
  loot compares with the vanilla raids: `docs/HTML/basic-gear-ladder.html`.
- **Outland gear rescaled onto the ladder.** Same items, same loot tables,
  smaller numbers, all wearable at 60: greens run from about level-60
  dungeon blues (Hellfire Peninsula) to about Emerald Dragon epics (the
  Isle); world blues from just under Hellfire Ramparts to the start of
  Naxxramas, and bind on pickup; each upper dungeon's blues land on its
  rung; Kael'thas's epics are item level 100. Rating stats (crit, hit,
  haste...) on Burning Crusade gear carry a discount so they are worth at
  60 what they were meant to be worth at 70.
- **Level 61–80 abilities from class books.** Every ability and rank a
  class trainer teaches from 61 to 80 (all ten classes) is a class book
  usable at 60, like the game's own Ahn'Qiraj books ("Tome of Frostbolt
  XIV"): the Burning Crusade–era ones drop in Ahn'Qiraj (the 40-person
  temple about one or two a clear, the 20-person ruins a quarter as often
  per boss) and three from each Emerald Dragon; the Wrath-era ones drop in
  Naxxramas, about one or two a clear. Talent abilities' higher ranks need
  the talent. Teleport and Portal: Dalaran are left out (Northrend is
  closed).
- **Level gaps stop hurting past three.** Hit and miss chances worsen with
  level difference only up to 3 levels (source patch B005), and crushing
  blows start only 8 levels up (stock: 4), ramping to their full chance at
  12 levels up (B031; 13% instead of 65% at 8 levels up).
- **Slower movement (80%), heavier fall damage (10×).**
- **Death knights allowed, with two limits.** An account needs a level-55
  character on the realm to create one, and no playerbot plays a death
  knight. A fuller design (creating a death knight consumes the level-55
  character; Acherus becomes an open leveling zone) is issue 718.
- **No random bots.** The bot module's ambient population is switched off;
  the only bots will be each player's own buddies (issue 617, not built
  yet), so for now the world has no bots.
- **No race intro cinematic** on first login.
- **GM accounts log in with GM on**, as on vanilla.

## What you do NOT get

- The wow-chat design layer (ambush spawns, the beta Lua corpus).
  `src/lua-basic/` starts empty.
- An experience multiplier: levelling is at the stock rate.
- Northrend: no basic character can use it.

## Installed modules

The same five as vanilla: mod-playerbots, mod-solo-lfg, mod-aoe-loot,
mod-fireworks-on-level, mod-ale. The source tree is shared with release,
beta and vanilla and pinned to the same commit (see `./scripts/profiles`).

<!-- patch-lists: begin. Written by scripts/generate-patch-lists from the patches' headers (issue 189f): edit a header, then run it; do not edit by hand. -->
## Patches

Every patch this profile takes, in the order the build runs them:
lowest priority first, each line its header's own (`scripts/plan-patches basic`).

**Before the compile (source patches, taken off again once it is through):**

| priority | id   | kind   | about                                                                                       |
| -------: | ---- | ------ | ------------------------------------------------------------------------------------------- |
|      120 | B002 | source | Add ALE OnLogin hook to playerbots bot login                                                |
|      140 | B004 | source | Fix ~695 compiler warnings in upstream modules                                              |
|      150 | B005 | source | Cap level difference impact on hit/miss at ±3 levels                                        |
|      300 | B020 | source | Add LOCK_ALE to ALEEventProcessor::RemoveEvent                                              |
|      320 | B022 | source | A --conf-dir option for the servers and dbimport, over the compiled-in module config folder |
|      360 | B026 | source | Fix the bot-login Engine::Init crash (dangling strategy on duplicate add)                   |
|      370 | B027 | source | Guard Engine::Init against a strategy with a stale/foreign bot facade                       |
|      380 | B028 | source | Basic: new characters spawn in their faction's rotating starting valley                     |
|      390 | B029 | source | A trainer gossip option can name which trainer list it opens                                |
|      400 | B030 | source | Build the basic profile's own server rules into the worldserver                             |
|      410 | B031 | source | Crushing blows start 4 levels later and ramp in over 4 more                                 |
|      420 | B032 | source | A buff can be cast on anyone, whatever the gap between its level and theirs                 |
|      430 | B033 | source | White (common-quality) gear is never repaired                                               |
|      450 | B035 | source | Respec cost: no cap, and it falls on the weekly reset                                       |
|      460 | B036 | source | Build the project's buddy module (mod-buddies) into the worldserver                         |
|      470 | B037 | source | Playerbots: a switch for the group invite at a bot's login                                  |
|      480 | B038 | source | Built-in chat channels a profile refuses                                                    |
|      490 | B039 | source | Log why the console thread shuts the world down (issue 163)                                 |
|      500 | B040 | source | Creatures one player cannot select                                                          |
|      510 | B041 | source | Lua calls for creatures one player cannot select                                            |
|      520 | B042 | source | A bot says "AI was reset to defaults" only when asked to reset                              |
|      530 | B043 | source | The world says who stopped it                                                               |
|      540 | B044 | source | Companion accounts: their characters are not in /who and can't be friended                  |
|      550 | B045 | source | Playerbots: a bot on a companion account takes no chat commands                             |
|      560 | B046 | source | Playerbots: buddies judge gear by their own talent plan and roll                            |
|      570 | B047 | source | Creature outfits: a creature can look like a dressed player character                       |
|      580 | B048 | source | Buddies don't whisper their owner about failed item moves                                   |
|      590 | B049 | source | Spirit heals by stamina, in combat too                                                      |
|      600 | B050 | source | Playerbots: a buddy weighs spirit by what it heals                                          |
|      610 | B051 | source | a Lua call that asks the navigation mesh how far a walk is                                  |
|      620 | B052 | source | Playerbots: a buddy's long walk never ends in a teleport                                    |
|      630 | B053 | source | Players walk at the full stock speed; only running and the rest                             |
|      640 | B054 | source | The server accepts navigation tiles built by version 19 of the                              |
|      660 | B056 | source | Bots see only as far as they act                                                            |
|      670 | B057 | source | The most any view distance may be, as a setting                                             |

**After the compile and install (install steps and settings, mixed by priority):**

| priority | id    | kind     | about                                                                                   |
| -------: | ----- | -------- | --------------------------------------------------------------------------------------- |
|     1010 | E001  | install  | Create symlinks from install dir to the profile-specific Lua source                     |
|     1040 | E004  | install  | Create RAM-backed log directory symlink                                                 |
|     1060 | E006  | install  | Initialize config files (.dist -> .conf) and apply profile-specific values              |
|     1100 | C001  | settings | Database Connections                                                                    |
|     1105 | C002  | settings | Directory Paths                                                                         |
|     1110 | C003  | settings | Run Speed 85% (named for its first value, 80%)                                          |
|     1115 | C004  | settings | Fall Damage 10x                                                                         |
|     1140 | C006d | settings | Max Level 60 (Basic)                                                                    |
|     1150 | C007b | settings | Starting Level 1 (Beta/Release/Basic)                                                   |
|     1160 | C008  | settings | GM Login State                                                                          |
|     1170 | C010  | settings | Network Ports                                                                           |
|     1175 | C011  | settings | Realmlist Setup                                                                         |
|     1195 | C016  | settings | Missing server config keys                                                              |
|     1200 | C017  | settings | Level-correlated caps                                                                   |
|     1210 | C019  | settings | RealmID per profile                                                                     |
|     1220 | C021  | settings | SOAP Loopback Console (remote command channel for local scripts)                        |
|     1230 | C023  | settings | Basic: No Random Bots                                                                   |
|     1235 | C024  | settings | Basic Death Knight Rules (interim, until issue 718)                                     |
|     1240 | C025  | settings | Client cache version follows the profile's content (issue 160)                          |
|     1245 | C026  | settings | Basic: No Dual Spec                                                                     |
|     1250 | C027  | settings | Basic: Buddies Spend Their Own Talents                                                  |
|     1255 | C028  | settings | Basic: Honor Without a Cap                                                              |
|     1260 | C029  | settings | Basic: Buddies Keep Their Own Parties                                                   |
|     1265 | C030  | settings | Basic: No Group Invite at a Buddy's Login                                               |
|     1270 | C031  | settings | Basic: No World Channels (General, Trade, the Defense channels, LFG, Guild Recruitment) |
|     1275 | C032  | settings | Preserve Custom Channels (so a script can tell one channel from another)                |
|     1285 | C034  | settings | No Faster Healing Below Level 15, on Every Server                                       |
|     1305 | C038  | settings | No Quest Sparkles, Object Quest Marks or Map Points                                     |
|     1310 | C039  | settings | Instances and Battlegrounds: See as Far as the Server Allows                            |
|     1380 | E008  | install  | Clear the flightmaster bit network-wide and replace gossip with                         |
|     1490 | E019  | install  | Installs a BEFORE INSERT trigger on acore_characters_vanilla.characters                 |
|     1500 | E020  | install  | Push the two ground riding skills to Classic level gates (148l): Apprentice             |
|     1520 | E022  | install  | Open every quest to its whole faction on the basic profile (issue 155e):                |
|     1530 | E023  | install  | Create and seed the rotation-state table the basic profile's                            |
|     1540 | E024  | install  | Basic's Outland dungeon ladder (issue 155f): sixteen dungeons open at 60,               |
|     1550 | E025  | install  | One "Visiting Mentor" per starting valley that teaches exactly the classes              |
|     1560 | E026  | install  | The table of per-creature (and per-map) damage, healing and health                      |
|     1570 | E027  | install  | Outland without tradeskills (issue 155n): its herb, ore, gas and fishing                |
|     1580 | E028  | install  | Outland without quests (issue 155l): every Outland, Shattrath, Isle and                 |
|     1590 | E029  | install  | Inscription without glyphs (issue 155o): glyph recipes off the trainers,                |
|     1600 | E030  | install  | Darkmoon cards (issue 155o): nothing from a Darkmoon deck binds, and the                |
|     1610 | E031  | install  | Outland gear scaling (issue 155k, with 155f's dungeon ladder): Outland's                |
|     1620 | E032  | install  | Outland world levels (issue 155k): Outland's open-world monsters +4, the                |
|     1630 | E033  | install  | Gem supply (issue 155p, stage 1): prospecting yields, Wrath and epic gem                |
|     1660 | E036  | install  | White gear durability (issue 155p): white weapons and armor last twice as               |
|     1670 | E037  | install  | Class books for the level 61-80 abilities (issue 155q): one stock-style                 |
|     1680 | E038  | install  | The Dark Portal as the only door into Outland (issue 155l): Shattrath's                 |
|     1690 | E039  | install  | No guild banks (issue 617l): every Guild Vault spawn removed. Same                      |
|     1700 | E040  | install  | Sargobras at the gate of Acherus (issue 718): the gossip NPC in the Ebon                |
|     1720 | E042  | install  | The buddy clan and roster tables (issue 617a1): each owner's companion                  |
|     1730 | E043  | install  | Sargobras, the buddy selector (issue 617b): his two creatures (the valley               |
|     1740 | E044  | install  | Every named area's borders and middle (issue 617e2), for the buddies'                   |
|     1750 | E045  | install  | The beds buddies sleep on in towns (issue 617e4), placed by hand in game                |
|     1760 | E046  | install  | The world bosses' respawn taken off the server's timer (issue 155j): the                |
|     1790 | E049  | install  | Every town's exploring grid baked ahead of time (issue 617o3), so buddies               |
|     1800 | E050  | install  | The world's little towns as circles (issue 617e4a): every cluster of                    |
|     1820 | E052  | install  | Every gearset profile (issue 617r: src/lua-basic/data/gearsets/*.lua) as                |
|     1830 | E053  | install  | The `command` rows for the game master commands the project compiles in                 |
|     1840 | E054  | install  | The game's legendaries as level-60 raid drops (issue 182): level-60 copies              |
|     1850 | E055  | install  | The smaller places buddies roam (issue 617e12, the first cut): every named              |
|     1860 | E056  | install  | The kept stand-ins (issue 617t1): one row per stand-in character the buddy              |
|     1870 | E057  | install  | The Eternal Belt Buckle usable from level 60 (issue 624): one item's                    |

**After the databases are brought to upstream's state (our SQL):** none.
<!-- patch-lists: end -->

## How to switch to basic

```bash
echo basic > .profile
./scripts/install --profile basic
./scripts/start-mysql
./scripts/authserver &
./scripts/worldserver
```

Install creates `acore_world_basic`, `acore_characters_basic` and
`acore_playerbots_basic` on the shared MySQL (port 3307), seeded from a
fresh AzerothCore base, and the realm list gains "Everland Ghostsong
(basic)" as realm 5. The servers use the shared ports (world 4462, auth
4362); only one of release, beta, vanilla and basic runs at a time.

MySQL should be running during install: the database setup steps register
their SQL directories with the server's updater then. If it is down they
print a NOTICE, and the SQL applies only after a later install run with
MySQL up.

## Checking an install

```bash
./scripts/test-profile-config-gates . basic   # offline: config values
./scripts/test-source-patches . basic         # offline: source patches round-trip
./scripts/test-patched-syntax . basic         # offline: patched files pass the compiler's checks
./scripts/validate-basic-state                # after install + first boot: database state
```
