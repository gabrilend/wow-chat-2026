# 173m - The Camera

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173a (first light), 173b1 (the settings store, completed 2026-10-06)
- Settings: 173b4 (camera and mouse settings, camera key bindings)
- Related: 617s7 (box select also wants a left-button drag; it waits
  until the original's behaviour is rebuilt)
- Priority: High

## Origin

Verbatim, 2026-10-06:

> Can we also add to the list to make the camera work correctly? There
> should be two scrolling modes - left click and drag, and right click and
> drag. Right click should turn the character, while left-click just orbits
> the camera. When the character moves, we should spin the camera back to
> behind, but only on the horizontal axis. Let's make room for multiple
> behaviors here though because there's several camera options.

## Current Behavior

**The drags and the following styles are built (2026-10-06)**, in C,
in `src/custom-client-c/camera.h` and `camera.c`, with 21 checks in
`tests/test_client.c` (75 in the program, all passing).
- **The camera is its own module.** `main.c` hands it this frame's mouse
  (buttons and movement), how far the keys turned her, whether she moved
  along the ground, and her facing. It gives back the camera's heading,
  pitch and distance (and her facing, for a right drag). It never touches
  the window, so the tests drive it directly.
- **Left drag** turns only the camera. **Right drag** turns her with it.
  Pressing right turns her to where the camera looks. First light did
  the reverse: it snapped the camera behind her, unlike the original.
- **Following styles** are a table in `camera.c`, one row per
  `cameraSmoothStyle` value (1, 4, 2, 0), each a one-line rule. The
  setting's choices in `settings.c` must match the rows, and the client
  stops if they ever don't.
- **"Moving"** is measured, not guessed from keys: she moved along the
  ground this frame (keys, both buttons, or sliding). Turning in place
  isn't moving; the keys' turning already carries the camera round.
- **Settings now in the store:** Camera Following Style
  (`cameraSmoothStyle`, default 1), Auto Follow Speed
  (`cameraYawSmoothSpeed`, 180), Invert Mouse (`mouseInvertPitch`, off),
  Mouse Look Speed and Max Camera Distance (from 173b1).

**Not built yet:** Follow Terrain, Water Collision (there's no water yet),
Smart Pivot, Head Bob (there's no first person or walking animation yet),
the saved views and the other camera key bindings (they wait for key
bindings, 173b3).

## Intended Behavior

**The two drags** (the stock game's):
- **Left drag orbits.** The camera turns round her on both axes (around
  and up/down). She doesn't move or turn. Letting go leaves the camera
  where it was put.
- **Right drag steers.** The camera turns, and she turns with it on the
  horizontal axis, so she always faces away from the camera. The vertical
  drag only pitches the camera. Pressing right after a left-drag first
  turns her to the camera's heading.

**Following styles.** What the camera does on its own while she moves is
one of several *following styles*. Each style is an entry in a table of
behaviours, looked up by name, and each answers one question per frame:
given where the camera is, where she is facing, and whether she is moving,
where should the camera's heading and pitch drift toward? The table starts
with the original's four (its Camera panel drop-down, stored as
`cameraSmoothStyle`):

| Style | Stored value | While she moves | While she stands |
|---|---|---|---|
| Only horizontal when moving (the owner's choice for the default) | 1 | the heading swings back behind her; the pitch stays where it was put | stays put |
| Only when moving | 4 | the heading swings back behind her, and the pitch returns to its resting angle | stays put |
| Always adjust camera | 2 | swings back behind her | also swings back |
| Never adjust camera | 0 | stays put | stays put |

The swing is a turn at a fixed rate, *Auto Follow Speed*: 90 to 270 degrees
a second, set in steps of 10. It never snaps. A drag in progress always
beats the swing: while either button is held, no style moves the camera.

**"Moving" means moving now**, not "started moving" (owner, 2026-10-06:
"it should spin behind her once you let go"). If she is running while you
hold the left button to look at her face, the swing starts the moment you
let go, mid-run. It doesn't wait for her to turn, or to stop and start
again. Each frame, a style asks only "is she moving this frame, and is a
button held?", and keeps no memory of when the movement began.

More styles can be added later as new rows (the owner, 2026-10-06:
"there's several camera options"). Click-to-move's own camera style
(`cameraSmoothTrackingStyle`, the same four choices) uses the same table.

**What the other camera settings mean for this code** (each one is read
from the settings store by name, so changing it takes effect the next
frame; see 173b4 for the full list):
- *Mouse Look Speed* (90 to 270): how fast a drag turns the camera,
  replacing today's fixed 0.006 radians per pixel.
- *Invert Mouse*: flips which way up/down drags pitch.
- *Max Camera Distance* (factor 1 to 2): how far the wheel can zoom out.
- *Follow Terrain*: pitch tilts up on uphill ground and down on downhill.
- *Water Collision*: the camera stays on her side of the water's surface.
- *Smart Pivot*: when the camera touches the ground, pitching further
  slides it along the ground and looks up, instead of stopping.
- *Head Bob*: in first person (zoomed all the way in), the view bobs with
  her steps.

**Camera key bindings** (the original's Camera Functions section): zoom
in and out, the next and previous view, five saved views (set, save,
reset), and *flip camera yaw* (look at her face). These wait for key
bindings (173b3), which are built with the action bar.

## Suggested Implementation Steps

1. Move the camera's state (heading, pitch, distance, which drag is held)
   into one plain structure that the main loop hands to the camera code
   each frame.
2. Split the drags out: left changes only the camera; right also sets her
   facing. Both drags read *Mouse Look Speed* and *Invert Mouse*.
3. Add the following-style table with the four stock styles, chosen by the
   `cameraSmoothStyle` setting, defaulting to 1. Each style is one small
   function that returns the heading and pitch to drift toward. The swing
   turns toward that target at *Auto Follow Speed*, taking the shorter way
   round the circle.
4. Add tests without a window (in C only, in `tests/test_client.c`; the
   Lua client is deprecated): after a left drag of 90 degrees, one second
   of walking in style 1 brings the heading back by exactly the follow
   speed's worth and leaves the pitch unchanged; style 0 leaves both
   unchanged; a held button freezes every style; letting go mid-run starts
   the swing that same frame.
5. Add the remaining camera settings, one at a time, each with a test.

## Decisions

- **Left drag belongs to the camera**, as in the original. Box select
  (617s7) is a new feature and waits until the original's behaviour is
  rebuilt (owner, 2026-10-06: "let's focus on re-implementing the
  original client before we build new features").
- **Defaults are this client's own.** The original's defaults aren't
  looked up (owner, 2026-10-06: "Don't worry too much about what the
  defaults on the original client are"). Style 1 is the default because
  the owner asked for it.

## Open Questions

None.
