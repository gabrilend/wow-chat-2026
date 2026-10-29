# The Architecture of Capabilities: Concerns That Cooperate, Ambitions to Be Wrong

The owner, 2026-10-29: "can you build an architecture document that
organizes all of our capabilities into a structure that cooperates on
concerns and ambitions to be wrong?" And then, alone: "][tests][".

This is that map. Every capability Everland Ghostsong has is placed in one
of seven rings, by the concern it serves. Each says what it believes, how
it could be wrong, where we would see that, and what turns it off. Between
every two rings stand the tests. The system-level wiring (servers,
databases, modules) is in [architecture.md](architecture.md); this
document is about how the parts think together. The board of what is
built is `docs/next-compile-status.md` (`scripts/issue-status-board`).

## The core rule: ][tests][

The brackets face outward. The tests are not inside any one part: they
stand between the parts, at every seam, holding two capabilities together.
A capability may be as clever as it likes inside; where it hands something
to another, a test says what is handed and checks it. So a part being
wrong is found at the edge where it would hurt a neighbour, by a check
that belongs to neither. Two cases from 2026-10-28 and 10-29:
- The Lua load test, which checks the seam between the project's scripts
  and the game's script engine, found that the buddy levers' list shared a
  file name with its code, and the engine would refuse one.
- The comparison of the six ways to find a path, which checks the seam
  between pathfinding and the bots' own steering, found that A* and "learn
  the map" wobbled at over 100 degrees a yard. Neither part's own test
  could have seen either fault.

## The shape: seven rings

From what is, to what we see. Each ring uses the one before it and never
overrides it.

| Ring | Its concern | It answers |
|---|---|---|
| 1. Ground | the world as the game's own files say it is | what is there? |
| 2. Knowledge | what our tools work out and our bots learn about the ground | what do we believe about it? |
| 3. Rules | the game as we changed it | what is allowed, and what happens? |
| 4. Minds | what bots and characters decide | what does each one choose to do? |
| 5. Bodies | how a decision becomes action in the running server | how is it done? |
| 6. Views | what a person sees of all this, without logging in | what is happening, and how does it look? |
| 7. Operations | how it is built, run, kept and shared | how does it reach the world, and stay well? |

The tests sit in the seams between every pair, and wrap the whole (the
quick tests at each compile, the tests of each commit).

## The contracts: how the rings cooperate

Rules every capability keeps with its neighbours. Each was learned, most
of them by being wrong first.

1. **The ground decides.** No belief overrides what is there: every
   planner's pick is checked against the navigation mesh before a bot
   walks it (617o1, "the mesh decides"), and the painted map learns only
   from the world's own refusals. Knowledge is a guess about the ground,
   never a replacement for it.
2. **One core, three bodies.** A behaviour's thinking is written once as
   plain arithmetic with no server code (the roaming core, the following
   core, the five ways, the painted map). It is then:
   - tested alone, offline;
   - worn by the server, through thin glue;
   - mirrored in a sandbox page, step for step, run on the same courses
     with the same random numbers so the numbers read side by side.

   What the owner watches on a page is what the buddies do.
3. **Data made apart from data viewed.** Generators write data; viewers
   only read it (the zone data and the zone renderer, the ground and the
   sandbox, the roads and the battleground page). A viewer's bug can't
   corrupt data, and a generator's fault shows in the data, where a test
   can read it.
4. **Patches round-trip.** Our changes to the server, its modules and its
   Lua engine are scripts that apply and undo. The source tree goes back to
   upstream after every build, so upstream can move and our changes re-derive
   (the patch system; `test-source-patches`, `test-patch-undo-order`).
5. **Headers are the registry.** A patch's or test's own header says which
   profiles take it, in what order, and whether it is a quick test. No
   shared list to fall out of step (189; `test-patch-headers`,
   `test-patch-lists-current`).
6. **Built is not on.** Every new behaviour comes behind a switch that
   starts off: a module setting, a profile's patch, a command. Being built
   and being on are separate decisions, and the board shows both (the
   design target in CLAUDE.md).
7. **Refusal teaches.** The world's "no" is data:
   - a refused step paints a wall on the painted map, for every bot;
   - "learn the map" learns the cell;
   - the stuck rule backs out twice as far each time.

   Nothing pushes against the same thing for ever.
8. **One map, many hands.** Knowledge is shared at the widest scope it
   holds true for: the painted map is one per region and every buddy there
   paints it; the explorers' paint is per clan per area. A lesson one bot
   learns, all of them know.
9. **Every picture kept, every run receipted.** Each screenshot is filed
   with what made it, what changed, and what it shows
   (`development-history/`). Programs that run unattended write a goodbye
   receipt of what they did. The record of being wrong is kept as carefully
   as the record of being right.

## The method: ambitions to be wrong

The aim is not to be right first. It is to be wrong early, cheaply, and
visibly, and to keep what was learned.

- **Race alternatives.** When the right design is unknown, build several
  and run them on the same ground: five ways to find a path, then six
  (617o7, 617o8); the battleground's open questions each built two ways
  behind a switch (176a2). The race decides, not the argument.
- **Measure before believing.** A capability gets a number that would
  embarrass it: degrees turned a yard, bumps by round of trips, yards kept
  from walls, plans a millisecond. The turning measure, added for the
  painted map, caught A*'s wobble the same hour.
- **Undo on numbers, and keep the note.** An idea that measures worse is
  taken out and its numbers written where it was. Choosing the least-walked
  waypoints made spacing worse, so it was undone; the template and 617o8
  say why, so nobody tries it blind again.
- **Make the call, then ask.** A design question that would stop work is
  answered with the agent's best call, written down with why, for the owner
  to curate (CLAUDE.md, the design target). A wrong call costs a revert; a
  stopped day costs a day.
- **Prefer an error to a fallback.** A fallback hides being wrong. Where
  something can't be done, it says so, with what was done before it stopped
  (the owner's standing rule).

## The capabilities, ring by ring

Each card: what it **claims**; what would prove it **wrong**; where we would
**see** that; and what turns it **off**. Numbers in brackets are issues.

### 1. Ground

| Capability | Claims | Wrong if | Seen in | Off |
|---|---|---|---|---|
| Map files: heights, areas, water (data-files/maps) | the shape of the land, and which area each square is | heights or areas misread | `test-zone-maps`, `test-ground-decode` | (always on: it is the world) |
| Navigation mesh (data-files/mmaps) | where a body can stand and walk | a walkable route refused, or a wall walked through | `test-navmesh-caves`, refusals counted in game | (always on) |
| Collision models (data-files/vmaps) | the trees, rocks and buildings that block | a doodad missing, or a ghost one | the sandbox's refused steps | (always on) |
| The world database (acore_world_*) | every creature, quest, item and spawn | a row disagreeing with the client | `test-quest-reward-has-a-giver`, `test-sql-mirror` | per profile |

### 2. Knowledge

| Capability | Claims | Wrong if | Seen in | Off |
|---|---|---|---|---|
| Zone data (617e14b) | every zone's squares and sub-zones, the open sea left out | a zone cut wrong, sea counted as land | `test-zone-maps`, `test-render-zone` | regenerated, not switched |
| Area middles and sub-areas (617e2, 617e12) | each area's centre, and its parts by monsters and steep edges | a part that can't be walked to | `test-buddy-subareas` | per area |
| Grids, rooms and baked distance maps (617o2, 617o3) | the walkable cells and their walking distances | a cell the mesh refuses | `test-exploration-engine` | per mode |
| The painted map (617o8) | what the bots have walked and bumped, shared, kept between runs | bumps not falling over trips; a gap shut that is open | `test-paint-paths`, `test-buddy-paint-paths` (bumps by round, round trip) | `.buddy path` (mesh is the default) |
| Roads and crossings (176a2c) | the battleground's roads as a graph, taken in turn | a squad going back the way it came | `test-arathi-basin-rules` | the scene's settings |
| Levers and the semantic map (638) | about 1,400 small things a buddy can do with its body, grouped by meaning | a lever the game won't do; a group that mixes meanings | `test-buddy-levers`, `test-lua-unique-names` | `.lever` (game masters) |

### 3. Rules

| Capability | Claims | Wrong if | Seen in | Off |
|---|---|---|---|---|
| Profiles and their caps (155, the profile pages) | each profile's level range and rules | a setting on the wrong profile | `test-profile-config-gates`, `test-profile-tables-agree` | the profile chosen |
| The empty world and ambushes (phase 2, 3) | monsters come to the player, 120 to 160 yards out, on a random walk of seconds | spawns too near, too regular | `test-ambush`, `test-datapath-ambush` | the Lua scripts' load |
| Treasure and the economy (phase 4) | value flows back into chests | items duplicated or lost | `test-treasure` | the scripts |
| Travelers (phase 5) | strangers wander between places | travellers stuck | `test-travel` | the scripts |
| Classes, talents and quests (phase 7) | each class's custom spells, talents every third of a level | a spell unlearnable, a point lost | `test-talent-builds`, `test-spell-designs`, `test-racial-quests` | per profile |
| Progression and endgame (phase 8) | gear tiers, legendaries, world bosses | a tier skipped | `test-basic-legendaries`, `test-world-boss-countdown`, `test-gearsets` | per profile |

### 4. Minds

| Capability | Claims | Wrong if | Seen in | Off |
|---|---|---|---|---|
| Buddies' roaming and exploring (617e, 617e6) | buddies cover the owner's area, spread, without being told | bunching, standing, leaving the area | `test-buddy-roam-core`, `test-measure-buddy-spread`, `test-roam-pattern` | `.buddy explore`, the roam strategy |
| Following (617e13) | followers walk the owner's own track, side by side, resting until 10 yards off | crossing each other, lagging | `test-buddy-follow-core`, `test-measure-buddy-spread` | ordered or not |
| Ways to find a path (617o7, 617o8) | six ways; the painted map keeps space, learns, spreads, walks in arcs | wobble, rings, bumps, bunching | the six-way comparison, `test-buddy-path-ways`, `test-paint-paths` | `.buddy path <way>` |
| Parties and the dungeon draw (617c2, 617c3) | buddies group by distance; a dungeon draws a balanced party | a buddy ungrouped beside a full party; no healer | no seam test yet: seen only in game | per place |
| Gear, gems, loot and spells (617a, 617j, 617n) | buddies dress, gem and learn by their talent plan | a socket left empty, a weapon unskilled | `test-buddy-kit`, `test-buddy-gems`, `test-buddy-talents` | per command |
| Stand-ins and the army (617t, 617e17) | strangers made on demand; an army of 64 round a game master, as buddies | a stand-in masterless, or ungrouped | `test-buddy-stand-ins`, `test-buddy-made-out-of-world` | test realms only |
| Battleground squads and fronts (176a2, 629) | trios on the roads; fronts that hold lines | squads clumping; lines breaking | `test-arathi-basin-rules`, `test-battleground-front` | the scene |
| Sargobras and the narrators (E066, phase 9) | a guide who answers by whispers | a choice made differently from his menus | `test-sargobras-follow`, `test-narrators` | the patch |

### 5. Bodies

| Capability | Claims | Wrong if | Seen in | Off |
|---|---|---|---|---|
| The buddy module, C++ (B036) | the minds above, in the server | a crash, a call on a character not yet in the world | `test-buddy-made-out-of-world`, `test-patched-syntax`, the owner's compile | the module's settings |
| The bot module and its patches (mod-playerbots, B0xx) | bots that fight, loot and take orders | a buddy taking another's orders | `test-compile-module-set`, `test-source-patches` | per patch |
| Lua scripts on the game's engine (ALE, src/lua-*) | fast-changing rules without a compile | two files one name; a missing global | `test-beta-lua-load`, `test-lua-globals`, `test-lua-unique-names`, `test-ale-method-names` | the profile's Lua folder |
| Settings and install steps (C0xx, E0xx) | each profile's values and its setup | a value on the wrong profile; a step out of order | `test-profile-config-gates`, `test-patch-plan`, `test-patch-undo-order` | the patch's header |

### 6. Views

| Capability | Claims | Wrong if | Seen in | Off |
|---|---|---|---|---|
| The ground sandbox (617e16) | bots on real ground, any way, any area, measured | the page and the game disagree | the page's measures, pictures, `test-ground-decode` | (a page) |
| The battleground sandbox (617e16l) | two sides playing Arathi Basin as the bots would | squads not on the roads | its pictures | (a page) |
| Zone renders, gearset gallery, lever map | the world, the gear and the levers seen whole | a render that differs from the data | `test-render-zone`, `test-gear-designs` | (pages) |
| The live map stream (617e16a) | the real server's positions on the page | stale or wrong positions | the page's live mode | `Buddies.MapStream.Port` |
| The GM command reference | every command, its level and words | a command undescribed | `test-gm-command-reference` | (generated) |
| The board (CLAUDE.md, the design target) | where every issue stands | an issue on the wrong row | read at each compile | (generated) |
| Development history | every picture, with its story | a picture without notes | `test-file-screenshot` | (always kept) |

### 7. Operations

| Capability | Claims | Wrong if | Seen in | Off |
|---|---|---|---|---|
| Compile, update, install (the owner's) | each profile built from upstream plus our patches | a build that differs from the tree | `test-compile-ledger`, `test-watch-compile`, `test-steady-mtimes` | (the owner runs them) |
| Patch runner and plan (189) | each profile's patches, in order, from their headers | a patch on the wrong profile | `test-patch-plan`, `test-carried-files` | headers |
| MySQL, private login (188, 136) | the databases, no password on any command line | a password leaked | `test-mysql-client-options`, `test-mysql-start`, `test-basic-sql-in-ram` | (always on) |
| Realm branches (136d) | a test realm made from a living one on demand | a branch writing the source's data | `test-branch-realm` | `scripts/branch-realm --drop` |
| Many agents, one folder (CLAUDE.md) | each agent commits only its own lines; claims before editing | one agent's work in another's commit | `test-commit`, `test-line-edits`, the commit tools | (always on) |
| Tests with each commit (1100) | every commit's tests run and are remembered | a failure unseen | `test-commit`, the commit reports | `--retest` |
| The comment-free copy (190) | a copy of the project without comments, for a machine's intuition | comments leaking through | `test-make-intuition-copy` | the push hook |
| Transcripts | the whole conversation kept with the work | a commit without its story | no seam test yet: the commit hook bundles them | (always on) |
| Party checkpoint | a character saved, changed and restored comes back bit for bit | a table forgotten | `test-party-checkpoint` | (a tool) |
| A player's journal | a player's journal opens with their password and nothing else | it opens for anyone | `test-journal-seal` | (a tool) |

## Where the rings are thinnest

These are the gaps, not the strengths: where being wrong is most likely
and least seen.

- **Minds without a compile.** The path switch, the painted map in game,
  the army and stand-in grouping are written and checked offline, but no
  buddy has walked them yet. The first compile is their first real test.
- **Knowledge kept but never forgotten.** The painted map learns walls and
  keeps them. A doodad that moves, or a wall painted wrongly, stays until
  the region's file is removed. Nothing yet unlearns.
- **Pages that run their own copy.** The sandboxes run the script twin, not
  the server. The twin is held to the C++ by shared courses
  (`test-buddy-paint-paths`), but only for the parts both have.
- **Seams with no test.** The dungeon draw and party grouping are seen only
  in game; the transcripts' bundling only by its hook. A card that says "no
  seam test yet" is a place to put one.
- **Issues with no Current Behavior.** 42 open issues say nothing of where
  they stand, so the board can't place them.

## Keeping this document true

It names tests, not numbers, so it stays true while numbers move: run the
named test for the current figure. When a capability is added:
1. Give it a card in its ring.
2. Name the test at its seam, or write one.
3. Say what turns it off.

When a contract above is broken and kept broken on purpose, the contract
changes here first.
