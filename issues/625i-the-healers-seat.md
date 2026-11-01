# 625i - The Healer's Seat

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625c (every tree's list: a hybrid's minor tree), 625h (the
  resource economy), 617z (tank-paced pulls: the healer's "oom" signals)
- Priority: Medium
- State: in progress (the seat built; mana-regaining fighting not yet)

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

**Built 2026-10-31** (the arithmetic committed and tested; the server's
side written and compiler-checked, waiting for the owner's compile):
`buddies_healer_seat.h`, read by the forward pass (625n).
- **Who can heal**: points in a healing tree (a priest's Discipline and
  Holy, a paladin's Holy, a shaman's and a druid's Restoration), read in
  the server from the bot module's points per tree.
- **The seat**: the party's healer (role 2) that is alive, the most mana
  among several; with none alive, the member able to heal with the most
  mana, until the fight ends.
- **Out of mana and ready again**, from the game's own numbers: out of
  mana when its mana is under its cheapest heal's cost (the cheapest
  direct heal of its class in the generated tables, a cost in percent of
  base mana worked on its own base mana); ready again only when its mana
  covers its own healing for the rest of the fight (its healing a second
  over the minute, times the fight's time left, at that heal's health a
  mana), or it is full, so it doesn't flicker at the line.
- **The leans**: a healing answer (a heal, a heal over time, a shield)
  leans as worked out for the seat's holder, away (0.05: stop casting, so
  spirit refills it) while it is out of mana; for the others able to heal,
  not at all while the seat is fine, and as worked out once it is empty or
  dry ("others can use that as the signal to jump in"). Heals over time
  now count in the fight curves (their ticks over their length, capped at
  full health).
- **It speaks**: the seat's holder, a buddy or stand-in only, says "oom" in
  party chat when it runs dry and "ready" when it is ready again; a player
  in the seat is read the same way and never spoken for.
Checked by `scripts/test-buddy-healer-seat` (13 checks).

Not yet: the holder fighting in the way that brings mana back (Seal of
Wisdom, a wand, a form), paladins choosing Judgement of Wisdom while the
seat is dry, and hearing a player's own "oom" in chat.

## Intended Behavior

- **One healer's seat per party.** The party's healer holds it. If the
  healer dies or is incapacitated and can't be brought back mid-fight (no
  combat resurrection to hand), the seat passes, until the fight ends, to
  the party member with at least some healing talents and the most mana.
- **The seat speaks.** The others look to whoever holds it for the
  healing signals ("ready", "oom", "mana": 617z's words).
- **Out of mana counts as fallen, for a while** (the owner, 2026-10-30:
  "this should also apply if the healer gets low on mana and can't cast
  spells. They should say "oom" or "mana" in an appropriate chat channel,
  and others can use that as the signal to jump in."). A buddy healer low
  on mana says "oom" (out of mana) or "mana" in the party's chat; hearing
  it, the others with healing talents lean toward healing as below, until
  it says "ready" again (617z's words).
- **Out of mana, the healer becomes something else for a while** (the
  owner, 2026-10-30, word for word: "A healer buddy should be able to
  utilize spirit (especially if they're a spirit class) to regenerate mana
  if they need it. If for example they say "oom" then maybe they switch to
  a DPS role and another more suitable player picks up healing if
  necessary - though, with the quality of heals faltering while the true
  healer is oom, there might need more help from the others. Then they can
  Seal of Wisdom, feral scratch, or priest wand or whatever until they get
  their mana back. Sometimes just hitting the enemy can get them judgement
  of wisdom - paladins should prioritize wisdom over light if the healer's
  mana is low."). So, once it has said "oom":
  - **it stops casting**, so its spirit regenerates (past the game's five
    seconds without casting), worth most to a spirit class (priests,
    druids);
  - **it fights instead, in the way that brings mana back**: a paladin
    with Seal of Wisdom on and striking, a druid in a form scratching, a
    priest with a wand (no spell cast, so spirit works);
  - **another suitable healer takes the seat** while it recovers (the one
    with healing talents and the most mana), and the others help more,
    the heals being weaker meanwhile;
  - **Judgement of Wisdom on the enemy**: anyone hitting it can give mana
    back; paladins put Judgement of Wisdom up rather than Light while the
    healer's mana is low;
  - **back in the seat** when it says "ready".
- **A player in the seat** (asked "What happens if a player is the
  healer?"; the agent's design, for the owner to curate): a player who
  heals (their talents, or what they cast) holds the seat like a buddy.
  Buddies read the player's mana and health as they do a buddy's, and
  hear the player's own words in the party's chat ("oom", "mana",
  "ready") the same way; they never speak for the player. If the player
  falls, the seat passes to a buddy as above.
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
   **Answered 2026-10-30:** "that's right".
