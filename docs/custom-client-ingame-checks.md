# Custom Client: Things to Check In-Game

Things the custom client does by this client's own reading or guess,
which the owner checks against the original client and answers. Each
item names the issue it belongs to. When checked, write the answer into
that issue and strike it here (keep the line, so the history stays).

## Look

1. **Torch flames** (173o): walk up to a torch at night (`--hour 23`).
   Is its flame as tall and as bright as the original's?
2. **Light inside buildings** (173g): inside an Astranaar house, is it as
   bright and as warm as the original's?
3. **Sky bands** (173n): do the sky's colour bands sit at the same
   heights above the horizon as the original's (horizon, two bands,
   middle, overhead)?
4. **The sun's path** (173n): at noon and dusk, does light fall from the
   same side as in the original (sun east at 6, south at noon, west at
   18 here)?
5. **Water** (173r): the lake round Astranaar. Its colour,
   see-throughness, and how fast its ripples run (15 pictures a second
   here).
6. **The moss over the archway near the bridge** (173g): where exactly
   is it (which bridge, or a picture)? The likely causes have been ruled
   out on Astranaar's own tile, so it may be on a neighbouring tile, or a
   different fault.
   **The halos** should now be round from every side (lamps, wisps,
   fireflies): check they look like the original's orbs.
7. **The tauren** (173d, 173p): his tail and coat now show (they used a
   fur picture the client skipped). Do they look like the original's? Are
   his hooves right? Are the two skin layers the client's tables name but
   its files lack (scalp, and a hair picture) visible as patches?

## Feel

8. **Step height and body width** (173q): can she walk up the same
   ledges, and get as close to walls, as in the original (1 yard and 0.4
   yards here)?
9. **Swimming** (173r):
   - How deep the water gets before she swims (1.6 yards over her feet
     here).
   - How fast she floats up when left alone (2 yards a second here).
   - Swimming forward with the right button held follows the camera's
     pitch.
10. **Camera follow speed** (173m): the swing behind her at 180 degrees a
    second.

## How to look

`scripts/custom-client` runs it. Picture options (after `--shot`):
`--hour H`, `--face DEG`, `--walk S`, `--zoom N`, `--pitch DEG`,
`--turn DEG`, `--pose ID MS`, `--clock MS`.
