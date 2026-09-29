/*
 * explore-check.cpp (issue 617e6) - the C++ side of the exploring
 * cross-check.
 *
 * For a general audience: builds the exploring core
 * (modules/mod-buddies/src/roam/buddy_explore_core.*) on the Lua model's
 * grid of the gallery's hall (written by explore-driver.lua), and checks
 * that the core, on its own, comes to the model's answers:
 *   - the wall pulse's cells and levels, the rooms and tunnels (every cell's
 *     label), and each room's and tunnel's middle: exactly;
 *   - the squished circle (each cell's place on the disc, from the model's
 *     border): to rounding;
 *   - a clan of four exploring for a while with each chooser (least paint,
 *     the room orbit, the squished circle), fed the same random numbers:
 *     every goal and every point of every path, and the paint's totals
 *     every 250 ticks.
 * And two checks of the parts only the server uses (the model has exact
 * shapes and doesn't need them):
 *   - distances measured on the grid alone, against the model's exact ones;
 *   - the disc from the grid's own traced border never folds (every little
 *     square of cells keeps its turning direction on the disc: the
 *     Jacobian's sign, docs/reference/jacobian-conjecture/).
 *
 * Usage: explore-check <grid.txt> <trace dir> <ticks> <seed>
 *   reads <trace dir>/lua-<mode>.txt for mode least, rooms, disc
 * Prints what passed and failed; exits 1 on any failure.
 */

#include "buddy_explore_core.h"

#include <cmath>
#include <cstdio>
#include <fstream>
#include <map>
#include <sstream>
#include <string>
#include <vector>

using namespace BuddyExplore;

// {{{ counting
static int32_t sPassed = 0, sFailed = 0;
static void Check(bool ok, std::string const& what)
{
    if (ok)
        ++sPassed;
    else
    {
        ++sFailed;
        if (sFailed <= 25)
            std::printf("    FAIL: %s\n", what.c_str());
    }
}
// }}}

// {{{ the model's grid
struct ModelGrid
{
    Grid g;
    double ex = 0.0, ey = 0.0;
    int32_t sweeps = 0;
    std::vector<uint8_t> rim;
    std::vector<double>  du, dv;
    std::vector<int32_t> room, tunnel;
    std::vector<std::pair<int32_t, int32_t>> wallCells;
    struct P { std::string kind; int32_t id, cells; double cx, cy; };
    std::vector<P> places;
    std::vector<int32_t> discClear;
};

static bool ReadGrid(char const* path, ModelGrid& m)
{
    std::ifstream in(path);
    if (!in)
        return false;
    std::string line;
    while (std::getline(in, line))
    {
        std::istringstream w(line);
        std::string tag;
        w >> tag;
        if (tag == "grid")
        {
            w >> m.g.nx >> m.g.ny >> m.g.x0 >> m.g.y0 >> m.g.cell >> m.ex >> m.ey >> m.sweeps;
            size_t n = size_t(m.g.nx) * size_t(m.g.ny);
            m.g.inside.assign(n, 0); m.g.open.assign(n, 0); m.g.edge.assign(n, -1.0); m.g.wall.assign(n, -1.0);
            m.rim.assign(n, 0); m.du.assign(n, 0.0); m.dv.assign(n, 0.0); m.room.assign(n, 0); m.tunnel.assign(n, 0);
        }
        else if (tag == "c")
        {
            int32_t i, inside, open, rim, room, tunnel;
            double edge, wall, du, dv;
            w >> i >> inside >> open >> edge >> wall >> rim >> du >> dv >> room >> tunnel;
            m.g.inside[i] = uint8_t(inside); m.g.open[i] = uint8_t(open);
            m.g.edge[i] = edge; m.g.wall[i] = wall;
            m.rim[i] = uint8_t(rim); m.du[i] = du; m.dv[i] = dv; m.room[i] = room; m.tunnel[i] = tunnel;
        }
        else if (tag == "w")
        {
            int32_t i, level;
            w >> i >> level;
            m.wallCells.emplace_back(i, level);
        }
        else if (tag == "p")
        {
            ModelGrid::P p;
            w >> p.kind >> p.id >> p.cells >> p.cx >> p.cy;
            m.places.push_back(p);
        }
        else if (tag == "d")
        {
            int32_t i;
            w >> i;
            m.discClear.push_back(i);
        }
    }
    return m.g.nx > 0;
}
// }}}

// {{{ the gallery's random numbers
// The generator's lcg, in doubles exactly as LuaJIT computes it (the
// product passes 2^53, so it rounds; the same rounding here):
// s = (s * 1103515245 + 12345) % 2^31, r = s / 2^31, with a % b = a -
// floor(a / b) * b.
struct Lcg
{
    double s;
    explicit Lcg(double seed) : s(seed) { }
    double operator()()
    {
        double a = s * 1103515245.0 + 12345.0;
        s = a - std::floor(a / 2147483648.0) * 2147483648.0;
        return s / 2147483648.0;
    }
};
// }}}

// {{{ a trace record
struct Record
{
    std::string tag;
    std::vector<std::string> words;
};
static std::vector<Record> ReadTrace(std::string const& path)
{
    std::vector<Record> out;
    std::ifstream in(path);
    std::string line;
    while (std::getline(in, line))
    {
        std::istringstream w(line);
        Record r;
        w >> r.tag;
        std::string x;
        while (w >> x) r.words.push_back(x);
        out.push_back(r);
    }
    return out;
}
// }}}

// {{{ the clan, as the model's paint_tick
struct SimBuddy
{
    Explorer e;
    std::vector<Point2> path;
    size_t pathI = 0;       // 0-based: the next point
    bool   hasPath = false;
};

static std::vector<Record> RunClan(Grid const& g, Settings const& s, std::string const& mode, double seed, int32_t ticks,
                                   double ex, double ey)
{
    std::vector<Record> out;
    Lcg rng(seed);
    Rng r = [&rng] { return rng(); };
    Paint paint;
    paint.Reset(g);
    double farRef = FarRef(g, ex, ey);
    std::vector<SimBuddy> bs(4);
    for (int32_t k = 0; k < 4; ++k)
    {
        bs[k].e.id = k + 1;
        bs[k].e.x = ex - 10.0 + double(k + 1) * 4.0;
        bs[k].e.y = ey - 4.0;
    }
    // the model's Roam.new: each buddy's direction, in order
    for (auto& b : bs)
    {
        b.e.spin = r() < 0.5 ? 1 : -1;
        out.push_back({ "S", { std::to_string(b.e.id), std::to_string(b.e.spin) } });
    }
    if (mode == "disc")
        for (auto& b : bs)
            BeginDisc(g, b.e);
    int32_t const paintEvery = 4, wallEvery = 48;
    double const step = 1.5;
    char buf[64];
    auto g17 = [&buf](double v) { std::snprintf(buf, sizeof buf, "%.17g", v); return std::string(buf); };
    for (int32_t t = 1; t <= ticks; ++t)
    {
        if ((t - 1) % wallEvery == 0)
            WallPulse(g, paint);
        for (auto& b : bs)
        {
            if ((t + b.e.id) % paintEvery == 0)
                Deposit(g, paint, s, b.e.x, b.e.y);
            if (!b.hasPath || b.pathI >= b.path.size())
            {
                if (mode == "least")      PickLeast(g, paint, s, b.e, ex, ey, farRef, r);
                else if (mode == "rooms") PickRooms(g, paint, s, b.e, ex, ey, farRef, r);
                else                      PickDisc(g, paint, s, b.e, ex, ey, farRef, r);
                b.path = GridPath(g, paint, s, b.e.x, b.e.y, b.e.gx, b.e.gy, s.pathWeight);
                if (b.path.empty())
                    b.path.push_back({ b.e.x, b.e.y });
                b.pathI = 0;
                b.hasPath = true;
                Record rec { "P", { std::to_string(t), std::to_string(b.e.id), g17(b.e.gx), g17(b.e.gy), std::to_string(b.path.size()) } };
                for (auto const& p : b.path) { rec.words.push_back(g17(p.x)); rec.words.push_back(g17(p.y)); }
                out.push_back(rec);
            }
            double left = step;
            while (left > 0.0 && b.pathI < b.path.size())
            {
                Point2 const& p = b.path[b.pathI];
                double d = std::sqrt((p.x - b.e.x) * (p.x - b.e.x) + (p.y - b.e.y) * (p.y - b.e.y));
                if (d > left)
                {
                    b.e.x = b.e.x + (p.x - b.e.x) / d * left;
                    b.e.y = b.e.y + (p.y - b.e.y) / d * left;
                    left = 0.0;
                }
                else
                {
                    b.e.x = p.x, b.e.y = p.y, left = left - d;
                    ++b.pathI;
                }
            }
        }
        if (t % 250 == 0)
        {
            long long sb = 0, sw = 0, sc = 0;
            for (int32_t i = 0; i < g.Count(); ++i) { sb += paint.buddy[i]; sw += paint.wallp[i]; sc += paint.close[i]; }
            out.push_back({ "C", { std::to_string(t), std::to_string(sb), std::to_string(sw), std::to_string(sc) } });
        }
    }
    return out;
}
// }}}

// {{{ compare traces
// Whole numbers must match exactly; positions within 1e-9 yards (the two
// compute the same doubles in the same order; any difference at all would
// mean a different step somewhere).
static void CompareTraces(std::string const& mode, std::vector<Record> const& cpp, std::vector<Record> const& lua)
{
    int32_t picks = 0, bad = 0;
    size_t n = std::max(cpp.size(), lua.size());
    for (size_t k = 0; k < n; ++k)
    {
        if (k >= cpp.size() || k >= lua.size())
        {
            ++bad;
            Check(false, mode + ": one side stopped early at record " + std::to_string(k)
                + " (C++ " + std::to_string(cpp.size()) + ", Lua " + std::to_string(lua.size()) + " records)");
            break;
        }
        Record const& a = cpp[k];
        Record const& b = lua[k];
        bool ok = a.tag == b.tag && a.words.size() == b.words.size();
        if (ok)
            for (size_t w = 0; w < a.words.size() && ok; ++w)
            {
                if (a.words[w] == b.words[w])
                    continue;
                double x = std::stod(a.words[w]), y = std::stod(b.words[w]);
                ok = a.tag == "P" && w >= 2 && w != 4 && std::fabs(x - y) <= 1e-9;
            }
        if (a.tag == "P") ++picks;
        if (!ok)
        {
            ++bad;
            std::string sa = a.tag, sb = b.tag;
            for (size_t w = 0; w < std::min<size_t>(a.words.size(), 8); ++w) sa += " " + a.words[w];
            for (size_t w = 0; w < std::min<size_t>(b.words.size(), 8); ++w) sb += " " + b.words[w];
            Check(false, mode + ": record " + std::to_string(k) + " differs: C++ [" + sa + " ...] Lua [" + sb + " ...]");
            break;                                      // after the first difference the two walks part ways
        }
        Check(true, "");
    }
    std::printf("  %-6s %zu records (%d choices with their paths), %s\n", mode.c_str(), lua.size(), picks,
        bad ? "DIFFERENT" : "all the same");
}
// }}}

int main(int argc, char** argv)
{
    if (argc < 5)
    {
        std::fprintf(stderr, "usage: explore-check <grid.txt> <trace dir> <ticks> <seed>\n");
        return 2;
    }
    ModelGrid m;
    if (!ReadGrid(argv[1], m))
    {
        std::printf("FAIL: could not read the model's grid %s\n", argv[1]);
        return 1;
    }
    std::string dir = argv[2];
    int32_t ticks = std::stoi(argv[3]);
    double seed = std::stod(argv[4]);
    Settings s;
    Grid& g = m.g;
    Prepare(g, s);
    int32_t n = g.Count();

    // {{{ the grid's derived parts
    Check(g.wallCells.size() == m.wallCells.size(), "wall pulse cell count " + std::to_string(g.wallCells.size())
        + " vs the model's " + std::to_string(m.wallCells.size()));
    for (size_t k = 0; k < std::min(g.wallCells.size(), m.wallCells.size()); ++k)
        Check(g.wallCells[k].first == m.wallCells[k].first && int32_t(g.wallCells[k].second) == m.wallCells[k].second,
            "wall pulse cell " + std::to_string(k));
    int32_t labelBad = 0;
    for (int32_t i = 0; i < n; ++i)
        if (g.room[i] != m.room[i] || g.tunnel[i] != m.tunnel[i]) ++labelBad;
    Check(labelBad == 0, std::to_string(labelBad) + " cells labelled with another room or tunnel than the model's");
    Check(g.places.size() == m.places.size(), "places: " + std::to_string(g.places.size()) + " vs " + std::to_string(m.places.size()));
    for (size_t k = 0; k < std::min(g.places.size(), m.places.size()); ++k)
    {
        Place const& a = g.places[k];
        auto const& b = m.places[k];
        Check((a.isRoom ? "room" : "tunnel") == b.kind && a.id == b.id && int32_t(a.cells.size()) == b.cells
              && std::fabs(a.cx - b.cx) <= 1e-9 && std::fabs(a.cy - b.cy) <= 1e-9, "place " + std::to_string(k));
    }
    std::printf("  grid   %dx%d cells of %.0f yd; %zu rooms, %zu tunnels, %zu places; %zu wall-pulse cells\n",
        g.nx, g.ny, g.cell, g.rooms.size(), g.tunnels.size(), g.places.size(), g.wallCells.size());
    // }}}

    // {{{ the disc, from the model's border
    int32_t made = DiscMap(g, [&m](int32_t i) { return std::make_pair(m.du[i], m.dv[i]); }, m.sweeps, 0.0);
    double worst = 0.0;
    int32_t rimBad = 0;
    for (int32_t i = 0; i < n; ++i)
    {
        if (g.rim[i] != m.rim[i]) ++rimBad;
        if (g.hasDisc[i]) worst = std::max(worst, std::fabs(g.du[i] - m.du[i]) + std::fabs(g.dv[i] - m.dv[i]));
    }
    Check(rimBad == 0, std::to_string(rimBad) + " cells on the border here but not in the model, or the other way");
    Check(worst <= 1e-9, "the disc differs from the model's by " + std::to_string(worst));
    Check(g.discClear == m.discClear, "the disc's waypoint cells differ from the model's");
    std::printf("  disc   %d sweeps; largest difference from the model %.3g\n", made, worst);
    // }}}

    // {{{ the clans
    for (std::string mode : { "least", "rooms", "disc" })
    {
        std::vector<Record> lua = ReadTrace(dir + "/lua-" + mode + ".txt");
        Check(!lua.empty(), "no Lua trace for " + mode);
        std::vector<Record> cpp = RunClan(g, s, mode, seed, ticks, m.ex, m.ey);
        CompareTraces(mode, cpp, lua);
    }
    // }}}

    // {{{ the server's own parts: distances on the grid, the traced border
    {
        Grid h = m.g;                                   // same cells, distances measured on the grid
        ComputeDistances(h);
        double we = 0.0, ww = 0.0, se = 0.0;
        int32_t ce = 0;
        for (int32_t i = 0; i < n; ++i)
        {
            if (h.inside[i]) { double d = std::fabs(h.edge[i] - m.g.edge[i]); we = std::max(we, d); se += d; ++ce; }
            if (h.open[i])   ww = std::max(ww, std::fabs(h.wall[i] - m.g.wall[i]));
        }
        // a grid can only know a wall to within a cell: its nearest blocked
        // cell's edge against the true outline, up to about a diagonal
        double const limit = 1.5 * h.cell;
        Check(we <= limit && ww <= limit, "grid distances off the exact ones by up to " + std::to_string(we) + " (edge), "
            + std::to_string(ww) + " (wall); allowed " + std::to_string(limit));
        Prepare(h, s);
        std::printf("  server distances: largest error %.2f yd to the edge (mean %.2f), %.2f yd to walls; %zu rooms, %zu tunnels from them\n",
            we, ce ? se / ce : 0.0, ww, h.rooms.size(), h.tunnels.size());

        std::vector<std::pair<int32_t, double>> rim = RimAngles(h);
        std::map<int32_t, double> angleOf(rim.begin(), rim.end());
        int32_t missing = 0;
        int32_t sweeps = DiscMap(h, [&angleOf, &missing](int32_t i)
        {
            auto it = angleOf.find(i);
            if (it == angleOf.end()) { ++missing; return std::make_pair(1.0, 0.0); }
            return std::make_pair(std::cos(it->second), std::sin(it->second));
        }, 20000, 1e-9);
        Check(missing == 0, std::to_string(missing) + " border cells without an angle from the trace");
        // fold check: every square of four cells on the disc keeps one
        // turning direction (the signed area of its two triangles)
        int32_t pos = 0, neg = 0;
        for (int32_t iy = 0; iy + 1 < h.ny; ++iy)
            for (int32_t ix = 0; ix + 1 < h.nx; ++ix)
            {
                int32_t a = iy * h.nx + ix, b = a + 1, c = a + h.nx + 1, d = a + h.nx;
                if (!h.hasDisc[a] || !h.hasDisc[b] || !h.hasDisc[c] || !h.hasDisc[d])
                    continue;
                auto area = [&h](int32_t p, int32_t q, int32_t r)
                {
                    return (h.du[q] - h.du[p]) * (h.dv[r] - h.dv[p]) - (h.du[r] - h.du[p]) * (h.dv[q] - h.dv[p]);
                };
                for (double v : { area(a, b, c), area(a, c, d) })
                {
                    if (v > 1e-15) ++pos;
                    else if (v < -1e-15) ++neg;
                }
            }
        Check(pos == 0 || neg == 0, "the disc from the traced border folds: " + std::to_string(pos) + " triangles one way, "
            + std::to_string(neg) + " the other");
        std::printf("  server disc: %zu border cells traced, %d sweeps; %d triangles, %d turned the other way (a fold)\n",
            rim.size(), sweeps, pos + neg, std::min(pos, neg));
    }
    // }}}

    std::printf("  checks passed %d, failed %d\n", sPassed, sFailed);
    return sFailed ? 1 : 0;
}
