/*
 * buddy_path_ways.h - five ways for a buddy to find its way to a point
 * (issue 617o7). No server code, so scripts/test-buddy-path-ways checks it
 * alone with the system compiler; the server side (buddies_path.cpp) fills
 * the grid from the navigation mesh, asks the chosen way for the next point,
 * and walks the buddy there.
 *
 * For a general audience, the owner, 2026-10-28: "create at least 3-5
 * radically different pathfinding solutions with equivalent levels of
 * complexity? then, make sure that all of them are viewable in-game. I want
 * to test them myself." The same five as the ground sandbox's
 * (docs/HTML/ground-sandbox.html, "Pathfinding"):
 *   orbit      straight at the point; not getting closer as fast as it could
 *              (the stuck check), back out (twice as far each time, until past
 *              the forwardmost stuck spot) and walk round what blocks, keeping
 *              it on one side, until the point is in sight;
 *   flow       a flow field: the walking distance to the point spread over the
 *              grid once (cheapest-first), each step downhill on it;
 *   astar      a whole route by A* over the grid, pulled tight (the farthest
 *              point of it in a clear line is steered to);
 *   potential  no route: the point pulls, blocked cells near push, a kick in a
 *              random direction when it barely moves;
 *   learn      A* over what the buddy has learned blocks (everything else
 *              taken as open); a step that falls short teaches the cell ahead.
 *
 * The grid: square cells STEP yards apart over a box round the buddy and its
 * point; a cell is open or not (the server asks the mesh: a point snapped
 * onto it within reach, and a clear line from its neighbours). Cells are
 * numbered row by row: q = r * w + c.
 */

#ifndef BUDDY_PATH_WAYS_H
#define BUDDY_PATH_WAYS_H

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <functional>
#include <limits>
#include <queue>
#include <string>
#include <vector>

namespace BuddyPath
{
    struct P { float x = 0, y = 0; };

    enum class Way : uint8_t { Orbit, Flow, AStar, Potential, Learn };

    // {{{ the way's name and back
    inline char const* WayName(Way w)
    {
        switch (w) { case Way::Orbit: return "orbit"; case Way::Flow: return "flow"; case Way::AStar: return "astar";
                     case Way::Potential: return "potential"; case Way::Learn: return "learn"; }
        return "orbit";
    }
    // false when `name` is no way (the caller says so; nothing is assumed)
    inline bool WayFromName(std::string const& name, Way& out)
    {
        for (Way w : { Way::Orbit, Way::Flow, Way::AStar, Way::Potential, Way::Learn })
            if (name == WayName(w)) { out = w; return true; }
        return false;
    }
    // }}}

    // {{{ Grid
    // open: 1 walkable, 0 not (from the mesh); learned: 1 where the buddy has
    // learned it blocks (the "learn" way plans by this alone).
    struct Grid
    {
        int w = 0, h = 0;
        float x0 = 0, y0 = 0, step = 4;
        std::vector<uint8_t> open, learned;
        int Cell(P p) const
        {
            int c = int(std::lround((p.x - x0) / step)), r = int(std::lround((p.y - y0) / step));
            return c < 0 || r < 0 || c >= w || r >= h ? -1 : r * w + c;
        }
        P Centre(int q) const { int col = q % w, row = q / w; return { x0 + float(col) * step, y0 + float(row) * step }; }
        bool Passable(int q, bool learnedOnly) const { return learnedOnly ? !learned[q] : open[q] != 0; }
    };
    // the eight neighbours of q that `pass` lets through, each with its
    // step's cost (1, or 1.414 diagonally). A diagonal step needs both cells
    // beside it passable too: otherwise it slips through the corner of a
    // wall's end, which the world refuses (the offline test's first run,
    // 2026-10-28: the flow way stood at a wall's end for ten minutes).
    template <class Pass, class F> inline void Neighbours(Grid const& g, int q, Pass pass, F fn)
    {
        static int const dc[8] = { 1, -1, 0, 0, 1, 1, -1, -1 }, dr[8] = { 0, 0, 1, -1, 1, -1, 1, -1 };
        int c = q % g.w, r = q / g.w;
        for (int k = 0; k < 8; ++k)
        {
            int nc = c + dc[k], nr = r + dr[k];
            if (nc < 0 || nr < 0 || nc >= g.w || nr >= g.h || !pass(nr * g.w + nc)) continue;
            if (k >= 4 && (!pass(r * g.w + nc) || !pass(nr * g.w + c))) continue;
            fn(nr * g.w + nc, k < 4 ? 1.0f : 1.414f);
        }
    }
    // a clear line over the grid from a to b: every cell the line passes
    // through is passable, the one it starts in aside (the buddy stands
    // there, perhaps half over a wall's edge). Walked cell by cell, crossing
    // whichever cell border comes first along the line (a cell spans half a
    // step either side of its centre). Sampled points, at first every half
    // step, then every quarter, missed a line clipping a wall's corner (the
    // offline test, 2026-10-28: A* walked into the corner of a cup's rim).
    inline bool LineClear(Grid const& g, P a, P b, bool learnedOnly)
    {
        float const inf = std::numeric_limits<float>::infinity();
        float ax = (a.x - g.x0) / g.step, ay = (a.y - g.y0) / g.step, bx = (b.x - g.x0) / g.step, by = (b.y - g.y0) / g.step;
        int c = int(std::lround(ax)), r = int(std::lround(ay)), ce = int(std::lround(bx)), re = int(std::lround(by));
        float dx = bx - ax, dy = by - ay;
        int sc = dx > 0 ? 1 : -1, sr = dy > 0 ? 1 : -1;
        // the line's length (in its own 0..1) to the next column and row border, and from one border to the next
        float nextC = dx != 0 ? ((float(c) + 0.5f * float(sc)) - ax) / dx : inf, eachC = dx != 0 ? 1.0f / std::fabs(dx) : inf;
        float nextR = dy != 0 ? ((float(r) + 0.5f * float(sr)) - ay) / dy : inf, eachR = dy != 0 ? 1.0f / std::fabs(dy) : inf;
        for (int n = std::abs(ce - c) + std::abs(re - r); n > 0; --n)
        {
            if (nextC < nextR) { c += sc; nextC += eachC; }
            else               { r += sr; nextR += eachR; }
            if (c < 0 || r < 0 || c >= g.w || r >= g.h || !g.Passable(r * g.w + c, learnedOnly)) return false;
        }
        return true;
    }
    // }}}

    // {{{ flow: the distance field to `target`, then a step downhill
    // FlowField: the walking cost from every cell to target (infinity where
    // it can't be reached), cheapest-first over the open cells.
    inline std::vector<float> FlowField(Grid const& g, int target)
    {
        float const inf = std::numeric_limits<float>::infinity();
        std::vector<float> dist(size_t(g.w * g.h), inf);
        if (target < 0) return dist;
        using Item = std::pair<float, int>;
        std::priority_queue<Item, std::vector<Item>, std::greater<Item>> open;
        dist[target] = 0; open.push({ 0, target });
        while (!open.empty())
        {
            float d = open.top().first; int q = open.top().second; open.pop();
            if (d > dist[q]) continue;
            Neighbours(g, q, [&](int n) { return g.open[n] != 0; }, [&](int n, float cost) {
                if (dist[n] <= d + cost) return;
                dist[n] = d + cost; open.push({ dist[n], n });
            });
        }
        return dist;
    }
    // FlowNext: up to AHEAD cells downhill from the cell at `from`, the
    // farthest of them in a clear line (the first always counts: it is a
    // neighbour the field allowed); false when the cell is unreachable or
    // already the lowest (the caller goes straight).
    inline bool FlowNext(Grid const& g, std::vector<float> const& dist, P from, P& out, int ahead = 3)
    {
        int q = g.Cell(from);
        if (q < 0 || !std::isfinite(dist[q])) return false;
        int start = q;
        for (int k = 0; k < ahead; ++k)
        {
            int best = q;
            Neighbours(g, q, [&](int n) { return g.open[n] != 0; }, [&](int n, float) { if (dist[n] < dist[best]) best = n; });
            if (best == q || (k > 0 && !LineClear(g, from, g.Centre(best), false))) break;
            q = best;
        }
        if (q == start) return false;
        out = g.Centre(q);
        return true;
    }
    // }}}

    // {{{ astar (and learn): the cheapest route, pulled tight
    // AStar: the cells from `from` to `to`, both included; empty when there
    // is no route. learnedOnly: plan by the learned cells alone (the "learn"
    // way). The target cell is allowed even if blocked (a point at a wall).
    inline std::vector<int> AStar(Grid const& g, int from, int to, bool learnedOnly)
    {
        std::vector<int> route;
        if (from < 0 || to < 0) return route;
        float const inf = std::numeric_limits<float>::infinity();
        std::vector<float> gs(size_t(g.w * g.h), inf);
        std::vector<int> came(size_t(g.w * g.h), -1);
        int tc = to % g.w, tr = to / g.w;
        auto hOf = [&](int q) { float dx = float(std::abs(q % g.w - tc)), dy = float(std::abs(q / g.w - tr));
                                return std::max(dx, dy) + 0.414f * std::min(dx, dy); };
        using Item = std::pair<float, int>;
        std::priority_queue<Item, std::vector<Item>, std::greater<Item>> open;
        gs[from] = 0; open.push({ hOf(from), from });
        while (!open.empty())
        {
            float f = open.top().first; int q = open.top().second; open.pop();
            if (q == to) break;
            if (f - hOf(q) > gs[q] + 1e-4f) continue;
            Neighbours(g, q, [&](int n) { return n == to || g.Passable(n, learnedOnly); }, [&](int n, float cost) {
                float ng = gs[q] + cost;
                if (ng < gs[n]) { gs[n] = ng; came[n] = q; open.push({ ng + hOf(n), n }); }
            });
        }
        if (!std::isfinite(gs[to])) return route;
        for (int q = to; q != -1; q = came[q]) route.push_back(q);
        std::reverse(route.begin(), route.end());
        return route;
    }
    // PullTight: the farthest point of the route within `reach` yards of
    // `from` that a clear line reaches; the route's second point when none.
    inline P PullTight(Grid const& g, std::vector<int> const& route, P from, float reach, bool learnedOnly)
    {
        for (size_t i = route.size(); i-- > 0;)
        {
            P c = g.Centre(route[i]);
            if (std::hypot(c.x - from.x, c.y - from.y) <= reach && LineClear(g, from, c, learnedOnly)) return c;
        }
        return g.Centre(route.size() > 1 ? route[1] : route[0]);
    }
    // Learn: a step from `at` toward `to` fell short: the cell it was going
    // into is learned (the next one along, if that is the cell it stands in).
    // True when something new was learned.
    inline bool Learn(Grid& g, P at, P to)
    {
        int q = g.Cell(to);
        if (q == g.Cell(at))
        {
            float d = std::max(std::hypot(to.x - at.x, to.y - at.y), 0.01f);
            q = g.Cell({ at.x + (to.x - at.x) / d * g.step, at.y + (to.y - at.y) / d * g.step });
        }
        if (q < 0 || g.learned[q]) return false;
        g.learned[q] = 1;
        return true;
    }
    // }}}

    // {{{ potential: forces, and a kick out of a dip
    // blocked(p): whether p can't be walked. The point pulls with 1; a blocked
    // point found within PUSH_RANGE along twelve bearings pushes away, more
    // the nearer. Returns the point 4 yards along the sum.
    static constexpr float PUSH_RANGE = 6.0f;
    inline P PotentialStep(P at, P target, std::function<bool(P)> const& blocked)
    {
        float d = std::max(std::hypot(target.x - at.x, target.y - at.y), 0.01f);
        float fx = (target.x - at.x) / d, fy = (target.y - at.y) / d;
        for (int k = 0; k < 12; ++k)
        {
            float a = float(k) * 3.14159265f / 6.0f, ca = std::cos(a), sa = std::sin(a);
            for (float r = 1.5f; r <= PUSH_RANGE; r += 1.5f)
                if (blocked({ at.x + ca * r, at.y + sa * r }))
                {
                    float push = (PUSH_RANGE - r + 1.5f) / PUSH_RANGE * 0.6f;
                    fx -= ca * push; fy -= sa * push;
                    break;
                }
        }
        float l = std::max(std::hypot(fx, fy), 0.01f);
        return { at.x + fx / l * 4.0f, at.y + fy / l * 4.0f };
    }
    // }}}

    // {{{ orbit: the stuck check, backing out, walking round
    // Stuck: over `elapsed` seconds on one order, the buddy got `closer`
    // yards closer to its point and could have walked `able` yards: stuck
    // when it got less than ABLE_SHARE of that and is still more than
    // ARRIVE yards away (the owner's rule: "if that's less than the distance
    // they were able to have travelled, then they're stuck on something").
    static constexpr float ABLE_SHARE = 0.5f, ARRIVE = 6.0f;
    inline bool Stuck(float closer, float able, float distLeft) { return distLeft > ARRIVE && closer < ABLE_SHARE * able; }

    // Backing out, twice as far each time, reset past the forwardmost stuck
    // spot ("this distance should be reset when they've travelled farther on
    // the forward axis than the place they were foremost stuck").
    static constexpr float BACK_FIRST = 2.0f, BACK_MAX = 64.0f, FRONT_PASS = 1.0f;
    struct Backing
    {
        float next = BACK_FIRST;               // the next back-out's yards
        bool front = false; P frontAt, frontAxis;
        // stuck at `at` heading for `target`: the yards to back out now
        float StuckAt(P at, P target)
        {
            float d = std::max(std::hypot(target.x - at.x, target.y - at.y), 0.01f);
            P axis { (target.x - at.x) / d, (target.y - at.y) / d };
            if (!front || (at.x - frontAt.x) * frontAxis.x + (at.y - frontAt.y) * frontAxis.y > 0) { front = true; frontAt = at; frontAxis = axis; }
            float now = next;
            next = std::min(next * 2.0f, BACK_MAX);
            return now;
        }
        // true when `at` is past the forwardmost stuck spot: reset
        bool Relax(P at)
        {
            if (!front || (at.x - frontAt.x) * frontAxis.x + (at.y - frontAt.y) * frontAxis.y <= FRONT_PASS) return false;
            front = false; next = BACK_FIRST;
            return true;
        }
    };

    // Walking round: keep the obstacle on `side` (+1 or -1): from the
    // heading turned IN toward it, turn away 15 degrees at a time until the
    // points 2 and 4 yards on are clear (4: the point it then walks to). Done when the target is in a clear line and
    // nearer than where the orbit began.
    static constexpr float ORBIT_IN = 1.3f;
    struct Orbit
    {
        bool on = false;
        int side = 1;
        float heading = 0, fromDist = 0;
        void Begin(P at, P target, int sideIn)
        {
            on = true; side = sideIn;
            heading = std::atan2(target.y - at.y, target.x - at.x);
            fromDist = std::hypot(target.x - at.x, target.y - at.y);
        }
        // the point to walk to now; false when the orbit is over (the target in sight) or no way round is found
        bool Step(P at, P target, std::function<bool(P)> const& blocked, std::function<bool(P, P)> const& lineClear, P& out)
        {
            float d = std::hypot(target.x - at.x, target.y - at.y);
            if (d < fromDist - 0.5f && lineClear(at, target)) { on = false; return false; }
            for (int k = 0; k <= 16; ++k)
            {
                float a = heading + float(side) * ORBIT_IN - float(side) * float(k) * 3.14159265f / 12.0f;
                P probe { at.x + std::cos(a) * 2.0f, at.y + std::sin(a) * 2.0f }, far { at.x + std::cos(a) * 4.0f, at.y + std::sin(a) * 4.0f };
                if (!blocked(probe) && !blocked(far)) { heading = a; out = { at.x + std::cos(a) * 4.0f, at.y + std::sin(a) * 4.0f }; return true; }
            }
            on = false;
            return false;
        }
    };
    // }}}

    // {{{ Walker: one buddy's way, and what it remembers between steps
    // The server and the offline test both drive a buddy through this: each
    // step, Next gives the point to walk to; when the walk fell short of it
    // (the world refused), Fell is told, so "learn" learns the cell. Next
    // also runs the owner's stuck check once a CHECK second (a snapshot of
    // the distance left; stuck when it shrank less than half what could have
    // been walked): orbit backs out and walks round, potential takes a kick,
    // the grid ways have nothing to do (their route already goes round).
    // ORBIT_LIMIT: seconds a walk round may last before the buddy tries straight again;
    // KICK_FOR: seconds a kick's direction is held (the sandbox's: one step's
    // kick was pulled straight back into the dip)
    static constexpr float CHECK = 1.0f, REACH = 12.0f, KICK_FOR = 1.5f, ORBIT_LIMIT = 15.0f;
    struct Walker
    {
        Way way = Way::Orbit;
        Backing back;
        Orbit orbit;
        bool backing = false; P backTo; float backUntil = 0, orbitUntil = 0;
        P kick; float kickUntil = -1;
        std::vector<float> flow; int flowTarget = -1;
        std::vector<int> route; int routeTarget = -1, routeLearned = -1, learnedCount = 0;
        float snapTime = -1, snapDist = 0; P snapAt;
        uint32_t seed = 12345;
        int stuckCount = 0, orbitCount = 0, kickCount = 0, replanCount = 0;

        float Random() { seed = seed * 1664525u + 1013904223u; return float(seed >> 8) / 16777216.0f; }
        static P Toward(P at, P to, float most)
        {
            float d = std::hypot(to.x - at.x, to.y - at.y);
            if (d <= most) return to;
            return { at.x + (to.x - at.x) / d * most, at.y + (to.y - at.y) / d * most };
        }
        // a new order (a new target point, or the way switched): forget the plans and the snapshot
        // (what was learned stays: it is the grid's)
        void Reset(Way w) { way = w; back = Backing(); orbit = Orbit(); backing = false; flowTarget = routeTarget = -1; snapTime = -1; }

        // the point to walk to from `at`, heading for `target`, at time `now`
        // seconds, walking `speed` yards a second
        P Next(Grid& g, P at, P target, float now, float speed)
        {
            float d = std::hypot(target.x - at.x, target.y - at.y);
            // the stuck check (the owner's: closer by less than half what could
            // have been walked), and for potential a stiller one (moved less
            // than half: a dip, where pull and push cancel; walking round a
            // wall away from the point is not a dip). No snapshot yet (or the
            // clock went back) takes one.
            bool stuck = false, still = false;
            if (snapTime < 0 || now < snapTime) { snapTime = now; snapDist = d; snapAt = at; }
            else if (now - snapTime >= CHECK)
            {
                float able = speed * (now - snapTime);
                stuck = Stuck(snapDist - d, able, d);
                still = d > ARRIVE && std::hypot(at.x - snapAt.x, at.y - snapAt.y) < ABLE_SHARE * able;
                snapTime = now; snapDist = d; snapAt = at;
                if (stuck) ++stuckCount;
            }
            auto blocked = [&](P p) { int q = g.Cell(p); return q < 0 || !g.open[q]; };

            switch (way)
            {
            case Way::Orbit:
            {
                back.Relax(at);
                // walking round, or backing out, is meant to take it no closer
                // for a while: the stuck check waits until the walk round is
                // over (the target in sight) or out of time (the sandbox's rule;
                // without it the first run backed out again a second into every
                // walk round, and never got round a wall)
                if (orbit.on && now >= orbitUntil) orbit.on = false;
                if (orbit.on || backing) stuck = false;
                if (stuck)
                {
                    // back out along the way it came, twice as far as last time
                    float yards = back.StuckAt(at, target);
                    float l = std::max(d, 0.01f);
                    backTo = { at.x - (target.x - at.x) / l * yards, at.y - (target.y - at.y) / l * yards };
                    backUntil = now + yards / std::max(speed, 0.1f) + CHECK;
                    backing = true; orbit.on = false;
                }
                if (backing)
                {
                    // there, or out of time (the way back was blocked too): walk round from here
                    if (std::hypot(backTo.x - at.x, backTo.y - at.y) > 1.0f && now < backUntil) return Toward(at, backTo, 4.0f);
                    backing = false; ++orbitCount;
                    orbit.Begin(at, target, Random() < 0.5f ? 1 : -1);
                    orbitUntil = now + ORBIT_LIMIT;
                    snapTime = now; snapDist = d; snapAt = at;
                }
                P out;
                if (orbit.on && orbit.Step(at, target, blocked, [&](P a, P b) { return LineClear(g, a, b, false); }, out)) return out;
                return Toward(at, target, 4.0f);
            }
            case Way::Flow:
            {
                int t = g.Cell(target);
                if (t != flowTarget) { flow = FlowField(g, t); flowTarget = t; ++replanCount; }
                P out;
                // downhill; at the target's own cell (or off the field) straight on
                if (FlowNext(g, flow, at, out)) return LineClear(g, at, target, false) && d < REACH ? target : out;
                return Toward(at, target, 4.0f);
            }
            case Way::AStar:
            case Way::Learn:
            {
                bool learnedOnly = way == Way::Learn;
                int t = g.Cell(target), from = g.Cell(at);
                // a new target, something newly learned, or the route lost: plan again
                if (t != routeTarget || (learnedOnly && routeLearned != learnedCount) || route.empty()
                    || std::find(route.begin(), route.end(), from) == route.end())
                {
                    route = AStar(g, from, t, learnedOnly); routeTarget = t; routeLearned = learnedCount; ++replanCount;
                }
                if (route.empty()) return Toward(at, target, 4.0f);
                // the route from where the buddy stands on
                auto here = std::find(route.begin(), route.end(), from);
                if (here != route.end()) route.erase(route.begin(), here);
                if (LineClear(g, at, target, learnedOnly) && d < REACH) return Toward(at, target, 4.0f);
                return Toward(at, PullTight(g, route, at, REACH, learnedOnly), 4.0f);
            }
            case Way::Potential:
            {
                if (still && now >= kickUntil)
                {
                    // a dip: a kick in a random direction, held a while
                    ++kickCount;
                    float a = Random() * 6.2831853f;
                    kick = { std::cos(a), std::sin(a) }; kickUntil = now + KICK_FOR;
                }
                if (now < kickUntil) return { at.x + kick.x * 4.0f, at.y + kick.y * 4.0f };
                return PotentialStep(at, target, blocked);
            }
            }
            return Toward(at, target, 4.0f);
        }
        // the walk from `at` toward `intended` fell short: learn says the cell ahead blocks
        void Fell(Grid& g, P at, P intended)
        {
            if (way == Way::Learn && Learn(g, at, intended)) ++learnedCount;
        }
    };
    // }}}
}

#endif
