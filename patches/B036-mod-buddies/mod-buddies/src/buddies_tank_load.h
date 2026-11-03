
#ifndef MOD_BUDDIES_TANK_LOAD_H
#define MOD_BUDDIES_TANK_LOAD_H

#include "buddies_forward_pass.h"

#include <algorithm>
#include <limits>

namespace BuddyTankLoad
{
    using namespace BuddyForwardPass;

    struct Load { int tank = -1; int enemies = 0; double lossNow = 0, lossMore = 0, leftNow = 0, leftMore = 0, room = 0, rest = 0; };

    inline Load Of(Snapshot const& s, Verdict const& v)
    {
        Load l;
        std::vector<int> held(s.party.size(), 0);
        for (int a : v.attention) if (a >= 0) ++held[a];
        for (size_t i = 0; i < s.party.size(); ++i)
            if (held[i] > 0 && (l.tank < 0 || held[i] > held[l.tank] || (held[i] == held[l.tank] && s.party[i].role == 1))) l.tank = int(i);
        if (l.tank < 0) return l;
        l.enemies = held[l.tank];

        double hits = 0, health = 0;
        for (size_t e = 0; e < s.enemies.size(); ++e) { hits += v.hits[e]; health += s.enemies[e].health; }
        double n = double(std::max<size_t>(1, s.enemies.size()));
        double avgHit = hits / n, avgHealth = health / n;

        Member const& t = s.party[l.tank];
        l.lossNow  = v.incoming[l.tank] * v.taken[l.tank] - v.healing[l.tank];
        l.lossMore = (v.incoming[l.tank] + avgHit) * v.taken[l.tank] - v.healing[l.tank];

        l.leftNow = v.left;
        double pace = v.leftKnown && v.left > 0 ? health / v.left : 0.0;
        l.leftMore = pace > 0 ? (health + avgHealth) / pace : std::numeric_limits<double>::infinity();

        auto end = [&](double loss, double left) {
            if (!std::isfinite(left)) return loss > 0 ? -std::numeric_limits<double>::infinity() : t.health;
            return std::min(t.maxHealth, t.health - loss * left);
        };
        l.rest = end(l.lossNow, l.leftNow);
        l.room = end(l.lossMore, l.leftMore);
        return l;
    }
}

#endif
