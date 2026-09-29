// roam-pattern.js - the JavaScript implementation of the roaming pattern
// (docs/roaming-pattern.md): the ground grid, paint and the walls' paint,
// paths, the eight-sector sensing, and the owner's waypoint rule. No page
// code here (that is scene-kit.js); the playable scenes build on this, and
// scripts/test-roam-pattern runs it under gjs beside the Lua model
// (src/lua-basic/lib/buddy-roam.lua), holding both to the pattern.
//
// The owner, 2026-09-28: "the datamodel being the same doesn't mean that
// it's implementation in a specific language needs to be the same. Build
// the pattern, build it twice." So this follows the pattern document, not
// the Lua code: its own structures and names. Where the pattern leaves a
// detail open, the choice is noted; where the check compares results, the
// pattern's words are the contract.
(function (global) {
  "use strict";

  // {{{ maps
  // The big dungeon (pattern: "the dungeon's grid"; also drawn in the
  // gallery's scenes 25 and 26): five rooms and tunnels of every kind the
  // owner named, as rectangles (a loop needs a hole a single outline can't
  // have). Each rectangle carries its name and kind for the scenes' counts.
  const dungeon = {
    rects: [
      { x0: 20, y0: 190, x1: 110, y1: 340, name: "the entrance room", kind: "room" },
      { x0: 190, y0: 140, x1: 310, y1: 240, name: "the hall", kind: "room" },
      { x0: 20, y0: 20, x1: 120, y1: 100, name: "the north-west room", kind: "room" },
      { x0: 370, y0: 20, x1: 480, y1: 110, name: "the north-east room", kind: "room" },
      { x0: 380, y0: 170, x1: 480, y1: 330, name: "the south-east room", kind: "room" },
      { x0: 110, y0: 215, x1: 190, y1: 225, name: "the straight tunnel", kind: "tunnel" },
      { x0: 245, y0: 60, x1: 255, y1: 140, name: "the fork's stem", kind: "tunnel" },
      { x0: 120, y0: 55, x1: 370, y1: 65, name: "the fork", kind: "tunnel" },
      { x0: 60, y0: 165, x1: 190, y1: 175, name: "the L", kind: "tunnel" },
      { x0: 60, y0: 100, x1: 70, y1: 175, name: "the L", kind: "tunnel" },
      { x0: 310, y0: 180, x1: 380, y1: 190, name: "the loop (north way)", kind: "tunnel" },
      { x0: 280, y0: 240, x1: 290, y1: 300, name: "the loop (south way)", kind: "tunnel" },
      { x0: 280, y0: 290, x1: 380, y1: 300, name: "the loop (south way)", kind: "tunnel" },
      { x0: 440, y0: 110, x1: 450, y1: 150, name: "the dead end", kind: "dead" }
    ],
    rocks: [{ x: 250, y: 190, r: 6 }, { x: 60, y: 280, r: 5 }, { x: 470, y: 30, r: 4 }, { x: 440, y: 250, r: 6 }],
    entrance: { x: 40, y: 330 },
    farRooms: [3, 4]                        // the north-east and south-east rooms: farthest from the entrance
  };
  // }}}

  // {{{ geometry of outlines
  function insidePolygon(poly, x, y) {
    let inside = false;
    for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      const [xi, yi] = poly[i], [xj, yj] = poly[j];
      if ((yi > y) !== (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) inside = !inside;
    }
    return inside;
  }
  function edgeDistance(poly, x, y) {
    let best = Infinity;
    for (let i = 0; i < poly.length; i++) {
      const [ax, ay] = poly[i], [bx, by] = poly[(i + 1) % poly.length];
      const vx = bx - ax, vy = by - ay;
      const t = Math.max(0, Math.min(1, ((x - ax) * vx + (y - ay) * vy) / (vx * vx + vy * vy)));
      best = Math.min(best, Math.hypot(ax + vx * t - x, ay + vy * t - y));
    }
    return best;
  }
  // yards from (cx, cy) along `bearing` to the first side of the outline
  function rayToEdge(poly, cx, cy, bearing) {
    const dx = Math.cos(bearing), dy = Math.sin(bearing);
    let best = Infinity;
    for (let i = 0; i < poly.length; i++) {
      const [ax, ay] = poly[i], [bx, by] = poly[(i + 1) % poly.length];
      const ex = bx - ax, ey = by - ay, den = dx * ey - dy * ex;
      if (Math.abs(den) <= 1e-9) continue;
      const t = ((ax - cx) * ey - (ay - cy) * ex) / den, u = ((ax - cx) * dy - (ay - cy) * dx) / den;
      if (t > 0 && u >= 0 && u <= 1 && t < best) best = t;
    }
    return best;
  }
  function inRects(rects, x, y) {
    for (let k = 0; k < rects.length; k++) {
      const r = rects[k];
      if (x >= r.x0 && x <= r.x1 && y >= r.y0 && y <= r.y1) return k;
    }
    return -1;
  }
  // }}}

  // {{{ the ground grid
  const STEPS = [[1, 0, 1], [-1, 0, 1], [0, 1, 1], [0, -1, 1], [1, 1, Math.SQRT2], [1, -1, Math.SQRT2], [-1, 1, Math.SQRT2], [-1, -1, Math.SQRT2]];

  // The pattern's grid over a rectangles area: corner at the bounds less one
  // cell; open = inside and not strictly inside a rock; edge distance to the
  // nearest outside cell's square; wall distance also to rock rims.
  class Grid {
    constructor(area, cell) {
      const xs = area.rects.flatMap(r => [r.x0, r.x1]), ys = area.rects.flatMap(r => [r.y0, r.y1]);
      this.area = area;
      this.cell = cell;
      this.x0 = Math.min(...xs) - cell;
      this.y0 = Math.min(...ys) - cell;
      this.nx = Math.ceil((Math.max(...xs) + cell - this.x0) / cell);
      this.ny = Math.ceil((Math.max(...ys) + cell - this.y0) / cell);
      this.n = this.nx * this.ny;
      this.rect = new Int8Array(this.n).fill(-1);     // which rectangle (room, tunnel, dead end), -1 outside
      this.open = new Uint8Array(this.n);
      this.edge = new Float32Array(this.n).fill(Infinity);
      this.wall = new Float32Array(this.n).fill(-1);
      for (let i = 0; i < this.n; i++) {
        const { x, y } = this.middle(i);
        this.rect[i] = inRects(area.rects, x, y);
        if (this.rect[i] >= 0) this.open[i] = area.rocks.some(k => (x - k.x) ** 2 + (y - k.y) ** 2 < k.r * k.r) ? 0 : 1;
      }
      this.measureEdges();
      this.openCount = this.open.reduce((s, v) => s + v, 0);
    }
    middle(i) { return { x: this.x0 + (i % this.nx + 0.5) * this.cell, y: this.y0 + (Math.floor(i / this.nx) + 0.5) * this.cell }; }
    cellAt(x, y) {
      const ix = Math.floor((x - this.x0) / this.cell), iy = Math.floor((y - this.y0) / this.cell);
      return ix < 0 || iy < 0 || ix >= this.nx || iy >= this.ny ? -1 : iy * this.nx + ix;
    }
    isOpen(x, y) { const i = this.cellAt(x, y); return i >= 0 && this.open[i] === 1; }
    // every square the line crosses (sampled at half a cell) is open
    sight(x0, y0, x1, y1) {
      const len = Math.hypot(x1 - x0, y1 - y0), steps = Math.ceil(len / (this.cell / 2));
      for (let k = 1; k < steps; k++) if (!this.isOpen(x0 + (x1 - x0) * k / steps, y0 + (y1 - y0) * k / steps)) return false;
      return true;
    }
    // edge distance: spread outward from the outside cells that touch an
    // inside one, each inside cell keeping the nearest such square
    measureEdges() {
      const { nx, ny, cell } = this, inside = i => this.rect[i] >= 0;
      const nearest = new Int32Array(this.n).fill(-1), queue = [];
      for (let i = 0; i < this.n; i++) {
        if (inside(i)) continue;
        const ix = i % nx, iy = Math.floor(i / nx);
        if (STEPS.some(([dx, dy]) => { const jx = ix + dx, jy = iy + dy; return jx >= 0 && jy >= 0 && jx < nx && jy < ny && inside(jy * nx + jx); })) {
          nearest[i] = i; queue.push(i);
        }
      }
      const toSquare = (x, y, s) => {
        const sx = this.x0 + (s % nx) * cell, sy = this.y0 + Math.floor(s / nx) * cell;
        return Math.hypot(Math.max(sx - x, 0, x - (sx + cell)), Math.max(sy - y, 0, y - (sy + cell)));
      };
      for (let h = 0; h < queue.length; h++) {
        const c = queue[h], ix = c % nx, iy = Math.floor(c / nx);
        for (const [dx, dy] of STEPS) {
          const jx = ix + dx, jy = iy + dy;
          if (jx < 0 || jy < 0 || jx >= nx || jy >= ny) continue;
          const j = jy * nx + jx;
          if (!inside(j)) continue;
          const { x, y } = this.middle(j), d = toSquare(x, y, nearest[c]);
          if (nearest[j] < 0) { nearest[j] = nearest[c]; this.edge[j] = d; queue.push(j); }
          else if (d < this.edge[j]) { nearest[j] = nearest[c]; this.edge[j] = d; }
        }
      }
      for (let i = 0; i < this.n; i++) {
        if (!this.open[i]) continue;
        const { x, y } = this.middle(i);
        this.wall[i] = this.area.rocks.reduce((d, k) => Math.min(d, Math.hypot(x - k.x, y - k.y) - k.r), this.edge[i]);
      }
    }
  }
  // }}}

  // {{{ paths
  // The cheapest way over open cells (eight neighbours, no corner cutting);
  // a step costs its length, more within 4 yards of a wall, plus `extra(i)`
  // (paint: unpainted ground cheaper). Returns waypoints (start excluded),
  // straightened where the line of sight allows, or null.
  function findPath(grid, from, to, extra) {
    const s = grid.cellAt(from.x, from.y), t = grid.cellAt(to.x, to.y);
    if (s < 0 || t < 0 || !grid.open[t]) return null;
    if (s === t) return [{ x: to.x, y: to.y }];
    const { nx, n, cell } = grid, cost = new Float32Array(n).fill(Infinity), came = new Int32Array(n).fill(-1), done = new Uint8Array(n);
    const tx = t % nx, ty = Math.floor(t / nx);
    const guess = i => { const dx = Math.abs(i % nx - tx), dy = Math.abs(Math.floor(i / nx) - ty); return (Math.max(dx, dy) + (Math.SQRT2 - 1) * Math.min(dx, dy)) * cell; };
    const heap = new MinHeap();
    cost[s] = 0; heap.push(guess(s), s);
    while (heap.size) {
      const c = heap.pop();
      if (done[c]) continue;
      done[c] = 1;
      if (c === t) break;
      const cx = c % nx, cy = Math.floor(c / nx);
      for (let k = 0; k < 8; k++) {
        const [dx, dy, len] = STEPS[k], jx = cx + dx, jy = cy + dy;
        if (jx < 0 || jy < 0 || jx >= nx || jy >= grid.ny) continue;
        const j = jy * nx + jx;
        if (!grid.open[j] || done[j]) continue;
        if (k >= 4 && (!grid.open[cy * nx + jx] || !grid.open[jy * nx + cx])) continue;
        const near = grid.wall[j] < 4 ? (4 - grid.wall[j]) * 0.6 : 0;
        const c2 = cost[c] + len * cell * (1 + near + (extra ? extra(j) : 0));
        if (c2 < cost[j]) { cost[j] = c2; came[j] = c; heap.push(c2 + guess(j), j); }
      }
    }
    if (!done[t]) return null;
    const cells = [];
    for (let c = t; c !== s && c >= 0; c = came[c]) cells.push(grid.middle(c));
    cells.reverse();
    cells[cells.length - 1] = { x: to.x, y: to.y };
    const out = [];
    let at = from, k = 0;
    while (k < cells.length) {
      let far = k;
      for (let m = cells.length - 1; m > k; m--) if (grid.sight(at.x, at.y, cells[m].x, cells[m].y)) { far = m; break; }
      out.push(cells[far]); at = cells[far]; k = far + 1;
    }
    return out;
  }
  class MinHeap {
    constructor() { this.keys = []; this.vals = []; }
    get size() { return this.keys.length; }
    push(key, val) {
      const K = this.keys, V = this.vals;
      let i = K.length;
      K.push(key); V.push(val);
      while (i > 0) { const p = (i - 1) >> 1; if (K[p] <= K[i]) break; [K[p], K[i]] = [K[i], K[p]]; [V[p], V[i]] = [V[i], V[p]]; i = p; }
    }
    pop() {
      const K = this.keys, V = this.vals, top = V[0], lk = K.pop(), lv = V.pop();
      if (K.length) {
        K[0] = lk; V[0] = lv;
        for (let i = 0; ;) {
          const l = 2 * i + 1, r = l + 1;
          let m = i;
          if (l < K.length && K[l] < K[m]) m = l;
          if (r < K.length && K[r] < K[m]) m = r;
          if (m === i) break;
          [K[m], K[i]] = [K[i], K[m]]; [V[m], V[i]] = [V[i], V[m]]; i = m;
        }
      }
      return top;
    }
  }
  // }}}

  // {{{ paint
  // A clan's paint over one grid (pattern: "Paint"). Float counts here: the
  // page never runs long enough to reach a wrap; the in-game counters are
  // fixed width and may wrap (accepted by the owner, 2026-09-27).
  class Paint {
    constructor(grid) {
      this.grid = grid;
      this.buddies = new Float32Array(grid.n);
      this.walls = new Float32Array(grid.n);
      this.seenAt = new Float32Array(grid.n).fill(-Infinity);    // last time seen up close (within 20 yards)
    }
    // what the buddy at (x, y) can see within `vision`, most at its feet
    deposit(x, y, vision, amount, now) {
      const g = this.grid, c = g.cellAt(x, y);
      if (c < 0) return;
      const r = Math.ceil(vision / g.cell), cx = c % g.nx, cy = Math.floor(c / g.nx);
      for (let oy = -r; oy <= r; oy++) for (let ox = -r; ox <= r; ox++) {
        const ix = cx + ox, iy = cy + oy;
        if (ix < 0 || iy < 0 || ix >= g.nx || iy >= g.ny) continue;
        const i = iy * g.nx + ix, d = Math.hypot(ox, oy) * g.cell;
        if (!g.open[i] || d > vision) continue;
        const p = g.middle(i);
        if (d > g.cell * 1.5 && !g.sight(x, y, p.x, p.y)) continue;
        this.buddies[i] += amount * (1 - d / vision);
        if (d <= 20) this.seenAt[i] = now;
      }
    }
    // the walls' pulse: open cells within 5 yards of a wall topped up to
    // 400 x (1 - wall distance / 5)^2, never lowered
    wallPulse(level = 400, reach = 5) {
      const g = this.grid;
      for (let i = 0; i < g.n; i++) {
        if (!g.open[i] || g.wall[i] >= reach) continue;
        const want = level * (1 - g.wall[i] / reach) ** 2;
        if (this.walls[i] < want) this.walls[i] = want;
      }
    }
    at(i, withWalls = true) { return this.buddies[i] + (withWalls ? this.walls[i] : 0); }
    explored() {
      let seen = 0;
      for (let i = 0; i < this.grid.n; i++) if (this.grid.open[i] && this.seenAt[i] > -Infinity) seen++;
      return seen / this.grid.openCount;
    }
  }
  // }}}

  // {{{ sensing: the eight sectors
  // Pattern: blocked share weighted 1 - d/radius over the sectors' 45-degree
  // halves (outside the grid counts as blocked); reach by a breadth-first
  // walk over open cells within the radius, per sector's 22.5-degree middle
  // half; tunnel = blocked >= threshold and reach >= radius - 1.5 cells.
  function senseSectors(grid, x, y, radius = 40, threshold = 0.6) {
    const sectors = Array.from({ length: 8 }, (_, k) => ({ bearing: k * Math.PI / 4, weight: 0, blockedWeight: 0, reach: 0, far: -1 }));
    const start = grid.cellAt(x, y);
    if (start < 0) return sectors.map(s => ({ ...s, blocked: 1, kind: "wall" }));
    const { nx, ny, cell } = grid, sx = start % nx, sy = Math.floor(start / nx), rc = Math.ceil(radius / cell);
    const within = (a, half) => sectors.filter(s => Math.abs(wrap(a - s.bearing)) <= half + 1e-9);
    for (let oy = -rc; oy <= rc; oy++) for (let ox = -rc; ox <= rc; ox++) {
      if (!ox && !oy) continue;
      const d = Math.hypot(ox, oy) * cell;
      if (d > radius) continue;
      const ix = sx + ox, iy = sy + oy;
      const blocked = !(ix >= 0 && iy >= 0 && ix < nx && iy < ny && grid.open[iy * nx + ix]);
      const w = 1 - d / radius;
      for (const s of within(Math.atan2(oy, ox), Math.PI / 4)) { s.weight += w; if (blocked) s.blockedWeight += w; }
    }
    const seen = new Set([start]), queue = [start];
    for (let h = 0; h < queue.length; h++) {
      const c = queue[h], ox = c % nx - sx, oy = Math.floor(c / nx) - sy, d = Math.hypot(ox, oy) * cell;
      if (c !== start) for (const s of within(Math.atan2(oy, ox), Math.PI / 8)) if (d > s.reach) { s.reach = d; s.far = c; }
      for (const [dx, dy] of STEPS) {
        const jx = c % nx + dx, jy = Math.floor(c / nx) + dy;
        if (jx < 0 || jy < 0 || jx >= nx || jy >= ny) continue;
        const j = jy * nx + jx;
        if (seen.has(j) || !grid.open[j] || ((jx - sx) ** 2 + (jy - sy) ** 2) * cell * cell > radius * radius) continue;
        seen.add(j); queue.push(j);
      }
    }
    return sectors.map(s => {
      const blocked = s.weight > 0 ? s.blockedWeight / s.weight : 1;
      const through = s.reach >= radius - 1.5 * cell;
      return { bearing: s.bearing, blocked, reach: s.reach, far: s.far, kind: blocked >= threshold ? (through ? "tunnel" : "wall") : "open" };
    });
  }
  // an angle folded into -pi..pi
  function wrap(a) { return ((a + Math.PI) % (2 * Math.PI) + 2 * Math.PI) % (2 * Math.PI) - Math.PI; }
  // }}}

  // {{{ the owner's waypoint rule
  const WAYPOINT_RULES = {
    turn: 2 * Math.PI / 10, clearance: 3, near: 10, changeMin: 1, changeMax: 20,
    crowd: 5, crowdShift: 10, pierce: 25, turnTries: 12, slideSteps: 99
  };
  // Pick the buddy's next waypoint on an outline area (pattern: "the
  // owner's waypoint rule", steps 1-6). buddy: { x, y, angle, spin, y100
  // (1..100, or null before its first waypoint), inward }; area: { outline,
  // centre, rocks }; others: [{ x, y }] (other buddies and players).
  // Changes the buddy and returns the waypoint { x, y }, or null.
  function pickWaypoint(buddy, area, others, rand, rules = WAYPOINT_RULES) {
    const [cx, cy] = area.centre, rocks = area.rocks || [];
    const clear = (x, y) => insidePolygon(area.outline, x, y)
      && rocks.every(k => (x - k.x) ** 2 + (y - k.y) ** 2 >= (k.r + rules.clearance) ** 2)
      && edgeDistance(area.outline, x, y) >= rules.clearance;
    for (let tryTurn = 0; tryTurn < rules.turnTries; tryTurn++) {
      buddy.angle += rules.turn * buddy.spin;
      let bearing = buddy.angle;
      let reach = rayToEdge(area.outline, cx, cy, bearing) - rules.clearance;
      let y100;
      if (buddy.y100 == null) {
        y100 = null;                                     // the first waypoint: any share, no step
      } else {
        const change = rules.changeMin + Math.floor(rand() * (rules.changeMax - rules.changeMin + 1));
        const sign = rand() < 0.5 ? -1 : 1;
        y100 = Math.max(1, Math.min(100, buddy.y100 + sign * change));
        // piercing: the second (or later) inward roll in a row at or under the line
        buddy.inward = y100 < buddy.y100 ? buddy.inward + 1 : 0;
        if (buddy.inward >= 2 && y100 <= rules.pierce) {
          buddy.angle += Math.PI; buddy.spin = -buddy.spin; buddy.inward = 0;
          bearing = buddy.angle;
          reach = rayToEdge(area.outline, cx, cy, bearing) - rules.clearance;
        }
        // crowding: someone within 5 yards of where Y lands moves it 10 toward 50
        const d0 = Math.max(rules.near, y100 / 100 * reach);
        const px = cx + Math.cos(bearing) * d0, py = cy + Math.sin(bearing) * d0;
        if (others.some(o => (o.x - px) ** 2 + (o.y - py) ** 2 < rules.crowd * rules.crowd)) {
          const side = y100 < 50 ? 1 : y100 > 50 ? -1 : (rand() < 0.5 ? 1 : -1);
          y100 += side * rules.crowdShift;
        }
      }
      // place: slide along the bearing a percent at a time, in then out; a
      // first waypoint instead draws up to 8 free shares
      const tries = y100 == null ? Array.from({ length: 8 }, () => rand() * 100) : slideOrder(y100, rules.slideSteps);
      for (const pct of tries) {
        if (y100 != null && (pct < 1 || pct > 100)) continue;
        const d = Math.max(rules.near, pct / 100 * reach);
        const x = cx + Math.cos(bearing) * d, y = cy + Math.sin(bearing) * d;
        if (clear(x, y)) {
          buddy.y100 = y100 == null ? Math.round(pct) : y100;    // the drawn Y, not the slid one
          buddy.waypoint = { x, y };
          return buddy.waypoint;
        }
      }
    }
    return null;
  }
  function slideOrder(y100, steps) {
    const out = [y100];
    for (let k = 1; k <= steps; k++) out.push(y100 - k, y100 + k);     // in, then out
    return out;
  }
  // }}}

  // {{{ seeded random numbers: s = (s * 1103515245 + 12345) mod 2^31
  function seeded(seed) {
    let s = seed;
    return () => { s = (s * 1103515245 + 12345) % 2147483648; return s / 2147483648; };
  }
  // }}}

  global.RoamPattern = { maps: { dungeon }, Grid, Paint, findPath, senseSectors, pickWaypoint, WAYPOINT_RULES, seeded,
                         insidePolygon, edgeDistance, rayToEdge, wrap };
})(typeof window !== "undefined" ? window : globalThis);
