/*
 * buddies_moment.h - choosing an answer by the moment's economy (issue
 * 625d): how well each of one concern's answers suits the moment, from
 * five measures; plain arithmetic, apart from the server, so it can be
 * tested on its own (tests/buddy-moment/, scripts/test-buddy-moment).
 *
 * For a general audience: the owner, 2026-10-29: "when they're very low,
 * we want fast heals. When they are slightly injured, we want cheap heals.
 * a HoT is usually cheap in the action economy, but overheals are expensive
 * in mana economy. the more concerns we have, the more important action
 * economy is - the less mana we have, the more important mana economy is.
 * more mp5 (from spirit or mp5) means mana economy is devalued and action
 * economy is told to be extravagant. movement requirements mean we have to
 * use things that are mobile friendly, and if those are common in this
 * fight then we try and do the cast-time static abilities when we don't
 * have to move at higher priority so we can save the instant ones for the
 * movement intensive periods. Oh and cooldowns should try and coincide with
 * other cooldowns or procs / buffs that make us feel empowered."
 *
 * The five measures, each a factor for each answer (1: no preference):
 *   1 urgency    fast when very low, cheap when slightly hurt  } the thrift's
 *   3 mana       cost counts by the time mana takes to refill  } Lean (625h)
 *                and never an overheal below 90% mana
 *   2 action     the more concerns firing, the more speed and heals that
 *                keep working on their own count
 *   4 movement   moving: instants only; standing in a fight full of
 *                movement: cast-time answers first, instants saved
 *   5 empowered  a cooldown waits for a moment that multiplies it, but not
 *                past the fight's middle or a critical moment
 * Suit multiplies them; the talent draw (625) multiplies that into its
 * weight. A suit of 0 is a refusal (the multiplier gives the answer 0, which
 * the bot module's engine skips).
 */

#ifndef MOD_BUDDIES_MOMENT_H
#define MOD_BUDDIES_MOMENT_H

#include "buddies_thrift.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <vector>

namespace BuddyMoment
{
    // {{{ the numbers
    // GCD:            the global cooldown, the least an answer takes
    // NO_OVERHEAL:    below this much mana (percent) an answer that would
    //                 overheal is refused (the owner, 2026-10-29: "bots
    //                 should emphasize never overhealing unless they're at
    //                 90% or above mana")
    // BUSY_HOT:       how much more a heal that keeps working counts when
    //                 the buddy is as busy as can be (1: up to double)
    // MOVE_SAVE:      how much more a cast-time answer counts, standing
    //                 still, in a fight spent wholly moving (1: up to double)
    // EMPOWERED:      a cooldown inside an empowered moment (Bloodlust, a
    //                 power buff, another cooldown of its own)
    // HOLD:           a cooldown outside one, before the fight's middle:
    //                 leaned away from, not forbidden
    // HALF:           past this share of the fight's guessed length a
    //                 cooldown is used anyway ("A cooldown is not held so
    //                 long that it is never used")
    constexpr double GCD         = 1.5;
    constexpr double NO_OVERHEAL = 90.0;
    constexpr double BUSY_HOT    = 1.0;
    constexpr double MOVE_SAVE   = 1.0;
    constexpr double EMPOWERED   = 4.0;
    constexpr double HOLD        = 0.25;
    constexpr double HALF        = 0.5;
    // }}}

    // {{{ Answer
    // One of a concern's answers, from the generated ability tables:
    //   cast      its cast time in seconds (0: instant)
    //   cost      its resource cost (0: free)
    //   amount    what it gives (health healed, or damage), all of it, its
    //             ticks over their length included
    //   heal      whether it heals (the overheal rule is for heals)
    //   overTime  a heal (or harm) that keeps working on its own
    //   cooldown  a long cooldown (Nature's Swiftness, Innervate, a trinket)
    struct Answer
    {
        double cast = 0, cost = 0, amount = 0;
        bool   heal = true, overTime = false, cooldown = false;
    };
    // }}}

    // {{{ Moment
    // The buddy's moment, read by the server:
    //   healthPct, missing  the target's health (percent) and the health it
    //                       lacks (the same unit as an answer's amount)
    //   aboutToBeHit        the target has just taken aggro, or is a tank
    //                       charging in: "HoTs can be placed on things
    //                       expecting damage soon"
    //   concerns            how many of the buddy's concerns are firing
    //   manaPct             the buddy's mana, percent
    //   refillSeconds       how long its missing mana takes to come back
    //                       (BuddyThrift::RefillSeconds)
    //   moving              it is moving now
    //   movingShare         the share of this phase it has spent moving
    //                       (Moving below)
    //   empowered           an empowered moment is up (Bloodlust, a power
    //                       buff or proc, another cooldown of its own)
    //   fightDone           the share of the fight's guessed length gone
    //                       (BuddyFight's guess; -1: not known)
    //   critical            the concern is a critical one (an ally about to
    //                       die)
    //   planWeight          the cooldown plan's weight for this cooldown
    //                       (625f, BuddyPlan), when there is one; -1: none
    struct Moment
    {
        double healthPct = 100, missing = 0;
        bool   aboutToBeHit = false;
        int    concerns = 1;
        double manaPct = 100, refillSeconds = 0;
        bool   moving = false;
        double movingShare = 0;
        bool   empowered = false;
        double fightDone = -1;
        bool   critical = false;
        double planWeight = -1;
    };
    // }}}

    // {{{ Seconds
    // The time an answer takes: its cast, or the global cooldown when it is
    // shorter (an instant still spends one).
    inline double Seconds(Answer const& a) { return std::max(a.cast, GCD); }
    // }}}

    // {{{ measures 1 and 3: urgency and mana (the thrift's lean, 625h)
    // How near each answer comes to the fastest and to the cheapest, weighed
    // by the target's hurt and by the time the buddy's mana takes to refill.
    // An answer that gives no amount of its own (a cooldown like Nature's
    // Swiftness, which makes the next answer better) is left out of the
    // comparison and gets 1: it has no health a mana to compare, and a free
    // one would otherwise count as infinitely cheap and zero the rest.
    inline std::vector<double> UrgencyAndMana(std::vector<Answer> const& answers, Moment const& m)
    {
        std::vector<BuddyThrift::Answer> t;
        for (Answer const& a : answers)
            if (a.amount > 0)
                t.push_back({ Seconds(a), a.cost > 0 ? a.amount / a.cost : std::numeric_limits<double>::infinity() });
        std::vector<double> lean = BuddyThrift::Lean(t, BuddyThrift::Weigh(m.healthPct, m.refillSeconds)), out;
        size_t k = 0;
        for (Answer const& a : answers)
            out.push_back(a.amount > 0 ? lean[k++] : 1.0);
        return out;
    }

    // Whether an answer would overheal, and is refused for it: a heal larger
    // than the health missing, below NO_OVERHEAL mana. A heal over time on a
    // target about to be hit is spent on damage about to come, not an
    // overheal ("These are not overheals").
    inline bool Overheals(Answer const& a, Moment const& m)
    {
        if (!a.heal || a.amount <= m.missing) return false;
        if (a.overTime && m.aboutToBeHit) return false;
        return true;
    }
    inline bool Refused(Answer const& a, Moment const& m)
    {
        return Overheals(a, m) && m.manaPct < NO_OVERHEAL;
    }
    // }}}

    // {{{ measure 2: the action economy
    // How busy the buddy is: 0 with one concern firing, 1/2 with two, 3/4
    // with four, toward 1.
    inline double Busy(int concerns) { return concerns <= 1 ? 0.0 : 1.0 - 1.0 / double(concerns); }

    // Each answer: how near it comes to the fastest, to the power of Busy
    // (every second of casting worth more), times 1 + BUSY_HOT x Busy for a
    // heal that keeps working while the buddy answers the next concern.
    inline std::vector<double> Action(std::vector<Answer> const& answers, Moment const& m)
    {
        double busy = Busy(m.concerns), fastest = std::numeric_limits<double>::infinity();
        for (Answer const& a : answers) fastest = std::min(fastest, Seconds(a));
        std::vector<double> out;
        for (Answer const& a : answers)
            out.push_back(std::pow(fastest / Seconds(a), busy) * (a.overTime ? 1.0 + BUSY_HOT * busy : 1.0));
        return out;
    }
    // }}}

    // {{{ measure 4: movement
    // The share of this phase the buddy has spent moving, from steps of the
    // server's update; started again at each phase change (the owner,
    // 2026-10-29: "should reset when the phase changes").
    struct Moving
    {
        double seen = 0, moved = 0;
        void Step(double dt, bool moving)
        {
            if (dt <= 0) return;
            seen += dt;
            if (moving) moved += dt;
        }
        void Phase() { seen = moved = 0; }
        double Share() const { return seen > 0 ? moved / seen : 0.0; }
    };

    // Moving now: a cast-time answer can't be used (0). Standing still: a
    // cast-time answer counts 1 + MOVE_SAVE x the share of the phase spent
    // moving, so the instants are kept for the moving stretches.
    inline double Movement(Answer const& a, Moment const& m)
    {
        if (a.cast <= 0) return 1.0;
        if (m.moving) return 0.0;
        return 1.0 + MOVE_SAVE * std::clamp(m.movingShare, 0.0, 1.0);
    }
    // }}}

    // {{{ measure 5: empowered moments
    // A cooldown: the plan's weight when 625f has one for it; otherwise
    // EMPOWERED inside an empowered moment, 1 in a critical moment or past
    // the fight's middle (used anyway), HOLD before it. Anything else: 1.
    inline double Empowered(Answer const& a, Moment const& m)
    {
        if (!a.cooldown) return 1.0;
        if (m.planWeight >= 0) return m.planWeight;
        if (m.empowered) return EMPOWERED;
        if (m.critical || m.fightDone >= HALF) return 1.0;
        return HOLD;
    }
    // }}}

    // {{{ Suit
    // How well each answer suits the moment: the five measures multiplied,
    // 0 for an answer refused (an overheal below 90% mana, a cast while
    // moving). In the order given.
    inline std::vector<double> Suit(std::vector<Answer> const& answers, Moment const& m)
    {
        std::vector<double> um = UrgencyAndMana(answers, m), act = Action(answers, m), out;
        for (size_t i = 0; i < answers.size(); ++i)
            out.push_back(Refused(answers[i], m) ? 0.0
                          : um[i] * act[i] * Movement(answers[i], m) * Empowered(answers[i], m));
        return out;
    }
    // }}}
}

#endif
