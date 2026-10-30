/*
 * buddies_curve.h - the curve a buddy keeps in its head: where each
 * character's health is heading over the rest of the fight, given who
 * holds the enemies' attention (issue 625j, the threat economy, step 3;
 * shared with the healer's seat, 625i); plain arithmetic, apart from the
 * server, so it can be tested on its own (tests/buddy-curve/,
 * scripts/test-buddy-curve).
 *
 * For a general audience: the owner, 2026-10-30, on Lay on Hands and Hand
 * of Protection on a dying tank: "Both of these cause the simulation
 * running in their head to no longer have a curve pointed toward "dead
 * tank" and instead point (ideally) toward "victory" or similar." So: the
 * fight is cut into stretches, each with one character holding the
 * enemies' attention. The holder loses health at the enemies' damage (as
 * much as it lets through) less the healing coming in; everyone else
 * holds steady. A curve that would fall below nothing before the fight's
 * end is a death coming, and how far below is the shortfall: the health
 * that would have to be found to live. A lever's worth is the shortfall it
 * takes away, in health (strategems/everything-is-damage-and-health.md):
 * Lay on Hands by adding health where the curve is falling, Hand of
 * Protection by moving the attention to someone who lasts while the tank
 * recovers.
 */

#ifndef MOD_BUDDIES_CURVE_H
#define MOD_BUDDIES_CURVE_H

#include <algorithm>
#include <cmath>
#include <limits>
#include <vector>

namespace BuddyCurve
{
    // {{{ Mark
    // A debuff (or buff) on a character that changes its curve until it
    // wears off, `until` seconds from now: `taken` multiplies the damage it
    // lets through, `healed` the healing it receives (a boss's stacking
    // debuff on its tank: more taken; a healing cut: less healed; a mark
    // that makes it the one the boss should hit: less taken). The owner,
    // 2026-10-30: "sometimes there's debuffs and stuff that can go to a
    // tank, and you do or don't want the boss targeting them for some
    // reason or another." Read by the server from the auras on each one.
    struct Mark { double until, taken, healed; };
    // }}}

    // {{{ Holder
    // One character the enemies might attack:
    //   health, maxHealth  now and at most
    //   taken              how much of the enemies' damage it lets through
    //                      when attacked, against the party's reference (1:
    //                      the tank as it stands; a cloth healer more; read
    //                      by the server from what each has taken so far)
    //   marks              what is on it for a while (Mark)
    struct Holder { double health, maxHealth, taken; std::vector<Mark> marks = {}; };
    // }}}

    // {{{ LossAt
    // What a holder loses each second at time t while attacked, its marks
    // still on counted: the damage it lets through less the healing it
    // takes in.
    inline double LossAt(Holder const& h, double t, double damage, double healing, double cut)
    {
        double taken = h.taken, healed = 1.0;
        for (Mark const& m : h.marks)
            if (t < m.until) { taken *= m.taken; healed *= m.healed; }
        return damage * taken * (1.0 - cut) - healing * healed;
    }
    // }}}

    // {{{ Stretch
    // A stretch of the fight with one holder: from `from` to `to` seconds
    // from now, `holder` attacked; `cut` the share of its damage taken away
    // (Hand of Protection against physical enemies: their physical share;
    // Divine Shield: 1), so 0 is all of it let through.
    struct Stretch { double from, to; int holder; double cut; };
    // }}}

    // {{{ Fight
    // What the fight brings, per second: `damage` the enemies deal to
    // whoever they attack (before `taken`), `healing` the healing that
    // follows the attacked one (the healers heal who is being hit); and
    // `left`, its time left (625h). Healing never lifts a holder above its
    // most.
    struct Fight { double damage, healing, left; };
    // }}}

    // {{{ TimeToDeath
    // How long a holder lasts holding the attention from now: its health
    // over what it loses each second; endless when the healing keeps up.
    inline double TimeToDeath(Holder const& h, Fight const& f, double cut = 0.0)
    {
        double loss = LossAt(h, 0.0, f.damage, f.healing, cut);             // as it stands now, marks on
        return loss > 0.0 ? h.health / loss : std::numeric_limits<double>::infinity();
    }
    // }}}

    // {{{ Shortfall
    // The curves over the stretches, to the fight's end: each holder's
    // health followed stretch by stretch; its lowest point, if below
    // nothing, is how much it falls short. The sum over everyone is the
    // health the party would have to find to see the end with no one dead:
    // 0 is a curve pointed at victory. Stretches are in order and cover what
    // they cover; time not covered has no one attacked.
    // Lost: alongside, what the party loses in all (each holder's health
    // at the start less at the end, healing counted): the damage the
    // healers' mana pays for (625h), compared when no one falls short.
    struct Walk { double short_, lost; };
    inline Walk Follow(std::vector<Holder> holders, std::vector<Stretch> const& stretches, Fight const& f);
    inline double Shortfall(std::vector<Holder> holders, std::vector<Stretch> const& stretches, Fight const& f)
    {
        return Follow(holders, stretches, f).short_;
    }
    inline Walk Follow(std::vector<Holder> holders, std::vector<Stretch> const& stretches, Fight const& f)
    {
        double start = 0.0;
        for (Holder const& h : holders) start += h.health;
        std::vector<double> lowest(holders.size());
        for (size_t i = 0; i < holders.size(); ++i) lowest[i] = holders[i].health;
        for (Stretch const& s : stretches)
        {
            double from = std::max(0.0, s.from), to = std::min(f.left, s.to);
            if (to <= from || s.holder < 0) continue;
            Holder& h = holders[s.holder];
            // a stretch is cut where a mark wears off, so each piece loses
            // at one steady rate
            std::vector<double> edges = { from, to };
            for (Mark const& m : h.marks)
                if (m.until > from && m.until < to) edges.push_back(m.until);
            std::sort(edges.begin(), edges.end());
            for (size_t e = 0; e + 1 < edges.size(); ++e)
            {
                double loss = LossAt(h, edges[e], f.damage, f.healing, s.cut) * (edges[e + 1] - edges[e]);
                h.health = std::min(h.maxHealth, h.health - loss);
                lowest[s.holder] = std::min(lowest[s.holder], h.health);
            }
        }
        double sum = 0.0, end = 0.0;
        for (double l : lowest) sum += std::max(0.0, -l);
        for (Holder const& h : holders) end += h.health;
        return { sum, start - end };
    }
    // }}}

    // {{{ Durable
    // Who lasts longest holding the attention (an index; -1 none): the
    // owner, 2026-10-30, "it's important to keep the attention onto a tank
    // or a durable character - the more durable, the better."
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
    // }}}

    // {{{ the levers, as curves
    // Nothing done: the tank holds to the end.
    inline double AsItIs(std::vector<Holder> const& holders, int tank, Fight const& f)
    {
        return Shortfall(holders, { { 0.0, f.left, tank, 0.0 } }, f);
    }
    // A heal of `amount` on the tank now (Lay on Hands: the paladin's whole
    // health), the attention left where it is.
    inline double HealNow(std::vector<Holder> holders, int tank, double amount, Fight const& f)
    {
        holders[tank].health = std::min(holders[tank].maxHealth, holders[tank].health + amount);
        return AsItIs(holders, tank, f);
    }
    // The tank made immune for `lasts` seconds (Hand of Protection; Divine
    // Shield on a paladin tank): the attention goes to `next` (the next in
    // line on the enemies' lists, buddies_threat.h's Attention) and comes
    // back with the tank's first act after, `back` seconds later (a global
    // cooldown or so). The healing follows the attention, so the tank
    // gains nothing while it isn't attacked.
    inline double Protect(std::vector<Holder> const& holders, int tank, int next, double lasts, double back, Fight const& f)
    {
        return Shortfall(holders, { { 0.0, lasts + back, next, 0.0 }, { lasts + back, f.left, tank, 0.0 } }, f);
    }
    // }}}

    // {{{ Swap
    // Which tank should hold the attention, and when it should change
    // hands (the owner, 2026-10-30: "the main and off-tank roles can switch
    // naturally and elegantly during the fight. But, they should keep in
    // mind which tank would be best suited to hold the attention, and they
    // should taunt accordingly."). Tried: the one holding now keeps it; each
    // other tank taunts now; and each swap at a moment a mark wears off
    // (the debuffed tank hands over, or takes back once it's clean), one
    // swap or a swap and a swap back, at the moments marks wear off and
    // every few seconds between (so two tanks can share a long fight's
    // damage, each healed while it holds). Kept: the plan that leaves the
    // team least short; on a tie the one that loses least in all (a tank
    // whose mark halves what it takes is the one the boss should hit, even
    // with no one dying); then the one with fewer swaps, so nothing changes
    // hands for nothing. `taunt` is the lag before a taunt takes hold (0: at
    // once; a taunt on cooldown: until it is ready).
    //   holder   who should hold the attention now
    //   at, to   the next change of hands planned: at `at` seconds, to `to`
    //            (-1: none planned)
    //   short_   the plan's shortfall, in health
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
        double step = std::max(5.0, f.left / 24.0);                            // at most two dozen moments between
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
                double take = at + taunt;                                       // the taunt takes hold
                if (take >= f.left) continue;
                // one swap: current until it, then the other
                // (a change at once, with the taunt ready, is the holder now;
                // otherwise the holder now keeps it and the change is next)
                bool now = at <= 0.0 && taunt <= 0.0;
                consider({ { 0.0, take, current, 0.0 }, { take, f.left, other, 0.0 } }, 1,
                         now ? SwapPlan{ other, -1.0, -1, 0.0 } : SwapPlan{ current, at, other, 0.0 });
                // and back again at a later moment
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
    // }}}
}

#endif
