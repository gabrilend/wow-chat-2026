# 155e1b - Geraldenge's Tower in Darnassus

## Status
- Created: 2026-10-22
- Phase: 1
- Parent: 155e1 (the Profession Mentor in each capital)
- Related: 155e1a (the goblin's tent), 155z11 (weapon presentations: the
  sparring youths are the same idea), 617f (B047's outfit list)
- Priority: Low
- State: planned; open questions first

## Origin

Verbatim, 2026-10-22, of Darnassus's mentor (the dwarf weaponsmith whose
look it borrows: Borgus Steelhand of Stormwind):

> this dwarf would be widely respected, and thus should live in a tall
> tower of a spiralling height. It's okay if it's out of the way, so long
> as it is still in Darnassus. [the viridian shore]
>
> in this tower, he should have a workshop, the finest that they could
> find. It must have a large area for mineral storage (carts against a
> shelf) and plenty of indoor plants. Ideally, odd or a-typical to that
> climate ones. It should be mostly bare of soft things, preferring wood
> and workspace. Also, several energetic youths to spar with weapons that
> have been crafted by the dwarf. Sometimes he watches them and takes
> notes on the weapons qualities. Sometimes they just tell him how it's
> best used. His name is Geraldenge, "ger" like "scare", "ald" like
> "aldi's" and "deeng" like "deen-guh".

## Current Behavior

Darnassus's Profession Mentor (E068, creature 1550033) is "Visiting Mentor",
a copy of Borgus Steelhand's look, standing two yards to the right of
Darnassus's fishing trainer (the city has no mining trainer), teaching
blacksmithing, engineering, jewelcrafting and mining.

## Intended Behavior

- **His name:** Geraldenge (said "GER-ald-deen-guh": "ger" as in "scare",
  "ald" as in "Aldi's", "deeng" as in "deen-guh"), the mentor's name in
  Darnassus, his subname still Profession Trainer.
- **A tall spiralling tower**, out of the way but inside Darnassus (open
  question 1 on where).
- **His workshop inside:** the finest; a large mineral store (ore carts
  against a shelf); plenty of indoor plants, odd ones for the climate;
  mostly wood and workspace, few soft things.
- **Sparring youths:** several energetic young night elves sparring with
  weapons he made. Sometimes he watches and takes notes on the weapons;
  sometimes a youth tells him how one is best used (a line of talk).

## Suggested Implementation Steps

1. Answer the open questions.
2. His name: E068's generator gives Darnassus's mentor its own name.
3. The tower and the workshop: game objects the client already has (the
   client can show only models it has; a night elf tower or another tall
   building model, stairs, ore carts, shelves, workbenches, potted and odd
   plants), placed by hand in game and written as rows of a basic world
   database step with its revert.
4. The youths: a few creatures (young night elves) with weapons
   blacksmiths make (their equipment), sparring each other on a loop (a
   small Lua script: attack emotes in turn, now and then a line to
   Geraldenge about the weapon; he turns, takes notes with a writing
   emote, and says something back).
5. In game: look at it.

## Open Questions

1. **Where:** "[the viridian shore]": is that the spot you have in mind
   for the tower (a `.gps` reading there would settle it), and inside
   Darnassus's walls or on its edge?
2. **The tower itself:** the game has no player-made buildings; an
   existing building model placed as an object is the way. Is a borrowed
   tower (a night elf tower, a Kirin Tor-like spire) all right, or does
   it need to be a particular one you've seen?
3. **His workshop and the mentor's dialogue:** does he still teach from
   the tower's workshop (so players climb to him), or stay at the crafting
   quarter with the tower as his home?

## Answers, 2026-10-22

- **His name, said:** "Ger like Geralt from that one monster hunting game
  I forget it's name... Monster Hunter? No, it's like, danish." (That is
  The Witcher's Geralt; the game is Polish.) So "Ger" as in Geralt: GER-
  ald-deen-guh.
- **The Viridian Shore is a poem, not a place:** "it's the name of a poem
  he wrote when first arriving there. He sang it to the court as his
  elegance art, and they are amazed that he crafted it in so few months.
  He says it was a burst of inspiration that secured a long-term
  feeling, they say that it's a testament to the flexibility of the
  eternally weaning (weird way to say it but okay) / translation is hard
  sorry". So the tower's place is still open (question 1), and the poem
  is part of who he is: something he might mention, or the youths ask
  about. Open: should the poem itself be written (by you, or drafted for
  you to change), so he can recite a line of it?
- **His name, said, corrected** (2026-10-22): "it's more like
  GER-all-dee-uh-ng-guh and rapidly pronounced gare like chair all like
  all of us, deemn like dream with no r". So, said quickly: GARE (as in
  "chair") - ALL (as in "all of us") - DEEM (as in "dream" without the r)
  - uh - ng - guh. (Replaces the GER-ald-deen-guh above.)
- **The poem is never recited** (2026-10-22): "He never recites it.
  Sometimes, he says snippets while in the forge. But nobody can quite
  make out what they mean because of the specific way that the vision he
  had inspired him to work with his tools and machinery". So no poem text
  is written. At the forge he now and then mutters a fragment (a few
  words, half-formed, tied to the work in his hands), and nobody,
  players included, can tell what it means.
