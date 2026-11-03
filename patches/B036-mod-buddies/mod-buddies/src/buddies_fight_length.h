
#ifndef MOD_BUDDIES_FIGHT_LENGTH_H
#define MOD_BUDDIES_FIGHT_LENGTH_H

#include "buddies_cooldown_plan.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <vector>

namespace BuddyFight
{
    struct Sample { double t, health; };

    struct Guess { bool known; double rate, seconds; };

    inline double RateOf(std::vector<Sample> const& samples, double now, double window)
    {
        double n = 0.0, st = 0.0, sh = 0.0, stt = 0.0, sth = 0.0, first = now, last = now - window;
        for (Sample const& s : samples)
        {
            if (s.t < now - window || s.t > now) continue;
            n += 1.0; st += s.t; sh += s.health; stt += s.t * s.t; sth += s.t * s.health;
            first = std::min(first, s.t);
            last  = std::max(last, s.t);
        }
        if (n < 2.0 || last - first < 1.0) return 0.0;
        double slope = (n * sth - st * sh) / (n * stt - st * st);
        return slope < 0.0 ? -slope : 0.0;
    }

    inline double Rescaled(double rate, double before, double after)
    {
        return before > 0.0 ? rate * after / before : rate;
    }

    inline Guess TimeLeft(double health, double rate, std::vector<BuddyPlan::Window> const& bursts)
    {
        double const inf = std::numeric_limits<double>::infinity();
        if (health <= 0.0) return { true, rate, 0.0 };
        if (rate <= 0.0)   return { false, rate, inf };
        std::vector<double> edges;
        for (BuddyPlan::Window const& b : bursts)
        {
            if (b.start + b.length > 0.0) edges.push_back(std::max(0.0, b.start));
            if (b.start + b.length > 0.0) edges.push_back(b.start + b.length);
        }
        std::sort(edges.begin(), edges.end());
        double t = 0.0, left = health;
        for (double e : edges)
        {
            if (e <= t) continue;
            double r = rate * BuddyPlan::FactorAt(bursts, t);
            if (r * (e - t) >= left) return { true, rate, t + left / r };
            left -= r * (e - t);
            t = e;
        }
        return { true, rate, t + left / (rate * BuddyPlan::FactorAt(bursts, t)) };
    }

    static constexpr double REGULAR_MOST = 600.0;
    inline double Horizon(std::vector<double> const& cooldowns, double regularMost = REGULAR_MOST)
    {
        double longest = 0.0;
        for (double c : cooldowns)
            if (c <= regularMost) longest = std::max(longest, c);
        return 3.0 * longest;
    }
}

#endif
