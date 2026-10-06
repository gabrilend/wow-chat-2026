# 173b1 - The Settings Store

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: None
- Blocks: 173m (the camera), and every other 173b sub-issue
- Priority: High

## Origin

See 173b (the owner's words, 2026-10-06): settings are added "as soon as
we're working on the feature, rather than in some later pass where we've
already built out infrastructure that's too rigid and has to be
refactored."

## Current Behavior

Not built. Every number the client uses is fixed in its source: the
window's 1280 x 720, the run speed, the drag rate of 0.006 radians a pixel,
the zoom limits, the keys.

## Intended Behavior

One place where every setting is declared, and one file where the
player's choices are kept.

**A declaration** is one row in a single table, in code (configuration in
structure, as the house style asks), with these fields:

| Field | Type | Meaning |
|---|---|---|
| name | text | the stored name, the original's where it is the same setting (`cameraSmoothStyle`, `farclip`); a project name otherwise |
| section | text | the menu panel it appears in (`Camera`, `Effects` ...), from the reference page's panel names |
| kind | one of: toggle, slider, choice, text, key | toggle = on/off; slider = a number in a range; choice = one of a list; text = typed in (a resolution); key = a bound key (173b3) |
| default | number or text | the value before the player changes it |
| min, max, step | numbers (sliders only) | the range, as the original's when it has one |
| choices | list of {label text, stored value} (choices only) | in the order shown |
| label, explanation | text | the words in the menu and its tooltip, the original's where they apply |
| applies | one of: live, restart | live = read again every time it is used; restart = read once at start (a window mode a library can only set at start) |

**Reading** a setting is a lookup by name that returns its current value.
Code asks for it each time it uses it (each frame, for the camera), so a
change takes effect at once. No code copies a setting into its own
variable at start, unless the setting is marked `restart`. An unknown name
is an error that names the setting and the file asking for it. It never
silently returns a default.

**Saving:** the player's changes go to one plain text file, one
`name value` per line, in the same shape as the original's
`WTF/Config.wtf` (`SET cameraSmoothStyle "1"`), kept beside the client's
other per-player files. Only values that differ from the default are
written. On load, a line naming an unknown setting, or holding a value out
of its range, is reported by name and line number and skipped. The
report is never silent.

**Both clients** (Lua and C) declare the same table. A test holds the two
tables to the same names, kinds, ranges and defaults.

## Suggested Implementation Steps

1. The declaration table and the lookup, in Lua first, then its C twin.
2. Load and save the file. Tests: a round trip keeps every non-default
   value; a bad line is reported with its line number; an unknown name
   asked for by code fails loudly.
3. Move the client's existing fixed numbers that are settings (window
   size, zoom limits, drag rate) into the table, as the first rows.
4. A test comparing the Lua and C tables.

## Open Questions

1. **Where the file lives.** Beside the client in the project
   (`tmp/shared-memory/` is RAM and is lost at reboot, so not there), or in
   the player's home (`~/.config/everland-ghostsong/`)?
