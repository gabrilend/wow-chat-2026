# 625f - The Action Economy

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625h (the resource economy), 625j (the threat economy), 625g
  (forms and stances), 617z (tank-paced pulls: the movement economy),
  617e5b (boss fights by the warnings: the boss-mechanic economy)
- Priority: High (the owner: "I am very excited to work on the action
  economy.")
- State: planned; designed with the owner next

## Origin

The owner, 2026-10-30, word for word:

> Remember... there's multiple economies we need to balance. There's mana
> economy, (rage energy etc for the others), action economy (global
> cooldowns primarily, but also cast-times and such. Putting abilities on
> cooldown is valued to the action economy, especially if it can line up
> the times on when they come off cooldown so that they can be cast as
> often as optimizable), movement economy (how much to move, how fast the
> party is moving "slow down" or "go faster" or "out of mana" style),
> threat economy (can the tank handle more monsters, should an off-tank
> pull off of a faltering main tank, etc). These economies (and possibly
> others, including boss-mechanic economy (unique to each boss probably))
> need to be balanced artfully and skillfully to create systems that react
> dynamically and appropriately. Ideally, they could adjust with time
> spent learning, though only if we keep track of both A. how to learn,
> and B. where we started from, so if we wanted to we could either 1.
> learn from scratch as a batch, to see if we grow into different
> conclusions (the ideal state), or 2. to learn individually and become
> better at the game and our class as we level up and get better.
>
> I am very excited to work on the action economy.

## Current Behavior

Not built. The bot module takes the first answer a concern offers that is
useful and possible: an ability on cooldown is simply skipped, and nothing
weighs the time a cast costs, or plans when cooldowns come back. The
talent draw (625, built) and the economy plan (625d) weigh answers but
not time.

## Intended Behavior

**Time is the currency.** Every answer costs time: the global cooldown it
starts (1.5 seconds, less with haste), its cast time (a channel's whole
length), and the cooldown it puts itself on. The action economy weighs
what each answer gets done against the time it spends, and:
- **Using a cooldown is worth something in itself**: an ability off
  cooldown and not used is time wasted, so an ability whose cooldown is
  ready leans upward the longer it sits ready ("putting abilities on
  cooldown is valued").
- **Cooldowns lined up.** A buddy keeps a small timeline of its own
  abilities: when each comes back. It prefers the order that has the
  most of them used as soon as they return, and lines up the long
  cooldowns with each other and with empowered moments (625d: Bloodlust,
  a boss's weak phase), "so that they can be cast as often as
  optimizable".
- **Cast times against the moment**: a long cast is worth more when
  nothing will interrupt it (standing still, nobody hitting the caster),
  less when movement is coming (625d's movement measure) or the target
  may die first.
- **The global cooldown as the scarce slot**: off-global abilities
  (some instants, item uses) are slipped between global cooldowns rather
  than spending one.

The action economy is one of several (625h resources, 625j threat, 617z
movement, 617e5b boss mechanics): each says how much an answer is worth
by its own measure, and the draw (625) weighs them together. Learning
(625k) may move its numbers, keeping how it learned and where it started.

## Suggested Implementation Steps

1. Designed with the owner (the open questions below), in a sandbox page
   first: one buddy's ability timeline over a fight, each choice shown
   with what each economy said.
2. The timeline as plain arithmetic in the buddy module's pure core
   (each ability's global cooldown, cast time, cooldown, readiness), with
   tests.
3. Its weight joined to the talent draw's multiplier.

## Open Questions

1. How long may a buddy hold a ready cooldown to line it up with another,
   or with an empowered moment, before using it anyway?
2. Should the timeline look ahead (plan the next few casts, as a skilled
   player does), or only weigh the next one by what is ready?
