# 173b4 - Camera and Mouse Settings

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store)
- Built with: 173m (the camera)
- Priority: High

## Origin

See 173b and 173m (the owner's words, 2026-10-06).

## Current Behavior

Not built. The camera's numbers are fixed (see 173m).

## Intended Behavior

The original's Camera and Mouse panels (reference page, *Interface* →
*Camera* and *Mouse*), declared in the store when 173m builds the
behaviour each controls:

**Camera panel**
- *Following style* (`cameraSmoothStyle`): Only horizontal when moving (1,
  the owner's default), Only when moving (4), Always adjust camera (2),
  Never adjust camera (0). The camera's table of styles (173m).
- *Auto Follow Speed* (`cameraYawSmoothSpeed`), 90 to 270 degrees a second,
  step 10: how fast a style swings the camera back.
- *Max Camera Distance* (`cameraDistanceMaxFactor`), 1 to 2, step 0.1: the
  zoom-out limit, as a multiple of the base limit.
- *Follow Terrain* (`cameraTerrainTilt`), *Water Collision*
  (`cameraWaterCollision`), *Smart Pivot* (`cameraPivot`), *Head Bob*
  (`cameraBobbing`): toggles; what each does is in 173m.

**Mouse panel**
- *Mouse Look Speed* (`cameraYawMoveSpeed`), 90 to 270, step 10: how fast a
  drag turns the camera.
- *Invert Mouse* (`mouseInvertPitch`).
- *Mouse Sensitivity* (`mouseSpeed`), 0.5 to 1.5: the pointer's own speed
  when it isn't dragging the camera. This applies only if the client draws
  its own pointer.
- *Click-to-Move* (`autointeract`) and its camera style
  (`cameraSmoothTrackingStyle`, the same four styles): arrive with
  click-to-move, which isn't planned yet.
- *Detect World of Warcraft Gaming Mouse* (`enableWoWMouse`): not copied.
  Any mouse's extra buttons are bindable keys in 173b3.

**Camera key bindings** (Camera Functions, 173b3): zoom in and out, next
and previous view, five saved views (set, save, reset), flip camera yaw.

## Suggested Implementation Steps

1. With 173m's steps: each setting declared in the same change as the
   behaviour that reads it, with a test of that behaviour at two values.

## Open Questions

1. **The base zoom limit.** The original's limit, before the 1-to-2
   factor, is kept inside its program. The custom client zooms out to its
   own limit (`ZOOM_MAX`). Keep that limit, or measure the original's?
