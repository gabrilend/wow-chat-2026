// scene-kit.js - the page side of the playable scenes of the buddy roaming
// gallery: the control strip (buttons, choices, sliders), the map layer
// drawn once into an offscreen canvas, the page's colours, and the frame
// loop. No roaming rules here: those are the pattern (roam-pattern.js,
// docs/roaming-pattern.md). The gallery generator inlines this file after
// roam-pattern.js and before the scene scripts (the artifact host runs no
// linked scripts).
//
// Why playable pages instead of GIFs (the owner, 2026-09-28): "the gallery
// rendering was taking too long, my computer can't keep up [...] ok let's
// make them playable scenes and allow the user to change certain things
// with their mouse on buttons." The browser draws only what is on screen,
// on the graphics card, and nothing has to be compressed.
(function (global) {
  "use strict";
  if (global.SceneKit) return;

  // {{{ styles, once per page, from the page's own tokens
  function addStyles() {
    if (document.getElementById("scene-kit-styles")) return;
    const s = document.createElement("style");
    s.id = "scene-kit-styles";
    s.textContent = `
      .sk { display: grid; gap: 10px; }
      .sk canvas { width: 100%; height: auto; max-width: 100%; border-radius: 6px; background: #0c0f14; touch-action: manipulation; cursor: pointer; }
      .sk-row { display: flex; flex-wrap: wrap; gap: 8px 16px; align-items: center; font-size: .9rem; color: var(--muted); }
      .sk-group { display: inline-flex; flex-wrap: wrap; gap: 4px; align-items: center; }
      .sk-group > .sk-label { margin-right: 2px; }
      .sk button { font: inherit; font-size: .85rem; padding: 4px 10px; border-radius: 6px; border: 1px solid var(--rule); background: var(--panel); color: var(--ink); cursor: pointer; }
      .sk button[aria-pressed="true"] { background: var(--accent); color: var(--panel); border-color: var(--accent); }
      .sk button:focus-visible, .sk input:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
      .sk input[type=range] { width: 110px; accent-color: var(--accent); }
      .sk-value { color: var(--ink); font-weight: 700; font-variant-numeric: tabular-nums; }
      .sk-counts { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 4px 14px; font-size: .88rem; color: var(--muted); font-variant-numeric: tabular-nums; }
      .sk-counts b { color: var(--ink); }
      .sk-note { font-size: .88rem; color: var(--muted); min-height: 1.4em; }`;
    document.head.appendChild(s);
  }
  // }}}

  // {{{ the control strip
  // One row of controls. Each item: { kind: "button" | "toggle" | "choice" |
  // "range", id, label?, text?, value?, options?: [[value, text]], min,
  // max, step, format? }. `onChange(id, value, element)` after each change.
  // Returns a live object of the current values by id.
  function controlRow(root, items, onChange) {
    addStyles();
    const row = document.createElement("div");
    row.className = "sk-row";
    const values = {};
    for (const it of items) {
      const group = document.createElement("span");
      group.className = "sk-group";
      if (it.label) group.insertAdjacentHTML("beforeend", `<span class="sk-label">${it.label}</span>`);
      if (it.kind === "button") {
        const b = button(it.id, it.text);
        b.addEventListener("click", () => onChange(it.id, null, b));
        group.append(b);
      } else if (it.kind === "toggle") {
        values[it.id] = !!it.value;
        const b = button(it.id, it.text, values[it.id]);
        b.addEventListener("click", () => { values[it.id] = !values[it.id]; b.setAttribute("aria-pressed", String(values[it.id])); onChange(it.id, values[it.id], b); });
        group.append(b);
      } else if (it.kind === "choice") {
        values[it.id] = it.value;
        for (const [v, text] of it.options) {
          const b = button(`${it.id}-${v}`, text, v === it.value);
          b.addEventListener("click", () => {
            values[it.id] = v;
            group.querySelectorAll("button").forEach(x => x.setAttribute("aria-pressed", String(x === b)));
            onChange(it.id, v, b);
          });
          group.append(b);
        }
      } else if (it.kind === "range") {
        values[it.id] = +it.value;
        const r = document.createElement("input");
        Object.assign(r, { type: "range", id: it.id, min: it.min, max: it.max, step: it.step, value: it.value });
        r.setAttribute("aria-label", it.label || it.id);
        const shown = document.createElement("span");
        shown.className = "sk-value";
        const fmt = it.format || String;
        shown.textContent = fmt(+it.value);
        r.addEventListener("input", () => { values[it.id] = +r.value; shown.textContent = fmt(+r.value); onChange(it.id, +r.value, r); });
        group.append(r, shown);
      }
      row.append(group);
    }
    root.append(row);
    return values;
  }
  function button(id, text, pressed) {
    const b = document.createElement("button");
    b.type = "button"; b.id = id; b.textContent = text;
    if (pressed !== undefined) b.setAttribute("aria-pressed", String(!!pressed));
    return b;
  }
  // }}}

  // {{{ colours and the map layer
  function pageColours(el) {
    const cs = getComputedStyle(el), v = (name, fallback) => cs.getPropertyValue(name).trim() || fallback;
    const ground = v("--ground", "#eef0f3");
    const m = /#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/i.exec(ground);
    const dark = m ? (parseInt(m[1], 16) + parseInt(m[2], 16) + parseInt(m[3], 16)) / 3 < 110 : false;
    return { dark, accent: v("--accent", "#8a5d0c") };
  }
  // The grid's ground drawn once: rock dark, rooms light, tunnels a shade
  // darker, the dead end warm; rocks as circles.
  function mapLayer(grid, scale, dark) {
    const cv = document.createElement("canvas");
    cv.width = Math.round((grid.x0 + grid.nx * grid.cell) * scale);
    cv.height = Math.round((grid.y0 + grid.ny * grid.cell) * scale);
    const c = cv.getContext("2d"), rock = dark ? "#0c0f14" : "#2a2622";
    c.fillStyle = rock; c.fillRect(0, 0, cv.width, cv.height);
    const shade = { room: dark ? "#28303b" : "#cfd5dc", tunnel: dark ? "#222933" : "#bfc6cf", dead: dark ? "#3a2c2c" : "#dcc9c4" };
    const s = grid.cell * scale;
    for (let i = 0; i < grid.n; i++) {
      if (!grid.open[i]) continue;
      const { x, y } = grid.middle(i);
      c.fillStyle = shade[grid.area.rects[grid.rect[i]].kind];
      c.fillRect((x - grid.cell / 2) * scale, (y - grid.cell / 2) * scale, s + 0.6, s + 0.6);
    }
    c.fillStyle = rock;
    for (const k of grid.area.rocks) { c.beginPath(); c.arc(k.x * scale, k.y * scale, k.r * scale, 0, 2 * Math.PI); c.fill(); }
    cv.dark = dark;
    return cv;
  }
  // }}}

  // {{{ the frame loop
  // `step(dt)` runs `api.rate` simulated seconds per real second in fixed
  // steps of dt, then `draw()`. Paused while the scene is off screen or the
  // tab is hidden; starts paused when the viewer asks for reduced motion
  // (returns true then).
  function runLoop(el, dt, step, draw, api) {
    let visible = true, last = 0, carry = 0;
    const reduce = !!(global.matchMedia && global.matchMedia("(prefers-reduced-motion: reduce)").matches);
    api.running = !reduce;
    if ("IntersectionObserver" in global) new IntersectionObserver(es => { visible = es[0].isIntersecting; }).observe(el);
    function frame(now) {
      requestAnimationFrame(frame);
      const real = last ? Math.min(0.1, (now - last) / 1000) : 0;
      last = now;
      if (!visible || document.hidden) return;
      if (api.running) {
        carry += real * api.rate;
        let guard = 0;
        while (carry >= dt && guard++ < 400) { step(dt); carry -= dt; }
        if (guard >= 400) carry = 0;          // too far behind: drop it rather than freeze the page
      }
      draw();
    }
    requestAnimationFrame(frame);
    return reduce;
  }
  // }}}

  global.SceneKit = { controlRow, pageColours, mapLayer, runLoop, addStyles };
})(typeof window !== "undefined" ? window : globalThis);
