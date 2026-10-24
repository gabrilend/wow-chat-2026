# 173b3 - Key Bindings

*Continues in the W client (`/mnt/kaun/custom-client/`), since the move on 2026-10-07 (173v): issue 1001. This issue stays as the record of how the client began; its paths are as they were then.*

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store)
- Related: 173m (camera actions), 173a (today's fixed keys)
- Priority: Low (owner, 2026-10-06: "Don't worry about keybindings for
  now. We don't really have anything to change except movement. We'll
  build keybinds when we build the action bar.")
- Built with: the action bar (173b10)

## Origin

See 173b (the owner's words, 2026-10-06: "things like UI, camera,
keybinds, etc.").

## Current Behavior

Not built. Keys are fixed in the source: W/Up forward, S/Down back, A/Left
and D/Right turn (strafe while the right button is held), Q and E strafe
left and right, Space jump, the keypad's / toggles walking (173i), Escape
quit, both mouse buttons forward.
(Until 2026-10-06 q quit and there was no strafe left.)

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

**The quit key.** Escape quits until the Escape pop-up exists (173b2),
then Escape opens it and quitting is its *Quit Game*. Q strafes left, as
in the original (owner, 2026-10-06: "Just have esc quit the game until we
build menus").

**Actions arrive with their features.** Each feature adds its own actions
to the table when it is built: movement now, camera with 173m, action bars
and targeting with the interface. An action from the list with no feature
yet is not shown.

**The rebinding screen** (drawn by 173b2): the sections and their actions,
each with two key buttons; click one, press a key, and it is bound. A key
already bound elsewhere is taken from the other action, and the screen
says which.

**Per character and global** (owner, 2026-10-06: "yes, though we should be
able to edit them globally as well"): there is one global set, and each
character may keep its own set on top of it. A character's set holds only
the bindings that differ from the global set. The screen has a switch
between editing *this character's* bindings and editing the *global*
ones. Changing a global binding changes it for every character that
hasn't overridden that action. Characters are identified by realm and
name once the client logs in; until then there is only the global set.

**Saved** in the settings file's binding lines, in the shape of the
original's `bindings-cache.wtf` (`bind W MOVEFORWARD`).

## Suggested Implementation Steps

1. The action table and the key-to-action lookup; the mover reads actions.
   A test: rebinding MOVEFORWARD to Up and pressing Up moves her forward,
   and pressing W does not.
2. Escape quits and Q strafes left (done 2026-10-06, as fixed keys,
   before the table exists).
3. Per-character sets over the global set, with a test: a character's
   override wins, and a global change reaches every character without
   one.
4. Camera actions with 173m.
5. The rebinding screen with 173b2.

## Open Questions

None. (Answered 2026-10-06: Escape quits for now; bindings are per
character over a global set.)
