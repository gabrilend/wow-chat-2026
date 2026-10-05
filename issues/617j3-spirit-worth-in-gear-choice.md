# 617j3 - Spirit's Worth in a Buddy's Gear Choice

## Status
- Created: 2026-10-04
- Phase: 6
- Parent: 617j (buddy loot judgement)
- Blocked by: 167 (spirit heals by stamina, patch B049)
- Patch: B050 (`patches/B050-playerbots-buddy-spirit-worth.sh`), basic; checked 2026-10-04 on a clean copy: applies once, compiles, reverts byte-identical
- Priority: Medium

## Origin

Verbatim, 2026-10-04:

> can you update the buddy-bot stat profile preferences according to the
> relative value compared to stamina of the spirit update? It should
> update dynamically as their gear shifts. They should try and keep them
> in balance.

## Current Behavior

**Written 2026-10-04, syntax-checked with the build's flags, not yet
compiled.** Before it: the bot module scores every item a bot might wear
with stat weights for its talent tree (`StatsWeightCalculator`), and B046
lets the buddy module answer for buddies (their talent plan's blend of
trees). Spirit's weight there is only its stock one: something for mana
users, nothing for anyone else. Since 167, spirit also heals every class
by stamina, which the weights don't know.

## Intended Behavior

For buddies, spirit's weight also counts its healing, measured against
stamina in the same coin (health over a fight):

- +1 stamina gives about 10 health at once, plus (by 167's rule) spirit /
  100 more health every 5 seconds;
- +1 spirit gives stamina / 100 health every 5 seconds;
- over a fight of T seconds (`FIGHT_SECONDS`, 30), spirit's worth in
  stamina is (S / 100 x T / 5) / (10 + P / 100 x T / 5), with S and P the
  buddy's stamina and spirit as it stands now.

Spirit's weight gains stamina's weight times that worth, on top of its
stock weight (mana users still value it for mana). It is worked out from
the buddy's current stats every time an item is scored, so it follows the
buddy's gear: the more stamina it has, the more spirit is worth; the more
spirit, the less each more is worth and the more stamina is. A buddy
choosing between items therefore drifts toward keeping the two in
balance. Example, T = 30: with 300 stamina and 100 spirit, one spirit is
worth 18 / 16 = about 1.1 stamina; with 300 of each, 18 / 28 = about 0.64.

Players are untouched (the stock scorer), and so are other bots.

## Suggested Implementation Steps

1. (Done) B050 in the bot module: the scorer's weight builder asks the buddy
   module `BuddySpiritWorth(player)` (declared in the patch, defined in
   `buddies_loot.cpp`; a negative answer: not a buddy, leave the weights
   as they are) and adds stamina's weight times it to spirit's.
2. (Done) `BuddySpiritWorth` in `buddies_loot.cpp`: the buddy test the
   module's other loot answers use (its remembered roster facts), then
   the formula above from the buddy's current stamina and spirit.
3. After the owner's compile: watch a buddy's choices between a stamina
   item and a spirit item as its spirit rises (the trace of its upgrades).

## Open Questions

1. `FIGHT_SECONDS`, 30: the longer the fights counted, the more spirit is
   worth. Is 30 seconds right for the fights buddies have?
