// explore-engine.js - the walking and choosing behind the cave comparison
// (issue 617e, "the pull toward openings", brainstorm of 2026-10-07). No
// drawing here: the page (compare.js) draws, the test
// (scripts/test-exploration-engine) runs this same file headless in node.
//
// For a general audience: a floor (from scripts/generate-exploration-floors)
// is made ready to walk: which squares join the entrance, how far each is
// from a wall, how far on foot from the entrance, and its skeleton. Then a
// clan of buddies is set walking under one of three rules, and the same
// yardsticks are kept for every rule. See compare.js's header for the rules.
(function (global) {
  "use strict";
  // {{{ numbers
  const DT          = 0.1;   // simulated seconds a step
  const RUN         = 7.0;   // yards a second (a character's run)
  const SIGHT_SEEN  = 20;    // yards: the yardstick's "seen from close"
  const SIGHT_FRONT = 40;    // yards: the frontier clan's sight
  const FORGET      = 240;   // seconds before the frontier clan forgets it saw a square
  const CLAIM       = 12;    // yards: a frontier spot this near another buddy's goal is taken
  const RING_BAND   = 2;     // percent either side of Y: the band a rings waypoint is drawn from
  const SPUR        = 6;     // yards: skeleton twigs shorter than this are shaved off
  const MERGE       = 3;     // yards: forks joined by a shorter run are one fork
  // the decided design (2026-10-07): survey close, then patrol by glancing
  const EXPLORE     = 5;     // yards: floor this near (and in view) counts as explored
  const MOVE_LOOK   = 2;     // yards walked between looks; standing still sees nothing new
  const WATCH_COVER = 0.98;  // share of the floor the watchman stops must see between them
  const FAR_END     = 10;    // yards: a skeleton tip on a branch at least this long is a far end
  const REACH       = 5;     // yards: standing this near a far end reaches it
  const BLOCK       = 6;     // yards: footprint blocks for the evenness measure
  const HISTORY     = 5;     // seconds between chart points
  const DIRS8 = [[1, 0, 1], [-1, 0, 1], [0, 1, 1], [0, -1, 1], [1, 1, Math.SQRT2], [1, -1, Math.SQRT2], [-1, 1, Math.SQRT2], [-1, -1, Math.SQRT2]];
  // }}}

  // {{{ seeded random numbers (the same seed for all three, so they start alike)
  function rng(seed) {
    let a = seed >>> 0;
    return function () {
      a = (a + 0x6D2B79F5) >>> 0;
      let t = a;
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  // }}}

  // {{{ a small heap of (key, cell) pairs, lowest key first
  function Heap(cap) {
    this.k = new Float64Array(cap); this.v = new Int32Array(cap); this.n = 0;
  }
  Heap.prototype.push = function (key, val) {
    if (this.n >= this.k.length) {
      const k2 = new Float64Array(this.k.length * 2); k2.set(this.k); this.k = k2;
      const v2 = new Int32Array(this.v.length * 2); v2.set(this.v); this.v = v2;
    }
    let i = this.n++;
    const k = this.k, v = this.v;
    while (i > 0) {
      const p = (i - 1) >> 1;
      if (k[p] <= key) break;
      k[i] = k[p]; v[i] = v[p]; i = p;
    }
    k[i] = key; v[i] = val;
  };
  Heap.prototype.pop = function () {
    const k = this.k, v = this.v;
    const top = v[0], topKey = k[0];
    const lastK = k[--this.n], lastV = v[this.n];
    let i = 0;
    for (;;) {
      let c = 2 * i + 1;
      if (c >= this.n) break;
      if (c + 1 < this.n && k[c + 1] < k[c]) c++;
      if (k[c] >= lastK) break;
      k[i] = k[c]; v[i] = v[c]; i = c;
    }
    k[i] = lastK; v[i] = lastV;
    this.lastKey = topKey;
    return top;
  };
  // }}}

  // {{{ decoding the floors
  function unb64(s) {
    const bin = atob(s);
    const u = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) u[i] = bin.charCodeAt(i);
    return u;
  }
  function bitsOf(u, n) {
    const out = new Uint8Array(n);
    for (let o = 0; o < n; o++) out[o] = (u[o >> 3] >> (o & 7)) & 1;
    return out;
  }
  // }}}

  // {{{ buildMap: one floor, made ready to walk
  // A floor bigger than 200,000 squares is drawn at two yards a square (the
  // whole of Wailing Caverns), so the three clans stay quick in the browser.
  function buildMap(F) {
    const W0 = F.w, H0 = F.h, n0 = W0 * H0;
    const open0 = bitsOf(unb64(F.open), n0), in0 = bitsOf(unb64(F.inside), n0);
    const zb = unb64(F.z);
    const z0 = new Int16Array(zb.buffer, 0, n0);
    const f = n0 > 200000 ? 2 : 1;
    const W = Math.ceil(W0 / f), H = Math.ceil(H0 / f), N = W * H;
    const open = new Uint8Array(N), inside = new Uint8Array(N), z = new Float32Array(N);
    for (let j = 0; j < H; j++) for (let i = 0; i < W; i++) {
      let c = 0, ins = 0, zs = 0;
      for (let b = 0; b < f; b++) for (let a = 0; a < f; a++) {
        const ii = i * f + a, jj = j * f + b;
        if (ii >= W0 || jj >= H0) continue;
        const o = jj * W0 + ii;
        if (open0[o]) { c++; ins += in0[o]; zs += z0[o] / 4; }
      }
      // a block counts as floor when half of it is floor: thin slivers of
      // floor along a wall don't join two passages through the wall
      if (c * 2 >= f * f) { const o = j * W + i; open[o] = 1; inside[o] = ins * 2 >= c ? 1 : 0; z[o] = zs / c; }
    }
    // the start: the nearest floor square to the generator's start point
    let s = Math.min(H - 1, Math.floor(F.start[1] / f)) * W + Math.min(W - 1, Math.floor(F.start[0] / f));
    if (!open[s]) {
      let best = -1, bd = 1e18;
      const si = s % W, sj = (s / W) | 0;
      for (let o = 0; o < N; o++) if (open[o]) {
        const d = (o % W - si) ** 2 + (((o / W) | 0) - sj) ** 2;
        if (d < bd) { bd = d; best = o; }
      }
      s = best;
    }
    const M = { key: F.key, title: F.title, note: F.note, W, H, N, f, yd: F.cell * f, open, inside, z, zlo: F.zlo, zhi: F.zhi, start: s, picture: F.picture, W0, H0, stats: F.stats };
    reachable(M);
    wallDistance(M);
    walkingDistance(M);
    skeleton(M);
    return M;
  }
  // }}}

  // {{{ reachable: only the floor joined to the start is walked (anything else drawn dim)
  function reachable(M) {
    const { W, H, N, open } = M;
    const reach = new Uint8Array(N), q = new Int32Array(N);
    let h = 0, t = 0;
    q[t++] = M.start; reach[M.start] = 1;
    while (h < t) {
      const c = q[h++], i = c % W, j = (c / W) | 0;
      for (const [di, dj] of DIRS8) {
        const i2 = i + di, j2 = j + dj;
        if (i2 < 0 || j2 < 0 || i2 >= W || j2 >= H) continue;
        const c2 = j2 * W + i2;
        if (!open[c2] || reach[c2]) continue;
        if (di && dj && (!open[j * W + i2] || !open[j2 * W + i])) continue;   // no squeezing between two corners
        reach[c2] = 1; q[t++] = c2;
      }
    }
    M.reach = reach; M.count = t; M.cells = q.slice(0, t);
  }
  // }}}

  // {{{ wallDistance: squares to the nearest non-floor square (two sweeps, 1 and 1.4 steps)
  function wallDistance(M) {
    const { W, H, N, reach } = M;
    const d = new Float32Array(N);
    for (let c = 0; c < N; c++) d[c] = reach[c] ? 1e9 : 0;
    const at = (i, j) => (i < 0 || j < 0 || i >= W || j >= H) ? 0 : d[j * W + i];
    for (let j = 0; j < H; j++) for (let i = 0; i < W; i++) {
      const c = j * W + i; if (!d[c]) continue;
      d[c] = Math.min(d[c], at(i - 1, j) + 1, at(i, j - 1) + 1, at(i - 1, j - 1) + 1.414, at(i + 1, j - 1) + 1.414);
    }
    for (let j = H - 1; j >= 0; j--) for (let i = W - 1; i >= 0; i--) {
      const c = j * W + i; if (!d[c]) continue;
      d[c] = Math.min(d[c], at(i + 1, j) + 1, at(i, j + 1) + 1, at(i + 1, j + 1) + 1.414, at(i - 1, j + 1) + 1.414);
    }
    M.wall = d;
  }
  // }}}

  // {{{ walkingDistance: yards on foot from the start (water poured at the entrance), and each square's place in that order
  function walkingDistance(M) {
    const g = new Float32Array(M.N);
    geoFrom(M, M.start, g);
    const order = Array.from(M.cells).sort((a, b) => g[a] - g[b]);
    const rank = new Float32Array(M.N);
    order.forEach((c, k) => { rank[c] = k / order.length; });
    M.geo = g; M.byGeo = Int32Array.from(order); M.rank = rank; M.geoMax = g[order[order.length - 1]];
  }
  // geoFrom: yards on foot from one square to every square, into g (Infinity where unreachable)
  function geoFrom(M, start, g) {
    const { W, H, reach } = M;
    g.fill(Infinity);
    const heap = new Heap(4096);
    g[start] = 0; heap.push(0, start);
    while (heap.n) {
      const c = heap.pop(), key = heap.lastKey;
      if (key > g[c]) continue;
      const i = c % W, j = (c / W) | 0;
      for (const [di, dj, w] of DIRS8) {
        const i2 = i + di, j2 = j + dj;
        if (i2 < 0 || j2 < 0 || i2 >= W || j2 >= H) continue;
        const c2 = j2 * W + i2;
        if (!reach[c2]) continue;
        if (di && dj && (!reach[j * W + i2] || !reach[j2 * W + i])) continue;
        const nd = key + w * M.yd;
        // the queue gets the distance as stored (single precision), not as worked out: a
        // stored value rounded below the worked-out one made the "is this entry stale?"
        // test above discard live entries, and the flood stopped a few hundred squares out
        // (2026-10-07: 178 of Jasperlode's 4,261 squares reached)
        if (nd < g[c2]) { g[c2] = nd; heap.push(g[c2], c2); }
      }
    }
  }
  // }}}

  // {{{ skeleton: shave the floor from its edges until one square wide (Zhang and Suen's thinning), then its graph
  function skeleton(M) {
    const { W, H, N, reach } = M;
    const s = Uint8Array.from(reach);
    const P = (i, j) => (i < 0 || j < 0 || i >= W || j >= H) ? 0 : s[j * W + i];
    const del = [];
    let changed = true;
    while (changed) {
      changed = false;
      for (let pass = 0; pass < 2; pass++) {
        del.length = 0;
        for (let k = 0; k < M.count; k++) {
          const c = M.cells[k];
          if (!s[c]) continue;
          const i = c % W, j = (c / W) | 0;
          const p2 = P(i, j - 1), p3 = P(i + 1, j - 1), p4 = P(i + 1, j), p5 = P(i + 1, j + 1);
          const p6 = P(i, j + 1), p7 = P(i - 1, j + 1), p8 = P(i - 1, j), p9 = P(i - 1, j - 1);
          const b = p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9;
          if (b < 2 || b > 6) continue;
          const seq = [p2, p3, p4, p5, p6, p7, p8, p9, p2];
          let a = 0;
          for (let m = 0; m < 8; m++) if (!seq[m] && seq[m + 1]) a++;
          if (a !== 1) continue;
          if (pass === 0 ? (p2 * p4 * p6 || p4 * p6 * p8) : (p2 * p4 * p8 || p2 * p6 * p8)) continue;
          del.push(c);
        }
        if (del.length) { changed = true; for (const c of del) s[c] = 0; }
      }
    }
    // the graph: knots (ends, and forks merged where fork squares touch) and the runs between them.
    // A square's branches are counted by walking once round its eight neighbours and counting
    // each step from empty onto line ("crossing number"): a staircase step of the line has two
    // line neighbours side by side but is still one way in and one way out, 2; a tip is 1; a
    // fork 3 or more. Counting neighbours instead would call every staircase step a fork.
    const deg = new Uint8Array(N);
    const skel = [];
    for (let c = 0; c < N; c++) if (s[c]) {
      skel.push(c);
      const i = c % W, j = (c / W) | 0;
      const seq = [P(i, j - 1), P(i + 1, j - 1), P(i + 1, j), P(i + 1, j + 1), P(i, j + 1), P(i - 1, j + 1), P(i - 1, j), P(i - 1, j - 1)];
      let n = 0;
      for (let m = 0; m < 8; m++) if (!seq[m] && seq[(m + 1) % 8]) n++;
      deg[c] = n;
    }
    // knots: squares of the line that are not plain line (tips, forks), grouped where they touch.
    // A fork also takes the line squares right round it: its branches can touch one another
    // corner to corner there, and would otherwise run together into one stretch of line.
    const neighbours = c => {
      const i = c % W, j = (c / W) | 0, out = [];
      for (const [di, dj] of DIRS8) if (P(i + di, j + dj)) out.push((j + dj) * W + (i + di));
      return out;
    };
    const knotMask = new Uint8Array(N);
    for (const c of skel) if (deg[c] !== 2) { knotMask[c] = 1; if (deg[c] >= 3) for (const d of neighbours(c)) knotMask[d] = 1; }
    const isKnot = c => knotMask[c] === 1;
    const knotOf = new Int32Array(N).fill(-1);
    const knots = [];
    for (const c of skel) {
      if (!isKnot(c) || knotOf[c] >= 0) continue;
      const id = knots.length, cells = [c], q = [c];
      knotOf[c] = id;
      while (q.length) for (const d2 of neighbours(q.pop())) if (isKnot(d2) && knotOf[d2] < 0) { knotOf[d2] = id; cells.push(d2); q.push(d2); }
      knots.push({ id, cell: cells[0], cells, edges: [], end: cells.length === 1 && deg[c] === 1 });
    }
    // runs: each unbroken stretch of plain line, collected whole, joined to the knots it
    // touches; the walk along it is the shortest way through its own squares from one
    // knot to the other (a thinned line can turn in ways a step-by-step tracer loses)
    const runOf = new Int32Array(N).fill(-1);
    const inRun = new Int32Array(N).fill(-1), parent = new Int32Array(N);
    const edges = [];
    let runs = 0;
    for (const c of skel) {
      if (isKnot(c) || runOf[c] >= 0) continue;
      const id = runs++, cells = [c], q = [c], touch = new Map();
      runOf[c] = id;
      while (q.length) for (const d2 of neighbours(q.pop())) {
        if (isKnot(d2)) { if (!touch.has(knotOf[d2])) touch.set(knotOf[d2], d2); continue; }
        if (runOf[d2] < 0) { runOf[d2] = id; cells.push(d2); q.push(d2); }
      }
      const ends = [...touch.entries()];
      if (ends.length < 2) continue;   // a ring of line with one door or none: not a passage between two places
      for (const d of cells) inRun[d] = id;
      const [ka, pa] = ends[0];
      for (let m = 1; m < ends.length; m++) {
        const [kb, pb] = ends[m];
        // shortest way pa -> pb through this run's squares
        const bq = [pa], seen = new Set([pa]);
        parent[pa] = -1;
        let found = false;
        while (bq.length && !found) {
          const d = bq.shift();
          for (const d2 of neighbours(d)) {
            if (seen.has(d2) || !(inRun[d2] === id || d2 === pb)) continue;
            seen.add(d2); parent[d2] = d; bq.push(d2);
            if (d2 === pb) { found = true; break; }
          }
        }
        if (!found) continue;
        const path = [];
        for (let d = pb; d >= 0; d = parent[d]) path.push(d);
        path.reverse();
        let len = 0;
        for (let n = 1; n < path.length; n++) {
          const a = path[n - 1], b = path[n];
          len += ((a % W !== b % W) && (((a / W) | 0) !== ((b / W) | 0)) ? Math.SQRT2 : 1) * M.yd;
        }
        const e = { id: edges.length, a: ka, b: kb, path, len, cut: false };
        edges.push(e); knots[ka].edges.push(e.id); knots[kb].edges.push(e.id);
      }
    }
    // forks closer than MERGE yards are one fork: a wide junction thins into a little
    // knot of short runs, and a buddy choosing among them would circle inside the junction
    const rep = knots.map(k => k.id);
    const find = a => { while (rep[a] !== a) { rep[a] = rep[rep[a]]; a = rep[a]; } return a; };
    for (const e of edges) {
      if (e.len < MERGE && knots[e.a].edges.length > 1 && knots[e.b].edges.length > 1) {
        rep[find(e.a)] = find(e.b); e.cut = true;
      }
    }
    for (const k of knots) k.edges = [];
    for (const e of edges) {
      if (e.cut) continue;
      e.a = find(e.a); e.b = find(e.b);
      knots[e.a].edges.push(e.id); if (e.b !== e.a) knots[e.b].edges.push(e.id);
    }
    // twigs: a run from a tip shorter than SPUR is shaved off
    for (const e of edges) {
      if (e.cut) continue;
      const ka = knots[e.a], kb = knots[e.b];
      if ((ka.edges.length === 1 || kb.edges.length === 1) && e.len < SPUR && ka.edges.length + kb.edges.length > 2) e.cut = true;
    }
    const live = k => k.edges.filter(id => !edges[id].cut);
    const farEnds = [];
    for (const k of knots) {
      const es = live(k);
      if (es.length === 1 && edges[es[0]].len >= FAR_END) farEnds.push(k.cell);
    }
    M.skel = s; M.knots = knots; M.edges = edges; M.liveEdges = live; M.farEnds = farEnds;
  }
  // }}}

  // {{{ pathTo: the walk from a to b (A*, kept off the walls where there is room)
  function makePather(M) {
    const { W, H, N, reach, wall } = M;
    const g = new Float32Array(N), came = new Int32Array(N), stamp = new Uint32Array(N), shut = new Uint32Array(N);
    let gen = 0;
    const heap = new Heap(4096);
    return function (a, b) {
      gen++;
      heap.n = 0;
      const bi = b % W, bj = (b / W) | 0;
      const hdist = c => { const dx = Math.abs(c % W - bi), dy = Math.abs(((c / W) | 0) - bj); return (Math.max(dx, dy) + 0.414 * Math.min(dx, dy)); };
      g[a] = 0; stamp[a] = gen; came[a] = -1; heap.push(hdist(a), a);
      while (heap.n) {
        const c = heap.pop();
        if (shut[c] === gen) continue;
        shut[c] = gen;
        if (c === b) break;
        const i = c % W, j = (c / W) | 0;
        for (const [di, dj, w] of DIRS8) {
          const i2 = i + di, j2 = j + dj;
          if (i2 < 0 || j2 < 0 || i2 >= W || j2 >= H) continue;
          const c2 = j2 * W + i2;
          if (!reach[c2] || shut[c2] === gen) continue;
          if (di && dj && (!reach[j * W + i2] || !reach[j2 * W + i])) continue;
          const near = wall[c2] < 2.5 ? (2.5 - wall[c2]) * 1.2 : 0;   // a little dearer beside a wall
          const ng = g[c] + w * (1 + near);
          if (stamp[c2] !== gen || ng < g[c2]) { g[c2] = ng; stamp[c2] = gen; came[c2] = c; heap.push(ng + hdist(c2), c2); }
        }
      }
      if (shut[b] !== gen) return [];
      const path = [];
      for (let c = b; c !== a && c >= 0; c = came[c]) path.push(c);
      return path.reverse();
    };
  }
  // }}}

  // {{{ sight: mark squares in view within `yards`, sight stopped by anything not floor
  function look(M, x, y, yards, rays, mark) {
    const r = yards / M.yd;
    for (let k = 0; k < rays; k++) {
      const a = (k / rays) * Math.PI * 2, dx = Math.cos(a), dy = Math.sin(a);
      for (let s = 0; s <= r; s += 0.7) {
        const i = Math.floor(x + dx * s), j = Math.floor(y + dy * s);
        if (i < 0 || j < 0 || i >= M.W || j >= M.H) break;
        const c = j * M.W + i;
        if (!M.reach[c]) break;
        mark(c);
      }
    }
  }
  // }}}

  // {{{ shadowcast: every square in view within `radius` squares of (cx, cy), each marked once or twice
  // The roguelike field of view (recursive shadowcasting): the circle round the looker is cut
  // into eight slices; each slice is swept row by row outward, keeping the range of angles not
  // yet hidden; a wall square narrows the range for the rows beyond it, and a gap in a wall
  // starts a new sweep through the gap. Unlike sight lines, it never visits a square twice per
  // slice and never skips a far square between two lines.
  const OCT = [[1, 0, 0, -1, -1, 0, 0, 1], [0, 1, -1, 0, 0, -1, 1, 0], [0, 1, 1, 0, 0, -1, -1, 0], [1, 0, 0, 1, -1, 0, 0, -1]];
  function shadowcast(M, cx, cy, radius, mark) {
    const { W, H, reach } = M;
    const solid = (x, y) => x < 0 || y < 0 || x >= W || y >= H || !reach[y * W + x];
    if (!solid(cx, cy)) mark(cy * W + cx);
    const r2 = radius * radius;
    function cast(row, start, end, xx, xy, yx, yy) {
      if (start < end) return;
      let newStart = 0;
      for (let j = row; j <= radius; j++) {
        let dx = -j - 1;
        const dy = -j;
        let blocked = false;
        while (dx <= 0) {
          dx++;
          const X = cx + dx * xx + dy * xy, Y = cy + dx * yx + dy * yy;
          const lSlope = (dx - 0.5) / (dy + 0.5), rSlope = (dx + 0.5) / (dy - 0.5);
          if (start < rSlope) continue;
          if (end > lSlope) break;
          if (dx * dx + dy * dy <= r2 && !solid(X, Y)) mark(Y * W + X);
          if (blocked) {
            if (solid(X, Y)) { newStart = rSlope; continue; }
            blocked = false; start = newStart;
          } else if (solid(X, Y) && j < radius) {
            blocked = true;
            cast(j + 1, start, lSlope, xx, xy, yx, yy);
            newStart = rSlope;
          }
        }
        if (blocked) break;
      }
    }
    for (let o = 0; o < 8; o++) cast(1, 1.0, 0.0, OCT[0][o], OCT[1][o], OCT[2][o], OCT[3][o]);
  }
  // }}}

  // {{{ watchman: the stops from which the whole floor is seen, and one short loop through them
  // Built once per floor, when a clan first finishes its survey. Candidates are the skeleton's
  // knots and a square every 6 yards along its runs. Stops are taken greedily: the candidate
  // that sees the most floor not yet seen by a stop, again and again, until WATCH_COVER of the
  // floor is seen (the last corners would each need a stop of their own). The loop is the
  // nearest-next tour by walking distance, tidied by "2-opt": wherever two legs cross,
  // the stretch between them is walked the other way round.
  function watchman(M) {
    if (M.watch) return M.watch;
    const R = SIGHT_FRONT / M.yd, every = Math.max(1, Math.round(6 / M.yd));
    const cand = new Set();
    for (const k of M.knots) if (M.liveEdges(k).length) cand.add(k.cell);
    for (const e of M.edges) if (!e.cut) for (let i = 0; i < e.path.length; i += every) cand.add(e.path[i]);
    const cands = [...cand];
    const vis = cands.map(c => { const out = []; shadowcast(M, c % M.W, (c / M.W) | 0, R, x => out.push(x)); return Int32Array.from(out); });
    const covered = new Uint8Array(M.N), taken = new Uint8Array(cands.length), stops = [];
    let seen = 0;
    while (seen < M.count * WATCH_COVER) {
      let best = -1, gain = 0;
      for (let i = 0; i < cands.length; i++) {
        if (taken[i]) continue;
        let g = 0;
        const v = vis[i];
        for (let j = 0; j < v.length; j++) if (!covered[v[j]]) g++;
        if (g > gain) { gain = g; best = i; }
      }
      if (best < 0 || gain < 3) break;
      taken[best] = 1; stops.push(cands[best]);
      for (const c of vis[best]) if (!covered[c]) { covered[c] = 1; seen++; }
    }
    const k = stops.length, D = new Float64Array(k * k), g = new Float32Array(M.N);
    for (let a = 0; a < k; a++) { geoFrom(M, stops[a], g); for (let b = 0; b < k; b++) D[a * k + b] = g[stops[b]]; }
    const tour = [0], inTour = new Uint8Array(k);
    inTour[0] = 1;
    for (let s = 1; s < k; s++) {
      const last = tour[tour.length - 1];
      let bi = -1, bd = Infinity;
      for (let j = 0; j < k; j++) if (!inTour[j] && D[last * k + j] < bd) { bd = D[last * k + j]; bi = j; }
      tour.push(bi); inTour[bi] = 1;
    }
    let better = true, passes = 0;
    while (better && passes++ < 50) {
      better = false;
      for (let i = 0; i < k - 2; i++) for (let j = i + 2; j < k; j++) {
        if (i === 0 && j === k - 1) continue;
        const a = tour[i], b = tour[i + 1], c = tour[j], d = tour[(j + 1) % k];
        if (D[a * k + c] + D[b * k + d] < D[a * k + b] + D[c * k + d] - 1e-6) {
          for (let l = i + 1, r = j; l < r; l++, r--) { const t = tour[l]; tour[l] = tour[r]; tour[r] = t; }
          better = true;
        }
      }
    }
    let length = 0;
    for (let i = 0; i < k; i++) length += D[tour[i] * k + tour[(i + 1) % k]];
    M.watch = { tour: tour.map(i => stops[i]), length, covered: seen / M.count, candidates: cands.length };
    return M.watch;
  }
  // }}}

  // {{{ the decided design's pieces: looking, the survey's edge, the patrol's next stop
  function decidedLook(S, b) {
    const M = S.M, ci = Math.floor(b.x), cj = Math.floor(b.y);
    b.lookX = b.x; b.lookY = b.y;
    shadowcast(M, ci, cj, EXPLORE / M.yd, c => { if (!S.explored[c]) { S.explored[c] = 1; S.exploredCount++; } });
    // the 40-yard glance is the patrol's (in the game it also spots monsters while surveying,
    // which this drawing has none of, so here it is skipped until the patrol begins)
    if (S.phase === "patrol") shadowcast(M, ci, cj, SIGHT_FRONT / M.yd, c => { S.checkedAt[c] = S.t; });
  }
  function bordersUnexplored(S, c) {
    const M = S.M, W = M.W, i = c % W, j = (c / W) | 0;
    for (const [di, dj] of DIRS8) {
      const i2 = i + di, j2 = j + dj;
      if (i2 >= 0 && j2 >= 0 && i2 < W && j2 < M.H && M.reach[j2 * W + i2] && !S.explored[j2 * W + i2]) return true;
    }
    return false;
  }
  // the nearest explored square on foot that touches unexplored floor and is not within
  // CLAIM yards of another buddy's goal; null when there is none left (the survey is done)
  function surveyPick(S, b) {
    const M = S.M, W = M.W;
    const goals = S.buddies.filter(o => o !== b && o.goal >= 0 && o.edgeGoal).map(o => o.goal);
    const claimed = c => goals.some(g => ((g % W - c % W) ** 2 + (((g / W) | 0) - ((c / W) | 0)) ** 2) * M.yd * M.yd < CLAIM * CLAIM);
    const mark = S.mark, q = S.queue;
    S.gen++;
    let h = 0, tl = 0, any = false;
    q[tl++] = b.cell; mark[b.cell] = S.gen;
    while (h < tl) {
      const c = q[h++], i = c % W, j = (c / W) | 0;
      if (S.explored[c] && bordersUnexplored(S, c)) {
        any = true;
        if (!claimed(c)) { b.goal = c; b.edgeGoal = true; return S.path(b.cell, c); }
      }
      for (const [di, dj] of DIRS8) {
        const i2 = i + di, j2 = j + dj;
        if (i2 < 0 || j2 < 0 || i2 >= W || j2 >= M.H) continue;
        const c2 = j2 * W + i2;
        if (!M.reach[c2] || mark[c2] === S.gen) continue;
        if (di && dj && (!M.reach[j * W + i2] || !M.reach[j2 * W + i])) continue;
        mark[c2] = S.gen; q[tl++] = c2;
      }
    }
    // edges remain but every one is claimed: walk toward the nearest unexplored square anyway
    if (any) {
      for (let k = 0; k < tl; k++) if (!S.explored[q[k]]) { b.goal = q[k]; b.edgeGoal = true; return S.path(b.cell, q[k]); }
    }
    return null;
  }
  // }}}

  // {{{ the choosers: each gets a buddy at the end of its walk and sets its next walk
  const METHODS = {
    rings: {
      label: "Walking rings",
      // the owner's Y rule, read as a percent of the floor by walking distance
      init(S, b) { b.Y = 10 + Math.floor(S.r() * 81); },
      pick(S, b) {
        const M = S.M;
        b.Y = Math.max(1, Math.min(100, b.Y + (S.r() < 0.5 ? -1 : 1) * (1 + Math.floor(S.r() * 20))));
        const lo = Math.max(0, Math.floor((b.Y - RING_BAND) / 100 * M.count));
        const hi = Math.min(M.count - 1, Math.floor((b.Y + RING_BAND) / 100 * M.count));
        const goal = M.byGeo[lo + Math.floor(S.r() * (hi - lo + 1))];
        return S.path(b.cell, goal);
      },
    },
    frontier: {
      label: "Unseen edge",
      init() {},
      pick(S, b) {
        const M = S.M, W = M.W, t = S.t;
        const fresh = c => S.seenAt[c] > t - FORGET;
        const goals = S.buddies.filter(o => o !== b && o.goal >= 0).map(o => o.goal);
        const claimed = c => goals.some(g => ((g % W - c % W) ** 2 + (((g / W) | 0) - ((c / W) | 0)) ** 2) * M.yd * M.yd < CLAIM * CLAIM);
        // walk outward from the buddy (shortest walk first) to the first claimable edge of the seen floor
        const came = S.came, mark = S.mark, q = S.queue;
        S.gen++;
        let h = 0, tl = 0;
        q[tl++] = b.cell; mark[b.cell] = S.gen; came[b.cell] = -1;
        let found = -1;
        while (h < tl && found < 0) {
          const c = q[h++], i = c % W, j = (c / W) | 0;
          if (fresh(c) && c !== b.cell) {
            for (const [di, dj] of DIRS8) {
              const c2 = (j + dj) * W + (i + di);
              if (i + di >= 0 && j + dj >= 0 && i + di < W && j + dj < M.H && M.reach[c2] && !fresh(c2)) { if (!claimed(c)) found = c; break; }
            }
          }
          for (const [di, dj] of DIRS8) {
            const i2 = i + di, j2 = j + dj;
            if (i2 < 0 || j2 < 0 || i2 >= W || j2 >= M.H) continue;
            const c2 = j2 * W + i2;
            if (!M.reach[c2] || mark[c2] === S.gen) continue;
            if (di && dj && (!M.reach[j * W + i2] || !M.reach[j2 * W + i])) continue;
            mark[c2] = S.gen; came[c2] = c; q[tl++] = c2;
          }
        }
        if (found >= 0) { b.goal = found; b.edgeGoal = true; return S.path(b.cell, found); }
        // nothing left unseen: go to the square seen longest ago, of a handful drawn at random
        let best = M.cells[0], age = Infinity;
        for (let k = 0; k < 64; k++) { const c = M.cells[Math.floor(S.r() * M.count)]; if (S.seenAt[c] < age) { age = S.seenAt[c]; best = c; } }
        b.goal = best; b.edgeGoal = false;
        return S.path(b.cell, best);
      },
      // an edge of the unseen that has been seen all round on the way is dropped for a
      // new one (a walk to the longest-ago-seen square is never dropped: it has no edge)
      stale(S, b) {
        if (b.goal < 0 || !b.edgeGoal) return false;
        const M = S.M, W = M.W, i = b.goal % W, j = (b.goal / W) | 0;
        for (const [di, dj] of DIRS8) {
          const c2 = (j + dj) * W + (i + di);
          if (i + di >= 0 && j + dj >= 0 && i + di < W && j + dj < M.H && M.reach[c2] && S.seenAt[c2] <= S.t - FORGET) return false;
        }
        return true;
      },
    },
    skeleton: {
      label: "Floor skeleton",
      init(S, b) { b.knot = -1; b.cameBy = -1; },
      pick(S, b) {
        const M = S.M;
        if (b.knot < 0) {
          // first: walk to the knot of the skeleton nearest on foot
          let best = -1, bd = Infinity;
          for (const k of M.knots) { if (!M.liveEdges(k).length) continue; const dd = Math.abs(M.geo[k.cell] - M.geo[b.cell]); if (dd < bd) { bd = dd; best = k.id; } }
          if (best < 0) return [];
          b.knot = best;
          return S.path(b.cell, M.knots[best].cell);
        }
        const k = M.knots[b.knot];
        const es = M.liveEdges(k).map(id => M.edges[id]);
        if (!es.length) return [];
        // Tremaux's rule for mazes, kept by the clan together: a run is marked each
        // time someone sets off along it. Take an unmarked run if there is one; else
        // go back the way you came, if it is marked only once; else the least-marked
        // run. When every run is marked twice the whole skeleton has been walked
        // there and back, and the marks are wiped for a new round.
        const marks = S.marks;
        const fresh = es.filter(e => marks[e.id] === 0 && e.id !== b.cameBy);
        let pick = null;
        if (fresh.length) pick = fresh[Math.floor(S.r() * fresh.length)];
        else if (b.cameBy >= 0 && marks[b.cameBy] < 2 && es.some(e => e.id === b.cameBy)) pick = M.edges[b.cameBy];
        else {
          for (const e of es) if (!pick || marks[e.id] < marks[pick.id] || (marks[e.id] === marks[pick.id] && S.used[e.id] < S.used[pick.id])) pick = e;
          if (marks[pick.id] >= 2) { marks.fill(0); S.rounds++; }
        }
        marks[pick.id]++;
        S.used[pick.id] = S.t;
        const fwd = pick.a === b.knot;
        const run = fwd ? pick.path.slice(1) : pick.path.slice(0, -1).reverse();
        b.knot = fwd ? pick.b : pick.a;
        b.cameBy = pick.id;
        const lead = S.path(b.cell, fwd ? pick.path[0] : pick.path[pick.path.length - 1]);
        return lead.concat(run);
      },
    },
    // The design decided from the three above (owner, 2026-10-07; issue 617e):
    // survey  - the unseen edge, where "explored" means within 5 yards and in view;
    //           looks are shadowcast, and only after walking 2 yards; nothing is forgotten
    // patrol  - once nothing is left unexplored: one loop through the watchman stops;
    //           each buddy joins at the stop nearest where its survey ended, walks the
    //           loop a random way round, glancing 40 yards at each stop; one that would
    //           head for the stop another is already heading for skips past it or turns
    //           round. (Monsters are not drawn here; in the game a buddy fights what it
    //           finds, then plans its walk again.)
    decided: {
      label: "Survey, then patrol",
      setup(S) {
        S.explored = new Uint8Array(S.M.N); S.exploredCount = 0;
        S.checkedAt = new Float32Array(S.M.N).fill(-1e9);
        S.phase = "survey"; S.patrolFrom = null;
      },
      init(S, b) { b.lookX = -1e9; b.lookY = -1e9; b.edgeGoal = false; b.stop = -1; b.dir = 1; },
      moved(S, b) { decidedLook(S, b); },
      pick(S, b) {
        decidedLook(S, b);
        if (S.phase === "survey") {
          const route = surveyPick(S, b);
          if (route) return route;
          S.phase = "patrol"; S.patrolFrom = S.t;
        }
        const W = watchman(S.M), k = W.tour.length, M = S.M;
        b.edgeGoal = false;
        if (!k) return [];
        let next;
        if (b.stop < 0) {
          let bd = Infinity;
          for (let s = 0; s < k; s++) { const c = W.tour[s], d = (c % M.W - b.x) ** 2 + (((c / M.W) | 0) - b.y) ** 2; if (d < bd) { bd = d; next = s; } }
          b.dir = S.r() < 0.5 ? -1 : 1;
        } else {
          next = (b.stop + b.dir + k) % k;
          const heading = s => S.buddies.some(o => o !== b && o.stop === s && o.at < o.route.length);
          if (k > 2 && heading(next)) {
            if (S.r() < 0.5) next = (next + b.dir + k) % k;               // skip past it
            else { b.dir = -b.dir; next = (b.stop + b.dir + k) % k; }      // or turn round
          }
        }
        b.stop = next; b.goal = W.tour[next];
        return S.path(b.cell, b.goal);
      },
      stale(S, b) { return S.phase === "survey" && b.edgeGoal && b.goal >= 0 && !bordersUnexplored(S, b.goal); },
    },
  };
  // }}}

  // {{{ Sim: one clan on one floor under one rule, and the yardsticks kept on it
  function Sim(M, method, n, seed) {
    this.M = M; this.method = METHODS[method]; this.kind = method;
    this.r = rng(seed); this.t = 0; this.path = makePather(M);
    this.seen = new Uint8Array(M.N); this.seenCount = 0;
    this.seenAt = new Float32Array(M.N).fill(-1e9);
    this.foot = new Uint32Array(M.N);
    this.ends = new Uint8Array(M.farEnds.length); this.endCount = 0;
    // the skeleton clan's marks and last-walked times, one per run (kept here, not on
    // the floor, which every clan and every restart shares)
    this.marks = new Uint8Array(M.edges.length); this.used = new Float64Array(M.edges.length).fill(-1e9); this.rounds = 0;
    this.came = new Int32Array(M.N); this.mark = new Uint32Array(M.N); this.queue = new Int32Array(M.N); this.gen = 0;
    this.history = [{ t: 0, seen: 0, ends: 0 }];
    this.firstHalf = null; this.firstMost = null;
    this.nextLook = 0; this.nextHistory = HISTORY;
    this.buddies = [];
    if (this.method.setup) this.method.setup(this);
    const sx = M.start % M.W + 0.5, sy = ((M.start / M.W) | 0) + 0.5;
    for (let k = 0; k < n; k++) {
      const b = { id: k, x: sx + (k - (n - 1) / 2) * 0.6, y: sy, cell: M.start, route: [], at: 0, rest: k * 1.5, goal: -1, trail: [] };
      this.method.init(this, b);
      this.buddies.push(b);
    }
  }
  Sim.prototype.step = function () {
    const M = this.M, speed = RUN / M.yd * DT;
    this.t += DT;
    for (const b of this.buddies) {
      if (b.rest > 0) { b.rest -= DT; continue; }
      if (b.at >= b.route.length) {
        b.route = this.method.pick(this, b); b.at = 0;
        if (!b.route.length) { b.rest = 1; continue; }
      }
      let left = speed;
      while (left > 0 && b.at < b.route.length) {
        const c = b.route[b.at], tx = c % M.W + 0.5, ty = ((c / M.W) | 0) + 0.5;
        const dx = tx - b.x, dy = ty - b.y, d = Math.hypot(dx, dy);
        if (d <= left) { b.x = tx; b.y = ty; b.cell = c; b.at++; left -= d; }
        else { b.x += dx / d * left; b.y += dy / d * left; left = 0; }
      }
      if (b.at >= b.route.length) b.rest = 0.5 + this.r() * 1.5;   // a short look round at each waypoint
      this.foot[b.cell]++;
      // a rule that looks as it walks looks again once it has gone MOVE_LOOK yards
      if (this.method.moved && Math.hypot(b.x - b.lookX, b.y - b.lookY) * M.yd >= MOVE_LOOK) this.method.moved(this, b);
    }
    if (this.t >= this.nextLook) {
      this.nextLook = this.t + 0.5;
      for (const b of this.buddies) {
        look(M, b.x, b.y, SIGHT_SEEN, 64, c => { if (!this.seen[c]) { this.seen[c] = 1; this.seenCount++; } });
        if (this.kind === "frontier") look(M, b.x, b.y, SIGHT_FRONT, 96, c => { this.seenAt[c] = this.t; });
        for (let e = 0; e < M.farEnds.length; e++) {
          if (this.ends[e]) continue;
          const c = M.farEnds[e];
          if (Math.hypot(c % M.W + 0.5 - b.x, ((c / M.W) | 0) + 0.5 - b.y) * M.yd <= REACH) { this.ends[e] = 1; this.endCount++; }
        }
        b.trail.push(b.x, b.y); if (b.trail.length > 80) b.trail.splice(0, 2);
        if (this.method.stale && b.at < b.route.length && this.method.stale(this, b)) b.route.length = b.at;
      }
      const share = this.seenCount / M.count;
      if (this.firstHalf === null && share >= 0.5) this.firstHalf = this.t;
      if (this.firstMost === null && share >= 0.9) this.firstMost = this.t;
    }
    if (this.t >= this.nextHistory) {
      this.nextHistory += HISTORY;
      this.history.push({ t: this.t, seen: this.seenCount / M.count, ends: M.farEnds.length ? this.endCount / M.farEnds.length : 0 });
    }
  };
  // unevenness: how much footprints differ between BLOCK-yard blocks of floor (0 = all alike)
  Sim.prototype.unevenness = function () {
    const M = this.M, B = Math.max(1, Math.round(BLOCK / M.yd)), bw = Math.ceil(M.W / B), bh = Math.ceil(M.H / B);
    const sum = new Float64Array(bw * bh), fl = new Uint32Array(bw * bh);
    for (let k = 0; k < M.count; k++) {
      const c = M.cells[k], o = (((c / M.W) | 0) / B | 0) * bw + ((c % M.W) / B | 0);
      sum[o] += this.foot[c]; fl[o]++;
    }
    const vals = [];
    for (let o = 0; o < sum.length; o++) if (fl[o] >= B * B * 0.3) vals.push(sum[o] / fl[o]);
    if (!vals.length) return 0;
    const mean = vals.reduce((a, v) => a + v, 0) / vals.length;
    if (!mean) return 0;
    const sd = Math.sqrt(vals.reduce((a, v) => a + (v - mean) ** 2, 0) / vals.length);
    return sd / mean;
  };
  // }}}

  global.ExploreEngine = { buildMap, Sim, METHODS, watchman, numbers: { DT, RING_BAND, FORGET, EXPLORE } };
})(typeof window !== "undefined" ? window : globalThis);
