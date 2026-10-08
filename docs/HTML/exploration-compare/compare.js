// compare.js - the playable comparison of three ways for buddies to explore
// a cave (issue 617e, "the pull toward openings", brainstorm of 2026-10-07).
//
// For a general audience: three copies of the same clan of buddies walk the
// same real cave floor at once, each copy choosing where to go next by a
// different rule. The floors are the server's own walking mesh, flattened to
// one-yard squares by scripts/generate-exploration-floors; this file only
// reads them (window.EXPLORATION_FLOORS, inlined by
// scripts/build-exploration-compare-page). Nothing here is the game: it is
// a drawing of three ideas, run on the game's real floors, measured the
// same way.
//
// The three rules (the owner liked options 1, 2 and 3 of the brainstorm):
//   rings    - walking distance from the entrance, cut into the owner's
//              Y rule's percent bands; a waypoint is a random square of
//              the band, so waypoints fall evenly over the floor
//   frontier - the clan remembers what it has seen; a buddy walks to the
//              nearest place where seen floor meets unseen floor
//   skeleton - the floor shaved down to a one-square line along every
//              passage; buddies walk passage to passage, least recently
//              walked first, and turn back at dead ends
// and the design decided from them after watching (2026-10-07):
//   decided  - survey by the unseen edge where "explored" means within 30
//              yards, then patrol one loop of watchman stops (see the
//              engine's header of this rule)
//
// The yardsticks are the same for all four: floor seen from within 20
// yards (sight stopped by walls), far ends reached (the skeleton's tips at
// least 10 yards out on their own branch), and how evenly the footprints
// spread.
(function () {
  "use strict";
  const FLOORS = window.EXPLORATION_FLOORS;
  const root = document.getElementById("xc-root");
  if (!root || !FLOORS || !FLOORS.length || !window.ExploreEngine) return;
  const { buildMap, Sim, METHODS, numbers } = window.ExploreEngine;
  const DT = numbers.DT, RING_BAND = numbers.RING_BAND, FORGET = numbers.FORGET;

  // {{{ the page's colours, read from its tokens so both themes work
  function tokens() {
    const cs = getComputedStyle(root);
    const get = n => cs.getPropertyValue(n).trim();
    // --m-*: each rule's colour on the page (charts, legend; light and dark themes);
    // --c-*: the same rule on the cave pictures, which are dark in both themes
    return { rings: get("--m-rings"), frontier: get("--m-frontier"), skeleton: get("--m-skeleton"), decided: get("--m-decided"),
             crings: get("--c-rings"), cfrontier: get("--c-frontier"), cskeleton: get("--c-skeleton"), cdecided: get("--c-decided"),
             ink: get("--ink"), muted: get("--muted"), rule: get("--rule"), accent: get("--accent") };
  }
  function rgbOf(css) {
    const d = document.createElement("canvas").getContext("2d");
    d.fillStyle = css; const h = d.fillStyle;
    if (h[0] === "#") return [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)];
    const m = h.match(/\d+/g); return m ? m.slice(0, 3).map(Number) : [200, 200, 200];
  }
  // }}}

  // {{{ drawing a floor once: the minimap behind (dimmed), the floor by height
  function baseLayer(M, img) {
    const S = M.scale, cv = document.createElement("canvas");
    cv.width = M.W * S; cv.height = M.H * S;
    const g = cv.getContext("2d");
    g.fillStyle = "#12161d"; g.fillRect(0, 0, cv.width, cv.height);
    if (img) { g.globalAlpha = 0.42; g.imageSmoothingEnabled = true; g.drawImage(img, 0, 0, M.W0 / M.f * S, M.H0 / M.f * S); g.globalAlpha = 1; }
    const id = new ImageData(M.W, M.H), px = id.data, span = Math.max(1, M.zhi - M.zlo);
    for (let c = 0; c < M.N; c++) {
      if (!M.open[c]) continue;
      const t = (M.z[c] - M.zlo) / span, L = 70 + 150 * t, o = c * 4;
      if (!M.reach[c]) { px[o] = 60; px[o + 1] = 64; px[o + 2] = 72; px[o + 3] = 200; continue; }
      if (M.inside[c]) { px[o] = L * 0.78; px[o + 1] = L * 0.86; px[o + 2] = L; }
      else { px[o] = L * 0.72; px[o + 1] = L * 0.92; px[o + 2] = L * 0.62; }
      px[o + 3] = 255;
    }
    const tmp = document.createElement("canvas"); tmp.width = M.W; tmp.height = M.H;
    tmp.getContext("2d").putImageData(id, 0, 0);
    g.imageSmoothingEnabled = false; g.drawImage(tmp, 0, 0, cv.width, cv.height);
    return cv;
  }
  // }}}

  // {{{ each rule's own view: what it is thinking about, laid over the floor
  function methodView(sim, id, col) {
    const M = sim.M, px = id.data;
    px.fill(0);
    if (sim.kind === "rings") {
      // ten bands of walking distance, alternating, the band each buddy aims at lit
      const aims = sim.buddies.map(b => b.Y / 100);
      for (let k = 0; k < M.count; k++) {
        const c = M.cells[k], r = M.rank[c], o = c * 4, band = Math.floor(r * 10);
        let a = band % 2 ? 70 : 20;
        for (const y of aims) if (Math.abs(r - y) <= RING_BAND / 100) a = 190;
        px[o] = col[0]; px[o + 1] = col[1]; px[o + 2] = col[2]; px[o + 3] = a;
      }
    } else if (sim.kind === "frontier") {
      for (let k = 0; k < M.count; k++) {
        const c = M.cells[k], o = c * 4, age = sim.t - sim.seenAt[c];
        if (age > FORGET) { px[o] = 8; px[o + 1] = 10; px[o + 2] = 14; px[o + 3] = 150; }
        else if (age < 6) { px[o] = col[0]; px[o + 1] = col[1]; px[o + 2] = col[2]; px[o + 3] = 120; }
      }
    } else if (sim.kind === "decided") {
      // surveying: floor not yet explored (in view within 30 yards) is veiled;
      // patrolling: floor dims as its last glance grows old, over three minutes
      for (let k = 0; k < M.count; k++) {
        const c = M.cells[k], o = c * 4;
        if (sim.phase === "survey") {
          if (!sim.explored[c]) { px[o] = 8; px[o + 1] = 10; px[o + 2] = 14; px[o + 3] = 160; }
        } else {
          const age = Math.min(1, (sim.t - sim.checkedAt[c]) / 180);
          px[o] = 8; px[o + 1] = 10; px[o + 2] = 14; px[o + 3] = 170 * age;
        }
      }
    } else {
      for (const e of M.edges) {
        if (e.cut) continue;
        const fresh = Math.max(0, 1 - (sim.t - sim.used[e.id]) / 300);
        for (const c of e.path) { const o = c * 4; px[o] = col[0]; px[o + 1] = col[1]; px[o + 2] = col[2]; px[o + 3] = 90 + 165 * fresh; }
      }
    }
  }
  function footView(sim, id) {
    const M = sim.M, px = id.data;
    let max = 1;
    for (let k = 0; k < M.count; k++) max = Math.max(max, sim.foot[M.cells[k]]);
    const lm = Math.log(1 + max);
    for (let k = 0; k < M.count; k++) {
      const c = M.cells[k], f = sim.foot[c];
      if (!f) continue;
      const t = Math.log(1 + f) / lm, o = c * 4;
      px[o] = 255; px[o + 1] = 120 + 120 * t; px[o + 2] = 40; px[o + 3] = 60 + 190 * t;
    }
  }
  // }}}

  // {{{ the page: controls, three panels, the charts, the table
  const state = { place: 0, playing: true, speed: 30, buddies: 3, view: true, feet: false, routes: true, focus: "all", sims: [], maps: {}, images: {} };
  const ORDER = ["rings", "frontier", "skeleton", "decided"];

  const el = (tag, attrs, ...kids) => {
    const e = document.createElement(tag);
    for (const k in attrs || {}) { if (k === "class") e.className = attrs[k]; else if (k.startsWith("on")) e.addEventListener(k.slice(2), attrs[k]); else e.setAttribute(k, attrs[k]); }
    for (const k of kids) e.append(k);
    return e;
  };

  const placeBar = el("div", { class: "xc-places", role: "tablist", "aria-label": "Cave" });
  FLOORS.forEach((F, k) => placeBar.append(el("button", { type: "button", role: "tab", id: "xc-place-" + F.key, "aria-selected": k === 0 ? "true" : "false", onclick: () => choosePlace(k) }, F.title)));
  const playBtn = el("button", { type: "button", id: "xc-play", onclick: () => { state.playing = !state.playing; playBtn.textContent = state.playing ? "Pause" : "Play"; } }, "Pause");
  const restartBtn = el("button", { type: "button", id: "xc-restart", onclick: () => restart() }, "Start again");
  const speedSel = el("select", { id: "xc-speed", onchange: () => { state.speed = +speedSel.value; } });
  [[1, "Real time"], [10, "10× faster"], [30, "30× faster"], [100, "100× faster"]].forEach(([v, t]) => { const o = el("option", { value: String(v) }, t); if (v === 30) o.selected = true; speedSel.append(o); });
  const budRange = el("input", { type: "range", id: "xc-buddies", min: "1", max: "5", value: "3", oninput: () => { budOut.textContent = budRange.value; }, onchange: () => { state.buddies = +budRange.value; restart(); } });
  const budOut = el("output", { for: "xc-buddies" }, "3");
  const viewChk = el("input", { type: "checkbox", id: "xc-view", checked: "", onchange: () => { state.view = viewChk.checked; } });
  const feetChk = el("input", { type: "checkbox", id: "xc-feet", onchange: () => { state.feet = feetChk.checked; } });
  const routeChk = el("input", { type: "checkbox", id: "xc-routes", checked: "", onchange: () => { state.routes = routeChk.checked; } });
  // one rule at a time, as large as the page allows, for following a single buddy's choices
  const focusSel = el("select", { id: "xc-focus", onchange: () => { state.focus = focusSel.value; showFocus(); } });
  [["all", "All three"], ...ORDER.map(k => [k, METHODS[k].label + " only"])].forEach(([v, t]) => focusSel.append(el("option", { value: v }, t)));
  const clock = el("span", { class: "xc-clock" }, "0:00");
  const controls = el("div", { class: "xc-controls" },
    el("div", { class: "xc-buttons" }, playBtn, restartBtn),
    el("label", { class: "xc-field" }, "Speed ", speedSel),
    el("label", { class: "xc-field" }, "Buddies ", budRange, budOut),
    el("label", { class: "xc-field" }, "Show ", focusSel),
    el("label", { class: "xc-check" }, routeChk, " Planned walks"),
    el("label", { class: "xc-check" }, viewChk, " Each rule's own view"),
    el("label", { class: "xc-check" }, feetChk, " Footprints"),
    el("span", { class: "xc-field" }, "Time exploring ", clock));
  // a failure in the frame loop is shown on the page, not left as a silently frozen picture
  const problem = el("p", { class: "xc-problem", role: "alert", hidden: "" });
  const placeNote = el("p", { class: "xc-note" });
  const panels = el("div", { class: "xc-panels" });
  const panelParts = ORDER.map(kind => {
    const cv = el("canvas", { class: "xc-canvas", "aria-label": METHODS[kind].label + " on the cave floor" });
    const nums = el("dl", { class: "xc-nums" });
    const p = el("figure", { class: "xc-panel", "data-method": kind }, el("figcaption", {}, el("span", { class: "xc-swatch" }), METHODS[kind].label), cv, nums);
    panels.append(p);
    return { kind, cv, nums, fig: p };
  });
  function showFocus() {
    panels.classList.toggle("xc-single", state.focus !== "all");
    for (const p of panelParts) p.fig.hidden = state.focus !== "all" && state.focus !== p.kind;
  }
  const chartSeen = el("canvas", { class: "xc-chart", "aria-label": "Floor seen over time" });
  const chartEnds = el("canvas", { class: "xc-chart", "aria-label": "Far ends reached over time" });
  const charts = el("div", { class: "xc-charts" },
    el("figure", {}, el("figcaption", {}, "Floor seen from within 20 yards"), chartSeen),
    el("figure", {}, el("figcaption", {}, "Far ends reached"), chartEnds));
  const legend = el("div", { class: "xc-legend" }, ...ORDER.map(k => el("span", { "data-method": k }, METHODS[k].label)));
  root.append(placeBar, placeNote, controls, problem, panels, el("section", { class: "xc-chartcard" }, legend, charts));

  function fmt(t) { const m = Math.floor(t / 60), s = Math.floor(t % 60); return m + ":" + String(s).padStart(2, "0"); }

  function choosePlace(k) {
    state.place = k;
    placeBar.querySelectorAll("button").forEach((b, i) => b.setAttribute("aria-selected", i === k ? "true" : "false"));
    restart();
  }

  function restart() {
    const F = FLOORS[state.place];
    let M = state.maps[F.key];
    if (!M) {
      M = buildMap(F);
      M.scale = Math.max(1, Math.min(4, Math.round(720 / Math.max(M.W, M.H))));
      state.maps[F.key] = M;
    }
    const ready = img => {
      if (!M.base) M.base = baseLayer(M, img);
      state.M = M;
      state.sims = ORDER.map(kind => new Sim(M, kind, state.buddies, 20261007));
      state.views = ORDER.map(() => new ImageData(M.W, M.H));
      state.layer = document.createElement("canvas"); state.layer.width = M.W; state.layer.height = M.H;
      for (const p of panelParts) { p.cv.width = M.W * M.scale; p.cv.height = M.H * M.scale; p.cv.style.aspectRatio = M.W + " / " + M.H; }
      const yards = Math.round(M.count * M.yd * M.yd).toLocaleString();
      placeNote.textContent = F.note + " " + yards + " square yards of floor, " + M.farEnds.length + " far ends." + (M.f > 1 ? " Shown at two yards a square." : "") + (M.stats.layered > 200 ? " Where one passage runs over another, the lower is drawn and both share the squares." : "");
      // the first half minute is walked at once and drawn straight away, so the page
      // shows buddies already inside the cave even as a still picture
      for (let s = 0; s < 300; s++) for (const sim of state.sims) sim.step();
      state.lastView = -1e9;
      drawPanels(performance.now());
      for (const sim of state.sims) sim.unevennessCache = sim.unevenness();
      const T = tokens();
      drawChart(chartSeen, "seen", T); drawChart(chartEnds, "ends", T);
    };
    if (F.picture && !M.base) {
      const img = new Image();
      img.onload = () => ready(img);
      img.onerror = () => ready(null);
      img.src = F.picture;
    } else ready(null);
  }

  function drawPanels(now) {
    const M = state.M, S = M.scale, T = tokens();
    const cols = ORDER.map(k => rgbOf(T["c" + k]));
    const refreshView = now - state.lastView > 250;
    if (refreshView) state.lastView = now;
    panelParts.forEach((p, k) => {
      if (p.fig.hidden) return;
      const sim = state.sims[k], g = p.cv.getContext("2d");
      g.imageSmoothingEnabled = false;
      g.drawImage(M.base, 0, 0);
      if (state.view || state.feet) {
        if (refreshView) {
          const id = state.views[k];
          if (state.view) methodView(sim, id, cols[k]); else id.data.fill(0);
          if (state.feet) footView(sim, id);
          state.views[k].ready = true;
        }
        state.layer.getContext("2d").putImageData(state.views[k], 0, 0);
        g.drawImage(state.layer, 0, 0, M.W * S, M.H * S);
      }
      // far ends: rings, filled once reached
      for (let e = 0; e < M.farEnds.length; e++) {
        const c = M.farEnds[e], x = (c % M.W + 0.5) * S, y = (((c / M.W) | 0) + 0.5) * S;
        g.beginPath(); g.arc(x, y, Math.max(3, 1.6 * S), 0, Math.PI * 2);
        g.lineWidth = Math.max(1, S * 0.5); g.strokeStyle = "rgba(255,255,255,0.75)";
        if (sim.ends[e]) { g.fillStyle = "rgba(255,255,255,0.9)"; g.fill(); } else g.stroke();
      }
      // buddies, with a short trail
      const col = T["c" + ORDER[k]];
      // the decided clan's patrol loop: the watchman stops (diamonds) joined in tour order
      if (sim.kind === "decided" && sim.phase === "patrol" && M.watch && M.watch.tour.length) {
        const tour = M.watch.tour, at = c => [(c % M.W + 0.5) * S, (((c / M.W) | 0) + 0.5) * S];
        g.beginPath();
        tour.forEach((c, i) => { const [x, y] = at(c); i ? g.lineTo(x, y) : g.moveTo(x, y); });
        g.closePath(); g.strokeStyle = col; g.globalAlpha = 0.45; g.lineWidth = Math.max(1, S * 0.5); g.stroke(); g.globalAlpha = 1;
        const r = Math.max(3.5, S * 1.8);
        for (const c of tour) {
          const [x, y] = at(c);
          g.beginPath(); g.moveTo(x, y - r); g.lineTo(x + r, y); g.lineTo(x, y + r); g.lineTo(x - r, y); g.closePath();
          g.fillStyle = "#0b0e13"; g.fill(); g.strokeStyle = col; g.lineWidth = Math.max(1, S * 0.5); g.stroke();
        }
      }
      // each buddy's planned walk, from where it stands to its goal (a cross): the path
      // finder's answer, so a wrong turn or a hug of a wall shows before it is walked
      if (state.routes) for (const b of sim.buddies) {
        if (b.at >= b.route.length) continue;
        g.beginPath(); g.moveTo(b.x * S, b.y * S);
        for (let m = b.at; m < b.route.length; m++) { const c = b.route[m]; g.lineTo((c % M.W + 0.5) * S, (((c / M.W) | 0) + 0.5) * S); }
        g.setLineDash([Math.max(2, S * 1.5), Math.max(2, S * 1.5)]);
        g.strokeStyle = "rgba(255,255,255,0.8)"; g.lineWidth = Math.max(1, S * 0.45); g.stroke(); g.setLineDash([]);
        const c = b.route[b.route.length - 1], gx = (c % M.W + 0.5) * S, gy = (((c / M.W) | 0) + 0.5) * S, r = Math.max(4, S * 2.2);
        g.beginPath(); g.moveTo(gx - r, gy - r); g.lineTo(gx + r, gy + r); g.moveTo(gx + r, gy - r); g.lineTo(gx - r, gy + r);
        g.strokeStyle = col; g.lineWidth = Math.max(1.5, S * 0.8); g.stroke();
      }
      for (const b of sim.buddies) {
        g.beginPath();
        for (let m = 0; m < b.trail.length; m += 2) { const x = b.trail[m] * S, y = b.trail[m + 1] * S; m ? g.lineTo(x, y) : g.moveTo(x, y); }
        g.strokeStyle = col; g.globalAlpha = 0.6; g.lineWidth = Math.max(1, S * 0.6); g.stroke(); g.globalAlpha = 1;
        g.beginPath(); g.arc(b.x * S, b.y * S, Math.max(3.5, S * 1.8), 0, Math.PI * 2);
        g.fillStyle = col; g.fill(); g.lineWidth = Math.max(1, S * 0.5); g.strokeStyle = "#0b0e13"; g.stroke();
      }
      if (!refreshView) return;   // the numbers change four times a second, not every frame
      const share = sim.seenCount / M.count;
      p.nums.replaceChildren(
        el("dt", {}, "Floor seen"), el("dd", {}, (share * 100).toFixed(1) + "%"),
        el("dt", {}, "Far ends"), el("dd", {}, sim.endCount + " of " + M.farEnds.length),
        el("dt", {}, "Half seen at"), el("dd", {}, sim.firstHalf === null ? "not yet" : fmt(sim.firstHalf)),
        el("dt", {}, "90% seen at"), el("dd", {}, sim.firstMost === null ? "not yet" : fmt(sim.firstMost)),
        el("dt", {}, "Unevenness"), el("dd", {}, sim.unevennessCache === undefined ? "–" : sim.unevennessCache.toFixed(2)));
      if (sim.kind === "decided") p.nums.append(
        el("dt", {}, sim.phase === "survey" ? "Surveyed" : "Patrolling"),
        el("dd", {}, sim.phase === "survey" ? (sim.exploredCount / M.count * 100).toFixed(1) + "% within " + numbers.EXPLORE + " yards"
          : "since " + fmt(sim.patrolFrom) + ", " + M.watch.tour.length + " stops, a " + Math.round(M.watch.length) + "-yard loop"));
    });
    clock.textContent = fmt(state.sims[0].t);
  }

  function drawChart(cv, field, T) {
    const r = cv.getBoundingClientRect(), dpr = window.devicePixelRatio || 1;
    if (!r.width) return;
    cv.width = Math.round(r.width * dpr); cv.height = Math.round(r.height * dpr);
    const g = cv.getContext("2d");
    g.scale(dpr, dpr);
    const w = r.width, h = r.height, L = 40, B = 24, Tp = 8, R = 10;
    const tmax = Math.max(300, state.sims[0].t);
    const X = t => L + (w - L - R) * t / tmax, Y = v => Tp + (h - Tp - B) * (1 - v);
    g.font = "12px 'Alegreya Sans', system-ui, sans-serif"; g.fillStyle = T.muted; g.strokeStyle = T.rule; g.lineWidth = 1;
    for (const v of [0, 0.25, 0.5, 0.75, 1]) {
      g.beginPath(); g.moveTo(L, Y(v)); g.lineTo(w - R, Y(v)); g.globalAlpha = v ? 0.5 : 1; g.stroke(); g.globalAlpha = 1;
      g.textAlign = "right"; g.textBaseline = "middle"; g.fillText(Math.round(v * 100) + "%", L - 6, Y(v));
    }
    const stepMin = tmax > 1800 ? 10 : tmax > 600 ? 5 : 1;
    g.textAlign = "center"; g.textBaseline = "top";
    for (let m = 0; m * 60 <= tmax; m += stepMin) g.fillText(m + " min", X(m * 60), h - B + 6);
    state.sims.forEach((sim, k) => {
      g.beginPath();
      sim.history.forEach((p, i) => { i ? g.lineTo(X(p.t), Y(p[field])) : g.moveTo(X(p.t), Y(p[field])); });
      g.strokeStyle = T[ORDER[k]]; g.lineWidth = 2.2; g.stroke();
      const last = sim.history[sim.history.length - 1];
      g.beginPath(); g.arc(X(last.t), Y(last[field]), 3.5, 0, Math.PI * 2); g.fillStyle = T[ORDER[k]]; g.fill();
    });
  }

  let lastFrame = performance.now(), lastChart = 0;
  function frame(now) {
    const real = Math.min(0.1, (now - lastFrame) / 1000);
    lastFrame = now;
    try {
      if (state.M && state.sims.length) {
        if (state.playing) {
          // simulated time owed is carried from frame to frame: at real time a frame
          // (1/60 s) is shorter than one step (1/10 s), and rounding each frame on its
          // own gave zero steps for ever (2026-10-07, "real time seems to be paused")
          state.owed = (state.owed || 0) + real * state.speed;
          while (state.owed >= DT) { state.owed -= DT; for (const sim of state.sims) sim.step(); }
        }
        drawPanels(now);
        if (now - lastChart > 1000) {
          lastChart = now;
          for (const sim of state.sims) sim.unevennessCache = sim.unevenness();
          const T = tokens();
          drawChart(chartSeen, "seen", T); drawChart(chartEnds, "ends", T);
        }
      }
    } catch (err) {
      // stop and say so: what failed, where, and what was running
      problem.hidden = false;
      problem.textContent = "The animation stopped: " + err.message + ". It was drawing " + (FLOORS[state.place] || {}).title +
        " at " + fmt(state.sims.length ? state.sims[0].t : 0) + " of exploring, " + state.buddies + " buddies, speed " + state.speed + "×. " +
        "To debug: open the browser's console for the line; does scripts/test-exploration-engine pass on the same floors?";
      return;
    }
    requestAnimationFrame(frame);
  }

  // The page plays from the start, even where the system asks for reduced motion: the moving
  // buddies are the content here, not decoration. (2026-10-07: starting paused under that setting,
  // with the loop also broken, read to the owner as "a picture gallery slideshow".)
  restart();
  requestAnimationFrame(frame);
  // }}}
})();
