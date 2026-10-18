# movement.lua

Plain geometry the beta scripts share: positions round a point, distances,
angles, orbits (x and y in yards, angles in radians). Only
`generateNewWanderPosition` and `getConsensusDirection` touch the game.
Checked offline by `scripts/test-movement`.

## Functions

- `Movement.getCircleSpawnPosition(ox, oy, min, max) -> x, y`: on a circle
  of radius min-max (whole-number angle and radius).
- `Movement.getPlusSpawnPosition(ox, oy, min, max) -> x, y`: on one arm of
  a plus sign, min-max out along it.
- `Movement.getBoxSpawnPosition(ox, oy, min, max) -> x, y`: in the square
  ring between min and max.
- `Movement.getArcSpawnPosition(ox, oy, min, max, facing) -> x, y`: ahead,
  within 45 degrees of `facing`.
- `Movement.getMidpoint(x1, y1, x2, y2) -> x, y`;
  `Movement.getPositionOppositePoint(ix, iy, px, py) -> x, y` (the point as
  far beyond `p` as `i` is before it);
  `Movement.getPositionInFrontOfPoint(x, y, o, dist) -> x, y`.
- `Movement.squaredDistance(...) -> number`; `Movement.isCloseEnough(x1, y1,
  x2, y2, dist) -> boolean`; `Movement.getLazyDistance(...) -> sum, dx, dy`
  (city-block distance, an overestimate).
- `Movement.normalize(dx, dy) -> dx, dy`; `Movement.nearestPointOnCircle(cx,
  cy, r, px, py) -> x, y`.
- `Movement.getInitialAngle(ox, oy, mx, my) -> radians`;
  `Movement.getOrbitPosition(ox, oy, r, speed, dt, angle, dir) -> x, y`;
  `Movement.normalizeAngle(a) -> 0..6.28`; `Movement.getMathAngle(a)`,
  `Movement.getWoWAngle(a)` (both return the angle unchanged within 0-6.28).
- `Movement.generateNewWanderPosition(x, y, z, o, theta, mapId) -> x, y, z, o`:
  10 yards ahead, the facing nudged but kept within 0.39 of `theta`.
- `Movement.getConsensusDirection(unit, range) -> radians or nil`: the
  average facing of real players nearby.
