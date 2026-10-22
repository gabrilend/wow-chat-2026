# Talents caught up over a character's first levels

A pattern, written down 2026-10-22 (issue 718d), for any character that
begins above level 10: a death knight at 55, a vanilla character at 20,
someday "a level 46 druid with this type of party etc in these conditions
whatever" (the owner).

## The problem

The server hands out one talent point a level from 10: `level - 9` in all.
A character made at level S therefore arrives with `S - 9` points at once
(46 for a death knight at 55), a whole tree's worth of choices on its first
screen, and nothing to look forward to for a while after.

## The pattern

Choose a level C where the character has caught up with everyone (60 for
the death knight). Hand out the points of level C, `C - 9`, over the
levels from S to C, then one a level after C, as stock. At C and after,
the character has exactly what any other has: the pattern only reshapes
the arrival, never the total.

The shares, from plain to tuned:

- **Even, front-loaded:** each of the `C - S + 1` levels takes `(C - 9) ÷
  (C - S + 1)` rounded down, and the first `(C - 9) mod (C - S + 1)`
  levels one more. Death knight: 51 over 6 levels, 9 9 9 8 8 8.
- **A richer first level:** the first level takes a chosen number F, the
  rest share `C - 9 - F` evenly. Death knight, as built: F = 11 ("so they
  can have an extra ability to play with"), then 8 a level: 11 19 27 35
  43 51.

Whatever the shares, check that the running total at C is `C - 9`; the
death knight's table checks it when it compiles.

## Where it is used

- `src/cpp-basic/basic_rules.cpp`, the death knight talent points (issue
  718d): a six-entry table on the server's talent-count hook
  (`OnPlayerCalculateTalentsPoints`), basic only.

## Found useful

- found this useful 10/22/26 (the death knight's 55-60, issue 718d)
