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
circle a second, jumps and falls by the game's gravity). q quits.
`scripts/test-custom-client` (14 checks) holds the ground and the movement
to their numbers without a window: Astranaar at 106.7 yards, no step where
tiles meet, a second's run 8.4 yards, a jump about 1.64 yards high, slopes
walked, cliffs fallen off.

Not yet: comparing heights with the running server point for point (the
server was down; it needs a console command or a Lua call reporting the
server's height at a point); the real night elf (173d); slopes too steep
to climb (open question 1). Window smoothing (multisampling) is off: with
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
  the right mouse button is held), E strafe right, space jump, left mouse
  drag to turn the camera, right mouse drag to turn her and the camera,
  wheel to zoom; **q quits** (in the game q strafes left).
- **Speeds**, the game's base speeds at 120%: run 7 x 1.2 = 8.4 yards a
  second, back 4.5 x 1.2 = 5.4, turning pi radians a second; gravity
  19.29 yards a second squared, a jump's lift 7.96.
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

1. Slopes: the game stops you walking up slopes steeper than about 50
   degrees. Wanted now, or later?
