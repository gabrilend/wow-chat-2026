/*
 * buddies_cooldown_plan.h - when a buddy should use a long cooldown, so its
 * uses over the rest of the fight are worth the most (issue 625f, the
 * action economy: "most valuable uptime"); plain arithmetic, apart from the
 * server, so it can be tested on its own (tests/buddy-cooldown-plan/,
 * scripts/test-buddy-cooldown-plan).
 *
 * For a general audience: a cooldown used now comes back in C seconds; one
 * held for a better moment (Bloodlust, a boss's weak phase) is worth more
 * when it lands, but may lose a whole use before the fight ends. The owner,
 * 2026-10-30: "we want to maximize valuable uptime." So this works out, for
 * one cooldown, the best set of moments to use it over the time the fight
 * has left: each use worth what the moment multiplies it by (the window
 * factors, from buddies_window_buffs.h, said in damage and health), the
 * uses at least C apart, none after the end. Holding is right only when the
 * best plan starts later than now; how much worse "use it now" is than the
 * best plan becomes the weight the talent draw reads (625), so a buddy that
 * should hold leans away from the cooldown rather than being forbidden it.
 *
 * Units: a use's worth is counted in plain uses (1 = the cooldown used
 * outside any window). The weight is a ratio, so it needs no unit; to
 * compare one cooldown's plan with another's, multiply by the use's own
 * worth in damage and health (what the cooldown gives, run through the
 * buddy's abilities: strategems/everything-is-damage-and-health.md).
 */

#ifndef MOD_BUDDIES_COOLDOWN_PLAN_H
#define MOD_BUDDIES_COOLDOWN_PLAN_H

#include <algorithm>
#include <cmath>
#include <vector>

namespace BuddyPlan
{
    // {{{ Window
    // An empowered stretch ahead: it starts `start` seconds from now (0 or
    // less: already running), lasts `length` seconds, and multiplies what a
    // use inside it is worth by `factor` (a buff's window factor for this
    // buddy, or another of its own cooldowns' planned uses, so cooldowns
    // line up with each other). Overlapping windows multiply.
    struct Window { double start, length, factor; };
    // }}}

    // {{{ Cooldown
    // One cooldown as the plan sees it, in seconds: `cooldown` its length,
    // `readyIn` how long until it is ready (0: ready now), `lasts` how long
    // one use keeps working (a buff's duration; 0 for a single strike or
    // heal, worth the moment it lands).
    struct Cooldown { double cooldown, readyIn, lasts; };
    // }}}

    // {{{ Plan
    // What the working out says, in plain uses:
    //   useNow  the most the rest of the fight is worth if it is used the
    //           moment it is ready
    //   best    the most it is worth by any plan
    //   nextUse seconds from now of the best plan's first use (-1: never,
    //           the fight ends first)
    //   uses    how many uses the best plan has
    //   weight  useNow / best: 1 when using it at once is the best plan,
    //           less the more holding gains (1 also when nothing is to be
    //           gained either way)
    //   at      every use of the best plan, seconds from now (what the
    //           buddy's other cooldowns line up with, LineUp)
    struct Plan { double useNow, best, nextUse; int uses; double weight; std::vector<double> at; };
    // }}}

    // {{{ FactorAt
    // What the windows multiply a use at time t by.
    inline double FactorAt(std::vector<Window> const& windows, double t)
    {
        double f = 1.0;
        for (Window const& w : windows)
            if (t >= w.start && t < w.start + w.length) f *= w.factor;
        return f;
    }
    // }}}

    // the grid's step, seconds: fine next to a 90-second-or-longer cooldown,
    // coarse enough that a buddy's whole plan is a few thousand sums
    static constexpr double STEP = 0.5;

    // {{{ UseWorth
    // One use at time t, in plain uses: the windows' factor averaged over
    // the time it keeps working, counting only what is left before the
    // fight's end (a 20-second buff used 5 seconds before the end is worth
    // a quarter of one; a single strike is worth the factor of its moment,
    // or nothing at or after the end).
    inline double UseWorth(std::vector<Window> const& windows, double t, double lasts, double fightLeft)
    {
        if (t >= fightLeft) return 0.0;
        if (lasts <= 0.0) return FactorAt(windows, t);
        double sum = 0.0;
        int    n   = static_cast<int>(std::ceil(lasts / STEP));
        for (int k = 0; k < n; ++k)
        {
            double s = t + (k + 0.5) * STEP;
            if (s < fightLeft) sum += FactorAt(windows, s);
        }
        return sum / n;
    }
    // }}}

    // {{{ Best
    // The working out: best[i] is the most the cooldown can still be worth
    // when it is ready at the grid's i-th moment. Either it is never used
    // again (0), or its next use is at some moment j from i on, worth
    // UseWorth there, after which it is ready again a cooldown later.
    // Only moments within one cooldown of i need trying: holding longer than
    // a whole cooldown is never better than using it now and again at the
    // held moment, which it would be ready for by then (and every use is
    // worth something). Worked from the fight's end backwards.
    inline Plan Best(Cooldown const& cd, std::vector<Window> const& windows, double fightLeft)
    {
        Plan plan{ 0.0, 0.0, -1.0, 0, 1.0, {} };
        if (fightLeft <= 0.0) return plan;
        int end   = static_cast<int>(std::ceil(fightLeft / STEP));            // first moment at or past the end
        int gap   = std::max(1, static_cast<int>(std::ceil(cd.cooldown / STEP)));
        int ready = static_cast<int>(std::ceil(std::max(0.0, cd.readyIn) / STEP));
        if (ready >= end) return plan;                                         // never ready before the end

        std::vector<double> worth(end), best(end + gap + 1, 0.0);
        std::vector<int>    pick(end, -1);                                     // the next use's moment, -1 never
        for (int i = 0; i < end; ++i) worth[i] = UseWorth(windows, i * STEP, cd.lasts, fightLeft);
        for (int i = end - 1; i >= 0; --i)
        {
            double top = 0.0;
            int    at  = -1;
            for (int j = i; j < end && j <= i + gap; ++j)
            {
                double v = worth[j] + best[j + gap];
                if (v > top + 1e-9) { top = v; at = j; }                       // the earliest of equals: no hold for nothing
            }
            best[i] = top;
            pick[i] = at;
        }

        plan.useNow  = worth[ready] + best[ready + gap];
        plan.best    = best[ready];
        plan.nextUse = pick[ready] < 0 ? -1.0 : pick[ready] * STEP;
        for (int i = ready; i < end && pick[i] >= 0; i = pick[i] + gap) plan.at.push_back(pick[i] * STEP);
        plan.uses    = static_cast<int>(plan.at.size());
        plan.weight  = plan.best > 0.0 ? plan.useNow / plan.best : 1.0;
        return plan;
    }
    // }}}

    // {{{ Own
    // One of a buddy's own long cooldowns, for lining them up: its timing,
    // and `gain`, what it multiplies the buddy's worth by while it works
    // (its window factor for this buddy, buddies_window_buffs.h: Arcane
    // Power's +20% damage run through the mage's own abilities). A use of
    // one inside another's working time is worth the other's gain more,
    // because the two multiply.
    struct Own { Cooldown cd; double gain; };
    // }}}

    // {{{ LineUp
    // Plans each of a buddy's cooldowns with the others' planned uses as
    // windows beside the outside ones (Bloodlust, a weak phase), so they
    // fall together "so that they can be cast as often as optimizable".
    // Each plan depends on the others', so it is worked out again a few
    // times (`passes`), longest cooldown first in each pass: the long ones
    // have the fewest uses to move, so the short ones fit round them. Three
    // passes settle the cases tested; a plan that still moves after them is
    // used as it stands (the next working out, a moment later, starts from
    // the world as it is then).
    inline std::vector<Plan> LineUp(std::vector<Own> const& own, std::vector<Window> const& outside, double fightLeft, int passes = 3)
    {
        std::vector<Plan>   plans(own.size());
        std::vector<size_t> order(own.size());
        for (size_t i = 0; i < own.size(); ++i) order[i] = i;
        std::stable_sort(order.begin(), order.end(), [&](size_t a, size_t b) { return own[a].cd.cooldown > own[b].cd.cooldown; });
        for (int pass = 0; pass < passes; ++pass)
            for (size_t i : order)
            {
                std::vector<Window> windows = outside;
                for (size_t k = 0; k < own.size(); ++k)
                    if (k != i)
                        for (double t : plans[k].at)
                            windows.push_back({ t, std::max(own[k].cd.lasts, STEP), own[k].gain });
                plans[i] = Best(own[i].cd, windows, fightLeft);
            }
        return plans;
    }
    // }}}
}

#endif
