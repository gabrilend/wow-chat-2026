# 155e1a - The Goblin's Quiet Tent in Thunder Bluff

## Status
- Created: 2026-10-22
- Phase: 1
- Parent: 155e1 (the Profession Mentor in each capital)
- Related: 155e1b (Geraldenge's tower in Darnassus), 617f (Sargobras's
  outfit: B047's outfit list dresses a creature in chosen items)
- Priority: Low
- State: planned; open questions first

## Origin

Verbatim, 2026-10-22, of Thunder Bluff's mentor (who borrows the look of
Roxxik, the goblin engineering trainer of Orgrimmar):

> they should be dressed in robes and use wizard decor in their area. Just
> a small, one person tent, with a bit of space like a living room.
> there's no typically loud goblin machines, to not disturb the peace and
> noble tranquility of blessed Mulgore. If the goblin wishes, the robes
> may be too large for them, but they will also be provided a pair that
> are their size.

And: "only the goblin trainer dances. And he dances for a set amount of
time each time."

## Current Behavior

Thunder Bluff's Profession Mentor (E068, creature 1550036) is a copy of
Roxxik's look in his own clothes, standing two yards to the right of
Thunder Bluff's mining trainer, with nothing around him. Since
2026-10-22 he is the only mentor who dances: a minute, every 30 to 90
minutes (`src/lua-basic/profession-mentors.lua`).

## Intended Behavior

- **Robes:** he wears a wizard's robe. The robe may be too large for him
  if he likes (a human-sized robe on a goblin), and a robe his own size
  is provided too (two outfits; open question 1 on when he wears which).
- **A small tent:** a one-person tent with a bit of space before it like a
  living room, furnished with wizard decor (books, a rug, a globe, candles,
  a scroll case: objects the game already has).
- **Quiet:** no goblin machines, nothing loud; the peace of Mulgore.
- He moves from beside the mining trainer to the tent (open question 2).

## Suggested Implementation Steps

1. Answer the open questions.
2. The robes: B047's outfit list (the buddy module's way of dressing a
   creature in chosen items) gets an entry for creature 1550036, a robe
   chosen from the game's cloth robes by look.
3. The tent and the decor: game objects the client already has (a small
   tent, rugs, books, a table, candles), placed by hand in game and
   written as rows of a basic world database step (as the beds of 617e4
   were placed), with their revert.
4. His spawn moved to the tent (the generator's spot for Thunder Bluff
   overridden).
5. In game: look at it.

## Open Questions

1. **Which robe when:** the too-large robe always (the joke), his own-size
   one always, or he changes between them now and then?
2. **Where the tent stands:** beside the mining trainer as now, or a quiet
   spot of your choosing on the bluffs (a `.gps` reading there)?
