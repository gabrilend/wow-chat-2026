# 625l - Buffs Given to Who Uses Them Most

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625f (the action economy: the window values), 625h (the
  resource economy: Innervate), 625i (the healer's seat)
- Priority: Medium
- State: planned

## Origin

The owner, 2026-10-30, word for word:

> those buffs are neat. Buddies should cast them onto characters that can
> use them the most - this matters for power infusion and innervate and
> others, less so for bloodlust since it affects everyone. We'd just
> compare the weights on each party member and pick the one that can use
> it best, and only check when we're about to cast the spell. We should
> be able to prioritize it as well for players who just cast a cooldown,
> because they will suddenly be bumped higher in the priority queue and
> that *movement* is what allows us to develop an idea that "hey this
> person is blowing their cooldowns, let's maximize them"
>
> Remember we don't want to specify exact values. We want their value to
> come cleanly from the roots of the weights that determine their output
> - at the end of the day, EVERYTHING that we weigh collapses to just
> damage, and health. It's just a question of whose it is, and what route
> through the complicated combat ideaspace leads us to victory most
> assuredly.

## Current Behavior

Not built. The bot module casts its buffs on fixed targets (Power
Infusion on itself or a set role, Innervate on a healer by its own
rules).

## Intended Behavior

- **Asked only when it is about to be cast.** When a buddy's draw (625)
  has chosen a targeted empowering buff (Power Infusion, Innervate, and
  the like; Bloodlust needs no target), it asks then, not before: which
  party member would turn it into the most damage and health?
- **By each member's own weights.** Each member's worth from the buff is
  what it provides (625f's table, read from the game) run through that
  member's own abilities and their weights: a caster mid-cast-sequence
  gains more from Power Infusion's haste than a rogue; a healer short of
  mana gains more from Innervate than one who is full. Players are read
  the same way as buddies (their class, talents and what they cast).
- **Moving up counts.** A member whose worth has just jumped (they just
  used a cooldown, so their next seconds are worth more) is preferred:
  the rise itself is the sign that "this person is blowing their
  cooldowns, let's maximize them". So the comparison weighs each member's
  worth now and how fast it has been rising over the last few seconds.
- **No set values** (the owner: "EVERYTHING that we weigh collapses to
  just damage, and health"): the choice is never a table of who gets
  what; it falls out of each member's damage and healing to come, as the
  economies weigh them (`strategems/everything-is-damage-and-health.md`).

## Suggested Implementation Steps

1. Each party member's worth under a buff, from 625f's provisions and the
   member's abilities, as plain arithmetic, with tests (a caster before a
   rogue for Power Infusion; the emptiest healer for Innervate).
2. Its rise over the last few seconds, kept per member.
3. The target chosen when the buff is about to be cast, in the buddy
   module's own buff action, behind a switch.

## Open Questions

1. How far back should "just jumped" look: the last few seconds (a
   cooldown just used), or long enough to see a whole burst start?
