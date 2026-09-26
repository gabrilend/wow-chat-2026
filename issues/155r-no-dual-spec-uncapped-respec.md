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
- **Respec cost: 1, 5, 10, then 20, 30, 40, 50 … gold, no cap** (Ritz,
  2026-09-25: "Could we make it 1, 5, 10, then 20, 30, 40, 50, etc?"):
  after 10 gold, each respec costs 10 gold more than the last. (Stock adds
  5 gold per step and stops at 50; Ritz had asked "Is it multiplied or
  added?" — added, in both.)
- **It comes back down on the weekly reset** (Ritz: "yeah let's make it
  weekly instead of monthly" / "Let's do a drop for everyone on the
  server's weekly reset day"): for each weekly reset (the server's weekly
  quest reset) since a character's last respec, the price drops one step
  (10 gold).
- **Floor 10 gold** ("yeah let's keep the floor"): the dropping price never
  goes below 10 gold, as stock.

## Suggested Implementation Steps

1. Dual spec: remove the way to buy it on basic (the class trainers'
   dual-spec purchase, and the spell it teaches), found and saved by an
   install-time SQL pair; check whether any character already has it.
2. Respec cost: a source patch on `Player::resetTalentsCost` for basic:
   steps 1, 5, 10, then +10 gold without a cap; the decrease counts the
   weekly resets between the last respec (`m_resetTalentsTime`) and now,
   using the server's next weekly reset time
   (`World::GetNextWeeklyQuestsResetTime`; the last one was a week before
   it), one 10-gold step per reset, floor 10 gold.
3. Tests: the RAM database test for the SQL; `scripts/test-source-patches`
   for the patch; in game, three respecs in a row cost 1, 5, 10, and the
   seventh 50 and the eighth 60; after one weekly reset the next respec
   costs one step less.

## Open Questions

- (Answered 2026-09-25) The decrease is weekly.
- (Answered 2026-09-25) On the server's weekly reset day, for everyone.
- (Answered 2026-09-25) The 10-gold floor stays.
