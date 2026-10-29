// paint-check.cpp - checks the buddy module's painted map
// (roam/buddy_paint_paths.h, issue 617o8) on the same courses, with the
// same random numbers, as the page's own test (tests/paint-paths/
// paint-check.js), so the two can be read side by side. Built and run by
// scripts/test-buddy-paint-paths. Each check prints "ok" or "FAIL" and what
// it held; the exit status is the number of failures.
//
// The world is shapes (boxes and round pillars) in yards, some known before
// the bots set out (as steep ground is), the rest only when a bot bumps
// one: its step is refused and the shape's box, grown by a body, is painted
// as wall on the shared map. Bots run at 7 yards a second in steps of a
// tenth of a second.

#include "buddy_paint_paths.h"
#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <string>
#include <vector>

using namespace BuddyPaint;

static int failures = 0, checks = 0;
// {{{ check
static void check(bool ok, std::string const& what)
{
    ++checks;
    if (!ok) ++failures;
    std::printf("%s %s\n", ok ? "ok  " : "FAIL", what.c_str());
}
// }}}
// the script's fixed random sequence, number for number
struct Rng { uint32_t s; double operator()() { s = s * 1664525u + 1013904223u; return double(s) / 4294967296.0; } };
static double median(std::vector<double> a) { if (a.empty()) return NAN; std::sort(a.begin(), a.end()); return a[a.size() >> 1]; }
static double pct(std::vector<double> a, double p) { if (a.empty()) return NAN; std::sort(a.begin(), a.end()); return a[std::min(a.size() - 1, size_t(double(a.size()) * p))]; }

static double const BODY = 0.5, SPEED = 7, DT = 0.1, STEP = 1, PI = 3.14159265358979323846;

// {{{ a course
struct Shape { double box[4]; bool round, known; };
struct Course { double w, h; std::vector<Shape> shapes; double gateX = -1; };
static bool inShape(Shape const& s, double x, double y, double grow)
{
    if (s.round) { double r = (s.box[2] - s.box[0]) / 2 + grow; return std::hypot(x - (s.box[0] + s.box[2]) / 2, y - (s.box[1] + s.box[3]) / 2) <= r; }
    return x >= s.box[0] - grow && x <= s.box[2] + grow && y >= s.box[1] - grow && y <= s.box[3] + grow;
}
static double shapeDistance(Shape const& s, double x, double y)
{
    if (s.round) return std::max(0.0, std::hypot(x - (s.box[0] + s.box[2]) / 2, y - (s.box[1] + s.box[3]) / 2) - (s.box[2] - s.box[0]) / 2);
    double dx = std::max({ s.box[0] - x, 0.0, x - s.box[2] }), dy = std::max({ s.box[1] - y, 0.0, y - s.box[3] });
    return std::hypot(dx, dy);
}
static double nearest(Course const& c, double x, double y) { double d = 1e300; for (Shape const& s : c.shapes) d = std::min(d, shapeDistance(s, x, y)); return d; }
// }}}

// {{{ run: bots walk a course's trips
struct Bot { double x, y, lane = 0; std::vector<Pt> goals; double h = 0; size_t gi = 0; int trip = 0; bool hasPath = false; Path path; double jitter = 0; bool done = false; };
struct Out { std::vector<int> bumpsByTrip; int arrived = 0, stuck = 0, unfinished = 0; std::vector<double> clear, crossings; double turnDeg = 0, yards = 0, maxTurn = 0, t = 0; Map M; };
static Out run(Course const& course, std::vector<Bot> bots, int trips, Options opt, double limitS)
{
    Out out;
    out.M = Make(int(std::ceil(course.w / STEP)) + 1, int(std::ceil(course.h / STEP)) + 1, STEP, 0, 0, opt);
    Map& M = out.M;
    SetGround(M, [&](double x, double y) -> uint8_t {
        if (x < 0 || y < 0 || x > course.w || y > course.h) return Outside;
        for (Shape const& s : course.shapes) if (s.known && inShape(s, x, y, 0)) return Steep;
        return Unknown;
    });
    for (size_t i = 0; i < bots.size(); ++i) bots[i].jitter = std::fmod(double(i) * 0.37, 1.5);
    out.bumpsByTrip.assign(size_t(trips), 0);
    double t = 0, nextCrowd = 0;
    auto active = [&] { for (Bot const& b : bots) if (!b.done) return true; return false; };
    while (t < limitS && active())
    {
        if (t >= nextCrowd)
        {
            std::vector<CrowdBot> cb;
            for (Bot const& b : bots) if (!b.done) cb.push_back({ b.x, b.y, b.hasPath ? &b.path : nullptr });
            Crowd(M, cb); nextCrowd = t + 1;
        }
        for (Bot& b : bots)
        {
            if (b.done) continue;
            double gx = b.goals[b.gi].x, gy = b.goals[b.gi].y;
            if (std::hypot(gx - b.x, gy - b.y) < M.opt.ARRIVE)
            {
                ++out.arrived;
                b.gi = (b.gi + 1) % b.goals.size(); b.hasPath = false;
                if (b.gi == 0 && ++b.trip >= trips) b.done = true;
                continue;
            }
            if (NeedsPlan(M, b.hasPath ? &b.path : nullptr, gx, gy, t, b.jitter))
            {
                b.hasPath = Plan(M, b.x, b.y, gx, gy, b.path);
                if (b.hasPath) { b.path.at = t; CrowdRoute(M, b.path, b.x, b.y); }
            }
            if (!b.hasPath) { ++out.stuck; continue; }
            Pt to = Follow(M, b.path, b.x, b.y, b.lane);
            double h, share;
            Steer(M, b.x, b.y, b.h, to.x, to.y, DT, h, share);
            double turned = std::fabs(h - b.h);
            double step = SPEED * share * DT, nx = b.x + std::cos(h) * step, ny = b.y + std::sin(h) * step;
            Shape const* hit = nullptr;
            for (Shape const& s : course.shapes) if (inShape(s, nx, ny, BODY)) { hit = &s; break; }
            bool edge = !hit && (nx < 0 || ny < 0 || nx > course.w || ny > course.h);
            b.h = h;
            if (hit || edge)
            {
                ++out.bumpsByTrip[size_t(std::min(b.trip, trips - 1))];
                if (hit) { double box[4] = { hit->box[0] - BODY, hit->box[1] - BODY, hit->box[2] + BODY, hit->box[3] + BODY }; Refused(M, nx, ny, box, b.x, b.y); }
                else Refused(M, nx, ny, nullptr, b.x, b.y);
                b.hasPath = false;
                continue;
            }
            if (course.gateX >= 0 && (b.x - course.gateX) * (nx - course.gateX) <= 0 && b.x != nx) out.crossings.push_back(ny);
            b.x = nx; b.y = ny;
            Walked(M, b.x, b.y);
            out.turnDeg += turned * 180 / PI; out.yards += step; out.maxTurn = std::max(out.maxTurn, turned / DT);
            if (std::hypot(gx - b.x, gy - b.y) > M.opt.RELAX) out.clear.push_back(nearest(course, b.x, b.y));
        }
        t += DT;
    }
    out.t = t;
    for (Bot const& b : bots) if (!b.done) ++out.unfinished;
    return out;
}
// }}}

int main()
{
    char line[400];
    // {{{ 1. learning together: a field of pillars nobody knows, ten bots shuttling across it
    {
        Rng R{ 7 };
        Course c{ 120, 60, {} };
        for (int x = 40; x <= 80; x += 6) for (int y = 6; y <= 54; y += 6)
        {
            double px = x + (R() - 0.5) * 3, py = y + (R() - 0.5) * 3;
            c.shapes.push_back({ { px - 0.8, py - 0.8, px + 0.8, py + 0.8 }, true, false });
        }
        std::vector<Bot> bots;
        for (int i = 0; i < 10; ++i) { Bot b; b.x = 8; b.y = 6 + i * 5; b.lane = (i % 3) - 1; b.goals = { { 112, 54.0 - i * 5 }, { 8, 6.0 + i * 5 } }; bots.push_back(b); }
        Out r = run(c, bots, 6, {}, 900);
        int first = r.bumpsByTrip[0], last = r.bumpsByTrip[4] + r.bumpsByTrip[5];
        std::printf("     pillars: bumps by round of trips %d, %d, %d, %d, %d, %d; %d wall cells painted, %.0f%% of the ground painted; %u plans, %.2f ms a plan; %.0f s\n",
            r.bumpsByTrip[0], r.bumpsByTrip[1], r.bumpsByTrip[2], r.bumpsByTrip[3], r.bumpsByTrip[4], r.bumpsByTrip[5], r.M.wallCells,
            100.0 * r.M.painted / std::max(1, r.M.inside), r.M.stats.plans, r.M.stats.ms / std::max(1u, r.M.stats.plans), r.t);
        std::snprintf(line, sizeof line, "pillars: all ten bots finish six round trips (%d arrivals, %d steps with no way)", r.arrived, r.stuck);
        check(r.unfinished == 0 && r.stuck == 0, line);
        std::snprintf(line, sizeof line, "pillars: the first round bumps into the unknown pillars (%d bumps)", first);
        check(first > 0, line);
        std::snprintf(line, sizeof line, "pillars: the last two rounds together bump far less than the first: the map was learned together (%d against %d)", last, first);
        check(last <= first * 0.15, line);
        double tpy = r.turnDeg / r.yards;
        std::printf("     pillars: %.1f degrees turned a yard walked; the most in a step %.0f degrees a second\n", tpy, r.maxTurn * 180 / PI);
        std::snprintf(line, sizeof line, "pillars: no bot turns faster than the limit (%.0f of %.0f degrees a second)", r.maxTurn * 180 / PI, r.M.opt.TURN * 180 / PI);
        check(r.maxTurn <= r.M.opt.TURN + 1e-6, line);
        std::snprintf(line, sizeof line, "pillars: smooth walking: under 8 degrees turned a yard (%.1f)", tpy);
        check(tpy < 8, line);
        // keeping the paint: the learned field saved, loaded into a fresh map
        // of the same size and place, comes back the same, clearance worked
        // out again included; a map of another size refuses it
        std::vector<uint8_t> bytes = Save(r.M);
        Map fresh = Make(r.M.w, r.M.h, r.M.step, r.M.x0, r.M.y0);
        bool loaded = Load(fresh, bytes);
        bool same = loaded && fresh.know == r.M.know && fresh.walks == r.M.walks && fresh.clear == r.M.clear &&
                    fresh.painted == r.M.painted && fresh.wallCells == r.M.wallCells;
        std::snprintf(line, sizeof line, "keeping the paint: the learned field (%zu bytes) saved and loaded comes back cell for cell, clearance and all", bytes.size());
        check(same, line);
        Map other = Make(r.M.w + 1, r.M.h, r.M.step, r.M.x0, r.M.y0);
        check(!Load(other, bytes) && other.wallCells == 0, "keeping the paint: a map of another size refuses it, untouched");
    }
    // }}}
    // {{{ 2. space from walls: a known wall with a 16-yard gap
    {
        Course c{ 120, 60, { { { 58, 0, 62, 36 }, false, true }, { { 58, 52, 62, 60 }, false, true } } };
        auto mk = [] { std::vector<Bot> b(3); b[0].x = 10; b[0].y = 8; b[0].goals = { { 110, 10 } }; b[1].x = 10; b[1].y = 50; b[1].goals = { { 110, 52 } }; b[2].x = 10; b[2].y = 30; b[2].goals = { { 110, 30 } }; return b; };
        Options tightOpt; tightOpt.WANT = 0.01; tightOpt.WALL_W = 0;
        Out spaced = run(c, mk(), 1, {}, 120), tight = run(c, mk(), 1, tightOpt, 120);
        double ls = pct(spaced.clear, 0.05), lt = pct(tight.clear, 0.05);
        std::printf("     wall and gap: yards to the nearest wall, median %.1f (no space wanted: %.1f); the closest 5%%: %.1f (%.1f)\n", median(spaced.clear), median(tight.clear), ls, lt);
        check(spaced.unfinished == 0, "wall and gap: every bot gets through the gap");
        std::snprintf(line, sizeof line, "wall and gap: bots keep their space through the gap: the closest 5%% of steps at least 2.5 yards from the wall (%.1f; without space wanted %.1f)", ls, lt);
        check(ls >= 2.5 && ls > lt + 0.5, line);
    }
    // }}}
    // {{{ 3. less space near the goal
    {
        Course c{ 80, 60, { { { 40, 10, 44, 50 }, false, true } } };
        std::vector<Bot> one(1); one[0].x = 10; one[0].y = 30; one[0].goals = { { 38.5, 30 } };
        Out r = run(c, one, 1, {}, 60);
        std::snprintf(line, sizeof line, "goal against a wall: the bot reaches a goal 1.5 yards from the wall's face (arrived %d)", r.arrived);
        check(r.unfinished == 0, line);
        Course thin{ 80, 60, { { { 39.5, 0, 40.5, 40 }, false, true } } };
        auto across = [&](bool relaxNear) {
            std::vector<Bot> b(1); b[0].x = 34; b[0].y = 20; b[0].goals = { { 46, 20 } };
            Options o; o.RELAX = 0.001; if (!relaxNear) o.NEAR = 0.001;
            return run(thin, b, 1, o, 60);
        };
        Out nearR = across(true), wideR = across(false);
        double cn = *std::min_element(nearR.clear.begin(), nearR.clear.end()), cw = *std::min_element(wideR.clear.begin(), wideR.clear.end());
        std::printf("     across a thin wall: walked %.1f yards, nearest the wall %.1f (full space all the way: %.1f yards, nearest %.1f; the shortest round: %.1f)\n",
            nearR.yards, cn, wideR.yards, cw, 2 * std::hypot(6, 20.5));
        std::snprintf(line, sizeof line, "across a thin wall: with the goal just across, the bot rounds the wall's end closer and shorter than keeping full space (%.1f against %.1f yards from the wall)", cn, cw);
        check(nearR.unfinished == 0 && cn < cw - 0.5 && nearR.yards < wideR.yards, line);
    }
    // }}}
    // {{{ 4. spreading: a dozen bots leaving in one knot, to one goal through a 20-yard gap
    {
        Course c{ 100, 60, { { { 48, 0, 52, 20 }, false, true }, { { 48, 40, 52, 60 }, false, true } } };
        c.gateX = 50;
        auto mk = [](bool lanes) { std::vector<Bot> b(12); for (int i = 0; i < 12; ++i) { b[size_t(i)].x = 8 + (i % 3) * 0.7; b[size_t(i)].y = 29 + (i / 3) * 0.7; b[size_t(i)].lane = lanes ? ((i * 7) % 12) / 5.5 - 1 : 0; b[size_t(i)].goals = { { 92, 30 } }; } return b; };
        Options single; single.CROWD_W = 0; single.LANE = 0;
        Out spread = run(c, mk(true), 1, {}, 60), file = run(c, mk(false), 1, single, 60);
        auto sd = [](std::vector<double> const& a) { double m = 0; for (double v : a) m += v; m /= double(a.size()); double s = 0; for (double v : a) s += (v - m) * (v - m); return std::sqrt(s / double(a.size())); };
        double ss = sd(spread.crossings), s1 = sd(file.crossings);
        std::printf("     gap for a dozen: spread across the gap (standard deviation) %.1f yards with lanes and the crowd, %.1f without\n", ss, s1);
        check(spread.unfinished == 0, "gap for a dozen: all twelve arrive");
        std::snprintf(line, sizeof line, "gap for a dozen: leaving in one knot, lanes and the crowd spread them across the gap (%.1f yards against %.1f single file)", ss, s1);
        check(ss >= 2.5 && ss >= s1 * 2, line);
    }
    // }}}
    // {{{ 5. planning: 500 by 500 one-yard cells, known blobs, 300 plans between random open points
    {
        Rng R{ 11 };
        Map M = Make(500, 500, 1, 0, 0, {});
        std::vector<std::array<double, 3>> blobs;
        for (int i = 0; i < 160; ++i) { double bx = R() * 500, by = R() * 500, br = 4 + R() * 18; blobs.push_back({ bx, by, br }); }
        SetGround(M, [&](double x, double y) -> uint8_t { for (auto const& b : blobs) if (std::hypot(x - b[0], y - b[1]) < b[2]) return Steep; return Unknown; });
        std::vector<double> times; int found = 0;
        for (int i = 0; i < 300; ++i)
        {
            double sx, sy, gx, gy;
            do { sx = R() * 500; sy = R() * 500; } while (Blocks(M.know[size_t(CellOf(M, sx, sy))]));
            do { gx = R() * 500; gy = R() * 500; } while (Blocks(M.know[size_t(CellOf(M, gx, gy))]));
            Path p;
            auto t0 = std::chrono::steady_clock::now();
            bool ok = Plan(M, sx, sy, gx, gy, p);
            times.push_back(std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count());
            if (ok) ++found;
        }
        double md = median(times), p95 = pct(times, 0.95);
        std::printf("     planning: 300 plans over 250,000 cells (a yard each): median %.2f ms, 95%% under %.2f ms, %d found a way; %.0f cells opened a plan\n",
            md, p95, found, double(M.stats.expanded) / 300);
        std::snprintf(line, sizeof line, "planning: a plan across 500 yards takes under 25 ms in the middle case (%.2f ms)", md);
        check(md < 25, line);
    }
    // }}}
    std::printf("%d of %d checks held\n", checks - failures, checks);
    return failures;
}
