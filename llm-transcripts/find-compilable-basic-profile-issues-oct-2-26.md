# Conversation Summary: agent-a6ebad95fd13ac5a3

Generated on: 2026-10-02 13:43:15
Models: claude-opus-5-5

--------------------------------------------------------------------------------

### User Request 1

Project: /mnt/mtwo/games/azeroth-core/wow-chat-2026 (a WoW 3.3.5a AzerothCore
private server with several "profiles"; the active one is "basic", levels 1-60).
Open issue files live in issues/ (top level only; issues/completed/ is done
work). C++ source changes are made via patches/B*.sh scripts applied to
source-beta/ at build time; config changes via config/patches/C*.sh; Lua via
src/lua-basic/ or src/lua-beta/.

Task (very thorough): list every OPEN issue in issues/ that (a) applies to the
basic profile (155* sub-issues, 617* buddy issues, 700s custom-class issues, or
anything whose text names basic), (b) needs C++ compilation to implement or to
finish — i.e. its implementation requires a new or changed B-patch / source
change, or it is built-but-not-compiled waiting on a build, and (c) is NOT
about: the RGPL, the model/gear design pipeline (gear gallery, ComfyUI, image
generation, m2/gltf conversion, art), or the custom client.

For each candidate, read its Current Behavior and Suggested Implementation
sections and report:
- filename
- one-sentence plain-English description of what the player would experience
- status: not started / partially built / built and waiting for compile/test
- whether it needs NEW C++ work, or only a compile of already-written patches
- blockers (other issues it depends on, unanswered open questions)
- rough size (small / medium / large)

Also separately note any issues whose patches were written AFTER 2026-09-30
00:05 (the last basic install) and so are not in the current build — check git
log dates on patches/ files they reference.

Sort the final list by how close each is to being playable (closest first). Do
not modify any files.

--------------------------------------------------------------------------------

### Assistant Response 1

> Now read the remaining 155 Current Behavior sections.

I've sent the full report back. Here's what it found.

**The issue files are out of date.** Many say "built, not yet compiled", but
most of that C++ is already in the 09-30 basic build. I checked this by
searching the installed `worldserver` binary for strings and function names that
only the new code contains.

Sorted from closest to playable:

1. **Compiled, only needs a server start and an in-game test (about 26
   issues).**
   - Profile rules: 155d, 155e, 155g, 155i, 155j's respawn countdown, 155o,
     155p, 155r, 155x.
   - Server patches: 803 (B005/B031), 163 (B039/B043), 164 (B040/B041).
   - Buddy work: 617a1–a4, 617b1, 617c1, 617c2, 617c4, 617e1/e2/e4/e6, the
     monster part of 617e3, and 617l's clan lock.
2. **C++ written but newer than the build; needs only a compile.**
   - 617d: quests are completed for buddies when you turn them in, and rewards
     that don't fit are mailed.
   - 617c3: buddies are drawn into dungeons.
   - 617i: buddies join battleground queues with you.
   - 617h: buddies sell at the auction house.
   - 617k: buddies' main professions, and death knights' professions starting at
     Artisan.
3. **Partly built; the rest needs new C++.** 155j's Fel Reaver boss,
   contribution score and loot draw (large, 3 unanswered questions). Also the
   remaining parts of 617h, 617i arenas, 617k crafting, and an optional startup
   check of ID counters in 163.
4. **Not started; needs new C++.**
   - 617e3: chests and gathering nodes (small–medium).
   - 617a5: hide buddies from /who and friends (small–medium).
   - 617j: loot rolls (medium).
   - 155t: one small B-patch, but the owner said plan it, don't build it yet.
   - 710: custom-class resource pools (medium; needs a client-side test and a
     port of the custom-class code).
   - 617e5/617e5a: the "kraken" dungeon tactic (large; the owner deferred it).
   - 617m: craft-on-request hunts (large; blocked on 917).

**Changes written after the 09-30 00:05 install:**
- **No `patches/B*.sh` file is newer than the install.** The last one, B043, was
  committed 09-29 22:44.
- **The buddy module's source is newer, though.** Eight commits to
  `modules/mod-buddies/src/` aren't in the build (bb5ad72 through 96ecb83); they
  are the group 2 work.
- **The real cutoff is about 23:44 on 09-29, not 00:05.** That's when the build
  copied the module and started compiling. So two commits older than 00:05 also
  missed it: the quest mirroring at 23:45 and the dungeon draw at 23:48.

I couldn't tell whether the server has run since the install, because its log
folder (under `/tmp`) is gone. No files were changed.

--------------------------------------------------------------------------------

