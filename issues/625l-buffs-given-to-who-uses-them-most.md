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

And, the same day:

> maybe when a buddy-bot enters a party, they build a list of the
> characters who might benefit from it, and then it only iterates through
> them when it's time to cast? They should be able to coordinate with the
> other buddy's cooldown economy to optimize uptime and such. And by
> coordinate I just mean like... when they can cast the buff, they look at
> the other buddy-bot's timing for the rest of the fight and they try and
> slot it into whichever buddy-bot has the best outcome for it. Keep in
> mind the cooldown economy where buddy-bots might be able to cast more
> than once in a fight, trying to optimize uptime! Anyway when joining a
> party we should make a mental list of each of the targets that *might*
> benefit from it, and then only iterate through them to see who we
> should cast it on.

On preferring a member whose worth just jumped: "this is an alternative.
Use whichever feels best."

## Current Behavior

Not built. The bot module casts its buffs on fixed targets (Power
Infusion on itself or a set role, Innervate on a healer by its own
rules).

## Intended Behavior

- **A short list made on joining.** When a buddy that can give such a
  buff joins a party (or the party changes), it lists the members who
  *might* benefit: for Power Infusion those who cast with mana; for
  Innervate those with mana to refill; and so on, by what the buff gives.
  Only that list is looked at later.
- **Slotted into the others' timelines.** When the buff is ready, the
  buddy looks at each listed member's plan for the rest of the fight (a
  buddy's cooldown timeline from the action economy, 625f) and gives it
  where the outcome is best: where it lands on that member's own burst,
  and so that the buff itself comes back in time for another good use
  (a buff cast more than once a fight is planned for the most valuable
  uptime, as a cooldown is).
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
- **Moving up counts, for those without a plan to read** (the agent's
  call, as the owner left it, "Use whichever feels best"): a buddy's
  timeline says when it will burst, so buddies are slotted by their
  plans; a player's isn't known, so for players the jump in worth (a
  cooldown just used) is the sign instead.
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
   Now asked only for players (buddies are slotted by their plans).
