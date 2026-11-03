
#ifndef MOD_BUDDIES_CURVE_H
#define MOD_BUDDIES_CURVE_H

#include <algorithm>
#include <cmath>
#include <limits>
#include <vector>

namespace BuddyCurve
{
    struct Mark { double until, taken, healed; };

    struct Holder { double health, maxHealth, taken; std::vector<Mark> marks = {}; };

    inline double LossAt(Holder const& h, double t, double damage, double healing, double cut)
    {
        double taken = h.taken, healed = 1.0;
        for (Mark const& m : h.marks)
            if (t < m.until) { taken *= m.taken; healed *= m.healed; }
        return damage * taken * (1.0 - cut) - healing * healed;
    }

    struct Stretch { double from, to; int holder; double cut; };

    struct Fight { double damage, healing, left; };

    inline double TimeToDeath(Holder const& h, Fight const& f, double cut = 0.0)
    {
        double loss = LossAt(h, 0.0, f.damage, f.healing, cut);
        return loss > 0.0 ? h.health / loss : std::numeric_limits<double>::infinity();
    }

    struct Lump { double at; int holder; double amount; };
    struct Walk { double short_, lost; };
    inline Walk Follow(std::vector<Holder> holders, std::vector<Stretch> const& stretches, Fight const& f, std::vector<Lump> const& lumps = {});
    inline double Shortfall(std::vector<Holder> holders, std::vector<Stretch> const& stretches, Fight const& f, std::vector<Lump> const& lumps = {})
    {
        return Follow(holders, stretches, f, lumps).short_;
    }
    inline Walk Follow(std::vector<Holder> holders, std::vector<Stretch> const& stretches, Fight const& f, std::vector<Lump> const& lumps)
    {
        double start = 0.0;
        for (Holder const& h : holders) start += h.health;
        std::vector<double> lowest(holders.size());
        for (size_t i = 0; i < holders.size(); ++i) lowest[i] = holders[i].health;
        std::vector<bool> landed(lumps.size(), false);
        auto land = [&](size_t k) {
            Lump const& l = lumps[k];
            landed[k] = true;
            if (l.holder < 0 || static_cast<size_t>(l.holder) >= holders.size() || l.at >= f.left) return;
            Holder& h = holders[l.holder];
            double taken = 1.0;
            for (Mark const& m : h.marks) if (l.at < m.until) taken *= m.taken;
            h.health -= l.amount * taken;
            lowest[l.holder] = std::min(lowest[l.holder], h.health);
        };
        for (Stretch const& s : stretches)
        {
            double from = std::max(0.0, s.from), to = std::min(f.left, s.to);
            for (size_t k = 0; k < lumps.size(); ++k) if (!landed[k] && lumps[k].at <= from) land(k);
            if (to <= from || s.holder < 0) continue;
            Holder& h = holders[s.holder];
            std::vector<double> edges = { from, to };
            for (Mark const& m : h.marks)
                if (m.until > from && m.until < to) edges.push_back(m.until);
            for (Lump const& l : lumps)
                if (l.holder == s.holder && l.at > from && l.at < to) edges.push_back(l.at);
            std::sort(edges.begin(), edges.end());
            for (size_t e = 0; e + 1 < edges.size(); ++e)
            {
                double loss = LossAt(h, edges[e], f.damage, f.healing, s.cut) * (edges[e + 1] - edges[e]);
                h.health = std::min(h.maxHealth, h.health - loss);
                lowest[s.holder] = std::min(lowest[s.holder], h.health);
                for (size_t k = 0; k < lumps.size(); ++k)
                    if (!landed[k] && lumps[k].holder == s.holder && lumps[k].at <= edges[e + 1]) land(k);
            }
        }
        for (size_t k = 0; k < lumps.size(); ++k) if (!landed[k]) land(k);
        double sum = 0.0, end = 0.0;
        for (double l : lowest) sum += std::max(0.0, -l);
        for (Holder const& h : holders) end += h.health;
        return { sum, start - end };
    }

    inline int Durable(std::vector<Holder> const& holders, Fight const& f, int skip = -1)
    {
        int best = -1;
        double longest = -1.0;
        for (size_t i = 0; i < holders.size(); ++i)
        {
            if (static_cast<int>(i) == skip) continue;
            double t = TimeToDeath(holders[i], f);
            if (t > longest) { longest = t; best = static_cast<int>(i); }
        }
        return best;
    }

    inline double AsItIs(std::vector<Holder> const& holders, int tank, Fight const& f)
    {
        return Shortfall(holders, { { 0.0, f.left, tank, 0.0 } }, f);
    }
    inline double HealNow(std::vector<Holder> holders, int tank, double amount, Fight const& f)
    {
        holders[tank].health = std::min(holders[tank].maxHealth, holders[tank].health + amount);
        return AsItIs(holders, tank, f);
    }
    inline double Protect(std::vector<Holder> const& holders, int tank, int next, double lasts, double back, Fight const& f)
    {
        return Shortfall(holders, { { 0.0, lasts + back, next, 0.0 }, { lasts + back, f.left, tank, 0.0 } }, f);
    }

    struct SwapPlan { int holder; double at; int to; double short_; };
    inline SwapPlan Swap(std::vector<Holder> const& holders, std::vector<int> const& tanks, int current, Fight const& f, double taunt = 0.0)
    {
        Walk keep = Follow(holders, { { 0.0, f.left, current, 0.0 } }, f);
        SwapPlan best{ current, -1.0, -1, keep.short_ };
        double bestLost = keep.lost;
        int bestSwaps = 0;
        std::vector<double> moments = { 0.0 };
        for (int t : tanks)
            for (Mark const& m : holders[t].marks)
                if (m.until > 0.0 && m.until < f.left) moments.push_back(m.until);
        double step = std::max(5.0, f.left / 24.0);
        for (double t = step; t < f.left; t += step) moments.push_back(t);
        std::sort(moments.begin(), moments.end());
        auto consider = [&](std::vector<Stretch> const& plan, int swaps, SwapPlan candidate) {
            Walk w = Follow(holders, plan, f);
            bool better = w.short_ < best.short_ - 1e-6
                       || (std::fabs(w.short_ - best.short_) <= 1e-6 && w.lost < bestLost - 1e-6)
                       || (std::fabs(w.short_ - best.short_) <= 1e-6 && std::fabs(w.lost - bestLost) <= 1e-6 && swaps < bestSwaps);
            if (better)
            {
                best = candidate;
                best.short_ = w.short_;
                bestLost = w.lost;
                bestSwaps = swaps;
            }
        };
        for (int other : tanks)
        {
            if (other == current) continue;
            for (double at : moments)
            {
                double take = at + taunt;
                if (take >= f.left) continue;
                bool now = at <= 0.0 && taunt <= 0.0;
                consider({ { 0.0, take, current, 0.0 }, { take, f.left, other, 0.0 } }, 1,
                         now ? SwapPlan{ other, -1.0, -1, 0.0 } : SwapPlan{ current, at, other, 0.0 });
                for (double back : moments)
                {
                    double again = back + taunt;
                    if (back <= at || again >= f.left) continue;
                    consider({ { 0.0, take, current, 0.0 }, { take, again, other, 0.0 }, { again, f.left, current, 0.0 } }, 2,
                             now ? SwapPlan{ other, back, current, 0.0 } : SwapPlan{ current, at, other, 0.0 });
                }
            }
        }
        return best;
    }
}

#endif
