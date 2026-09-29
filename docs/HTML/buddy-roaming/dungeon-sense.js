// dungeon-sense.js - the playable "sensing tunnels" scene of the buddy
// roaming gallery (issue 617e6). A drawn simulation, not the game. A clan
// of buddies explores the big dungeon by the roaming pattern
// (docs/roaming-pattern.md; the rules come from roam-pattern.js, the page
// parts from scene-kit.js): least paint, the walls' paint, paths through
// unpainted ground, and, with sensing on, the owner's quadrant sensing:
//
//   the owner, 2026-09-27: "let's look at the 4 quadrants around us, then
//   at the 4 peridicular quadrants (rotated 45 degrees, isometric style)
//   and if a high percentage of the terrain in a quadrant is impassible
//   then it's probably a surface. But if there is a high percentage but we
//   can still pathfind to the edge of our pathfinding radius, then it's a
//   tunnel there. [...] we prioritize the tunnel areas unless we've
//   already painted that area recently."
//
// The viewer turns sensing on and off, sets the clan's size, the blocked
// share that makes a wall or a tunnel, the sensing radius, and whether the
// walls paint, and clicks a buddy to see its eight sectors.
(function () {
  "use strict";
  const root = document.getElementById("ds-root");
  const RP = window.RoamPattern, SK = window.SceneKit;
  if (!root || !RP || !SK) return;

  // {{{ numbers
  const DT = 0.1;                           // simulated seconds per step
  const SPEED = 8.4;                        // yards a second (the widgets' pace, 2026-09-28)
  const PAINT_EVERY = 0.5, VISION = 45, PAINT_AMOUNT = 100;
  const WALL_EVERY = 3;                     // the walls' pulse (pattern: every 3 seconds)
  const PICK = { n: 30, min: 12, max: 70 }; // least paint: 30 spots 12..70 yards off
  const RECENT = 90, RECENT_MAX = 0.35;     // seconds; a tunnel whose far half is more than this share that recently seen is passed over
  const COLOURS = ["#e0735a", "#e2c16a", "#74d1bd", "#7fa6e6"];
  const SCALE = 2;                          // canvas pixels per yard
  // }}}

  const map = RP.maps.dungeon, grid = new RP.Grid(map, 3);

  // {{{ the widget's parts
  root.classList.add("sk");
  const api = { running: true, rate: 4 };
  const opt = Object.assign(
    SK.controlRow(root, [
      { kind: "toggle", id: "ds-sense", text: "Sensing", value: true },
      { kind: "choice", id: "ds-n", label: "Buddies", value: 2, options: [[1, "1"], [2, "2"], [4, "4"]] },
      { kind: "range", id: "ds-block", label: "Blocked share", min: 0.4, max: 0.7, step: 0.05, value: 0.6, format: v => Math.round(v * 100) + "%" },
      { kind: "choice", id: "ds-radius", label: "Sensing radius", value: 40, options: [[25, "25 yd"], [40, "40 yd"], [60, "60 yd"]] }
    ], id => { if (id === "ds-n") reset(); }),
    SK.controlRow(root, [
      { kind: "toggle", id: "ds-paint", text: "Show paint", value: true },
      { kind: "toggle", id: "ds-walls", text: "Walls paint", value: true },
      { kind: "choice", id: "ds-rate", label: "Speed", value: 4, options: [[1, "1×"], [4, "4×"], [12, "12×"]] },
      { kind: "button", id: "ds-play", text: "Pause" },
      { kind: "button", id: "ds-reset", text: "Start over" }
    ], (id, v, el) => {
      if (id === "ds-rate") api.rate = v;
      if (id === "ds-play") { api.running = !api.running; el.textContent = api.running ? "Pause" : "Play"; }
      if (id === "ds-reset") reset();
    }));
  const canvas = document.createElement("canvas");
  canvas.width = Math.round((grid.x0 + grid.nx * grid.cell) * SCALE);
  canvas.height = Math.round((grid.y0 + grid.ny * grid.cell) * SCALE);
  canvas.setAttribute("aria-label", "The dungeon from above: rooms light, tunnels darker, the buddies as coloured dots");
  const counts = document.createElement("div"); counts.className = "sk-counts";
  const note = document.createElement("div"); note.className = "sk-note";
  root.append(canvas, counts, note);
  const ctx = canvas.getContext("2d");
  // }}}

  let state, selected = 0, layer = null, heat = null;

  // {{{ reset
  function reset() {
    const e = map.entrance;
    state = {
      t: 0, paint: new RP.Paint(grid), nextPaint: 0, nextWall: 0,
      buddies: Array.from({ length: opt["ds-n"] }, (_, k) => ({ x: e.x - 6 + k * 4, y: e.y - 8, path: null, goal: null, why: "", rect: 0, trail: [] })),
      tunnels: 0, deadEnds: 0, reached: {}, bothFar: null, bySensing: 0, explored: 0
    };
    selected = 0; shownSectors = null;
    say("Buddy 1 is selected: its eight sectors are drawn round it. Click another buddy to follow it.");
  }
  const say = s => { note.textContent = s; };
  // }}}

  // {{{ choosing where to go
  const paintAt = i => state.paint.at(i, opt["ds-walls"]);
  const fromEntrance = p => Math.hypot(p.x - map.entrance.x, p.y - map.entrance.y);

  // least paint (pattern): of 30 random spots 12..70 yards off, the least
  // paint round each (a 6-yard disc), farther from the entrance weighing more
  function leastPainted(b) {
    let best = null, bestScore = Infinity;
    for (let k = 0; k < PICK.n; k++) {
      const a = Math.random() * 2 * Math.PI, r = PICK.min + Math.random() * (PICK.max - PICK.min);
      const x = b.x + Math.cos(a) * r, y = b.y + Math.sin(a) * r, i = grid.cellAt(x, y);
      if (i < 0 || !grid.open[i] || grid.wall[i] < 1.5) continue;
      let sum = 0, n = 0;
      for (let oy = -2; oy <= 2; oy++) for (let ox = -2; ox <= 2; ox++) {
        const j = i + oy * grid.nx + ox;
        if (j >= 0 && j < grid.n && grid.open[j]) { sum += paintAt(j); n++; }
      }
      const score = sum / Math.max(1, n) - 0.8 * fromEntrance({ x, y });
      if (score < bestScore) { bestScore = score; best = { x, y }; }
    }
    return best;
  }
  // share of a sector's far half seen up close within RECENT seconds
  function recentShare(b, far) {
    let n = 0, hit = 0;
    for (let k = 5; k <= 10; k++) {
      const i = grid.cellAt(b.x + (far.x - b.x) * k / 10, b.y + (far.y - b.y) * k / 10);
      if (i < 0 || !grid.open[i]) continue;
      n++;
      if (state.t - state.paint.seenAt[i] < RECENT) hit++;
    }
    return n ? hit / n : 1;
  }
  function choose(b) {
    if (opt["ds-sense"]) {
      let best = null, bestScore = -Infinity;
      for (const s of RP.senseSectors(grid, b.x, b.y, opt["ds-radius"], opt["ds-block"])) {
        if (s.kind !== "tunnel" || s.far < 0) continue;
        const far = grid.middle(s.far), recent = recentShare(b, far);
        if (recent > RECENT_MAX) continue;
        const score = s.blocked - recent + 0.3 * fromEntrance(far) / 500;
        if (score > bestScore) { bestScore = score; best = far; }
      }
      if (best) { state.bySensing++; return { at: best, why: "a tunnel it sensed" }; }
    }
    const l = leastPainted(b);
    return l && { at: l, why: "the least painted ground" };
  }
  // }}}

  // {{{ one step
  function step(dt) {
    const st = state;
    st.t += dt;
    if (st.t >= st.nextPaint) {
      st.nextPaint = st.t + PAINT_EVERY;
      for (const b of st.buddies) st.paint.deposit(b.x, b.y, VISION, PAINT_AMOUNT, st.t);
      st.explored = st.paint.explored();
    }
    if (opt["ds-walls"] && st.t >= st.nextWall) { st.nextWall = st.t + WALL_EVERY; st.paint.wallPulse(); }
    for (const b of st.buddies) {
      if (!b.path || !b.path.length) {
        const pick = choose(b);
        if (!pick) continue;
        b.path = RP.findPath(grid, b, pick.at, j => { const p = paintAt(j); return 0.6 * p / (p + 300); });
        b.goal = pick.at; b.why = pick.why;
        if (!b.path) continue;
      }
      let left = SPEED * dt;
      while (left > 0 && b.path.length) {
        const p = b.path[0], d = Math.hypot(p.x - b.x, p.y - b.y);
        if (d <= left) { b.x = p.x; b.y = p.y; left -= d; b.path.shift(); }
        else { b.x += (p.x - b.x) / d * left; b.y += (p.y - b.y) / d * left; left = 0; }
      }
      // counts: tunnels entered from a room, dead-end visits, far rooms reached
      const i = grid.cellAt(b.x, b.y), r = i >= 0 ? grid.rect[i] : -1;
      if (r >= 0 && r !== b.rect) {
        const was = map.rects[b.rect].kind, now = map.rects[r].kind;
        if (now === "tunnel" && was === "room") st.tunnels++;
        if (now === "dead" && was !== "dead") st.deadEnds++;
        if (map.farRooms.includes(r) && st.reached[r] == null) {
          st.reached[r] = st.t;
          if (map.farRooms.every(fr => st.reached[fr] != null)) st.bothFar = st.t;
        }
        b.rect = r;
      }
      const last = b.trail[b.trail.length - 1];
      if (!last || Math.abs(last.x - b.x) + Math.abs(last.y - b.y) > 4) { b.trail.push({ x: b.x, y: b.y }); if (b.trail.length > 90) b.trail.shift(); }
    }
  }
  // }}}

  // {{{ drawing
  let shownSectors = null, sectorsAt = -1, lastHud = -1;
  function draw() {
    const { dark } = SK.pageColours(root);
    if (!layer || layer.dark !== dark) layer = SK.mapLayer(grid, SCALE, dark);
    ctx.drawImage(layer, 0, 0);
    if (opt["ds-paint"]) drawHeat();
    const e = map.entrance;
    ctx.fillStyle = "#f5f5f5"; ctx.fillRect((e.x - 4) * SCALE, (e.y - 4) * SCALE, 8 * SCALE, 8 * SCALE);
    // the selected buddy's sectors, read again once a simulated second
    const sb = state.buddies[selected];
    if (sb) {
      if (!shownSectors || state.t - sectorsAt >= 1 || sectorsAt > state.t) { shownSectors = RP.senseSectors(grid, sb.x, sb.y, opt["ds-radius"], opt["ds-block"]); sectorsAt = state.t; }
      const R = opt["ds-radius"] * SCALE, fill = { tunnel: "rgba(226,193,106,0.45)", wall: "rgba(214,90,80,0.35)", open: "rgba(200,205,212,0.18)" };
      for (const s of shownSectors) {
        ctx.beginPath(); ctx.moveTo(sb.x * SCALE, sb.y * SCALE);
        ctx.arc(sb.x * SCALE, sb.y * SCALE, R, s.bearing - Math.PI / 8, s.bearing + Math.PI / 8);
        ctx.closePath(); ctx.fillStyle = fill[s.kind]; ctx.fill();
      }
      ctx.strokeStyle = "rgba(255,255,255,0.35)"; ctx.lineWidth = 1;
      ctx.beginPath(); ctx.arc(sb.x * SCALE, sb.y * SCALE, R, 0, 2 * Math.PI); ctx.stroke();
    }
    state.buddies.forEach((b, k) => {
      const col = COLOURS[k % COLOURS.length];
      ctx.strokeStyle = col; ctx.globalAlpha = 0.35; ctx.lineWidth = 2;
      ctx.beginPath(); b.trail.forEach((p, m) => m ? ctx.lineTo(p.x * SCALE, p.y * SCALE) : ctx.moveTo(p.x * SCALE, p.y * SCALE)); ctx.stroke();
      ctx.globalAlpha = 1;
      if (b.goal) {
        ctx.setLineDash([4, 4]); ctx.lineWidth = 1;
        ctx.beginPath(); ctx.moveTo(b.x * SCALE, b.y * SCALE); ctx.lineTo(b.goal.x * SCALE, b.goal.y * SCALE); ctx.stroke();
        ctx.setLineDash([]);
      }
      ctx.fillStyle = col; ctx.beginPath(); ctx.arc(b.x * SCALE, b.y * SCALE, 5, 0, 2 * Math.PI); ctx.fill();
      if (k === selected) { ctx.strokeStyle = "#fff"; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(b.x * SCALE, b.y * SCALE, 8, 0, 2 * Math.PI); ctx.stroke(); }
    });
    hud();
  }
  // the paint as a warm shading, the walls' fringe blue-grey where the
  // walls' paint is the greater; drawn at grid size and scaled up
  function drawHeat() {
    if (!heat) { heat = document.createElement("canvas"); heat.width = grid.nx; heat.height = grid.ny; heat.img = heat.getContext("2d").createImageData(grid.nx, grid.ny); }
    const d = heat.img.data, p = state.paint;
    for (let i = 0; i < grid.n; i++) {
      const o = i * 4, b = p.buddies[i], w = opt["ds-walls"] ? p.walls[i] : 0;
      if (!grid.open[i]) d[o + 3] = 0;
      else if (w > b && w > 20) { d[o] = 110; d[o + 1] = 140; d[o + 2] = 180; d[o + 3] = Math.min(150, w / 400 * 150); }
      else if (b > 1) { const a = Math.min(1, b / 1500); d[o] = 235; d[o + 1] = 150 - a * 60; d[o + 2] = 60; d[o + 3] = 40 + a * 150; }
      else d[o + 3] = 0;
    }
    heat.getContext("2d").putImageData(heat.img, 0, 0);
    ctx.imageSmoothingEnabled = false;
    ctx.drawImage(heat, grid.x0 * SCALE, grid.y0 * SCALE, grid.nx * grid.cell * SCALE, grid.ny * grid.cell * SCALE);
    ctx.imageSmoothingEnabled = true;
  }
  function hud() {
    const sec = Math.floor(state.t);
    if (sec === lastHud) return;
    lastHud = sec;
    const tm = t => `${Math.floor(t / 60)}:${String(Math.floor(t % 60)).padStart(2, "0")}`;
    counts.innerHTML = [
      ["Explored", Math.round(100 * state.explored) + "%"], ["Tunnels entered", state.tunnels], ["Dead-end visits", state.deadEnds],
      ["Both far rooms", state.bothFar != null ? tm(state.bothFar) : "not yet"], ["Picks by sensing", state.bySensing], ["Time", tm(state.t)]
    ].map(([k, v]) => `<span>${k} <b>${v}</b></span>`).join("");
    const b = state.buddies[selected];
    if (b && b.goal) say(`Buddy ${selected + 1} is heading for ${b.why}. Its sectors: gold a tunnel, red a wall, grey open ground.`);
  }
  // }}}

  // {{{ picking a buddy with the mouse
  canvas.addEventListener("click", e => {
    const r = canvas.getBoundingClientRect();
    const x = (e.clientX - r.left) / r.width * canvas.width / SCALE, y = (e.clientY - r.top) / r.height * canvas.height / SCALE;
    let best = -1, bd = 14;
    state.buddies.forEach((b, k) => { const d = Math.hypot(b.x - x, b.y - y); if (d < bd) { bd = d; best = k; } });
    if (best >= 0) { selected = best; shownSectors = null; lastHud = -1; }
  });
  // }}}

  reset();
  if (SK.runLoop(root, DT, step, draw, api)) {
    document.getElementById("ds-play").textContent = "Play";
    say("Paused because your system asks for reduced motion: press Play to start.");
  }
})();
