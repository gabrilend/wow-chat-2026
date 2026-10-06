# 173b5 - Video: Resolution

## Status
- Created: 2026-10-06
- Phase: 1
- Parent: 173b (the options menu)
- Blocked by: 173b1 (the settings store)
- Priority: Medium

## Origin

Verbatim, 2026-10-04 (the original 173b): "We should allow all
resolutions up to ultrawide. The user should be able to type in a value if
they want. Or there's a drop-down with common increments."

## Current Behavior

Not built. The window opens at 1280 x 720, can be resized by the window
manager, and asks for vsync.

## Intended Behavior

The original's Resolution panel (reference page, *Video* → *Resolution*):

- **Resolution:** typed in as width and height, or picked from a list of
  common sizes: 1280x720, 1920x1080, 2560x1080, 2560x1440, 3440x1440,
  3840x1080, 3840x2160, 5120x1440. The list also offers the sizes the
  display itself reports. Ultrawide (21:9 and 32:9) is allowed. The
  original offers only the display's own modes.
- **Refresh rate** (`gxRefresh`) and **Multisampling** (anti-aliasing;
  the original sets it by a program call, with no stored name).
- **Windowed Mode** (`gxWindow`), **Maximized** (`gxMaximize`), **Disable
  Resize** (`windowResizeLock`).
- **Vertical Sync** (`gxVSync`), **Triple Buffering** (`gxTripleBuffer`),
  **Reduce Input Lag** (`gxFixLag`), **Hardware Cursor** (`gxCursor`).
- **Use UI Scale** (`useUiScale`) and the scale (`uiscale`, 0.64 to 1):
  the size of the interface, independent of the window's.
- **Gamma** (`gamma`, -0.5 to 0.5) and **Use desktop gamma**
  (`desktopGamma`): brightness, done in the client's own shaders, not by
  changing the display.

Settings a graphics library can only set at start (multisampling, on
Raylib) are marked *restart*.

## Suggested Implementation Steps

1. Resolution, windowed and maximized from the store at start; the window
   size saved when the player resizes it.
2. Vsync and gamma, live.
3. UI scale when the interface exists (173c).

## Open Questions

None yet.
