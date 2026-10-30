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
#include <limits>
#include <vector>

namespace BuddyCurve
{
    // {{{ Holder
    // One character the enemies might attack:
    //   health, maxHealth  now and at most
    //   taken              how much of the enemies' damage it lets through
    //                      when attacked, against the party's reference (1:
    //                      the tank as it stands; a cloth healer more; read
    //                      by the server from what each has taken so far)
    struct Holder { double health, maxHealth, taken; };
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
        double loss = f.damage * h.taken * (1.0 - cut) - f.healing;
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
    inline double Shortfall(std::vector<Holder> holders, std::vector<Stretch> const& stretches, Fight const& f)
    {
        std::vector<double> lowest(holders.size());
        for (size_t i = 0; i < holders.size(); ++i) lowest[i] = holders[i].health;
        for (Stretch const& s : stretches)
        {
            double from = std::max(0.0, s.from), to = std::min(f.left, s.to);
            if (to <= from || s.holder < 0) continue;
            Holder& h = holders[s.holder];
            double loss = (f.damage * h.taken * (1.0 - s.cut) - f.healing) * (to - from);
            h.health = std::min(h.maxHealth, h.health - loss);
            lowest[s.holder] = std::min(lowest[s.holder], h.health);
        }
        double sum = 0.0;
        for (double l : lowest) sum += std::max(0.0, -l);
        return sum;
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
}

#endif
