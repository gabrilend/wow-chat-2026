// join-leave.js - the interactive "joining and leaving the owner's group"
// widget of the buddy roaming gallery (issues 617c2, 617e5). A drawn
// simulation of the intended behaviour, not the game: the owner's dot eases
// toward the cursor (or finger); five buddies roam the area with the
// owner's waypoint rule (the bearing turns a tenth of a circle a waypoint,
// the distance out moves 1 to 20 points of 100 at even odds, never nearer
// the centre than 10 yards, a waypoint within 5 yards of someone moves 10
// points toward the middle, a blocked spot slides along its bearing); and
// the grouping rules of 617c2 run live, drawn at half their real distances
// so the drawn area can show them (the GIF it replaces did the same).
//
// The page embeds this file's text in a <script> of its own (the artifact
// host only runs scripts from a few approved CDNs, so a separate file next
// to the page was blocked there, 2026-09-27); this file is the source the
// generator reads.
(function () {
  "use strict";
  var cv = document.getElementById("jl-canvas");
  if (!cv) return;
  var ctx = cv.getContext("2d");

  // {{{ the area and its numbers (yards)
  var AW = 128, AH = 98;                     // the drawn world
  var OUTLINE = [[6, 14], [40, 4], [88, 8], [122, 24], [124, 60], [104, 88], [60, 94], [22, 84], [2, 52]];
  var ROCKS = [[42, 34, 6], [80, 30, 5], [64, 60, 7], [30, 64, 4], [100, 58, 4], [88, 76, 3]];
  var DT = 1 / 30;
  var OWNER_SPEED = 8.4, BUDDY_SPEED = 4.8;  // yards a second (both 20% up, 2026-09-28: the owner, "a little faster [...] Just for the scenes with the player dot")
  // the grouping distances, drawn at half the real ones (60, 74, 75, 70)
  var HALF = 0.5;
  var JOIN = 60 * HALF, FAR = 74 * HALF, LEAVE = 75 * HALF, MERGE = 70 * HALF;
  var SEATS = 4;                             // the owner's party holds four buddies
  var FAR_SIZE = 5;                          // a far party holds five
  var PASS = 0.5;                            // seconds between grouping passes (5 in game)
  // the owner's waypoint rule
  var TURN = Math.PI * 2 / 10, NEAR = 10, CLEAR = 3, CROWD = 5, CROWD_SHIFT = 10;
  var BUDDIES = [
    { name: "Warrior", letter: "W", color: "#e07a62" },
    { name: "Mage",    letter: "M", color: "#7fa6e6" },
    { name: "Hunter",  letter: "H", color: "#9ccc65" },
    { name: "Priest",  letter: "P", color: "#f0e2a0" },
    { name: "Rogue",   letter: "R", color: "#c4a3ee" }
  ];
  // }}}

  // {{{ geometry
  function inside(x, y) {
    var r = false, j = OUTLINE.length - 1;
    for (var i = 0; i < OUTLINE.length; i++) {
      var xi = OUTLINE[i][0], yi = OUTLINE[i][1], xj = OUTLINE[j][0], yj = OUTLINE[j][1];
      if ((yi > y) !== (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) r = !r;
      j = i;
    }
    return r;
  }
  function edgeDistance(x, y) {
    var best = Infinity;
    for (var i = 0; i < OUTLINE.length; i++) {
      var a = OUTLINE[i], b = OUTLINE[(i + 1) % OUTLINE.length];
      var vx = b[0] - a[0], vy = b[1] - a[1];
      var t = Math.max(0, Math.min(1, ((x - a[0]) * vx + (y - a[1]) * vy) / (vx * vx + vy * vy)));
      best = Math.min(best, Math.hypot(a[0] + vx * t - x, a[1] + vy * t - y));
    }
    return best;
  }
  // a place a body can stand: inside, `margin` clear of rocks
  function walkable(x, y, margin) {
    if (!inside(x, y)) return false;
    for (var i = 0; i < ROCKS.length; i++) {
      var k = ROCKS[i];
      if (Math.hypot(x - k[0], y - k[1]) < k[2] + margin) return false;
    }
    return true;
  }
  // yards from the centre along a bearing to the area's edge
  function rayToEdge(cx, cy, a) {
    var dx = Math.cos(a), dy = Math.sin(a), best = Infinity;
    for (var i = 0; i < OUTLINE.length; i++) {
      var p = OUTLINE[i], q = OUTLINE[(i + 1) % OUTLINE.length];
      var ex = q[0] - p[0], ey = q[1] - p[1];
      var den = dx * ey - dy * ex;
      if (Math.abs(den) < 1e-9) continue;
      var t = ((p[0] - cx) * ey - (p[1] - cy) * ex) / den;
      var u = ((p[0] - cx) * dy - (p[1] - cy) * dx) / den;
      if (t > 0 && u >= 0 && u <= 1 && t < best) best = t;
    }
    return best;
  }
  var CX = 0, CY = 0;
  OUTLINE.forEach(function (p) { CX += p[0]; CY += p[1]; });
  CX /= OUTLINE.length; CY /= OUTLINE.length;
  function dist(a, b) { return Math.hypot(a.x - b.x, a.y - b.y); }
  // }}}

  var S, pointer = null, running = true, visible = true;

  // {{{ the owner's waypoint rule
  function pickWaypoint(b) {
    for (var turns = 0; turns < 12; turns++) {
      b.angle += TURN * b.spin;
      var reach = rayToEdge(CX, CY, b.angle) - CLEAR;
      // the step: 1..20 points in or out at even odds, kept within 1..100
      var change = 1 + Math.floor(Math.random() * 20);
      var pct = Math.max(1, Math.min(100, b.pct + (Math.random() < 0.5 ? -change : change)));
      // crowding: someone within 5 yards of that spot moves it 10 toward 50
      var d0 = Math.max(NEAR, pct / 100 * reach);
      var sx = CX + Math.cos(b.angle) * d0, sy = CY + Math.sin(b.angle) * d0;
      var crowded = [S.owner].concat(S.buddies).some(function (o) { return o !== b && Math.hypot(o.x - sx, o.y - sy) < CROWD; });
      if (crowded) pct = pct < 50 ? pct + CROWD_SHIFT : pct > 50 ? pct - CROWD_SHIFT : pct + (Math.random() < 0.5 ? -CROWD_SHIFT : CROWD_SHIFT);
      b.pct = pct;
      // a blocked spot slides along the bearing, nearer first then farther
      for (var k = 1; k < 200; k++) {
        var share = pct / 100 + Math.floor(k / 2) * (k % 2 === 0 ? -1 : 1) / 100;
        if (share < 0.01 || share > 1) continue;
        var d = Math.max(NEAR, share * reach);
        var x = CX + Math.cos(b.angle) * d, y = CY + Math.sin(b.angle) * d;
        if (walkable(x, y, CLEAR) && edgeDistance(x, y) >= CLEAR) { b.wp = { x: x, y: y }; b.wpTime = 0; return; }
      }
    }
  }
  // walk toward the waypoint: of sixteen headings that stay walkable, the
  // one pointing most nearly at it (so rocks are slid round)
  function walk(b) {
    b.wpTime += DT;
    var dx = b.wp.x - b.x, dy = b.wp.y - b.y, d = Math.hypot(dx, dy);
    var step = BUDDY_SPEED * DT;
    if (d <= step || b.wpTime > 25) { pickWaypoint(b); return; }
    var best = -2, bx = b.x, by = b.y;
    for (var k = 0; k < 16; k++) {
      var a = k * Math.PI / 8, hx = Math.cos(a), hy = Math.sin(a);
      var x = b.x + hx * step, y = b.y + hy * step;
      if (!walkable(x, y, 1)) continue;
      var aim = (hx * dx + hy * dy) / d;
      if (aim > best) { best = aim; bx = x; by = y; }
    }
    b.x = bx; b.y = by;
  }
  // }}}

  // {{{ the grouping pass (617c2), at half distances
  function say(t) { S.log.unshift(t); if (S.log.length > 6) S.log.length = 6; }
  function farPartyOf(b) { for (var i = 0; i < S.far.length; i++) if (S.far[i].indexOf(b) >= 0) return S.far[i]; return null; }
  function leaveFar(b, why) {
    var p = farPartyOf(b);
    if (!p) return;
    p.splice(p.indexOf(b), 1);
    say(b.name + " left the far party (" + why + ").");
    if (p.length === 1) { say(p[0].name + " is alone: that far party breaks up."); p.length = 0; }
    S.far = S.far.filter(function (q) { return q.length > 0; });
  }
  function groupingPass() {
    var O = S.owner;
    // the owner's party: leave past 75
    S.buddies.forEach(function (b) {
      if (b.inOwner && dist(b, O) > LEAVE) { b.inOwner = false; say(b.name + " left your group (past 75 yards)."); }
    });
    var seatsUsed = S.buddies.filter(function (b) { return b.inOwner; }).length;
    // far parties: leave within 74 of the owner (so also whenever it could
    // join the owner's party), or when more than 74 from every other member
    S.buddies.forEach(function (b) {
      var p = farPartyOf(b);
      if (!p) return;
      if (dist(b, O) <= FAR) { leaveFar(b, "back within 74 yards of you"); return; }
      var near = p.some(function (o) { return o !== b && dist(o, b) <= FAR; });
      if (!near) leaveFar(b, "more than 74 yards from the rest of it");
    });
    // join the owner's party within 60, nearest first, while it has room
    S.buddies.filter(function (b) { return !b.inOwner && !farPartyOf(b) && dist(b, O) <= JOIN; })
      .sort(function (a, b) { return dist(a, O) - dist(b, O); })
      .forEach(function (b) {
        if (seatsUsed < SEATS) { b.inOwner = true; seatsUsed++; say(b.name + " joined your group (inside 60 yards)."); }
      });
    // far buddies (past 74, ungrouped): join a far party with room that has
    // a member within 70, else pair with another loose far buddy within 70
    var loose = S.buddies.filter(function (b) { return !b.inOwner && !farPartyOf(b) && dist(b, O) > FAR; });
    loose.forEach(function (b) {
      if (farPartyOf(b)) return;
      var home = S.far.filter(function (p) { return p.length < FAR_SIZE && p.some(function (o) { return dist(o, b) <= MERGE; }); })[0];
      if (home) { home.push(b); say(b.name + " joined a far party."); return; }
      var mate = loose.filter(function (o) { return o !== b && !farPartyOf(o) && dist(o, b) <= MERGE; })[0];
      if (mate) { S.far.push([b, mate]); say(b.name + " and " + mate.name + " formed a far party."); }
    });
    // two far parties merge when members come within 70 and they fit
    for (var i = 0; i < S.far.length; i++) for (var j = i + 1; j < S.far.length; j++) {
      var p = S.far[i], q = S.far[j];
      if (!p.length || !q.length || p.length + q.length > FAR_SIZE) continue;
      var close = p.some(function (a) { return q.some(function (c) { return dist(a, c) <= MERGE; }); });
      if (close) { Array.prototype.push.apply(p, q.splice(0)); say("Two far parties merged."); }
    }
    S.far = S.far.filter(function (p) { return p.length > 0; });
  }
  // }}}

  // {{{ reset and update
  function reset() {
    S = { t: 0, sincePass: 0, owner: { x: 14, y: 50, isOwner: true }, far: [], log: [], buddies: [] };
    BUDDIES.forEach(function (d, i) {
      var b = { name: d.name, letter: d.letter, color: d.color, inOwner: false, pct: 20 + Math.floor(Math.random() * 60) };
      do { b.x = 10 + Math.random() * 108; b.y = 10 + Math.random() * 80; } while (!walkable(b.x, b.y, 2));
      b.angle = Math.atan2(b.y - CY, b.x - CX); b.spin = Math.random() < 0.5 ? 1 : -1;
      S.buddies.push(b);
    });
    S.buddies.forEach(pickWaypoint);
    pointer = null;
    say("A new day. Move the cursor over the area: you follow it.");
    groupingPass();
    hud();
  }
  function update() {
    S.t += DT;
    var O = S.owner;
    // the owner eases toward the cursor, stopping a yard short, and keeps
    // to the area (a step that would leave it isn't taken)
    if (pointer) {
      var dx = pointer.x - O.x, dy = pointer.y - O.y, d = Math.hypot(dx, dy);
      if (d > 1) {
        var s = Math.min(d - 1, OWNER_SPEED * DT);
        var nx = O.x + dx / d * s, ny = O.y + dy / d * s;
        if (walkable(nx, ny, 0.5)) { O.x = nx; O.y = ny; }
        else if (walkable(nx, O.y, 0.5)) O.x = nx;
        else if (walkable(O.x, ny, 0.5)) O.y = ny;
      }
    }
    S.buddies.forEach(walk);
    S.sincePass += DT;
    if (S.sincePass >= PASS) { S.sincePass = 0; groupingPass(); }
  }
  // }}}

  // {{{ drawing
  var scale = 1;
  function resize() {
    var dpr = window.devicePixelRatio || 1;
    var w = cv.clientWidth || 600;
    cv.width = Math.round(w * dpr); cv.height = Math.round(w * AH / AW * dpr);
    scale = cv.width / AW;
  }
  function X(v) { return v * scale; }
  function ringAt(x, y, r, color, dash, width) {
    ctx.beginPath(); ctx.setLineDash(dash ? [X(1.4), X(1.1)] : []);
    ctx.arc(X(x), X(y), X(r), 0, Math.PI * 2);
    ctx.lineWidth = Math.max(1, X(width || 0.3)); ctx.strokeStyle = color; ctx.stroke(); ctx.setLineDash([]);
  }
  function draw() {
    ctx.fillStyle = "#12161d"; ctx.fillRect(0, 0, cv.width, cv.height);
    // the area and its rocks
    ctx.beginPath();
    OUTLINE.forEach(function (p, i) { if (i) ctx.lineTo(X(p[0]), X(p[1])); else ctx.moveTo(X(p[0]), X(p[1])); });
    ctx.closePath(); ctx.fillStyle = "#1f2833"; ctx.fill();
    ctx.lineWidth = Math.max(1, X(0.3)); ctx.strokeStyle = "#4a5a6e"; ctx.stroke();
    ROCKS.forEach(function (k) {
      ctx.beginPath(); ctx.arc(X(k[0]), X(k[1]), X(k[2]), 0, Math.PI * 2);
      ctx.fillStyle = "#5a5146"; ctx.fill(); ctx.strokeStyle = "#7a6e60"; ctx.stroke();
    });
    var O = S.owner;
    // the rings round the owner (half the real distances)
    ringAt(O.x, O.y, JOIN, "#5ec27a", true);
    ringAt(O.x, O.y, FAR, "#d7b85a", false);
    ringAt(O.x, O.y, LEAVE, "#e06c5a", true);
    // far parties: members joined by faint gold lines
    S.far.forEach(function (p) {
      ctx.strokeStyle = "rgba(215,184,90,0.45)"; ctx.lineWidth = Math.max(1, X(0.35));
      for (var i = 0; i < p.length; i++) for (var j = i + 1; j < p.length; j++) {
        ctx.beginPath(); ctx.moveTo(X(p[i].x), X(p[i].y)); ctx.lineTo(X(p[j].x), X(p[j].y)); ctx.stroke();
      }
    });
    // lines from the owner to its party
    S.buddies.forEach(function (b) {
      if (!b.inOwner) return;
      ctx.strokeStyle = "rgba(255,255,255,0.35)"; ctx.lineWidth = Math.max(1, X(0.3));
      ctx.beginPath(); ctx.moveTo(X(O.x), X(O.y)); ctx.lineTo(X(b.x), X(b.y)); ctx.stroke();
    });
    // waypoints: a small faint cross each
    S.buddies.forEach(function (b) {
      var x = X(b.wp.x), y = X(b.wp.y), r = X(1.1);
      ctx.strokeStyle = b.color; ctx.globalAlpha = 0.5; ctx.lineWidth = Math.max(1, X(0.3));
      ctx.beginPath(); ctx.moveTo(x - r, y - r); ctx.lineTo(x + r, y + r); ctx.moveTo(x - r, y + r); ctx.lineTo(x + r, y - r); ctx.stroke();
      ctx.globalAlpha = 1;
    });
    // the buddies: a disc with a letter; a white ring in your group, gold in a far party
    S.buddies.forEach(function (b) {
      ctx.beginPath(); ctx.arc(X(b.x), X(b.y), X(1.9), 0, Math.PI * 2); ctx.fillStyle = b.color; ctx.fill();
      ctx.fillStyle = "#12161d"; ctx.font = "700 " + Math.round(X(2.2)) + "px system-ui, sans-serif";
      ctx.textAlign = "center"; ctx.textBaseline = "middle"; ctx.fillText(b.letter, X(b.x), X(b.y) + X(0.1));
      if (b.inOwner) ringAt(b.x, b.y, 3.1, "#ffffff", false, 0.45);
      else if (farPartyOf(b)) ringAt(b.x, b.y, 3.1, "#d7b85a", false, 0.45);
    });
    // the owner
    ctx.beginPath(); ctx.arc(X(O.x), X(O.y), X(2.1), 0, Math.PI * 2); ctx.fillStyle = "#ffffff"; ctx.fill();
    if (pointer) {
      ctx.strokeStyle = "rgba(255,255,255,0.3)"; ctx.setLineDash([X(0.8), X(0.8)]);
      ctx.beginPath(); ctx.moveTo(X(O.x), X(O.y)); ctx.lineTo(X(pointer.x), X(pointer.y)); ctx.stroke(); ctx.setLineDash([]);
    }
  }
  var el = {
    owner: document.getElementById("jl-owner"), far: document.getElementById("jl-far"),
    alone: document.getElementById("jl-alone"), log: document.getElementById("jl-log")
  };
  function hud() {
    var inOwner = S.buddies.filter(function (b) { return b.inOwner; });
    var alone = S.buddies.filter(function (b) { return !b.inOwner && !farPartyOf(b); });
    if (el.owner) el.owner.textContent = inOwner.length + " of " + SEATS + (inOwner.length ? ": " + inOwner.map(function (b) { return b.name; }).join(", ") : "");
    if (el.far) el.far.textContent = S.far.length ? S.far.map(function (p) { return p.map(function (b) { return b.name; }).join(" + "); }).join(" · ") : "none";
    if (el.alone) el.alone.textContent = alone.length ? alone.map(function (b) { return b.name; }).join(", ") : "nobody";
    if (el.log) el.log.innerHTML = S.log.map(function (s) { return "<li>" + s + "</li>"; }).join("");
  }
  // }}}

  // {{{ the loop: fixed steps, drawn each frame; stops when off screen
  var acc = 0, last = 0, lastHud = 0;
  function frame(now) {
    if (!visible) { last = 0; return; }
    requestAnimationFrame(frame);
    if (!last) last = now;
    acc += Math.min(0.25, (now - last) / 1000); last = now;
    if (running) while (acc >= DT) { update(); acc -= DT; } else acc = 0;
    draw();
    if (S.t - lastHud > 0.25 || !running) { hud(); lastHud = S.t; }
  }
  // }}}

  // {{{ input
  function toWorld(ev) {
    var r = cv.getBoundingClientRect();
    return { x: (ev.clientX - r.left) / r.width * AW, y: (ev.clientY - r.top) / r.height * AH };
  }
  cv.addEventListener("pointermove", function (ev) { pointer = toWorld(ev); });
  cv.addEventListener("pointerdown", function (ev) { pointer = toWorld(ev); });
  cv.addEventListener("pointerleave", function (ev) { if (ev.pointerType === "mouse") pointer = null; });
  var play = document.getElementById("jl-play");
  function setRunning(on) { running = on; if (play) { play.textContent = on ? "Pause" : "Play"; play.setAttribute("aria-pressed", on ? "false" : "true"); } }
  if (play) play.addEventListener("click", function () { setRunning(!running); });
  var rst = document.getElementById("jl-reset");
  if (rst) rst.addEventListener("click", function () { reset(); draw(); });
  window.addEventListener("resize", function () { resize(); draw(); });
  if ("IntersectionObserver" in window) {
    new IntersectionObserver(function (entries) {
      var v = entries[0].isIntersecting;
      if (v && !visible) { visible = true; requestAnimationFrame(frame); }
      visible = v;
    }).observe(cv);
  }
  // }}}

  reset();
  resize();
  var reduce = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  setRunning(!reduce);                         // reduced motion: waits for Play
  draw(); hud();
  requestAnimationFrame(frame);
})();
