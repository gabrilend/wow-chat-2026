
#ifndef MOD_BUDDIES_HEALER_SEAT_H
#define MOD_BUDDIES_HEALER_SEAT_H

#include "buddies_ability_data.h"
#include "buddies_fight_state.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>

namespace BuddySeat
{
    using namespace BuddyFightState;

    inline bool HealingTree(uint8_t cls, uint8_t tab)
    {
        switch (cls)
        {
            case 5:  return tab == 0 || tab == 1;
            case 2:  return tab == 0;
            case 7:  return tab == 2;
            case 11: return tab == 2;
            default: return false;
        }
    }

    struct Heal { double cost = 0, amount = 0; };
    inline Heal CheapestHeal(uint8_t cls, double baseMana)
    {
        Heal best;
        for (BuddyAbilityReachRow const& r : BUDDY_ABILITY_REACH)
        {
            if (r.cls != cls || r.heal <= 0) continue;
            for (BuddyAbilityRow const& a : BUDDY_ABILITIES)
                if (a.cls == cls && std::strcmp(a.name, r.name) == 0 && a.power == 0)
                {
                    double cost = a.costPct > 0 ? a.costPct * baseMana / 100.0 : double(a.cost);
                    if (cost > 0 && (best.cost == 0 || cost < best.cost)) best = { cost, double(r.heal) };
                }
        }
        return best;
    }

    inline double HealerShare(Member const& m)
    {
        if (m.talentPoints == 0) return m.role == 2 ? 1.0 : 0.0;
        double thirds = std::round(3.0 * m.healPoints / m.talentPoints);
        return thirds >= 2.0 ? 1.0 : thirds >= 1.0 ? 1.0 / 3.0 : 0.0;
    }

    struct Seats { double want = -1; std::vector<int> holders, dry; bool short_ = false; };

    inline bool CanHeal(Member const& m) { return (m.healPoints > 0 || (m.talentPoints == 0 && m.role == 2)) && m.health > 0; }

    inline bool Oom(Member const& m)
    {
        Heal h = CheapestHeal(m.cls, m.baseMana);
        return m.resourceKind == 0 && h.cost > 0 && m.resource < h.cost;
    }

    inline double ReadyAt(Member const& m, double healingPerSecond, double left)
    {
        Heal h = CheapestHeal(m.cls, m.baseMana);
        if (h.cost <= 0 || h.amount <= 0) return m.maxResource;
        double need = healingPerSecond * left / (h.amount / h.cost);
        return std::min(m.maxResource, std::max(h.cost, need));
    }

    inline bool Has(std::vector<int> const& v, int i) { return std::find(v.begin(), v.end(), i) != v.end(); }

    inline Seats Now(Snapshot const& s, Memory const& memory, Seats was, double left)
    {
        Seats seats;
        seats.want = was.want;
        if (seats.want < 0)
        {
            seats.want = 0;
            for (size_t i = 0; i < s.party.size(); ++i)
                if (s.party[i].role == 2 && s.party[i].health > 0) { seats.holders.push_back(int(i)); seats.want += HealerShare(s.party[i]); }
        }
        else
            for (int i : was.holders)
                if (i >= 0 && size_t(i) < s.party.size() && s.party[i].health > 0) seats.holders.push_back(i);
        for (int i : was.dry)
            if (i >= 0 && size_t(i) < s.party.size() && s.party[i].health > 0 &&
                s.party[i].resource < ReadyAt(s.party[i], memory.HealingPerSecond(s.party[i].id, s.t), left)) seats.dry.push_back(i);
        for (auto it = seats.holders.begin(); it != seats.holders.end(); )
            if (Oom(s.party[*it])) { seats.dry.push_back(*it); it = seats.holders.erase(it); }
            else ++it;
        auto have = [&]() { double h = 0; for (int i : seats.holders) h += HealerShare(s.party[i]); return h; };
        while (have() + 1e-9 < seats.want)
        {
            int best = -1;
            for (size_t i = 0; i < s.party.size(); ++i)
            {
                Member const& m = s.party[i];
                if (!CanHeal(m) || HealerShare(m) <= 0 || Has(seats.holders, int(i)) || Has(seats.dry, int(i)) || Oom(m)) continue;
                double share = HealerShare(m), bestShare = best < 0 ? -1 : HealerShare(s.party[best]);
                if (best < 0 || share > bestShare + 1e-9 ||
                    (std::fabs(share - bestShare) <= 1e-9 && m.resource > s.party[best].resource)) best = int(i);
            }
            if (best < 0) { seats.short_ = true; break; }
            seats.holders.push_back(best);
        }
        return seats;
    }
}

#endif
