# 173b8 - Controls and Combat

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store), the client talking to the
  server (not yet an issue: targeting, loot and combat need it)
- Priority: Low

## Origin

See 173b (the owner's words, 2026-10-06).

## Current Behavior

Not built. The client has no targeting, loot or combat.

## Intended Behavior

The original's Controls and Combat panels (reference page, *Interface* →
*Controls*, *Combat*), each built with the feature it changes:

**Controls**
- *Sticky Targeting* (`deselectOnClick`): clicking empty ground doesn't
  clear the target. With targeting.
- *Auto Loot* (`autoLootDefault`) and *Auto Loot Key* (`autoLootKey`:
  Alt, Ctrl, Shift or none, the key that flips it for one click). With
  loot.
- *Open Loot Window at Mouse* (`lootUnderMouse`). With the loot window.
- *Auto Dismount in Flight* (`autoDismountFlying`), *Auto Clear Away*
  (`autoClearAFK`), *Block Trades* (`blockTrades`). With mounts, chat and
  trade.

**Combat**
- *Auto Self Cast* (`autoSelfCast`), and the *Self Cast Key* and *Focus
  Cast Key* (Alt, Ctrl, Shift or none). With spell casting.
- *Attack on Assist* (`assistAttack`), *Auto Attack/Auto Shot*
  (`autoRangedCombat`), *Stop Auto Attack* when the target changes
  (`stopAutoAttackOnTargetChange`). With combat.
- *Target of Target* (`showTargetOfTarget`) and when to show it
  (`targetOfTargetMode`: Raid, Party, Solo, Raid & Party, Always). With
  the target frame.
- *Cast bars* on targets (`showTargetCastbar`) and on nameplates
  (`showVKeyCastbar`); *Class Colors in Nameplates*. With unit frames and
  nameplates.

## Suggested Implementation Steps

1. Each setting in the same change as its feature.

## Open Questions

None yet.
