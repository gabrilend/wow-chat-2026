/*
 * buddies_form_trip.h - forms and stances weighed (issue 625g): an answer
 * that needs the buddy out of its form or stance is weighed together with
 * the trip out and back, as one answer; plain arithmetic, apart from the
 * server, so it can be tested on its own (tests/buddy-form-trip/,
 * scripts/test-buddy-form-trip).
 *
 * For a general audience: a cat druid can step out of cat form, cast two
 * Rejuvenations and step back in; a warrior can switch to defensive stance
 * for a taunt and switch back. The owner, 2026-10-30: "furor is especially
 * important for feral druids in cat form, who can let their energy
 * regenerate while casting a couple rejuvenations and such. Similarly a
 * warrior can switch to defensive mode temporarily to cast a taunt or
 * something, but they have to weigh the cost of losing their rage to do
 * so." So the trip is priced as a whole: what the answers outside give,
 * against the time the form's own work stops, the mana spent (the answers'
 * and shifting back in), and the form's resource kept, lost or gained on
 * the way (rage above what the stance keeps lost; energy coming back while
 * away, and Furor's gift on entering again). Everything is counted in
 * damage and health (strategems/everything-is-damage-and-health.md), so
 * the stance dance "falls out of the weighing".
 *
 * Read from the game (the server, or a generator): what a change keeps
 * (Tactical Mastery's rage), what entering gives (Furor's chance and
 * amount), the form's mana cost (the generated ability table, here) less
 * Natural Shapeshifter's share, the form's worth a second and a point of
 * its resource (the forward pass's rates).
 */

#ifndef MOD_BUDDIES_FORM_TRIP_H
#define MOD_BUDDIES_FORM_TRIP_H

#include "buddies_ability_data.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>

namespace BuddyForm
{
    // {{{ ShiftMana
    // The mana to enter a form, from the generated ability table (its cost,
    // or its cost in percent of base mana worked out on this buddy's base
    // mana), less a talent's share (Natural Shapeshifter's percent). 0 for
    // a stance or anything not in the table.
    inline double ShiftMana(uint8_t cls, char const* name, double baseMana, double reductionPct)
    {
        for (BuddyAbilityRow const& a : BUDDY_ABILITIES)
            if (a.cls == cls && std::strcmp(a.name, name) == 0 && a.power == 0)
            {
                double cost = a.costPct > 0 ? a.costPct * baseMana / 100.0 : double(a.cost);
                return cost * std::max(0.0, 1.0 - reductionPct / 100.0);
            }
        return 0.0;
    }

    // The time entering a form or stance takes: its global cooldown, from
    // the table (a druid's form 1.5 s; a warrior's stance none: it has a
    // cooldown of its own instead). 0 when not in the table.
    inline double ShiftSeconds(uint8_t cls, char const* name)
    {
        for (BuddyAbilityRow const& a : BUDDY_ABILITIES)
            if (a.cls == cls && std::strcmp(a.name, name) == 0)
                return a.gcdMs / 1000.0;
        return 0.0;
    }
    // }}}

    // {{{ State
    // The form or stance left, and returned to:
    //   held            its resource now (rage, energy; 0 for a form
    //                   without one)
    //   keep            the most of it a change keeps (each change: out and
    //                   back in); a warrior's stance by its talents, a form
    //                   whose resource carries on while away its cap
    //   regen           its resource a second while away (energy; rage 0)
    //   gift            the resource expected on entering again (Furor:
    //                   its chance times its amount)
    //   cap             the most it holds
    //   backMana        mana to enter it again (ShiftMana)
    //   backSeconds     time to enter it again (ShiftSeconds)
    //   outSeconds      time to leave it (a form is cancelled at once: 0; a
    //                   stance changed to another is that one's entering)
    //   worthPerSecond  what the state's own work is worth each second
    //                   (its damage, or a tank's threat said as the health
    //                   it saves), in damage and health
    //   worthPerPoint   what one point of its resource is worth
    struct State
    {
        double held = 0, keep = 0, regen = 0, gift = 0, cap = 100;
        double backMana = 0, backSeconds = 0, outSeconds = 0;
        double worthPerSecond = 0, worthPerPoint = 0;
    };

    // The answers taken while away: the time they take, what they give (in
    // damage and health) and the mana they cost.
    struct Away { double seconds = 0, worth = 0, mana = 0; };
    // }}}

    // {{{ Returned
    // The resource held on coming back: what it held, plus what comes back
    // while away, of which the changes keep at most `keep` (both the change
    // out and the change back cut to it; nothing lowers it while away, so
    // one cut at the end is the same as two), plus the gift on entering,
    // held to the cap.
    inline double Seconds(State const& s, Away const& a) { return s.outSeconds + a.seconds + s.backSeconds; }

    inline double Returned(State const& s, Away const& a)
    {
        double away = s.held + s.regen * Seconds(s, a);
        return std::min(s.cap, std::min(away, s.keep) + s.gift);
    }
    // }}}

    // {{{ Price
    // The trip as one answer, in damage and health:
    //   resource  (Returned - held) x worthPerPoint: negative when rage is
    //             lost, positive when energy and Furor bring more back
    //   time      the state's worth a second over the whole trip
    //   mana      the answers' mana and entering the form again, at
    //             worthPerMana (the mana's worth to this buddy: 625h's)
    //   net       what the answers give + resource - time - mana
    struct Price { double resource = 0, time = 0, mana = 0, net = 0; };

    inline Price Weigh(State const& s, Away const& a, double worthPerMana)
    {
        Price p;
        p.resource = (Returned(s, a) - s.held) * s.worthPerPoint;
        p.time     = s.worthPerSecond * Seconds(s, a);
        p.mana     = (a.mana + s.backMana) * worthPerMana;
        p.net      = a.worth + p.resource - p.time - p.mana;
        return p;
    }
    // }}}

    // {{{ Take
    // Whether to take the trip (open question 1, decided 2026-11-06): it
    // must come out ahead (net above 0), and an answer its role doesn't need
    // (a cat druid's heal, a damage warrior's taunt) is taken only while its
    // role's own concerns are quiet or the party's healer seats are short
    // or dry (625i: "others can use that as the signal to jump in"). The
    // role's own duty (a tank's taunt) needs only to come out ahead.
    inline bool Take(Price const& p, bool rolesOwn, bool roleQuiet, bool seatShort)
    {
        if (p.net <= 0) return false;
        return rolesOwn || roleQuiet || seatShort;
    }
    // }}}
}

#endif
