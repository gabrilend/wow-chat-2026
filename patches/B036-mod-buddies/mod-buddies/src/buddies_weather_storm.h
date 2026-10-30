/*
 * buddies_weather_storm.h - the storm that wanders Alterac Valley (issue
 * 921b); plain arithmetic, apart from the server, so it can be tested on
 * its own (tests/buddy-weather/storm-check.cpp, scripts/test-buddy-weather).
 *
 * For a general audience: the owner asked for "A storm cloud should wander
 * across the map and always be intensely downpowering". One storm, shared
 * by every match, drifts at a walking pace, keeping its heading for a while
 * and turning gently. It never leaves the valley: the valley is the ground
 * within a cell or two of the battleground's own known places (its
 * graveyards, towers, creatures), and a step that would leave it turns the
 * storm back. It leans toward the parts it has visited least, so over a long
 * match every part has its share. Within 60 yards of its middle everyone is
 * in the heaviest rain with thunder; out to 90 yards the rain thins; beyond
 * that, the shared sky.
 */

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
    // {{{ the numbers
    // SPEED:      yards a second (921b: "2 yards a second").
    // WANDER:     the most it turns a second by chance, radians.
    // LOOK:       how far ahead it judges where it is heading, yards.
    // CELL:       the valley's cells and the visit counts, yards a side.
    // NEAR_CELLS: a cell within this many cells of a known place is valley.
    // DOWNPOUR, EDGE: the storm's reach: full within the first, thinning to
    //             nothing at the second (921b, question 1).
    static constexpr float SPEED      = 2.0f;
    static constexpr float WANDER     = 0.05f;
    static constexpr float LOOK       = 60.0f;
    static constexpr float CELL       = 50.0f;
    static constexpr int   NEAR_CELLS = 1;
    static constexpr float DOWNPOUR   = 60.0f;
    static constexpr float EDGE       = 90.0f;
    // }}}

    // {{{ Valley
    // The cells that are valley, and how long the storm has been over each.
    struct Valley
    {
        std::set<std::pair<int, int>> cells;
        std::vector<std::pair<std::pair<int, int>, float>> visits;   // filled as the storm goes
        // {{{ Cell
        static std::pair<int, int> Cell(float x, float y) { return { int(std::floor(x / CELL)), int(std::floor(y / CELL)) }; }
        // }}}
        // {{{ Inside
        bool Inside(float x, float y) const { return cells.count(Cell(x, y)) > 0; }
        // }}}
    };
    // }}}

    // {{{ ValleyFrom
    // The valley from known places (x, y): each place's cell and its
    // neighbours within NEAR_CELLS.
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
    // }}}

    // {{{ ValleyFromCells
    // The valley from its cells as generated (buddies_av_valley_data.h).
    inline Valley ValleyFromCells(int const (*cells)[2], size_t n)
    {
        Valley v;
        for (size_t i = 0; i < n; ++i)
            v.cells.insert({ cells[i][0], cells[i][1] });
        return v;
    }
    // }}}

    // {{{ Storm
    // Where it is, which way it heads, and the seconds it has spent over
    // each cell (the lean's memory).
    struct Storm
    {
        float x = 0.0f, y = 0.0f, heading = 0.0f;
        std::vector<std::pair<std::pair<int, int>, float>> spent;   // cell -> seconds over it
        // {{{ Spent
        float Spent(std::pair<int, int> c) const
        {
            for (auto const& s : spent) if (s.first == c) return s.second;
            return 0.0f;
        }
        // }}}
        // {{{ AddSpent
        void AddSpent(std::pair<int, int> c, float sec)
        {
            for (auto& s : spent) if (s.first == c) { s.second += sec; return; }
            spent.push_back({ c, sec });
        }
        // }}}
    };
    // }}}

    // {{{ Start
    // Where the storm starts: the middle of the valley's middle cell by x
    // (along its length).
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
    // }}}

    // {{{ Step
    // One second of wandering. The heading drifts by chance (at most WANDER);
    // three headings are judged (straight, and a little either side), each
    // by the time already spent over the cell LOOK yards along it, the least
    // spent preferred, valley only; with none of the three in the valley it
    // turns about in steps until one is. Then it moves SPEED yards.
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
            // the least visited wins, a little chance mixed in so it isn't a machine
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
    // }}}

    // {{{ Reach
    // The weather a player d yards from the storm's middle is given: within
    // DOWNPOUR the heaviest rain with thunder (state 86, thunders, grade 1);
    // to EDGE the rain thinning (heavy rain, state 5, grade 1 down to 0.2);
    // beyond, none of the storm's (state 0: the shared sky stands).
    inline std::pair<uint32_t, float> Reach(float d)
    {
        if (d < DOWNPOUR)
            return { 86, 1.0f };
        if (d < EDGE)
            return { 5, 1.0f - 0.8f * (d - DOWNPOUR) / (EDGE - DOWNPOUR) };
        return { 0, 0.0f };
    }
    // }}}
}

#endif
