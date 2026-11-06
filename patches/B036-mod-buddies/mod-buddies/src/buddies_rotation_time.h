/*
 * buddies_rotation_time.h - the global cooldown and the cast times of a
 * buddy's short abilities, weighed as time (issue 625f, the action economy,
 * step 2: "the global cooldown and cast times of the rotation's short
 * abilities are next"); plain arithmetic, apart from the server, so it can
 * be tested on its own (tests/buddy-rotation-time/, scripts/test-buddy-rotation-time).
 *
 * For a general audience: every answer costs time. A cast holds the buddy
 * for its cast time, every ability on the global cooldown holds the next
 * one back for a second and a half (less with haste), and an ability with a
 * cooldown can't be used again for a while. The owner, 2026-10-30: "action
 * economy (global cooldowns primarily, but also cast-times and such.
 * Putting abilities on cooldown is valued to the action economy,
 * especially if it can line up the times on when they come off cooldown so
 * that they can be cast as often as optimizable)". So this looks a few
 * seconds ahead, tries every order of the buddy's short abilities in that
 * time (and waiting for one about to come back), and counts:
 *   - what each cast is worth when it lands (said in damage and health:
 *     strategems/everything-is-damage-and-health.md): nothing for a cast
 *     that movement would cut short or that the target dies under (a
 *     channel: the part before), nothing past the fight's end, and a cast
 *     straddling the look ahead's end by the share of it inside;
 *   - the uses still to come after the look ahead: an ability with a
 *     cooldown C is used about once every C seconds for the rest of the
 *     fight, each use gaining its worth less what the buddy's filler would
 *     have earned in its slot, so a cooldown started sooner leaves more of
 *     them ("putting abilities on cooldown is valued"), and one no better
 *     than the filler is no hurry;
 * then, like the long cooldowns' plan (buddies_cooldown_plan.h), each
 * ability's weight is the best order that starts with it against the best
 * order of all: 1 for the best first cast, less for the others, 0 for one
 * not ready. An ability off the global cooldown (a warrior's Heroic
 * Strike on the next swing, an interrupt) is not in the race: it is
 * slipped in between, weight 1 whenever ready and worth something.
 *
 * What it leaves to the other economies: the resource each cast costs
 * (625h), threat (625j), the long cooldowns (buddies_cooldown_plan.h, whose
 * windows can be folded into a cast's worth by the caller).
 */

#ifndef MOD_BUDDIES_ROTATION_TIME_H
#define MOD_BUDDIES_ROTATION_TIME_H

#include "buddies_ability_data.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <vector>

namespace BuddyRotation
{
    // {{{ Cast
    // One short ability as the look ahead sees it, in seconds:
    //   cast      its cast time (a channel's whole length), before haste
    //   gcd       the global cooldown it starts, before haste (0: off it)
    //   cooldown  its own cooldown (0: none)
    //   readyIn   until it is ready (0: now)
    //   worth     one use, said in damage and health (the caller's: the
    //             ability's own numbers, through the talent draw's weights)
    //   channeled whether its worth comes over the cast (cut short, the
    //             part before) or as it lands (cut short, nothing)
    //   cost      the resource it spends, counted only when the Moment
    //             gives a pool (a pet's lane, 625m; a buddy's own resource
    //             is the resource economy's, 625h)
    //   deadline  seconds from now it must land by to be worth anything (an
    //             interrupt: before the enemy's cast lands; -1: none)
    //   fade      worth lost for each second until it lands (a taunt: the
    //             health lost each second the enemy stays loose; 0: none)
    struct Cast { double cast, gcd, cooldown, readyIn, worth; bool channeled; double cost = 0.0, deadline = -1.0, fade = 0.0; };
    // }}}

    // {{{ FromRow
    // A Cast from the game's own data (the generated buddies_ability_data.h):
    // cast time, global cooldown and cooldown as the game has them. A
    // channel's cast time is 0 in the spell's cast-time column; its length is
    // its aura's (BUDDY_ABILITY_REACH, Mind Flay's 3 seconds), or the
    // caller's `channel` seconds when the table has none (Arcane Missiles).
    // The worth and the readiness are the caller's.
    inline double ChannelSeconds(BuddyAbilityRow const& r)
    {
        for (BuddyAbilityReachRow const& x : BUDDY_ABILITY_REACH)
            if (x.cls == r.cls && std::strcmp(x.name, r.name) == 0)
                return x.lastsMs / 1000.0;
        return 0.0;
    }
    inline Cast FromRow(BuddyAbilityRow const& r, double worth, double readyIn = 0.0, double channel = -1.0)
    {
        double cast = r.channeled ? (channel >= 0.0 ? channel : ChannelSeconds(r)) : std::max(0, r.castMs) / 1000.0;
        return { cast, r.gcdMs / 1000.0, r.cooldownMs / 1000.0, readyIn, worth, r.channeled != 0 };
    }
    // }}}

    // {{{ Moment
    // What the moment says about time, in seconds from now:
    //   gcdLeft    the global cooldown still running (nothing on it starts
    //              before)
    //   haste      the buddy's casting haste as a share (0.3: 30%)
    //   moveIn     movement coming (-1: none), lasting moveFor: a cast with
    //              a cast time can't be under way then (one begun before
    //              and landing after is lost; a channel keeps the part
    //              before); instants go on
    //   targetLeft until the target is dead (-1: unknown): a cast begun
    //              before and landing after is wasted (a channel keeps the
    //              part before); one begun after is on the next enemy
    //   fightLeft  until the fight's end (625h's estimate; -1: unknown,
    //              counted as ASSUME_LEFT): nothing lands after it
    //   ahead      how far the orders are tried (the look ahead)
    //   pool       the resource there is now (-1: not counted), up to
    //              `most`, coming back `regen` a second (625m: a pet's
    //              focus, energy or mana, its own)
    struct Moment
    {
        double gcdLeft = 0.0, haste = 0.0, moveIn = -1.0, moveFor = 2.0, targetLeft = -1.0, fightLeft = -1.0, ahead = 6.0;
        double pool = -1.0, most = 0.0, regen = 0.0;
    };
    // }}}

    // the fight's length when nobody knows it (seconds; ours: a pack's ordinary length)
    static constexpr double ASSUME_LEFT = 30.0;
    // the game's floor for a hastened global cooldown
    static constexpr double GCD_FLOOR   = 1.0;

    // {{{ Answer
    // What the look ahead says:
    //   weight  per ability, the best order starting with it against the
    //           best of all (0: not ready, or worth nothing now); an ability
    //           off the global cooldown 1 when ready
    //   best    the best order's worth (casts in the look ahead and the
    //           uses after it), in the casts' own unit
    //   first   the best order's first ability (-1: waiting is best, or
    //           nothing is ready)
    //   waitFor seconds the best order waits before its first cast (0 when
    //           it casts at once)
    struct Answer { std::vector<double> weight; double best = 0.0; int first = -1; double waitFor = 0.0; };
    // }}}

    // {{{ Hastened
    // A cast time and a global cooldown with haste (the global cooldown no
    // shorter than the game's floor, and none stays none).
    inline double CastTime(Cast const& c, double haste) { return c.cast / (1.0 + haste); }
    inline double GcdTime(Cast const& c, double haste)  { return c.gcd > 0.0 ? std::max(GCD_FLOOR, c.gcd / (1.0 + haste)) : 0.0; }
    // }}}

    // {{{ Landed
    // What one cast begun at t is worth by the moment (Moment says how
    // movement, the target's death and the fight's end each cut it), and by
    // its own deadline and fading (not for a channel: a channel's worth
    // comes over its length).
    inline double Landed(Cast const& c, double t, Moment const& m)
    {
        double len   = CastTime(c, m.haste);
        double lands = t + len;
        double end   = m.fightLeft >= 0.0 ? m.fightLeft : 1e30;
        bool   moves = len > 0.0 && m.moveIn >= 0.0 && t < m.moveIn + m.moveFor;
        bool   dies  = m.targetLeft >= 0.0 && t < m.targetLeft;
        if (c.channeled && len > 0.0)
        {
            double stop = end;
            if (moves) stop = std::min(stop, std::max(t, m.moveIn));
            if (dies)  stop = std::min(stop, m.targetLeft);
            return c.worth * std::clamp((stop - t) / len, 0.0, 1.0);
        }
        if (lands > end || (moves && lands > m.moveIn) || (dies && lands > m.targetLeft)
            || (c.deadline >= 0.0 && lands > c.deadline + 1e-9))
            return 0.0;
        return std::max(0.0, c.worth - c.fade * lands);
    }
    // }}}

    // {{{ Within
    // The share of a cast's slot (begun at t, `slot` long) inside the look
    // ahead: a cast straddling its end counts by that share, so a long cast
    // begun just before the end gets no more than its time there earns.
    inline double Within(double t, double slot, Moment const& m)
    {
        return slot <= 0.0 ? 1.0 : std::clamp((m.ahead - t) / slot, 0.0, 1.0);
    }
    // }}}

    // {{{ Tail
    // The uses after the look ahead. The buddy's steady rate is what its
    // best ability without a cooldown earns per second of its slot (the
    // filler it falls back on); every use of an ability with a cooldown takes
    // a slot from that filler, so a use gains its worth less what the filler
    // would have earned in its slot (nothing, if the filler earns more). An
    // ability ready again at r is used about once every cooldown from
    // max(r, ahead) to the fight's end. So a cooldown started sooner leaves
    // more gainful uses ("putting abilities on cooldown is valued"), and one
    // that earns less than the filler is worth no hurry.
    inline double Rate(std::vector<Cast> const& cs, Moment const& m)
    {
        double rate = 0.0;
        for (Cast const& c : cs)
        {
            double slot = std::max(CastTime(c, m.haste), GcdTime(c, m.haste));
            if (c.gcd > 0.0 && c.cooldown <= 0.0 && slot > 0.0)
                rate = std::max(rate, c.worth / slot);
        }
        return rate;
    }
    inline double Tail(std::vector<Cast> const& cs, std::vector<double> const& readyAt, Moment const& m)
    {
        double left = m.fightLeft >= 0.0 ? m.fightLeft : ASSUME_LEFT;
        double rate = Rate(cs, m);
        double sum  = 0.0;
        for (size_t i = 0; i < cs.size(); ++i)
        {
            Cast const& c = cs[i];
            if (c.cooldown <= 0.0 || c.gcd <= 0.0)
                continue;
            double gain = c.worth - rate * std::max(CastTime(c, m.haste), GcdTime(c, m.haste));
            if (gain > 0.0)
                sum += gain * std::max(0.0, left - std::max(readyAt[i], m.ahead)) / c.cooldown;
        }
        return sum;
    }
    // }}}

    // {{{ Afford, Refill
    // When a cast costing `cost` can be paid, from time t with `pool` then:
    // t itself when the resource isn't counted or there is enough, else
    // when the regeneration makes enough (never, with none). And the pool
    // after dt more seconds of regeneration, no more than the most.
    inline double Afford(Cast const& c, double pool, double t, Moment const& m)
    {
        if (m.pool < 0.0 || c.cost <= pool + 1e-9) return t;
        if (c.cost > m.most + 1e-9 || m.regen <= 0.0) return 1e30;
        return t + (c.cost - pool) / m.regen;
    }
    inline double Refill(double pool, double dt, Moment const& m)
    {
        return m.pool < 0.0 ? pool : std::min(m.most, pool + m.regen * dt);
    }
    // }}}

    // {{{ Search
    // Every order from time t (with `pool` of the resource then): cast any
    // ability on the global cooldown that is ready and paid for (it holds
    // the next cast for the longer of its cast and its global cooldown, and
    // comes back a cooldown after it lands), or wait for the soonest one not
    // yet ready or paid for. Ends at the look ahead; the tail counts the
    // rest. Returns the best worth from here.
    inline double Search(std::vector<Cast> const& cs, std::vector<double>& readyAt, double t, double pool, Moment const& m)
    {
        if (t >= m.ahead)
            return Tail(cs, readyAt, m);
        double best = -1.0, soonest = 1e30;
        for (size_t i = 0; i < cs.size(); ++i)
        {
            Cast const& c = cs[i];
            if (c.gcd <= 0.0)
                continue;                      // off the global cooldown: slipped in, not raced
            double at = std::max(readyAt[i], Afford(c, pool, t, m));
            if (at > t + 1e-9)
            {
                soonest = std::min(soonest, at);
                continue;
            }
            double len  = CastTime(c, m.haste);
            double slot = std::max(len, GcdTime(c, m.haste));
            double keep = readyAt[i];
            readyAt[i]  = c.cooldown > 0.0 ? t + len + c.cooldown : t;
            double left = m.pool < 0.0 ? pool : pool - c.cost;
            double v    = Landed(c, t, m) * Within(t, slot, m) + Search(cs, readyAt, t + slot, Refill(left, slot, m), m);
            readyAt[i]  = keep;
            best = std::max(best, v);
        }
        if (soonest < 1e29)
        {
            double to = std::min(soonest, m.ahead);
            best = std::max(best, Search(cs, readyAt, to, Refill(pool, to - t, m), m));
        }
        if (best < 0.0)
            best = Tail(cs, readyAt, m);       // nothing to cast, nothing coming back
        return best;
    }
    // }}}

    // {{{ Weigh
    // The weights for the talent draw's multiplier (625), the best order's
    // first step, and its worth.
    inline Answer Weigh(std::vector<Cast> const& cs, Moment const& m)
    {
        Answer a;
        a.weight.assign(cs.size(), 0.0);
        std::vector<double> readyAt(cs.size());
        for (size_t i = 0; i < cs.size(); ++i)
            readyAt[i] = cs[i].readyIn;
        double t0    = std::max(0.0, m.gcdLeft);
        double pool0 = Refill(m.pool, t0, m);

        // each ability first (on the global cooldown, ready and paid for by t0)
        std::vector<double> start(cs.size(), -1.0);
        double soonest = 1e30;
        for (size_t i = 0; i < cs.size(); ++i)
        {
            Cast const& c = cs[i];
            if (c.gcd <= 0.0)
                continue;
            double at = std::max(readyAt[i], Afford(c, pool0, t0, m));
            if (at > t0 + 1e-9)
            {
                soonest = std::min(soonest, at);
                continue;
            }
            double len  = CastTime(c, m.haste);
            double slot = std::max(len, GcdTime(c, m.haste));
            double keep = readyAt[i];
            readyAt[i]  = c.cooldown > 0.0 ? t0 + len + c.cooldown : t0;
            double left = m.pool < 0.0 ? pool0 : pool0 - c.cost;
            start[i]    = Landed(c, t0, m) * Within(t0, slot, m) + Search(cs, readyAt, t0 + slot, Refill(left, slot, m), m);
            readyAt[i]  = keep;
        }
        // or waiting for the soonest to come back
        double waiting = soonest < m.ahead ? Search(cs, readyAt, soonest, Refill(pool0, soonest - t0, m), m) : -1.0;

        // the best first cast; waiting only when it is better (a tie casts now)
        a.best = -1.0;
        for (size_t i = 0; i < cs.size(); ++i)
            if (start[i] >= 0.0 && start[i] > a.best + 1e-9)
            {
                a.best  = start[i];
                a.first = int(i);
            }
        if (waiting >= 0.0 && waiting > a.best + 1e-9)
        {
            a.best    = waiting;
            a.first   = -1;
            a.waitFor = soonest - t0;
        }
        if (a.best < 0.0)
            a.best = 0.0;
        for (size_t i = 0; i < cs.size(); ++i)
        {
            if (cs[i].gcd <= 0.0)
                a.weight[i] = (readyAt[i] <= 1e-9 && Afford(cs[i], m.pool, 0.0, m) <= 0.0 && Landed(cs[i], 0.0, m) > 0.0) ? 1.0 : 0.0;
            else if (start[i] > 0.0 && a.best > 0.0)
                a.weight[i] = start[i] / a.best;
        }
        return a;
    }
    // }}}
}

#endif // MOD_BUDDIES_ROTATION_TIME_H
