# 173a - First Light: a Night Elf in Ashenvale

## Status
- Created: 2026-10-04
- Phase: 1
- Parent: 173 (the custom client)
- Blocked by: None
- Priority: Medium

## Origin

See 173 (the owner's words, 2026-10-04).

## Current Behavior

**Built 2026-10-05, first light** (`src/custom-client/`, a LÖVE program:
Lua on LuaJIT, 3D with a depth buffer and a small shader; run with
`scripts/custom-client`, checked with `scripts/custom-client --shot`, which
saves a picture and quits). It opens on Ashenvale's ground round
Astranaar, the 3 x 3 tiles round her loaded and drawn as she walks
(`lib/maps.lua` reads the server's map files; `lib/ground-mesh.lua` makes
the server's four triangles per cell, lit by the sun, coloured forest
floor to rock by steepness, fog in the distance), and a stand-in night elf
(a violet upright box 2.3 yards tall with a pale face) moved by the
game's controls at 120% (`lib/mover.lua`: run 8.4, back 5.4, turning half a
circle a second, jumps and falls by the game's gravity). Escape quits
(q until 2026-10-06; Q now strafes left, as in the game).
**Steep ground** (2026-10-05): no walking up ground steeper than the
server's own limit, read from the header of its navigation tiles
(`lib/navmesh-slope.lua`; 60 degrees in every tile built here), and
sliding down such ground as on a frictionless slope until she reaches
ground she can stand on. Steepness is the exact slope of the map triangle
she stands on (`lib/maps.lua` gives it with each height).
`scripts/test-custom-client` (22 checks) holds the ground and the movement
to their numbers without a window: Astranaar at 106.7 yards, no step where
tiles meet, a second's run 8.4 yards, a jump about 1.64 yards high, slopes
walked, cliffs fallen off.

Not yet: comparing heights with the running server point for point (the
server was down; it needs a console command or a Lua call reporting the
server's height at a point); the real night elf (173d). Window smoothing (multisampling) is off: with
it on, the `--shot` picture came out black.

## Intended Behavior

A window shows the ground of Ashenvale around Astranaar and a night elf
standing on it; the player moves her as in the game, and she walks on the
same ground the server walks on:

- **The ground** is the server's own (`data-files/maps/*.map`, the grids
  the server reads for heights): each 533-yard grid's 129 x 129 corner
  heights and 128 x 128 centre heights, drawn as the server's four
  triangles per cell, so the drawn ground and the height the server
  computes agree.
- **Her height** is worked out exactly as the server does (the same
  triangle choice and plane formula).
- **Controls**, the game's: W forward, S back, A and D turn (strafe while
  the right mouse button is held), Q and E strafe left and right, space
  jump, left mouse drag to turn the camera, right mouse drag to turn her
  and the camera, wheel to zoom; **Escape quits** until the game menu
  exists (owner, 2026-10-06; first light used q, which the game uses to
  strafe left).
- **Speeds**, the game's base speeds at 120%: run 7 x 1.2 = 8.4 yards a
  second, back 4.5 x 1.2 = 5.4, turning pi radians a second; gravity
  19.29 yards a second squared, a jump's lift 7.96.
- **Steep ground**: she can't walk up ground steeper than the server's
  navigation limit, and slides down it when she stands on it (owner,
  2026-10-05: "when they're too steep, you should start falling, using
  the same rules that the server uses").
- **Done means** (owner, 2026-10-05): "if the server accepts the movement
  packs without correcting, then we have a client that handles movement
  correctly. We're trying to render the world exactly as it's expected to
  render in the proprietary client." So the measure of movement is a
  connected client whose movement the server never corrects, and the
  measure of drawing is the original client's picture.
- She is drawn as a stand-in shape (a night elf's height, about 2.3
  yards) until models come (173d).

## Suggested Implementation Steps

1. The map reader: a `.map` file's header, its height block (float,
   int16 or int8 heights), holes; a test against the server's own height
   rule at sample points.
2. The ground mesh for the grids around her, rebuilt as she crosses grids.
3. The camera and the controls; her movement and gravity on the ground.
4. A run script.

## Open Questions

1. (Answered 2026-10-05) Slopes: now ("Sure. Also, when they're too
   steep, you should start falling, using the same rules that the server
   uses"). The server's rule is its navigation mesh's 60 degrees. The
   original game client has its own limit, which I believe is nearer 50
   degrees but have not measured. Since the client decides movement and
   the server does not check slopes, the two can differ without the
   server correcting anyone. Should the client follow the original
   client's limit instead, once it is measured?
