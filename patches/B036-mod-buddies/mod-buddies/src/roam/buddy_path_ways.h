
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

    enum class Way : uint8_t { Orbit, Flow, AStar, Potential, Learn, Paint };

    inline char const* WayName(Way w)
    {
        switch (w) { case Way::Orbit: return "orbit"; case Way::Flow: return "flow"; case Way::AStar: return "astar";
                     case Way::Potential: return "potential"; case Way::Learn: return "learn"; case Way::Paint: return "paint"; }
        return "orbit";
    }
    inline bool WayFromName(std::string const& name, Way& out)
    {
        for (Way w : { Way::Orbit, Way::Flow, Way::AStar, Way::Potential, Way::Learn, Way::Paint })
            if (name == WayName(w)) { out = w; return true; }
        return false;
    }

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
    inline bool LineClear(Grid const& g, P a, P b, bool learnedOnly)
    {
        float const inf = std::numeric_limits<float>::infinity();
        float ax = (a.x - g.x0) / g.step, ay = (a.y - g.y0) / g.step, bx = (b.x - g.x0) / g.step, by = (b.y - g.y0) / g.step;
        int c = int(std::lround(ax)), r = int(std::lround(ay)), ce = int(std::lround(bx)), re = int(std::lround(by));
        float dx = bx - ax, dy = by - ay;
        int sc = dx > 0 ? 1 : -1, sr = dy > 0 ? 1 : -1;
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
    inline P PullTight(Grid const& g, std::vector<int> const& route, P from, float reach, bool learnedOnly)
    {
        for (size_t i = route.size(); i-- > 0;)
        {
            P c = g.Centre(route[i]);
            if (std::hypot(c.x - from.x, c.y - from.y) <= reach && LineClear(g, from, c, learnedOnly)) return c;
        }
        return g.Centre(route.size() > 1 ? route[1] : route[0]);
    }
    inline int CellAhead(Grid const& g, P at, P to)
    {
        int q = g.Cell(to);
        if (q == g.Cell(at))
        {
            float d = std::max(std::hypot(to.x - at.x, to.y - at.y), 0.01f);
            q = g.Cell({ at.x + (to.x - at.x) / d * g.step, at.y + (to.y - at.y) / d * g.step });
        }
        return q;
    }
    inline bool Learn(Grid& g, P at, P to)
    {
        int q = CellAhead(g, at, to);
        if (q < 0 || g.learned[q]) return false;
        g.learned[q] = 1;
        return true;
    }

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

    static constexpr float ABLE_SHARE = 0.5f, ARRIVE = 6.0f;
    inline bool Stuck(float closer, float able, float distLeft) { return distLeft > ARRIVE && closer < ABLE_SHARE * able; }

    static constexpr float BACK_FIRST = 2.0f, BACK_MAX = 64.0f, FRONT_PASS = 1.0f;
    struct Backing
    {
        float next = BACK_FIRST;
        bool front = false; P frontAt, frontAxis;
        float StuckAt(P at, P target)
        {
            float d = std::max(std::hypot(target.x - at.x, target.y - at.y), 0.01f);
            P axis { (target.x - at.x) / d, (target.y - at.y) / d };
            if (!front || (at.x - frontAt.x) * frontAxis.x + (at.y - frontAt.y) * frontAxis.y > 0) { front = true; frontAt = at; frontAxis = axis; }
            float now = next;
            next = std::min(next * 2.0f, BACK_MAX);
            return now;
        }
        bool Relax(P at)
        {
            if (!front || (at.x - frontAt.x) * frontAxis.x + (at.y - frontAt.y) * frontAxis.y <= FRONT_PASS) return false;
            front = false; next = BACK_FIRST;
            return true;
        }
    };

    static constexpr float ORBIT_IN = 1.3f, FEEL = 4.5f, ROUND = 0.52f;
    struct Orbit
    {
        bool on = false, touched = false;
        int side = 1;
        float heading = 0, fromDist = 0;
        void Begin(P at, P target, int sideIn)
        {
            on = true; touched = false; side = sideIn;
            heading = std::atan2(target.y - at.y, target.x - at.x);
            fromDist = std::hypot(target.x - at.x, target.y - at.y);
        }
        bool Step(P at, P target, std::function<bool(P)> const& blocked, std::function<bool(P, P)> const& lineClear, P& out)
        {
            float d = std::hypot(target.x - at.x, target.y - at.y);
            if (d < fromDist - 0.5f && lineClear(at, target)) { on = false; return false; }
            auto clear = [&](float a) {
                return !blocked({ at.x + std::cos(a) * 2.0f, at.y + std::sin(a) * 2.0f }) && !blocked({ at.x + std::cos(a) * 4.0f, at.y + std::sin(a) * 4.0f });
            };
            if (!touched)
            {
                float a = std::atan2(target.y - at.y, target.x - at.x);
                if (clear(a)) { heading = a; out = { at.x + std::cos(a) * 4.0f, at.y + std::sin(a) * 4.0f }; return true; }
                touched = true; heading = a - float(side) * 1.5708f;
            }
            float wallSide = heading + float(side) * 1.5708f;
            bool felt = false;
            for (float r = 1.5f; r <= FEEL && !felt; r += 1.5f)
                felt = blocked({ at.x + std::cos(wallSide) * r, at.y + std::sin(wallSide) * r });
            if (!felt)
            {
                float a = heading + float(side) * ROUND;
                if (clear(a)) { heading = a; out = { at.x + std::cos(a) * 4.0f, at.y + std::sin(a) * 4.0f }; return true; }
            }
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
        void Reset(Way w) { way = w; back = Backing(); orbit = Orbit(); backing = false; flowTarget = routeTarget = -1; snapTime = -1; }

        P Next(Grid& g, P at, P target, float now, float speed)
        {
            float d = std::hypot(target.x - at.x, target.y - at.y);
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
                if (orbit.on && now >= orbitUntil) orbit.on = false;
                if (orbit.on || backing) stuck = false;
                if (stuck)
                {
                    float yards = back.StuckAt(at, target);
                    float l = std::max(d, 0.01f);
                    backTo = { at.x - (target.x - at.x) / l * yards, at.y - (target.y - at.y) / l * yards };
                    backUntil = now + yards / std::max(speed, 0.1f) + CHECK;
                    backing = true; orbit.on = false;
                }
                if (backing)
                {
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
                if (FlowNext(g, flow, at, out)) return LineClear(g, at, target, false) && d < REACH ? target : out;
                return Toward(at, target, 4.0f);
            }
            case Way::AStar:
            case Way::Learn:
            {
                bool learnedOnly = way == Way::Learn;
                int t = g.Cell(target), from = g.Cell(at);
                if (t != routeTarget || (learnedOnly && routeLearned != learnedCount) || route.empty()
                    || std::find(route.begin(), route.end(), from) == route.end())
                {
                    route = AStar(g, from, t, learnedOnly); routeTarget = t; routeLearned = learnedCount; ++replanCount;
                }
                if (route.empty()) return Toward(at, target, 4.0f);
                auto here = std::find(route.begin(), route.end(), from);
                if (here != route.end()) route.erase(route.begin(), here);
                if (LineClear(g, at, target, learnedOnly) && d < REACH) return Toward(at, target, 4.0f);
                return Toward(at, PullTight(g, route, at, REACH, learnedOnly), 4.0f);
            }
            case Way::Potential:
            {
                if (still && now >= kickUntil)
                {
                    ++kickCount;
                    float a = Random() * 6.2831853f;
                    kick = { std::cos(a), std::sin(a) }; kickUntil = now + KICK_FOR;
                }
                if (now < kickUntil) return { at.x + kick.x * 4.0f, at.y + kick.y * 4.0f };
                return PotentialStep(at, target, blocked);
            }
            case Way::Paint:
                break;
            }
            return Toward(at, target, 4.0f);
        }
        void Fell(Grid& g, P at, P intended)
        {
            if (way == Way::Learn && Learn(g, at, intended)) ++learnedCount;
            if (way == Way::Flow || way == Way::AStar)
            {
                int q = CellAhead(g, at, intended);
                if (q >= 0 && q != g.Cell(at) && g.open[q]) { g.open[q] = 0; flowTarget = routeTarget = -1; }
            }
        }
    };
}

#endif
