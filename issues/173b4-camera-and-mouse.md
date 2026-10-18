# 173b4 - Camera and Mouse Settings

*Continues in the W client (`/mnt/kaun/custom-client/`), since the move on 2026-10-07 (173v): issue 1001. This issue stays as the record of how the client began; its paths are as they were then.*

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store, completed 2026-10-06)
- Built with: 173m (the camera)
- Priority: High

## Origin

See 173b and 173m (the owner's words, 2026-10-06).

## Current Behavior

**Built with 173m (2026-10-06):** in the store and read live:
- following style, Auto Follow Speed, Max Camera Distance;
- Follow Terrain, Water Collision, Smart Pivot;
- Mouse Look Speed, Invert Mouse.
Left: Head Bob (no first-person view yet), Mouse Sensitivity (no drawn
pointer yet), click-to-move and its camera style (not planned yet), and
the camera key bindings (with the action bar).

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
These wait for key bindings, which are built with the action bar.

**The zoom limit** (owner, 2026-10-06: "We will adjust as we go. So,
just pick a limit that seems fine"): a base of 20 yards, times *Max Camera
Distance*. The slider's top (2) gives 40 yards, today's fixed limit, and
its bottom (1) gives 20. The closest zoom stays 2 yards. These are tuning
numbers. Later changes go to `docs/balance-updates.md` with the reason.

## Suggested Implementation Steps

1. With 173m's steps: each setting declared in the same change as the
   behaviour that reads it, with a test of that behaviour at two values.

## Open Questions

None.
