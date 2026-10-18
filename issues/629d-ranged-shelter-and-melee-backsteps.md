# 629d - Ranged Shelter and Melee Backsteps

## Status
- Created: 2026-10-17
- Phase: 6
- Parent: 629 (battleground fronts)
- Blocked by: 629c (the line)
- Related: 619 (combat footwork: the pack retreat, giving ground
  together), 617s5 (sidesteps in a fight), 611 (ranged bots back up)
- Priority: Medium

## Origin

See 629 (the owner's words, 2026-10-17, quoted in full there): "When
ranged units were struck, they'd put a melee character between
themselves and their foe, close enough that they can still use ranged
attacks on them... but ideally with enough distance to defeat their
foe." / "Melee units don't run, they back up and recede when need is
[great/grand]. but only backsteps, meaning they go slow."

## Current Behavior

**On paper, 2026-10-17** (homework branch): `Front.shelter_spot` and the
backstep rule in `Front.tick` (`src/lua-basic/lib/battleground-front.lua`),
checked by `scripts/test-battleground-front` (the spot lies behind the
ally on the foe's line, inside casting reach; no melee bot on the line
ever gives ground faster than a backstep, which also caps any ground
given while closing on a foe that got past). "Need is great" is set to
health under 30% or 2 more foes than allies within 10 yards (question 1);
at that setting backsteps are frequent in the paper matches. Not in the
buddy module.

Before this, not built. The bot module's ranged bots stand at casting range and step
back to keep it; its bots flee when in trouble.

## Intended Behavior

- **Shelter.** A ranged bot struck by a foe finds the nearest melee ally
  in its section and moves so that ally stands on the line between it
  and the foe: still within its casting range of the foe, as far back as
  that range allows. If no melee ally is in the section, it stays and
  fights.
- **Backsteps.** A melee bot never turns its back to run. When the need
  is great (its health low, or its section outnumbered past a point), it
  gives ground by stepping backwards, facing the foe, at walking-backward
  speed, along its front's axis; it stops when the need passes or when
  it would leave its section's ground.
- **Fighting to the last.** A melee bot with nowhere to step back to (the
  section surrounded) stands and fights.

## Suggested Implementation Steps

1. In the paper simulation: the shelter spot (on the foe-to-ally line,
   behind the ally, inside casting range), the backstep rule.
2. In the buddy module: as fighting actions of the bots in a front,
   above the bot module's own flee and range rules.
3. Logs: each ranged bot's distance from the line through its foe and
   ally; each melee bot's speed and facing during a backstep.

## Open Questions

1. "When need is great": what is the need: its own health under a share,
   its section outnumbered by some count, or both?
2. Does 619's pack retreat (giving ground together) become this backstep
   rule for melee, or are they separate (the pack outside battlegrounds,
   the backstep inside)?
