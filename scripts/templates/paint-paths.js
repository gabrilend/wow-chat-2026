// paint-paths.js - the painted map (issue 617o8): pathfinding that learns,
// keeps its distance from walls, spreads, and walks in arcs. Inlined into
// docs/HTML/ground-sandbox.html by scripts/generate-ground-sandbox-page and
// run alone by scripts/test-paint-paths (Node), so the page and its test
// share one copy.
//
// The owner, 2026-10-29: "Remember we want bots to paint surfaces and
// collectively get better at navigating as we gather more data. Also they
// should give space to walls, less if they need something nearby or
// directly nearby opposite the wall, and they should spread out through an
// area. ... We are trying to make the path finding look natural. We can
// make arcs between way points if necessary."
//
// How it works, in order below:
//   the map      one per area, shared by every bot: fine cells holding what
//                the bots have learned (unknown, painted, wall, steep,
//                outside the area), how often each was walked, and each
//                one's clearance (yards to the nearest wall or steep cell);
//   painting     a bot paints the cell it stands in; a refused step paints
//                the thing it hit as wall, and the clearance round it is
//                mended at once, so every bot plans by it from then on;
//   the cost     open ground 1 a yard; nearer a wall than the wanted space,
//                dearer the nearer (less so near the goal, measured
//                straight, so a goal across a wall counts as near); unknown
//                ground a little dearer than painted; the crowd's cells
//                dearer, so bots going the same way take side-by-side lanes;
//   the planner  A* over the cells with that cost, its memory reused from
//                plan to plan (stamps instead of clearing);
//   pulling      the route of cells pulled tight into long straights, none
//                passing nearer a wall than the route itself ran;
//   following    a point a few yards ahead along the straights, shifted to
//                the bot's own lane where there is room, steered to at a
//                limited turning rate: every corner is walked as an arc.
// Cells are numbered row by row (q = r * w + c); cell (c, r)'s middle is at
// (x0 + c * step, y0 + r * step), in the page's screen yards.

"use strict";
const PaintPaths = (function () {

  // {{{ the numbers (each a guess: 617o8's question 2; the page's sliders move some)
  const DEFAULTS = {
    WANT:       4.0,    // yards of space wanted between a bot's middle and a wall or steep cell
    WALL_W:     8.0,    // how much dearer a yard right at a wall is than a yard in the open
                        // (3 until 2026-10-29: a few dear cells at a wall's end cost less than
                        // the detour, and bots grazed it even with full space wanted)
    RELAX:     10.0,    // within this many yards (straight) of its goal, the wanted space fades
    NEAR:      24.0,    // a goal this near the bot (straight, even across a wall) relaxes the whole route
    UNKNOWN:    0.15,   // unknown ground's premium over painted ground
    CROWD_W:    0.5,    // a bot's presence, or its route's, in extra cost a yard
    CROWD_AHEAD: 14,    // yards of each bot's route ahead counted in the crowd
    CLEAR_CAP:  8.0,    // clearance is worked out no farther than this (what the space and the
                        // lanes use; at 12 each wall cell stamped a window 25 cells across, at 8 one 17 across: half the work)
    LOOK:       6.0,    // yards ahead along the route the followed point runs (nearer when the
                        // straight to it isn't clear, down to 1.5)
    SAFE:       1.0,    // yards of clearance the straight to the followed point keeps
    TURN:       4.2,    // radians a second, the most a bot turns (240 degrees)
    LANE:       4.0,    // yards to its own side of the route a bot walks, at most (and 60% of the room there)
    REACH:     40.0,    // yards one pulled straight may run
    REPLAN:     6.0,    // seconds, a plan made again now and then (the crowd moves)
    ARRIVE:     1.5,    // yards from the goal that count as there
  };
  const UNKNOWN = 0, PAINTED = 1, WALL = 2, STEEP = 3, OUTSIDE = 4;
  const SQRT2 = Math.SQRT2;
  const now = typeof performance !== "undefined" ? () => performance.now() : () => Date.now();
  // }}}

  // {{{ make: a map of w x h cells, step yards apart
  function make(w, h, step, x0, y0, opt) {
    const n = w * h;
    const M = {
      w, h, n, step, x0, y0,
      opt: Object.assign({}, DEFAULTS, opt || {}),
      know:  new Uint8Array(n),           // UNKNOWN, PAINTED, WALL, STEEP or OUTSIDE
      walks: new Uint16Array(n),          // times a bot has stood here (stops at 65535)
      clear: new Float32Array(n),         // yards to the nearest wall or steep cell, at most CLEAR_CAP
      crowd: new Float32Array(n),         // extra cost a yard from the crowd, remade each second
      walls: [],                          // the latest wall paintings: { v, c0, r0, c1, r1 }
      version: 0,                         // goes up with each wall painted
      painted: 0, wallCells: 0, inside: n,
      // the planner's memory, kept between plans
      gen: 0, stamp: new Uint32Array(n), shut: new Uint32Array(n),
      g: new Float32Array(n), came: new Int32Array(n),
      heapF: new Float64Array(4096), heapQ: new Int32Array(4096), heapN: 0,
      stats: { plans: 0, ms: 0, failed: 0, expanded: 0, bumps: 0 },
    };
    M.clear.fill(M.opt.CLEAR_CAP);
    return M;
  }
  const cellOf = (M, x, y) => {
    const c = Math.round((x - M.x0) / M.step), r = Math.round((y - M.y0) / M.step);
    return c < 0 || r < 0 || c >= M.w || r >= M.h ? -1 : r * M.w + c;
  };
  const cx = (M, q) => M.x0 + (q % M.w) * M.step;
  const cy = (M, q) => M.y0 + Math.floor(q / M.w) * M.step;
  const blocks = k => k >= WALL;                       // a wall, steep, or outside: not walked through
  const walling = k => k === WALL || k === STEEP;      // what wants space kept from it (the area's edge doesn't:
                                                        // it is a fence in the mind, not a cliff, 617e16j)
  // }}}

  // {{{ what is known before any walk: steep ground and the area's edge
  // set(x, y) is asked of each cell's middle: STEEP, OUTSIDE, or UNKNOWN.
  // Painted cells and walls already learned are kept.
  function setGround(M, kindAt) {
    let inside = 0;
    for (let q = 0; q < M.n; q++) {
      const k = M.know[q];
      if (k === PAINTED || k === WALL) { inside++; continue; }
      const kk = kindAt(cx(M, q), cy(M, q));
      M.know[q] = kk;
      if (kk !== OUTSIDE) inside++;
    }
    M.inside = inside;
    clearAll(M);
  }
  // }}}

  // {{{ clearance: yards from each cell's middle to the nearest wall or steep cell's
  // Worked out from each wall or steep cell at the edge of its patch (one
  // with an open side: an inner one is nobody's nearest), over a window of
  // CLEAR_CAP yards round it, keeping the least. Walls are only ever added,
  // so a new one is mended in by the same window alone (stampClear).
  function stampClear(M, s) {
    const R = Math.ceil(M.opt.CLEAR_CAP / M.step), sc = s % M.w, sr = (s - sc) / M.w;
    const r0 = Math.max(0, sr - R), r1 = Math.min(M.h - 1, sr + R), c0 = Math.max(0, sc - R), c1 = Math.min(M.w - 1, sc + R);
    for (let r = r0; r <= r1; r++) {
      const dy = (r - sr) * M.step, row = r * M.w;
      for (let c = c0; c <= c1; c++) {
        const dx = (c - sc) * M.step, d = Math.sqrt(dx * dx + dy * dy);
        if (d < M.clear[row + c]) M.clear[row + c] = d;
      }
    }
  }
  function clearAll(M) {
    M.clear.fill(M.opt.CLEAR_CAP);
    const w = M.w, k = M.know;
    for (let q = 0; q < M.n; q++) {
      if (!walling(k[q])) continue;
      const c = q % w;
      const edge = (c > 0 && !walling(k[q - 1])) || (c < w - 1 && !walling(k[q + 1])) ||
                   (q >= w && !walling(k[q - w])) || (q < M.n - w && !walling(k[q + w]));
      if (edge) stampClear(M, q);
    }
    for (let q = 0; q < M.n; q++) if (walling(k[q])) M.clear[q] = 0;
  }
  // }}}

  // {{{ painting
  // walked: the cell a bot stands in is painted (proven ground) and counted
  function walked(M, x, y) {
    const q = cellOf(M, x, y); if (q < 0) return;
    if (M.know[q] === UNKNOWN) { M.know[q] = PAINTED; M.painted++; }
    if (M.walks[q] < 65535) M.walks[q]++;
  }
  // wall: what a refused step hit, as a box in yards (a doodad's footprint
  // grown by a body's half-width, or the refused point alone): every cell
  // whose middle is in it, or the one cell holding it when it is smaller
  // than a cell. Returns the cells newly painted (0: known already); a
  // caller whose refusal painted nothing new paints the refused point itself
  // (refused, below), so every bump teaches at least one cell and no bot
  // can push against the same thing for ever. The bot that was refused plans
  // again at once (its caller drops its path); others only when a painting
  // falls near their route ahead (needsPlan).
  // Painting every cell the box overlapped instead (tried 2026-10-29, at
  // 2-yard cells) shut real gaps: pillars 6 yards apart left 3.4 yards to
  // walk between them and none on the map. Cells are now a yard.
  function wall(M, x0, y0, x1, y1, keep, ring) {
    let c0 = Math.ceil((x0 - M.x0) / M.step), c1 = Math.floor((x1 - M.x0) / M.step);
    let r0 = Math.ceil((y0 - M.y0) / M.step), r1 = Math.floor((y1 - M.y0) / M.step);
    if (c0 > c1) c0 = c1 = Math.round(((x0 + x1) / 2 - M.x0) / M.step);
    if (r0 > r1) r0 = r1 = Math.round(((y0 + y1) / 2 - M.y0) / M.step);
    c0 = Math.max(0, c0); r0 = Math.max(0, r0); c1 = Math.min(M.w - 1, c1); r1 = Math.min(M.h - 1, r1);
    let fresh = 0;
    for (let r = r0; r <= r1; r++) for (let c = c0; c <= c1; c++) {
      const q = r * M.w + c, k = M.know[q];
      if (blocks(k) || q === keep) continue;      // never the cell the refused bot stands in (it would wall itself in)
      if (ring && keep >= 0 && Math.abs(c - keep % M.w) <= 1 && Math.abs(r - Math.floor(keep / M.w)) <= 1) continue;
      if (k === PAINTED) M.painted--;
      M.know[q] = WALL; M.wallCells++; fresh++;
      stampClear(M, q); M.clear[q] = 0;
    }
    if (fresh) {
      M.walls.push({ v: ++M.version, c0, r0, c1, r1 });
      if (M.walls.length > 128) M.walls.splice(0, M.walls.length - 128);
    }
    return fresh;
  }
  // }}}

  // refused: a step from (bx, by) into (x, y) was refused by the world and
  // hit `box` (a thing's footprint grown by a body, or null when the world
  // can't say what): the thing painted, or failing anything new, the refused
  // point; never the bot's own cell, and the refused point not even beside
  // it (a point refused within a cell of the bot is in the thing's reach,
  // not its body: painting it overstates the thing). Until 2026-10-29 a bot
  // refused right beside a pillar painted its own cell and its neighbours,
  // and had no way out.
  function refused(M, x, y, box, bx, by) {
    const keep = bx === undefined ? -1 : cellOf(M, bx, by);
    let fresh = box ? wall(M, box[0], box[1], box[2], box[3], keep, false) : 0;
    if (!fresh) fresh = wall(M, x, y, x, y, keep, true);
    M.stats.bumps++;
    return fresh;
  }
  // }}}

  // {{{ the cost of a yard through cell q, for a bot going to (gx, gy)
  // trip: the plan's own relaxing, from how near the goal is to the bot in a
  // straight line (1 from NEAR yards up): a goal just across a wall relaxes
  // the whole way round it ("less if they need something nearby or directly
  // nearby opposite the wall"). Until 2026-10-29 only the cells within RELAX
  // of the goal relaxed, and a wall's end 20 yards off kept its full space.
  function costAt(M, q, gx, gy, trip) {
    const o = M.opt;
    let cost = 1;
    const cl = M.clear[q];
    if (cl < o.WANT) {
      const dx = cx(M, q) - gx, dy = cy(M, q) - gy, dg = Math.sqrt(dx * dx + dy * dy);
      const relax = Math.min(dg >= o.RELAX ? 1 : dg / o.RELAX, trip === undefined ? 1 : trip);   // near the goal, less space kept
      const f = (o.WANT - cl) / o.WANT;
      cost += o.WALL_W * f * f * relax;
    }
    if (M.know[q] === UNKNOWN) cost += o.UNKNOWN;
    return cost + M.crowd[q];
  }
  // }}}

  // {{{ the heap: cells by their estimated total, least first
  function push(M, q, f) {
    if (M.heapN === M.heapF.length) {
      const F = new Float64Array(M.heapN * 2), Q = new Int32Array(M.heapN * 2);
      F.set(M.heapF); Q.set(M.heapQ); M.heapF = F; M.heapQ = Q;
    }
    const F = M.heapF, Q = M.heapQ;
    let i = M.heapN++;
    while (i > 0) { const p = (i - 1) >> 1; if (F[p] <= f) break; F[i] = F[p]; Q[i] = Q[p]; i = p; }
    F[i] = f; Q[i] = q;
  }
  function pop(M) {
    const F = M.heapF, Q = M.heapQ, top = Q[0], n = --M.heapN;
    if (n > 0) {
      const f = F[n], q = Q[n];
      let i = 0;
      for (;;) {
        const l = 2 * i + 1; if (l >= n) break;
        const m = l + 1 < n && F[l + 1] < F[l] ? l + 1 : l;
        if (F[m] >= f) break;
        F[i] = F[m]; Q[i] = Q[m]; i = m;
      }
      F[i] = f; Q[i] = q;
    }
    return top;
  }
  // }}}

  // {{{ plan: from (sx, sy) to (gx, gy); a path, or null when there is no way
  // A goal on a wall or outside is moved to the nearest open cell within 8
  // cells (a thing fetched from a wall is reached from beside it). The start
  // may stand anywhere (a bot half over a wall's cell starts from there).
  // A diagonal step needs both cells beside it open (or it slips through a
  // corner: 617o7's offline test).
  const DC = [1, -1, 0, 0, 1, 1, -1, -1], DR = [0, 0, 1, -1, 1, -1, 1, -1];
  function nearestOpen(M, t, R) {
    const tc = t % M.w, tr = (t - tc) / M.w;
    let best = -1, bd = Infinity;
    for (let r = Math.max(0, tr - R); r <= Math.min(M.h - 1, tr + R); r++)
      for (let c = Math.max(0, tc - R); c <= Math.min(M.w - 1, tc + R); c++) {
        const q = r * M.w + c, d = (c - tc) * (c - tc) + (r - tr) * (r - tr);
        if (!blocks(M.know[q]) && d < bd) { bd = d; best = q; }
      }
    return best;
  }
  // squeeze: when no way is found, the plan is tried again letting the
  // first step pass through a painted wall beside the start (not steep
  // ground, not outside): the bot stands there, so the cells round it can't
  // all be what the paint says, and a bot boxed in by over-painting walks
  // out (the safety net under refused's rules).
  function plan(M, sx, sy, gx, gy) {
    const p = planOnce(M, sx, sy, gx, gy, false);
    return p || planOnce(M, sx, sy, gx, gy, true);
  }
  function planOnce(M, sx, sy, gx, gy, squeeze) {
    const t0 = now(), w = M.w, st = M.step, know = M.know;
    const s = cellOf(M, sx, sy);
    let t = cellOf(M, gx, gy);
    if (s >= 0 && t >= 0 && blocks(know[t])) t = nearestOpen(M, t, 8);
    if (s < 0 || t < 0) { M.stats.failed++; return null; }
    if (++M.gen === 0xffffffff) { M.stamp.fill(0); M.shut.fill(0); M.gen = 1; }
    const gen = M.gen, tc = t % w, tr = (t - tc) / w;
    const trip = Math.min(1, Math.hypot(gx - sx, gy - sy) / M.opt.NEAR);
    M.heapN = 0;
    M.g[s] = 0; M.came[s] = -1; M.stamp[s] = gen;
    const h0c = Math.abs(s % w - tc), h0r = Math.abs((s - s % w) / w - tr);
    push(M, s, (Math.max(h0c, h0r) + (SQRT2 - 1) * Math.min(h0c, h0r)) * st);
    let expanded = 0;
    while (M.heapN > 0) {
      const q = pop(M);
      if (q === t) break;
      if (M.shut[q] === gen) continue;
      M.shut[q] = gen; expanded++;
      const qc = q % w, qr = (q - qc) / w, gq = M.g[q];
      for (let k = 0; k < 8; k++) {
        const nc = qc + DC[k], nr = qr + DR[k];
        if (nc < 0 || nr < 0 || nc >= w || nr >= M.h) continue;
        const n = nr * w + nc;
        if (M.shut[n] === gen) continue;
        const out = q === s && squeeze;                       // the first step, squeezing: painted walls let through
        if (blocks(know[n]) && !(out && know[n] === WALL)) continue;
        if (k >= 4 && !out && (blocks(know[qr * w + nc]) || blocks(know[nr * w + qc]))) continue;
        const ng = gq + (k >= 4 ? SQRT2 : 1) * st * costAt(M, n, gx, gy, trip);
        if (M.stamp[n] !== gen || ng < M.g[n]) {
          M.stamp[n] = gen; M.g[n] = ng; M.came[n] = q;
          const hc = Math.abs(nc - tc), hr = Math.abs(nr - tr);
          push(M, n, ng + (Math.max(hc, hr) + (SQRT2 - 1) * Math.min(hc, hr)) * st);
        }
      }
    }
    M.stats.expanded += expanded;
    if (M.stamp[t] !== gen) { if (squeeze) M.stats.failed++; M.stats.plans++; M.stats.ms += now() - t0; return null; }
    const cells = [];
    for (let q = t; q !== -1; q = M.came[q]) cells.push(q);
    cells.reverse();
    const path = pullTight(M, cells, sx, sy, gx, gy);
    path.v = M.version;
    M.stats.plans++; M.stats.ms += now() - t0;
    return path;
  }
  // }}}

  // {{{ pulling tight: the route's cells as a few long straights
  // From each corner kept, the farthest route cell (within REACH yards) whose
  // straight from it crosses no blocking cell and no cell nearer a wall
  // than the route itself came between them (less a hair), is the next
  // corner. The straight is walked cell by cell, whichever border comes
  // first (617o7's lesson: sampled points miss a clipped corner).
  function fair(M, ax, ay, bx, by, need) {
    const w = M.w, st = M.step;
    const fx = (ax - M.x0) / st, fy = (ay - M.y0) / st, tx = (bx - M.x0) / st, ty = (by - M.y0) / st;
    let c = Math.round(fx), r = Math.round(fy);
    const ce = Math.round(tx), re = Math.round(ty), dx = tx - fx, dy = ty - fy, sc = dx > 0 ? 1 : -1, sr = dy > 0 ? 1 : -1;
    let nextC = dx ? ((c + 0.5 * sc) - fx) / dx : Infinity, nextR = dy ? ((r + 0.5 * sr) - fy) / dy : Infinity;
    const eachC = dx ? 1 / Math.abs(dx) : Infinity, eachR = dy ? 1 / Math.abs(dy) : Infinity;
    for (let n = Math.abs(ce - c) + Math.abs(re - r); n > 0; n--) {
      if (nextC < nextR) { c += sc; nextC += eachC; } else { r += sr; nextR += eachR; }
      if (c < 0 || r < 0 || c >= w || r >= M.h) return false;
      const q = r * w + c;
      if (blocks(M.know[q]) || M.clear[q] < need) return false;
    }
    return true;
  }
  function pullTight(M, cells, sx, sy, gx, gy) {
    const pts = [[sx, sy]];
    let ax = sx, ay = sy, a = 0;
    while (a < cells.length - 1) {
      let best = a + 1, need = Infinity;
      for (let j = a + 1; j < cells.length; j++) {
        need = Math.min(need, M.clear[cells[j]]);
        const bx = cx(M, cells[j]), by = cy(M, cells[j]);
        if (Math.hypot(bx - ax, by - ay) > M.opt.REACH) break;
        if (j > a + 1 && !fair(M, ax, ay, bx, by, need - 0.01)) break;
        best = j;
      }
      ax = cx(M, cells[best]); ay = cy(M, cells[best]);
      pts.push([ax, ay]); a = best;
    }
    // the goal itself last, when it is open and in a fair straight from the
    // last corner (in place of that corner's cell middle; added after the
    // start when the route is one cell, so a path always has two points)
    const gq = cellOf(M, gx, gy), goalOpen = gq >= 0 && !blocks(M.know[gq]) && fair(M, ax, ay, gx, gy, 0);
    if (pts.length === 1) pts.push(goalOpen ? [gx, gy] : [cx(M, cells[0]), cy(M, cells[0])]);
    else if (goalOpen) pts[pts.length - 1] = [gx, gy];
    let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
    for (const [x, y] of pts) { x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); }
    let len = 0;
    for (let i = 1; i < pts.length; i++) len += Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]);
    return { cells, pts, gx, gy, len, box: [x0, y0, x1, y1], seg: 0, at: 0 };
  }
  // }}}

  // {{{ whether a bot needs a new plan
  // A path for another goal (more than two cells off), an old path (the
  // crowd has moved: REPLAN seconds, plus the bot's own jitter so they don't
  // all plan in the same frame), or a wall painted since near the route
  // (its box grown by the wanted space). A wall painted far away keeps the
  // path: its version is brought up to date without a plan.
  function needsPlan(M, path, gx, gy, t, jitter) {
    if (!path) return true;
    if (Math.hypot(path.gx - gx, path.gy - gy) > 2 * M.step) return true;
    if (t - path.at > M.opt.REPLAN + (jitter || 0)) return true;
    if (path.v !== M.version) {
      const g = M.opt.WANT, [x0, y0, x1, y1] = path.box;
      for (const wl of M.walls) {
        if (wl.v <= path.v) continue;
        const wx0 = M.x0 + wl.c0 * M.step, wx1 = M.x0 + wl.c1 * M.step, wy0 = M.y0 + wl.r0 * M.step, wy1 = M.y0 + wl.r1 * M.step;
        if (wx1 >= x0 - g && wx0 <= x1 + g && wy1 >= y0 - g && wy0 <= y1 + g) return true;
      }
      path.v = M.version;
    }
    return false;
  }
  // }}}

  // {{{ following: the point to steer to, LOOK yards ahead, in the bot's lane
  // The bot's place on the path is the nearest point of the segment it is
  // on or the next two; the followed point runs LOOK yards on from there.
  // Its lane (lane: -1 to 1, the bot's own) shifts it sideways by up to
  // LANE yards, never more than the room the clearance leaves there, so
  // bots on one route walk side by side, and close to the goal (within
  // LOOK) the shift fades so each still arrives at its goal.
  // The straight from the bot to the followed point must be clear and keep
  // SAFE yards from walls; if not, the point is taken nearer (60%, 35%, then
  // 1.5 yards), and a lane shift that would break it is dropped. Steering
  // at a point far ahead cuts inside every bend: until 2026-10-29 bots
  // clipped the pillars and wall ends their routes went round, thousands of
  // refused steps after the map was learned.
  // No point ahead clear (the bot pressed against something, its cell
  // perhaps painted): a step to the most open ground beside it, leaning
  // toward the route, before trying again (until 2026-10-29 it aimed into
  // the pillar it stood against, 2,894 refusals in a row).
  function follow(M, path, x, y, lane) {
    const o = M.opt;
    let near = null;
    for (const look of [o.LOOK, o.LOOK * 0.6, o.LOOK * 0.35, 1.5]) {
      const p = followAt(M, path, x, y, lane, look);
      if (fair(M, x, y, p[0], p[1], o.SAFE)) return p;
      if (lane) { const p0 = followAt(M, path, x, y, 0, look); if (fair(M, x, y, p0[0], p0[1], o.SAFE)) return p0; }
      near = p;
    }
    const toward = Math.atan2(near[1] - y, near[0] - x);
    let best = near, bestScore = -Infinity;
    for (let k = 0; k < 8; k++) {
      const a = k * Math.PI / 4, ex = x + Math.cos(a) * 1.5, ey = y + Math.sin(a) * 1.5, q = cellOf(M, ex, ey);
      if (q < 0 || blocks(M.know[q])) continue;
      const score = M.clear[q] + 0.5 * Math.cos(a - toward);
      if (score > bestScore) { bestScore = score; best = [ex, ey]; }
    }
    return best;
  }
  function followAt(M, path, x, y, lane, look) {
    const p = path.pts, o = M.opt;
    let seg = Math.min(path.seg, p.length - 2), best = Infinity, bestSeg = seg, bestT = 0;
    for (let s = seg; s < Math.min(p.length - 1, seg + 3); s++) {
      const [ax, ay] = p[s], [bx, by] = p[s + 1], dx = bx - ax, dy = by - ay, L2 = dx * dx + dy * dy;
      const tt = L2 ? Math.max(0, Math.min(1, ((x - ax) * dx + (y - ay) * dy) / L2)) : 0;
      const d = Math.hypot(ax + dx * tt - x, ay + dy * tt - y);
      if (d < best) { best = d; bestSeg = s; bestT = tt; }
    }
    path.seg = bestSeg;
    // `look` yards on from the bot's place
    let s = bestSeg, left = look;
    let px = p[s][0] + (p[s + 1][0] - p[s][0]) * bestT, py = p[s][1] + (p[s + 1][1] - p[s][1]) * bestT;
    let hx = p[s + 1][0] - p[s][0], hy = p[s + 1][1] - p[s][1];
    for (;;) {
      const [bx, by] = p[s + 1], d = Math.hypot(bx - px, by - py);
      if (d >= left || s + 1 >= p.length - 1) {
        const k = d > 0 ? Math.min(1, left / d) : 0;
        px += (bx - px) * k; py += (by - py) * k;
        if (d > 0) { hx = bx - p[s][0]; hy = by - p[s][1]; }
        break;
      }
      left -= d; px = bx; py = by; s++;
      hx = p[s + 1][0] - p[s][0]; hy = p[s + 1][1] - p[s][1];
    }
    const gx = p[p.length - 1][0], gy = p[p.length - 1][1], toGoal = Math.hypot(gx - px, gy - py);
    if (lane && toGoal > 0.01) {
      const hl = Math.hypot(hx, hy) || 1, nx = -hy / hl, ny = hx / hl;
      const q = cellOf(M, px, py), room = q >= 0 ? Math.max(0, M.clear[q] - o.WANT * 0.5) : 0;
      const shift = lane * Math.min(o.LANE, room * 0.6) * Math.min(1, toGoal / o.LOOK);   // fades in the last LOOK yards
      const sx2 = px + nx * shift, sy2 = py + ny * shift, q2 = cellOf(M, sx2, sy2);
      if (q2 >= 0 && !blocks(M.know[q2])) { px = sx2; py = sy2; }
    }
    return [px, py];
  }
  // steer: from heading h toward (tx, ty), turning at most TURN a second;
  // the new heading, and the share of full speed (slower while turning hard)
  function steer(M, x, y, h, tx, ty, dt) {
    const want = Math.atan2(ty - y, tx - x);
    let d = want - h;
    d -= Math.round(d / (2 * Math.PI)) * 2 * Math.PI;
    const most = M.opt.TURN * dt, turn = Math.max(-most, Math.min(most, d));
    return [h + turn, 0.4 + 0.6 * Math.max(0, Math.cos(d))];
  }
  // }}}

  // {{{ the crowd: where bots stand and where their routes run next
  // Remade each second from the bots: each bot's cell and its neighbours,
  // and its path's next CROWD_AHEAD yards, sampled a cell apart. A cell's
  // crowd cost is CROWD_W for each bot standing in it (half beside it) and
  // half that for each route running through it. Bots planning later go
  // round the crowd by a little: lanes, not a single file.
  function crowdAdd(M, x, y, v) {
    const w = M.w, q = cellOf(M, x, y); if (q < 0) return;
    const c = q % w, r = (q - c) / w;
    for (let dr = -1; dr <= 1; dr++) for (let dc = -1; dc <= 1; dc++) {
      const nc = c + dc, nr = r + dr; if (nc < 0 || nr < 0 || nc >= w || nr >= M.h) continue;
      M.crowd[nr * w + nc] += dr || dc ? v * 0.5 : v;
    }
  }
  // a route just planned joins the crowd at once, so bots planning in the
  // same moment see each other's lanes (until 2026-10-29 only the next
  // second's remaking counted it, and a dozen bots leaving together all
  // planned the same line: the test's spread was 3.9 yards against 3.1)
  function crowdRoute(M, path, fromX, fromY) {
    const p = path.pts, v = M.opt.CROWD_W * 0.5;
    let s = 0, x = fromX, y = fromY, left = M.opt.CROWD_AHEAD;
    while (left > 0 && s < p.length - 1) {
      const [bx, by] = p[s + 1], d = Math.hypot(bx - x, by - y), k = Math.min(d, left);
      for (let u = M.step; u <= k; u += M.step) crowdAdd(M, x + (bx - x) * u / d, y + (by - y) * u / d, v);
      left -= k; x = bx; y = by; s++;
    }
  }
  function crowd(M, bots) {
    M.crowd.fill(0);
    const W = M.opt.CROWD_W, w = M.w;
    const add = (x, y, v) => {
      const q = cellOf(M, x, y); if (q < 0) return;
      const c = q % w, r = (q - c) / w;
      for (let dr = -1; dr <= 1; dr++) for (let dc = -1; dc <= 1; dc++) {
        const nc = c + dc, nr = r + dr; if (nc < 0 || nr < 0 || nc >= w || nr >= M.h) continue;
        M.crowd[nr * w + nc] += dr || dc ? v * 0.5 : v;
      }
    };
    for (const b of bots) {
      add(b.x, b.y, W);
      const p = b.path && b.path.pts; if (!p) continue;
      let s = b.path.seg, x = b.x, y = b.y, left = M.opt.CROWD_AHEAD;
      while (left > 0 && s < p.length - 1) {
        const [bx, by] = p[s + 1], d = Math.hypot(bx - x, by - y), k = Math.min(d, left);
        for (let u = M.step; u <= k; u += M.step) add(x + (bx - x) * u / d, y + (by - y) * u / d, W * 0.5);
        left -= k; x = bx; y = by; s++;
      }
    }
  }
  // }}}

  return { DEFAULTS, UNKNOWN, PAINTED, WALL, STEEP, OUTSIDE, make, cellOf, cx, cy, blocks, setGround, clearAll,
           walked, wall, refused, costAt, plan, needsPlan, follow, steer, crowd, crowdRoute, fair };
})();

if (typeof module !== "undefined") module.exports = PaintPaths;
