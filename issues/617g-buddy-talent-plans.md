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

### Decision, 2026-09-25 (Ritz): one profile, random talents within it

"we might have to say that bots will randomly select their talents up to a
certain amount in each tree, always prioritizing the ones that have 1
talent point cost, and they can be re-randomly chosen whenever the player
respecs. [...] Also I kinda want them to pick one profile and stick with
it - so if they're a holy paladin, they'll always be a holy paladin, but
the exact talents they choose can be randomly picked every time you
re-roll. Is that terrible?"
- A buddy's **profile** (how many points go in each tree, e.g. two-thirds
  holy and one-third protection) is fixed for life, as before.
- Within it, **talents are picked at random**, single-point abilities
  first, each tree filled up to its amount.
- **Re-rolled when the owner respecs**: the buddy's talents are drawn again
  within the same profile.
- This replaces the generator's balancing pass as the way talents are
  chosen; the plan shapes (the per-tree amounts) stay.
- Removed from basic alongside: dual spec; and the gold cost of a respec
  grows without a cap and comes down over time (155r).

### Decision, 2026-09-25 (Ritz): random profiles, a tank and a healer guaranteed

"random, but each clan is guaranteed at least one tank, and one healer."
- A buddy's profile is drawn at random at creation.
- **Guarantee**: a clan's buddies always include at least one tank and
  one healer; the owner's class is ignored ("the owner's class is
  ignored"). When a buddy is created while the buddies
  lack one, its draw is limited to profiles that fill the missing role
  (tank first, then healer) if its class can fill it; a random class draw
  at Sargobras (617b) is likewise limited to classes that can.
- Tank profiles: most points in protection (warrior, paladin), feral
  (druid, the bear side) or a death knight tree played as a tank. Healer
  profiles: most points in holy or discipline (priest), holy (paladin),
  restoration (shaman, druid). The exact list is for the generator.

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

- (Answered 2026-09-25) Random, with at least one tank and one healer
  guaranteed per clan (see the decision above).
- (Answered 2026-09-25) The owner doesn't count ("the owner's class is
  ignored"): the buddies alone always include a tank and a healer.
- **Random (non-buddy) bots**: same plans, or keep stock orders?
