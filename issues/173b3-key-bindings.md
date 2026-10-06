# 173b3 - Key Bindings

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store)
- Related: 173m (camera actions), 173a (today's fixed keys)
- Priority: High

## Origin

See 173b (the owner's words, 2026-10-06: "things like UI, camera,
keybinds, etc.").

## Current Behavior

Not built. Keys are fixed in the source: W/Up forward, S/Down back, A/Left
and D/Right turn (strafe while the right button is held), E strafe right,
Space jump, q quit, both mouse buttons forward. There is no strafe left key
(Q quits instead).

## Intended Behavior

**Code asks for actions, never keys.** The mover asks "is MOVEFORWARD
held?", not "is W held?". A table maps keys (and mouse buttons, and
modifier combinations such as Shift-1) to action names. The action names
are the original's (`MOVEFORWARD`, `STRAFELEFT`, `CAMERAZOOMIN`,
`FLIPCAMERAYAW` ...), so its list is the plan. The reference page lists all
275 actions in its 13 sections (Movement, Chat, Action Bar, Targeting,
Interface Panel, Miscellaneous, Camera, MultiActionBar, Raid Targeting,
Vehicle, and the original's totem, iTunes and movie-recording sections).

**Each action has two keys**, as in the original (a primary and a
secondary). The defaults are the original's (W A S D, Q and E strafe, Space
jump, and so on), typed into the table because the original keeps them
inside its program, not in its interface files.

**The quit key.** Q is strafe left in the original. The custom client's
temporary "q quits" moves to the game menu's Exit (173b2). Until that
exists, it moves to a key the original leaves unbound, so Q can strafe.

**Actions arrive with their features.** Each feature adds its own actions
to the table when it is built: movement now, camera with 173m, action bars
and targeting with the interface. An action from the list with no feature
yet is not shown.

**The rebinding screen** (drawn by 173b2): the sections and their actions,
each with two key buttons; click one, press a key, and it is bound. A key
already bound elsewhere is taken from the other action, and the screen
says which. "Character specific" bindings (the original's tick box) are an
open question.

**Saved** in the settings file's binding lines, in the shape of the
original's `bindings-cache.wtf` (`bind W MOVEFORWARD`).

## Suggested Implementation Steps

1. The action table and the key-to-action lookup; the mover reads actions.
   A test: rebinding MOVEFORWARD to Up and pressing Up moves her forward,
   and pressing W does not.
2. Give Q to strafe left and move quit to an unbound key, until the game
   menu exists.
3. Camera actions with 173m.
4. The rebinding screen with 173b2.

## Open Questions

1. **Which key quits** until the game menu exists? (The original binds
   nothing to F10 or to Shift-Escape.)
2. **Character-specific bindings** (the original lets each character keep
   its own set): wanted, or one set for the player?
