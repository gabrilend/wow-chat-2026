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

## Intended Behavior

A sixth profile, `cc-test` ("custom client test"), that resolves
everywhere the others do (153a's table: source tree, installed tree, Lua
directory, the four databases, build directory, log directory, config
patch gates, source patch list, the word in `.profile`).

- **Stripped down to what is being tested.** Stock AzerothCore as close to
  upstream as the build allows: no playerbots, no ambush or traveller
  scripts, no custom items, no level-cap changes. A difference from the
  stock server shows up as a test failure, not as a mystery.
- **The server's own checks left on, at their strictest useful setting.**
  Warden on, with a failed check *kicking* the client instead of only
  being logged. The movement checks are the core's own. The custom client
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

1. (Answered 2026-10-07) **Modules:** mod-ale, yes. Test scenes can be
   written in Lua.
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
