# 177 - Gnomeregan, a City by Thirds of the Day

## Status
- Created: 2026-10-08
- Phase: 1
- Related: 617t (stand-ins: Gnomeregan counts as cold for their shirts)
- Priority: Low

## Origin

The owner, 2026-10-08, listing cold places for stand-ins' shirts:

> gnomeregan yes because it's under dun morogh, also can we turn it into
> a capital city for 1/3rd of the day, then a dungeon, then a city
> again? Next time it'll be dungeon city dungeon, so over two days it
> equalizes exactly the same number of hours per day per year.

## Current Behavior

Not built. Gnomeregan is a five-player dungeon, its hostile troggs and
leper gnomes always there. The gnomes live as refugees in Ironforge.

## Intended Behavior

Gnomeregan switches between a capital city and a dungeon in thirds of
the day (eight hours each):

| | First third | Second third | Third third |
|---|---|---|---|
| Day one | city | dungeon | city |
| Day two | dungeon | city | dungeon |

Over every two days it is a city 24 hours and a dungeon 24 hours, so
across a year each gets exactly half the time.

- **As a city:** the gnomes' capital, with its own people (vendors,
  trainers, guards), and none of the dungeon's enemies.
- **As a dungeon:** the stock dungeon.
- **Caught inside at the change** (owner, 2026-10-08): a player in the
  city when it turns finds themselves alone in a dungeon of their own,
  at the spot they stood. The toxic gas and ooze stop health and mana
  coming back on their own; health and mana potions work with no
  cooldown.

## Suggested Implementation Steps

1. Decide the open questions.
2. The clock: which third of which day it is, from the server's time.
3. The city's people and the dungeon's creatures as two sets, one shown
   at a time.
4. The change itself: what happens to whoever is inside.
5. A test listing the switches over a week against the table.

## Open Questions

1. **Which profile:** basic, or every profile?
2. **When the day starts:** midnight server time, or another hour?
3. (Answered 2026-10-08) **Who is inside at the change:** "they get
   dumped into a dungeon at the spot they're in, alone, and health
   doesn't regenerate nor mana outside of mana potions which have no
   cooldown. also health potions. to counteract the toxic gas/ooze."
   Anyone in the city when it turns into the dungeon finds themselves
   in a dungeon of their own, alone, at the spot they stood. There
   neither health nor mana comes back on its own; health and mana
   potions have no cooldown, as the cure for the toxic gas and ooze.
4. **The city's people:** from the existing gnome refugees in Ironforge
   (moving home for those hours), or new ones?
5. **The city half and the dungeon half:** one place (the instance turns
   into a city), or the city in the open world above it while the
   dungeon keeps its own entrance?
