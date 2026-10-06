# 173b2 - The Options Screen

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store), 173c (interface pieces by name)
- Priority: Medium

## Origin

See 173b. The original 173b text (2026-10-04) asked for the window size
"typed in" or picked from "a drop-down with common increments"; that
setting is now 173b5's, drawn by this screen.

## Current Behavior

Not built. The client has no menu; Escape quits.

## Intended Behavior

**Escape opens a small pop-up** (owner, 2026-10-06: "esc should open up a
small pop-up where you can click "settings" or "quit game""): Settings,
which opens the settings windows, and Quit Game. Further entries (the
original's Key Bindings, Macros, Help, Logout) join it with their
features. Escape again closes the top window. Until this exists, Escape
quits. The menu's look waits on menu design, which hasn't started.

**Each settings window** (Video, Sound & Voice, Interface) has its panel
list on the left (the original's order, from the reference page) and the
chosen panel on the right. **Okay** keeps the changes and saves them.
**Cancel** puts back what was there when the window opened. **Defaults**
resets this panel (or, as the original asks, all panels) to their declared
defaults.

**Panels are built from the store, not drawn by hand.** For a section, the
screen lists the store's settings in declaration order and draws each by
its kind: a tick box for a toggle, a slider showing its value for a slider,
a drop-down for a choice, a typing field for text, a key button for a key.
The label sits beside it and the explanation shows on hover. A setting
added to the store appears here with no screen code. A setting marked
*restart* says so in its explanation, as the original does.

**Live settings change as the control moves.** Dragging Auto Follow Speed
changes the camera behind the window at once; Cancel undoes it.

## Suggested Implementation Steps

1. The game menu and an empty window with the panel list, built with
   173c's pieces.
2. One control per kind, each tested on its own (a slider snaps to its
   step and stays in range).
3. A panel built from the store's rows for its section.
4. Okay / Cancel / Defaults over a copy of the values taken when the
   window opened.

## Open Questions

None yet.
