# 173b10 - Action Bars

*Continues in the W client (`/mnt/mtwo/games/azeroth-core/custom-client/`), since the move on 2026-10-07 (173v): issue 1001. This issue stays as the record of how the client began; its paths are as they were then.*

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store), action bars in the client (not
  yet an issue)
- Priority: Low

## Origin

See 173b (the owner's words, 2026-10-06).

## Current Behavior

Not built. The client has no action bars.

## Intended Behavior

The original's ActionBars panel (reference page, *Interface* →
*ActionBars*), built with the bars:

- Which extra bars show: *Bottom Left*, *Bottom Right*, *Right*, *Right
  Bar 2* (`bottomLeftActionBar` ... `rightTwoActionBar`).
- *Lock ActionBars* (`lockActionBars`): abilities can't be dragged off by
  accident.
- *Always Show ActionBars* (`alwaysShowActionBars`): empty slots stay
  visible.
- *Secure Ability Toggle* (`secureAbilityToggle`): a second press of a
  toggled ability within a moment doesn't turn it back off.

Their key bindings are 173b3's *Action Bar* and *MultiActionBar* sections.

## Suggested Implementation Steps

1. With the action bars.

## Open Questions

None yet.
