# 155z14 - Crowd Control Without Diminishing Returns

## Status
- Created: 2026-10-26
- Phase: 1
- Parent: 155 (the basic profile)
- Related: patch B060 (`patches/B060-no-crowd-control-diminishing.sh`),
  B031 (crushing blows late: another combat rule of basic's)
- Priority: Medium
- State: built 2026-10-26, not yet seen in game

## Origin

The owner, 2026-10-26:

> we should disable the stunlock protection rules. If players want to
> throw out that much CC, well, the other side deserves it. This should
> not apply

## Current Behavior

Built 2026-10-26 as patch B060 (basic), compiled with the next build; not
yet seen in game. The server's one function that shortens crowd control
(`Unit::ApplyDiminishingToDuration`, `Unit.cpp`) returns "full length" at
its start for every kind of crowd control except taunts, so neither rule
below applies on basic:

- **Diminishing returns**: in stock 3.3.5 a second stun (or fear, or
  root... each kind its own group) on the same target within 15 seconds
  lasts half as long, a third a quarter, and the fourth does not land (the
  target is immune until 15 seconds pass).
- **The PvP cap**: crowd control from a player on a player (or a pet's)
  lasts at most 10 seconds (patch 2.2.0's rule).

The counting still happens (the target's diminishing level goes up as
before); nothing reads it but taunts.

**Taunts are left as they are**: their diminishing applies only to
creatures marked for it (bosses that grow resistant to repeated taunts),
a tank's rule, not stun protection.

## Intended Behavior

- On basic, every stun, fear, root, silence, polymorph and other crowd
  control lasts its full length however often it is cast on the same
  target, by players or by monsters, and a player's crowd control on a
  player is not capped at 10 seconds.
- Taunt diminishing on creatures unchanged.

## Suggested Implementation Steps

1. A source patch (B060, basic) at the start of
   `Unit::ApplyDiminishingToDuration`: for every group but
   `DIMINISHING_TAUNT`, return 1.0 (full length) before the 10-second cap
   and the level table. Marker comments; the unpatch deletes them.
2. Seen in game: the same stun four times in a row on a player or a
   monster, each at full length.

## Open Questions

1. **Only basic?** Built for basic (the profile in play); the other
   profiles keep the stock rule. Should beta, vanilla or cc-test take it
   too?
