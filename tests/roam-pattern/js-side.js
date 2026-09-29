// js-side.js - the JavaScript half of the roaming-pattern check
// (scripts/test-roam-pattern). Loads docs/HTML/buddy-roaming/roam-pattern.js
// under gjs, makes the seeded situations, and prints each with the
// JavaScript implementation's answer, one line each, for the Lua half
// (lua-side.lua) to answer again and compare. Usage: gjs js-side.js DIR
const GLib = imports.gi.GLib;
const DIR = ARGV[0] || "/mnt/mtwo/games/azeroth-core/wow-chat-2026";
const src = new TextDecoder().decode(GLib.file_get_contents(DIR + "/docs/HTML/buddy-roaming/roam-pattern.js")[1]);
(new Function(src))();
const RP = globalThis.RoamPattern;
const out = [];
const f = x => (Math.abs(x) < 1e-12 ? 0 : x).toFixed(9);

// {{{ the dungeon: its map, then its grid
const map = RP.maps.dungeon;
for (const r of map.rects) out.push(`rect ${r.x0} ${r.y0} ${r.x1} ${r.y1}`);
for (const k of map.rocks) out.push(`rock ${k.x} ${k.y} ${k.r}`);
const grid = new RP.Grid(map, 3);
let sum = 0;
for (let i = 0; i < grid.n; i++) if (grid.open[i]) sum += i;
out.push(`grid ${grid.nx} ${grid.ny} ${f(grid.x0)} ${f(grid.y0)} ${grid.openCount} ${sum}`);
// }}}

// {{{ sectors at seeded points on open ground
const rand = RP.seeded(7);
const open = [];
for (let i = 0; i < grid.n; i++) if (grid.open[i]) open.push(i);
for (let k = 0; k < 300; k++) {
  const c = grid.middle(open[Math.floor(rand() * open.length)]);
  const x = c.x + (rand() - 0.5) * 2.4, y = c.y + (rand() - 0.5) * 2.4;
  const secs = RP.senseSectors(grid, x, y, 40, 0.6);
  out.push(`sector ${f(x)} ${f(y)} ` + secs.map(s => `${s.kind} ${f(s.reach)}`).join(" "));
}
// }}}

// {{{ waypoints on the gallery's first area (outline and rocks)
const outline = [[6, 14], [40, 4], [88, 8], [122, 24], [124, 60], [104, 88], [60, 94], [22, 84], [2, 52]];
const rocks = [{ x: 42, y: 34, r: 6 }, { x: 80, y: 30, r: 5 }, { x: 64, y: 60, r: 7 }, { x: 30, y: 64, r: 4 }, { x: 100, y: 58, r: 4 }, { x: 88, y: 76, r: 3 }];
const centre = [outline.reduce((s, p) => s + p[0], 0) / outline.length, outline.reduce((s, p) => s + p[1], 0) / outline.length];
const area = { outline, rocks, centre };
const setup = RP.seeded(11);
for (let k = 1; k <= 600; k++) {
  const angle = setup() * 2 * Math.PI, spin = setup() < 0.5 ? -1 : 1;
  const y100 = 1 + Math.floor(setup() * 100), inward = Math.floor(setup() * 3);
  const others = [];
  const nOthers = Math.floor(setup() * 3);
  for (let m = 0; m < nOthers; m++) others.push({ x: 8 + setup() * 110, y: 8 + setup() * 80 });
  // a crowd right on the likely spot now and then, so crowding happens
  if (setup() < 0.3) {
    const a = angle + RP.WAYPOINT_RULES.turn * spin, reach = RP.rayToEdge(outline, centre[0], centre[1], a) - 3;
    const d = Math.max(10, y100 / 100 * reach);
    others.push({ x: centre[0] + Math.cos(a) * d + 1, y: centre[1] + Math.sin(a) * d });
  }
  const b = { x: 60, y: 50, angle, spin, y100, inward };
  const wp = RP.pickWaypoint(b, area, others, RP.seeded(1000 + k));
  const ins = `${f(angle)} ${spin} ${y100} ${inward} ${others.length} ` + others.map(o => `${f(o.x)} ${f(o.y)}`).join(" ");
  out.push(`waypoint ${k} ${ins} => ` + (wp ? `${f(wp.x)} ${f(wp.y)} ${b.y100} ${b.spin} ${b.inward}` : "none"));
}
// }}}
print(out.join("\n"));
