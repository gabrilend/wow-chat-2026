# 617t3 - A Stand-in Becomes a Buddy

## Status
- Created: 2026-10-15
- Phase: 6
- Parent: 617t (dungeon stand-ins)
- Related: 617t1 (the stand-in maker), 617n (weapon kinds), 617a3
  (buddy creation), 617b (choosing a buddy at Sargobras)
- Priority: Low
- State: planned; the design is open

## Origin

Verbatim, 2026-10-15, on weapon kinds:

> When they are instantiated as buddy-bots, they might lose weapon
> skills! That's fine. Though it does produce an incongruity... If the
> stand-in-becoming-buddy-bot wore a weapon in a battleground / dungeon,
> then they should have that skill trained first from among the potential
> weapon skills learned when instantiated. I don't think it could be the
> case that a player would have fewer than the buddy-bot has weapon
> appearances, but we should account for that possibility too.

Asked whether this is planned: "but it's planned, right?" It was not;
this is the plan.

## Current Behavior

Stand-ins (617t1) are characters on their own accounts, drawn into
dungeons, battlegrounds and arenas, and dismissed after. None ever joins
a player as a buddy; a buddy is always made fresh from a roster slot
(617a3).

## Intended Behavior

A stand-in a player has fought beside can become one of that player's
buddies, keeping its name, face, race, class and history. On becoming a
buddy it follows the buddy rules: its weapon kinds are cut to its new
owner's count (617n), keeping first the kinds of the weapons it was seen
wielding, even past the count if it wielded more kinds than the owner
knows.

## Suggested Implementation Steps

1. Answer the open questions.
2. Moving the character from the stand-in account to the owner's
   companion account (617a2), and filling the roster slot with it.
3. Its weapon kinds: the kinds of its worn weapons first, then cut to the
   owner's count; its other gear and spells by the buddy rules of its
   level.

## Open Questions

1. How does a stand-in become a buddy: chosen at Sargobras from the ones
   the player has met, offered by the stand-in after a dungeon, or
   something else?
2. Does it take an owed roster slot, or replace a buddy the player has?
3. Does it keep its gear, or get the kit of its level?
