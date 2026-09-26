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
- **The cost comes back down with time, weekly** (Ritz, 2026-09-25: "yeah
  let's make it weekly instead of monthly"): one increment (5 gold) less
  per week since the last respec, instead of stock's per month.
- The cost grows by adding, not multiplying (Ritz asked: "How does the
  respec cost increase? Is it multiplied or added?"): 1, 5, 10 gold, then 5
  gold more per respec (15, 20, 25 … the 20th respec costs 90 gold).

## Suggested Implementation Steps

1. Dual spec: remove the way to buy it on basic (the class trainers'
   dual-spec purchase, and the spell it teaches), found and saved by an
   install-time SQL pair; check whether any character already has it.
2. Respec cost: a source patch on `Player::resetTalentsCost` that drops the
   50-gold cap for the basic profile and counts weeks (7 days since the
   last respec) instead of months for the decrease.
3. Tests: the RAM database test for the SQL; `scripts/test-source-patches`
   for the patch; in game, three respecs in a row cost 1, 5, 10, and the
   eleventh more than 50.

## Open Questions

- (Answered 2026-09-25) The decrease is weekly.
- A week counted as 7 days since the character's last respec (like stock's
  month), or at the server's weekly reset day?
- Does the minimum after decreasing stay at 10 gold?
