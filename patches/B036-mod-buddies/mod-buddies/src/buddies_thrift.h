/*
 * buddies_thrift.h - the resource economy (issue 625h, steps 1 and 3): the
 * bot module's hard health and mana lines made smooth, a buddy's resource
 * measured as the time it takes to come back, and the surplus it holds
 * until the fight's end; plain arithmetic, apart from the server, so it can
 * be tested on its own (tests/buddy-thrift/, scripts/test-buddy-thrift).
 *
 * For a general audience: the owner, 2026-10-30, on the lean from cheap
 * heals to fast ones: "smoothly. Also those breakpoints should be smoothed
 * as well." And on a healer's spare mana: "a trash mob fight for example
 * might not require a long-duration stretch of healing, so they can freely
 * throw out damage spells inbetween casting their most powerful and
 * expensive spells on the tank or whoever needs it. However in a longer
 * fight they are less likely to cast damage spells because they probably
 * will need their mana. However if the fight is ending sooner than their
 * mana supply demands, then they can cast out damage spells as well."
 *
 * So, in four pieces:
 *   - the lines, smoothed: the bot module's health bands (critical below
 *     25%, low 45, medium 65, almost full 85) and its one mana line (save
 *     mana below 60%) each fade in over SOFTNESS points either side, so an
 *     ally at 44% and one at 46% are treated almost alike (Hurt, Saving);
 *   - regeneration as time: what comes back each second at the moment (in
 *     combat the slow kind, spirit only past the game's five seconds
 *     without casting; between fights the fast kind, with drinking), and
 *     the seconds the missing part takes to come back; under BARELY
 *     seconds a cost barely matters, past EVERY every cost counts (Thrift);
 *   - the lean among answers: fast answers for the badly hurt, cheap ones
 *     for the slightly hurt, the more so the longer the buddy's resource
 *     takes to come back (Weigh, Lean);
 *   - the surplus: what it holds and what comes back by the fight's end
 *     (buddies_fight_length.h's guess), less what it will need by then,
 *     counted a third longer than the guess (MARGIN); a surplus lets
 *     damage spells in between heals (DamageLean). Between fights, a buddy
 *     low on mana drinks and says "mana" so the tank waits (617z's word),
 *     and "ready" when it is full again (Rest).
 * Every number here is the agent's call (2026-11-06), to be judged in game.
 */

#ifndef MOD_BUDDIES_THRIFT_H
#define MOD_BUDDIES_THRIFT_H

#include "buddies_fight_length.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <vector>

namespace BuddyThrift
{
    // {{{ the lines
    // The bot module's health bands (critical, low, medium, almost full) and
    // its save-mana line, in percent; how far either side of a line it fades
    // in, in points (two lines 20 apart, faded 10 either side, meet without
    // overlapping: the smoothed staircase still climbs one step per band).
    constexpr double BANDS[4]  = { 25.0, 45.0, 65.0, 85.0 };
    constexpr double SAVE_MANA = 60.0;
    constexpr double SOFTNESS  = 10.0;
    // }}}

    // {{{ the times
    // Regeneration as time (625h): under BARELY seconds to refill, a cost
    // barely matters; past EVERY, every cost counts; the game's five-second
    // rule for spirit; mana a surplus must cover SPARE_CASTS damage casts of
    // before damage spells come fully in; the guess counted a third longer
    // than it says (question 1: "spend as soon as the estimate says there is
    // surplus, or only with a margin (say the estimate could be a third too
    // short)?", answered with the margin, 2026-11-06).
    constexpr double BARELY           =  30.0;
    constexpr double EVERY            = 120.0;
    constexpr double FIVE_SECOND_RULE =   5.0;
    constexpr double SPARE_CASTS      =   3.0;
    constexpr double MARGIN           = 1.0 / 3.0;
    constexpr double AWAY             =   0.05;   // the leans' "stop doing that" (as the healer's seat's)
    // }}}

    // {{{ the drinking
    // Between fights, in percent of mana: a buddy below DRINK_BELOW drinks
    // (the bot module's save-mana line, reused), and keeps drinking until
    // DRINK_UNTIL, so the next fight starts fresh.
    constexpr double DRINK_BELOW =  60.0;
    constexpr double DRINK_UNTIL = 100.0;
    // }}}

    // {{{ Smooth
    // 0 at or below `from`, 1 at or above `to`, and between them the smooth
    // step 3t^2 - 2t^3 (no jump, and no kink at either end).
    inline double Smooth(double x, double from, double to)
    {
        if (to <= from) return x < from ? 0.0 : 1.0;
        double t = std::clamp((x - from) / (to - from), 0.0, 1.0);
        return t * t * (3.0 - 2.0 * t);
    }
    // }}}

    // {{{ Below
    // How far `x` is below a line at `edge`: 1 well below it, 0 well above,
    // smooth over `softness` either side (0.5 on the line itself).
    inline double Below(double x, double edge, double softness = SOFTNESS)
    {
        return 1.0 - Smooth(x, edge - softness, edge + softness);
    }
    // }}}

    // {{{ Hurt
    // How badly hurt an ally at `healthPct` is, 0 (full) to 1 (dying): the
    // bands it is below, counted smoothly, over the four of them. Far from a
    // line it is the bot module's band (at 35%, below low, medium and almost
    // full: 3/4); across a line it slides.
    inline double Hurt(double healthPct)
    {
        double below = 0.0;
        for (double band : BANDS) below += Below(healthPct, band);
        return below / 4.0;
    }
    // }}}

    // {{{ Saving
    // The bot module's save-mana switch made smooth: 1 well below 60% mana
    // (save it), 0 well above, sliding between.
    inline double Saving(double manaPct)
    {
        return Below(manaPct, SAVE_MANA);
    }
    // }}}

    // {{{ Regen
    // What brings a buddy's mana back:
    //   perFive       mana per 5 seconds from gear and buffs (always on)
    //   spirit        mana a second from spirit, five seconds after a cast
    //   whileCasting  the share of `spirit` that goes on within those five
    //                 seconds (Meditation and the like; 0 for most)
    //   drinking      mana a second from a drink (out of combat only)
    // Read by the server from the character (its spirit regeneration, its
    // mana per 5, its talents).
    struct Regen { double perFive = 0, spirit = 0, whileCasting = 0, drinking = 0; };
    // }}}

    // {{{ PerSecond
    // Mana coming back each second at the moment: the slow kind in combat
    // (mana per 5, and spirit only `FIVE_SECOND_RULE` seconds after the last
    // cast, `whileCasting` of it before); between fights the same, plus the
    // drink when drinking.
    inline double PerSecond(Regen const& r, bool inCombat, double sinceCast, bool drinking)
    {
        double spirit = sinceCast >= FIVE_SECOND_RULE ? r.spirit : r.spirit * r.whileCasting;
        double drink  = !inCombat && drinking ? r.drinking : 0.0;
        return r.perFive / 5.0 + spirit + drink;
    }
    // }}}

    // {{{ Kind
    // The game's power types, as the fight state names them (resourceKind).
    enum Kind : uint8_t { MANA = 0, RAGE = 1, FOCUS = 2, ENERGY = 3, RUNIC = 6 };
    // }}}

    // {{{ RefillSeconds
    // How long the missing part of a resource takes to come back at
    // `perSecond`: mana, energy and focus by time (energy's own 10 a
    // second, focus's 5, unless the caller gives more: Adrenaline Rush);
    // rage and runic power come from fighting, not from waiting, so there
    // is nothing to save: 0. Nothing missing: 0; missing and nothing coming
    // back: endless.
    inline double RefillSeconds(uint8_t kind, double current, double most, double perSecond)
    {
        if (kind == RAGE || kind == RUNIC) return 0.0;
        if (kind == ENERGY && perSecond <= 0.0) perSecond = 10.0;
        if (kind == FOCUS  && perSecond <= 0.0) perSecond = 5.0;
        double missing = std::max(0.0, most - current);
        if (missing <= 0.0) return 0.0;
        if (perSecond <= 0.0) return std::numeric_limits<double>::infinity();
        return missing / perSecond;
    }
    // }}}

    // {{{ Thrift
    // How much a cost counts, 0 to 1, by the seconds the resource takes to
    // come back: under BARELY barely at all, past EVERY wholly, smooth
    // between (625h: "under about 30 seconds it barely matters; past two
    // minutes every cost counts").
    inline double Thrift(double refillSeconds)
    {
        return Smooth(refillSeconds, BARELY, EVERY);
    }
    // }}}

    // {{{ Weights
    // How much an answer's speed and its cost count, for a target at
    // `healthPct` and a buddy whose resource takes `refillSeconds` to come
    // back (625d's urgency and mana economy, smoothed):
    //   speed  Hurt: fast answers for the badly hurt;
    //   cost   (1 - Hurt) x Thrift: cheap answers for the slightly hurt, the
    //          more so the longer the buddy's resource takes to come back
    //          (a buddy that refills fast "is told to be extravagant").
    struct Weights { double speed, cost; };
    inline Weights Weigh(double healthPct, double refillSeconds)
    {
        double hurt = Hurt(healthPct);
        return { hurt, (1.0 - hurt) * Thrift(refillSeconds) };
    }
    // }}}

    // {{{ Answer
    // One answer among a concern's (a heal, here): the time it takes (its
    // cast, or the global cooldown when instant) and what it gives for each
    // point of resource (its healing over its cost; a free answer: infinity).
    struct Answer { double seconds, perCost; };
    // }}}

    // {{{ Lean
    // Each answer's lean, 0 to 1 (1: the best both ways): how near it comes
    // to the fastest answer, to the power of the speed weight, times how
    // near it comes to the cheapest, to the power of the cost weight. With
    // both weights 0 (an ally barely hurt, mana coming back fast) every
    // answer is 1: nothing to prefer, the bot module's own choice stands.
    inline std::vector<double> Lean(std::vector<Answer> const& answers, Weights const& w)
    {
        double fastest = std::numeric_limits<double>::infinity(), cheapest = 0.0;
        for (Answer const& a : answers)
        {
            fastest  = std::min(fastest, a.seconds);
            cheapest = std::max(cheapest, a.perCost);
        }
        std::vector<double> out;
        for (Answer const& a : answers)
        {
            double speed = a.seconds > 0.0 ? std::min(1.0, fastest / a.seconds) : 1.0;
            double cost  = std::isinf(cheapest) ? (std::isinf(a.perCost) ? 1.0 : 0.0)
                         : cheapest > 0.0 ? a.perCost / cheapest : 1.0;
            out.push_back(std::pow(speed, w.speed) * (w.cost > 0.0 ? std::pow(cost, w.cost) : 1.0));
        }
        return out;
    }
    // }}}

    // {{{ Surplus
    // What a buddy has to spare until the fight ends: what it holds, less
    // what it will lose by then (its need a second, less what comes back a
    // second, over the guess counted `margin` longer). Its need a second: its
    // own spending, a healer's at the rate the party has been needing heals
    // (read by the server from the minute of events). No end seen (a guess
    // not known): nothing to spare. Coming back faster than it is needed:
    // all it holds is spare, however long the fight.
    inline double Surplus(double held, double perSecond, double need, BuddyFight::Guess const& g, double margin = MARGIN)
    {
        if (!g.known) return 0.0;
        double drain = need - perSecond;
        if (drain <= 0.0) return held;
        return held - drain * g.seconds * (1.0 + margin);
    }
    // }}}

    // {{{ DamageLean
    // How far a healer's damage spells lean in, by its surplus and a damage
    // spell's cost: AWAY with nothing spare (keep the mana); 1 once the
    // surplus covers SPARE_CASTS of them; smooth between. A free spell is
    // never held back.
    inline double DamageLean(double surplus, double castCost)
    {
        if (castCost <= 0.0) return 1.0;
        return AWAY + (1.0 - AWAY) * Smooth(surplus, 0.0, SPARE_CASTS * castCost);
    }
    // }}}

    // {{{ Rest
    // Between fights: whether to drink, and the word to say as it changes
    // (617z's words, which the tank's pace hears): below DRINK_BELOW it
    // starts and says "mana"; drinking, it keeps on until DRINK_UNTIL and
    // then says "ready". Nothing to say while nothing changes. Rage and
    // runic power users never drink.
    struct Rest { bool drink; char const* say; };
    inline Rest Between(uint8_t kind, double manaPct, bool drinking)
    {
        if (kind != MANA)                       return { false, nullptr };
        if (drinking && manaPct >= DRINK_UNTIL) return { false, "ready" };
        if (drinking)                           return { true,  nullptr };
        if (manaPct < DRINK_BELOW)              return { true,  "mana"  };
        return                                         { false, nullptr };
    }
    // }}}
}

#endif
