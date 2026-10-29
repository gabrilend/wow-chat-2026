# 617e16c - The Sandbox on the Ground

## Status
- Created: 2026-10-28
- Phase: 6
- Parent: 617e16 (the fish-school sandbox)
- Related: 617o (pathfinding on the navigation mesh), 617o6 (layered
  ways), the waypoint slope limit (50 degrees, `WALK_SLOPE_DEGREES` in
  the buddy module's ground code; `docs/balance-updates.md`)
- Priority: High
- State: in progress

## Origin

The owner, 2026-10-28, on the fish-school sandbox:

> this pathfinding design is excellent, make sure a copy of it is
> archived. It's not quite what we're looking for, but it's delightful.
> Can we add / modify it when we copy it to a new location archive style
> to interact with and relate to the heightmap of the world? The bots
> should treat anywhere beyond a slope above a certain angle as
> unpathable. They should also avoid doodads and such.

## Current Behavior

**Built 2026-10-28** (pictures 021-027 in `development-history/`):
- **The archive**: `docs/HTML/archive/fish-sandbox-2026-10-28.html` and
  `scripts/templates/archive/fish-sandbox-2026-10-28.html`, each folder
  with a README; committed (61645b6c7).
- **The data**: `scripts/generate-ground-sandbox-data` writes
  `docs/HTML/ground-sandbox/zone-<map>-<zone>.js` for every zone of the
  two continents (50 zones, 6 processes at a time, about 10 seconds, 50 MB
  in all): heights every 4.17 yards (`scripts/lib/map-heights.lua`) as
  tenths of a yard, stored as differences, gzipped, base64; and each
  collision footprint near the ground, from the collision tiles'
  **placed boxes** (every spawn carries one; the models' own files hold
  no usable box for doodads, all zeros). Left out: structures wider than
  40 yards, and boxes wholly above head height or below the ground (the
  Barrens: 21,776 kept, 481 large and 4,004 off the ground left out).
- **The decoder**: `scripts/templates/ground-decode.js`, a small inflater
  of its own (synchronous, so a headless screenshot waits for it),
  inlined into the page; `scripts/test-ground-decode` checks 400 points
  of Durotar against the map files (all match to a tenth of a yard).
- **The page**: `docs/HTML/ground-sandbox.html` (template
  `scripts/templates/ground-sandbox.html`, built by
  `scripts/generate-ground-sandbox-page`, `--screenshot SETTINGS` files a
  picture). Hill shading over the zone; ground steeper than the
  **Steepest** slider (50 degrees to start) in red; doodads as dark marks
  when zoomed in; a bot's step onto blocked ground is turned aside, 20
  degrees at a time, left and right in turn, up to 140. The panel adds
  steps turned aside and stopped a second, the fence's open share, the
  zone's doodads and level. The tool checks every script of the page
  parses (Node) before any picture. Controls: scroll to zoom, hold the
  middle button and drag to pan (the owner, 2026-10-28: "drag the map
  with middle click just panning"; the browser's own middle-button
  scrolling is kept off the map).
- **Drawn the right way round.** The fish-school sandbox draws the world
  mirrored left to right (the game's y points west, so the squares' Y
  grows eastward, and the page put larger Y on the left: Orgrimmar left
  of Thunder Bluff). The ground sandbox puts east on the right.

Seen in the pictures: the largest Barrens fence (Venture Co. Supervisor)
is mostly a mine: two thirds of its spawns are 100-170 yards under the
ground, and the steep red is the hill above. Fences mix cave and surface
spawns (open question 2).

## Intended Behavior

1. **The archive.** The fish-school sandbox as it stands, kept unchanged
   and openable: the generated page and its template, side by side in
   `docs/HTML/archive/` and `scripts/templates/archive/`, dated, with a
   note on what it is. The live sandbox goes on as it was.
2. **The ground sandbox**, a new page built from a copy of the sandbox
   (`docs/HTML/ground-sandbox.html`), the same flock, fences, themes and
   controls, and under them the world's own ground, per zone:
   - **Heights**: the terrain's height every 4.17 yards (the map files'
     own spacing, `scripts/lib/map-heights.lua`), drawn as hill shading,
     so the flock is seen against hills and valleys.
   - **Slope**: each point's steepness from its neighbours' heights. Ground
     steeper than the limit is **unpathable**: a bot never steps onto it,
     and a slider on the page sets the limit (50 degrees to start, the
     buddy module's own waypoint limit) so its effect can be watched.
   - **Doodads**: the trees, rocks, fences and small buildings the server
     collides with, from its collision files (`data-files/vmaps/`: each
     tile's placed models, their position, turn and size, and each model's
     collision box), each marked as a blocked footprint on the ground. A
     tree blocks at its trunk, since the collision box is the trunk, not
     the canopy. Large structures (towns, bridges, caves: wider than 40
     yards) are not marked, since bots walk in and on them.
   - **Avoiding**: a bot's next step that would land on a blocked point is
     turned aside (the smaller turn, left or right, that finds open
     ground), so the flock flows round trees and along cliff feet.
   - A measure on the panel: how often a step was turned aside, and the
     share of the fence that is open ground.
3. **The data**, made by a tool and kept per zone (one file each, loaded
   when the zone is opened, since all zones' ground together is too much
   for one page).

## Suggested Implementation Steps

1. Archive: copy the page and its template, dated; a README line in the
   archive folder.
2. `scripts/generate-ground-sandbox-data`: per zone, the height grid
   (quantized), the doodad footprints, written to
   `docs/HTML/ground-sandbox/zone-<map>-<zone>.js`; slope is worked out by
   the page from the heights, so the slider can change the limit live.
3. The page: the template copied to `scripts/templates/ground-sandbox.html`,
   with the ground's loading, shading, the slope slider, the blocked
   mask, and the steering's turn-aside; its generator.
4. Pictures filed in `development-history/` by the page's tool.

## Open Questions

1. **Large structures**: towns and bridges are left unmarked (bots walk
   in them). Should a town's buildings block instead, each building by
   its own pieces (a model's groups), at the cost of reading each model's
   pieces?
2. **Fences under the ground**: a fence built from spawns partly in a
   cave (the Barrens' Venture Co. Supervisors in Boulder Lode Mine) puts
   surface bots over a hill. Should fences take only spawns standing on
   the surface (within a few yards of the terrain's height), with caves
   as fences of their own (617e12's cave layers)?
3. **The mirror**: fix the fish-school sandbox too (its live page; the
   archive stays as it was), and check the zone renderer
   (`scripts/render-zone`, 617e14c) and the zone data's note ("Y grows
   westward") for the same mistake?
4. **The ground files in git**: 50 MB for the two continents, made in
   ten seconds by the tool. Commit them (the page works from a fresh
   copy), or leave them out and make them on install?
