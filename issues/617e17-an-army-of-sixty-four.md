# 617e17 - An Army of Sixty-Four

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617e (buddies in the world)
- Related: 617o7 (the five ways they test), 136d (the test realm they
  live on), the stand-ins (`buddies_stand_ins.cpp`), 617e16 (the
  sandboxes, where the white dot is the player), 1100e (the realm locked
  to game masters)
- Priority: High
- State: in progress (planning)

## Origin

The owner, 2026-10-28:

> We should have stand-in buddy-bots, say an army of 64, just for me, and
> my buddy-bots should displace some of them, so it's always a total of 64
> (for the scenario setup scene jumps we're planning for later) - anyway
> they will quest in the area that my character is in, as if they were the
> white dot. remember, random buddy-bot stand-ins. They should behave as if
> we were all in one clan, and in-fact, for these purposes, you can make it
> so. But this is for the test server probably...

## Current Behavior

A partner has their own buddies (a roster of slots); stand-ins are made
by the buddy module for scenes (`buddies_stand_ins.cpp`). Nothing makes a
fixed-size army round one player.

## Intended Behavior

- **Sixty-four, always.** On the test realm, a game master can raise an
  army of 64 round their character: their own buddies first, then random
  stand-ins (made as stand-ins are, random races, classes and looks) to
  make up 64. A buddy of theirs logging in displaces a stand-in; logging
  out, a stand-in takes its place.
- **One clan.** The army and the player are one clan (the clan the
  buddies already share; the stand-ins joined to it for the test), so
  they treat each other as clan-mates.
- **Questing round the player**, as the sandbox's bots do round the white
  dot: wandering the area the player is in, fighting what they meet, by
  whichever of the five ways (617o7) is switched on.
- **Test realm only**: the commands refuse on a realm that isn't a test
  branch (136d).

## Suggested Implementation Steps

1. `.buddies army [count]`: raise or top up to the count; `.buddies army
   dismiss`.
2. Displacement when the player's own buddies come and go.
3. The clan join for the test; refused off the test realm.
4. Tried with the owner after the compile.

## Open Questions

1. **"scenario setup scene jumps we're planning for later"**: the 64 is
   kept constant for those; should the army's makeup (which stand-ins,
   their classes) be fixed from one jump to the next, or drawn again?
