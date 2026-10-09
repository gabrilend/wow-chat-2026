# 176a2 - Test Scene: an Arathi Basin Match

## Status
- Created: 2026-10-08
- Phase: 1
- Parent: 176a (test scenes)
- Blocked by: 176 (the cc-test profile), 176a (the scene format and the
  runner)
- Related: 176a1 (Alterac Valley: the stand-in rules this one borrows),
  617t (stand-ins), 619 (combat footwork), 617i (buddies in
  battlegrounds), 155u (battleground rewards)
- Sub-issues: 176a2a to 176a2f (below)
- Priority: Medium (after 176a1, whose stand-in machinery it reuses)

## Origin

The owner, 2026-10-08:

> Can we make plans for the Arathi Basin test profile now? I'm thinking
> it should go like this:
>
> we should have stand-ins spawn in groups of three, two dps and one
> healer. They should alternatingly travel down each path intersection to
> reach the enemy base - it works like a flow chart where you reverse the
> path each time you cross it. They should be able to claim bases, and
> when they respawn they should know how to leave the graveyard and travel
> one way or the other. Whenever a friendly base is taken, a tank
> character spawns at your base and waits for the next group before
> advancing. The stand-ins don't use the powerups. They just fight enemy
> units and attempt to cap bases. They can go along the side paths between
> BS and GM, and BS and LM, but not the secret water path unless they are
> knocked off by like, cyclone or something. Stand-ins should be able to
> "group up" when there's nobody around and travel in a formation -
> either two in front with the healer behind, or two to the sides and the
> tank in front with the healer behind. So, triangle or diamond shape.
> Also, when each base is taken there's a ticking buff bonus that is
> applied - GM increases the armor value of all units by 5% every 200
> resources (I think? Could be 100 resources) that have been claimed since
> the base has been taken - it resets to 0 if the enemy fully takes it.
> While they're partially capturing it, the bonus is toggled off, but it
> doesn't reset until they fully capture it. However, it doesn't increase
> either while it's under contested control. Lumbermill has +5% damage to
> ranged attacks, BS to melee attacks. Stables has +5% movement speed, and
> Farm has +5% health. But, we should make the horde and alliance spawn at
> a random side each time. Most of the stand-in rules can be applied from
> Alterac Valley, so look there for inspiration. There's no interim
> period. Well, an interim of 1 minute maybe. There can be multiple
> instances up at once though. But the match starts as soon as a single
> person queues. Any questions? Can you make the entire planning documents
> for this feature?

## Current Behavior

**2026-10-08: every rule is built and tested as plain Lua; nothing runs in
game yet.** `src/lua-cc-test/lib/arathi-basin-*.lua` (routes, crossings,
squads, formations, bonuses, the match), 64 checks in
`scripts/test-arathi-basin-rules`, all passing under every reading of
every open question. Each open question is built two or more ways behind
a switch; `scripts/compare-arathi-basin-variants` plays the same
scenarios under each, and the report for the owner's client presents
them with a suggested answer each:
https://claude.ai/artifact/BRN1s6jpZj49ei8fQM4kJQ (private until shared).
Waiting on: the cc-test server build (176), stand-ins (617t), the scene
runner (176a), the client's input queues (W client 109).

Before this, not built. On every profile Arathi Basin is the stock battleground: it
opens when enough players queue at a battlemaster (155u), 15 a side, the
Alliance always at Trollbane Hall in the north-west and the Horde at the
Defiler's Den in the south-east. Holding bases earns resources (one base:
10 every 12 seconds; two: 10 every 9; three: 10 every 6; four: 10 every
3; five: 30 every second; the first side to 1,600 wins;
`BattlegroundAB.h`). A banner clicked starts a capture that completes 60
seconds later unless the other side clicks it back. Each base has
power-ups (speed, restoration, berserking) that respawn.

The bot module plays its bots in Arathi Basin with its own tactics
(`BattleGroundTactics.cpp` in mod-playerbots), walking 15 hand-placed
road paths: each home base to the Stables or Farm, the Gold Mine and the
Lumber Mill; the Stables and Farm to the Blacksmith, Gold Mine and Lumber
Mill and to each other; the Blacksmith to the Lumber Mill and Gold Mine.
The river path is not among them. Stand-ins don't exist yet (617t), and
the Alterac Valley scene that first uses them is planned, not built
(176a1).

## Intended Behavior

A fresh Arathi Basin match, started the moment one person queues, fought
by trios of stand-ins that spread over the map by a fixed rule, claim
bases, and are joined by a tank for every base their side takes. Each
base held grows a bonus for its side the longer it is held. The parts:

- **The match** (176a2a): starts on the first queue; several can run at
  once; Horde and Alliance take a random home base each match; one minute
  between matches; the Alterac Valley scene's rules for stand-ins and
  players (176a1).
- **Squads** (176a2b): stand-ins come in threes (two damage, one healer);
  a tank appears at home for each base taken and goes out with the next
  trio; no power-ups; they fight and capture.
- **Routes** (176a2c): the roads as a flow chart; at each crossing a side
  sends its next squad down the branch the last one didn't take; out of a
  graveyard the same way; side roads yes, the river no (except to climb
  out of it).
- **Formations** (176a2d): with no enemy near, a squad walks as a
  triangle (two ahead, the healer behind) or, with a tank, a diamond (the
  tank ahead, two at the sides, the healer behind).
- **Base bonuses** (176a2e): each base held grows a +5% bonus for its
  side, one step per so many resources gained; paused while the base is
  being taken, lost when it is taken.
- **The sealed test** (176a2f): what the scene's test copy plays and
  checks, as 176a1's does.

## Sub-issues

| ID | Name | Dependencies | Description |
|---|---|---|---|
| 176a2a | arathi-basin-match-lifecycle | None | The match's life: first queue starts it, many instances, random home bases, one-minute interim, tiers, side sizes, players and stand-ins as in Alterac Valley |
| 176a2b | arathi-basin-stand-in-squads | 176a2a | Trios of two damage and a healer; a tank per base taken, waiting at home for the next trio; no power-ups; fight and capture; what a squad does when it respawns |
| 176a2c | arathi-basin-flow-chart-routes | 176a2b | The road graph from the bot module's 15 paths; the alternating rule at each crossing, per side; graveyard exits; the river kept out, and the way back from it |
| 176a2d | arathi-basin-squad-formations | 176a2b | Triangle and diamond when no enemy is near; breaking into the fight (619's footwork) and closing up again |
| 176a2e | arathi-basin-base-bonuses | 176a2a | The five bases' growing bonuses: armour, ranged damage, melee damage, movement speed, health; paused while contested, reset when taken |
| 176a2f | arathi-basin-sealed-test | 176a2b, 176a2c, 176a2d, 176a2e | The scene's sealed copy: one full match, then each mechanism quickly with fixed inputs; the logs and what they must show |

**Why split:** the match's life, the squads, their roads, their walking
shape and the base bonuses are five mechanisms that can each be built,
tested and read alone: the bonuses are pure arithmetic over the match's
resource ticks and need no stand-in at all; the routes are a rule over a
graph that can be run on paper before a single bot walks it; formations
are movement, shared with buddies (619). One issue would hold five
designs and their questions tangled together.

**Execution order:**

```
176a2a (the match)  ──┬──> 176a2b (squads) ──┬──> 176a2c (routes)     ──┐
                      │                      └──> 176a2d (formations) ──┤
                      └──> 176a2e (base bonuses, parallel with b-d) ────┴──> 176a2f (sealed test)
```

## Suggested Implementation Steps

1. Answer the open questions below and in each sub-issue.
2. 176a2a, then 176a2e alongside 176a2b.
3. 176a2c and 176a2d once squads exist.
4. 176a2f last.

## Open Questions

The ones that shape more than one sub-issue; each sub-issue lists its
own.

1. (Answered 2026-10-08) **How many stand-ins a side?** "as many slots
   for stand-ins as there are players": a side's places are shared, and
   each player joining takes a stand-in's place, the next one to reach a
   graveyard (176a2a). Whether the places number 15, the stock side, is
   176a2a's question 5.
2. **Tiers:** a match per ten-level tier, as Alterac Valley (176a1: the 20
   tier takes 11 to 20)? Stock Arathi Basin opens at level 20.
3. **The playerbots module's own Arathi Basin tactics:** stand-ins are
   played by it, and it already decides where its bots go in Arathi
   Basin. The flow chart, the tank's wait and the formations replace that
   for stand-ins. Is that a patch to the bot module (its battleground
   tactics), or a strategy the buddy module teaches it (as it taught it
   "buddy roam", 617e)?
