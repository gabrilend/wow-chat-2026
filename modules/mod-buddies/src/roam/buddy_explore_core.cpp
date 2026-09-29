/*
 * buddy_explore_core.cpp - exploring an area as painting (issue 617e6).
 *
 * For a general audience: the three new ways a buddy explores a named area
 * (least paint, the room orbit, the squished circle) and the ground grid,
 * paint, rooms, disc and paths they share. The design and every number are
 * the Lua model's (src/lua-basic/lib/buddy-roam.lua, "painting"); this is
 * that model written again for the server, loop for loop, so a test can
 * hold the two to the same answers (tests/buddy-roam-core/explore-check.cpp).
 * See buddy_explore_core.h for what each part is.
 */

#include "buddy_explore_core.h"

#include <algorithm>
#include <cmath>

namespace BuddyExplore
{

namespace
{
constexpr double kPi = 3.141592653589793;   // the model's math.pi (the same double)

// {{{ YStep
// The owner's Y rule, as the model's Y_DRAW.step: Y a whole number 1..100,
// moved in or out at even odds by yChangeMin..yChangeMax. Two random
// numbers, the change first, then the side.
double YStep(Settings const& s, double y, Rng const& rng)
{
    double pct    = std::floor(y * 100.0 + 0.5);
    double change = double(s.yChangeMin) + std::floor(rng() * double(s.yChangeMax - s.yChangeMin + 1));
    double sign   = rng() < 0.5 ? -1.0 : 1.0;
    return std::max(1.0, std::min(100.0, pct + sign * change)) / 100.0;
}
// }}}

double Clamp01(double v) { return std::max(0.01, std::min(1.0, v)); }

// {{{ ScoreSpot
// How worth visiting a spot is, lower better: how painted the ground round
// it is, less a bonus for being far from where the owner entered ("the
// spots farthest from the entrance").
double ScoreSpot(Grid const& g, Paint const& p, Settings const& s, double x, double y, double ex, double ey, double farRef)
{
    double far = std::sqrt((x - ex) * (x - ex) + (y - ey) * (y - ey)) / farRef;
    return PaintedNear(g, p, s, x, y) - s.farWeight * far;
}
// }}}

bool Passable(Grid const& g, Settings const& s, int32_t i) { return g.open[i] && g.wall[i] >= s.pathMargin; }
}

// {{{ Grid cells
int32_t Grid::CellOf(double x, double y) const
{
    double fx = std::floor((x - x0) / cell), fy = std::floor((y - y0) / cell);
    if (fx < 0.0 || fy < 0.0 || fx >= double(nx) || fy >= double(ny))
        return -1;
    return int32_t(fy) * nx + int32_t(fx);
}
void Grid::CellXY(int32_t i, double& x, double& y) const
{
    int32_t ix = i % nx, iy = i / nx;
    x = x0 + (double(ix) + 0.5) * cell;
    y = y0 + (double(iy) + 0.5) * cell;
}
// }}}

// {{{ Paint::Reset
void Paint::Reset(Grid const& g)
{
    buddy.assign(size_t(g.Count()), 0);
    wallp.assign(size_t(g.Count()), 0);
    close.assign(size_t(g.Count()), 0);
}
// }}}

// {{{ Prepare
// The open list, the wall pulse's cells, and the rooms and tunnels, as the
// model's Roam.paint_grid and Roam.paint_rooms. Rooms and tunnels: each
// inside cell's distance to the area's edge is a distance transform;
//   1. cores: cells at least roomMin from the edge, the deep middles of wide
//      places; each connected group (eight neighbours) is one room;
//   2. growth: every other inside cell within roomMin yards (walked over
//      cells) of a core joins that core's room, breadth first from every
//      core at once: the band between a room's middle and its walls;
//   3. the rest: the narrow places between rooms and in dead ends, are
//      tunnels, each connected group one tunnel.
// An L-shaped hall stays one room (its corner is as wide as its arms); a
// corridor under 14 yards wide is a tunnel; a dead-end passage is a tunnel
// that leads nowhere.
void Prepare(Grid& g, Settings const& s)
{
    int32_t n = g.Count();
    g.openList.clear();
    for (int32_t i = 0; i < n; ++i)
        if (g.open[i])
            g.openList.push_back(i);
    if (g.height.size() != size_t(n))
        g.height.assign(static_cast<size_t>(n), 0.0f);

    // the wall pulse: every open cell within wallReach of a wall, and the
    // level the pulse tops it up to, falling off with the square of the
    // distance (the middle of a 10-yard tunnel gets little, its edges much)
    g.wallCells.clear();
    for (int32_t i : g.openList)
        if (g.wall[i] < s.wallReach)
        {
            double k = 1.0 - g.wall[i] / s.wallReach;
            g.wallCells.emplace_back(i, uint16_t(std::floor(double(s.wallPaint) * k * k + 0.5)));
        }

    int32_t reach = int32_t(std::floor(s.roomMin / g.cell + 0.5));
    g.room.assign(static_cast<size_t>(n), 0);
    g.tunnel.assign(static_cast<size_t>(n), 0);
    g.rooms.clear();
    g.tunnels.clear();
    // the model's each_nb: the eight neighbours in its order, inside ones only
    auto eachNb = [&g](int32_t i, auto&& fn)
    {
        int32_t ix = i % g.nx, iy = i / g.nx;
        for (int32_t oy = -1; oy <= 1; ++oy)
            for (int32_t ox = -1; ox <= 1; ++ox)
            {
                if (ox == 0 && oy == 0)
                    continue;
                int32_t jx = ix + ox, jy = iy + oy;
                if (jx >= 0 && jy >= 0 && jx < g.nx && jy < g.ny)
                {
                    int32_t j = jy * g.nx + jx;
                    if (g.inside[j])
                        fn(j);
                }
            }
    };

    // 1. cores, grouped (a stack, popped from the end, as the model)
    for (int32_t i = 0; i < n; ++i)
    {
        if (!g.inside[i] || g.edge[i] < s.roomMin || g.room[i])
            continue;
        int32_t r = int32_t(g.rooms.size()) + 1;
        g.rooms.emplace_back();
        std::vector<int32_t> stack { i };
        g.room[i] = r;
        while (!stack.empty())
        {
            int32_t c = stack.back();
            stack.pop_back();
            eachNb(c, [&](int32_t j)
            {
                if (!g.room[j] && g.edge[j] >= s.roomMin) { g.room[j] = r; stack.push_back(j); }
            });
        }
    }
    // 2. growth, breadth first from every core at once
    std::vector<int32_t> queue, depth(static_cast<size_t>(n), 0);
    for (int32_t i = 0; i < n; ++i)
        if (g.room[i])
            queue.push_back(i);
    for (size_t head = 0; head < queue.size(); ++head)
    {
        int32_t c = queue[head];
        if (depth[c] < reach)
            eachNb(c, [&](int32_t j)
            {
                if (!g.room[j]) { g.room[j] = g.room[c]; depth[j] = depth[c] + 1; queue.push_back(j); }
            });
    }
    // 3. tunnels
    for (int32_t i = 0; i < n; ++i)
    {
        if (!g.inside[i] || g.room[i] || g.tunnel[i])
            continue;
        int32_t k = int32_t(g.tunnels.size()) + 1;
        g.tunnels.emplace_back();
        g.tunnels.back().isRoom = false;
        g.tunnels.back().id = k;
        std::vector<int32_t> stack { i };
        g.tunnel[i] = k;
        while (!stack.empty())
        {
            int32_t c = stack.back();
            stack.pop_back();
            eachNb(c, [&](int32_t j)
            {
                if (!g.room[j] && !g.tunnel[j]) { g.tunnel[j] = k; stack.push_back(j); }
            });
        }
    }
    // the walkable cells of each, in cell order
    for (int32_t i : g.openList)
    {
        if (g.room[i])
            g.rooms[g.room[i] - 1].cells.push_back(i);
        if (g.tunnel[i])
            g.tunnels[g.tunnel[i] - 1].cells.push_back(i);
    }
    // each room's middle: the average of its walkable cells, moved to its
    // nearest walkable cell of that room if the average falls outside it
    for (size_t r = 0; r < g.rooms.size(); ++r)
    {
        Place& room = g.rooms[r];
        room.isRoom = true;
        room.id = int32_t(r) + 1;
        if (room.cells.empty())
            continue;                                   // a room entirely under rocks: no middle, never chosen
        double sx = 0.0, sy = 0.0;
        for (int32_t i : room.cells)
        {
            double x, y;
            g.CellXY(i, x, y);
            sx += x, sy += y;
        }
        double cx = sx / double(room.cells.size()), cy = sy / double(room.cells.size());
        // the model looks this cell up without a bounds check; off the
        // grid it counts as "not this room" (the nearest cell is taken)
        int32_t ci = int32_t(std::floor((cx - g.x0) / g.cell)) + int32_t(std::floor((cy - g.y0) / g.cell)) * g.nx;
        bool here = ci >= 0 && ci < n && g.room[ci] == room.id && g.open[ci];
        if (!here)
        {
            int32_t best = -1;
            double bd = 0.0;
            for (int32_t i : room.cells)
            {
                double x, y;
                g.CellXY(i, x, y);
                double d = (x - cx) * (x - cx) + (y - cy) * (y - cy);
                if (best < 0 || d < bd) best = i, bd = d;
            }
            g.CellXY(best, cx, cy);
        }
        room.cx = cx, room.cy = cy;
    }
    // the places a buddy can be drawn to: every room, and every tunnel with
    // walkable cells (a dead end is a tunnel leading nowhere, and must be
    // walked to be seen); a tunnel's middle is its cell deepest from the edge
    g.places.clear();
    for (Place const& room : g.rooms)
        g.places.push_back(room);
    for (Place const& tn : g.tunnels)
    {
        if (tn.cells.empty())
            continue;
        int32_t best = tn.cells[0];
        double be = -1.0;
        for (int32_t i : tn.cells)
            if (g.edge[i] > be) best = i, be = g.edge[i];
        Place p = tn;
        g.CellXY(best, p.cx, p.cy);
        g.places.push_back(p);
    }
}
// }}}

// {{{ ComputeDistances
// A two-pass nearest-seed sweep (each cell carries the nearest blocked
// cell found so far from its neighbours; eight neighbours, forward then
// backward, twice), which is exact or within a fraction of a cell for the
// shapes areas have. Blocked for `edge`: not inside (and the grid's own
// border); for `wall`: not open.
void ComputeDistances(Grid& g)
{
    int32_t n = g.Count();
    auto sweep = [&g, n](std::vector<uint8_t> const& blocked, std::vector<double>& out)
    {
        // nearest blocked cell (as grid coordinates; the grid's border counts
        // as blocked just outside it)
        std::vector<int32_t> sx(static_cast<size_t>(n)), sy(static_cast<size_t>(n));
        std::vector<double>  d2(static_cast<size_t>(n));
        const double far = 1e30;
        for (int32_t i = 0; i < n; ++i)
        {
            int32_t ix = i % g.nx, iy = i / g.nx;
            if (blocked[i]) { sx[i] = ix; sy[i] = iy; d2[i] = 0.0; continue; }
            // the grid's border: a blocked cell just outside
            int32_t bx = ix, by = iy;
            double best = far;
            auto consider = [&](int32_t ox, int32_t oy)
            {
                double dx = double(ox - ix), dy = double(oy - iy), d = dx * dx + dy * dy;
                if (d < best) best = d, bx = ox, by = oy;
            };
            consider(-1, iy); consider(g.nx, iy); consider(ix, -1); consider(ix, g.ny);
            sx[i] = bx; sy[i] = by; d2[i] = best;
        }
        auto relax = [&](int32_t i, int32_t j)
        {
            int32_t ix = i % g.nx, iy = i / g.nx;
            double dx = double(sx[j] - ix), dy = double(sy[j] - iy), d = dx * dx + dy * dy;
            if (d < d2[i]) { d2[i] = d; sx[i] = sx[j]; sy[i] = sy[j]; }
        };
        for (int32_t pass = 0; pass < 2; ++pass)
        {
            for (int32_t iy = 0; iy < g.ny; ++iy)
                for (int32_t ix = 0; ix < g.nx; ++ix)
                {
                    int32_t i = iy * g.nx + ix;
                    if (ix > 0) relax(i, i - 1);
                    if (iy > 0) relax(i, i - g.nx);
                    if (ix > 0 && iy > 0) relax(i, i - g.nx - 1);
                    if (ix + 1 < g.nx && iy > 0) relax(i, i - g.nx + 1);
                }
            for (int32_t iy = g.ny - 1; iy >= 0; --iy)
                for (int32_t ix = g.nx - 1; ix >= 0; --ix)
                {
                    int32_t i = iy * g.nx + ix;
                    if (ix + 1 < g.nx) relax(i, i + 1);
                    if (iy + 1 < g.ny) relax(i, i + g.nx);
                    if (ix + 1 < g.nx && iy + 1 < g.ny) relax(i, i + g.nx + 1);
                    if (ix > 0 && iy + 1 < g.ny) relax(i, i + g.nx - 1);
                }
        }
        // centre to centre, less half a cell: to the blocked cell's edge
        for (int32_t i = 0; i < n; ++i)
            out[i] = std::max(0.0, std::sqrt(d2[i]) * g.cell - 0.5 * g.cell);
    };
    std::vector<uint8_t> notInside(static_cast<size_t>(n)), notOpen(static_cast<size_t>(n));
    for (int32_t i = 0; i < n; ++i)
    {
        notInside[i] = g.inside[i] ? 0 : 1;
        notOpen[i]   = g.open[i] ? 0 : 1;
    }
    std::vector<double> e(static_cast<size_t>(n)), w(static_cast<size_t>(n));
    sweep(notInside, e);
    sweep(notOpen, w);
    g.edge.assign(static_cast<size_t>(n), -1.0);
    g.wall.assign(static_cast<size_t>(n), -1.0);
    for (int32_t i = 0; i < n; ++i)
    {
        if (g.inside[i]) g.edge[i] = e[i];
        if (g.open[i])   g.wall[i] = w[i];
    }
}
// }}}

// {{{ RimAngles
// The outer border traced cell by cell (Moore neighbour tracing from the
// first border cell in cell order, clockwise in the grid's own rows),
// each border cell's angle its share of the traced length. Border cells the
// trace doesn't meet (the rims of holes, a second piece) are given the angle
// of the nearest traced cell, so every rim cell has one. For the disc of a
// grid made from samples.
std::vector<std::pair<int32_t, double>> RimAngles(Grid const& g)
{
    int32_t n = g.Count();
    auto isInside = [&g](int32_t x, int32_t y)
    {
        return x >= 0 && y >= 0 && x < g.nx && y < g.ny && g.inside[y * g.nx + x];
    };
    auto isRim = [&](int32_t x, int32_t y)
    {
        return isInside(x, y) && (!isInside(x + 1, y) || !isInside(x - 1, y) || !isInside(x, y + 1) || !isInside(x, y - 1));
    };
    std::vector<std::pair<int32_t, double>> out;
    int32_t start = -1;
    for (int32_t i = 0; i < n && start < 0; ++i)
        if (isRim(i % g.nx, i / g.nx))
            start = i;
    if (start < 0)
        return out;
    // Moore tracing over inside cells: the eight directions clockwise from
    // east (in rows: +x, then +x+y, +y, ...)
    static int32_t const DX[8] = { 1, 1, 0, -1, -1, -1, 0, 1 };
    static int32_t const DY[8] = { 0, 1, 1, 1, 0, -1, -1, -1 };
    std::vector<int32_t> order;
    std::vector<uint8_t> seen(static_cast<size_t>(n), 0);
    int32_t cx = start % g.nx, cy = start / g.nx, dir = 6;   // came from "up": the first cell has nothing inside above-left in cell order
    for (int32_t guard = 0; guard < 8 * n; ++guard)
    {
        int32_t ci = cy * g.nx + cx;
        if (!seen[ci]) { seen[ci] = 1; order.push_back(ci); }
        // search clockwise starting just after backtracking
        int32_t k = (dir + 6) % 8, found = -1;
        for (int32_t t = 0; t < 8; ++t)
        {
            int32_t d = (k + t) % 8;
            if (isInside(cx + DX[d], cy + DY[d])) { found = d; break; }
        }
        if (found < 0)
            break;                                      // a single-cell area
        cx += DX[found], cy += DY[found], dir = found;
        if (cy * g.nx + cx == start && guard > 0)
            break;
    }
    // lengths along the trace
    std::vector<double> along(order.size(), 0.0);
    double total = 0.0;
    for (size_t k = 0; k < order.size(); ++k)
    {
        along[k] = total;
        int32_t a = order[k], b = order[(k + 1) % order.size()];
        double dx = double(b % g.nx - a % g.nx), dy = double(b / g.nx - a / g.nx);
        total += std::sqrt(dx * dx + dy * dy) * g.cell;
    }
    std::vector<double> angleOf(static_cast<size_t>(n), -1.0);
    for (size_t k = 0; k < order.size(); ++k)
    {
        angleOf[order[k]] = total > 0.0 ? 2.0 * kPi * along[k] / total : 0.0;
        out.emplace_back(order[k], angleOf[order[k]]);
    }
    // rim cells the trace missed: the nearest traced cell's angle
    for (int32_t i = 0; i < n; ++i)
    {
        if (!isRim(i % g.nx, i / g.nx) || angleOf[i] >= 0.0)
            continue;
        double bd = 1e30, ba = 0.0;
        for (int32_t j : order)
        {
            double dx = double(j % g.nx - i % g.nx), dy = double(j / g.nx - i / g.nx), d = dx * dx + dy * dy;
            if (d < bd) bd = d, ba = angleOf[j];
        }
        out.emplace_back(i, ba);
    }
    return out;
}
// }}}

// {{{ DiscMap
// The squished circle, as the model's Roam.paint_disc_map: cells on the
// border (an inside cell with a four-neighbour outside, or off the grid) go
// round the circle; every other inside cell is moved, sweep after sweep,
// to the average of its four neighbours (over-relaxed Gauss-Seidel, weight
// 1.9, in cell order). Why it can't fold: a harmonic map whose border goes
// once round a convex shape (the circle) in order is one-to-one inside
// (Rado-Kneser-Choquet; Tutte's theorem for graphs); each cell is the
// average of its neighbours, so none can be pushed past them, and the
// local stretch (the Jacobian) keeps one sign everywhere, never flipping
// into a fold (docs/reference/jacobian-conjecture/). So each point of the
// disc names one place, and a pinwheel run in the disc's angle and radius
// turns round an L's bend, runs down corridors (thin bands of the disc) and
// into dead ends (parts of the rim).
int32_t DiscMap(Grid& g, std::function<std::pair<double, double>(int32_t)> const& rimPoint, int32_t sweeps, double tolerance)
{
    int32_t n = g.Count();
    g.du.assign(static_cast<size_t>(n), 0.0);
    g.dv.assign(static_cast<size_t>(n), 0.0);
    g.hasDisc.assign(static_cast<size_t>(n), 0);
    g.rim.assign(static_cast<size_t>(n), 0);
    std::vector<int32_t> inner;
    for (int32_t iy = 0; iy < g.ny; ++iy)
        for (int32_t ix = 0; ix < g.nx; ++ix)
        {
            int32_t i = iy * g.nx + ix;
            if (!g.inside[i])
                continue;
            static int32_t const NB[4][2] = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } };
            bool rim = false;
            for (auto const& nb : NB)
            {
                int32_t jx = ix + nb[0], jy = iy + nb[1];
                if (jx < 0 || jy < 0 || jx >= g.nx || jy >= g.ny || !g.inside[jy * g.nx + jx])
                    rim = true;
            }
            g.hasDisc[i] = 1;
            if (rim)
            {
                std::pair<double, double> p = rimPoint(i);
                g.du[i] = p.first, g.dv[i] = p.second, g.rim[i] = 1;
            }
            else
                inner.push_back(i);
        }
    double const w = 1.9;
    int32_t made = 0;
    for (int32_t pass = 0; pass < sweeps; ++pass)
    {
        double moved = 0.0;
        for (int32_t i : inner)
        {
            int32_t const nbs[4] = { i - 1, i + 1, i - g.nx, i + g.nx };
            double su = 0.0, sv = 0.0;
            int32_t cnt = 0;
            for (int32_t j : nbs)
                if (g.hasDisc[j]) su += g.du[j], sv += g.dv[j], ++cnt;
            if (cnt > 0)
            {
                double nu = (1.0 - w) * g.du[i] + w * su / double(cnt);
                double nv = (1.0 - w) * g.dv[i] + w * sv / double(cnt);
                moved = std::max(moved, std::fabs(nu - g.du[i]) + std::fabs(nv - g.dv[i]));
                g.du[i] = nu, g.dv[i] = nv;
            }
        }
        ++made;
        if (tolerance > 0.0 && moved < tolerance)
            break;
    }
    // the cells a waypoint may take: open, 3 yards off walls (the model's
    // literal 3), with a place on the disc
    g.discClear.clear();
    for (int32_t i : g.openList)
        if (g.wall[i] >= 3.0 && g.hasDisc[i])
            g.discClear.push_back(i);
    return made;
}
// }}}

// {{{ Deposit
// A buddy's paint from where it stands: sight lines every 4 degrees,
// marched cell by cell until a wall or rock stops them. Cells near the
// buddy are crossed by many lines, so the paint heaps up where it stands
// ("more paint at their location and less and less drifting out"). The
// counts wrap at 65,536 (see Paint).
void Deposit(Grid const& g, Paint& p, Settings const& s, double x, double y)
{
    for (int32_t k = 0; k < s.rays; ++k)
    {
        double a = 2.0 * kPi * double(k) / double(s.rays);
        double dx = std::cos(a), dy = std::sin(a);
        double d = 0.0;
        while (d <= s.vision)
        {
            int32_t i = g.CellOf(x + dx * d, y + dy * d);
            if (i < 0 || !g.open[i])
                break;
            double f = 1.0 - d / s.vision;
            p.buddy[i] = uint16_t(p.buddy[i] + uint16_t(std::floor(double(s.nearPaint) * f * f) + 1.0));
            if (d <= s.close)
                p.close[i] = 1;
            d = d + g.cell;
        }
    }
}
// }}}

// {{{ WallPulse
// Tops the ground near the walls up to its level (never adds on top): walls
// never stop pulsing, so paint added without end would outweigh every
// buddy's and flatten the difference between a tunnel's edges and its
// middle, which is what keeps a buddy walking the middle.
void WallPulse(Grid const& g, Paint& p)
{
    for (auto const& c : g.wallCells)
        if (p.wallp[c.first] < c.second)
            p.wallp[c.first] = c.second;
}
// }}}

// {{{ PaintedNear
// 0..1: how painted the ground within Settings.disc yards of (x, y) is,
// walls' paint included; 1 off the grid.
double PaintedNear(Grid const& g, Paint const& p, Settings const& s, double x, double y)
{
    double sum = 0.0;
    int32_t cnt = 0;
    int32_t r = int32_t(std::ceil(s.disc / g.cell));
    int32_t ci = g.CellOf(x, y);
    if (ci < 0)
        return 1.0;
    int32_t cx = ci % g.nx, cy = ci / g.nx;
    for (int32_t oy = -r; oy <= r; ++oy)
        for (int32_t ox = -r; ox <= r; ++ox)
        {
            int32_t ix = cx + ox, iy = cy + oy;
            if (ix >= 0 && iy >= 0 && ix < g.nx && iy < g.ny && ox * ox + oy * oy <= r * r)
            {
                int32_t i = iy * g.nx + ix;
                if (g.open[i])
                {
                    double v = double(p.buddy[i]) + double(p.wallp[i]);
                    sum += v / (v + s.saturate);
                    ++cnt;
                }
            }
        }
    return cnt > 0 ? sum / double(cnt) : 1.0;
}
// }}}

// {{{ Coverage / FarRef
double Coverage(Grid const& g, Paint const& p)
{
    if (g.openList.empty())
        return 1.0;
    int32_t seen = 0;
    for (int32_t i : g.openList)
        if (p.close[i]) ++seen;
    return double(seen) / double(g.openList.size());
}
double FarRef(Grid const& g, double ex, double ey)
{
    double far = 0.0;
    for (int32_t i : g.openList)
    {
        double x, y;
        g.CellXY(i, x, y);
        far = std::max(far, std::sqrt((x - ex) * (x - ex) + (y - ey) * (y - ey)));
    }
    return far;
}
// }}}

// {{{ PickLeast
// No pinwheel: of 30 random walkable spots 12 to 70 yards away (at most 400
// draws), the least painted, farthest from the entrance breaking near-ties.
// The walls' own paint is what keeps it off them. None in range (a buddy
// boxed into a tiny room): it stays put this time.
bool PickLeast(Grid const& g, Paint const& p, Settings const& s, Explorer& e, double ex, double ey, double farRef, Rng const& rng)
{
    if (g.openList.empty())
        return false;
    bool have = false;
    double bx = 0.0, by = 0.0, bs = 0.0;
    int32_t weighed = 0;
    for (int32_t draw = 0; draw < 400; ++draw)
    {
        int32_t i = g.openList[size_t(std::floor(rng() * double(g.openList.size())))];
        if (g.wall[i] >= s.clearance)
        {
            double x, y;
            g.CellXY(i, x, y);
            double d = std::sqrt((x - e.x) * (x - e.x) + (y - e.y) * (y - e.y));
            if (d >= 12.0 && d <= 70.0)
            {
                double sc = ScoreSpot(g, p, s, x, y, ex, ey, farRef);
                if (!have || sc < bs) have = true, bx = x, by = y, bs = sc;
                if (++weighed >= 30)
                    break;
            }
        }
    }
    e.hasGoal = true;
    e.gx = have ? bx : e.x;
    e.gy = have ? by : e.y;
    return true;
}
// }}}

// {{{ BeginDisc / PickDisc
void BeginDisc(Grid const& g, Explorer& e)
{
    int32_t i = g.CellOf(e.x, e.y);
    double u = (i >= 0 && g.hasDisc[i]) ? g.du[i] : 0.0, v = (i >= 0 && g.hasDisc[i]) ? g.dv[i] : 0.0;
    e.dang = std::atan2(v, u);
    e.dshare = Clamp01(std::sqrt(u * u + v * v));
}

// The waypoint-worthy cell whose disc place is nearest the disc point at
// angle a and radius r (0..1); -1 when there is none.
static int32_t NearestInDisc(Grid const& g, double a, double r)
{
    double u = std::cos(a) * r, v = std::sin(a) * r;
    int32_t best = -1;
    double bd = 0.0;
    for (int32_t i : g.discClear)
    {
        double d = (g.du[i] - u) * (g.du[i] - u) + (g.dv[i] - v) * (g.dv[i] - v);
        if (best < 0 || d < bd) best = i, bd = d;
    }
    return best;
}

// The pinwheel run in the squished circle: the angle turns a steady step,
// the radius is the owner's Y rule; that point and eight near it (half a
// step either way, 15 points out or in) are looked up to their cells and
// weighed by paint.
bool PickDisc(Grid const& g, Paint const& p, Settings const& s, Explorer& e, double ex, double ey, double farRef, Rng const& rng)
{
    if (g.discClear.empty())
        return false;
    e.dang = e.dang + s.turn * double(e.spin);
    e.dshare = YStep(s, e.dshare, rng);
    bool have = false;
    double bx = 0.0, by = 0.0, bs = 0.0;
    double const das[3] = { 0.0, -s.turn / 2.0, s.turn / 2.0 };
    double const dys[3] = { 0.0, -0.15, 0.15 };
    for (double da : das)
        for (double dy : dys)
        {
            int32_t i = NearestInDisc(g, e.dang + da, Clamp01(e.dshare + dy));
            double x, y;
            g.CellXY(i, x, y);
            double sc = ScoreSpot(g, p, s, x, y, ex, ey, farRef);
            if (!have || sc < bs) have = true, bx = x, by = y, bs = sc;
        }
    e.hasGoal = true, e.gx = bx, e.gy = by;
    return true;
}
// }}}

// {{{ PickRooms
// The pinwheel round the middle of the room the buddy is in, in that room's
// own coordinates (its centre, and where a line leaves the room: a wall or
// a tunnel's mouth), the least painted of the proposal and eight near it;
// until the room is roomLeave explored and another place less so, when the
// paint draws the buddy there (a room or a tunnel, dead ends included),
// farther from the entrance weighing more; arriving in a new room it orbits
// that room's middle. As the model's PAINT_PICK.rooms, step for step.
static double CellsExplored(Paint const& p, std::vector<int32_t> const& cells)
{
    int32_t cnt = 0, seen = 0;
    for (int32_t i : cells)
    {
        ++cnt;
        if (p.close[i]) ++seen;
    }
    return cnt > 0 ? double(seen) / double(cnt) : 1.0;
}
static bool InPlace(Grid const& g, Place const& pl, int32_t i)
{
    if (i < 0)
        return false;
    return pl.isRoom ? g.room[i] == pl.id : g.tunnel[i] == pl.id;
}
static double RoomReach(Grid const& g, int32_t r, double a)
{
    Place const& room = g.rooms[size_t(r - 1)];
    double dx = std::cos(a), dy = std::sin(a);
    double d = 0.0;
    for (;;)
    {
        int32_t i = g.CellOf(room.cx + dx * (d + g.cell * 0.5), room.cy + dy * (d + g.cell * 0.5));
        if (i < 0 || !g.inside[i] || (g.open[i] && g.room[i] != r))
            return d;
        d = d + g.cell * 0.5;
    }
}
static bool RoomSpotOk(Grid const& g, Settings const& s, int32_t r, double x, double y)
{
    int32_t i = g.CellOf(x, y);
    return i >= 0 && g.open[i] && g.room[i] == r && g.wall[i] >= s.clearance;
}
bool PickRooms(Grid const& g, Paint const& p, Settings const& s, Explorer& e, double ex, double ey, double farRef, Rng const& rng)
{
    if (g.rooms.empty())
        return false;
    int32_t ci = g.CellOf(e.x, e.y);
    int32_t here = ci >= 0 ? g.room[ci] : 0;
    if (here && here != e.room)
        e.room = here, e.rshare = 0.5;
    // arrived where the paint drew it (a room, or the spot chosen in a
    // tunnel): the drawing is done
    if (e.heading && (InPlace(g, g.places[size_t(e.heading - 1)], ci) ||
                      (e.hasGoal && (e.gx - e.x) * (e.gx - e.x) + (e.gy - e.y) * (e.gy - e.y) < 4.0)))
        e.heading = 0;
    // never stood in a room (it starts in a tunnel): the room whose middle
    // is nearest
    if (!e.room)
    {
        int32_t best = 0;
        double bd = 0.0;
        for (size_t k = 0; k < g.rooms.size(); ++k)
        {
            Place const& room = g.rooms[k];
            double d = (room.cx - e.x) * (room.cx - e.x) + (room.cy - e.y) * (room.cy - e.y);
            if (!best || d < bd) best = int32_t(k) + 1, bd = d;
        }
        e.room = best, e.rshare = 0.5;
    }
    int32_t r = e.room;
    // leave? First to places still under roomLeave; once every place is past
    // it, to the least explored place if at least 5 points less explored
    // than this room, so buddies keep circulating until the last corners
    // are seen.
    double mine = CellsExplored(p, g.rooms[size_t(r - 1)].cells);
    if (!e.heading && mine >= s.roomLeave)
    {
        int32_t best = 0;
        double bs = 0.0;
        bool under = false;
        for (size_t k = 0; k < g.places.size(); ++k)
        {
            Place const& pl = g.places[k];
            if (pl.isRoom && pl.id == r)
                continue;
            double ev = CellsExplored(p, pl.cells);
            if (ev < 1.0)
            {
                double far = std::sqrt((pl.cx - ex) * (pl.cx - ex) + (pl.cy - ey) * (pl.cy - ey)) / farRef;
                double sc = ev - s.farWeight * far;
                bool u = ev < s.roomLeave;
                // places under the bar beat places over it
                if (!best || (u && !under) || (u == under && sc < bs)) best = int32_t(k) + 1, bs = sc, under = u;
            }
        }
        if (best && (under || CellsExplored(p, g.places[size_t(best - 1)].cells) <= mine - 0.05))
            e.heading = best;
    }
    if (e.heading)
    {
        Place const& pl = g.places[size_t(e.heading - 1)];
        bool have = false;
        double bx = 0.0, by = 0.0, bs = 0.0;
        for (int32_t draw = 0; draw < 30; ++draw)
        {
            int32_t i = pl.cells[size_t(std::floor(rng() * double(pl.cells.size())))];
            if (g.wall[i] >= std::min(s.clearance, pl.isRoom ? s.clearance : 2.0))
            {
                double x, y;
                g.CellXY(i, x, y);
                double sc = ScoreSpot(g, p, s, x, y, ex, ey, farRef);
                if (!have || sc < bs) have = true, bx = x, by = y, bs = sc;
            }
        }
        e.hasGoal = true;
        e.gx = have ? bx : pl.cx;
        e.gy = have ? by : pl.cy;
        return true;
    }
    // orbit this room's middle
    Place const& room = g.rooms[size_t(r - 1)];
    if (!e.rangSet)
        e.rang = std::atan2(e.y - room.cy, e.x - room.cx), e.rangSet = true;
    e.rang = e.rang + s.turn * double(e.spin);
    e.rshare = YStep(s, e.rshare, rng);
    bool have = false;
    double bx = 0.0, by = 0.0, bs = 0.0;
    double const das[3] = { 0.0, -s.turn / 2.0, s.turn / 2.0 };
    double const dys[3] = { 0.0, -0.15, 0.15 };
    for (double da : das)
        for (double dy : dys)
        {
            double a = e.rang + da;
            double reach = RoomReach(g, r, a) - s.clearance;
            double share = Clamp01(e.rshare + dy);
            // a blocked spot slides along its bearing to the nearest clear
            // one, as the owner's step rule does (1% at a time)
            for (int32_t k = 1; k <= 199; ++k)
            {
                double sh = share + std::floor(double(k) / 2.0) * (k % 2 == 0 ? -1.0 : 1.0) / 100.0;
                if (sh >= 0.01 && sh <= 1.0)
                {
                    double d = std::max(std::min(s.nearYards, reach), sh * reach);
                    double x = room.cx + std::cos(a) * d, y = room.cy + std::sin(a) * d;
                    if (RoomSpotOk(g, s, r, x, y))
                    {
                        double sc = ScoreSpot(g, p, s, x, y, ex, ey, farRef);
                        if (!have || sc < bs) have = true, bx = x, by = y, bs = sc;
                        break;
                    }
                }
            }
        }
    e.hasGoal = true;
    e.gx = have ? bx : room.cx;
    e.gy = have ? by : room.cy;
    return true;
}
// }}}

// {{{ GridPath
// A* over the walkable cells kept pathMargin off walls, eight neighbours
// (diagonals 1.4142 as the model), each step its length times (1 + weight x
// the painted share of the cell stepped onto), so paths lean through
// unexplored ground (the owner's "dijkstra heat map style"). The open set
// is the model's binary heap, pushed and popped the same way, so ties fall
// the same way. Then pulled straight: from each kept point, the farthest
// cell ahead (up to 16) a straight line reaches over passable cells.
static int32_t NearestPassable(Grid const& g, Settings const& s, double x, double y)
{
    int32_t i = g.CellOf(x, y);
    if (i >= 0 && Passable(g, s, i))
        return i;
    int32_t best = -1;
    double bd = 0.0;
    for (int32_t j : g.openList)
        if (Passable(g, s, j))
        {
            double jx, jy;
            g.CellXY(j, jx, jy);
            double d = (jx - x) * (jx - x) + (jy - y) * (jy - y);
            if (best < 0 || d < bd) best = j, bd = d;
        }
    return best;
}
static bool LineClear(Grid const& g, Settings const& s, double ax, double ay, double bx, double by)
{
    double len = std::sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay));
    int32_t cnt = std::max(1, int32_t(std::ceil(len / (g.cell * 0.5))));
    for (int32_t k = 1; k <= cnt; ++k)
    {
        int32_t i = g.CellOf(ax + (bx - ax) * double(k) / double(cnt), ay + (by - ay) * double(k) / double(cnt));
        if (i < 0 || !Passable(g, s, i))
            return false;
    }
    return true;
}
std::vector<Point2> GridPath(Grid const& g, Paint const& p, Settings const& s,
                             double ax, double ay, double bx, double by, double weight)
{
    std::vector<Point2> pts;
    int32_t start = NearestPassable(g, s, ax, ay), goal = NearestPassable(g, s, bx, by);
    if (start < 0 || goal < 0)
        return pts;
    double gx, gy;
    g.CellXY(goal, gx, gy);
    int32_t n = g.Count();
    std::vector<double>  cost(static_cast<size_t>(n), -1.0);    // -1: not reached
    std::vector<int32_t> from(static_cast<size_t>(n), -1);
    std::vector<uint8_t> closed(static_cast<size_t>(n), 0);
    cost[start] = 0.0;
    std::vector<std::pair<double, int32_t>> heap { { 0.0, start } };
    auto push = [&heap](double f, int32_t i)
    {
        heap.emplace_back(f, i);
        size_t k = heap.size();                         // 1-based, as the model
        while (k > 1)
        {
            size_t par = k / 2;
            if (heap[par - 1].first <= heap[k - 1].first)
                break;
            std::swap(heap[par - 1], heap[k - 1]);
            k = par;
        }
    };
    auto pop = [&heap]() -> std::pair<double, int32_t>
    {
        std::pair<double, int32_t> top = heap[0];
        heap[0] = heap.back();
        heap.pop_back();
        size_t k = 1;
        for (;;)
        {
            size_t l = 2 * k, r = 2 * k + 1, m = k;
            if (l <= heap.size() && heap[l - 1].first < heap[m - 1].first) m = l;
            if (r <= heap.size() && heap[r - 1].first < heap[m - 1].first) m = r;
            if (m == k)
                break;
            std::swap(heap[m - 1], heap[k - 1]);
            k = m;
        }
        return top;
    };
    static double const NB[8][3] = { { 1, 0, 1 }, { -1, 0, 1 }, { 0, 1, 1 }, { 0, -1, 1 },
                                     { 1, 1, 1.4142 }, { 1, -1, 1.4142 }, { -1, 1, 1.4142 }, { -1, -1, 1.4142 } };
    while (!heap.empty())
    {
        int32_t i = pop().second;
        if (i == goal)
            break;
        if (closed[i])
            continue;
        closed[i] = 1;
        int32_t ix = i % g.nx, iy = i / g.nx;
        for (auto const& nb : NB)
        {
            int32_t jx = ix + int32_t(nb[0]), jy = iy + int32_t(nb[1]);
            if (jx < 0 || jy < 0 || jx >= g.nx || jy >= g.ny)
                continue;
            int32_t j = jy * g.nx + jx;
            if (!Passable(g, s, j) || closed[j])
                continue;
            double step = nb[2] * g.cell;
            if (weight > 0.0)
            {
                double v = double(p.buddy[j]) + double(p.wallp[j]);
                step = step * (1.0 + weight * v / (v + s.saturate));
            }
            double c = cost[i] + step;
            if (cost[j] < 0.0 || c < cost[j])
            {
                cost[j] = c, from[j] = i;
                double x, y;
                g.CellXY(j, x, y);
                push(c + std::sqrt((x - gx) * (x - gx) + (y - gy) * (y - gy)), j);
            }
        }
    }
    if (cost[goal] < 0.0)
        return pts;
    std::vector<int32_t> cells;
    for (int32_t i = goal; i >= 0; i = from[i])
        cells.push_back(i);
    std::reverse(cells.begin(), cells.end());
    double px = ax, py = ay;
    size_t k = 0;
    while (k < cells.size())
    {
        size_t best = k;
        for (size_t j = std::min(cells.size() - 1, k + 16); ; --j)
        {
            double x, y;
            g.CellXY(cells[j], x, y);
            if (LineClear(g, s, px, py, x, y)) { best = j; break; }
            if (j == k)
                break;
        }
        g.CellXY(cells[best], px, py);
        pts.push_back({ px, py });
        k = best + 1;
    }
    pts.back() = { bx, by };
    return pts;
}
// }}}

} // namespace BuddyExplore
