# 155z8 - Rares and Rare Elites Return as Often as Ordinary Monsters

## Status
- Created: 2026-10-22
- Phase: 1
- Parent: 155 (basic profile)
- Related: 155c (basic's world database patches), 155j (world bosses:
  their own clock, untouched)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-22:

> can we set the rare and rare elite timer to be the same timer as the
> monster spawning timer?

Then, on which clock, 2026-10-22:

> the more players are in the area, the faster they respawn. Each player
> gives a 10% boost to the respawn speed, with each 10% modifying the
> remaining percent after the last one. So 100%, 90%, 81%, 72%, 63%, I
> think, actually no that's wrong, but I'm sleepy

And on the pools (a 5-minute rare taking turns with its placeholders):
"we'll have to do the math to work through that."

The arithmetic of "each 10% off what remains": the wait is 0.9 to the
power of the number of players, so it shrinks more slowly each time (the
72 and 63 above take 9 points off each time instead of 10% of what is
left):

| Players | Wait, share of the base |
|--------:|------------------------:|
|       0 |                  100.0% |
|       1 |                   90.0% |
|       2 |                   81.0% |
|       3 |                   72.9% |
|       4 |                   65.6% |
|       5 |                   59.0% |
|      10 |                   34.9% |
|      20 |                   12.2% |

(Open question 4: does the first player already count, or is one player
the base?)

## Current Behavior

Basic has no monster spawner of its own (no ambush script); monsters come
back by the server's stock respawn: each spawn's own timer
(`creature.spawntimesecs`), and the dynamic respawn settings left at stock
(`Respawn.DynamicRateCreature = 1`).

Read 2026-10-22, spawns in the four open worlds (maps 0, 1, 530, 571), by
the creature's rank (`creature_template.rank`):

| Rank           | Spawns | Shortest | Average  | Longest   | At 5 min |
|----------------|-------:|---------:|---------:|----------:|---------:|
| ordinary (0)   | 117738 |    0 s   |    406 s | 432000 s  |    76551 |
| elite (1)      |   5998 |    0 s   |    539 s | 259200 s  |     2970 |
| rare elite (2) |    217 |  420 s   |  35586 s | 151200 s  |        0 |
| rare (4)       |    847 |  120 s   |  44630 s | 252000 s  |        9 |

So an ordinary monster mostly returns after 5 minutes, a rare after about
12 hours on average and a rare elite after about 10. 802 of the 1,064
rare and rare elite spawns sit in spawn pools, which pick one of several
spots (sometimes sharing the spot with an ordinary "placeholder" monster)
each time the pool's member respawns.

## Intended Behavior

Every rare and rare elite spawn on basic returns on the ordinary
monsters' clock (open question 1 says which), so a rare is found about as
often as the monsters around it. World bosses (rank 3, 155j) keep theirs.

## Suggested Implementation Steps

1. Answer the open questions.
2. A basic world database step (apply and revert SQL in
   `sql/basic/db_world.src/`, its install step in `patches/`, its header
   naming basic): the apply records each rare and rare elite spawn's
   timer in a table of its own, then sets the new one; the revert puts
   each back from that table.
3. The post-install checker: no rank 2 or 4 spawn on the open-world maps
   has a timer other than the chosen one.
4. A line in `docs/balance-updates.md`.

## Open Questions

1. **Which clock?** The ordinary monsters' usual 5 minutes for every rare,
   or each rare matched to the ordinary monsters around it (or to its
   pool's placeholder), where those differ from 5 minutes? **Answered
   2026-10-30:** asked with the agent's call, matched to the monsters
   around it, the owner: "this one". Each rare's respawn time is that of
   the ordinary monsters around it.
2. **Pools.** A rare in a pool with placeholders appears at one of its
   spots each time; with a 5-minute timer it can show up every few
   minutes in turn with them. Is that wanted, or should the pools be
   loosened so the rare always appears? Asked back by the owner,
   2026-10-30: "so... cycle through multiple spots? If the rare is
   already spawned, it won't spawn again until it's slain, right?" Read
   in basic's world database the same day: 135 of the 426 rares are in a
   pool, and those pools hold only the rare's own possible spots (Scale
   Belly's pool: 4 spots, at most 1 alive), not placeholder monsters. So
   yes: one rare at one of its spots, never a second while it lives;
   once slain, after its respawn time it appears again at one of its
   spots, picked at random. Kept as it is (the agent's reading, for the
   owner to correct).
3. **Instances.** Rares inside dungeons and raids too, or the open world
   only? **Answered 2026-10-30** (the owner, word for word): "rares in
   dungeons and raids should always spawn. Or rather, if there are any
   to be found in the dungeon or raid, then at least one will always
   spawn, but it's a random one each time." Each time a dungeon or raid
   instance is made, at least one of its rares is present, picked at
   random.
4. **Players in the area.** The server already has a player-count knob
   (`Respawn.DynamicRateCreature`: past a set number of players in a
   zone, waits shrink in proportion, so twice the players is half the
   wait, never under `Respawn.DynamicMinimumCreature`, 10 s). The rule
   above (0.9 per player) is gentler and needs compiled code instead.
   Which? And: "area" is the zone, or a radius around the rare? The
   first player counts (one player: 90%), or one player is the base?
   Every monster, or rares only? **Answered 2026-10-30:** "let's just
   use their system for now, we can come back to ours later." The
   server's own setting (`Respawn.DynamicRateCreature`, by players in
   the zone) for now; the 0.9-per-player rule is kept for later.
