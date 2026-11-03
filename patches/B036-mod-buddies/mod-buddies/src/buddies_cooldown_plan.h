
#ifndef MOD_BUDDIES_COOLDOWN_PLAN_H
#define MOD_BUDDIES_COOLDOWN_PLAN_H

#include <algorithm>
#include <cmath>
#include <deque>
#include <vector>

namespace BuddyPlan
{
    struct Window { double start, length, factor; };

    struct Cooldown { double cooldown, readyIn, lasts; };

    struct Plan { double useNow, best, nextUse; int uses; double weight; std::vector<double> at; };

    inline double FactorAt(std::vector<Window> const& windows, double t)
    {
        double f = 1.0;
        for (Window const& w : windows)
            if (t >= w.start && t < w.start + w.length) f *= w.factor;
        return f;
    }

    static constexpr double STEP = 0.5;

    enum class Fight { Trash, Boss };

    struct Ending
    {
        Fight  fight;
        double nextWorth, nextIn;
        Ending(Fight f) : fight(f), nextWorth(f == Fight::Trash ? 1.0 : 0.0), nextIn(0.0) {}
        Ending(Fight f, double worth, double in) : fight(f), nextWorth(worth), nextIn(in) {}
    };

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

    inline double Kept(double late, double cooldown, Ending const& ending)
    {
        if (ending.nextWorth <= 0.0 || cooldown <= 0.0) return 0.0;
        double cooling = std::max(0.0, late - ending.nextIn);
        return ending.nextWorth * std::max(0.0, 1.0 - cooling / cooldown);
    }

    inline Plan Best(Cooldown const& cd, std::vector<Window> const& windows, double fightLeft, Ending const& ending,
                     std::vector<Window> const& blocked = {})
    {
        Plan plan{ 0.0, 0.0, -1.0, 0, 1.0, {} };
        if (fightLeft <= 0.0) return plan;
        int end   = static_cast<int>(std::ceil(fightLeft / STEP));
        int gap   = std::max(1, static_cast<int>(std::ceil(cd.cooldown / STEP)));
        int ready = static_cast<int>(std::ceil(std::max(0.0, cd.readyIn) / STEP));
        if (ready >= end)
        {
            plan.useNow = plan.best = Kept((ready - end) * STEP, cd.cooldown, ending);
            return plan;
        }

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

        double const IMPOSSIBLE = -1e18;
        for (Window const& b : blocked)
            for (int i = std::max(0, static_cast<int>(std::ceil(b.start / STEP))); i < end && i * STEP < b.start + b.length; ++i)
                worth[i] = IMPOSSIBLE;

        std::vector<double> best(end + gap + 1, 0.0), via(end, 0.0);
        std::vector<int>    pick(end, -1);
        for (int k = end; k <= end + gap; ++k) best[k] = Kept((k - end) * STEP, cd.cooldown, ending);
        double kept = Kept(0.0, cd.cooldown, ending);
        std::deque<int> queue;
        for (int i = end - 1; i >= 0; --i)
        {
            while (!queue.empty() && queue.back() > i + gap) queue.pop_back();
            via[i] = worth[i] + best[i + gap];
            while (!queue.empty() && via[queue.front()] <= via[i] + 1e-9) queue.pop_front();
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

    struct Block { size_t other; double seconds; };
    struct Own { Cooldown cd; double gain; std::vector<Block> blocks = {}; };

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
        for (Block const& b : own[i].blocks)
            for (double t : plans[b.other].at) blocked.push_back({ t - b.seconds + 1e-6, b.seconds, 0.0 });
    }

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
}

#endif
