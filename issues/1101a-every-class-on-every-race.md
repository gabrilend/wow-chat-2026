# 1101a - Every Class on Every Race

## Status
- Created: 2026-10-27
- Phase: 1
- Parent: 1101 (the advanced profile)
- Priority: Low
- State: plan only; nothing built

## Origin

The owner, 2026-10-27:

> also can we enable all classes on all races but just for the advanced
> profile? separate issue file probably.

## Current Behavior

Which race may be which class is the game's own table (`playercreateinfo`
in the world database: one row per allowed race and class, with its start
place; and the client's `ChrClasses`/`CharBaseInfo`, which the character
screen uses). There is no advanced profile yet (1101).

## Intended Behavior

- On the advanced profile only, any race may become any class, through
  the starting zone's NPC below; the character screen keeps the stock
  pairings.
- Each new pairing keeps its race's start and gets the class's own first
  spells, skills and outfit.
- The other profiles keep the stock pairings.

**The owner's way round the client (2026-10-27):** "alternatively, talk to
an NPC in the starting zone while level 1 or level 2 and no higher, and
it'll let you switch to whatever class you want." So the character screen
keeps the stock pairings; in each starting zone an NPC offers a character of
level 1 or 2 any class, and turns it into that class (the class-change
tool's steps, in game: the old class's spells and skills off, the new
class's first ones on, its starting outfit). No client file needed.

## Suggested Implementation Steps

1. Server side: a `playercreateinfo` row (and its spells, actions, items)
   for each missing pairing, made by a tool from the race's and the class's
   existing rows, as an install step gated on `advanced` (the server checks
   these rows when a character's class changes too).
2. The NPC in each starting zone: a gossip menu of the classes, offered to a
   character of level 1 or 2; the change done in game by the class-change
   tool's steps (the old class's spells, skills and talents off, the new
   class's first ones on, the new class's starting outfit).
3. The bot module's class and race checks (buddies of new pairings) read
   from the same table.

## Open Questions

1. (Answered 2026-10-27) The client file is not needed: the starting-zone
   NPC changes class at level 1-2.
2. (Answered 2026-10-27) Racial abilities: kept, as 3.3.5 already fits some
   to the class (Arcane Torrent gives a rogue energy); on advanced, the old
   racial forms (TBC's Mana Tap, and the like) come back with the rest of
   the old abilities (1101, the report).
3. Which NPC, and where in each starting zone?
