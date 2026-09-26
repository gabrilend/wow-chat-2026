# 155r - No Dual Spec, Uncapped Respec Cost

## Status
- Created: 2026-09-25
- Phase: 1
- Parent: 155
- Related: 155g (the talent cap), 617g (buddies re-roll their talents
  when the owner respecs)
- Priority: Medium

## Origin

Verbatim, 2026-09-25, while designing buddies' talents (617g):

> Also, we should remove dual spec from the game. Also, we should remove the
> cap on the gold cost of respeccing, and it should decrease by one
> increment every month of calendar time. Or maybe every reset? Not sure.

## Current Behavior

Stock (read 2026-09-25 in `Player::resetTalentsCost`, Player.cpp): the
first respec costs 1 gold, the second 5, the third 10; after that each
respec costs 5 gold more than the last, **capped at 50 gold**; and when a
calendar month or more has passed since the last respec, the price drops
by 5 gold per month, to no less than 10 gold. Dual talent specialization
is bought from class trainers at level 40 (stock 1,000 gold).

## Intended Behavior

- **No dual spec on basic**: characters can't buy or use a second talent
  specialization.
- **No cap on respec cost**: each respec costs one increment (5 gold) more
  than the last, without limit.
- **The cost comes back down with time**: one increment less per calendar
  month since the last respec, as stock does (or per reset: open below).

## Suggested Implementation Steps

1. Dual spec: remove the way to buy it on basic (the class trainers'
   dual-spec purchase, and the spell it teaches), found and saved by an
   install-time SQL pair; check whether any character already has it.
2. Respec cost: a source patch on `Player::resetTalentsCost` that drops the
   50-gold cap for the basic profile (the monthly decrease stays).
3. Tests: the RAM database test for the SQL; `scripts/test-source-patches`
   for the patch; in game, three respecs in a row cost 1, 5, 10, and the
   eleventh more than 50.

## Open Questions

- The decrease: once per calendar month (stock), or "every reset" — which
  reset: the weekly raid reset, or something else?
- Does the minimum after decreasing stay at 10 gold?
