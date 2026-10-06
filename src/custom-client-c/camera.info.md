# camera

*Written by `scripts/generate-custom-client-info` from `camera.h`; don't edit, re-run it.*

camera.h (issue 173m) - the camera that follows her

For a general audience: the camera sits behind the character at a
distance, raised by an angle. The mouse moves it as the original game's
does: dragging with the left button looks around her without turning
her, and dragging with the right button turns her with the camera. On
its own, the camera drifts back behind her by one of several
"following styles", the original's four first. Each style is a row in
a table, chosen by the setting cameraSmoothStyle, so more can be added
as rows. It drifts at a steady turning speed (the setting
cameraYawSmoothSpeed) and never snaps.

Nothing here draws or reads the mouse: main.c hands in what the mouse
and the mover did this frame, so tests can drive it without a window.

A FollowCam (named so beside Raylib's own Camera), field by field:
  yaw         float, radians: the direction the camera looks along,
              measured as her facing is (0 = east, counter-clockwise);
              not wrapped, so only differences matter
  pitch       float, radians: how far above her the camera is raised,
              from CAMERA_PITCH_MIN (below her shoulders) to
              CAMERA_PITCH_MAX (nearly overhead)
  dist        float, yards: how far back from her it sits
  rest_pitch  float, radians: the pitch styles 4 and 2 drift back to

A FollowCamInput, field by field (all for this frame only):
  left, right   int, 0 or 1: the mouse buttons held
  dx, dy        float, pixels: how far the mouse moved
  dt            float, seconds: the frame's length

## What it offers

- `type FollowCam`
- `type FollowCamInput`
- `void camera_drag(FollowCam *c, const FollowCamInput *in, int was_right, double *facing);`
  The mouse's part, before she moves this frame. Left drag turns only the
  camera; right drag turns the camera, and sets `*facing` (her facing,
  radians) to the camera's heading. The first frame of a right drag turns
  her to where the camera already looks, as the original does after a
  left drag. Reads cameraYawMoveSpeed and mouseInvertPitch. `was_right`
  is whether the right button was held last frame.
- `void camera_follow(FollowCam *c, const FollowCamInput *in, double turned, int moving, double facing);`
  The camera's own part, after she moves this frame. `turned` is how far
  (radians) the keys turned her this frame: the camera turns with her
  unless the left button holds it. `moving` is whether she moved along
  the ground this frame (now, not "started moving": letting go of a drag
  mid-run starts the drift that same frame; owner, 2026-10-06). `facing`
  is her facing after the move. While either button is held no style
  moves the camera. Reads cameraSmoothStyle and cameraYawSmoothSpeed.
- `void camera_tilt(FollowCam *c, const FollowCamInput *in, int moving, float slope);`
  Follow Terrain (cameraTerrainTilt, 173m): while she moves along the
  ground, the camera's pitch drifts (at the follow speed) toward its rest
  less the slope's angle ahead of her (`slope`: rise per yard along her
  facing), so climbing tilts it up and descending down. Off, or still:
  nothing. Not while a button holds the camera.
- `float camera_turn_between(float from, float to);`
  The angle from `from` to `to` the shorter way round, in -pi to pi.
