# Vanilla Profile

**One-line summary:** Default WotLK 3.3.5a + AI companion playerbots,
with a light ruleset that compresses the level curve and trims a few
quality-of-life knobs.

## What you get

A WoW 3.3.5a server that feels like stock Wrath of the Lich King in
most ways, but with a deliberate set of tunings:

- **Level 20 start, level 40 cap.** No tutorial grind; you begin in
  the middle of the level curve and play through the sweet spot of
  3.3.5a content toward Uldaman as your endgame dungeon.
- **AI companion playerbots.** Run dungeons solo with bots filling
  your party. The auction house is also active — bots buy gear they
  want and post their drops.
- **Fixed starting towns by race.** Each race starts at a level-20
  town's innkeeper: human and dwarf at Menethil Harbor, draenei at
  Darkshire, night elf and gnome at Astranaar, orc at Ratchet,
  undead and troll at Tarren Mill, tauren and blood elf at Sun Rock
  (148n; the setup step E007 holds the coordinates).
- **Death Knight class disabled.** A level-55-starting class in a
  level-40-cap ruleset doesn't make sense yet. Disabled until the
  client-patching pipeline can land a custom DK starting flow.
- **No flight paths.** Walk, ride a mount when you can afford one,
  take boats and zeppelins between continents. The world is smaller
  and the travel matters. Each former flight master has a unique
  flavor line explaining why the gryphons/wyverns aren't flying.
- **Full level-20 starter kit per class.** Every character spawns
  wearing a complete class-appropriate white-quality outfit (chest,
  legs, gloves, boots, belt, bracers, cape, weapon kit, class relic)
  — no helmets or shoulderpads on purpose. The kit shows on the
  character-select screen the moment you finish creation.
- **All trainer abilities through level 20 already learned.** No
  trips to nineteen trainers — your Rogue knows Dual Wield, your
  Mage has Frostbolt rank 4, your Warrior has Charge / Rend /
  Thunder Clap from day one.
- **Slower movement (80% of normal), heavier fall damage (10×).**
  Travel is deliberate, terrain matters. Pairs naturally with the
  no-flight rule.
- **GM characters auto-elevate on login.** If you create a character
  on a GM-flagged account, GM mode is on automatically — handy for
  ops, harmless if you're just playing.

## What you do NOT get

These are conscious omissions, not bugs:

- **No wow-chat custom design layer.** No ambush monster spawns,
  no custom classes, no talent reshaping, no level-20 cap-with-
  reshaped-talents, none of the experimental scripts living in
  `src/lua-beta/`. Vanilla loads its own minimal Lua corpus
  (`src/lua-vanilla/`) which currently just handles the auto-equip
  hook.
- **No transmog system.** Visual appearance comes from what you wear.
- **No NPC services NPCs** (no `mod-npc-services`). Repair, train,
  flight (well, no flight), and other interactions happen at the
  appropriate canonical NPCs.
- **No NPC buffer.** No standing in a city to get world buffs from
  a vendor NPC.
- **No XP rate multiplier.** The 20-to-40 stretch plays at canonical
  XP pacing; the compression comes from skipping the 1-to-20 grind,
  not from doubling rewards.
- **No instant teleport convenience commands.** You walk or you fly
  (oh wait).

## Installed modules

- **mod-playerbots** — the AI companion system
- **mod-solo-lfg** — solo queue for the dungeon finder; bots fill
- **mod-aoe-loot** — one keypress loots every nearby corpse
- **mod-fireworks-on-level** — visual confetti on level-up
- **mod-ale** — Lua scripting engine; runs the starter-equipment
  auto-equip hook and is available for future scripts

All five modules track upstream HEAD — vanilla stays current with
upstream improvements rather than being pinned to specific commits.

<!-- patch-lists: begin. Written by scripts/generate-patch-lists from the patches' headers (issue 189f): edit a header, then run it; do not edit by hand. -->
## Patches

Every patch this profile takes, in the order the build runs them:
lowest priority first, each line its header's own (`scripts/plan-patches vanilla`).

**Before the compile (source patches, taken off again once it is through):**

| priority | id   | kind   | about                                                                                       |
| -------: | ---- | ------ | ------------------------------------------------------------------------------------------- |
|      120 | B002 | source | Add ALE OnLogin hook to playerbots bot login                                                |
|      140 | B004 | source | Fix ~695 compiler warnings in upstream modules                                              |
|      300 | B020 | source | Add LOCK_ALE to ALEEventProcessor::RemoveEvent                                              |
|      320 | B022 | source | A --conf-dir option for the servers and dbimport, over the compiled-in module config folder |
|      350 | B025 | source | Vanilla playerbots start in the 148h starter kit (issue 148s)                               |
|      360 | B026 | source | Fix the bot-login Engine::Init crash (dangling strategy on duplicate add)                   |
|      370 | B027 | source | Guard Engine::Init against a strategy with a stale/foreign bot facade                       |
|      660 | B056 | source | Bots see only as far as they act                                                            |
|      670 | B057 | source | The most any view distance may be, as a setting                                             |

**After the compile and install (install steps and settings, mixed by priority):**

| priority | id    | kind     | about                                                                      |
| -------: | ----- | -------- | -------------------------------------------------------------------------- |
|     1010 | E001  | install  | Create symlinks from install dir to the profile-specific Lua source        |
|     1040 | E004  | install  | Create RAM-backed log directory symlink                                    |
|     1060 | E006  | install  | Initialize config files (.dist -> .conf) and apply profile-specific values |
|     1100 | C001  | settings | Database Connections                                                       |
|     1105 | C002  | settings | Directory Paths                                                            |
|     1110 | C003  | settings | Run Speed 85% (named for its first value, 80%)                             |
|     1115 | C004  | settings | Fall Damage 10x                                                            |
|     1135 | C006c | settings | Max Level 40 (Vanilla)                                                     |
|     1155 | C007c | settings | Starting Level 20 (Vanilla)                                                |
|     1160 | C008  | settings | GM Login State                                                             |
|     1170 | C010  | settings | Network Ports                                                              |
|     1175 | C011  | settings | Realmlist Setup                                                            |
|     1185 | C014  | settings | Vanilla Playerbot Progression (enter at 20, climb to the 40 cap)           |
|     1190 | C015  | settings | Disable Death Knight (Vanilla)                                             |
|     1195 | C016  | settings | Missing server config keys                                                 |
|     1200 | C017  | settings | Level-correlated caps                                                      |
|     1205 | C018  | settings | Vanilla Playerbot Account Count                                            |
|     1210 | C019  | settings | RealmID per profile                                                        |
|     1215 | C020  | settings | Vanilla Playerbot Population Band (hold 128–256 active bots)               |
|     1220 | C021  | settings | SOAP Loopback Console (remote command channel for local scripts)           |
|     1225 | C022  | settings | Enable Custom Starting Spells (Vanilla)                                    |
|     1240 | C025  | settings | Client cache version follows the profile's content (issue 160)             |
|     1275 | C032  | settings | Preserve Custom Channels (so a script can tell one channel from another)   |
|     1285 | C034  | settings | No Faster Healing Below Level 15, on Every Server                          |
|     1305 | C038  | settings | No Quest Sparkles, Object Quest Marks or Map Points                        |
|     1310 | C039  | settings | Instances and Battlegrounds: See as Far as the Server Allows               |

**After the databases are brought to upstream's state (our SQL):**

| priority | id   | kind | about                                                                        |
| -------: | ---- | ---- | ---------------------------------------------------------------------------- |
|     2370 | E007 | sql  | Override playercreateinfo so vanilla characters spawn at the                 |
|     2380 | E008 | sql  | Clear the flightmaster bit network-wide and replace gossip with              |
|     2390 | E009 | sql  | Apply vanilla profile's class-specific starting equipment kit                |
|     2400 | E010 | sql  | Grant every newly-created vanilla character the full set of                  |
|     2490 | E019 | sql  | Installs a BEFORE INSERT trigger on acore_characters_vanilla.characters      |
|     2500 | E020 | sql  | Push the two ground riding skills to Classic level gates (148l): Apprentice  |
|     2510 | E021 | sql  | Grant every level-20 vanilla character a gathering + a production profession |
<!-- patch-lists: end -->

## How to switch to vanilla

From the project root:

```bash
echo vanilla > .profile
./scripts/install --profile vanilla
./scripts/start-mysql
./scripts/authserver &
./scripts/worldserver
```

The first `install` invocation clones the AzerothCore source (if
not already), clones the five modules, compiles the worldserver,
creates the suffixed databases (`acore_world_vanilla`, etc.) on
the shared MySQL instance (port 3307), and applies vanilla's
config patches and SQL migrations.

The worldserver listens on port 4462; authserver on 4362 — the same
ports as release, beta and basic, since only one runs at a time
(config patch C010). Point
your client's `realmlist.wtf` at the appropriate address (see the
[connection guide](../connection-guide.md)).

## What to expect at each level

### Level 1–19 (you don't see these)

Skipped. Characters are created at level 20.

### Level 20 (creation moment)

You appear at your race's starting town (see "What you get") — fully equipped in your class kit, with
every trainer ability through level 20 already in your spellbook.
The character-select screen shows you in the kit, not in the
default DBC starter outfit.

Your first session: pick up the quests in your starting hub, talk
to the local playerbots if you want a party, head out into the
zone. The kit is white-quality so any green drops you find are
upgrades, but the kit's stats are sized for your level — you're
not handicapped, you're just not ahead either.

### Level 20–30

The normal 3.3.5a 20-30 content is your playground. Alliance:
finish Duskwood, push into Stranglethorn Vale or back to the
Wetlands. Horde: finish Hillsbrad, push into Arathi Highlands or
the Hinterlands. The slower movement makes each zone feel larger
than it would on a normal server.

### Level 30–40

The cap is in sight. You're now playing toward Uldaman as your
endgame dungeon. Alliance reach it through Loch Modan / the Dwarf
roads; Horde reach it through Arathi and the Badlands. Five-man
content with playerbots in your party is the loop.

### Level 40 (cap)

XP gain stops at 40. Endgame is Uldaman runs (mod-solo-lfg lets
you queue for it solo with bots filling the group), the open-world
chase of better gear, and whatever you want to do with the freedom
of being capped on a small map.

If a higher-level character is your friend, the proportional
reward system (issue 801 — designed, not yet implemented on
vanilla) is meant to make small contributions to high-level fights
meaningful. Today on vanilla, low/high-level grouping is
unmodified.

## Where to ask for help

- Server design / ruleset choices: [`issues/148-vanilla-profile-default-wotlk-playerbots.md`](../../issues/148-vanilla-profile-default-wotlk-playerbots.md)
- Why a particular feature was added or removed: each sub-issue
  (`issues/148a-...`, `148h-...`, etc.) records the rationale.
- Profile-system architecture (how the four profiles relate): see
  [`issues/136-canonical-profile-definitions.md`](../../issues/136-canonical-profile-definitions.md).
- Other profiles: [`docs/profiles/index.md`](index.md).
