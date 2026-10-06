# 173b14 - Buffs and Debuffs

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store), auras in the client
- Priority: Low

## Origin

See 173b (the owner's words, 2026-10-06).

## Current Behavior

Not built. The client shows no buffs or debuffs.

## Intended Behavior

The original's Buffs and Debuffs panel (reference page, *Interface* →
*Buffs and Debuffs*), built with the aura icons:

- *Buff Durations* (`buffDurations`): time left under each icon.
- *Dispellable Debuffs* (`showDispelDebuffs`): on friendly frames, only the
  debuffs this player can remove.
- *Castable Buffs* (`showCastableBuffs`): on friendly frames, only the buffs
  this player can cast.
- *Castable Debuffs* (`showCastableDebuffs`): on the target, only this
  player's own debuffs.
- *Consolidate Buffs* (`consolidateBuffs`): long-lasting buffs folded into
  one icon.

## Suggested Implementation Steps

1. With the aura icons.

## Open Questions

None yet.
