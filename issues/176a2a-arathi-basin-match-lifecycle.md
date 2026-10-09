# 176a2a - Arathi Basin: the Match's Life

## Status
- Created: 2026-10-08
- Phase: 1
- Parent: 176a2 (an Arathi Basin match)
- Blocked by: 176 (the cc-test profile)
- Related: 176a1 (Alterac Valley's match life, players and stand-ins),
  155u (queueing at battlemasters), 617i (buddies queueing with their
  owner)
- Priority: Medium

## Origin

The owner, 2026-10-08 (whole request in 176a2): "we should make the horde
and alliance spawn at a random side each time. Most of the stand-in rules
can be applied from Alterac Valley, so look there for inspiration.
There's no interim period. Well, an interim of 1 minute maybe. There can
be multiple instances up at once though. But the match starts as soon as
a single person queues."

## Current Behavior

Not built. A stock Arathi Basin match opens only when both sides have
enough players queued, at most 15 a side; the Alliance always starts at
Trollbane Hall (north-west, near the Stables) and the Horde at the
Defiler's Den (south-east, near the Farm). When a side reaches 1,600
resources the match ends, everyone is sent out, and the instance closes.

## Intended Behavior

- **One person starts it.** The first player to queue gets a match at
  once: stand-ins fill both sides, so nobody waits for an opponent.
- **Many at once.** Each first queue that finds no match with room opens
  a new instance; several run side by side, each its own copy of the map.
- **Home bases at random.** Each match decides by a coin which side
  starts at Trollbane Hall and which at the Defiler's Den. Everything
  that names a home base (spawn, home graveyard, where tanks appear,
  where routes begin, 176a2b and 176a2c) reads it from the match, never
  from the faction.
- **Stand-ins and players as in Alterac Valley** (176a1): stand-ins are
  character records (level, attributes, spec) played by the playerbots
  module; players join on top of the stand-ins; past a number of players
  stand-ins give way; a player may take over a stand-in already fighting;
  stand-ins level on their tracks after the match (617t); shirts by
  climate (Arathi Highlands: normal, shirt as it is).
- **Stand-in slots and players** (owner, 2026-10-08: "as many slots for
  stand-ins as there are players. When a player joins, then the next
  stand-in to enter a graveyard is removed from the battle untill someone
  leaves. Alternatively, if someone is already at a graveyard, their soul
  can be temporarily shredded until they can have space to spawn in."): a
  side has a fixed number of places. Stand-ins fill those players don't.
  A player joining takes a stand-in's place: the next stand-in of that
  side to die stays in the pool (stand-ins go to a pool when they die,
  not to a graveyard: 176a2b), until a player leaves and a place opens.
- **Win and restart.** The stock win (1,600 resources). Then one minute
  ("an interim of 1 minute maybe"), then a fresh match in the same
  instance: every base neutral, scores at zero, sides drawn again.

## Suggested Implementation Steps

1. Read how the core opens and closes a battleground instance
   (`BattlegroundMgr`, `BattlegroundQueue`) and where "enough players"
   is decided.
2. Open a match for one queued player, filled with stand-ins.
3. The random home base: swap the two sides' start positions, home
   graveyards and the banner the home base flies, per match.
4. The one-minute interim and the restart in place, shared with Alterac
   Valley's turn (176a1, open question 11 there: how a battleground ends).
5. Players on top, stand-ins giving way, taking over a stand-in, from
   176a1's machinery.

## Open Questions

1. **The interim:** during the minute, where are the players? Kept in the
   instance (as in Alterac Valley's town time), or sent out and invited
   back?
2. **The random side and the client:** the stock client shows the map with
   each faction's home marked by its faction. Is it acceptable that the
   map's marks say one thing and the match another, or should the custom
   client draw the home bases from the match?
3. **More than one person queueing:** does a second player join the first
   one's match (on their faction's side) while it has room, or always get
   a new one?
4. **Ending the stock battleground:** as Alterac Valley's question 11:
   the restart in place changes how the server ends a battleground. The
   owner, 2026-10-08, for Alterac Valley: "unclear. will assess
   momentarily."
5. **How many places a side:** "as many slots for stand-ins as there are
   players" reads as the stock side size, 15, shared by players and
   stand-ins. Is that it?
