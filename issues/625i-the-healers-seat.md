# 625i - The Healer's Seat

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625c (every tree's list: a hybrid's minor tree), 625h (the
  resource economy), 617z (tank-paced pulls: the healer's "oom" signals)
- Priority: Medium
- State: planned

## Origin

The owner, 2026-10-30, asked whether a two-thirds Restoration, one-third
Balance druid should still cast Wrath a third of the time when an ally is
dying, word for word:

> if the healer is dead or incapacitated and can't be revived mid-combat
> through a combat rez or something, then those with healing talents are
> encouraged to heal more to keep things going. The person with at least
> some healing talents and the most mana is designated as the new
> "healer" at least until the fight is over, and people look to them for
> healing-based signals. If the healer's mana is ever low, we can
> prioritize other healing talented classes to throw out heals as well to
> help supplement, especially if they know an instant or easy spell like
> rejuvenation or renew or similar.

## Current Behavior

Not built. Each bot heals by its own strategy; nothing names a healer for
the party or hands the role on.

## Intended Behavior

- **One healer's seat per party.** The party's healer holds it. If the
  healer dies or is incapacitated and can't be brought back mid-fight (no
  combat resurrection to hand), the seat passes, until the fight ends, to
  the party member with at least some healing talents and the most mana.
- **The seat speaks.** The others look to whoever holds it for the
  healing signals ("ready", "oom", "mana": 617z's words).
- **Help when the seat runs dry.** While the seat's mana is low, others
  with healing talents lean toward healing too, first with instant or easy
  heals (Rejuvenation, Renew and the like).
- **Read here as the answer to "when busy"**: a hybrid's minor tree waits
  while its role's duty calls (the role speaks first, 625c); the shares
  are kept across the calmer moments.

## Suggested Implementation Steps

1. Who can heal: the talent shapes (617g) and the talent table (625a).
2. The seat: held, passed on death or incapacity, released at the fight's
   end.
3. The lean toward healing for the others, by the seat's mana.

## Open Questions

1. The reading above of "when busy": is it right that a hybrid's minor
   tree waits while its role's duty calls, its share made up in calm
   moments, or should the third hold even then?
