
#include "buddy_path_ways.h"
#include <cstdio>
#include <string>

using namespace BuddyPath;

static int failures = 0, checks = 0;

static void check(bool ok, std::string const& what)
{
    ++checks;
    if (!ok)
        ++failures;
    std::printf("%s %s\n", ok ? "ok  " : "FAIL", what.c_str());
}

static constexpr int   CELLS = 40;
static constexpr float STEP  = 2.0f, DT = 0.5f, SPEED = 7.0f, ARRIVED = 3.0f;
static constexpr int   LIMIT = 1200;

static Grid Open()
{
    Grid g;
    g.w = g.h = CELLS; g.step = STEP;
    g.open.assign(size_t(CELLS * CELLS), 1);
    g.learned.assign(size_t(CELLS * CELLS), 0);
    return g;
}
static void Wall(Grid& g, int c0, int r0, int c1, int r1)
{
    for (int r = r0; r <= r1; ++r)
        for (int c = c0; c <= c1; ++c)
            g.open[size_t(r * g.w + c)] = 0;
}

struct Run { int steps = 0, refused = 0, firstStep = -1; P firstAt, firstTo, lastAt; Walker w; };
static Run Walk(Grid g, Way way, P at, P target)
{
    Run run;
    run.w.Reset(way);
    float now = 0;
    for (; run.steps <= LIMIT; ++run.steps, now += DT)
    {
        run.lastAt = at;
        if (std::hypot(target.x - at.x, target.y - at.y) < ARRIVED) return run;
        P to = run.w.Next(g, at, target, now, SPEED);
        P moved = Walker::Toward(at, to, SPEED * DT), last = at;
        float d = std::hypot(moved.x - at.x, moved.y - at.y);
        int n = std::max(1, int(d / 0.25f));
        bool short_ = false;
        for (int i = 1; i <= n; ++i)
        {
            P p { at.x + (moved.x - at.x) * float(i) / float(n), at.y + (moved.y - at.y) * float(i) / float(n) };
            int q = g.Cell(p);
            if (q < 0 || !g.open[size_t(q)]) { short_ = true; break; }
            last = p;
        }
        if (short_)
        {
            if (run.refused++ == 0) { run.firstStep = run.steps; run.firstAt = at; run.firstTo = to; }
            run.w.Fell(g, last, to);
        }
        at = last;
    }
    return run;
}

int main()
{
    {
        bool ok = true;
        for (Way w : { Way::Orbit, Way::Flow, Way::AStar, Way::Potential, Way::Learn })
        {
            Way back;
            ok = ok && WayFromName(WayName(w), back) && back == w;
        }
        Way none;
        check(ok, "each way's name gives the way back");
        check(!WayFromName("teleport", none), "a name that is no way is refused, not taken as orbit");
    }

    check(Stuck(1.0f, 7.0f, 30.0f),  "a second's order, 7 yards walkable, 1 closer: stuck");
    check(!Stuck(5.0f, 7.0f, 30.0f), "5 of 7 closer: not stuck");
    check(!Stuck(0.0f, 7.0f,  4.0f), "not moving but within 6 yards of the point: arrived, not stuck");
    {
        Backing b;
        P at { 10, 10 }, target { 50, 10 };
        float a = b.StuckAt(at, target), c = b.StuckAt(at, target), e = b.StuckAt(at, target);
        check(a == 2.0f && c == 4.0f && e == 8.0f, "backing out: 2, then 4, then 8 yards");
        for (int k = 0; k < 10; ++k) b.StuckAt(at, target);
        check(b.next == BACK_MAX, "backing out stops doubling at 64 yards");
        check(!b.Relax({ 10.5f, 10 }), "half a yard past the forwardmost stuck spot: still doubling");
        check(b.Relax({ 12.0f, 10 }) && b.next == BACK_FIRST, "two yards past it: back to 2 yards");
    }

    {
        Grid g = Open();
        Wall(g, 20, 0, 20, 30);
        int from = g.Cell({ 10, 20 }), to = g.Cell({ 70, 20 });
        std::vector<int> r = AStar(g, from, to, false);
        bool clear = !r.empty();
        for (int q : r) clear = clear && g.open[size_t(q)];
        check(clear, "A*: a route round the wall, every cell of it open");
        check(!r.empty() && r.front() == from && r.back() == to, "A*: the route runs from the start's cell to the target's");
        std::vector<float> f = FlowField(g, to);
        check(std::isfinite(f[size_t(from)]) && f[size_t(from)] > 30.0f, "flow: the start can reach the target, and further than the 30 cells straight across");
        check(std::fabs(f[size_t(from)] - [&] { float s = 0; for (size_t i = 1; i < r.size(); ++i) { int a = r[i - 1], b = r[i]; s += (a % g.w != b % g.w && a / g.w != b / g.w) ? 1.414f : 1.0f; } return s; }()) < 0.01f,
              "flow and A* agree on the route's length");
        Grid sealed = Open();
        Wall(sealed, 20, 0, 20, CELLS - 1);
        check(AStar(sealed, from, to, false).empty(), "A*: a wall from edge to edge, no route");
        check(!std::isfinite(FlowField(sealed, to)[size_t(from)]), "flow: a wall from edge to edge, unreachable");
        Grid l = Open();
        check(Learn(l, { 10, 10 }, { 12, 10 }) && l.learned[size_t(l.Cell({ 12, 10 }))], "learn: the cell a short step was going into is learned");
        check(!Learn(l, { 10, 10 }, { 12, 10 }), "learn: the same cell twice is nothing new");
    }

    Grid wall = Open();
    Wall(wall, 20, 0, 20, 30);
    Grid pocket = Open();
    Wall(pocket, 22, 8, 22, 32); Wall(pocket, 12, 8, 21, 8); Wall(pocket, 12, 32, 21, 32);
    struct Course { char const* name; Grid const* g; P from, to; };
    Grid grove = Open();
    for (int c = 6; c <= 34; c += 4)
        for (int r = (c / 4) % 2 ? 4 : 6; r <= 36; r += 4)
            Wall(grove, c, r, c, r);
    Course const courses[] = { { "the wall", &wall, { 10, 20 }, { 70, 20 } }, { "the pocket", &pocket, { 30, 40 }, { 70, 40 } },
                               { "the grove", &grove, { 4, 41 }, { 76, 39 } } };
    for (Course const& c : courses)
        for (Way w : { Way::Orbit, Way::Flow, Way::AStar, Way::Potential, Way::Learn })
        {
            Run run = Walk(*c.g, w, c.from, c.to);
            char line[200];
            std::snprintf(line, sizeof line, "%-9s over %-10s: %s in %4d steps (%3d refused, %2d stuck, %2d orbits, %2d kicks, %3d plans)",
                          WayName(w), c.name, run.steps <= LIMIT ? "arrived" : "never arrived", run.steps,
                          run.refused, run.w.stuckCount, run.w.orbitCount, run.w.kickCount, run.w.replanCount);
            bool knownLimit = w == Way::Potential && c.g != &grove;
            if (knownLimit)
                check(run.steps > LIMIT, std::string(line) + "  (known limit: trapped, as expected)");
            else
                check(run.steps <= LIMIT, line);
            if ((!knownLimit && run.steps > LIMIT) || ((w == Way::Flow || w == Way::AStar) && run.refused > 0))
                std::printf("       first refused at step %d, at (%.1f, %.1f) headed for (%.1f, %.1f); at the end at (%.1f, %.1f)\n",
                            run.firstStep, run.firstAt.x, run.firstAt.y, run.firstTo.x, run.firstTo.y, run.lastAt.x, run.lastAt.y);
            if (w == Way::Flow || w == Way::AStar)
                check(run.refused == 0, std::string(WayName(w)) + " over " + c.name + ": never walks into a wall");
        }

    std::printf("%d of %d checks held\n", checks - failures, checks);
    return failures;
}
