# 155z12 - A Fall Costs Rest, Not Repairs

## Status
- Created: 2026-10-22
- Phase: 1
- Parent: 155 (basic profile)
- Related: 718 (the death knight skip ends in a deliberate fall to the
  death), 718e (the fall into the chapel), 155p (white gear never
  repaired)
- Priority: Medium
- State: will not be built (the owner, 2026-10-23: "it's fine let's just drop it"); kept as the record of the idea

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

## Answers, 2026-10-22

1. **Every death:** "every death." Every death costs rested experience
   instead of durability.
2. **How much:** "I was thinking about 2 or 4 bars, 2 at earlier levels
   and 4 at higher levels." A bar (a bubble of the experience bar) is a
   twentieth of the level's experience: two bubbles at the lower levels,
   four at the higher.

Still open:
- At which level the cost goes from two bubbles to four (say 30)?
- The spirit healer's 25% durability: gone too (no death costs
  durability at all), or kept as the price of not walking back?
- A character with less rested experience than the cost: it loses what
  it has, and nothing more?
- (Answered 2026-10-22) **The level where it changes: "it's a gradient."**
  Not a step at one level: the cost rises smoothly with level, from two
  bubbles at level 1 to four at the cap (60 on basic), parts of a bubble
  allowed (about three at level 30).
- (Answered 2026-10-22) **Durability stays as normal:** asked whether the
  spirit healer's 25% should go too, "oh, um, yeah, good point, we should
  have the gear take damage as normal. Sorry I don't agree with how I felt
  before." So gear takes durability damage on death as stock (the fall's
  10% included, the spirit healer's 25% too); the "instead of durability"
  above no longer holds. Open: does the rested experience cost stay, on
  top of the normal durability loss, or does this issue fall away?
- (Answered 2026-10-23) **Dropped:** asked whether a death should still
  cost rested experience on top of the normal durability loss: "it's fine
  let's just drop it." Deaths stay as stock.
