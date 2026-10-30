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
#include <deque>
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
    //   nextUse seconds from now of the best plan's first use (-1: never:
    //           the fight ends first, or against trash it is worth more
    //           kept for the next fight)
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

    // {{{ Fight
    // What kind of fight it is, which decides how a lasting buff near the
    // end counts (the owner, 2026-10-30: "for trash mobs, yes it diminishes
    // the value. But for a boss, even if it's the end of the fight we still
    // wanna burn it down as fast as we can, so use everything."):
    //   Trash  only the part before the end counts
    //   Boss   the whole of it counts, however near the end (burning faster
    //          is what shortens the fight)
    // Which enemies make a boss fight (the owner, 2026-10-30): a boss (the
    // game's boss rank, or the dungeon's boss list) or a rare elite in the
    // open world; "not regular elites", which are trash. The server reads
    // it from the enemies in the fight (not built yet).
    enum class Fight { Trash, Boss };
    // }}}

    // {{{ Ending
    // What comes after the fight, which decides what a cooldown is worth
    // kept rather than spent:
    //   fight      the kind of fight (above)
    //   nextWorth  what one use is worth in the next fight that would use
    //              it, against one here (plain uses): after trash 1, the
    //              next pack is the same; after a boss with no boss known to
    //              follow 0, so everything is used; before a harder boss more
    //              than 1, so a big cooldown is saved for it (the owner,
    //              2026-10-30: "better to get the full use of a BL on the
    //              next boss than waste it on an easier boss.")
    //   nextIn     seconds from this fight's end to that next fight's start
    //              (0 after trash: the next pack is pulled at once)
    // A Fight alone gives its ordinary ending: trash before more trash,
    // a boss with nothing after.
    struct Ending
    {
        Fight  fight;
        double nextWorth, nextIn;
        Ending(Fight f) : fight(f), nextWorth(f == Fight::Trash ? 1.0 : 0.0), nextIn(0.0) {}
        Ending(Fight f, double worth, double in) : fight(f), nextWorth(worth), nextIn(in) {}
    };
    // }}}

    // {{{ UseWorth
    // One use at time t, in plain uses: the windows' factor averaged over
    // the time it keeps working. Against trash only what is left before the
    // fight's end counts (a 20-second buff used 5 seconds before the end is
    // worth a quarter of one); against a boss the whole of it does. A use at
    // or after the end is worth nothing either way: the fight is over.
    inline double UseWorth(std::vector<Window> const& windows, double t, double lasts, double fightLeft, Fight fight)
    {
        if (t >= fightLeft) return 0.0;
        if (lasts <= 0.0) return FactorAt(windows, t);
        double sum = 0.0;
        int    n   = static_cast<int>(std::ceil(lasts / STEP));
        for (int k = 0; k < n; ++k)
        {
            double s = t + (k + 0.5) * STEP;
            if (s < fightLeft || fight == Fight::Boss) sum += FactorAt(windows, s);
        }
        return sum / n;
    }
    // }}}

    // {{{ Kept
    // What the cooldown is worth at the fight's end when it comes back
    // `late` seconds after it (0: ready as the fight ends): one use in the
    // next fight at what it is worth there (Ending's nextWorth), less by
    // the share of a cooldown it would still be cooling when that fight
    // starts (`nextIn` seconds after this one ends).
    inline double Kept(double late, double cooldown, Ending const& ending)
    {
        if (ending.nextWorth <= 0.0 || cooldown <= 0.0) return 0.0;
        double cooling = std::max(0.0, late - ending.nextIn);
        return ending.nextWorth * std::max(0.0, 1.0 - cooling / cooldown);
    }
    // }}}

    // {{{ Best
    // The working out: best[i] is the most the cooldown can still be worth
    // when it is ready at the grid's i-th moment. Either it is never used
    // again (kept for after the fight: Kept), or its next use is at some
    // moment j from i on, worth UseWorth there, after which it is ready
    // again a cooldown later. Only moments within one cooldown of i need
    // trying: holding longer than a whole cooldown is never better than
    // using it now and again at the held moment, which it would be ready for
    // by then (and every use is worth something; the future after the held
    // moment is the same). Moments past the end hold what is kept for after
    // the fight. Worked from the fight's end backwards.
    //
    // Kept quick (the owner, 2026-10-30, on the step-by-step working out:
    // "sounds performance intensive, maybe someday we can make this stuff
    // into equations rather than discrete checks. For now this is fine."),
    // two ways, each giving what trying every moment gives (the test checks
    // them against that, tests/buddy-cooldown-plan/):
    //   each use's worth from running totals of the windows' factor, step
    //   by step, so a long buff's average is one subtraction, not a sum
    //   over its length;
    //   the best next use within a cooldown from a running maximum (a
    //   queue of moments, each better than every earlier one after it):
    //   stepping back one moment adds it at the front and lets the one a
    //   cooldown away fall off the back, so no moment is looked at twice.
    // A 30-minute plan of three cooldowns went from about 90 milliseconds
    // to a few.
    //
    // `blocked`: stretches in which it can't be cast at all (its factor is
    // not read): a lockout one of the buddy's own other cooldowns leaves
    // (Divine Shield keeps Avenging Wrath waiting 30 seconds:
    // buddies_lockouts.h, LineUp), or one someone else left on it that is
    // known to run out (the server makes the stretch from the mark's time
    // left). No use is planned in them; when it would be ready inside one,
    // using it now is impossible, and the weight is 0.
    inline Plan Best(Cooldown const& cd, std::vector<Window> const& windows, double fightLeft, Ending const& ending,
                     std::vector<Window> const& blocked = {})
    {
        Plan plan{ 0.0, 0.0, -1.0, 0, 1.0, {} };
        if (fightLeft <= 0.0) return plan;
        int end   = static_cast<int>(std::ceil(fightLeft / STEP));            // first moment at or past the end
        int gap   = std::max(1, static_cast<int>(std::ceil(cd.cooldown / STEP)));
        int ready = static_cast<int>(std::ceil(std::max(0.0, cd.readyIn) / STEP));
        if (ready >= end)                                                      // never ready before the end: only what is kept
        {
            plan.useNow = plan.best = Kept((ready - end) * STEP, cd.cooldown, ending);
            return plan;
        }

        // each use's worth, as UseWorth gives it: a single strike the factor
        // of its moment; a lasting buff the average over the steps it works,
        // from running totals (a step past the end counts 0 against trash,
        // its factor against a boss)
        std::vector<double> worth(end);
        int n = cd.lasts > 0.0 ? static_cast<int>(std::ceil(cd.lasts / STEP)) : 0;
        if (n == 0)
            for (int i = 0; i < end; ++i) worth[i] = FactorAt(windows, i * STEP);
        else
        {
            std::vector<double> total(end + n + 1, 0.0);
            for (int c = 0; c < end + n; ++c)
            {
                double s = (c + 0.5) * STEP;
                total[c + 1] = total[c] + ((s < fightLeft || ending.fight == Fight::Boss) ? FactorAt(windows, s) : 0.0);
            }
            for (int i = 0; i < end; ++i) worth[i] = (total[i + n] - total[i]) / n;
        }

        // a moment inside a blocked stretch can't hold a use: worth so little
        // that no plan picks it
        double const IMPOSSIBLE = -1e18;
        for (Window const& b : blocked)
            for (int i = std::max(0, static_cast<int>(std::ceil(b.start / STEP))); i < end && i * STEP < b.start + b.length; ++i)
                worth[i] = IMPOSSIBLE;

        std::vector<double> best(end + gap + 1, 0.0), via(end, 0.0);          // via[j]: a use at j and the best after
        std::vector<int>    pick(end, -1);                                     // the next use's moment, -1 never (kept)
        for (int k = end; k <= end + gap; ++k) best[k] = Kept((k - end) * STEP, cd.cooldown, ending);
        double kept = Kept(0.0, cd.cooldown, ending);                           // never used again: ready at the end
        std::deque<int> queue;                                                 // front the earliest; each worth more than all before it
        for (int i = end - 1; i >= 0; --i)
        {
            while (!queue.empty() && queue.back() > i + gap) queue.pop_back();  // more than a cooldown away: too late to try
            via[i] = worth[i] + best[i + gap];
            while (!queue.empty() && via[queue.front()] <= via[i] + 1e-9) queue.pop_front();  // as good later: the earlier wins, no hold for nothing
            queue.push_front(i);
            int j = queue.back();
            if (via[j] > kept + 1e-9) { best[i] = via[j]; pick[i] = j; }
            else                      { best[i] = kept;   pick[i] = -1; }
        }

        bool canNow  = worth[ready] > IMPOSSIBLE / 2;
        plan.useNow  = canNow ? worth[ready] + best[ready + gap] : 0.0;
        plan.best    = best[ready];
        plan.nextUse = pick[ready] < 0 ? -1.0 : pick[ready] * STEP;
        for (int i = ready; i < end && pick[i] >= 0; i = pick[i] + gap) plan.at.push_back(pick[i] * STEP);
        plan.uses    = static_cast<int>(plan.at.size());
        plan.weight  = !canNow ? 0.0 : plan.best > 0.0 ? plan.useNow / plan.best : 1.0;
        return plan;
    }
    // }}}

    // {{{ Own
    // One of a buddy's own long cooldowns, for lining them up: its timing,
    // and `gain`, what it multiplies the buddy's worth by while it works
    // (its window factor for this buddy, buddies_window_buffs.h: Arcane
    // Power's +20% damage run through the mage's own abilities). A use of
    // one inside another's working time is worth the other's gain more,
    // because the two multiply. `blocks`: the buddy's other cooldowns (by
    // their place in the list) that a use of this one refuses, and for how
    // many seconds (buddies_lockouts.h, BlocksOwnMs: Divine Shield refuses
    // Avenging Wrath 30 seconds, and Avenging Wrath Divine Shield).
    struct Block { size_t other; double seconds; };
    struct Own { Cooldown cd; double gain; std::vector<Block> blocks = {}; };
    // }}}

    // {{{ Around
    // What cooldown i sees of the others' plans: their uses as windows (each
    // multiplies by its gain while it works) and the stretches their uses
    // block it for.
    inline void Around(size_t i, std::vector<Own> const& own, std::vector<Plan> const& plans, std::vector<Window> const& outside,
                       std::vector<Window>& windows, std::vector<Window>& blocked)
    {
        windows = outside;
        blocked.clear();
        for (size_t k = 0; k < own.size(); ++k)
            if (k != i)
            {
                for (double t : plans[k].at)
                    windows.push_back({ t, std::max(own[k].cd.lasts, STEP), own[k].gain });
                for (Block const& b : own[k].blocks)
                    if (b.other == i)
                        for (double t : plans[k].at) blocked.push_back({ t, b.seconds, 0.0 });
            }
        // and the moments where a use of i would block a use another has
        // already planned: i's lockout on k lasts `seconds`, so a use of i in
        // the `seconds` before one of k's would refuse it. Respecting them,
        // each cooldown fits round the plans made before it, never over them
        // (the order of planning, tried every way in LineUp, decides who
        // fits round whom).
        for (Block const& b : own[i].blocks)
            for (double t : plans[b.other].at) blocked.push_back({ t - b.seconds + 1e-6, b.seconds, 0.0 });
    }
    // }}}

    // {{{ Together
    // What all of a buddy's plans are worth together, each use counted
    // against the others' plans as they finally stand, and what each keeps
    // for after; a use inside a stretch another blocks makes the whole set
    // impossible (-1: no such set).
    inline double Together(std::vector<Own> const& own, std::vector<Plan> const& plans, std::vector<Window> const& outside,
                           double fightLeft, Ending const& ending)
    {
        double sum = 0.0;
        std::vector<Window> windows, blocked;
        for (size_t i = 0; i < own.size(); ++i)
        {
            Around(i, own, plans, outside, windows, blocked);
            for (double t : plans[i].at)
            {
                for (Window const& b : blocked)
                    if (t >= b.start && t < b.start + b.length) return -1.0;
                sum += UseWorth(windows, t, own[i].cd.lasts, fightLeft, ending.fight);
            }
            double back = plans[i].at.empty() ? own[i].cd.readyIn : plans[i].at.back() + own[i].cd.cooldown;
            sum += Kept(std::max(0.0, back - fightLeft), own[i].cd.cooldown, ending);
        }
        return sum;
    }
    // }}}

    // {{{ LineUp
    // Plans each of a buddy's cooldowns with the others' planned uses as
    // windows beside the outside ones (Bloodlust, a weak phase), so they
    // fall together "so that they can be cast as often as optimizable", and
    // with the stretches the others' uses block it for (lockouts). Each
    // plan depends on the others', so it is worked out again a few times
    // (`passes`). Each cooldown plans for itself, so the one planned first
    // takes its best moments and the rest fit round it; when one keeps
    // another waiting (Divine Shield and Avenging Wrath) that order decides
    // who waits, and the first may take a moment that costs the other more
    // than it gains. So every cooldown is tried first in turn (the rest
    // longest first: the long ones have the fewest uses to move), and the
    // set worth most together (Together) is kept. A buddy has a handful of
    // long cooldowns, so that is a handful of tries.
    inline std::vector<Plan> LineUp(std::vector<Own> const& own, std::vector<Window> const& outside, double fightLeft, Ending const& ending, int passes = 3)
    {
        std::vector<size_t> longest(own.size());
        for (size_t i = 0; i < own.size(); ++i) longest[i] = i;
        std::stable_sort(longest.begin(), longest.end(), [&](size_t a, size_t b) { return own[a].cd.cooldown > own[b].cd.cooldown; });

        std::vector<Plan> kept(own.size());
        double            keptWorth = -2.0;
        std::vector<Window> windows, blocked;
        for (size_t first : longest)
        {
            std::vector<size_t> order = { first };
            for (size_t i : longest) if (i != first) order.push_back(i);
            std::vector<Plan> plans(own.size());
            for (int pass = 0; pass < passes; ++pass)
                for (size_t i : order)
                {
                    Around(i, own, plans, outside, windows, blocked);
                    plans[i] = Best(own[i].cd, windows, fightLeft, ending, blocked);
                }
            double worth = Together(own, plans, outside, fightLeft, ending);
            if (worth > keptWorth + 1e-9) { kept = plans; keptWorth = worth; }
        }
        return kept;
    }
    // }}}
}

#endif
