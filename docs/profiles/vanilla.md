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
- **Fixed starting zones by faction.** Every Alliance character
  starts in Duskwood (at Darkshire). Every Horde character starts
  in Hillsbrad Foothills (at Tarren Mill).
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

The worldserver listens on port 4464; authserver on 4364. Point
your client's `realmlist.wtf` at the appropriate address (see the
[connection guide](../connection-guide.md)).

## What to expect at each level

### Level 1–19 (you don't see these)

Skipped. Characters are created at level 20.

### Level 20 (creation moment)

You appear in your faction's starting zone — Darkshire for Alliance,
Tarren Mill for Horde — fully equipped in your class kit, with
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
