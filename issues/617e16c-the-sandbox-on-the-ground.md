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

The fish-school sandbox (`docs/HTML/fish-sandbox.html`) flocks its bots
over flat zone squares: the ground's shape, hills and cliffs, trees,
rocks and buildings are not in it. Being built (2026-10-28): the archive
copy and the ground sandbox.

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
