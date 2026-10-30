/*
 * buddies_fight_length.h - a running guess at how long the fight has left
 * (issue 625h, the resource economy, and the fight's length); plain
 * arithmetic, apart from the server, so it can be tested on its own
 * (tests/buddy-fight-length/, scripts/test-buddy-fight-length).
 *
 * For a general audience: how long a fight will last decides how a buddy
 * spends. With a minute left a healer may pour spare mana into damage, and
 * a cooldown is used now because it won't come back in time; with five
 * minutes left both are kept for later (the cooldown timeline, 625f, reads
 * this as the time it plans over). The guess: the enemies' health has been
 * falling at some rate over the last seconds; at that rate, what is left
 * runs out in so long. Known bursts ahead (Bloodlust, a boss's weak phase)
 * are stretches where it falls faster, not a flat amount off; a party
 * member dying or joining changes the rate by their part of the damage.
 * Said in damage and health only: health left and damage per second
 * (strategems/everything-is-damage-and-health.md).
 */

#ifndef MOD_BUDDIES_FIGHT_LENGTH_H
#define MOD_BUDDIES_FIGHT_LENGTH_H

#include "buddies_cooldown_plan.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <vector>

namespace BuddyFight
{
    // {{{ Sample
    // The enemies' health together at a moment (seconds, any clock that
    // only goes forward), read each time the buddy's plan is worked out.
    struct Sample { double t, health; };
    // }}}

    // {{{ Guess
    //   known     false while the health isn't falling (the fight just
    //             started, or the enemies are healed as fast as they're
    //             hurt): there is no end to see yet, and seconds is infinite
    //   rate      health lost per second, as measured
    //   seconds   the time left at that rate, bursts counted
    struct Guess { bool known; double rate, seconds; };
    // }}}

    // {{{ RateOf
    // How fast the health has been falling over the last `window` seconds
    // before `now`: the slope of the straight line that best fits those
    // samples (least squares), so one big hit or a heal on an enemy moves
    // it a little, not wholly. Fewer than two samples, or samples less than
    // a second apart, say nothing yet (0). A rising health (enemies healed
    // faster than hurt, or a new enemy joining) is 0 as well: no end seen.
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
    // }}}

    // {{{ Rescaled
    // The rate after the party changes: `before` and `after` are the
    // party's damage per second by member, summed (a member who died
    // takes theirs away; one who joined adds theirs). An empty party
    // before (nothing to scale from) keeps the rate as measured.
    inline double Rescaled(double rate, double before, double after)
    {
        return before > 0.0 ? rate * after / before : rate;
    }
    // }}}

    // {{{ TimeLeft
    // How long `health` lasts at `rate`, with the bursts ahead (each a
    // stretch from `start` seconds from now, `length` long, in which the
    // health falls `factor` times faster; overlapping ones multiply) worked
    // through stretch by stretch: between two edges of the bursts the rate
    // is steady, so the health it takes is the rate times the stretch.
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
    // }}}
}

#endif
