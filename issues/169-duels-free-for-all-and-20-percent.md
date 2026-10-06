# 169 - Nearby Duels Are One Fight; Duels End at 20%

## Status
- Created: 2026-10-04
- Phase: 1
- Profile: basic
- Priority: Medium
- Related: 170 (the sparring grounds use both rules)

## Origin

Verbatim, 2026-10-04:

> Also, we should make it so that anyone who is in a duel can fight and
> deal damage to anyone else who is in a duel near them.

> Also, duels end at 20% health on this server.

## Current Behavior

Not built. Stock: a duel is between two players only; a dueller can't
harm anyone else, and the duel ends when one would drop to 0 health (they
are left at 1).

## Intended Behavior

Owner, 2026-10-04: "dueling should just be consenting to
free-for-all-ing. If you drop to 20% health you can't be targeted or ask
for duels or be asked until you hit 100% health again."

- **A duel is consent to a free-for-all**: anyone in a duel may attack,
  harm and heal anyone else in a duel (no distance limit beyond being
  able to reach them), as well as their own opponent.
- **Out at 20%**: a duellist who would drop below 20% of their health
  stops there and is out: nobody can target them, and they can neither
  ask for a duel nor be asked, until their health is full again.
- **Healers from outside** (owner, 2026-10-04: "healers should be able to
  heal anyone in a duel without being engaged in a duel. They will run
  out of mana eventually."): anyone may heal a duellist without joining
  the fight.
- **No eating where you fight** ("can we remove the health restorative
  effects of food and water when near a duel? It's not good to fight where
  you eat. So characters have to either walk far away (back into the
  city, to a cafe or something for food) or they can just sit by the fire
  with their allies at the duel place."): food and drink restore nothing
  near a duel (a radius round each duellist, open question 4); campfires
  (170) still help.
- **Monsters hit duellists twice as hard** (owner, 2026-10-04: "also
  monsters deal 2x damage to dueling characters").
- **Posts stay manned** ("there must be the correct number of combatants
  at all time, so if they want to leave another ally will walk to the
  duel area, until that time they wait, when the ally arrives they can
  swap places and go wander about."): at a duel post (170), a fighter who
  wants to leave waits until a replacement has walked up, then swaps out.

## Suggested Implementation Steps

1. Read how the server decides who may attack whom in a duel (the duel
   check in the attack-validity and damage paths) and where a duel ends
   on a killing blow.
2. A source patch for both rules, basic only.
3. In game: three duels side by side; strikes across them land; a loser
   stops at 20%.

## Open Questions

1. (Answered 2026-10-04) No "near": a duel is consent to fight every
   other duellist.
2. (Answered 2026-10-04) Healing across duels: part of the free-for-all.
3. (Answered 2026-10-04) At 20%: out, untargetable, no duels either way
   until full health.
4. (Answered 2026-10-04) Food and drink stop working within 100 yards of
   a duellist.
