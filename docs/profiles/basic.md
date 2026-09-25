# Basic Profile

**One-line summary:** The ordinary level 1–60 game with AI companion
playerbots and the quality-of-life layer, Outland open at the cap. It is
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
- **Outland open at the cap, as a hunting ground.** The Dark Portal opens
  at 58, as in the stock game. Outland has no quests, no gathering nodes
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
  loot compares with the vanilla raids: `docs/profiles/basic-gear-ladder.html`.
- **Outland gear rescaled onto the ladder.** Same items, same loot tables,
  smaller numbers, all wearable at 60: greens run from about level-60
  dungeon blues (Hellfire Peninsula) to about Emerald Dragon epics (the
  Isle); world blues from just under Hellfire Ramparts to the start of
  Naxxramas, and bind on pickup; each upper dungeon's blues land on its
  rung; Kael'thas's epics are item level 100. Rating stats (crit, hit,
  haste...) on Burning Crusade gear carry a discount so they are worth at
  60 what they were meant to be worth at 70.
- **Level gaps stop hurting past three.** Hit and miss chances worsen with
  level difference only up to 3 levels (source patch B005), and creatures
  of level 64 and up never land crushing blows (B031).
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
