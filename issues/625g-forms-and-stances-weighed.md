# 625g - Forms and Stances, Weighed

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625c (every tree's list), 625f (the action economy), 625h (the
  resource economy)
- Priority: Medium
- State: planned

## Origin

The owner, 2026-10-30, word for word:

> the hybrid tree shares looks great. Though a feral druid can often do
> cool things if they have things like Natural Shapeshifter and Furor - we
> should treat various states as important. This also applies to like,
> warrior stances. Some talents allow you to shift into and out of forms
> easily, sometimes even rewarding you for doing so - furor is especially
> important for feral druids in cat form, who can let their energy
> regenerate while casting a couple rejuvenations and such. Similarly a
> warrior can switch to defensive mode temporarily to cast a taunt or
> something, but they have to weigh the cost of losing their rage to do
> so. The weighting for each ability should be very dynamic and update
> according to their context around them, and their stats and talents
> and... so much... But once we build a sufficiently discrete and clear
> system then it should resolve such things naturally.

## Current Behavior

Not built. The bot module puts a druid in the form its strategy names and
a warrior in its tree's stance, and changes them by fixed rules.

## Intended Behavior

- **A form or stance is a state with a price and a gift.** Changing costs
  a global cooldown, mana, and what the old state held (a warrior's rage
  above what the stance keeps, a cat's energy); some talents make it
  cheaper (Natural Shapeshifter) or pay for it (Furor: energy or rage on
  entering a form). These are read from the game's own data, like 625a's
  table.
- **An answer from another state is weighed with the trip.** A cat druid
  with Furor weighs "out of cat, two Rejuvenations, back into cat" as one
  answer: the heals, the energy that comes back meanwhile, and Furor's
  gift on returning, against the time and mana. A warrior weighs a quick
  defensive stance for a taunt against the rage it loses.
- **Not a special case.** Each state's cost and gift are inputs to the
  economies (625f time, 625h resources, 625j threat), so the stance dance
  falls out of the weighing ("once we build a sufficiently discrete and
  clear system then it should resolve such things naturally").

## Suggested Implementation Steps

1. From the game's tables: each form and stance, what changing costs and
   keeps, and the talents that change that (Natural Shapeshifter, Furor,
   Tactical Mastery, Improved Berserker Stance and the like).
2. The trip as one answer in the draw: its total time, cost and gain.
3. Seen in game: a Furor cat healing an ally and returning; a warrior's
   taunt from battle stance.

## Open Questions

1. Should a buddy ever leave a form or stance for an answer its role
   doesn't need (a cat druid healing an ally a healer is already healing),
   or only when its role's concerns are quiet?
