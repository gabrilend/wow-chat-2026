# 155z12 - A Fall Costs Rest, Not Repairs

## Status
- Created: 2026-10-22
- Phase: 1
- Parent: 155 (basic profile)
- Related: 718 (the death knight skip ends in a deliberate fall to the
  death), 718e (the fall into the chapel), 155p (white gear never
  repaired)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-22:

> can we make it so there's no durability damage when we die from fall
> damage? also we'll have to subtract rested experience while dying
> instead. Because it makes you stressed out.

## Current Behavior

Stock (`Player::EnvironmentalDamage`, Player.cpp): a player killed by a
fall loses 10% of every equipped item's durability at once
(`DurabilityLoss.OnDeath = 10` on basic), the one place the server takes
durability for a death by itself (other deaths' loss comes through the
damage step). A spirit healer's resurrection costs a further 25%
(`DurabilityLoss.OnSpiritResurrect`). So every death knight that skips
its story loses 10% durability in its planned fall (718), and on white
gear that can't be repaired (155p).

## Intended Behavior

- **A death by falling costs no durability.**
- **It costs rested experience instead** ("Because it makes you stressed
  out"): some of the character's rested experience is taken (open
  question 2 on how much).
- Other deaths stay as they are (open question 1).

## Suggested Implementation Steps

1. Answer the open questions.
2. A source patch at the fall's durability line in
   `Player::EnvironmentalDamage` (basic only): the loss skipped, and the
   rested experience reduced in its place; or a compiled script hook if
   the server offers one at that point (none found 2026-10-22: the loss
   happens inside the step).
3. A test where the build allows: a fall death leaves durability and
   lowers rested experience.
4. A line in `docs/balance-updates.md`.

## Open Questions

1. **Only falls, or every death?** "while dying instead" could mean every
   death costs rested experience instead of durability, or only falls.
   And the spirit healer's 25%: kept?
2. **How much rest a fall takes:** all of it, half, or a fixed amount
   (say, the experience of one bubble, a twentieth of the level)?
3. **A character with no rested experience:** nothing more happens, or
   something else is taken?
