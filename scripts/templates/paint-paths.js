
"use strict";
const PaintPaths = (function () {

  const DEFAULTS = {
    WANT:       4.0,
    WALL_W:     8.0,
    RELAX:     10.0,
    NEAR:      24.0,
    UNKNOWN:    0.0,
    CLUTTER_R:  6.0,
    CLUTTER_KEEP: 0.4,
    CROWD_W:    0.5,
    CROWD_AHEAD: 14,
    CLEAR_CAP:  8.0,
    LOOK:       6.0,
    LOOK_MIN:   2.5,
    SAFE:       1.0,
    TURN:       4.2,
    LANE:       4.0,
    REACH:     40.0,
    REPLAN:     6.0,
    ARRIVE:     1.5,
  };
  const UNKNOWN = 0, PAINTED = 1, WALL = 2, STEEP = 3, OUTSIDE = 4;
  const SQRT2 = Math.SQRT2;
  const now = typeof performance !== "undefined" ? () => performance.now() : () => Date.now();

  function make(w, h, step, x0, y0, opt) {
    const n = w * h;
    const M = {
      w, h, n, step, x0, y0,
      opt: Object.assign({}, DEFAULTS, opt || {}),
      know:  new Uint8Array(n),
      walks: new Uint16Array(n),
      clear: new Float32Array(n),
      crowd: new Float32Array(n),
      walls: [],
      version: 0,
      painted: 0, wallCells: 0, inside: n,
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
  const blocks = k => k >= WALL;
  const walling = k => k === WALL || k === STEEP;

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

  function walked(M, x, y) {
    const q = cellOf(M, x, y); if (q < 0) return;
    if (M.know[q] === UNKNOWN) { M.know[q] = PAINTED; M.painted++; }
    if (M.walks[q] < 65535) M.walks[q]++;
  }
  function wall(M, x0, y0, x1, y1, keep, ring) {
    let c0 = Math.ceil((x0 - M.x0) / M.step), c1 = Math.floor((x1 - M.x0) / M.step);
    let r0 = Math.ceil((y0 - M.y0) / M.step), r1 = Math.floor((y1 - M.y0) / M.step);
    if (c0 > c1) c0 = c1 = Math.round(((x0 + x1) / 2 - M.x0) / M.step);
    if (r0 > r1) r0 = r1 = Math.round(((y0 + y1) / 2 - M.y0) / M.step);
    c0 = Math.max(0, c0); r0 = Math.max(0, r0); c1 = Math.min(M.w - 1, c1); r1 = Math.min(M.h - 1, r1);
    let fresh = 0;
    for (let r = r0; r <= r1; r++) for (let c = c0; c <= c1; c++) {
      const q = r * M.w + c, k = M.know[q];
      if (blocks(k) || q === keep) continue;
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

  function refused(M, x, y, box, bx, by) {
    const keep = bx === undefined ? -1 : cellOf(M, bx, by);
    let fresh = box ? wall(M, box[0], box[1], box[2], box[3], keep, false) : 0;
    if (!fresh) fresh = wall(M, x, y, x, y, keep, true);
    M.stats.bumps++;
    return fresh;
  }

  function clutter(M, x, y) {
    const q = cellOf(M, x, y); if (q < 0) return 0;
    const R = Math.ceil(M.opt.CLUTTER_R / M.step), R2 = R * R, c0 = q % M.w, r0 = (q - c0) / M.w;
    let all = 0, walled = 0;
    for (let dr = -R; dr <= R; dr++) {
      const r = r0 + dr; if (r < 0 || r >= M.h) continue;
      for (let dc = -R; dc <= R; dc++) {
        const c = c0 + dc; if (c < 0 || c >= M.w || dc * dc + dr * dr > R2) continue;
        const k = M.know[r * M.w + c];
        if (k === OUTSIDE) continue;
        all++; if (walling(k)) walled++;
      }
    }
    return all ? walled / all : 0;
  }
  const wantAt = (M, cl) => M.opt.WANT * (1 - (1 - M.opt.CLUTTER_KEEP) * cl);

  function costAt(M, q, gx, gy, trip, want) {
    const o = M.opt, W = want === undefined ? o.WANT : want;
    let cost = 1;
    const cl = M.clear[q];
    if (cl < W) {
      const dx = cx(M, q) - gx, dy = cy(M, q) - gy, dg = Math.sqrt(dx * dx + dy * dy);
      const relax = Math.min(dg >= o.RELAX ? 1 : dg / o.RELAX, trip === undefined ? 1 : trip);
      const f = (W - cl) / W;
      cost += o.WALL_W * f * f * relax;
    }
    if (M.know[q] === UNKNOWN) cost += o.UNKNOWN;
    return cost + M.crowd[q];
  }

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
    const want = wantAt(M, clutter(M, sx, sy));
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
        const out = q === s && squeeze;
        if (blocks(know[n]) && !(out && know[n] === WALL)) continue;
        if (k >= 4 && !out && (blocks(know[qr * w + nc]) || blocks(know[nr * w + qc]))) continue;
        const ng = gq + (k >= 4 ? SQRT2 : 1) * st * costAt(M, n, gx, gy, trip, want);
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
    const gq = cellOf(M, gx, gy), goalOpen = gq >= 0 && !blocks(M.know[gq]) && fair(M, ax, ay, gx, gy, 0);
    if (pts.length === 1) pts.push(goalOpen ? [gx, gy] : [cx(M, cells[0]), cy(M, cells[0])]);
    else if (goalOpen) pts[pts.length - 1] = [gx, gy];
    let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
    for (const [x, y] of pts) { x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); }
    let len = 0;
    for (let i = 1; i < pts.length; i++) len += Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]);
    return { cells, pts, gx, gy, len, box: [x0, y0, x1, y1], seg: 0, at: 0 };
  }

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

  function follow(M, path, x, y, lane) {
    const o = M.opt;
    const L = o.LOOK_MIN + (o.LOOK - o.LOOK_MIN) * (1 - clutter(M, x, y));
    let near = null;
    for (const look of [L, L * 0.6, L * 0.35, 1.5]) {
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
      const shift = lane * Math.min(o.LANE, room * 0.6) * Math.min(1, toGoal / o.LOOK);
      const sx2 = px + nx * shift, sy2 = py + ny * shift, q2 = cellOf(M, sx2, sy2);
      if (q2 >= 0 && !blocks(M.know[q2])) { px = sx2; py = sy2; }
    }
    return [px, py];
  }
  function steer(M, x, y, h, tx, ty, dt) {
    const want = Math.atan2(ty - y, tx - x);
    let d = want - h;
    d -= Math.round(d / (2 * Math.PI)) * 2 * Math.PI;
    const most = M.opt.TURN * dt, turn = Math.max(-most, Math.min(most, d));
    return [h + turn, 0.4 + 0.6 * Math.max(0, Math.cos(d))];
  }

  function crowdAdd(M, x, y, v) {
    const w = M.w, q = cellOf(M, x, y); if (q < 0) return;
    const c = q % w, r = (q - c) / w;
    for (let dr = -1; dr <= 1; dr++) for (let dc = -1; dc <= 1; dc++) {
      const nc = c + dc, nr = r + dr; if (nc < 0 || nr < 0 || nc >= w || nr >= M.h) continue;
      M.crowd[nr * w + nc] += dr || dc ? v * 0.5 : v;
    }
  }
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

  return { DEFAULTS, UNKNOWN, PAINTED, WALL, STEEP, OUTSIDE, make, cellOf, cx, cy, blocks, setGround, clearAll,
           walked, wall, refused, costAt, plan, needsPlan, follow, steer, crowd, crowdRoute, fair, clutter, wantAt };
})();

if (typeof module !== "undefined") module.exports = PaintPaths;
