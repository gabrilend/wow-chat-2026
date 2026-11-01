/*
 * buddies_tank_load.h - the tank's load: whether it has room for one more
 * enemy (issue 625j, the threat economy, step 4); plain arithmetic over the
 * forward pass's verdict, apart from the server, so it can be tested on its
 * own (tests/buddy-tank-load/, scripts/test-buddy-tank-load).
 *
 * For a general audience: damage dealers can pull more when the tank can
 * hold more (617z: "If the DPS wants to go faster, they should just pull
 * more mobs"), and should hold when it can't. "Can hold" is said in health,
 * like everything else (strategems/everything-is-damage-and-health.md):
 * with one more enemy like the average one on it, the tank loses that
 * enemy's damage too (through its armour), and the fight lasts longer by
 * that enemy's health at the party's pace. The room is the health the tank
 * would have left at the fight's end that way: above nothing, room to pull
 * more; below, hold (and how far below says how badly).
 */

#ifndef MOD_BUDDIES_TANK_LOAD_H
#define MOD_BUDDIES_TANK_LOAD_H

#include "buddies_forward_pass.h"

#include <algorithm>
#include <limits>

namespace BuddyTankLoad
{
    using namespace BuddyForwardPass;

    // {{{ Load
    //   tank      the member holding the most enemies (-1: no one holds any)
    //   enemies   how many it holds
    //   lossNow   health it loses a second now (damage let through, less
    //             healing), and lossMore with one more average enemy
    //   leftNow   the fight's time left now, and leftMore with that enemy too
    //   room      its health at the end with one more: above 0, room to pull
    //   rest      its health at the end as it is (the same sum, no one more)
    struct Load { int tank = -1; int enemies = 0; double lossNow = 0, lossMore = 0, leftNow = 0, leftMore = 0, room = 0, rest = 0; };
    // }}}

    // {{{ Of
    // The load from a step's verdict and its snapshot.
    inline Load Of(Snapshot const& s, Verdict const& v)
    {
        Load l;
        std::vector<int> held(s.party.size(), 0);
        for (int a : v.attention) if (a >= 0) ++held[a];
        for (size_t i = 0; i < s.party.size(); ++i)
            if (held[i] > 0 && (l.tank < 0 || held[i] > held[l.tank] || (held[i] == held[l.tank] && s.party[i].role == 1))) l.tank = int(i);
        if (l.tank < 0) return l;
        l.enemies = held[l.tank];

        // the average enemy: its real damage, and its health
        double hits = 0, health = 0;
        for (size_t e = 0; e < s.enemies.size(); ++e) { hits += v.hits[e]; health += s.enemies[e].health; }
        double n = double(std::max<size_t>(1, s.enemies.size()));
        double avgHit = hits / n, avgHealth = health / n;

        Member const& t = s.party[l.tank];
        l.lossNow  = v.incoming[l.tank] * v.taken[l.tank] - v.healing[l.tank];
        l.lossMore = (v.incoming[l.tank] + avgHit) * v.taken[l.tank] - v.healing[l.tank];

        // the party's pace on the enemies: their health over the time left
        // (the forward pass's guess); with one more, its health added at it
        l.leftNow = v.left;
        double pace = v.leftKnown && v.left > 0 ? health / v.left : 0.0;
        l.leftMore = pace > 0 ? (health + avgHealth) / pace : std::numeric_limits<double>::infinity();

        // its health at the end, capped at full (healing can't lift it above)
        auto end = [&](double loss, double left) {
            if (!std::isfinite(left)) return loss > 0 ? -std::numeric_limits<double>::infinity() : t.health;
            return std::min(t.maxHealth, t.health - loss * left);
        };
        l.rest = end(l.lossNow, l.leftNow);
        l.room = end(l.lossMore, l.leftMore);
        return l;
    }
    // }}}
}

#endif
