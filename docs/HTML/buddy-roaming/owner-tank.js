// owner-tank.js - the interactive "owner as the tank" widget of the buddy
// roaming gallery (issue 617e5). A drawn simulation of the intended
// behaviour, not the game's combat: the owner's dot eases toward the
// cursor, the four buddies follow, and when 3 or more monsters stand where
// area spells reach them all the buddies run the "kraken" round the owner:
// the damage dealers pick the maw (where their ranges overlap best), pull
// outliers with one hit and a slow, lead them to a neighbouring quadrant,
// blink or disengage to keep their distance, and kite them round the maw
// until the owner takes them by coming near. Pullers only pull while the
// enemies' total threat stays under what they have learned the owner can
// take (the danger meter). Units are yards; one tick is 1/30 of a second.
(function () {
  "use strict";
  var cv = document.getElementById("ot-canvas");
  if (!cv) return;
  var ctx = cv.getContext("2d");

  // {{{ the arena and its numbers
  var AW = 170, AH = 110;                    // arena, yards
  var DT = 1 / 30;
  // monsters are faster than you and the buddies (the owner, 2026-09-27:
  // "the enemies should move faster than the player, so they can always
  // hit"); 6.2 before. Slows and blinks save a kiter, not its legs.
  // Melee as the server does it (AzerothCore, read 2026-09-28; the owner:
  // "we should be trying to build the datamodel to match the game"). All
  // distances centre to centre, yards.
  //   reach      every body's combat reach; players and ordinary monsters
  //              1.5 (DEFAULT_COMBAT_REACH), elites here 2.0
  //   chase      a chasing monster stops at the sum of the two reaches
  //              (GetChaseRange), and starts again only when the target is
  //              more than CONTACT (0.5) beyond that, checked every 0.4 s
  //              (ChaseMovementGenerator: maxTarget, i_recheckDistance)
  //   melee      a swing lands if the target is within the two reaches plus
  //              4/3, never less than 5 (Unit::GetMeleeRange), plus the
  //              leeway of 2.66 when both are running and one is a player
  //              (GetLeewayBonusRange): the "thin strip" the owner asked for
  //   swing      melee lands once per attack time (2 s here), not as a drain
  var REACH = 1.5, REACH_ELITE = 2.0, CONTACT = 0.5, RECHECK = 0.4;
  var MELEE_MIN = 5.0, LEEWAY = 2.66, SWING = 2.0;
  var RUN = 8.4, MOB_SPEED = 9.6;            // yards a second (both 20% up, 2026-09-28: the owner, "a little faster [...] Just for the scenes with the player dot"; monsters still outpace players)
  var AGGRO = 9, AGGRO_ELITE = 11;           // an idle monster notices a party member this near
  var TAKE = 8;                              // the owner takes a monster this near (the abstract taunt)
  var MAW_R = 9, AOE_MIN = 2;                // area spells need this many in the maw
  var CLUSTER_R = 12, CLUSTER_N = 3;         // the owner's rule: 3+ monsters where area spells reach them all
  var PULL_REACH = 50, PULL_RANGE = { mage: 30, hunter: 35 };
  var KITE_R = 17, LEAD_R = 20;
  var RESPAWN = 30, LEASH = 60;
  var SPAWNS = [                             // x, y, elite, pack (0 = alone)
    [118, 42, 0, 1], [124, 48, 0, 1], [114, 50, 0, 1], [122, 38, 0, 1],
    [142, 22, 0, 0], [96, 66, 0, 0],
    [58, 88, 0, 2], [64, 92, 1, 2], [54, 94, 0, 2],
    [34, 28, 0, 0], [150, 92, 0, 0], [84, 18, 0, 0]
  ];
  var ROLE = {
    mage:   { label: "Mage",   letter: "M", color: "#7fa6e6", range: 30 },
    hunter: { label: "Hunter", letter: "H", color: "#9ccc65", range: 35 },
    healer: { label: "Priest", letter: "P", color: "#f0e2a0", range: 40 },
    melee:  { label: "Melee",  letter: "F", color: "#e07a62", range: 3 }
  };
  var MELEE_KIND = {
    whirlwind: "spins blades through everything near it",
    heavy: "kills the skull, then the cross, with heavy blows",
    control: "slows and stuns the monsters not yet on the owner"
  };
  // }}}

  var S;                                     // the whole state, rebuilt by reset()
  var pointer = null;                        // where the cursor is, in yards (null: not over the arena)
  var running = true, visible = true, meleeKind = "whirlwind";

  // {{{ reset
  function reset() {
    S = {
      t: 0,
      owner: { x: 18, y: 72, hp: 100, max: 100, isOwner: true },
      buddies: ["mage", "hunter", "healer", "melee"].map(function (r, i) {
        var a = Math.PI * (0.65 + i * 0.23);          // the same loose fan behind the owner they keep when following
        return { role: r, x: 18 + Math.cos(a) * 6, y: 72 + Math.sin(a) * 6, hp: 100, max: 100, cd: 0, pull: null, cast: 0, hop: 0 };
      }),
      mobs: SPAWNS.map(function (s, i) {
        return { id: i, sx: s[0], sy: s[1], x: s[0], y: s[1], elite: !!s[2], pack: s[3],
                 max: s[2] ? 260 : 90, hp: s[2] ? 260 : 90, state: "idle", holder: null, target: null,
                 slow: 0, respawn: 0, pulled: null, flash: 0 };
      }),
      kraken: false, maw: null,
      danger: 2, calm: 0,                      // what the buddies believe the owner can take
      lines: [],                               // short-lived drawn lines: tentacles, tags
      log: [], counts: { taken: 0, pulls: 0, slows: 0, blinks: 0, disengages: 0, aoe: 0, kills: 0, krakens: 0 }
    };
    pointer = null; lastLearn = 0; lastHud = -1;
    say("A new day in the arena. Move the cursor: the owner follows it.");
    hud();
  }
  // }}}

  // {{{ small helpers
  function dist(a, b) { return Math.hypot(a.x - b.x, a.y - b.y); }
  function clampArena(p) { p.x = Math.max(2, Math.min(AW - 2, p.x)); p.y = Math.max(2, Math.min(AH - 2, p.y)); }
  function moveToward(e, tx, ty, speed, stop) {
    var dx = tx - e.x, dy = ty - e.y, d = Math.hypot(dx, dy);
    if (d <= (stop || 0.3)) return true;
    var step = Math.min(speed * DT, d - (stop || 0));
    e.x += dx / d * step; e.y += dy / d * step; clampArena(e);
    return false;
  }
  function party() { return [S.owner].concat(S.buddies); }
  function alive(m) { return m.state !== "dead"; }
  function fighting() { return S.mobs.filter(function (m) { return m.state === "fight"; }); }
  function say(text) { S.log.unshift(text); if (S.log.length > 4) S.log.pop(); }
  function line(a, b, color, life) { S.lines.push({ ax: a.x, ay: a.y, bx: b.x, by: b.y, color: color, life: life || 0.6 }); }
  function threatOf(m) { return m.elite ? 3 : 1; }
  function packOf(m) { return m.pack ? S.mobs.filter(function (o) { return o.pack === m.pack && o.state === "idle"; }) : [m]; }
  function buddy(role) { for (var i = 0; i < S.buddies.length; i++) if (S.buddies[i].role === role) return S.buddies[i]; }
  // }}}

  // {{{ engage
  // A monster (and its idle pack-mates) turns on `who`.
  function engage(m, who) {
    packOf(m).concat([m]).forEach(function (o) {
      if (o.state !== "idle") return;
      o.state = "fight"; o.target = who;
    });
  }
  // }}}

  // {{{ the kraken's parts
  // Is there a cluster the owner's rule allows: 3+ living monsters, one of
  // them fighting, all within area-spell reach of their middle?
  function clusterNow() {
    var live = S.mobs.filter(alive);
    for (var i = 0; i < live.length; i++) {
      if (live[i].state !== "fight") continue;
      var near = live.filter(function (o) { return dist(o, live[i]) <= CLUSTER_R; });
      if (near.length >= CLUSTER_N) return true;
    }
    return false;
  }
  // The maw: the damage dealers' choice. Start from the middle of what the
  // owner holds (or of the fight), then lean toward where the two ranged
  // buddies stand, so every one of them reaches all of it and can switch
  // targets freely; it moves smoothly, never jumps.
  function placeMaw() {
    var held = fighting().filter(function (m) { return m.holder === S.owner; });
    var set = held.length ? held : fighting();
    if (!set.length) return;
    var cx = 0, cy = 0;
    set.forEach(function (m) { cx += m.x; cy += m.y; });
    cx /= set.length; cy /= set.length;
    var mg = buddy("mage"), hn = buddy("hunter");
    var rx = (mg.x + hn.x) / 2 - cx, ry = (mg.y + hn.y) / 2 - cy, rl = Math.hypot(rx, ry);
    var lean = Math.min(5, rl * 0.25);
    var tx = cx + (rl ? rx / rl * lean : 0), ty = cy + (rl ? ry / rl * lean : 0);
    if (!S.maw) S.maw = { x: tx, y: ty };
    S.maw.x += (tx - S.maw.x) * Math.min(1, 1.5 * DT);
    S.maw.y += (ty - S.maw.y) * Math.min(1, 1.5 * DT);
  }
  function inMaw(m) { return S.maw && m.state === "fight" && dist(m, S.maw) <= MAW_R; }
  function enemyThreat() { return fighting().reduce(function (a, m) { return a + threatOf(m); }, 0); }
  // Hand an outlier to a free puller, if the danger allows the whole pack.
  function assignPulls() {
    if (!S.kraken || !S.maw) return;
    ["hunter", "mage"].forEach(function (role) {
      var b = buddy(role);
      if (b.pull) return;
      var best = null, bd = 1e9;
      S.mobs.forEach(function (m) {
        if (m.state !== "idle" || m.pulled) return;
        var d = dist(m, S.maw);
        if (d < 16 || d > PULL_REACH) return;
        if (d < bd) { bd = d; best = m; }
      });
      if (!best) return;
      var size = packOf(best).reduce(function (a, o) { return a + threatOf(o); }, 0);
      if (enemyThreat() + size > S.danger) return;        // the owner has enough on them
      best.pulled = b;
      b.pull = { mob: best, phase: "approach", dest: null, time: 0 };
    });
  }
  // }}}

  // {{{ update
  function update() {
    S.t += DT;
    var O = S.owner;

    // the owner eases toward the cursor (not onto it: it stops a yard short)
    if (pointer && O.hp > 0) moveToward(O, pointer.x, pointer.y, RUN, 1.2);

    // monsters notice what comes near
    S.mobs.forEach(function (m) {
      if (m.state === "dead") {
        m.respawn -= DT;
        if (m.respawn <= 0) { m.state = "idle"; m.hp = m.max; m.x = m.sx; m.y = m.sy; m.holder = null; m.target = null; m.pulled = null; }
        return;
      }
      if (m.state === "idle") {
        var reach = m.elite ? AGGRO_ELITE : AGGRO;
        party().forEach(function (p) { if (m.state === "idle" && dist(m, p) <= reach) engage(m, p); });
      }
    });

    // the owner takes a monster by coming near it (the abstract taunt)
    fighting().forEach(function (m) {
      if (m.holder !== O && dist(m, O) <= TAKE) {
        m.holder = O; m.target = O; S.counts.taken++;
        line(O, m, "#d7b85a", 0.8);
        if (m.pulled) { m.pulled.pull = null; m.pulled = null; }
      }
    });

    // kraken or an ordinary fight
    var hadFight = S.hadFight;
    S.hadFight = fighting().length > 0;
    if (!fighting().length) {
      if (S.kraken) { say("The pack is down; the party moves on."); }
      S.kraken = false; S.maw = null;
    } else if (!S.kraken && clusterNow()) {
      S.kraken = true; S.counts.krakens++;
      say("Three or more together: the kraken forms round the owner.");
    }
    if (S.kraken) { placeMaw(); assignPulls(); }
    else if (!hadFight && S.hadFight) say("A lone fight: no maw, no pulls.");

    // monsters: chase whoever they are on, hit when close, leash home
    fighting().forEach(function (m) {
      var tgt = m.holder || m.target;
      if (!tgt) return;
      var sp = MOB_SPEED * (m.slow > 0 ? 0.5 : 1);
      if (m.slow > 0) m.slow -= DT;
      // the chase and the swing, as the server does them (constants above).
      // The owner's rule this matches (2026-09-28): "a pathing range where
      // they path to be close to, then a thin strip beyond that where they
      // can attack within. They shouldn't move after getting in range again
      // until the tank pulls beyond their pathing radius".
      var reach = m.elite ? REACH_ELITE : REACH;
      var chaseR = reach + REACH;                         // the two combat reaches
      var d = dist(m, tgt);
      m.recheck = (m.recheck || 0) - DT;
      if (!m.chasing && m.recheck <= 0) {                 // the 0.4 s look: has the target got away?
        m.recheck = RECHECK;
        if (d > chaseR + CONTACT) m.chasing = true;
      }
      if (m.chasing && moveToward(m, tgt.x, tgt.y, sp, chaseR)) m.chasing = false;
      // the target is running if it moved since the last tick (the owner
      // and buddies are players to the server, so the leeway applies)
      var tgtRunning = tgt.lx !== undefined && Math.hypot(tgt.x - tgt.lx, tgt.y - tgt.ly) > 0.05;
      var melee = Math.max(reach + REACH + 4 / 3, MELEE_MIN) + (m.chasing && tgtRunning ? LEEWAY : 0);
      m.swing = (m.swing || 0) - DT;
      if (m.swing <= 0 && dist(m, tgt) <= melee) {
        m.swing = SWING;
        tgt.hp = Math.max(0, tgt.hp - (m.elite ? 6 : 2.6) * SWING);   // the same damage as before, landed in blows
      }
      if (Math.hypot(m.x - m.sx, m.y - m.sy) > LEASH && m.holder !== O && !m.pulled) {
        m.state = "idle"; m.hp = m.max; m.x = m.sx; m.y = m.sy; m.target = null;
      }
    });

    party().forEach(function (u) { u.lx = u.x; u.ly = u.y; });   // where each stood this tick: next tick, "has it moved?"

    // the owner goes down: everything resets, the owner stands up again
    if (O.hp <= 0) {
      say("The owner went down: the monsters reset. The buddies trust the owner a little less.");
      S.danger = Math.max(1.5, S.danger - 1);
      S.mobs.forEach(function (m) { if (m.state === "fight") { m.state = "idle"; m.hp = m.max; m.x = m.sx; m.y = m.sy; m.holder = null; m.target = null; m.pulled = null; } });
      S.buddies.forEach(function (b) { b.pull = null; });
      O.hp = O.max; S.kraken = false; S.maw = null;
    }

    S.buddies.forEach(stepBuddy);

    // deaths
    S.mobs.forEach(function (m) {
      if (m.state === "fight" && m.hp <= 0) {
        m.state = "dead"; m.respawn = RESPAWN; m.holder = null; m.target = null; S.counts.kills++;
        if (m.pulled) { m.pulled.pull = null; m.pulled = null; }
      }
    });

    // regeneration out of combat; a buddy never drops below a tenth
    var inFight = fighting().length > 0;
    party().forEach(function (p) {
      if (!inFight) p.hp = Math.min(p.max, p.hp + 8 * DT);
      if (!p.isOwner) p.hp = Math.max(p.max * 0.1, p.hp);
    });

    learnDanger();
    S.lines = S.lines.filter(function (l) { l.life -= DT; return l.life > 0; });
  }
  // }}}

  // {{{ learnDanger
  // Every second: the buddies start deferential (the owner can take 2), and
  // raise their belief while the owner holds at least that much and stays
  // healthy; they drop it when the owner's health runs low.
  var lastLearn = 0;
  function learnDanger() {
    if (S.t - lastLearn < 1) return;
    lastLearn = S.t;
    var O = S.owner;
    var held = fighting().filter(function (m) { return m.holder === O; }).reduce(function (a, m) { return a + threatOf(m); }, 0);
    if (held >= Math.floor(S.danger) && O.hp / O.max > 0.6) {
      if (++S.calm >= 4) { S.danger = Math.min(9, S.danger + 0.5); S.calm = 0; say("The owner is holding up: the buddies will pull a little more."); }
    } else S.calm = 0;
    if (O.hp / O.max < 0.35 && S.danger > 1.5) { S.danger = Math.max(1.5, S.danger - 1); say("The owner is struggling: no more pulls for now."); }
  }
  // }}}

  // {{{ stepBuddy
  function stepBuddy(b, i) {
    var O = S.owner;
    var fights = fighting();
    if (b.cd > 0) b.cd -= DT;
    if (b.cast > 0) b.cast -= DT;

    // out of combat: follow the owner in a loose fan behind
    if (!fights.length) {
      var a = Math.PI * (0.65 + i * 0.23);
      moveToward(b, O.x + Math.cos(a) * 6, O.y + Math.sin(a) * 6, RUN, 0.4);
      return;
    }

    if (b.pull) { stepPull(b); return; }

    if (b.role === "healer") {
      var low = party().filter(function (p) { return dist(p, b) <= 40; })
        .sort(function (p, q) { return p.hp / p.max - q.hp / q.max; })[0];
      if (low && low.hp < low.max) { low.hp = Math.min(low.max, low.hp + 9 * DT); if (Math.random() < 0.03) line(b, low, "#f0e2a0", 0.4); }
      var hx = (S.maw || O).x - 16, hy = (S.maw || O).y + 10;
      moveToward(b, hx, hy, RUN, 3);
      return;
    }

    if (b.role === "melee") { stepMelee(b); return; }

    // mage and hunter: area spells on a full maw, otherwise the priority target
    var centre = S.maw || O;
    var ang = Math.atan2(b.y - centre.y, b.x - centre.x) + (b.role === "mage" ? 0.25 : -0.25) * DT;
    var standX = centre.x + Math.cos(ang) * 22, standY = centre.y + Math.sin(ang) * 22;
    if (b.cast <= 0) moveToward(b, standX, standY, RUN, 1);   // casters stand still to cast
    var inside = fights.filter(inMaw);
    if (S.kraken && inside.length >= AOE_MIN) {
      inside.forEach(function (m) { m.hp -= (b.role === "mage" ? 3.6 : 2.6) * DT; });
      if (Math.random() < 0.02) { S.counts.aoe++; b.cast = b.role === "mage" ? 1.2 : 0; }
    } else {
      var tgt = priorityTarget(b);
      if (tgt && dist(b, tgt) <= ROLE[b.role].range) {
        tgt.hp -= 7 * DT;
        if (tgt.target === null) tgt.target = b;
        if (b.role === "mage" && b.cast <= 0 && Math.random() < 0.02) b.cast = 2.5;   // frostbolt: stands to cast
      } else if (tgt) moveToward(b, tgt.x, tgt.y, RUN, ROLE[b.role].range - 2);
    }
  }
  // }}}

  // {{{ priorityTarget
  // Skull then cross: the hardest monster the owner holds first (an elite),
  // then the next; without marks, the one nearest the owner.
  function marks() {
    var held = fighting().filter(function (m) { return m.holder === S.owner; })
      .sort(function (p, q) { return q.max - p.max || q.hp - p.hp; });
    return { skull: held[0] || null, cross: held[1] || null };
  }
  function priorityTarget() {
    var mk = marks();
    if (mk.skull) return mk.skull;
    var O = S.owner;
    return fighting().sort(function (p, q) { return dist(p, O) - dist(q, O); })[0] || null;
  }
  // }}}

  // {{{ stepMelee
  function stepMelee(b) {
    var fights = fighting();
    b.hop += DT;
    var jitter = Math.sin(b.hop * 5) * 0.8;          // instant-cast fighters shift about
    if (meleeKind === "whirlwind") {
      var c = S.maw || priorityTarget() || S.owner;
      moveToward(b, c.x + jitter, c.y + 2, RUN, 1);
      fights.forEach(function (m) { if (dist(m, b) <= 6) m.hp -= 3.2 * DT; });
    } else if (meleeKind === "heavy") {
      var t = priorityTarget();
      if (t) { if (moveToward(b, t.x + jitter, t.y + 1.5, RUN, 1.5)) t.hp -= 11 * DT; }
    } else {
      var loose = fights.filter(function (m) { return m.holder !== S.owner; })
        .sort(function (p, q) { return dist(p, b) - dist(q, b); })[0];
      var tc = loose || priorityTarget();
      if (tc && moveToward(b, tc.x + jitter, tc.y + 1.5, RUN, 1.5)) {
        tc.hp -= 4 * DT;
        if (loose && tc.slow <= 0) { tc.slow = 4; S.counts.slows++; }
      }
    }
  }
  // }}}

  // {{{ stepPull
  // approach (circling the maw, instants on the move) -> tag (one hit and a
  // slow) -> lead (to the far side of a neighbouring quadrant, never the
  // opposite one) -> kite (round the maw) until the owner takes it.
  function stepPull(b) {
    var p = b.pull, m = p.mob, M = S.maw;
    p.time += DT;
    if (!M || m.state === "dead" || m.holder === S.owner || p.time > 25) {
      if (m.pulled === b) m.pulled = null;
      b.pull = null; return;
    }
    var range = PULL_RANGE[b.role];
    if (p.phase === "approach") {
      var a = Math.atan2(b.y - M.y, b.x - M.x), am = Math.atan2(m.y - M.y, m.x - M.x);
      var da = Math.atan2(Math.sin(am - a), Math.cos(am - a));
      var step = Math.max(-0.9 * DT, Math.min(0.9 * DT, da));
      var r = Math.min(dist(b, M) + RUN * DT, Math.max(KITE_R, dist(m, M) - range + 4));
      if (Math.abs(da) > 0.25) moveToward(b, M.x + Math.cos(a + step) * r, M.y + Math.sin(a + step) * r, RUN, 0.2);
      else moveToward(b, m.x, m.y, RUN, range - 2);
      if (m.state === "fight" && m.target !== b) { b.pull = null; m.pulled = null; return; }   // it woke on someone else
      if (dist(b, m) <= range) {
        m.hp -= m.max * 0.05;                         // one hit: as little threat as possible
        m.slow = 6; S.counts.slows++; S.counts.pulls++;
        engage(m, b);
        packOf(m).forEach(function (o) { o.target = b; });
        line(b, m, "#9fd0ff", 0.7);
        var q = Math.floor(((Math.atan2(b.y - M.y, b.x - M.x) + Math.PI * 2) % (Math.PI * 2)) / (Math.PI / 2));
        var q2 = (q + (Math.random() < 0.5 ? 1 : 3)) % 4;   // a neighbouring quadrant, never the opposite (q + 2)
        var far = q2 * Math.PI / 2 + (q2 === (q + 1) % 4 ? Math.PI / 2 * 0.8 : Math.PI / 2 * 0.2);
        p.dest = { x: M.x + Math.cos(far) * LEAD_R, y: M.y + Math.sin(far) * LEAD_R };
        p.phase = "lead";
        say(ROLE[b.role].label + " tags a monster and leads it in (" + ["east", "south", "west", "north"][q2] + " quadrant).");
      }
      return;
    }
    // lead, then kite round the maw; make distance when it closes in
    if (dist(m, b) < 4 && b.cd <= 0) {
      var ax = b.x - m.x, ay = b.y - m.y, al = Math.hypot(ax, ay) || 1;
      b.x += ax / al * 12; b.y += ay / al * 12; clampArena(b);
      b.cd = b.role === "mage" ? 15 : 10;
      if (b.role === "mage") S.counts.blinks++; else S.counts.disengages++;
      say(ROLE[b.role].label + (b.role === "mage" ? " blinks away." : " disengages."));
    }
    if (p.phase === "lead") {
      if (moveToward(b, p.dest.x, p.dest.y, RUN, 1)) p.phase = "kite";
    } else {
      var ka = Math.atan2(b.y - M.y, b.x - M.x) + 0.35;
      moveToward(b, M.x + Math.cos(ka) * KITE_R, M.y + Math.sin(ka) * KITE_R, RUN, 0.5);
    }
    if (Math.random() < 0.02 && m.slow <= 0) { m.slow = 5; S.counts.slows++; line(b, m, "#9fd0ff", 0.5); }
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
  function dot(e, r, fill, stroke) {
    ctx.beginPath(); ctx.arc(X(e.x), X(e.y), X(r), 0, Math.PI * 2);
    ctx.fillStyle = fill; ctx.fill();
    if (stroke) { ctx.lineWidth = Math.max(1, X(0.35)); ctx.strokeStyle = stroke; ctx.stroke(); }
  }
  function ring(x, y, r, color, dash) {
    ctx.beginPath(); ctx.setLineDash(dash ? [X(1.2), X(1)] : []);
    ctx.arc(X(x), X(y), X(r), 0, Math.PI * 2); ctx.strokeStyle = color; ctx.lineWidth = Math.max(1, X(0.3)); ctx.stroke();
    ctx.setLineDash([]);
  }
  function draw() {
    ctx.fillStyle = "#12161d"; ctx.fillRect(0, 0, cv.width, cv.height);
    ctx.fillStyle = "#1c2430"; ctx.fillRect(X(1), X(1), X(AW - 2), X(AH - 2));
    var M = S.maw;
    if (S.kraken && M) {
      ctx.strokeStyle = "rgba(215,184,90,0.18)"; ctx.lineWidth = 1;
      for (var q = 0; q < 4; q++) {                 // the quadrants, seen from the maw
        var a = q * Math.PI / 2 + Math.PI / 4;
        ctx.beginPath(); ctx.moveTo(X(M.x), X(M.y)); ctx.lineTo(X(M.x + Math.cos(a) * 40), X(M.y + Math.sin(a) * 40)); ctx.stroke();
      }
      ctx.fillStyle = "rgba(215,184,90," + (0.10 + 0.05 * Math.sin(S.t * 6)) + ")";
      ctx.beginPath(); ctx.arc(X(M.x), X(M.y), X(MAW_R), 0, Math.PI * 2); ctx.fill();
      ring(M.x, M.y, MAW_R, "#d7b85a", true);
      ring(M.x, M.y, KITE_R, "rgba(159,208,255,0.25)", true);
      var O = S.owner;
      if (dist(O, M) > 6) {                         // a hint: drag them to the maw
        ctx.strokeStyle = "rgba(255,255,255,0.35)"; ctx.setLineDash([X(0.8), X(1.2)]);
        ctx.beginPath(); ctx.moveTo(X(O.x), X(O.y)); ctx.lineTo(X(M.x), X(M.y)); ctx.stroke(); ctx.setLineDash([]);
      }
    }
    S.lines.forEach(function (l) {
      ctx.strokeStyle = l.color; ctx.globalAlpha = Math.min(1, l.life * 2); ctx.lineWidth = Math.max(1.5, X(0.45));
      ctx.beginPath(); ctx.moveTo(X(l.ax), X(l.ay)); ctx.lineTo(X(l.bx), X(l.by)); ctx.stroke(); ctx.globalAlpha = 1;
    });
    var mk = marks();
    S.mobs.forEach(function (m) {
      if (m.state === "dead") { ctx.fillStyle = "#3a4250"; ctx.fillRect(X(m.x - 0.6), X(m.y - 0.6), X(1.2), X(1.2)); return; }
      var r = m.elite ? 2.2 : 1.5;
      dot(m, r, m.state === "fight" ? "#d0524f" : "#8a3d3f", m.holder === S.owner ? "#d7b85a" : null);
      if (m.slow > 0) ring(m.x, m.y, r + 1, "#9fd0ff");
      if (m.state === "fight") {                    // health
        ctx.fillStyle = "#2b313b"; ctx.fillRect(X(m.x - 2), X(m.y - r - 1.6), X(4), X(0.5));
        ctx.fillStyle = "#e7eaef"; ctx.fillRect(X(m.x - 2), X(m.y - r - 1.6), X(4 * Math.max(0, m.hp) / m.max), X(0.5));
      }
      if (meleeKind === "heavy" && (m === mk.skull || m === mk.cross)) {
        ctx.fillStyle = "#ffffff"; ctx.font = Math.round(X(2.2)) + "px sans-serif"; ctx.textAlign = "center";
        ctx.fillText(m === mk.skull ? "☠" : "✕", X(m.x), X(m.y - r - 2.2));
      }
    });
    // a buddy: its colour, with its initial inside (the key under the
    // arena names them); names beside the dots overlapped while they walked
    // together behind the owner
    S.buddies.forEach(function (b) {
      dot(b, 1.8, ROLE[b.role].color, b.pull ? "#9fd0ff" : "#12161d");
      ctx.fillStyle = "#12161d"; ctx.font = "bold " + Math.round(X(2.1)) + "px sans-serif";
      ctx.textAlign = "center"; ctx.textBaseline = "middle";
      ctx.fillText(ROLE[b.role].letter, X(b.x), X(b.y + 0.1));
      ctx.textBaseline = "alphabetic";
    });
    dot(S.owner, 1.8, "#ffffff", "#d7b85a");
    ctx.fillStyle = "#ffffff"; ctx.font = Math.round(X(1.9)) + "px sans-serif"; ctx.textAlign = "center";
    ctx.fillText("You", X(S.owner.x), X(S.owner.y + 4));
    if (pointer) {                                  // where the owner is heading
      ctx.strokeStyle = "rgba(255,255,255,0.5)"; ctx.lineWidth = 1;
      ctx.beginPath(); ctx.moveTo(X(pointer.x - 1), X(pointer.y)); ctx.lineTo(X(pointer.x + 1), X(pointer.y));
      ctx.moveTo(X(pointer.x), X(pointer.y - 1)); ctx.lineTo(X(pointer.x), X(pointer.y + 1)); ctx.stroke();
    }
  }
  // }}}

  // {{{ the readout beside the arena
  var el = {
    danger: document.getElementById("ot-danger"), dangerN: document.getElementById("ot-danger-n"),
    threat: document.getElementById("ot-threat"), threatN: document.getElementById("ot-threat-n"),
    mode: document.getElementById("ot-mode"), log: document.getElementById("ot-log"),
    counts: document.getElementById("ot-counts"), health: document.getElementById("ot-health"),
    healthN: document.getElementById("ot-health-n"), melee: document.getElementById("ot-melee-note")
  };
  var lastHud = -1;
  function hud() {
    if (!el.danger) return;
    var th = enemyThreat();
    el.danger.style.width = Math.min(100, S.danger / 9 * 100) + "%";
    el.dangerN.textContent = S.danger.toFixed(1);
    el.threat.style.width = Math.min(100, th / 9 * 100) + "%";
    el.threat.dataset.over = th > S.danger ? "yes" : "no";
    el.threatN.textContent = th.toFixed(0);
    el.health.style.width = Math.max(0, S.owner.hp) + "%";
    el.healthN.textContent = Math.round(Math.max(0, S.owner.hp)) + "%";
    el.mode.textContent = !fighting().length ? "Out of combat" : S.kraken ? "Kraken: pulling toward the maw" : "Ordinary fight";
    el.mode.dataset.mode = !fighting().length ? "rest" : S.kraken ? "kraken" : "plain";
    el.log.innerHTML = S.log.map(function (s) { return "<li>" + s + "</li>"; }).join("");
    var c = S.counts;
    el.counts.textContent = "Taken " + c.taken + " · pulls " + c.pulls + " · slows " + c.slows +
      " · blinks " + c.blinks + " · disengages " + c.disengages + " · area spells " + c.aoe + " · kills " + c.kills;
    el.melee.textContent = "The melee buddy " + MELEE_KIND[meleeKind] + ".";
  }
  // }}}

  // {{{ the loop: fixed steps, drawn each frame; stops when hidden
  var acc = 0, last = 0;
  function frame(now) {
    if (!visible) { last = 0; return; }
    requestAnimationFrame(frame);
    if (!last) last = now;
    acc += Math.min(0.25, (now - last) / 1000); last = now;
    if (running) while (acc >= DT) { update(); acc -= DT; } else acc = 0;
    draw();
    if (S.t - lastHud > 0.2 || !running) { hud(); lastHud = S.t; }
  }
  // }}}

  // {{{ input
  function toWorld(ev) {
    var r = cv.getBoundingClientRect();
    return { x: (ev.clientX - r.left) / r.width * AW, y: (ev.clientY - r.top) / r.height * AH };
  }
  cv.addEventListener("pointermove", function (ev) { pointer = toWorld(ev); });
  cv.addEventListener("pointerdown", function (ev) { pointer = toWorld(ev); });
  cv.addEventListener("pointerleave", function () { pointer = null; });
  var play = document.getElementById("ot-play");
  function setRunning(on) { running = on; if (play) { play.textContent = on ? "Pause" : "Play"; play.setAttribute("aria-pressed", on ? "false" : "true"); } }
  if (play) play.addEventListener("click", function () { setRunning(!running); });
  var rst = document.getElementById("ot-reset");
  if (rst) rst.addEventListener("click", function () { reset(); draw(); });
  document.querySelectorAll('input[name="ot-melee"]').forEach(function (r) {
    r.addEventListener("change", function () { if (r.checked) { meleeKind = r.value; hud(); } });
  });
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
