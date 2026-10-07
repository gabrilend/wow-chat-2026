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

**Built 2026-10-06 and 2026-10-07** (in the settings store's table,
`settings.c`, section "Resolution", and `main.c`):
- **Resolution** (`gxResolution`, typed as WIDTHxHEIGHT, 640x480 to
  7680x4320, ultrawide included; default 1280x720): the window opens at
  it. No list to pick from yet (that is the menu, 173b2).
- **Windowed Mode** (`gxWindow`, on) and **Maximized** (`gxMaximize`,
  off): read when the window opens (Raylib chooses fullscreen and borders
  then, so both are marked *restart*). Off, Windowed Mode opens
  fullscreen at the resolution; Maximized opens the window maximized
  without borders. Tried: a maximized start opens and draws.
- **Vertical Sync** (`gxVSync`, on) and **Disable Resize**
  (`windowResizeLock`, off): applied at start and live, so a change from
  the menu takes effect at once.
- **The window's size is kept:** resized by the player in a plain window
  (not maximized, not fullscreen), its size becomes the resolution and is
  saved into the settings file on quitting (pictures never save). The
  save rewrites the file with every setting that differs from its
  default, so comments in a hand-edited file are not kept. Not yet tried
  by a real quit: no window-automation tool is installed here, so this
  needs one quit by hand (resize the window, press Escape, look at
  `src/custom-client-c/settings/Config.wtf`).
- **Tests:** the new settings' defaults and which need a restart.

**Not built:**
- Refresh rate (`gxRefresh`) and Multisampling: Raylib picks the
  display's own rate, and offers only 4x multisampling, at start.
- Triple Buffering (`gxTripleBuffer`), Reduce Input Lag (`gxFixLag`),
  Hardware Cursor (`gxCursor`): Raylib and its OpenGL setup give no
  control of these.
- Gamma (`gamma`, `desktopGamma`): see the open question.
- UI scale (`useUiScale`, `uiscale`): waits for the interface (173c).

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

1. **Gamma's curve.** The original's Gamma slider (-0.5 to 0.5) changes
   the display's own gamma ramp; this client would do it in its shaders
   instead, as the intended behavior says. Which curve should the slider
   drive: each colour raised to the power 1 / (1 + gamma) (so +0.5
   brightens the dark parts most), or something matched by eye against
   the original at a few slider positions?
