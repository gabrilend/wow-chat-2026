
"use strict";
const DIR = process.argv[2] || "/mnt/kaun/wow-chat-2026";
const PP = require(DIR + "/scripts/templates/paint-paths.js");

let failures = 0, checks = 0;
function check(ok, what) {
  checks++;
  if (!ok) failures++;
  console.log((ok ? "ok   " : "FAIL ") + what);
}
function rng(seed) { let s = seed >>> 0; return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296); }
const median = a => { const b = a.slice().sort((x, y) => x - y); return b.length ? b[b.length >> 1] : NaN; };
const pct = (a, p) => { const b = a.slice().sort((x, y) => x - y); return b.length ? b[Math.min(b.length - 1, Math.floor(b.length * p))] : NaN; };

const BODY = 0.5, SPEED = 7, DT = 0.1, STEP = 1;

function inShape(s, x, y, grow) {
  const [x0, y0, x1, y1] = s.box;
  if (s.round) { const r = (x1 - x0) / 2 + grow; return Math.hypot(x - (x0 + x1) / 2, y - (y0 + y1) / 2) <= r; }
  return x >= x0 - grow && x <= x1 + grow && y >= y0 - grow && y <= y1 + grow;
}
function shapeDistance(s, x, y) {
  const [x0, y0, x1, y1] = s.box;
  if (s.round) return Math.max(0, Math.hypot(x - (x0 + x1) / 2, y - (y0 + y1) / 2) - (x1 - x0) / 2);
  const dx = Math.max(x0 - x, 0, x - x1), dy = Math.max(y0 - y, 0, y - y1);
  return Math.hypot(dx, dy);
}
function nearest(course, x, y) { let d = Infinity; for (const s of course.shapes) d = Math.min(d, shapeDistance(s, x, y)); return d; }

function run(course, botsIn, trips, opt, limitS) {
  const M = PP.make(Math.ceil(course.w / STEP) + 1, Math.ceil(course.h / STEP) + 1, STEP, 0, 0, opt);
  PP.setGround(M, (x, y) => {
    if (x < 0 || y < 0 || x > course.w || y > course.h) return PP.OUTSIDE;
    for (const s of course.shapes) if (s.known && inShape(s, x, y, 0)) return PP.STEEP;
    return PP.UNKNOWN;
  });
  const bots = botsIn.map((b, i) => ({ ...b, h: b.h || 0, gi: 0, trip: 0, path: null, jitter: (i * 0.37) % 1.5, done: false }));
  const out = { bumpsByTrip: new Array(trips).fill(0), arrived: 0, clear: [], turnDeg: 0, yards: 0, maxTurn: 0, crossings: [], times: [], stuck: 0 };
  let t = 0, nextCrowd = 0;
  const shapeOf = (x, y) => course.shapes.find(s => inShape(s, x, y, BODY));
  while (t < limitS && bots.some(b => !b.done)) {
    if (t >= nextCrowd) { PP.crowd(M, bots.filter(b => !b.done)); nextCrowd = t + 1; }
    for (const b of bots) {
      if (b.done) continue;
      const [gx, gy] = b.goals[b.gi];
      if (Math.hypot(gx - b.x, gy - b.y) < M.opt.ARRIVE) {
        out.arrived++; out.times.push(t);
        b.gi = (b.gi + 1) % b.goals.length; b.path = null;
        if (b.gi === 0 && ++b.trip >= trips) b.done = true;
        continue;
      }
      if (PP.needsPlan(M, b.path, gx, gy, t, b.jitter)) {
        b.path = PP.plan(M, b.x, b.y, gx, gy);
        if (b.path) { b.path.at = t; PP.crowdRoute(M, b.path, b.x, b.y); }
      }
      if (!b.path) { out.stuck++; continue; }
      const [tx, ty] = PP.follow(M, b.path, b.x, b.y, b.lane || 0);
      const [h, share] = PP.steer(M, b.x, b.y, b.h, tx, ty, DT);
      const turned = Math.abs(h - b.h);
      const step = SPEED * share * DT, nx = b.x + Math.cos(h) * step, ny = b.y + Math.sin(h) * step;
      const hit = shapeOf(nx, ny) || (nx < 0 || ny < 0 || nx > course.w || ny > course.h ? { box: [nx, ny, nx, ny], edge: true } : null);
      b.h = h;
      if (hit) {
        out.bumpsByTrip[Math.min(b.trip, trips - 1)]++;
        const [x0, y0, x1, y1] = hit.box;
        PP.refused(M, nx, ny, hit.edge ? null : [x0 - BODY, y0 - BODY, x1 + BODY, y1 + BODY], b.x, b.y);
        b.path = null;
        continue;
      }
      if (course.gateX !== undefined && (b.x - course.gateX) * (nx - course.gateX) <= 0 && b.x !== nx) out.crossings.push(ny);
      b.x = nx; b.y = ny;
      PP.walked(M, b.x, b.y);
      out.turnDeg += turned * 180 / Math.PI; out.yards += step; out.maxTurn = Math.max(out.maxTurn, turned / DT);
      if (Math.hypot(gx - b.x, gy - b.y) > M.opt.RELAX) out.clear.push(nearest(course, b.x, b.y));
    }
    t += DT;
  }
  out.t = t; out.M = M; out.unfinished = bots.filter(b => !b.done).length;
  return out;
}

{
  const R = rng(7), shapes = [];
  for (let x = 40; x <= 80; x += 6) for (let y = 6; y <= 54; y += 6) {
    const px = x + (R() - 0.5) * 3, py = y + (R() - 0.5) * 3;
    shapes.push({ box: [px - 0.8, py - 0.8, px + 0.8, py + 0.8], round: true, known: false });
  }
  const course = { w: 120, h: 60, shapes };
  const bots = [];
  for (let i = 0; i < 10; i++) bots.push({ x: 8, y: 6 + i * 5, lane: (i % 3) - 1, goals: [[112, 54 - i * 5], [8, 6 + i * 5]] });
  const r = run(course, bots, 6, {}, 900);
  const first = r.bumpsByTrip[0], last = r.bumpsByTrip[4] + r.bumpsByTrip[5];
  console.log(`     pillars: bumps by round of trips ${r.bumpsByTrip.join(", ")}; ${r.M.wallCells} wall cells painted, ` +
              `${(100 * r.M.painted / r.M.inside).toFixed(0)}% of the ground painted; ${r.M.stats.plans} plans, ` +
              `${(r.M.stats.ms / Math.max(1, r.M.stats.plans)).toFixed(2)} ms a plan; ${r.t.toFixed(0)} s`);
  check(r.unfinished === 0 && r.stuck === 0, `pillars: all ten bots finish six round trips (${r.arrived} arrivals, ${r.stuck} steps with no way)`);
  check(first > 0, `pillars: the first round bumps into the unknown pillars (${first} bumps)`);
  check(last <= first * 0.15, `pillars: the last two rounds together bump far less than the first: the map was learned together (${last} against ${first})`);
  const turnPerYard = r.turnDeg / r.yards;
  console.log(`     pillars: ${turnPerYard.toFixed(1)} degrees turned a yard walked; the most in a step ${(r.maxTurn * 180 / Math.PI).toFixed(0)} degrees a second`);
  check(r.maxTurn <= r.M.opt.TURN + 1e-6, `pillars: no bot turns faster than the limit (${(r.maxTurn * 180 / Math.PI).toFixed(0)} of ${(r.M.opt.TURN * 180 / Math.PI).toFixed(0)} degrees a second)`);
  check(turnPerYard < 8, `pillars: smooth walking: under 8 degrees turned a yard (${turnPerYard.toFixed(1)})`);
}

{
  const shapes = [{ box: [58, 0, 62, 36], known: true }, { box: [58, 52, 62, 60], known: true }];
  const course = { w: 120, h: 60, shapes };
  const mk = () => [{ x: 10, y: 8, goals: [[110, 10]] }, { x: 10, y: 50, goals: [[110, 52]] }, { x: 10, y: 30, goals: [[110, 30]] }];
  const spaced = run(course, mk(), 1, {}, 120), tight = run(course, mk(), 1, { WANT: 0.01, WALL_W: 0 }, 120);
  const ms = median(spaced.clear), mt = median(tight.clear), ls = pct(spaced.clear, 0.05), lt = pct(tight.clear, 0.05);
  console.log(`     wall and gap: yards to the nearest wall, median ${ms.toFixed(1)} (no space wanted: ${mt.toFixed(1)}); the closest 5%: ${ls.toFixed(1)} (${lt.toFixed(1)})`);
  check(spaced.unfinished === 0, "wall and gap: every bot gets through the gap");
  check(ls >= 2.5 && ls > lt + 0.5, `wall and gap: bots keep their space through the gap: the closest 5% of steps at least 2.5 yards from the wall (${ls.toFixed(1)}; without space wanted ${lt.toFixed(1)})`);
}

{
  const course = { w: 80, h: 60, shapes: [{ box: [40, 10, 44, 50], known: true }] };
  const r = run(course, [{ x: 10, y: 30, goals: [[38.5, 30]] }], 1, {}, 60);
  check(r.unfinished === 0, `goal against a wall: the bot reaches a goal 1.5 yards from the wall's face (arrived ${r.arrived})`);
  const thin = { w: 80, h: 60, shapes: [{ box: [39.5, 0, 40.5, 40], known: true }] };
  const lenOf = opt => { const q = run(thin, [{ x: 34, y: 20, goals: [[46, 20]] }], 1, Object.assign({ RELAX: 0.001, CLUTTER_KEEP: 1, LOOK_MIN: 6, UNKNOWN: 0.15 }, opt), 60); return { q, yards: q.yards }; };
  const near = lenOf({}), wide = lenOf({ NEAR: 0.001 });
  const best = 2 * Math.hypot(6, 20.5);
  const closest = r => Math.min(...r.q.clear);
  console.log(`     across a thin wall: walked ${near.yards.toFixed(1)} yards, nearest the wall ${closest(near).toFixed(1)} (full space all the way: ${wide.yards.toFixed(1)} yards, nearest ${closest(wide).toFixed(1)}; the shortest round: ${best.toFixed(1)})`);
  check(near.q.unfinished === 0 && closest(near) < closest(wide) - 0.5 && near.yards < wide.yards, `across a thin wall: with the goal just across, the bot rounds the wall's end closer and shorter than keeping full space (${closest(near).toFixed(1)} against ${closest(wide).toFixed(1)} yards from the wall)`);
}

{
  const M = PP.make(60, 60, 1, 0, 0, {});
  PP.setGround(M, (x, y) => (x >= 28 && x <= 32 && y >= 10 && y <= 50) || (x >= 10 && x <= 50 && y >= 28 && y <= 32) ? PP.STEEP : PP.UNKNOWN);
  const open = PP.clutter(M, 8, 8), cross = PP.clutter(M, 26, 26);
  check(open === 0 && cross > 0.2, `clutter: none in the open (${open.toFixed(2)}), plenty in the crook of two walls (${cross.toFixed(2)})`);
  const wOpen = PP.wantAt(M, open), wCross = PP.wantAt(M, cross);
  check(wOpen === M.opt.WANT && wCross < wOpen && wCross >= M.opt.WANT * M.opt.CLUTTER_KEEP,
    `clutter: the space wanted is full in the open (${wOpen.toFixed(1)} yards) and less in clutter (${wCross.toFixed(1)}), never under CLUTTER_KEEP of it`);
}

{
  const shapes = [{ box: [48, 0, 52, 20], known: true }, { box: [48, 40, 52, 60], known: true }];
  const course = { w: 100, h: 60, shapes, gateX: 50 };
  const mk = lanes => { const b = []; for (let i = 0; i < 12; i++) b.push({ x: 8 + (i % 3) * 0.7, y: 29 + Math.floor(i / 3) * 0.7, lane: lanes ? ((i * 7) % 12) / 5.5 - 1 : 0, goals: [[92, 30]] }); return b; };
  const spread = run(course, mk(true), 1, {}, 60), single = run(course, mk(false), 1, { CROWD_W: 0, LANE: 0 }, 60);
  const sd = a => { const m = a.reduce((s, v) => s + v, 0) / a.length; return Math.sqrt(a.reduce((s, v) => s + (v - m) * (v - m), 0) / a.length); };
  const ss = sd(spread.crossings), s1 = sd(single.crossings);
  console.log(`     gap for a dozen: spread across the gap (standard deviation) ${ss.toFixed(1)} yards with lanes and the crowd, ${s1.toFixed(1)} without`);
  check(spread.unfinished === 0, "gap for a dozen: all twelve arrive");
  check(ss >= 2.5 && ss >= s1 * 2, `gap for a dozen: leaving in one knot, lanes and the crowd spread them across the gap (${ss.toFixed(1)} yards against ${s1.toFixed(1)} single file)`);
}

{
  const R = rng(11), M = PP.make(500, 500, 1, 0, 0, {});
  const blobs = [];
  for (let i = 0; i < 160; i++) blobs.push([R() * 500, R() * 500, 4 + R() * 18]);
  PP.setGround(M, (x, y) => blobs.some(([bx, by, br]) => Math.hypot(x - bx, y - by) < br) ? PP.STEEP : PP.UNKNOWN);
  const times = []; let found = 0;
  for (let i = 0; i < 300; i++) {
    let sx, sy, gx, gy;
    do { sx = R() * 500; sy = R() * 500; } while (PP.blocks(M.know[PP.cellOf(M, sx, sy)]));
    do { gx = R() * 500; gy = R() * 500; } while (PP.blocks(M.know[PP.cellOf(M, gx, gy)]));
    const t0 = process.hrtime.bigint();
    const p = PP.plan(M, sx, sy, gx, gy);
    times.push(Number(process.hrtime.bigint() - t0) / 1e6);
    if (p) found++;
  }
  const md = median(times), p95 = pct(times, 0.95);
  console.log(`     planning: 300 plans over 250,000 cells (a yard each): median ${md.toFixed(2)} ms, 95% under ${p95.toFixed(2)} ms, ${found} found a way; ${(M.stats.expanded / 300).toFixed(0)} cells opened a plan`);
  check(md < 25, `planning: a plan across 500 yards takes under 25 ms in the middle case (${md.toFixed(2)} ms)`);
}

console.log(`${checks - failures} of ${checks} checks held`);
process.exit(failures);
