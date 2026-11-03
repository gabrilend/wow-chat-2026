
#ifndef BUDDY_PAINT_PATHS_H
#define BUDDY_PAINT_PATHS_H

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <functional>
#include <limits>
#include <vector>

namespace BuddyPaint
{
    struct Options
    {
        double WANT        =  4.0;
        double WALL_W      =  8.0;
        double RELAX       = 10.0;
        double NEAR        = 24.0;
        double UNKNOWN     =  0.15;
        double CROWD_W     =  0.5;
        double CROWD_AHEAD = 14.0;
        double CLEAR_CAP   =  8.0;
        double LOOK        =  6.0;
        double SAFE        =  1.0;
        double TURN        =  4.2;
        double LANE        =  4.0;
        double REACH       = 40.0;
        double REPLAN      =  6.0;
        double ARRIVE      =  1.5;
    };
    enum Kind : uint8_t { Unknown = 0, Painted = 1, Wall = 2, Steep = 3, Outside = 4 };
    inline bool Blocks(uint8_t k)  { return k >= Wall; }
    inline bool Walling(uint8_t k) { return k == Wall || k == Steep; }

    struct Pt { double x = 0, y = 0; };
    struct WallMark { uint32_t v; int c0, r0, c1, r1; };
    struct Stats { uint32_t plans = 0, failed = 0, bumps = 0; uint64_t expanded = 0; double ms = 0; };
    struct Path
    {
        std::vector<int> cells;
        std::vector<Pt> pts;
        double gx = 0, gy = 0, len = 0, box[4] = { 0, 0, 0, 0 };
        int seg = 0;
        double at = 0;
        uint32_t v = 0;
    };
    struct Map
    {
        int w = 0, h = 0, n = 0;
        double step = 1, x0 = 0, y0 = 0;
        Options opt;
        std::vector<uint8_t> know;
        std::vector<uint16_t> walks;
        std::vector<float> clear, crowd;
        std::vector<WallMark> walls;
        uint32_t version = 0;
        int painted = 0, wallCells = 0, inside = 0;
        uint32_t gen = 0;
        std::vector<uint32_t> stamp, shut;
        std::vector<float> g;
        std::vector<int> came;
        std::vector<double> heapF;
        std::vector<int> heapQ;
        int heapN = 0;
        Stats stats;
    };
    inline Map Make(int w, int h, double step, double x0, double y0, Options opt = {})
    {
        Map M;
        M.w = w; M.h = h; M.n = w * h; M.step = step; M.x0 = x0; M.y0 = y0; M.opt = opt;
        M.know.assign(size_t(M.n), Unknown); M.walks.assign(size_t(M.n), 0);
        M.clear.assign(size_t(M.n), float(opt.CLEAR_CAP)); M.crowd.assign(size_t(M.n), 0.0f);
        M.stamp.assign(size_t(M.n), 0); M.shut.assign(size_t(M.n), 0);
        M.g.assign(size_t(M.n), 0.0f); M.came.assign(size_t(M.n), -1);
        M.heapF.assign(4096, 0.0); M.heapQ.assign(4096, 0);
        M.inside = M.n;
        return M;
    }
    inline double Round(double v) { return std::floor(v + 0.5); }
    inline int CellOf(Map const& M, double x, double y)
    {
        int c = int(Round((x - M.x0) / M.step)), r = int(Round((y - M.y0) / M.step));
        return c < 0 || r < 0 || c >= M.w || r >= M.h ? -1 : r * M.w + c;
    }
    inline double Cx(Map const& M, int q) { return M.x0 + double(q % M.w) * M.step; }
    inline double Cy(Map const& M, int q) { int row = q / M.w; return M.y0 + double(row) * M.step; }

    inline void StampClear(Map& M, int s)
    {
        int R = int(std::ceil(M.opt.CLEAR_CAP / M.step)), sc = s % M.w, sr = s / M.w;
        int r0 = std::max(0, sr - R), r1 = std::min(M.h - 1, sr + R), c0 = std::max(0, sc - R), c1 = std::min(M.w - 1, sc + R);
        for (int r = r0; r <= r1; ++r)
        {
            double dy = double(r - sr) * M.step;
            for (int c = c0; c <= c1; ++c)
            {
                double dx = double(c - sc) * M.step, d = std::sqrt(dx * dx + dy * dy);
                float& cl = M.clear[size_t(r * M.w + c)];
                if (d < double(cl)) cl = float(d);
            }
        }
    }
    inline void ClearAll(Map& M)
    {
        std::fill(M.clear.begin(), M.clear.end(), float(M.opt.CLEAR_CAP));
        int w = M.w;
        auto const& k = M.know;
        for (int q = 0; q < M.n; ++q)
        {
            if (!Walling(k[size_t(q)])) continue;
            int c = q % w;
            bool edge = (c > 0 && !Walling(k[size_t(q - 1)])) || (c < w - 1 && !Walling(k[size_t(q + 1)])) ||
                        (q >= w && !Walling(k[size_t(q - w)])) || (q < M.n - w && !Walling(k[size_t(q + w)]));
            if (edge) StampClear(M, q);
        }
        for (int q = 0; q < M.n; ++q) if (Walling(k[size_t(q)])) M.clear[size_t(q)] = 0;
    }
    inline void SetGround(Map& M, std::function<uint8_t(double, double)> const& kindAt)
    {
        int inside = 0;
        for (int q = 0; q < M.n; ++q)
        {
            uint8_t k = M.know[size_t(q)];
            if (k == Painted || k == Wall) { ++inside; continue; }
            uint8_t kk = kindAt(Cx(M, q), Cy(M, q));
            M.know[size_t(q)] = kk;
            if (kk != Outside) ++inside;
        }
        M.inside = inside;
        ClearAll(M);
    }

    inline void Walked(Map& M, double x, double y)
    {
        int q = CellOf(M, x, y); if (q < 0) return;
        if (M.know[size_t(q)] == Unknown) { M.know[size_t(q)] = Painted; ++M.painted; }
        if (M.walks[size_t(q)] < 65535) ++M.walks[size_t(q)];
    }
    inline int PaintWallIn(Map& M, double x0, double y0, double x1, double y1, int keep, bool ring)
    {
        int c0 = int(std::ceil((x0 - M.x0) / M.step)), c1 = int(std::floor((x1 - M.x0) / M.step));
        int r0 = int(std::ceil((y0 - M.y0) / M.step)), r1 = int(std::floor((y1 - M.y0) / M.step));
        if (c0 > c1) c0 = c1 = int(Round(((x0 + x1) / 2 - M.x0) / M.step));
        if (r0 > r1) r0 = r1 = int(Round(((y0 + y1) / 2 - M.y0) / M.step));
        c0 = std::max(0, c0); r0 = std::max(0, r0); c1 = std::min(M.w - 1, c1); r1 = std::min(M.h - 1, r1);
        int fresh = 0;
        for (int r = r0; r <= r1; ++r)
            for (int c = c0; c <= c1; ++c)
            {
                int q = r * M.w + c;
                uint8_t k = M.know[size_t(q)];
                if (Blocks(k) || q == keep) continue;
                if (ring && keep >= 0 && std::abs(c - keep % M.w) <= 1 && std::abs(r - keep / M.w) <= 1) continue;
                if (k == Painted) --M.painted;
                M.know[size_t(q)] = Wall; ++M.wallCells; ++fresh;
                StampClear(M, q); M.clear[size_t(q)] = 0;
            }
        if (fresh)
        {
            M.walls.push_back({ ++M.version, c0, r0, c1, r1 });
            if (M.walls.size() > 128) M.walls.erase(M.walls.begin(), M.walls.end() - 128);
        }
        return fresh;
    }
    inline int PaintWall(Map& M, double x0, double y0, double x1, double y1) { return PaintWallIn(M, x0, y0, x1, y1, -1, false); }
    inline int Refused(Map& M, double x, double y, double const* box, double bx, double by)
    {
        int keep = CellOf(M, bx, by);
        int fresh = box ? PaintWallIn(M, box[0], box[1], box[2], box[3], keep, false) : 0;
        if (!fresh) fresh = PaintWallIn(M, x, y, x, y, keep, true);
        ++M.stats.bumps;
        return fresh;
    }

    inline double CostAt(Map const& M, int q, double gx, double gy, double trip)
    {
        Options const& o = M.opt;
        double cost = 1;
        double cl = M.clear[size_t(q)];
        if (cl < o.WANT)
        {
            double dx = Cx(M, q) - gx, dy = Cy(M, q) - gy, dg = std::sqrt(dx * dx + dy * dy);
            double relax = std::min(dg >= o.RELAX ? 1.0 : dg / o.RELAX, trip);
            double f = (o.WANT - cl) / o.WANT;
            cost += o.WALL_W * f * f * relax;
        }
        if (M.know[size_t(q)] == Unknown) cost += o.UNKNOWN;
        return cost + double(M.crowd[size_t(q)]);
    }

    inline void Push(Map& M, int q, double f)
    {
        if (M.heapN == int(M.heapF.size())) { M.heapF.resize(M.heapF.size() * 2); M.heapQ.resize(M.heapQ.size() * 2); }
        int i = M.heapN++;
        while (i > 0) { int p = (i - 1) >> 1; if (M.heapF[size_t(p)] <= f) break; M.heapF[size_t(i)] = M.heapF[size_t(p)]; M.heapQ[size_t(i)] = M.heapQ[size_t(p)]; i = p; }
        M.heapF[size_t(i)] = f; M.heapQ[size_t(i)] = q;
    }
    inline int Pop(Map& M)
    {
        int top = M.heapQ[0], n = --M.heapN;
        if (n > 0)
        {
            double f = M.heapF[size_t(n)]; int q = M.heapQ[size_t(n)], i = 0;
            for (;;)
            {
                int l = 2 * i + 1; if (l >= n) break;
                int m = l + 1 < n && M.heapF[size_t(l + 1)] < M.heapF[size_t(l)] ? l + 1 : l;
                if (M.heapF[size_t(m)] >= f) break;
                M.heapF[size_t(i)] = M.heapF[size_t(m)]; M.heapQ[size_t(i)] = M.heapQ[size_t(m)]; i = m;
            }
            M.heapF[size_t(i)] = f; M.heapQ[size_t(i)] = q;
        }
        return top;
    }

    inline bool Fair(Map const& M, double ax, double ay, double bx, double by, double need)
    {
        int w = M.w;
        double fx = (ax - M.x0) / M.step, fy = (ay - M.y0) / M.step, tx = (bx - M.x0) / M.step, ty = (by - M.y0) / M.step;
        int c = int(Round(fx)), r = int(Round(fy));
        int ce = int(Round(tx)), re = int(Round(ty));
        double dx = tx - fx, dy = ty - fy;
        int sc = dx > 0 ? 1 : -1, sr = dy > 0 ? 1 : -1;
        double const inf = std::numeric_limits<double>::infinity();
        double nextC = dx != 0 ? ((c + 0.5 * sc) - fx) / dx : inf, nextR = dy != 0 ? ((r + 0.5 * sr) - fy) / dy : inf;
        double eachC = dx != 0 ? 1 / std::fabs(dx) : inf, eachR = dy != 0 ? 1 / std::fabs(dy) : inf;
        for (int n = std::abs(ce - c) + std::abs(re - r); n > 0; --n)
        {
            if (nextC < nextR) { c += sc; nextC += eachC; } else { r += sr; nextR += eachR; }
            if (c < 0 || r < 0 || c >= w || r >= M.h) return false;
            int q = r * w + c;
            if (Blocks(M.know[size_t(q)]) || double(M.clear[size_t(q)]) < need) return false;
        }
        return true;
    }
    inline Path PullTight(Map const& M, std::vector<int> cells, double sx, double sy, double gx, double gy)
    {
        Path P;
        P.pts.push_back({ sx, sy });
        double ax = sx, ay = sy;
        size_t a = 0;
        while (a + 1 < cells.size())
        {
            size_t best = a + 1;
            double need = std::numeric_limits<double>::infinity();
            for (size_t j = a + 1; j < cells.size(); ++j)
            {
                need = std::min(need, double(M.clear[size_t(cells[j])]));
                double bx = Cx(M, cells[j]), by = Cy(M, cells[j]);
                if (std::hypot(bx - ax, by - ay) > M.opt.REACH) break;
                if (j > a + 1 && !Fair(M, ax, ay, bx, by, need - 0.01)) break;
                best = j;
            }
            ax = Cx(M, cells[best]); ay = Cy(M, cells[best]);
            P.pts.push_back({ ax, ay }); a = best;
        }
        int gq = CellOf(M, gx, gy);
        bool goalOpen = gq >= 0 && !Blocks(M.know[size_t(gq)]) && Fair(M, ax, ay, gx, gy, 0);
        if (P.pts.size() == 1) P.pts.push_back(goalOpen ? Pt{ gx, gy } : Pt{ Cx(M, cells[0]), Cy(M, cells[0]) });
        else if (goalOpen) P.pts.back() = { gx, gy };
        double x0 = 1e300, y0 = 1e300, x1 = -1e300, y1 = -1e300;
        for (Pt const& p : P.pts) { x0 = std::min(x0, p.x); y0 = std::min(y0, p.y); x1 = std::max(x1, p.x); y1 = std::max(y1, p.y); }
        double len = 0;
        for (size_t i = 1; i < P.pts.size(); ++i) len += std::hypot(P.pts[i].x - P.pts[i - 1].x, P.pts[i].y - P.pts[i - 1].y);
        P.cells = std::move(cells); P.gx = gx; P.gy = gy; P.len = len;
        P.box[0] = x0; P.box[1] = y0; P.box[2] = x1; P.box[3] = y1;
        return P;
    }

    inline int NearestOpen(Map const& M, int t, int R)
    {
        int tc = t % M.w, tr = t / M.w, best = -1;
        long bd = std::numeric_limits<long>::max();
        for (int r = std::max(0, tr - R); r <= std::min(M.h - 1, tr + R); ++r)
            for (int c = std::max(0, tc - R); c <= std::min(M.w - 1, tc + R); ++c)
            {
                int q = r * M.w + c;
                long d = long(c - tc) * (c - tc) + long(r - tr) * (r - tr);
                if (!Blocks(M.know[size_t(q)]) && d < bd) { bd = d; best = q; }
            }
        return best;
    }
    inline bool PlanOnce(Map& M, double sx, double sy, double gx, double gy, bool squeeze, Path& out)
    {
        static int const DC[8] = { 1, -1, 0, 0, 1, 1, -1, -1 }, DR[8] = { 0, 0, 1, -1, 1, -1, 1, -1 };
        double const SQRT2 = std::sqrt(2.0);
        auto t0 = std::chrono::steady_clock::now();
        auto ms = [&] { return std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count(); };
        int w = M.w;
        double st = M.step;
        int s = CellOf(M, sx, sy), t = CellOf(M, gx, gy);
        if (s >= 0 && t >= 0 && Blocks(M.know[size_t(t)])) t = NearestOpen(M, t, 8);
        if (s < 0 || t < 0) { ++M.stats.failed; return false; }
        if (++M.gen == 0xffffffffu) { std::fill(M.stamp.begin(), M.stamp.end(), 0u); std::fill(M.shut.begin(), M.shut.end(), 0u); M.gen = 1; }
        uint32_t gen = M.gen;
        int tc = t % w, tr = t / w;
        double trip = std::min(1.0, std::hypot(gx - sx, gy - sy) / M.opt.NEAR);
        M.heapN = 0;
        M.g[size_t(s)] = 0; M.came[size_t(s)] = -1; M.stamp[size_t(s)] = gen;
        int h0c = std::abs(s % w - tc), h0r = std::abs(s / w - tr);
        Push(M, s, (std::max(h0c, h0r) + (SQRT2 - 1) * std::min(h0c, h0r)) * st);
        uint64_t expanded = 0;
        while (M.heapN > 0)
        {
            int q = Pop(M);
            if (q == t) break;
            if (M.shut[size_t(q)] == gen) continue;
            M.shut[size_t(q)] = gen; ++expanded;
            int qc = q % w, qr = q / w;
            double gq = M.g[size_t(q)];
            for (int k = 0; k < 8; ++k)
            {
                int nc = qc + DC[k], nr = qr + DR[k];
                if (nc < 0 || nr < 0 || nc >= w || nr >= M.h) continue;
                int n = nr * w + nc;
                if (M.shut[size_t(n)] == gen) continue;
                bool squeezing = q == s && squeeze;
                uint8_t kn = M.know[size_t(n)];
                if (Blocks(kn) && !(squeezing && kn == Wall)) continue;
                if (k >= 4 && !squeezing && (Blocks(M.know[size_t(qr * w + nc)]) || Blocks(M.know[size_t(nr * w + qc)]))) continue;
                double ng = gq + (k >= 4 ? SQRT2 : 1.0) * st * CostAt(M, n, gx, gy, trip);
                if (M.stamp[size_t(n)] != gen || ng < double(M.g[size_t(n)]))
                {
                    M.stamp[size_t(n)] = gen; M.g[size_t(n)] = float(ng); M.came[size_t(n)] = q;
                    int hc = std::abs(nc - tc), hr = std::abs(nr - tr);
                    Push(M, n, ng + (std::max(hc, hr) + (SQRT2 - 1) * std::min(hc, hr)) * st);
                }
            }
        }
        M.stats.expanded += expanded;
        if (M.stamp[size_t(t)] != gen) { if (squeeze) ++M.stats.failed; ++M.stats.plans; M.stats.ms += ms(); return false; }
        std::vector<int> cells;
        for (int q = t; q != -1; q = M.came[size_t(q)]) cells.push_back(q);
        std::reverse(cells.begin(), cells.end());
        out = PullTight(M, std::move(cells), sx, sy, gx, gy);
        out.v = M.version;
        ++M.stats.plans; M.stats.ms += ms();
        return true;
    }
    inline bool Plan(Map& M, double sx, double sy, double gx, double gy, Path& out)
    {
        return PlanOnce(M, sx, sy, gx, gy, false, out) || PlanOnce(M, sx, sy, gx, gy, true, out);
    }

    inline bool NeedsPlan(Map const& M, Path* path, double gx, double gy, double t, double jitter)
    {
        if (!path) return true;
        if (std::hypot(path->gx - gx, path->gy - gy) > 2 * M.step) return true;
        if (t - path->at > M.opt.REPLAN + jitter) return true;
        if (path->v != M.version)
        {
            double g = M.opt.WANT;
            for (WallMark const& wl : M.walls)
            {
                if (wl.v <= path->v) continue;
                double wx0 = M.x0 + wl.c0 * M.step, wx1 = M.x0 + wl.c1 * M.step, wy0 = M.y0 + wl.r0 * M.step, wy1 = M.y0 + wl.r1 * M.step;
                if (wx1 >= path->box[0] - g && wx0 <= path->box[2] + g && wy1 >= path->box[1] - g && wy0 <= path->box[3] + g) return true;
            }
            path->v = M.version;
        }
        return false;
    }

    inline Pt FollowAt(Map const& M, Path& path, double x, double y, double lane, double look)
    {
        auto const& p = path.pts;
        Options const& o = M.opt;
        int last = int(p.size()) - 1;
        int seg = std::min(path.seg, last - 1), bestSeg = seg;
        double best = std::numeric_limits<double>::infinity(), bestT = 0;
        for (int s = seg; s < std::min(last, seg + 3); ++s)
        {
            double ax = p[size_t(s)].x, ay = p[size_t(s)].y, dx = p[size_t(s + 1)].x - ax, dy = p[size_t(s + 1)].y - ay, L2 = dx * dx + dy * dy;
            double tt = L2 > 0 ? std::max(0.0, std::min(1.0, ((x - ax) * dx + (y - ay) * dy) / L2)) : 0;
            double d = std::hypot(ax + dx * tt - x, ay + dy * tt - y);
            if (d < best) { best = d; bestSeg = s; bestT = tt; }
        }
        path.seg = bestSeg;
        int s = bestSeg;
        double left = look;
        double px = p[size_t(s)].x + (p[size_t(s + 1)].x - p[size_t(s)].x) * bestT, py = p[size_t(s)].y + (p[size_t(s + 1)].y - p[size_t(s)].y) * bestT;
        double hx = p[size_t(s + 1)].x - p[size_t(s)].x, hy = p[size_t(s + 1)].y - p[size_t(s)].y;
        for (;;)
        {
            double bx = p[size_t(s + 1)].x, by = p[size_t(s + 1)].y, d = std::hypot(bx - px, by - py);
            if (d >= left || s + 1 >= last)
            {
                double k = d > 0 ? std::min(1.0, left / d) : 0;
                px += (bx - px) * k; py += (by - py) * k;
                if (d > 0) { hx = bx - p[size_t(s)].x; hy = by - p[size_t(s)].y; }
                break;
            }
            left -= d; px = bx; py = by; ++s;
            hx = p[size_t(s + 1)].x - p[size_t(s)].x; hy = p[size_t(s + 1)].y - p[size_t(s)].y;
        }
        double gx = p[size_t(last)].x, gy = p[size_t(last)].y, toGoal = std::hypot(gx - px, gy - py);
        if (lane != 0 && toGoal > 0.01)
        {
            double hl = std::hypot(hx, hy); if (hl == 0) hl = 1;
            double nx = -hy / hl, ny = hx / hl;
            int q = CellOf(M, px, py);
            double room = q >= 0 ? std::max(0.0, double(M.clear[size_t(q)]) - o.WANT * 0.5) : 0;
            double shift = lane * std::min(o.LANE, room * 0.6) * std::min(1.0, toGoal / o.LOOK);
            double sx2 = px + nx * shift, sy2 = py + ny * shift;
            int q2 = CellOf(M, sx2, sy2);
            if (q2 >= 0 && !Blocks(M.know[size_t(q2)])) { px = sx2; py = sy2; }
        }
        return { px, py };
    }
    inline Pt Follow(Map const& M, Path& path, double x, double y, double lane)
    {
        Options const& o = M.opt;
        Pt nearPt;
        for (double look : { o.LOOK, o.LOOK * 0.6, o.LOOK * 0.35, 1.5 })
        {
            Pt p = FollowAt(M, path, x, y, lane, look);
            if (Fair(M, x, y, p.x, p.y, o.SAFE)) return p;
            if (lane != 0) { Pt p0 = FollowAt(M, path, x, y, 0, look); if (Fair(M, x, y, p0.x, p0.y, o.SAFE)) return p0; }
            nearPt = p;
        }
        double toward = std::atan2(nearPt.y - y, nearPt.x - x), bestScore = -std::numeric_limits<double>::infinity();
        Pt best = nearPt;
        double const PI = 3.14159265358979323846;
        for (int k = 0; k < 8; ++k)
        {
            double a = k * PI / 4, ex = x + std::cos(a) * 1.5, ey = y + std::sin(a) * 1.5;
            int q = CellOf(M, ex, ey);
            if (q < 0 || Blocks(M.know[size_t(q)])) continue;
            double score = double(M.clear[size_t(q)]) + 0.5 * std::cos(a - toward);
            if (score > bestScore) { bestScore = score; best = { ex, ey }; }
        }
        return best;
    }
    inline void Steer(Map const& M, double x, double y, double h, double tx, double ty, double dt, double& heading, double& share)
    {
        double const PI = 3.14159265358979323846;
        double want = std::atan2(ty - y, tx - x), d = want - h;
        d -= Round(d / (2 * PI)) * 2 * PI;
        double most = M.opt.TURN * dt, turn = std::max(-most, std::min(most, d));
        heading = h + turn;
        share = 0.4 + 0.6 * std::max(0.0, std::cos(d));
    }

    inline void CrowdAdd(Map& M, double x, double y, double v)
    {
        int w = M.w, q = CellOf(M, x, y); if (q < 0) return;
        int c = q % w, r = q / w;
        for (int dr = -1; dr <= 1; ++dr)
            for (int dc = -1; dc <= 1; ++dc)
            {
                int nc = c + dc, nr = r + dr; if (nc < 0 || nr < 0 || nc >= w || nr >= M.h) continue;
                M.crowd[size_t(nr * w + nc)] += float(dr || dc ? v * 0.5 : v);
            }
    }
    inline void CrowdAlong(Map& M, Path const& path, int s, double x, double y, double v)
    {
        auto const& p = path.pts;
        double left = M.opt.CROWD_AHEAD;
        while (left > 0 && s < int(p.size()) - 1)
        {
            double bx = p[size_t(s + 1)].x, by = p[size_t(s + 1)].y, d = std::hypot(bx - x, by - y), k = std::min(d, left);
            for (double u = M.step; u <= k; u += M.step) CrowdAdd(M, x + (bx - x) * u / d, y + (by - y) * u / d, v);
            left -= k; x = bx; y = by; ++s;
        }
    }
    inline void CrowdRoute(Map& M, Path const& path, double fromX, double fromY) { CrowdAlong(M, path, 0, fromX, fromY, M.opt.CROWD_W * 0.5); }
    struct CrowdBot { double x, y; Path const* path; };
    inline void Crowd(Map& M, std::vector<CrowdBot> const& bots)
    {
        std::fill(M.crowd.begin(), M.crowd.end(), 0.0f);
        double W = M.opt.CROWD_W;
        for (CrowdBot const& b : bots)
        {
            CrowdAdd(M, b.x, b.y, W);
            if (b.path) CrowdAlong(M, *b.path, b.path->seg, b.x, b.y, W * 0.5);
        }
    }

    inline std::vector<uint8_t> Save(Map const& M)
    {
        std::vector<uint8_t> out;
        auto put = [&](void const* p, size_t n) { auto b = static_cast<uint8_t const*>(p); out.insert(out.end(), b, b + n); };
        uint32_t version = 1;
        int32_t w = M.w, h = M.h;
        out.insert(out.end(), { 'B', 'P', 'N', 'T' });
        put(&version, 4); put(&w, 4); put(&h, 4); put(&M.step, 8); put(&M.x0, 8); put(&M.y0, 8);
        out.insert(out.end(), M.know.begin(), M.know.end());
        for (uint16_t v : M.walks) { out.push_back(uint8_t(v & 0xff)); out.push_back(uint8_t(v >> 8)); }
        return out;
    }
    inline bool Load(Map& M, std::vector<uint8_t> const& in)
    {
        size_t const head = 4 + 4 + 4 + 4 + 8 + 8 + 8, n = size_t(M.n);
        if (in.size() != head + n + 2 * n || in[0] != 'B' || in[1] != 'P' || in[2] != 'N' || in[3] != 'T') return false;
        uint32_t version; int32_t w, h; double step, x0, y0;
        std::memcpy(&version, &in[4], 4); std::memcpy(&w, &in[8], 4); std::memcpy(&h, &in[12], 4);
        std::memcpy(&step, &in[16], 8); std::memcpy(&x0, &in[24], 8); std::memcpy(&y0, &in[32], 8);
        if (version != 1 || w != M.w || h != M.h || step != M.step || x0 != M.x0 || y0 != M.y0) return false;
        int painted = 0, wallCells = 0, inside = 0;
        for (size_t q = 0; q < n; ++q)
        {
            uint8_t k = in[head + q];
            if (k > Outside) return false;
            M.know[q] = k;
            if (k == Painted) ++painted;
            if (k == Wall) ++wallCells;
            if (k != Outside) ++inside;
            M.walks[q] = uint16_t(in[head + n + 2 * q] | (in[head + n + 2 * q + 1] << 8));
        }
        M.painted = painted; M.wallCells = wallCells; M.inside = inside;
        ++M.version;
        ClearAll(M);
        return true;
    }
}

#endif
