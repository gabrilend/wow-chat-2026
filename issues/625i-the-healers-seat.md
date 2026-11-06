# 625i - The Healer's Seat

## Status
- Created: 2026-10-30
- Phase: 6
- Parent: 625 (buddies favour the abilities their talents touch)
- Related: 625c (every tree's list: a hybrid's minor tree), 625h (the
  resource economy), 617z (tank-paced pulls: the healer's "oom" signals)
- Priority: Medium
- State: in progress (the seats built; the dry healer's way back to mana,
  Judgement of Wisdom and a player's own words built offline 2026-11-06)

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

And 2026-10-31, word for word, on the seat as first built:

> but we should only update this role when the current healer runs out of
> mana or dies. Also, for raids, we should have as many healers as we had
> when the fight started - we can count 1/3rd specs as 1/3rd of a healer,
> off-specs (2/3rd and 1/3rd with 1/3rd being healing talents) as 1/3rd of
> a healer, and full specs and main specs (2/3rd healing talents 1/3rd non
> healing tree) as 1 whole healer.

## Current Behavior

**Built 2026-10-31** (the arithmetic tested; the server's side written and
compiler-checked for cc-test, waiting for the owner's compile):
`buddies_healer_seat.h`, read by the forward pass (625n).
- **How much of a healer each member is** (the owner's thirds): the share
  of its talent points in healing trees (a priest's Discipline and Holy, a
  paladin's Holy, a shaman's and a druid's Restoration), to the nearest
  third: two thirds or all, a whole healer; a third, a third of one; none,
  none. A healer by role with no points spent yet (a low level) counts
  whole. The points per tree are read in the server from the bot module.
- **Seats, not one seat**: when a fight begins, the party's healers by role
  (alive) hold the seats, and what their shares add up to is what the
  party keeps for the whole fight ("as many healers as we had when the
  fight started"; two whole healers in a raid stay two).
- **Changed only by running dry or falling**: a holder keeps its seat
  while it is alive and has mana; someone else having more mana changes
  nothing. When a holder falls or runs out of mana, the seats are filled
  back to the fight's starting count from the members able to heal (alive,
  some healing points, not out of mana, not recovering): whole healers
  before thirds, then the most mana among equals. If they can't be filled
  back, the party is **short**.
- **Out of mana and ready again**, from the game's own numbers: out of
  mana ("oom") when its mana is under its cheapest heal's cost (the
  cheapest direct heal of its class in the generated tables, a cost in
  percent of base mana worked on its own base mana). Once out, it stays
  out ("dry") until its mana covers its own healing for the rest of the
  fight (its healing a second over the minute, times the fight's time
  left, at that heal's health a mana), or it is full, so it doesn't flip
  back and forth at the line. Ready again, it is a candidate like any
  other; it takes a seat back only when one comes free.
- **The leans**: a dry member's healing answers (a heal, a heal over
  time, a shield) lean away (0.05: it stops casting, so spirit refills its
  mana); a member able to heal but not seated does its own job (healing
  answers don't lean) while the seats are full, and leans in as worked out
  when the party is short ("others can use that as the signal to jump
  in"); the holders' heals lean as worked out. Heals over time count in
  the fight curves (their ticks over their length, capped at full health).
- **It speaks**: a buddy or stand-in that runs dry says "oom" in party chat
  and "ready" when it is ready again; a player is read the same way and
  never spoken for.
- The seats are kept between the forward pass's steps by the party's
  order in the server (the same within one fight), and drawn fresh when a
  new fight begins.
Checked by `scripts/test-buddy-healer-seat` (19 checks: the thirds, the
starting count, sticking while nothing happens, a third of a healer
leaving the party short, a Holy paladin making it whole, ready again
without taking the seat back, a fallen holder replaced, the leans, and
Innervate's target).

**The rest, built 2026-11-06 (offline, on a branch for review):** in
`buddies_healer_seat.h`.
- **The dry member's way back to mana** (`Dry`, `DryLean`): a paladin puts
  on Seal of Wisdom and strikes, a druid goes into cat form and claws
  ("feral scratch"), a priest uses its wand, a shaman strikes; none of them
  casts, so spirit works. The seal or the form leans in (3) while the
  member is dry; its heals already lean away (0.05).
- **Judgement of Wisdom** (`HealersLow`, `Judgement`): a paladin keeps
  Judgement of Wisdom on the enemy while a seat is dry or short, or a
  holder is under half its mana; Judgement of Light otherwise.
- **A player's own words** (`Heard`, and `Now`'s new last argument): the
  party chat's "oom", "out of mana", "mana" and "ready" (read by the tank
  pace's `ReadWord`, the whole line the word), from a player or a buddy,
  each heard once: "oom" takes the speaker out of the seat and keeps it
  dry whatever its mana bar shows; "ready" ends its dry spell at once, and
  it takes a seat back only when one is free.
Checked by the same test, now 40 checks; 16 of 16 deliberately broken
versions of the additions caught. Not yet: the server carrying these out
(putting on the seal or form and striking, choosing the judgement, passing
the party's chat lines to `Heard`), which waits for the owner's compile.

## Intended Behavior

- **As many healers as the fight began with.** The party's healers hold
  the seats; their shares (a whole healer for two thirds or more of its
  points in healing, a third for a third) are what the party keeps. A seat
  changes hands only when its holder runs out of mana or dies (or is
  incapacitated and can't be brought back mid-fight); then it passes to
  members with healing talents, whole healers first, the most mana among
  equals, until the count is made up again.
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

## Decisions (2026-11-06)

The agent's calls while building the rest, for the owner to curate; each
number is one constant in `buddies_healer_seat.h`:
- **A dry shaman strikes**: the owner named the paladin, the druid and the
  priest; a shaman has no wand or mana-giving seal, so it fights in melee
  without casting, letting spirit work.
- **How far the seal or form leans**: 3, so it is put on before the
  strikes begin; nothing else of the dry member's changes.
- **"The healer's mana is low"**: a seat dry or short, or a holder under
  half its mana (`WISDOM_BELOW` 0.5).
- **A word outweighs the bar**: a player's (or buddy's) "oom" counts it out
  of mana even with mana showing (it may know better: a long cast ahead, a
  silence), and its "ready" counts it ready at once; each word is used
  once, at the next step.
