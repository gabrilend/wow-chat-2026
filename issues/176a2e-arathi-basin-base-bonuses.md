# 176a2e - Arathi Basin: Base Bonuses

## Status
- Created: 2026-10-08
- Phase: 1
- Parent: 176a2 (an Arathi Basin match)
- Blocked by: 176a2a (the match)
- Related: 155u (battleground rewards), 617t (stand-ins), 176a2f (the
  arithmetic tested)
- Priority: Medium

## Origin

The owner, 2026-10-08 (whole request in 176a2): "when each base is taken
there's a ticking buff bonus that is applied - GM increases the armor
value of all units by 5% every 200 resources (I think? Could be 100
resources) that have been claimed since the base has been taken - it
resets to 0 if the enemy fully takes it. While they're partially
capturing it, the bonus is toggled off, but it doesn't reset until they
fully capture it. However, it doesn't increase either while it's under
contested control. Lumbermill has +5% damage to ranged attacks, BS to
melee attacks. Stables has +5% movement speed, and Farm has +5% health."

## Current Behavior

**2026-10-08: the rule is built and tested on paper; nothing applies it
yet** (no running scene, no auras): `src/lua-cc-test/lib/arathi-basin-
bonuses.lua` holds each base's holder, whether it is under attack, and
the resources counted since its capture; it is told of captures,
assaults, defences and resource ticks, and answers each side's bonuses
in force. `scripts/test-arathi-basin-rules` checks the owner's examples
(Blacksmith taken at 165 steps up at 265 and 365; Stables taken at 35 at
135, 235, 335), the pause under attack and the return at the same steps,
the reset on capture, nothing from an assault on a neutral base, the
ceiling of 16 steps (+80%), and the three-minute table above.

Before this, not built. Holding a base gives resources only (`BattlegroundAB`); the
power-ups lying at each base are the only buffs.

## Intended Behavior

**The five bonuses**, each for the side holding the base:

| Base | One step gives |
|---|---|
| Gold Mine | +5% armour |
| Lumber Mill | +5% damage by ranged attacks |
| Blacksmith | +5% damage by melee attacks |
| Stables | +5% movement speed |
| Farm | +5% health |

**Growing, each base on its own count** (owner, 2026-10-08: "they're
tracked separately. So if you capture the BS while you have 165
resources, then at 265 the BS bonus will increment. The Stables could
have been capped at 35 resources, which means it'll increment at 135,
then 235, etc."). From the moment a side fully captures a base, the base
counts the resources the side gains (from all its bases) while that base
is held and not contested ("every 100 "points" that are attained while
that base is operational"). Every 100 (owner: "is the max 1600? If so,
then we should do every 100 resources it gives +5%") the bonus grows a
step. A base can't pass 16 steps: a side never gains more than 1,600.

**Paused while contested.** While the enemy is capturing the base (its
banner clicked, the 60 seconds running), the bonus is switched off for
the holders, and resources gained in that time don't count toward it;
the steps it reached are kept. Defended (the banner clicked back), it
comes on again at exactly the steps it had and counts on from there.
The same holds while a base is first being taken from neutral: nothing
counts until the capture completes.

**Lost when taken.** When the enemy fully captures the base, the count
goes to zero for the old holders, and starts from zero for the new ones.

**Worked through, a step per 100.** The side's income decides the pace
of every base it holds (the stock tick table: `BG_AB_TickIntervals` and
`BG_AB_TickPoints` in `BattlegroundAB.h`):

| Bases held | Income | A step every | Steps in 3 minutes |
|---|---|---|---|
| 1 | 10 every 12 s | 2 minutes | 1 |
| 2 | 10 every 9 s | 90 seconds | 2 |
| 3 | 10 every 6 s | 1 minute | 3 |
| 4 | 10 every 3 s | 30 seconds | 6 |
| 5 | 30 every second | about 3 seconds | up to 16 (the match ends at 1,600) |

The owner's first reading ("15 times ... +75% health? That feels
wrong") counted three minutes at the five-base rate; with fewer bases
it is far slower. At +5% a step a base tops out at +80% ("enough to
quickly finish off a snowball, but also meaningful to fight over and
defend"); at +1% a step, +16% (open question 1).

## Suggested Implementation Steps

1. The rule as plain data and code, with no server: per base, the holder,
   its count, whether contested; fed the match's resource ticks and the
   bases' state changes; answering "how many steps does each side have of
   each bonus now". Tested on paper against the worked examples.
2. Hearing the match: each resource tick and each base state change
   (`BattlegroundAB::NodeOccupied`, the tick in `PostUpdateImpl`, or the
   Lua engine's battleground events, whichever carries both).
3. Applying a bonus: an aura per base per side with stacks, cast on every
   unit the bonus covers, its stacks set to the steps; removed while
   contested; cleared when taken. The auras are new spell entries, or
   existing ones scaled (open question 4).
4. Logs: each tick, each base's holder, count, steps and contested state,
   for 176a2f.

## Open Questions

1. (Answered 2026-10-08: "let's try 5%") **How much a step gives:** +5%,
   a base at most +80%.
2. (Answered 2026-10-08) **Whose resources:** the side's whole income,
   counted per base from that base's own capture, only while it is held
   and uncontested.
3. (Answered 2026-10-08) **A ceiling:** none beyond the match's own: 16
   steps.
4. (Answered 2026-10-08, "yep") **Who gets it:** every unit on the
   holding side, anywhere on the map: players, stand-ins, buddies, pets.
   Still open: the aura, a new spell per bonus (the stock client can't
   describe it in its tooltip; the custom client can), or an existing
   spell with a similar effect?
5. **"Partially capturing":** does the pause start at the click on the
   banner (the stock "assaulted" state), or only while an enemy stands
   at it?
