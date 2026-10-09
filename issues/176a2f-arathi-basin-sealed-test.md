# 176a2f - Arathi Basin: the Sealed Test

## Status
- Created: 2026-10-08
- Phase: 1
- Parent: 176a2 (an Arathi Basin match)
- Blocked by: 176a2b, 176a2c, 176a2d, 176a2e
- Related: 176a (test scenes: a sealed test copy and an open cc-patch;
  run alone, then all together), 176a1 (Alterac Valley's sealed test)
- Priority: Medium

## Origin

From 176a's design (owner, 2026-10-08: test patches as sealed copies, each
run alone and validated, then all at once) and the Alterac Valley scene's
answer on what a sealed test plays: "it virtualizes the mechanism once,
to verify that bots can level up and such [...] Then, it tests the other
mechanics very quickly but controll-ed-ly, to verify that everything
works out."

## Current Behavior

Not built.

## Intended Behavior

**The sealed copy** lets no one in, starts the same way every run (the
home bases fixed, not drawn), and writes its logs to
`tmp/shared-memory/test-scenes/arathi-basin/`.

**One whole match, no shortcuts:** trios set out, tanks appear on
captures, the bases change hands, someone wins. What it must show:
- every squad's crossings follow the alternating rule (176a2c): the log
  of each crossing's pointer, replayed by the test, gives the same
  branches;
- no stand-in collects a power-up;
- every full capture is followed by exactly one tank at home (or as
  176a2b's question 1 decides), which leaves with the next trio;
- no stand-in stays off every road for long unless it is fighting or
  walking back from the river;
- squads in formation keep each member near its slot when no enemy is in
  sight (176a2d);
- the stand-ins level on their tracks afterwards (617t).

**Then each mechanism quickly, with fixed inputs:**
- the base bonuses (176a2e) against a scripted list of resource ticks
  and captures: steps grow, pause while contested, keep the count, reset
  on a full capture; checked against the worked examples;
- the river: a stand-in placed in the water walks out to the road;
- respawning: a stand-in killed at a known spot rises, waits, and leaves
  its graveyard by the next exit in turn;
- the random home base (176a2a): played with each side at each home, the
  routes and tanks start from the right place;
- many instances: two matches at once keep separate pointers, tanks and
  bonuses.

## Suggested Implementation Steps

1. The no-server checks first: the route rule (176a2c step 2) and the
   bonus arithmetic (176a2e step 1) as ordinary tests.
2. The scene's setup in the cc-test profile: a sealed match, both home
   bases fixed.
3. The logs the other sub-issues name, in one format.
4. The checks over the logs, and the quick mechanism runs.

## Open Questions

1. **How long a whole match may take:** a real match with stand-ins on
   both sides could run 20 minutes or more. Is a full match the test, or a
   match to a lower score (say 400) with everything else stock?
