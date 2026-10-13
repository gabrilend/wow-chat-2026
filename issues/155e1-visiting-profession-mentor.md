# 155e1 - A Visiting Mentor for Professions

## Status
- Created: 2026-10-13
- Phase: 1
- Parent: 155e (quests open to the faction; the Visiting Mentor, a class
  trainer for the classes a site lacks)
- Related: 155p1 (each capital jewelcrafter teaches its own order of
  cuts; the eccentric visitor), 155n (no profession trainers beyond
  Azeroth), B029 (the server honours a trainer list named on a gossip
  line)
- Priority: Medium
- State: planned; open questions first

## Origin

Verbatim, 2026-10-13. Asked about jewelcrafting trainers:

> We have a special vendor that teaches all the professions in each
> capital city, right? How does that go?

On hearing it was the Visiting Mentor, who teaches classes, not
professions:

> ah yes we need one of those

## Current Behavior

Each capital has the stock one-profession trainers, scattered through
the city, and (from 155p) a Visiting Jewelcrafter in the six capitals
that had no jewelcrafting trainer. No trainer teaches more than one
profession.

The Visiting Mentor (155e, install step E022): one at each of 23 sites
(every starting valley, first town and capital), teaching the classes
that have no trainer there. It has no list of its own: its dialogue has
one line per missing class ("Can you teach me the ways of the druid?"),
each naming that class's list, which source patch B029 makes the server
open. A player sees only the line for their own class.

## Intended Behavior

A visiting profession mentor in each capital: one creature whose
dialogue has a line per profession ("Can you teach me alchemy?"), each
opening that profession's trainer list, through the same mechanism as
the Visiting Mentor.

## Suggested Implementation Steps

1. Answer the open questions.
2. The profession lists (one per profession, capped at 300 by 155n's
   rules), the gossip menu with a line per profession, and the creature,
   in a basic install step with its revert.
3. Its spawn in each capital, beside the Visiting Mentor or the city's
   crafting quarter (generated, as the mentors' sites are).
4. A check in `scripts/validate-basic-state`: one per capital, every
   profession line opening a list.
5. In game: one capital, each line.

## Open Questions

1. Every profession, or only those with no trainer in that city?
2. Capitals only (eight), or every site the Visiting Mentor stands at
   (starting valleys and first towns too)?
3. Jewelcrafting: does its line open the capital's own jewelcrafting
   order (155p1), or is jewelcrafting left to the eccentric visitor?
4. Its look and name: one figure everywhere, or a different look per
   city as the mentors borrow one?
