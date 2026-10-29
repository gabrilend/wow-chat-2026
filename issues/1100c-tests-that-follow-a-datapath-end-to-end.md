# 1100c - Tests That Follow a Data Path End to End

## Status
- Created: 2026-10-26
- Phase: 1
- Parent: 1100
- Related: `docs/datapaths/ambush.md`, `scripts/lib/toy-world.lua`,
  `patches/E001-lua-script-symlinks.sh`, `scripts/test-ambush`
- State: in progress (treasure and travellers not yet followed; open
  questions)

## Current Behavior

Built 2026-10-26, two tests, both quick tests:

**`scripts/test-datapath-ambush`** follows one monster's number along the
ambush's path, step by step as the datapath document numbers them:
- Step 0, the install: the folder E001 links for beta is read from E001's
  own `LUA_SRC` line, and beta's scripts are loaded from it (movement, the
  ambush, the travellers, together).
- The world database is pretend but strict: a small `creature_template`
  of one fitting monster (1531) and five decoys, each kept out by exactly
  one of the query's conditions (a vendor, lootless, a humanoid, too high,
  too low). It answers the script's actual SQL by applying each of the
  query's conditions; a condition it does not know is a failure.
- Steps 1-9: one clock at login, the question asked for the player's
  level, every monster that enters the player's queues (watched as they
  are written), the spawn on the plus sign, the chase closing in, the
  attack, the kill taking it off the count, the corpse left with no
  timers, and the clock still running.
- Checked that it fails: with `npcflag = 0` taken out of the query, the
  vendor is queued and the test fails at step 4. (At first it watched only
  the field, where one spawn per tick let the vendor wait unseen in the
  queue; the queue watch was added for that.)

**`scripts/test-datapath-installed-lua`** looks at the real installed
trees: each one's `bin/lua_scripts/custom` link must name the folder E001
would link for its profile, and that folder must exist. By default the
active profile's tree and the shadow tree (what the compile uses);
`--every-profile` checks all. Its header says `remember: no` (1100b). It
found, on its first run with `--every-profile`:
- beta's and release's links point at `src/lua`, renamed away on
  2026-06-02: those realms load none of the project's Lua until
  reinstalled;
- there is no `src/lua-release`, so a reinstall of release stops at E001.

Found while writing the ambush test: a still player's monster comes from
up to 200 yards (the plus sign: 120-160 out along one axis, up to 120 to
the side, as in wow-chat-1, "more like a plus shape but that's close
enough"), not 120-160 as `docs/datapaths/ambush.md` and
`src/lua-beta/ambush.info.md` said. The documents were corrected; the code
was not changed.

## Intended Behavior

- Each datapath document (`docs/datapaths/`) has a test that follows one
  datum through every step it names, with the database's answers
  simulated by a table that applies the real query's conditions.
- The first link, the install's folder for the server, is checked both as
  E001 means it and as it really is in the installed trees.

## Suggested Implementation Steps

1. `scripts/test-datapath-ambush` (done).
2. `scripts/test-datapath-installed-lua` (done).
3. Treasure: one item from a sale through the counter, the pool, another
   player's queue, a chest, its expiry and back to the pool, then looted
   (`docs/datapaths/treasure.md`). The script is `.disabled` (issue 200),
   so the server would not load it; the test loads it as test-treasure
   does.
4. Travellers and trainers: one trainer from its data file
   (`src/lua-beta/data/travel-trainers.lua`) to a player meeting them
   (`docs/datapaths/travellers-and-trainers.md`).

## Open Questions

- **Beta's and release's installed links are broken** (above). Reinstall
  beta? And release: should it have its own `src/lua-release`, or share
  `src/lua-beta` (the CLAUDE.md list says release shares source-beta,
  which is the C++ tree, not the Lua)?
  **2026-10-28:** release shares `src/lua-beta`, as its own page says
  (`docs/profiles/release.md`: "The full wow-chat Lua corpus
  (`src/lua-beta/`) runs on this profile"). E001 now runs for release
  and asks one function which folder a profile loads (`_e001_lua_src`:
  release, beta's; every other profile, its own); this test asks the
  same function, and its advice now says when E001 doesn't run for a
  profile at all. The installed links mend on each profile's next
  install (`scripts/install --profile beta`, `--profile release`: the
  owner's to run). Asked about release, the owner turned to alpha:
  "we should ensure that the old pinned azerothcore we have for that
  profile is fully functional, then we should bring it to compatibility
  with the current version", meaning alpha's pinned-old fork: issue 134a.
- **The plus sign's 200 yards**: keep wow-chat-1's shape, or should a
  still player's monsters also come from 120-160 (a ring)?
