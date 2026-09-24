# 617g - Buddy Talent Plans

## Status
- Created: 2026-09-23
- Phase: 6
- Parent: 617
- Blocked by: 155g (the capped trees these plans are made for)
- Priority: Medium

## Origin

Verbatim, 2026-09-23, on bots at 60 keeping points they can't spend in
capped rows:

> Yeah. Usually this is another spec tho - like 2/3rds arms, 1/3rd fury. Or
> 2/3rds disc, 1/3rd shadow. Buddies never change their spec. There should
> also be a 1/3rd in each talent tree option. So we'll need to create "talent
> plans" for all of these permutations, and estimate which talents to pick
> based on theme analysis and also a double-pass scoring system that repeats
> continuously, increasing the score for talents that aren't picked as much,
> searching for an equilibrium where all talents are near equally chosen in
> all the permutations. The main abilities, the ones that require a single
> talent point, they should always be chosen, and if they have pre-requisites,
> those prerequisites should also always be chosen as well.

## Current Behavior

Bots follow premade talent orders from `playerbots.conf` (parsed into
`parsedSpecLinkOrder` and spent by `PlayerbotFactory`), written for full
WotLK trees. Under basic's cap (155g) the deep rows are refused and those
points stay unspent.

## Intended Behavior

- **Plan shapes**, per class, for the 51 points of a level-60 character in
  trees capped at tier 6 (capstone only):
  - two-thirds / one-third in every ordered pair of trees (6 per class);
  - one-third in each tree (1 per class).
- **Always taken**: every talent that is a single-point ability (grants a
  spell), and its prerequisites.
- **The rest is chosen by a generator**, not by hand:
  1. a theme score per talent for its plan (what the plan's trees are for);
  2. a balancing pass that, run repeatedly, raises the score of talents
     picked rarely across all plans and lowers the often-picked ones, until
     picks settle near an equilibrium where every talent is chosen about
     equally often across the permutations.
- **Buddies never change spec**: a buddy gets one plan at creation (617a) and
  keeps it for life; its points are spent by that plan as it levels.
- Output: talent orders in the bot module's own config format, so the
  module spends them unchanged.

## Suggested Implementation Steps

1. Read the capped trees (client `Talent.dbc`, `TalentTab.dbc`) into a
   generator (LuaJIT, the project's generator style).
2. Mark always-taken talents (single-point spells + prerequisites).
3. Theme scores: a first pass from the tree each talent is in and what
   it modifies; refine by hand where needed.
4. Balancing loop to equilibrium; print how evenly talents are used.
5. Emit per-class plans in `playerbots.conf` syntax, installed by a config
   patch for basic.

## Related Issues

- **155g** the talent cap; **617a** buddy creation (plan chosen there);
  **617** parent

## Open Questions

- **How is a buddy's plan chosen?** Random, or matched to what the owner's
  group lacks?
- **Random (non-buddy) bots**: same plans, or keep stock orders?
