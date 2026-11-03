
#ifndef MOD_BUDDIES_WEATHER_STORM_H
#define MOD_BUDDIES_WEATHER_STORM_H

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <random>
#include <set>
#include <utility>
#include <vector>

namespace BuddyStorm
{
    static constexpr float SPEED      = 2.0f;
    static constexpr float WANDER     = 0.05f;
    static constexpr float LOOK       = 60.0f;
    static constexpr float CELL       = 50.0f;
    static constexpr int   NEAR_CELLS = 1;
    static constexpr float DOWNPOUR   = 60.0f;
    static constexpr float EDGE       = 90.0f;

    struct Valley
    {
        std::set<std::pair<int, int>> cells;
        std::vector<std::pair<std::pair<int, int>, float>> visits;
        static std::pair<int, int> Cell(float x, float y) { return { int(std::floor(x / CELL)), int(std::floor(y / CELL)) }; }
        bool Inside(float x, float y) const { return cells.count(Cell(x, y)) > 0; }
    };

    inline Valley ValleyFrom(std::vector<std::pair<float, float>> const& places)
    {
        Valley v;
        for (auto const& p : places)
        {
            auto c = Valley::Cell(p.first, p.second);
            for (int dx = -NEAR_CELLS; dx <= NEAR_CELLS; ++dx)
                for (int dy = -NEAR_CELLS; dy <= NEAR_CELLS; ++dy)
                    v.cells.insert({ c.first + dx, c.second + dy });
        }
        return v;
    }

    inline Valley ValleyFromCells(int const (*cells)[2], size_t n)
    {
        Valley v;
        for (size_t i = 0; i < n; ++i)
            v.cells.insert({ cells[i][0], cells[i][1] });
        return v;
    }

    struct Storm
    {
        float x = 0.0f, y = 0.0f, heading = 0.0f;
        std::vector<std::pair<std::pair<int, int>, float>> spent;
        float Spent(std::pair<int, int> c) const
        {
            for (auto const& s : spent) if (s.first == c) return s.second;
            return 0.0f;
        }
        void AddSpent(std::pair<int, int> c, float sec)
        {
            for (auto& s : spent) if (s.first == c) { s.second += sec; return; }
            spent.push_back({ c, sec });
        }
    };

    inline Storm Start(Valley const& v)
    {
        std::vector<std::pair<int, int>> cells(v.cells.begin(), v.cells.end());
        std::sort(cells.begin(), cells.end());
        Storm s;
        if (cells.empty())
            return s;
        auto c = cells[cells.size() / 2];
        s.x = (float(c.first) + 0.5f) * CELL;
        s.y = (float(c.second) + 0.5f) * CELL;
        return s;
    }

    template <class Rng>
    void Step(Storm& s, Valley const& v, Rng& rng)
    {
        std::uniform_real_distribution<float> u(-1.0f, 1.0f);
        s.heading += u(rng) * WANDER;
        float best = 1e30f, bestHeading = s.heading;
        bool any = false;
        for (float off : { 0.0f, -0.35f, 0.35f })
        {
            float h = s.heading + off;
            float ax = s.x + std::cos(h) * LOOK, ay = s.y + std::sin(h) * LOOK;
            if (!v.Inside(ax, ay) || !v.Inside(s.x + std::cos(h) * SPEED, s.y + std::sin(h) * SPEED))
                continue;
            float score = s.Spent(Valley::Cell(ax, ay)) + std::fabs(off) * 20.0f + (u(rng) + 1.0f) * 5.0f;
            if (score < best) { best = score; bestHeading = h; any = true; }
        }
        if (!any)
        {
            for (int k = 1; k <= 18 && !any; ++k)
                for (float sign : { 1.0f, -1.0f })
                {
                    float h = s.heading + sign * float(k) * 0.35f;
                    if (v.Inside(s.x + std::cos(h) * LOOK, s.y + std::sin(h) * LOOK) && v.Inside(s.x + std::cos(h) * SPEED, s.y + std::sin(h) * SPEED))
                    { bestHeading = h; any = true; break; }
                }
        }
        s.heading = bestHeading;
        if (any)
        {
            s.x += std::cos(s.heading) * SPEED;
            s.y += std::sin(s.heading) * SPEED;
        }
        s.AddSpent(Valley::Cell(s.x, s.y), 1.0f);
    }

    inline std::pair<uint32_t, float> Reach(float d)
    {
        if (d < DOWNPOUR)
            return { 86, 1.0f };
        if (d < EDGE)
            return { 5, 1.0f - 0.8f * (d - DOWNPOUR) / (EDGE - DOWNPOUR) };
        return { 0, 0.0f };
    }
}

#endif
