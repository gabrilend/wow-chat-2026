// dungeon-kraken.js - the playable "kraken in the dungeon" scene of the
// buddy roaming gallery (issue 617e5). A drawn simulation of the intended
// behaviour, not the game's combat: health, damage, speeds and cooldowns
// are round numbers. A party of five explores the big dungeon
// (the roaming pattern, docs/roaming-pattern.md: rules from roam-pattern.js,
// page parts from scene-kit.js), the tank leading by least paint; packs stand in the
// rooms and patrols walk the tunnels between them. With the kraken on, a
// fight is the owner's battle pattern (2026-09-27):
//
//   "picture a kraken sitting at the base of a massive whirlpool. It has
//   tentacles that reach out and grab nearby ships and pulls them into it's
//   insatiable maw. That is the tank [...] The tank should be able to move
//   in a small radius from the AoE spot [...] DPS, especially ranged DPS,
//   can pull monsters [...] hit them once to generate as little threat as
//   possible, and apply a movement slowing effect. Then they move to the
//   opposite side of a neighboring quadrant [...] If all the mobs are slain
//   and the AoE zone is empty, then the entire structure moves on."
//
// With it off, the party fights the ordinary way: everyone on the tank's
// target, nobody pulling. Monsters are faster than the party (the owner,
// 2026-09-27: "the enemies should move faster than the player, so they can
// always hit"), so slows, blinks, disengages and the tank's taunt are what
// save a puller, not its legs.
(function () {
  "use strict";
  var root = document.getElementById("dk-root");
  var RP = window.RoamPattern, SK = window.SceneKit;
  if (!root || !RP || !SK) return;
  var map = RP.maps.dungeon, g = new RP.Grid(map, 3);

  // {{{ numbers
  var DT = 0.1;
  var RUN = 8.4, MOB_SPEED = 9.6;            // yards a second (the widgets' pace, 2026-09-28)
  var AGGRO = 10, SEE_PACK = 40, TAUNT = 30, TAUNT_CD = 2.5;
  // PULL_REACH 50 first (the open-field widget's): in the dungeon the next
  // monsters stood 50-85 yards from the maw and nothing was ever pulled
  // (2026-09-28); each pack now also has a lone outlier 25-40 yards off.
  var MAW_R = 9, HOLD_R = 6, LEAD_R = 20, KITE_R = 16, PULL_REACH = 75;
  var HOLD_MAX = 6;                          // the tank reaches out while holding this many or fewer
  var LINK = 12;                             // a patrol this near a fighting monster blunders in
  var RESPAWN = 180;
  var PACK_SPOTS = [[250, 160], [222, 218], [292, 224], [60, 45], [98, 82], [405, 45], [458, 88], [410, 200], [458, 262], [418, 312], [72, 232], [300, 150]];
  var ROUTES = [[[250, 190], [65, 60]], [[250, 190], [420, 60]], [[250, 190], [430, 250]], [[285, 235], [420, 300]],
                [[70, 300], [240, 200]], [[70, 50], [430, 45]], [[65, 140], [180, 170]], [[300, 170], [470, 180]],
                [[230, 100], [250, 170]], [[420, 90], [445, 140]], [[330, 60], [140, 60]], [[395, 185], [320, 185]]];
  var ROLE = {
    tank:   { letter: "T", color: "#e0735a", hp: 220, range: 2,  dps: 3 },
    mage:   { letter: "M", color: "#7fa6e6", hp: 100, range: 30, dps: 5 },
    hunter: { letter: "H", color: "#9ccc65", hp: 110, range: 35, dps: 5 },
    healer: { letter: "P", color: "#f0e2a0", hp: 100, range: 40, dps: 0 },
    melee:  { letter: "F", color: "#c9a0ee", hp: 130, range: 2,  dps: 6 }
  };
  // }}}

  // {{{ the widget's parts
  root.classList.add("sk");
  var SCALE = 2;
  var cv = document.createElement("canvas");
  cv.width = Math.round((g.x0 + g.nx * g.cell) * SCALE); cv.height = Math.round((g.y0 + g.ny * g.cell) * SCALE);
  cv.setAttribute("aria-label", "The dungeon from above: the party as lettered dots, monsters red, patrols ringed in gold");
  var counts = document.createElement("div"); counts.className = "sk-counts";
  var note = document.createElement("div"); note.className = "sk-note";
  var api = { running: true, rate: 4 };
  var opt = SK.controlRow(root, [
    { kind: "toggle", id: "dk-kraken", text: "Kraken pattern", value: true },
    { kind: "choice", id: "dk-packs", label: "Packs", value: 8, options: [[4, "4"], [8, "8"], [12, "12"]] },
    { kind: "choice", id: "dk-patrols", label: "Patrols", value: 8, options: [[0, "0"], [4, "4"], [8, "8"], [12, "12"]] },
    { kind: "choice", id: "dk-melee", label: "Melee", value: "whirlwind", options: [["whirlwind", "Whirlwind"], ["heavy", "Heavy hitter"], ["control", "Control"]] }
  ], function (id) { if (id === "dk-packs" || id === "dk-patrols") reset(); });
  SK.controlRow(root, [
    { kind: "choice", id: "dk-rate", label: "Speed", value: 4, options: [[1, "1×"], [4, "4×"], [12, "12×"]] },
    { kind: "button", id: "dk-play", text: "Pause" },
    { kind: "button", id: "dk-reset", text: "Start over" }
  ], function (id, v, el) {
    if (id === "dk-rate") api.rate = v;
    if (id === "dk-play") { api.running = !api.running; el.textContent = api.running ? "Pause" : "Play"; }
    if (id === "dk-reset") reset();
  });
  root.appendChild(cv); root.appendChild(counts); root.appendChild(note);
  var ctx = cv.getContext("2d");
  // }}}

  var S, layer = null;

  // {{{ reset
  function reset() {
    var e = map.entrance;
    S = { t: 0, paint: new RP.Paint(g), nextPaint: 0,
          party: ["tank", "mage", "hunter", "healer", "melee"].map(function (r, i) {
            return { role: r, x: e.x - 8 + i * 4, y: e.y - 10, hp: ROLE[r].hp, max: ROLE[r].hp, dead: 0,
                     cd: 0, blink: 0, pull: null, path: null, pathTo: null, pathAt: -9, hop: 0 };
          }),
          mobs: [], fight: false, maw: null, lines: [], goal: null,
          c: { taunts: 0, reach: 0, pulls: 0, slows: 0, blinks: 0, disengages: 0, kills: 0, blunders: 0, deaths: 0, fights: 0, aoe: 0 } };
    var id = 0;
    PACK_SPOTS.slice(0, opt["dk-packs"]).forEach(function (p, k) {
      for (var m = 0; m < 3; m++) {
        var a = m * 2.1, x = p[0] + Math.cos(a) * 4, y = p[1] + Math.sin(a) * 4;
        S.mobs.push(mob(id++, x, y, m === 0 && k % 3 === 0, k));
      }
      // its outlier: a lone monster on open ground 25-40 yards off, the
      // kind the tank reaches for and the pullers fetch
      for (var tries = 0; tries < 20; tries++) {
        var oa = Math.random() * 2 * Math.PI, od = 25 + Math.random() * 15, ox = p[0] + Math.cos(oa) * od, oy = p[1] + Math.sin(oa) * od;
        if (g.isOpen(ox, oy) && g.sight(p[0], p[1], ox, oy)) { S.mobs.push(mob(id++, ox, oy, false, -1)); break; }
      }
    });
    ROUTES.slice(0, opt["dk-patrols"]).forEach(function (r) {
      var m = mob(id++, r[0][0], r[0][1], false, -1);
      m.route = RP.findPath(g, { x: r[0][0], y: r[0][1] }, { x: r[1][0], y: r[1][1] }) || [];
      m.route.unshift({ x: r[0][0], y: r[0][1] });
      m.leg = 1; m.dir = 1;
      S.mobs.push(m);
    });
    say("The tank leads by the least painted ground; the party follows. Patrols (gold rings) walk the tunnels.");
  }
  function mob(id, x, y, elite, pack) {
    return { id: id, hx: x, hy: y, x: x, y: y, elite: elite, pack: pack, hp: elite ? 420 : 160, max: elite ? 420 : 160,   // tougher than a first try (260 / 90): fights of ~7 s ended before any puller reached an outlier (2026-09-28)
             state: "idle", target: null, slow: 0, respawn: 0, path: null, pathTo: null, pathAt: -9, route: null };
  }
  function say(s) { note.textContent = s; }
  // }}}

  // {{{ small helpers
  function dist(a, b) { return Math.hypot(a.x - b.x, a.y - b.y); }
  function tank() { return S.party[0]; }
  function alive(p) { return !p.dead; }
  function line(a, b, color, dash, life) { S.lines.push({ x0: a.x, y0: a.y, x1: b.x, y1: b.y, color: color, dash: dash, until: S.t + (life || 0.6) }); }
  // Walk toward (tx, ty): straight when in sight, else along a path over
  // the grid, re-planned twice a second. A straight step that would land on
  // closed ground (the line of sight is sampled, so a corner can look
  // clear) switches to the path for a second: without that a walker at a
  // tunnel's corner could stand still for good (found 2026-09-28).
  // Returns true once within `stop`.
  function move(e, tx, ty, speed, stop, dt) {
    var d = Math.hypot(tx - e.x, ty - e.y);
    if (d <= (stop || 0.5)) return true;
    var aim = { x: tx, y: ty };
    e.forcePath = Math.max(0, (e.forcePath || 0) - dt);
    if (e.forcePath > 0 || !g.sight(e.x, e.y, tx, ty)) {
      if (!e.path || S.t - e.pathAt > 0.5 || !e.pathTo || Math.hypot(e.pathTo.x - tx, e.pathTo.y - ty) > 4) {
        e.path = RP.findPath(g, e, { x: tx, y: ty }); e.pathTo = { x: tx, y: ty }; e.pathAt = S.t;
      }
      if (e.path && e.path.length) { aim = e.path[0]; if (Math.hypot(aim.x - e.x, aim.y - e.y) < 1) { e.path.shift(); if (e.path.length) aim = e.path[0]; } }
    } else e.path = null;
    var ad = Math.hypot(aim.x - e.x, aim.y - e.y), step = Math.min(speed * dt, Math.max(0, ad - (aim.x === tx && aim.y === ty ? (stop || 0.5) : 0)));
    if (ad > 1e-6) {
      var nx = e.x + (aim.x - e.x) / ad * step, ny = e.y + (aim.y - e.y) / ad * step;
      if (g.isOpen(nx, ny)) { e.x = nx; e.y = ny; }
      else { e.forcePath = 1; e.path = null; }
    }
    return false;
  }
  function engaged() { return S.mobs.filter(function (m) { return m.state === "fight"; }); }
  function engage(m, who) {
    if (m.state !== "idle") return;
    m.state = "fight"; m.target = who;
    // its pack comes with it
    if (m.pack >= 0) S.mobs.forEach(function (o) { if (o.pack === m.pack && o.state === "idle") { o.state = "fight"; o.target = who; } });
  }
  function threat() { return engaged().reduce(function (s, m) { return s + (m.elite ? 3 : 1); }, 0); }
  // }}}

  // {{{ one step
  function step(dt) {
    S.t += dt;
    var T = tank(), kraken = opt["dk-kraken"];
    S.lines = S.lines.filter(function (l) { return l.until > S.t; });
    if (S.t >= S.nextPaint) { S.nextPaint = S.t + 0.5; S.paint.deposit(T.x, T.y, 40, 100, S.t); }

    // {{{ monsters
    S.mobs.forEach(function (m) {
      if (m.state === "dead") { if (S.t >= m.respawn) { m.state = "idle"; m.hp = m.max; m.x = m.hx; m.y = m.hy; m.target = null; if (m.route) { m.leg = 1; m.dir = 1; } } return; }
      m.slow = Math.max(0, m.slow - dt);
      var sp = MOB_SPEED * (m.slow > 0 ? 0.5 : 1);
      if (m.state === "idle") {
        // patrols walk their route back and forth
        if (m.route && m.route.length > 1) {
          var p = m.route[m.leg];
          if (move(m, p.x, p.y, MOB_SPEED * 0.45, 1, dt)) {
            if (m.leg + m.dir >= m.route.length || m.leg + m.dir < 0) m.dir = -m.dir;
            m.leg += m.dir;
          }
          // a patrol near a fight blunders in
          var f = S.mobs.find(function (o) { return o.state === "fight" && dist(o, m) < LINK; });
          if (f) { engage(m, f.target); S.c.blunders++; line(m, f, "#e2c16a", true, 1); }
        }
        // anyone of the party in reach and sight is noticed
        S.party.forEach(function (b) {
          if (m.state === "idle" && alive(b) && dist(b, m) < AGGRO + (m.elite ? 2 : 0) && g.sight(m.x, m.y, b.x, b.y)) engage(m, b);
        });
        return;
      }
      // fighting: go for its target and hit it
      if (!m.target || m.target.dead) m.target = T.dead ? S.party.find(alive) : T;
      if (!m.target) return;
      if (move(m, m.target.x, m.target.y, sp, 1.6, dt)) {
        m.target.hp -= (m.elite ? 9 : 4) * dt;
        if (m.target.hp <= 0 && !m.target.dead) { m.target.dead = 1; m.target.hp = 0; S.c.deaths++; }
      }
    });
    // }}}

    var fighting = engaged();
    if (fighting.length && !S.fight) {
      S.fight = true; S.c.fights++;
      S.maw = kraken ? mawSpot(fighting) : null;
    }
    if (!fighting.length && S.fight) {
      S.fight = false; S.maw = null;
      S.party.forEach(function (b) { if (b.dead) { b.dead = 0; b.hp = b.max * 0.5; } b.pull = null; });   // back on their feet: the fight is over
      say("The maw is empty: the whole party moves on.");
    }

    // {{{ the party
    S.party.forEach(function (b, k) {
      if (b.dead) return;
      b.cd = Math.max(0, b.cd - dt); b.blink = Math.max(0, b.blink - dt);
      if (!S.fight) { roam(b, k, dt); return; }
      if (b.role === "tank") return tankTurn(b, fighting, kraken, dt);
      if (b.role === "healer") return healTurn(b, dt);
      if ((b.role === "mage" || b.role === "hunter") && kraken && pullerTurn(b, fighting, dt)) return;
      dpsTurn(b, fighting, kraken, dt);
    });
    // }}}
    // regeneration out of a fight
    if (!S.fight) S.party.forEach(function (b) { if (!b.dead) b.hp = Math.min(b.max, b.hp + 4 * dt); });
  }
  // }}}

  // {{{ roaming: the tank leads by least paint, the rest follow
  function roam(b, k, dt) {
    if (k === 0) {
      // a new goal on arrival, or when 5 seconds brought no 2 yards of progress
      if (!b.since || Math.hypot(b.x - b.since.x, b.y - b.since.y) > 2) b.since = { x: b.x, y: b.y, t: S.t };
      if (!S.goal || Math.hypot(S.goal.x - b.x, S.goal.y - b.y) < 3 || S.t - b.since.t > 5) { S.goal = pickLeast(b); b.since = { x: b.x, y: b.y, t: S.t }; }
      if (S.goal) move(b, S.goal.x, S.goal.y, RUN * 0.8, 2, dt);
      // a pack in sight and in reach: open the fight (the tank's pull)
      var pack = S.mobs.find(function (m) { return m.state === "idle" && !m.route && dist(m, b) < SEE_PACK && g.sight(b.x, b.y, m.x, m.y); });
      if (pack && b.cd <= 0) { engage(pack, b); b.cd = TAUNT_CD; S.c.taunts++; line(b, pack, "#e2c16a", false, 0.8); }
      return;
    }
    var T = tank(), a = Math.PI * (0.6 + k * 0.2) + Math.atan2(T.y - b.y, T.x - b.x);
    move(b, T.x + Math.cos(a) * 6, T.y + Math.sin(a) * 6, RUN, 1.5, dt);
  }
  function pickLeast(b) {
    var best = null, bs = Infinity;
    for (var k = 0; k < 30; k++) {
      var a = Math.random() * 6.283, r = 15 + Math.random() * 60, x = b.x + Math.cos(a) * r, y = b.y + Math.sin(a) * r;
      var i = g.cellAt(x, y);
      if (i < 0 || !g.open[i] || g.wall[i] < 2) continue;
      var sc = S.paint.at(i, false) - 0.5 * Math.hypot(x - map.entrance.x, y - map.entrance.y);
      if (sc < bs) { bs = sc; best = { x: x, y: y }; }
    }
    return best;
  }
  // }}}

  // {{{ the fight
  // The maw: where the damage dealers' ranges overlap best. Here: the
  // monsters' middle pulled toward the party, kept on open ground.
  function mawSpot(ms) {
    var mx = 0, my = 0;
    ms.forEach(function (m) { mx += m.x; my += m.y; });
    mx /= ms.length; my /= ms.length;
    var T = tank(), x = mx + (T.x - mx) * 0.4, y = my + (T.y - my) * 0.4;
    return g.isOpen(x, y) ? { x: x, y: y } : { x: T.x, y: T.y };
  }
  function tankTurn(b, fighting, kraken, dt) {
    // taunt back anything on someone else
    var loose = fighting.find(function (m) { return m.target !== b && dist(m, b) < TAUNT && g.sight(b.x, b.y, m.x, m.y); });
    if (loose && b.cd <= 0) { loose.target = b; b.cd = TAUNT_CD; S.c.taunts++; line(b, loose, "#e2c16a"); b.lean = loose; }
    // reach out: an idle monster in taunt range, while the hold is light
    if (kraken && b.cd <= 0 && threat() <= HOLD_MAX && b.hp > b.max * 0.5) {
      var near = S.mobs.find(function (m) { return m.state === "idle" && dist(m, b) < TAUNT && dist(m, S.maw) < PULL_REACH && g.sight(b.x, b.y, m.x, m.y); });
      if (near) { engage(near, b); b.cd = TAUNT_CD; S.c.taunts++; S.c.reach++; line(b, near, "#e2c16a"); b.lean = near; }
    }
    var tgt = fighting.find(function (m) { return m.target === b; }) || fighting[0];
    if (kraken && S.maw) {
      // hold within HOLD_R of the maw; step to the far side from the newest arrival
      var ax = S.maw.x, ay = S.maw.y;
      if (b.lean && b.lean.state === "fight" && dist(b.lean, S.maw) > MAW_R) {
        var a = Math.atan2(b.lean.y - ay, b.lean.x - ax) + Math.PI;
        ax += Math.cos(a) * HOLD_R; ay += Math.sin(a) * HOLD_R;
      }
      move(b, ax, ay, RUN, 1, dt);
    } else if (tgt) move(b, tgt.x, tgt.y, RUN, 1.5, dt);
    if (tgt && dist(tgt, b) < 3) hit(tgt, ROLE.tank.dps * dt);
  }
  function healTurn(b, dt) {
    var hurt = S.party.filter(function (p) { return !p.dead && p.hp < p.max * 0.8; }).sort(function (x, y) { return x.hp / x.max - y.hp / y.max; })[0];
    var T = tank(), stand = S.maw || T;
    move(b, stand.x - 16, stand.y + 10, RUN, 3, dt);
    if (hurt && dist(hurt, b) < ROLE.healer.range && b.cd <= 0) { hurt.hp = Math.min(hurt.max, hurt.hp + 40); b.cd = 1.5; line(b, hurt, "#9fe0a0", false, 0.4); }
  }
  // A ranged puller: an idle monster within reach of the maw, not too much
  // held already: go in range, hit once and slow it, lead it round to a
  // neighbouring quadrant, blink or disengage when it closes, kite until the
  // tank takes it.
  function pullerTurn(b, fighting, dt) {
    var T = tank(), range = ROLE[b.role].range;
    if (b.pull) {
      var m = b.pull.mob;
      if (m.state !== "fight" || m.target !== b) { b.pull = null; return false; }     // taken, or dead
      if (dist(m, b) < 6 && b.blink <= 0) {
        var away = Math.atan2(b.y - m.y, b.x - m.x), nx = b.x + Math.cos(away) * 15, ny = b.y + Math.sin(away) * 15;
        if (g.isOpen(nx, ny) && g.sight(b.x, b.y, nx, ny)) {
          line(b, { x: nx, y: ny }, "#ffffff", true, 0.6);
          b.x = nx; b.y = ny; b.blink = b.role === "mage" ? 15 : 20;
          if (b.role === "mage") S.c.blinks++; else S.c.disengages++;
          m.slow = Math.max(m.slow, 3); S.c.slows++;
        }
      }
      var d = b.pull.dest;
      if (!b.pull.kite) { if (move(b, d.x, d.y, RUN, 1.5, dt)) b.pull.kite = true; }
      else {
        var ka = Math.atan2(b.y - S.maw.y, b.x - S.maw.x) + 0.35;
        move(b, S.maw.x + Math.cos(ka) * KITE_R, S.maw.y + Math.sin(ka) * KITE_R, RUN, 0.5, dt);
      }
      if (b.cd <= 0 && dist(m, b) < range) { hit(m, 6); b.cd = 1.2; }
      return true;
    }
    if (threat() > HOLD_MAX || T.hp < T.max * 0.5 || !S.maw) return false;
    var cand = S.mobs.find(function (m) { return m.state === "idle" && dist(m, S.maw) < PULL_REACH && !m.route; });
    if (!cand) return false;
    if (dist(cand, b) > range - 2 || !g.sight(b.x, b.y, cand.x, cand.y)) { move(b, cand.x, cand.y, RUN, range - 3, dt); return true; }
    // the one hit and the slow; lead to the far side of a neighbouring quadrant
    engage(cand, b); hit(cand, 4); cand.slow = 5; S.c.pulls++; S.c.slows++;
    line(b, cand, ROLE[b.role].color, true, 0.8);
    var q = Math.floor((Math.atan2(cand.y - S.maw.y, cand.x - S.maw.x) + Math.PI) / (Math.PI / 2));
    var nq = (q + (Math.random() < 0.5 ? 1 : 3)) % 4, da = -Math.PI + (nq + 0.5) * Math.PI / 2;
    var dest = { x: S.maw.x + Math.cos(da) * LEAD_R, y: S.maw.y + Math.sin(da) * LEAD_R };
    if (!g.isOpen(dest.x, dest.y)) dest = { x: S.maw.x, y: S.maw.y };
    b.pull = { mob: cand, dest: dest, kite: false };
    return true;
  }
  function dpsTurn(b, fighting, kraken, dt) {
    var T = tank(), R = ROLE[b.role];
    var tgt = fighting.find(function (m) { return m.target === T; }) || fighting[0];
    if (!tgt) return;
    if (b.role === "melee") {
      var kind = opt["dk-melee"];
      if (kind === "heavy") tgt = fighting.slice().sort(function (x, y) { return y.max - x.max || x.id - y.id; })[0];       // skull, then cross
      if (kind === "control") {
        var off = fighting.find(function (m) { return m.target !== T && m.slow <= 0; });
        if (off) tgt = off;
      }
      b.hop = (b.hop + dt) % 1.4;
      var j = b.hop < 0.2 ? 1.5 : 0;                     // shift about: instant-cast users hop
      move(b, tgt.x + j, tgt.y + j, RUN, 1.8, dt);
      if (dist(tgt, b) < 3) {
        if (kind === "whirlwind") fighting.forEach(function (m) { if (dist(m, b) < 6) hit(m, R.dps * 0.8 * dt); });
        else hit(tgt, R.dps * (kind === "heavy" ? 1.4 : 0.8) * dt);
        if (kind === "control" && tgt.target !== T) tgt.slow = Math.max(tgt.slow, 1);
      }
      return;
    }
    // ranged: stand at range from the maw (or the target) and cast
    var centre = S.maw || tgt, a = Math.atan2(b.y - centre.y, b.x - centre.x);
    move(b, centre.x + Math.cos(a) * (R.range - 6), centre.y + Math.sin(a) * (R.range - 6), RUN, 2, dt);
    if (b.cd > 0) return;
    var inMaw = S.maw ? fighting.filter(function (m) { return dist(m, S.maw) < MAW_R; }) : [];
    var boss = fighting.some(function (m) { return m.elite; });
    if (kraken && inMaw.length >= 2 && (!boss || Math.random() < 0.5)) {
      inMaw.forEach(function (m) { hit(m, 6); }); S.c.aoe++; b.cd = 1.5;
      S.lines.push({ ring: S.maw, r: MAW_R, color: "rgba(127,166,230,0.5)", until: S.t + 0.4 });
    } else if (dist(tgt, b) < R.range + 4) { hit(tgt, 11); b.cd = 1.5; line(b, tgt, R.color, false, 0.3); }
  }
  function hit(m, amount) {
    if (m.state === "dead") return;
    m.hp -= amount;
    if (m.hp <= 0) { m.state = "dead"; m.respawn = S.t + RESPAWN; m.target = null; S.c.kills++; }
  }
  // }}}

  // {{{ drawing
  function draw() {
    var dark = SK.pageColours(root).dark;
    if (!layer || layer.dark !== dark) layer = SK.mapLayer(g, SCALE, dark);
    ctx.drawImage(layer, 0, 0);
    // patrol routes, faint
    ctx.setLineDash([3, 5]); ctx.strokeStyle = "rgba(226,193,106,0.35)"; ctx.lineWidth = 1;
    S.mobs.forEach(function (m) {
      if (!m.route) return;
      ctx.beginPath(); m.route.forEach(function (p, k) { if (k) ctx.lineTo(p.x * SCALE, p.y * SCALE); else ctx.moveTo(p.x * SCALE, p.y * SCALE); }); ctx.stroke();
    });
    ctx.setLineDash([]);
    // the maw and its quadrants
    if (S.maw) {
      var mx = S.maw.x * SCALE, my = S.maw.y * SCALE;
      ctx.strokeStyle = "rgba(127,166,230,0.9)"; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.arc(mx, my, MAW_R * SCALE, 0, 7); ctx.stroke();
      ctx.strokeStyle = "rgba(200,205,212,0.25)"; ctx.lineWidth = 1;
      ctx.beginPath(); ctx.moveTo(mx - 40 * SCALE, my); ctx.lineTo(mx + 40 * SCALE, my); ctx.moveTo(mx, my - 40 * SCALE); ctx.lineTo(mx, my + 40 * SCALE); ctx.stroke();
      ctx.beginPath(); ctx.arc(mx, my, KITE_R * SCALE, 0, 7); ctx.stroke();
    }
    // short-lived lines: taunts, pulls, heals, blinks, area spells
    S.lines.forEach(function (l) {
      ctx.strokeStyle = l.color; ctx.lineWidth = 2;
      if (l.ring) { ctx.fillStyle = l.color; ctx.beginPath(); ctx.arc(l.ring.x * SCALE, l.ring.y * SCALE, l.r * SCALE, 0, 7); ctx.fill(); return; }
      if (l.dash) ctx.setLineDash([4, 4]);
      ctx.beginPath(); ctx.moveTo(l.x0 * SCALE, l.y0 * SCALE); ctx.lineTo(l.x1 * SCALE, l.y1 * SCALE); ctx.stroke();
      ctx.setLineDash([]);
    });
    // monsters
    S.mobs.forEach(function (m) {
      if (m.state === "dead") return;
      var r = m.elite ? 5 : 3.5;
      ctx.fillStyle = m.state === "fight" ? "#ff5a4a" : "#b8453c";
      ctx.beginPath(); ctx.arc(m.x * SCALE, m.y * SCALE, r, 0, 7); ctx.fill();
      if (m.route) { ctx.strokeStyle = "#e2c16a"; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.arc(m.x * SCALE, m.y * SCALE, r + 3, 0, 7); ctx.stroke(); }
      if (m.slow > 0) { ctx.strokeStyle = "rgba(170,210,255,0.9)"; ctx.lineWidth = 1; ctx.beginPath(); ctx.arc(m.x * SCALE, m.y * SCALE, r + 5, 0, 7); ctx.stroke(); }
    });
    // the party
    ctx.font = "bold 9px system-ui, sans-serif"; ctx.textAlign = "center"; ctx.textBaseline = "middle";
    S.party.forEach(function (b) {
      var R = ROLE[b.role];
      ctx.globalAlpha = b.dead ? 0.35 : 1;
      ctx.fillStyle = R.color; ctx.beginPath(); ctx.arc(b.x * SCALE, b.y * SCALE, 7, 0, 7); ctx.fill();
      ctx.fillStyle = "#12161d"; ctx.fillText(R.letter, b.x * SCALE, b.y * SCALE + 0.5);
      ctx.globalAlpha = 1;
    });
    hud();
  }
  var lastHud = -1;
  function hud() {
    var s = Math.floor(S.t * 2);
    if (s === lastHud) return;
    lastHud = s;
    var c = S.c;
    counts.innerHTML = [["Kills", c.kills], ["Fights", c.fights], ["Taunts", c.taunts], ["…reaching out", c.reach], ["Pulls", c.pulls],
      ["Slows", c.slows], ["Blinks", c.blinks], ["Disengages", c.disengages], ["Area spells", c.aoe], ["Patrols blundered in", c.blunders], ["Deaths", c.deaths]]
      .map(function (p) { return "<span>" + p[0] + " <b>" + p[1] + "</b></span>"; }).join("");
    if (S.fight) say(opt["dk-kraken"] ? "The kraken: the tank holds the maw (blue ring) and reaches out; the mage and hunter pull, slow and kite outliers round it." : "An ordinary fight: everyone on the tank's target, nobody pulling.");
  }
  // }}}

  reset();
  var reduced = SK.runLoop(root, DT, step, draw, api);
  if (reduced) { var pb = document.getElementById("dk-play"); if (pb) pb.textContent = "Play"; say("Paused because your system asks for reduced motion: press Play to start."); }
})();
