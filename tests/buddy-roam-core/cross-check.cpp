/*
 * cross-check.cpp - runs the C++ roaming core on the drawn maps, for the
 * test that holds it to the Lua model (issue 617e2).
 *
 * For a general audience: the roaming design was settled on a Lua model
 * (src/lua-basic/lib/buddy-roam.lua) and then written again in C++ for the
 * server (modules/mod-buddies/src/roam/). This program makes a few thousand
 * test situations on the two drawn maps of the animations (a buddy standing
 * somewhere, the others near it, where its last waypoint left its distance
 * number, the random numbers it will draw), writes them out so the Lua
 * model can be run on exactly the same, and writes what the C++ core
 * answered. The Lua side (lua-driver.lua) then answers the same situations
 * and compares. scripts/test-buddy-roam-core runs the lot.
 *
 * Usage: cross-check <maps.txt> <cases.txt> <cpp-results.txt> <cases per map>
 *   maps.txt  written by lua-driver.lua (the one description of the maps)
 *
 * The situations are drawn from a fixed-seed generator, so every run makes
 * the same ones. The core's random numbers come from a recorded list per
 * situation, written into cases.txt, so both sides consume the very same
 * numbers; how many each side consumed is compared too, which catches a
 * port that draws them in another order.
 */

#include "buddy_roam_core.h"

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

using namespace BuddyRoam;

// {{{ Lcg
// The gallery's generator, in exact integer arithmetic:
// s = (s * 1103515245 + 12345) mod 2^31, r = s / 2^31.
struct Lcg
{
    uint64_t s;
    explicit Lcg(uint64_t seed) : s(seed) { }
    double operator()()
    {
        s = (s * 1103515245ULL + 12345ULL) % 2147483648ULL;
        return double(s) / 2147483648.0;
    }
};
// }}}

// {{{ DrawnMap
// One drawn map as maps.txt gives it.
struct DrawnMap
{
    std::string name;
    double cx = 0, cy = 0;
    std::vector<double> outline;   // x, y, x, y, ...
    std::vector<double> walls;     // x, y, radius, tall, ...
    std::vector<double> hills;     // x, y, height, spread, ...
    std::vector<double> mobs;      // x, y, aggro radius, ... (the monster nudge)
};
// }}}

// {{{ ReadMaps
static std::vector<DrawnMap> ReadMaps(char const* path)
{
    std::ifstream in(path);
    if (!in)
    {
        std::fprintf(stderr, "cross-check: can't read the maps file %s (written by lua-driver.lua dump)\n", path);
        std::exit(2);
    }
    std::vector<DrawnMap> maps;
    std::string word;
    while (in >> word)
    {
        if (word == "map")
        {
            maps.emplace_back();
            in >> maps.back().name >> maps.back().cx >> maps.back().cy;
            continue;
        }
        size_t n, per = word == "outline" ? 2 : word == "mobs" ? 3 : 4;
        in >> n;
        std::vector<double>& into = word == "outline" ? maps.back().outline : word == "walls" ? maps.back().walls
                                  : word == "mobs" ? maps.back().mobs : maps.back().hills;
        into.resize(n * per);
        for (double& v : into)
            in >> v;
    }
    return maps;
}
// }}}

// {{{ the drawn map's ground (the Lua model's geometry, exactly)
static bool InsidePolygon(std::vector<double> const& o, double x, double y)
{
    bool inside = false;
    size_t n = o.size() / 2, j = n - 1;
    for (size_t i = 0; i < n; ++i)
    {
        double xi = o[2 * i], yi = o[2 * i + 1], xj = o[2 * j], yj = o[2 * j + 1];
        if (((yi > y) != (yj > y)) && x < (xj - xi) * (y - yi) / (yj - yi) + xi)
            inside = !inside;
        j = i;
    }
    return inside;
}

static double EdgeDistance(std::vector<double> const& o, double x, double y)
{
    double best = HUGE_VAL;
    size_t n = o.size() / 2;
    for (size_t i = 0; i < n; ++i)
    {
        size_t j = (i + 1) % n;
        double ax = o[2 * i], ay = o[2 * i + 1], bx = o[2 * j], by = o[2 * j + 1];
        double vx = bx - ax, vy = by - ay;
        double t = ((x - ax) * vx + (y - ay) * vy) / (vx * vx + vy * vy);
        t = std::max(0.0, std::min(1.0, t));
        double d = std::sqrt((ax + vx * t - x) * (ax + vx * t - x) + (ay + vy * t - y) * (ay + vy * t - y));
        if (d < best)
            best = d;
    }
    return best;
}

static double RayToEdge(std::vector<double> const& o, double cx, double cy, double a)
{
    double dx = std::cos(a), dy = std::sin(a), best = HUGE_VAL;
    size_t n = o.size() / 2;
    for (size_t i = 0; i < n; ++i)
    {
        size_t j = (i + 1) % n;
        double ax = o[2 * i], ay = o[2 * i + 1];
        double ex = o[2 * j] - ax, ey = o[2 * j + 1] - ay;
        double den = dx * ey - dy * ex;
        if (std::fabs(den) > 1e-9)
        {
            double t = ((ax - cx) * ey - (ay - cy) * ex) / den;
            double u = ((ax - cx) * dy - (ay - cy) * dx) / den;
            if (t > 0 && u >= 0 && u <= 1 && t < best)
                best = t;
        }
    }
    return best;
}

static Ground MakeGround(DrawnMap const& m)
{
    Ground g;
    g.height = [&m](float x, float y, float /*zHint*/)
    {
        double h = 0.0;
        for (size_t i = 0; i + 3 < m.hills.size(); i += 4)
        {
            double hx = m.hills[i], hy = m.hills[i + 1], hh = m.hills[i + 2], sp = m.hills[i + 3];
            h = h + hh * std::exp(-((x - hx) * (x - hx) + (y - hy) * (y - hy)) / (2 * sp * sp));
        }
        double top = 0.0;
        for (size_t i = 0; i < m.walls.size(); i += 4)
            if ((x - m.walls[i]) * (x - m.walls[i]) + (y - m.walls[i + 1]) * (y - m.walls[i + 1]) < m.walls[i + 2] * m.walls[i + 2])
                top = std::max(top, m.walls[i + 3]);
        return float(h + top);
    };
    g.clear = [&m](float x, float y, float /*z*/, float clearance)
    {
        if (!InsidePolygon(m.outline, x, y))
            return false;
        for (size_t i = 0; i < m.walls.size(); i += 4)
        {
            double dx = x - m.walls[i], dy = y - m.walls[i + 1], r = m.walls[i + 2] + clearance;
            if (dx * dx + dy * dy < r * r)
                return false;
        }
        return EdgeDistance(m.outline, x, y) >= clearance;
    };
    g.edgeAlong = [&m](float cx, float cy, float /*cz*/, float bearing)
    {
        return float(RayToEdge(m.outline, cx, cy, bearing));
    };
    // The Lua model's seen_through tests every yard between the ends; the
    // end itself is tested too, as the model's obstacle test does for each
    // test point (both ends of a waypoint trip are inside the area anyway).
    g.seenThrough = [&m](Point const& a, Point const& b)
    {
        double len = std::sqrt(double(b.x - a.x) * (b.x - a.x) + double(b.y - a.y) * (b.y - a.y));
        int n = std::max(1, int(std::ceil(len)));
        for (int i = 1; i < n; ++i)
        {
            double k = double(i) / n;
            if (!InsidePolygon(m.outline, a.x + (b.x - a.x) * k, a.y + (b.y - a.y) * k))
                return false;
        }
        return InsidePolygon(m.outline, b.x, b.y);
    };
    return g;
}
// }}}

// {{{ output helpers
static std::string F(double v)
{
    char buf[40];
    std::snprintf(buf, sizeof(buf), "%.17g", v);
    return buf;
}
static float ToFloat(double v) { return float(v); }

// A path's walking cost, from its points alone (x, y and the ground height
// in z): the Lua model's cost without roads. Written beside every path so
// the comparison can tell an equally cheap mirror-image choice (the left
// bow against the right one on flat ground) from a different answer.
static double Cost(std::vector<Point> const& path, Settings const& settings)
{
    double cost = 0.0;
    for (size_t i = 1; i < path.size(); ++i)
    {
        double dx = double(path[i].x) - path[i - 1].x, dy = double(path[i].y) - path[i - 1].y;
        double ds = std::sqrt(dx * dx + dy * dy);
        double grade = ds > 0.0 ? (double(path[i].z) - path[i - 1].z) / ds : 0.0;
        cost += ds * (1.0 + settings.slopeWeight * grade * grade);
    }
    return cost;
}
// }}}

// {{{ a recorded random list
// The numbers a situation may draw; `used` counts how many it did.
struct Recorded
{
    std::vector<double> list;
    size_t used = 0;
    bool exhausted = false;
    double Next()
    {
        if (used >= list.size())
        {
            exhausted = true;          // reported as a failure of the test's sizing, not hidden
            return 0.0;
        }
        return list[used++];
    }
};
// }}}

// {{{ RandomClear
// A random place clear of obstacles by 2 yards (as the gallery places
// buddies), as floats.
static Point RandomClear(Ground const& g, Lcg& gen)
{
    for (;;)
    {
        double x = 2.0 + gen() * 122.0, y = 4.0 + gen() * 90.0;
        if (g.clear(ToFloat(x), ToFloat(y), 0.0f, 2.0f))
            return { ToFloat(x), ToFloat(y), g.height(ToFloat(x), ToFloat(y), 0.0f) };
    }
}
// }}}

int main(int argc, char** argv)
{
    if (argc != 5)
    {
        std::fprintf(stderr, "usage: cross-check <maps.txt> <cases.txt> <cpp-results.txt> <cases per map>\n");
        return 2;
    }
    std::vector<DrawnMap> maps = ReadMaps(argv[1]);
    int perMap = std::atoi(argv[4]);
    std::ofstream cases(argv[2]), results(argv[3]);
    Settings settings;
    cases << "settings turn " << F(settings.turn) << "\n";

    static float const BODIES[] = { 0.61f, 0.69f, 0.78f, 1.95f };
    int id = 0;
    for (DrawnMap const& m : maps)
    {
        Ground g = MakeGround(m);
        Area area;
        area.id = 1;
        area.centre = { ToFloat(m.cx), ToFloat(m.cy), 0.0f };
        area.centre.z = g.height(area.centre.x, area.centre.y, 0.0f);

        // the map's monsters, for the nudge
        std::vector<Mob> mobs;
        for (size_t i = 0; i + 2 < m.mobs.size(); i += 3)
        {
            Mob mob;
            mob.at = { ToFloat(m.mobs[i]), ToFloat(m.mobs[i + 1]), 0.0f };
            mob.at.z = g.height(mob.at.x, mob.at.y, 0.0f);
            mob.aggro = ToFloat(m.mobs[i + 2]);
            mobs.push_back(mob);
        }

        // {{{ waypoint situations
        // Two sets: the first as before (piercing off, no monsters); the
        // second with piercing on (25) and the map's monsters, and Y and the
        // inward count drawn so crossings happen often (a low Y, one or two
        // inward rolls already carried).
        for (int set = 0; set < 2; ++set)
        for (int c = 0; c < perMap; ++c, ++id)
        {
            bool rules = set == 1;
            Settings caseSettings = settings;
            caseSettings.piercePercent = rules ? 25 : 0;
            std::vector<Mob> const& caseMobs = rules ? mobs : std::vector<Mob>();
            Lcg gen(uint64_t(id) * 7919ULL + 1ULL);
            Point at = RandomClear(g, gen);
            Buddy b;
            b.spin        = gen() < 0.5 ? 1 : -1;
            b.angle       = ToFloat(std::atan2(double(at.y) - area.centre.y, double(at.x) - area.centre.x));
            b.hasWaypoint = gen() < 0.8;
            b.yPercent    = b.hasWaypoint ? 1 + int32_t(std::floor(gen() * (rules ? 45.0 : 100.0))) : 0;
            b.body        = BODIES[int(std::floor(gen() * 4.0))];
            b.inward      = rules ? int32_t(std::floor(gen() * 3.0)) : 0;

            // others: some anywhere, some placed near where the Y rule is
            // likely to land, so the crowding rule is exercised
            std::vector<Point> others;
            int nOthers = int(std::floor(gen() * 4.0));
            for (int k = 0; k < nOthers; ++k)
            {
                if (gen() < 0.5)
                {
                    others.push_back(RandomClear(g, gen));
                    continue;
                }
                double bearing = double(b.angle) + double(settings.turn) * b.spin;
                double reach = double(g.edgeAlong(area.centre.x, area.centre.y, 0.0f, ToFloat(bearing))) - settings.clearance;
                double d = std::max(double(settings.nearYards), (b.hasWaypoint ? b.yPercent : 50) / 100.0 * reach);
                double x = area.centre.x + std::cos(bearing) * d + (gen() - 0.5) * 8.0;
                double y = area.centre.y + std::sin(bearing) * d + (gen() - 0.5) * 8.0;
                others.push_back({ ToFloat(x), ToFloat(y), 0.0f });
            }

            Recorded rec;
            Lcg rgen(uint64_t(id) * 104729ULL + 17ULL);
            for (int k = 0; k < 256; ++k)
                rec.list.push_back(rgen());

            cases << "wp " << id << " " << m.name << " " << F(at.x) << " " << F(at.y) << " " << b.spin << " " << F(b.angle)
                  << " " << (b.hasWaypoint ? 1 : 0) << " " << b.yPercent << " " << F(b.body)
                  << " " << b.inward << " " << caseSettings.piercePercent << " " << (rules ? 1 : 0) << " " << others.size();
            for (Point const& o : others)
                cases << " " << F(o.x) << " " << F(o.y);
            cases << " " << rec.list.size();
            for (double r : rec.list)
                cases << " " << F(r);
            cases << "\n";

            Rng rng = [&rec]() { return rec.Next(); };
            bool ok = NextWaypoint(b, area, at, others, caseMobs, g, caseSettings, rng);
            results << "wp " << id << " " << (rec.exhausted ? "exhausted" : ok ? "ok" : "fail");
            if (ok)
            {
                results << " " << F(b.waypoint.x) << " " << F(b.waypoint.y) << " " << F(b.angle) << " " << b.yPercent
                        << " " << b.crowdMoves << " " << rec.used
                        << " " << b.spin << " " << b.inward << " " << b.pierced << " " << (b.lured ? 1 : 0)
                        << " " << F(b.lured ? b.lurePoint.x : 0.0) << " " << F(b.lured ? b.lurePoint.y : 0.0)
                        << " " << F(Cost(b.path, settings)) << " " << b.path.size();
                for (Point const& p : b.path)
                    results << " " << F(p.x) << " " << F(p.y);
            }
            results << "\n";
        }
        // }}}

        // {{{ planner situations
        for (int c = 0; c < perMap; ++c, ++id)
        {
            // only trips whose ends see each other: the core plans no other
            // kind (a walled way goes by a turning point, two legs in sight)
            Lcg gen(uint64_t(id) * 6007ULL + 3ULL);
            Point a = RandomClear(g, gen), z = RandomClear(g, gen);
            while (!g.seenThrough(a, z))
                z = RandomClear(g, gen);
            float body = BODIES[int(std::floor(gen() * 4.0))];
            cases << "plan " << id << " " << m.name << " " << F(a.x) << " " << F(a.y) << " " << F(z.x) << " " << F(z.y) << " " << F(body) << "\n";
            std::vector<Point> path = PlanPath(a, z, body, g, settings);
            results << "plan " << id << " " << (path.empty() ? "fail" : "ok");
            if (!path.empty())
            {
                results << " " << F(Cost(path, settings)) << " " << path.size();
                for (Point const& p : path)
                    results << " " << F(p.x) << " " << F(p.y);
            }
            results << "\n";
        }
        // }}}

        // {{{ beginning, and the rest chance
        for (int c = 0; c < 20; ++c, ++id)
        {
            Lcg gen(uint64_t(id) * 31ULL + 5ULL);
            Point at = RandomClear(g, gen);
            Recorded rec;
            rec.list.push_back(gen());
            cases << "begin " << id << " " << m.name << " " << F(at.x) << " " << F(at.y) << " 1 " << F(rec.list[0]) << "\n";
            Buddy b;
            Rng rng = [&rec]() { return rec.Next(); };
            Begin(b, area, at, rng);
            results << "begin " << id << " ok " << b.spin << " " << F(b.angle) << " " << rec.used << "\n";

            float health = ToFloat(gen() * 5000.0), maxHealth = ToFloat(5000.0 + gen() * 5000.0);
            cases << "rest " << id << " " << F(health) << " " << F(maxHealth) << "\n";
            results << "rest " << id << " ok " << F(RestChance(health, maxHealth)) << "\n";
        }
        // }}}
    }
    return 0;
}
