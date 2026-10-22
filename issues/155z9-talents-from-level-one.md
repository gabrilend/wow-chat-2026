# 155z9 - Talent Points from Level 1: Two Full Trees at 60

## Status
- Created: 2026-10-22
- Phase: 1
- Parent: 155 (basic profile)
- Related: 155g (the talent cap: past the 30-point row only its one-point
  capstones), 718d (a death knight's points over 55-60, whose table must
  end where this rule says level 60 is), 155r (no dual spec, uncapped
  respec)
- Pattern: `strategems/talents-caught-up-over-first-levels.md`
- Priority: Medium
- State: will not be built (the owner, 2026-10-22: "let's do the default of 51 talent points, starting at level 10"); kept as the record of the idea

## Origin

Verbatim, 2026-10-22:

> what if we make it so that at level 60 we have 62 talent points? It'd
> make each character truly "dual spec". That could be... interesting.
> Maybe what, 2 points at level 1 or something? Or 2 at level 60, as a
> reward... Though it's more fun to have them earlier. So level 1 then.
> And level 2-9 each can have +1 talent points.

## Current Behavior

Stock: one point a level from 10, `level - 9`: 51 at 60. Under the 155g
cap a tree takes at most 31 points (30 to reach its last open row, plus
the one-point capstone there), so 51 is one full tree and 20 in a second.
Death knights: 718d (11 at 55, 51 at 60), written and waiting for a
compile.

## Intended Behavior

Points start at level 1, and at 60 a character has 62: two full trees of
31 ("truly dual spec"). Decided 2026-10-22: 3 at level 1, then one a
level, so `level + 2` points at every level (the middle column below).

The arithmetic of the plan as said, 2 at level 1 and then one a level:
levels 2 to 60 are 59 levels, so 2 + 59 = **61** at 60, one short of
62. Two ways to reach 62 (open question 1):

| Level | 2 at 1, one a level | 3 at 1, one a level | 2 at 1, one a level, 2 at 60 |
|------:|--------------------:|--------------------:|-----------------------------:|
|     1 |                   2 |                   3 |                            2 |
|     2 |                   3 |                   4 |                            3 |
|     9 |                  10 |                  11 |                           10 |
|    10 |                  11 |                  12 |                           11 |
|    59 |                  60 |                  61 |                           60 |
|    60 |                  61 |                  62 |                           62 |

The same rule for every class; a death knight's table (718d) ends at the
new count for 60.

## Suggested Implementation Steps

1. Answer the open questions.
2. The rule on the server's talent-count hook in basic's compiled rules
   (`src/cpp-basic/basic_rules.cpp`, beside 718d's death knight table):
   every class, one line of arithmetic. The death knight table's last
   entry and its compile-time check move to the new count at 60.
3. The client: talents are offered from level 10 in the stock client
   (the talent pane opens at 10). Check in game that a level 1 character
   with points can open the pane and learn a first-row talent; if the
   client refuses below 10, the points before 10 wait until 10 (and the
   issue says so).
4. A line in `docs/balance-updates.md`.
5. Tests: the rule as a pure function (every level 1-80 against the
   chosen column); in game a level 1, a level 10 and a level 60.

## Open Questions

1. (Answered 2026-10-22: "let's try 3 at level 1.") 3 at level 1, then
   one a level: `level + 2`, 62 at 60.
2. **The talent pane before level 10:** if the client won't let a level 1
   spend points, is "they wait until 10" all right?
3. **Above 60** (expert, 156): one a level after 60, as now?
