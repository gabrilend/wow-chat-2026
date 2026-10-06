# 173b16 - Features, Help and Languages

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store)
- Related: 719 (true ability tooltips)
- Priority: Low

## Origin

See 173b (the owner's words, 2026-10-06).

## Current Behavior

Not built. The client has no tooltips or tutorials.

## Intended Behavior

The original's last three Interface panels (reference page, *Interface* →
*Features*, *Help*, *Languages*):

**Help**
- *Enhanced Tooltips* (`UberTooltips`): the long form of each tooltip.
  With 719's tooltips.
- *Beginner Tooltips* (`showNewbieTips`), *Tutorials* (`showTutorials`),
  *Loading Screen Tips* (`showGameTips`): with those features, if built.
- *Display Lua Errors* (`scriptErrors`): the custom client runs no
  interface scripts. Its own error display is the client's error log, and
  this switch decides whether errors also show on screen.

**Features**
- *Use Equipment Manager* (`equipmentManager`), *Preview Talent Changes*
  (`previewTalents`): with the character and talent windows.

**Languages**
- *Locale* (`locale`): which language's archives the client reads its
  strings and voice files from (today fixed to enUS).
- *Use English Audio* (`useEnglishAudio`): English voices with another
  language's text.

**The original's Interface window also has an AddOns tab.** It is not
copied: the custom client has no addon system.

## Suggested Implementation Steps

1. Locale now. The archive reader already takes it as a parameter, so it
   only needs to be read from the store.
2. The rest with their features.

## Open Questions

None yet.
