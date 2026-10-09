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

Not built. Holding a base gives resources only (`BattlegroundAB`); the
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

**Growing.** From the moment a side fully captures a base, the base
counts the resources that side gains. Every N of them (N is 200 or 100,
open question 1) the base's bonus grows one step.

**Paused while contested.** While the enemy is capturing the base (its
banner clicked, the 60 seconds running), the bonus is switched off for
the holders and doesn't grow; the count it reached is kept. Defended (the
banner clicked back), it comes on again at the steps it had and goes on
growing.

**Lost when taken.** When the enemy fully captures the base, the count
goes to zero for the old holders, and starts from zero for the new ones.

**Worked through, N = 200, one base held.** Holding one base gives 10
resources every 12 seconds, so 200 resources take 4 minutes: +5% after
4 minutes, +10% after 8. Holding three bases, the side gains 10 every 6
seconds, so each base held grows a step every 2 minutes. Holding all
five, 30 a second: a step every 7 seconds. (The stock tick table:
`BG_AB_TickIntervals` and `BG_AB_TickPoints` in `BattlegroundAB.h`.)

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

1. **The step: every 200 resources, or every 100?** At 100, holding three
   bases gives a step every minute, and a side holding all five could
   stack quickly.
2. **Whose resources:** the side's whole gain since the capture (every
   base it holds feeds every bonus, as the worked example assumes), or only
   what that one base produces (each base growing at its own pace)?
3. **A ceiling?** A long match could stack the bonus high: by 1,600
   resources, a base held from the start would be at 8 steps (+40%) with
   N = 200, or 16 steps (+80%) with N = 100. Is there a cap?
4. **Who gets it:** every unit on the holding side (players, stand-ins,
   buddies, their pets), anywhere on the map? And the aura: a new spell
   per bonus, which the stock client can't describe in its tooltip (the
   custom client can), or an existing spell with a similar effect?
5. **"Partially capturing":** does the pause start at the click on the
   banner (the stock "assaulted" state), or only while an enemy stands
   at it?
