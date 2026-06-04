# 148 - Vanilla Profile: Default WotLK + Playerbots

## Status
- Created: 2026-06-01
- Phase: 1 (Foundation — profile model)
- Priority: Medium (a clean comparison baseline; unblocks a-b testing
  of any future custom feature against an un-customized server)

## User-facing reference

[`docs/profiles/vanilla.md`](../docs/profiles/vanilla.md) is the
user-facing summary — what vanilla gives you, how to switch, what
to expect at each level. This issue captures the design rationale
and implementation history; the docs page captures what a player
or operator needs to know to use it.

## Problem

The three existing profiles (`alpha`, `release`, `beta`) all carry
project-specific customizations. There is no profile that represents
**a baseline WotLK server with AI companions and nothing else** — no
custom Lua engine, no quality-of-life module stack, no project-local
behaviors.

That baseline is useful in three ways:

1. **A/B comparison.** When a custom feature behaves strangely, being
   able to spin up the same playerbots experience without our layer
   pinpoints whether the bug lives in our code or upstream.
2. **A landing-pad for first-time visitors.** Friends curious about
   "AzerothCore with playerbots" can play the un-modded version before
   committing to the Everland Ghostsong custom ruleset.
3. **A clean recipe.** The smallest meaningful WotLK+bots configuration
   is the floor that every other profile builds on. Naming it makes
   that floor explicit.

## Canonical Definition

### `vanilla` — WotLK 3.3.5a + Playerbots, Light Ruleset

A WotLK 3.3.5a server with the playerbots fork of AzerothCore,
mod-playerbots, and a small set of quality-of-life modules. Light
ruleset customizations replace the full Everland Ghostsong rule
package with a more traditional WotLK feel.

- **AzerothCore source:** `liyunfan1223/azerothcore-wotlk` on the
  `Playerbot` branch — the same fork release/beta use, because
  mod-playerbots requires core-integrated changes that only this fork
  provides.
- **Lua engine:** `mod-ale` (added 2026-06-02 per sub-issue 148k).
  Previously vanilla shipped without a scripting layer; the
  starter-equipment auto-equip hook (148k) needs a `PLAYER_EVENT_ON_FIRST_LOGIN`
  callback to move starter kit items from the bag into equipment
  slots before the character-select screen renders. ALE is the
  smallest engine that does this. Per-profile Lua dir is
  `src/lua-vanilla/` (introduced alongside the rename of `src/lua/`
  → `src/lua-beta/`); E001 symlinks the right dir per profile.
- **Playerbots:** `mod-playerbots` (the focus of this profile).
- **Modules:** `mod-playerbots`, `mod-solo-lfg`, `mod-aoe-loot`,
  `mod-fireworks-on-level`, `mod-ale`, `mod-soren-chat`. These six
  are the agreed core set; any further additions get their own
  ticket. The sixth, `mod-soren-chat`, was added 2026-06-03 per
  issue 916 to provide LLM-driven gameplay guidance (party-level
  strategy assignment) and bot chat (race/class/spec-shaped
  dialogue). It uses the three Ollama mini-PCs on the LAN as its
  inference backend and runs entirely in-process via effil-jit
  worker threads, never blocking the worldserver tick.
- **Patches:** the minimum set needed to compile the fork (e.g.
  compile-fix patches like B009/B010 if still necessary). No project
  feature patches (no ambush spawns, no custom classes, no talent
  reshaping). The level-cap and class-availability configuration
  changes described below are config-side, not source patches.

### Ruleset customizations

A few server-side tunings define vanilla's identity beyond "stock + bots":

- **Level cap: 40.** A halfway point between classic vanilla (60) and
  WotLK (80). Compresses leveling so a player can reach endgame in a
  practical session length while still passing through most of the
  3.3.5a content meaningfully.
- **Starting level: 20.** Characters are created at level 20, not
  level 1. This skips the early-leveling content (which is well-trodden,
  faster to relearn than to grind) and drops the player straight into
  level-band-appropriate content. Combined with the 40 cap, this gives
  a focused 20→40 progression arc: roughly half the WotLK experience
  range, compressed into the sweet spot of the 3.3.5a content curve.
  Replaces the more conventional "boost the XP rate" approach (which
  vanilla does not use) with a cleaner skip-the-tutorial design.
- **Starting zones — Alliance: Duskwood (Darkshire).** Level 18–30
  zone south of Elwynn Forest. Whole zone tuned for the starting
  level band, with a clear progression path toward Stranglethorn and
  the contested 30+ zones.
- **Starting zones — Horde: Hillsbrad Foothills (Tarren Mill).** Level
  20–30 zone in central-north EK. The only true level-20 Horde zone in
  Eastern Kingdoms; geography is "central" rather than "south", but
  the level band is correct. Progression path leads to Arathi
  Highlands and onward to Stranglethorn at 30+.
- **Movement speed: 80%.** Inherited from C003 — slows the world down
  to a more deliberate pace that pairs with the starting-at-20 design
  (the world is bigger when you move slower, which matches the
  intent of dropping into a single starting zone rather than rapid
  cross-continent travel).
- **Fall damage: 10x.** Inherited from C004 — falls hurt, players
  respect terrain. Matches the deliberate movement-speed tuning.
- **GM login state: on.** Inherited from C008 — administrator
  characters log in with GM privileges enabled so testing and
  intervention are immediate.
- **Endgame dungeon target: Uldaman.** Design intent, not a hard
  configuration — Uldaman sits at the right level band for a 40-cap
  ruleset, has a memorable layout, and rewards the kind of small-party
  exploration that pairs well with playerbots. Higher dungeons remain
  reachable but are tuned implicitly out of scope by the level cap.
- **Death Knight class: disabled** (see sub-issue 148a). The DK intro
  experience starts the character at level 55 in a scripted zone that
  doesn't fit a 40-cap ruleset. Properly skipping the intro requires
  a client-side patch capability that the project doesn't yet have,
  so for now the class is turned off entirely. Re-enabling depends on
  the client-patching pipeline landing.

### Tunings deliberately NOT applied

- **2x XP rate (C005)** — replaced by the starting-at-level-20 design
  above. Skipping the early levels does the same compression more
  cleanly than scaling the XP curve.
- **Instant teleport (C009)** — beta-only convenience. Vanilla
  expects the normal travel/flight-path experience.
- **Custom max-level patches (C006a/C006b)** — vanilla gets its own
  C006c at level 40.

### How vanilla differs from the other profiles

- vs **alpha** — alpha is pinned-old-AC with the wow-chat-1 Lua corpus
  on mod-eluna and no playerbots. Vanilla is current-AC with playerbots
  and ALE (a tiny scripting surface for the 148k starter-equip hook,
  not the wow-chat design corpus).
- vs **release** — release uses mod-ale for the full wow-chat design
  layer (ambush, travel, custom classes, etc., living in
  `src/lua-beta/`). Vanilla uses the same mod-ale but with an empty
  `src/lua-vanilla/` apart from the starter-equip hook. Same engine,
  vanishingly different script payload.
- vs **beta** — beta is release plus in-flight QoL modules
  (mod-aoe-loot, mod-grownup) and experimental work. Vanilla is the
  opposite extreme: nothing extra.

The mental model: **vanilla ⊂ release ⊂ beta** (on the playerbots
fork). Each step up adds something. Vanilla is the floor.

## Current Behavior

- `scripts/profiles` knows all four profiles including vanilla; the
  display loop lists them in floor→relic→stable→bleeding order.
- `scripts/install` recognizes vanilla, clones the upstream fork into
  `source-beta/`, installs the configured module set, compiles, and
  populates `installed-files-vanilla/` with binaries and configs.
- The MySQL setup block creates the three `acore_*_vanilla` databases
  and grants `ritz` full privileges on them.
- **However:** the install does NOT seed the world / characters /
  auth databases with their base content. AC's `DatabaseLoader::Populate()`
  in `source-beta/src/server/database/Database/DatabaseLoader.cpp:138`
  is supposed to do this on first worldserver start, but the
  populate phase isn't running (or is silently no-opping) on this
  build's vanilla profile. Result: the empty `acore_world_vanilla`
  causes the worldserver's Update phase to crash on the very first
  incremental update with `Table 'acore_world_vanilla.version'
  doesn't exist` — because `version` lives in the base content
  (`source-beta/data/sql/base/db_world/version.sql`), which never
  ran. The auto-setup logic in `DBUpdater<T>::Update`'s
  `CheckUpdateTable` lambda only seeds the two tracking tables
  (`updates`, `updates_include`) — not the actual content tables.
- `installed-files-vanilla/bin/dbimport` exists but aborts on launch
  with ACE00046 (`mysql_get_client_version()` runtime/compile-time
  mismatch). The binary needs `LD_LIBRARY_PATH=${DIR}/mysql/installed-files/lib`
  to find the project's libmysqlclient — `scripts/authserver` and
  `scripts/worldserver` set this, but there is no wrapper for
  `dbimport`, so any caller hits the version check and fails.

## Intended Behavior

- Writing `vanilla` into `.profile` selects a build that compiles the
  liyunfan1223 fork on the `Playerbot` branch with only mod-playerbots
  in the module set.
- `scripts/profiles` lists vanilla alongside the other three with a
  one-line description ("Default WotLK + playerbots, no extras").
- `scripts/install --profile vanilla` clones the source, clones
  mod-playerbots into `source-beta/modules/`, compiles, and installs
  into `installed-files-vanilla/`.
- `scripts/authserver` and `scripts/worldserver` recognize the profile
  and start binaries from the vanilla install dir.
- A clean vanilla worldserver run with `.playerbots bot list` (or
  equivalent) shows playerbots functioning, with **no** ALE Lua hooks
  firing, **no** project-custom NPCs spawned, **no** project-custom
  spawn behavior.

## Source Tree Decision: Shared or Dedicated?

Two options, with the same reasoning structure as the release/beta
decision recorded in issue 136.

### Option A — Share `source-beta/` with release and beta

Vanilla compiles from `source-beta/` (the existing liyunfan1223
checkout). The module list and patch selection differ, but the source
is the same.

**Pros:** One source tree to maintain. Saves disk. Matches the
already-established pattern that release and beta share source.
**Cons:** Patch application becomes per-profile (vanilla applies
fewer patches than release, which applies fewer than beta). The patch
system already supports this via `PHASE_BEGIN_PATCHES`, so the cost
is small.

### Option B — Dedicated `source-vanilla/`

A fresh clone, never patched beyond compile-fix essentials.

**Pros:** Iron-clad guarantee that nothing from beta's experimental
patches leaks in.
**Cons:** Triples the source-tree disk usage (now four checkouts:
alpha, beta, vanilla, plus the now-unused release-only slot). Goes
against the fourth-path design from issue 136, which treats source
trees as build artifacts regenerable from the recipe.

**Recommendation: Option A.** Vanilla compiles from `source-beta/`
with a profile-specific patch subset (the minimum compile-fix set).
This stays consistent with the fourth-path design: the recipe (module
list + patch list) is what differs between profiles; the source tree
itself is a regenerable artifact.

## Modules: Playerbots + QoL + LLM Layer

The vanilla module set is intentionally small. Each module earns its
slot by being either the defining feature (playerbots), a low-risk
quality-of-life improvement that doesn't change the game's character,
or the LLM-driven companion-intelligence layer added 2026-06-03 per
issue 916.

- **mod-playerbots** — the reason this profile exists. AI companion
  characters that fill dungeon groups, run errands, fight in PvP. Also
  participates in the auction house by default (the liyunfan1223 fork
  ships with bot AH activity enabled — bots buy gear they want, post
  loot and quest rewards, undercut existing listings). Vanilla relies
  on this dynamic AH activity rather than a scripted fill module like
  mod-ah-bot; the decision is to use emergent bot behaviour over
  prefab listings.
- **mod-solo-lfg** — lets a single player queue for the dungeon finder.
  Playerbots fill the rest of the group. Without this, dungeon content
  (including the Uldaman endgame target) is effectively unreachable
  when you log in alone.
- **mod-aoe-loot** — one keypress loots every corpse in range. Cuts the
  wrist effort of post-combat cleanup, which matters more when a bot
  party leaves five corpses per pull.
- **mod-fireworks-on-level** — visual confetti on level-up. Pure
  decoration, included because it's cheap and pleasant.
- **mod-soren-chat** — LLM-driven bot intelligence layer with two
  responsibilities: (1) gameplay guidance — when a party comes within
  100 yards of a player, an Ollama-cluster consultation sets per-bot
  policy flags (which strategies to activate, what target priorities
  to apply, what positional stance to take) which mod-playerbots then
  executes via its existing strategy/trigger/action engine; (2) chat
  — bots speak in a race/class/spec-shaped voice with persistent
  per-bot personas. Reasoning that this doesn't violate vanilla's
  "no wow-chat design layer" principle: mod-soren-chat doesn't add
  content (no ambush, no custom classes, no scripted talents), it
  makes the existing companion AI smarter. Smart companions is what
  vanilla is already about; this just turns the dial up. The
  three-box Ollama cluster (192.168.1.11-13) is external
  infrastructure; the module's worldserver-side code uses effil-jit
  worker threads so the main tick never blocks on inference. See
  issue 916 for the full design and 916a-n for the implementation
  sub-issues.

**Explicitly excluded** (for reasons recorded against each so future
sessions don't re-add them by reflex):

- **mod-eluna** — vanilla uses mod-ale instead (added 2026-06-02 per
  148k for the starter-equip hook). mod-eluna stays alpha-only.
  Originally vanilla excluded mod-ale as well; that changed when the
  character-select-screen-shows-the-kit requirement surfaced. Vanilla still has minimal custom
  Lua. Adding either would reintroduce a hook surface that vanilla
  intentionally lacks.
- **mod-learn-spells** — players are meant to return to capital cities
  to train. Forced trips to trainers are part of the intended pacing.
- **mod-transmog** — cosmetic gear-appearance swapping. Out of scope
  for the light ruleset.
- **mod-grownup** — character model scaling by level. A release/beta
  feature; vanilla keeps standard model sizes.
- **mod-npc-buffer, mod-npc-services** — convenience NPCs that shortcut
  intended downtime; against the spirit of the ruleset.
- **mod-ah-bot** — scripted auction-house listings. Superseded by the
  dynamic AH participation built into mod-playerbots; the design
  preference is emergent bot economic activity over canned fill data.

Any module not in either list above gets its own ticket if it's a
candidate for inclusion.

## Files To Update

### `scripts/profiles`
Add `vanilla` to the four arrays:
- `PROFILE_REPO["vanilla"]` — `https://github.com/liyunfan1223/azerothcore-wotlk.git`
- `PROFILE_BRANCH["vanilla"]` — `Playerbot`
- `PROFILE_COMMIT["vanilla"]` — empty (track HEAD, same as release/beta)
- `PROFILE_MODULES["vanilla"]` — `mod-playerbots mod-solo-lfg mod-aoe-loot mod-fireworks-on-level mod-ale mod-soren-chat`

Update the `for p in alpha beta release; do` loop to include `vanilla`
(decide print order; suggested: `vanilla alpha release beta`, so the
list reads "floor → relic → stable → bleeding-edge").

Update `show_help` to describe vanilla in one line.

### `scripts/install`
- Add `PROFILE_MODULES["vanilla"]="mod-playerbots mod-solo-lfg mod-aoe-loot mod-fireworks-on-level mod-ale mod-soren-chat"` to the manifest.
- Add `MODULE_REPOS` entries for `mod-solo-lfg` and `mod-fireworks-on-level`
  (the playerbots, aoe-loot, and mod-ale entries already exist). The
  `mod-soren-chat` entry is added separately as part of issue 916a
  (skeleton) since the module is locally developed and its repo URL
  may be a local path during development.
- `PROFILE_COMMIT["vanilla"]` stays empty (tracks upstream HEAD,
  matching beta and release). `PROFILE_MODULE_COMMITS` carries no
  vanilla entries either — modules also track HEAD. Originally
  pinned 2026-06-02 on the rationale that vanilla should be a
  stable reference baseline; reverted later that day per user
  direction so vanilla stays current alongside beta/release. Drift
  is intentional — bug fixes and upstream improvements land
  automatically.
- Update `get_profile_paths` to map `vanilla` → `AC_CODE_DIR=source-beta`.
- Confirm `INSTALL_DIR="${DIR}/installed-files-${PROFILE}"` produces
  `installed-files-vanilla/` (it already will; no code change needed,
  just verify the directory gets created cleanly on first install).

### Config patches (`config/patches/C###-*.sh`)

Vanilla joins the existing C-patch system, which scopes each config
modification to a list of profiles via `CONFIG_PROFILES[func_name]`.
The work splits between extending existing patches to know about
vanilla, and writing new patches for vanilla-specific values.

Extend existing:
- **C001 (database connections)** — add a `vanilla` case to the
  `case "${PROFILE}"` block. Database names get the `_vanilla` suffix
  (`acore_auth_vanilla`, `acore_world_vanilla`, `acore_characters_vanilla`,
  `acore_playerbots_vanilla`). Port stays on 3307 — the same MySQL
  instance serves all suffixed databases, so coexistence with a
  running release server works without standing up a second MySQL.
- **C010 (network ports)** — add a `vanilla` case. Suggested ports
  4364 (auth) / 4464 (worldserver), continuing the C010 pattern
  (release/beta 4362/4462, alpha 4363/4463, vanilla 4364/4464).
- **C011 (realmlist setup)** — confirm it handles vanilla by reading
  the C010 port values; likely no edit needed but verify during P2.

Write new:
- **C006c (max level 40)** — sets `MaxPlayerLevel = 40` for vanilla.
  Patterned after C006a/C006b (max level 80 for alpha / 20 for
  beta+release).
- **C007c (starting level 20)** — sets `StartPlayerLevel = 20` for
  vanilla. Drops new characters straight into the level-20 starting
  zone band, skipping early-leveling content.
- **C013-vanilla-starting-zones (new)** — overrides the
  `playercreateinfo` starting location for Alliance and Horde races
  on vanilla. Alliance → Duskwood (Darkshire) coordinates; Horde →
  Hillsbrad Foothills (Tarren Mill) coordinates. Patterned as an
  SQL-side override applied at install time, similar to 148a's DK
  disablement mechanism.
- **C014-vanilla-playerbot-level-cap (new)** — sets
  `AiPlayerbot.RandomBotMinLevel = 20` and `AiPlayerbot.RandomBotMaxLevel = 40`
  in the vanilla module config. Mirrors the existing C012 pattern
  (beta/release at 1..20).

Walk-the-list result for the existing C-patches:

| Patch | Description | Vanilla? |
|-------|-------------|----------|
| C001 | Database connections | Extend with `vanilla` case |
| C002 | Directory paths | Add `vanilla` to profile list |
| C003 | Run speed 80% | Add `vanilla` to profile list (kept) |
| C004 | Fall damage 10x | Add `vanilla` to profile list (kept) |
| C005 | EXP rate 2x | Skip (replaced by starting-at-20 design) |
| C006a | Max level 80 | Skip (alpha-only) |
| C006b | Max level 20 | Skip (beta/release; vanilla uses new C006c) |
| C007a | Starting level 40 | Skip (alpha-only) |
| C007b | Starting level 1 | Skip (default; vanilla uses new C007c) |
| C008 | GM login state | Add `vanilla` to profile list (kept) |
| C009 | Instant teleport (beta) | Skip (beta-only convenience) |
| C010 | Network ports | Extend with `vanilla` case (4364/4464) |
| C011 | Realmlist setup | Verify it handles vanilla; likely just add to list |
| C012 | Playerbot level cap (1..20 for beta/release) | Skip (vanilla uses new C014) |

### Source patches (`patches/B###-*.sh`)

Vanilla applies the compile-fix subset only. Full walk:

**APPLY for vanilla (13 patches, all pure compile fixes):**
B004, B009, B010, B012, B013, B014, B015, B016, B017, B018, B019,
B021, B022.

**SKIP for vanilla (11 patches, ALE integration or wow-chat features):**
B001 (aoe-loot ALE namespace — vanilla has aoe-loot but no ALE
consumer), B002, B003, B006, B007, B011, B020, B023 (ALE engine
patches), B005 (accuracy level cap — wow-chat feature), B008
(mod-talent-bonus — vanilla has no such module), B024 (symmetric
aggro radius — gameplay change).

Update `patches/patches.sh` `PHASE_BEGIN_PATCHES["vanilla"]` to list
exactly the APPLY set above.

### `worldserver.conf` (vanilla profile copy)
The level cap and starting level are set by C006c and C007c above.
The DK class disablement is handled by 148a's SQL-side approach.
No direct worldserver.conf edit needed beyond what the C-patches do.

### `scripts/authserver`, `scripts/worldserver`, `scripts/compile`
Each of these has a profile → source-dir / install-dir mapping. Add
the `vanilla` case (pointing at `source-beta` and
`installed-files-vanilla` respectively).

### `scripts/redownload-source`
Verify it picks up the vanilla profile's module list correctly — since
vanilla shares `source-beta`, the only difference is which modules
get cloned into `source-beta/modules/` for vanilla vs release vs beta.

### `.profile` switching
Switching profiles is `echo vanilla > .profile` (the existing
mechanism — `scripts/profiles` reads `.profile` to know the active
profile, and downstream scripts read it through the same path).
The install step does NOT switch `.profile` for the user. Switching
happens manually at the moment they want to run vanilla.

### `CLAUDE.md`
Update the "Current Development State" section to mention vanilla as
the fourth profile (one-line summary; link this issue for detail).

### `issues/136-canonical-profile-definitions.md`
Add a fourth subsection ("`vanilla` — Default WotLK + Playerbots
Baseline") to keep 136 as the single canonical reference. Issue 148
remains the implementation ticket; 136 absorbs the definition.

### `docs/table-of-contents.md`
If 136 has an entry, leave a note that the canonical-profiles section
now describes four profiles, not three.

## Database Isolation Policy

Vanilla's databases are fully suffixed: `acore_auth_vanilla`,
`acore_world_vanilla`, `acore_characters_vanilla`,
`acore_playerbots_vanilla`. The MySQL instance on port 3307 (shared
with release/beta) serves all of them — coexistence is achieved by
database-name namespacing, not by running a second MySQL.

The character database is suffixed too. Future profiles with
different max/starting levels should follow the same pattern: each
profile gets its own character database, so leveling rules don't
contaminate other profiles' player state. The general principle:
**any profile with distinct rulesets warrants its own character DB**.

The C-patch system (`config/patches/C###-*.sh`) supports this
cleanly. Patches that modify only the worldserver or character
database scope themselves to specific profiles via their
`CONFIG_PROFILES` array. Patches that should not apply to vanilla
simply omit `vanilla` from their list. The system is hot-swappable
in the sense the user described: changing profiles changes which
patches run, with no cross-contamination across profile data.

### Base Content Seeding

Creating the empty databases is not enough — the world database
needs roughly 300 base SQL files (~294 MB) seeded before any
worldserver can boot against it. The files live at
`source-beta/data/sql/base/db_{auth,characters,world}/` and are
checked into the upstream AC source tree, so they're always
available right after `scripts/install` clones the source.

The seed is a per-profile-DB one-time operation. It belongs in the
install flow, not the worldserver-boot flow, because:

1. **The worldserver path is unreliable here.** AC's
   `DatabaseLoader::Populate()` is supposed to detect an empty DB
   and import the base, but its early-exit conditions (DB has any
   table → skip; `MySQLExecutable` config not resolvable → skip;
   one base file errors → silent return-false-and-continue) mean
   it can silently no-op while still letting the subsequent Update
   phase run and crash on the first missing-table reference. We
   want the seed to be a loud, traceable step.
2. **It's a slow operation that wants its own progress output.**
   The world DB alone is ~300 files. Burying it behind `worldserver`
   would make the first boot look hung; surfacing it under
   `scripts/install` puts the time cost where the user expects
   slow work.
3. **It's idempotent and cheap to re-check.** Subsequent installs
   detect a populated DB by a marker table (`account` for auth,
   `characters` for characters, `version` for world) and skip
   straight through. A user can re-run install freely.

The seed uses the project's bundled mysql client
(`mysql/installed-files/bin/mysql`) over the project's MySQL socket
(`mysql/databases/mysql.sock`), iterating each base directory's
`*.sql` files in sorted order. Failure on any file is fatal —
fall through to the user with the failing file's name and the
mysql error.

## Implementation Steps

1. Add vanilla entries to `scripts/profiles` (four arrays + display loop + help text).
2. Add vanilla entries to `scripts/install` (PROFILE_MODULES + MODULE_REPOS for new modules + get_profile_paths case). Leave PROFILE_COMMIT and PROFILE_MODULE_COMMITS empty for vanilla — it tracks upstream HEAD same as beta/release.
3. Add vanilla cases to `scripts/authserver`, `scripts/worldserver`, `scripts/compile`.
4. Extend C001 (database connections) and C010 (network ports) with vanilla cases; suffix all database names with `_vanilla`, use ports 4364/4464.
5. Add `vanilla` to the CONFIG_PROFILES of C002, C003, C004, C008, C011.
6. Write new config patches: C006c (max level 40), C007c (starting level 20), C013-starting-zones (Duskwood Alliance / Hillsbrad Horde), C014-playerbot-level-cap (1..40 for vanilla).
7. Add `PHASE_BEGIN_PATCHES["vanilla"]` listing the 13 compile-fix B-patches (B004, B009, B010, B012–B019, B021, B022).
8. Sub-issue 148a: write the DK disablement SQL (delete DK rows from `playercreateinfo`, clear DK bit on `realmlist.flag`).
9. Sub-issue 148h: write the starting-equipment SQL (per-class level-20 white kit, no head/shoulders, cape included).
10. Sub-issue 148i: write the flight-path removal SQL (clear flightmaster NPC flag, add flavor gossip).
11. Extend `scripts/install`'s MySQL setup block: after the existing `CREATE DATABASE` step, seed each of the three databases from `source-beta/data/sql/base/db_{auth,characters,world}/`. Idempotent on a marker table per DB (`account` / `characters` / `version`). See "Base Content Seeding" above for the rationale on owning this at install time rather than relying on `DatabaseLoader::Populate()`.
12. Add `scripts/dbimport` — a small wrapper that exports `LD_LIBRARY_PATH=${DIR}/mysql/installed-files/lib` and execs `${INSTALL_DIR}/bin/dbimport` for the active profile (with `--profile <name>` override consistent with `scripts/authserver` / `scripts/worldserver`). Without this wrapper, the bundled `dbimport` binary aborts on launch with ACE00046 because the system libmysqlclient (8.4.0) doesn't match what AC compiled against (9.6.0). Not in the install boot path today, but any operator reaching for `dbimport` hits the version check and fails — treating that as a blocker per the project's "warnings are errors" rule.
13. Run `scripts/install --profile vanilla` from a clean state; verify `installed-files-vanilla/` populates and binaries appear.
14. Manually switch active profile via `echo vanilla > .profile`, then boot worldserver. Confirm: level cap enforced at 40, characters start at level 20 in correct faction zones with full white-quality class-specific equipment (no helmet, no shoulders, cape present), DK class unavailable, flight masters show no taxi icon and either no gossip or flavor gossip, boats and zeppelins still work, mod-aoe-loot key works, mod-fireworks-on-level fires on ding, mod-solo-lfg accepts a solo queue, playerbots spawn and behave at the 1..40 level range, no ALE hooks fire beyond the starter-equip hook (148k) and the soren-chat hooks (916), no Everland Ghostsong custom NPCs or spawn behavior present.
15. Update issue 136 with the canonical vanilla definition; update `CLAUDE.md` profile summary.
16. Sub-issues 916a-n: implement mod-soren-chat in stages — see issue 916 for the full plan. The order recommended there lands the foundation set first (916a-c, plumbing), then the guidance layer (916d-i + 916j), then the chat layer (916k-l), with operations (916m-n) interleaved. Verification at each sub-issue checkpoint.

## Sub-Issues

- **148a — Disable Death Knights on vanilla** (config-side disablement
  now, full DK-intro-skip pending a client-patching capability).
- **148h — Class-specific starting equipment** (full level-20 white-
  quality suit per class, no helmets, no shoulderpads, capes
  included; necessary because a level-20 character starting with
  level-1 starting kit is unplayable).
- **148i — Remove all flight paths** (clear flightmaster NPC flag
  network-wide; pairs with the slow-travel and small-world design;
  boats and zeppelins remain).
- **148j — Pre-train level-≤20 abilities** (generator-driven SQL
  inserting `playercreateinfo_spell_custom` rows for every trainer
  spell a class would normally know by level 20).
- **148k — ALE auto-equip starter kit** (Lua hook on
  `PLAYER_EVENT_ON_FIRST_LOGIN` that moves 148h's starter kit from
  the bag into equipment slots so the character-select screen
  renders the character in their kit. Reason for adding mod-ale to
  the vanilla module set — see Lua engine bullet in the canonical
  definition above).

## Decisions Recorded — Sub-Issues Considered and Declined

These were scoped during initial planning but are NOT being added to
vanilla. The tickets remain on disk as a record of why each was
passed over, so future sessions don't re-propose them by reflex.

- **148b — mod-instance-reset.** Default 5-instances-per-hour cap is
  acceptable. Revisit only if play-testing produces evidence the
  cap actually blocks the loop in practice.
- **148c — mod-quest-status.** Players read quest text and use the
  in-game map. The slower exploration matches the ruleset's intent.
- **148d — mod-zone-difficulty.** Uldaman's vanilla tuning is left
  alone for now. The mechanism (zone-keyed HP/damage multipliers
  reloadable via `.reload config`) is well-understood and easy to
  layer on later if needed.
- **148e — mod-account-achievements.** Achievements are not a focus
  of this ruleset. Default per-character behavior stands.
- **148f — mod-server-auto-shutdown.** Manual restarts when needed.

## Related (not sub-issues)

- **716 — Class combination modifier system** (a patcher-style
  mechanism for enabling/disabling arbitrary race/class combinations,
  with mod-arac as the reference implementation to study). Vanilla
  is the first profile that will consume this system, but the system
  itself is cross-profile and lives in the phase-7 custom-class
  cluster. Originally tracked here as 148g; promoted 2026-06-01.
- **916 — mod-soren-chat** (LLM-driven companion intelligence layer:
  gameplay guidance + chat). The sixth vanilla module. Lands as the
  bot intelligence layer on top of mod-playerbots' tactical engine,
  using the three-box Ollama cluster on the LAN. Added 2026-06-03;
  see also the implementation sub-issues 916a-n. mod-soren-chat may
  later land on release/beta as well but vanilla is the first
  consumer per the user's design direction.

## Notes

Each candidate module that was discussed in scoping has been promoted
to a sub-issue (148b through 148f). Future module candidates should
likewise become sub-issues rather than getting tracked in this
parent's body, so they don't get lost in the prose.

## Open Questions

- Should vanilla use a dedicated `acore_*_vanilla` database namespace,
  or share with release/beta? (Recommendation above: dedicated, for
  coexistence.)
- Should the patch system have a `PHASE_BEGIN_PATCHES["vanilla"]`
  array distinct from release/beta, or is "compile-fix patches only"
  expressible as a tag/filter on the existing arrays?
- Is there value in pinning vanilla's mod-playerbots commit
  (`PROFILE_MODULE_COMMITS["vanilla:mod-playerbots"]`) so the
  baseline doesn't drift as upstream playerbots changes? Tracking
  HEAD is simpler; pinning is more "vanilla" in spirit.
