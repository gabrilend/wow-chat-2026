# 173m - The Camera

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: 173a (first light), 173b1 (the settings store)
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

Built in both clients (`src/custom-client-c/main.c`, its camera block;
`src/custom-client/main.lua`): the camera sits behind her at a distance
(starting 12 yards, the wheel zooms it), raised by a pitch angle, never
below the ground.
- Left drag turns the camera around her; she doesn't turn.
- Right drag turns the camera, and she turns to face where it faces. While
  right is held, A and D step sideways instead of turning.
- Both buttons held walk her forward.
- When she turns with A or D, the camera turns with her (unless left is
  held).

Missing: when she walks after a left-drag, the camera stays where it was
left. It never swings back behind her. There is one fixed behaviour and no
settings.

## Intended Behavior

**The two drags** (the stock game's):
- **Left drag orbits.** The camera turns round her on both axes (around
  and up/down). She doesn't move or turn. Letting go leaves the camera
  where it was put.
- **Right drag steers.** The camera turns, and she turns with it on the
  horizontal axis, so she always faces away from the camera. The vertical
  drag only pitches the camera. Pressing right after a left-drag first
  turns her to the camera's heading, as now.

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
reset), and *flip camera yaw* (look at her face). These are bindable
actions in the key-binding store (173b3), not fixed keys.

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
4. Add tests without a window (Lua and C twins, as `scripts/test-custom-client`
   and `tests/test_client.c` do): after a left drag of 90 degrees, one
   second of walking in style 1 brings the heading back by exactly the
   follow speed's worth and leaves the pitch unchanged; style 0 leaves
   both unchanged; a held button freezes every style.
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
