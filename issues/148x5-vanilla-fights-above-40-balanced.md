# 148x5 - Vanilla: Fights Above 40 Balanced for Level-40 Groups

## Status
- Created: 2026-10-27
- Phase: 1
- Parent: 148x
- Blocked by: 148x2, 148x4
- Related: 155f1 (basic's level-60 fights balanced: the method and its
  measuring tools), 155i (the multiplier table), 803 (level-gap caps)
- Priority: Medium
- State: plan only

## Current Behavior

Nothing measured for vanilla. Basic's measures (155f1) read each boss's
health, melee and spells against a geared level-60 tank.

## Intended Behavior

- **The same targets as basic's dungeons** (the owner, for basic,
  2026-10-25): an unhealed tank dies in about 10 to 15 seconds, and no
  single hit, crit included, is bigger than the tank's health. Here the
  tank is a level 40 in 148x3's gear for that rung.
- **The level gap is capped** where a creature far above the group would
  otherwise never be hit or always crush (803's caps, extended to the
  vanilla profile's levels).
- **Every value from a tool**: the measuring tool, given the profile and
  the tank's level and gear, writes the multiplier rows, each with a
  comment saying why; changes logged in `docs/balance-updates.md`.
- **The check of the whole of 148x**: Ragnaros measured against a level-40
  raid, and the numbers shown to the owner.

## Suggested Implementation Steps

1. Basic's measuring tool given a profile, a tank level and a gear budget.
2. Its rows for vanilla's dungeons and raids, by rung.
3. A quick test that every boss above 40 has a row, and that Ragnaros's
   numbers fall inside the targets.

## Open Questions

- None of its own yet; it follows 148x's.
