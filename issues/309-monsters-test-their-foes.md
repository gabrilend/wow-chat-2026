# 309 - Monsters Test Their Foes

## Status
- Created: 2026-10-15
- Phase: 3
- Related: 622 (buddies learn from what their weapons do: the same idea
  from the companions' side)
- Priority: Low
- State: an idea; the design is open

## Origin

Verbatim, 2026-10-15:

> but the monsters must be trained to vote. Right now they all mostly
> just... fight and attack. They should test some parts of their foes, but
> not others, to enable strategy in their attack. Thus, choice, and then
> they are monster no more. With their wisdom and guidance, they vote for
> what they think is alignment. Then, they are creatures no more. Noble
> wisdom ariseth.

Asked to describe one fight from the monster's side:

> "Hmmm, I will use my purple fire attack because they seem to be made out
> of fire wood. Though I don't see the fire at this angle..."

Asked how it happens: "somehow."

## Current Behavior

Monsters (ambush spawns and the world's own) fight by their scripted or
default behaviour: approach, attack, cast what their script lists on its
timers. None looks at what its foe is weak to, none remembers what worked,
none chooses among its attacks by what it has seen.

## Intended Behavior

A monster looks at its foe, guesses what it is weak to from what it can
see (its armour kind, its class, the school of what it has been hit
with), and picks the attack that guess favours. Its guess is imperfect on
purpose: it tests some parts of its foe and not others ("I don't see the
fire at this angle"), so different monsters choose differently, and a
player can learn what they test and play around it. What a kind of
monster learns can be shared among its kind: a vote, the monsters' own
alignment.

## Suggested Implementation Steps

1. Answer the open questions; until then this is an idea, not a plan.
2. A first, small version: one ambush monster kind with two attacks of
   different schools that picks by the foe's highest and lowest
   resistance it "sees", seeing only one at a time.
3. A memory of results per monster kind (damage done by each attack
   against each class), and a vote: the kind's next spawns prefer what
   the memory favours.

## Open Questions

1. What can a monster see of its foe: armour kind, class, race,
   resistances, the last spell that hit it? Which are hidden from it?
2. The vote: among monsters of one kind, of one zone, or all monsters?
   What do they vote on: the attack to open with, the foe to strike
   first, whether to fight or flee?
3. Is the "alignment" they vote for the same as the alignment players
   choose elsewhere in the design, or the monsters' own?
4. What does "monster no more, creatures no more" become in play: does a
   monster that has learned enough change (a name, a look, a side)?
