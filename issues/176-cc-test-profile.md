# 176 - The cc-test Profile

## Status
- Created: 2026-10-07
- Phase: 1
- Related: 173 (the custom client), 173e (what the server checks),
  173v (moving the client to its own project), 136 (canonical profile
  definitions), 153a (explore profile plumbing: the last time a profile
  was added, and the checklist of places a profile name must resolve)
- Priority: High (the custom client's networking is tested against it)

## Origin

The owner, 2026-10-07, asked whether the generated creature list (the
custom client's stand-in for the network, 173t) should move with the
client:

> let's just build in networking. I think we should create a new .profile
> for this project called "cc-test" for custom-client-test. It should have
> most things stripped out except what we're testing, and we can have some
> patches be tests. I think we might need to refactor the patching system
> too by the way, but we can come back to that later.

## Current Behavior

There is no server for the custom client to talk to that is built for
testing it. The profiles that exist (basic, vanilla, beta, release, alpha)
each carry the whole game's customisations: playerbots, ambushes,
travellers, buddies, level caps, custom items. Any of them would answer
the custom client, but a failure could come from any of those layers. The
custom client has no network code yet. Its world comes from a file
generated out of a world database (`scripts/generate-custom-client-creatures`).

**2026-10-08: registered everywhere a profile name resolves; not yet
built or installed** (the owner runs the build). The table below is what
each place resolves to. Checked without a server or a build:

- `scripts/test-profile-config-gates <project> cc-test`: 19 of 19 values
  as promised (stock level cap, speed and fall damage; realm 6; GM level
  0; Warden failures logged; no random bots; the buddy settings). basic
  still passes all of its own.
- `scripts/test-compile-module-set`: cc-test builds mod-ale, mod-buddies
  and mod-playerbots; basic, beta and vanilla build exactly their own sets.
- `scripts/test-source-patches` on a clean copy of the pinned source (built
  from git, not the working tree): cc-test's 24 patches apply and revert to
  a byte-identical tree; basic's 39 too.
- `scripts/test-patched-syntax` on the same copy: every file cc-test's
  patches change compiles, and now also every file of the buddy module
  (the check used to skip a whole folder a patch adds).

**The buddy module is in** (owner, 2026-10-08, asked whether stand-ins
need it: "cc-test should include it."). It makes the stand-ins of the
Alterac Valley scene (176a1) the way it makes buddies (617t). It brings
two core patches it can't compile without (B044, the list of companion
accounts; B047, creature outfits), the patches that act only on buddies
(B037, B042, B045, B046, B048, B050), its data (roster and clan tables,
area centres, beds and boardings, town circles, gearsets), read from
basic's SQL sources so the two profiles never drift (`_buddy_sql_src` in
`patches/E-patches.sh`), and basic's three buddy settings (C027, C029,
C030). Left out: the buddy selector NPCs (placed in basic's starting
valleys), the baked town grids (towns are measured live), the level-20
kit change to items, and every change to the stock world.

Two things found and fixed on the way, both affecting every profile:

- **Other profiles' modules were built in.** The source tree is shared and
  only `scripts/install` removes modules a profile doesn't list;
  `scripts/update` and `scripts/compile` built whatever module folders
  were there. A cc-test build would have linked basic's mod-aoe-loot,
  mod-solo-lfg, mod-fireworks-on-level and a copied-in mod-buddies. Now
  `scripts/compile` sets each module folder on or off for the profile
  being built (its module list, plus mod-buddies where the buddy-module
  patch B036 is in its list), and reconfigures when the set differs from
  the last build's. basic's own set is unchanged, so basic does not
  reconfigure.
- **B002's revert left a file behind** (`mod-playerbots.cmake`, which it
  writes), so the tree never returned to upstream; earlier dry runs passed
  because they copied a tree that already held it. The revert now removes
  the file when it carries B002's header.

Not done, for the owner: the first `scripts/install` with `.profile` set
to `cc-test` (clone, build, databases). Install removes from the shared
source tree every module cc-test doesn't list (basic's three extra
modules); basic's next `scripts/update` clones them back.

## What the name resolves to

| What | cc-test | Why |
|---|---|---|
| source tree | `source-beta` | shared with basic, vanilla, beta, release: same schema, one compile target |
| installed tree | `installed-files-cc-test/` | every profile has its own |
| build directory | `build-shadow/` | shared by every profile (`scripts/compile`); the patches are applied to the source before each build, and the module set is switched per profile (below) |
| Lua directory | `src/lua-cc-test/` | its own, holding only a README until the first scene; E001 stops if a profile has none |
| databases | `acore_auth` (shared), `acore_world_cc_test`, `acore_characters_cc_test`, `acore_playerbots_cc_test` | test characters made and wiped without touching anyone's play; underscores, because a hyphen is not allowed in an unquoted database name |
| logs | `logs-cc-test` → `/tmp/wow-chat-2/logs-cc-test` | as every profile (E004) |
| ports | auth 4362, world 4462 | shared with basic, vanilla, beta, release: one of them runs at a time, and the realm list shows which (136a); open question 4 |
| realm id | 6 | the next free row in the shared realm list (C019 and `scripts/set-active-realm`, a pair) |
| modules | mod-playerbots, mod-ale (cloned); mod-buddies (copied in by B036) | pinned exactly as basic's (the shared tree must pin identically) |
| source patches | B002 B004 B009 B012 B013 B014 B015 B017 B018 B020 B021 B022 B023 B026 B027 B036 B037 B042 B044 B045 B046 B047 B048 B050 | compile and warning fixes, ALE stability (B020, B023), the bot-login crash guards (B026, B027), runtime config folder (B022), bots firing ALE's login event (B002); the buddy module and what it needs (above). Left out: B001 (mod-aoe-loot, not loaded), every gameplay patch |
| install steps | E001 E004 E006 E042 E044 E045 E050 E052 | the Lua link, the log folder, the config files; the buddy module's data (above) |
| config patches | the all-profile ones except run speed (C003, now gated away from cc-test), plus C016 (missing keys), C023 (no random bots), C027 C029 C030 (the buddy settings), C033 (Warden) | stock values everywhere else |
| GM on login | 0 (player) | a test character sees what a player sees and meets every check a player meets |
| `.profile` | `cc-test` | the one word |

Random bots are off (C023) because a scene places the bots it needs; a
random population would walk into scenes and change their logs.

Warden (C033): failures are logged only (`Warden.ClientCheckFailAction
= 0`) until the custom client answers Warden's checks; then C033's value
becomes 1 and a failed check kicks. The log meanwhile lists what the client
still gets wrong. A client that never answers at all is still dropped after
`Warden.ClientResponseDelay` (600 seconds), in any profile.

## Intended Behavior

A sixth profile, `cc-test` ("custom client test"), that resolves
everywhere the others do (153a's table: source tree, installed tree, Lua
directory, the four databases, build directory, log directory, config
patch gates, source patch list, the word in `.profile`).

- **Stripped down to what is being tested.** Stock AzerothCore as close to
  upstream as the build allows, plus the playerbots module: no ambush or
  traveller scripts, no custom items, no level-cap changes. Playerbots
  are in because scenes need characters the server plays (the owner,
  2026-10-08, on "the cc-test plan says that profile has no playerbots":
  "let's change that."), first the stand-ins of the Alterac Valley scene
  (176a1).
- **Failures are found by running scenes one at a time.** The owner,
  2026-10-08: "we should always run each test individually, validate
  that it performed correctly, then run the next. Then, at the end, we
  run them all at once. If that suite passes, then the mechanisms can be
  assured to be functional properly." So a failure points at the custom
  client or at one scene, because each scene has passed alone before the
  combined run.
- **The server's own checks left on, at their strictest useful setting.**
  Warden on, with a failed check *kicking* the client instead of only
  being logged, once the client can answer Warden (until then, logged
  only: question 5). The movement checks are the core's own. The custom client
  passes when a session leaves the server's logs empty (173e's pass mark).
- **Some patches are tests.** A config or install patch gated to cc-test
  can set up a known situation (a test account, a night elf standing in
  Astranaar, a creature at a known spot) or turn a check up. Each such
  patch says what it tests at its top, the way every patch says what it
  changes.
- **Its own databases,** so tests can create and wipe characters without
  touching anyone's play.

## Suggested Implementation Steps

1. Read 136 (the canonical profile list) and 153a (the last profile
   added), and list every place a profile name must resolve.
2. Add `cc-test` to each: the source tree (`source-beta`), the installed
   tree `installed-files-cc-test/`, an empty `src/lua-cc-test/`, its four
   databases, its build and log directories, and its patch list in
   `patches/patches.sh`, as short as the build allows.
3. Gate the config patches: list which `config/patches/C*.sh` should
   *not* run for cc-test (most), and which test settings it needs (Warden
   kicks on failure). Add each test setting as its own patch with the
   test it serves written at its top.
4. A setup patch that creates the test account and character.
5. A check that the installed cc-test server matches upstream except for
   the listed patches (the patch system already round-trips the source to
   upstream; this lists what remains different).
6. Document the profile in `docs/profiles/cc-test.md` and add it to the
   table of contents. Add it to CLAUDE.md's profile list.

## Open Questions

1. (Answered 2026-10-07, extended 2026-10-08) **Modules:** mod-ale, yes.
   Test scenes can be written in Lua. Playerbots, yes (2026-10-08), for
   the characters scenes need the server to play.
2. (Answered 2026-10-07) **The patching system's refactor** is for tests:
   "I'm thinking we could add a patch that runs a test by setting up a
   particular scene. Each one could be in a different location so they
   don't interfere, and then with a cc-test build they could all be tested
   at once, to catch regressions." So a test patch sets up one scene (its
   creatures, objects, a character's starting spot) in a place of its
   own. A cc-test build installs every scene, and one run checks them all.
   This is its own issue: 176a (test scenes), which also holds the
   queued inputs and test characters that drive a scene.
   - (Answered 2026-10-07) How a scene's result is read: "each character
     would create log files, as specified in the 'test patch'. These are
     saved to RAM and evaluated by a traditional testing suite, to ensure
     that they produce correct results. Any discrepancies can be picked up
     by an LLM agent and evaluated, to see if some unrelated change is
     causing them, if that result is desired, and if so, to update the
     test to expect the newly provided result." So a test patch names what
     each character in its scene writes down. The logs go to RAM
     (`tmp/shared-memory/`), and ordinary test code compares them with
     what is expected. A difference goes to an agent, which judges whether
     an unrelated change caused it and whether the new result is wanted,
     and if so updates what the test expects.
   - Pictures too: "we should be able to 'headlessly' generate pictures
     of scenes, so we can create hundreds of these pictures at once for
     testing purposes." The client draws a scene to a picture file with
     no window, so many scenes can be photographed in one run and
     compared with stored references. This belongs to the client (173v,
     after the move).
3. (Answered 2026-10-07) **Where the client's networking is built:** in
   the W client, after the move: "let's focus on moving over to to the W
   client." The cc-test server stays in this project.
4. (Answered 2026-10-08) **Ports: shared, or its own?** Shared. A pair of
   its own would mean two servers at once: "would that be two servers at
   once? My computer can only handle one. We will need that eventually,
   but sharded onto different servers." So cc-test runs instead of basic.
   Running several profiles at once waits for servers on separate
   machines.
5. (Answered 2026-10-08) **The custom client and Warden:** "only log
   failures until we can answer." C033 writes 0 (log only) now and 1
   (kick) once the client's Warden replies exist.
6. (Answered 2026-10-08) **Stand-ins and the buddy module:** "cc-test
   should include it." (Above, "The buddy module is in".)
