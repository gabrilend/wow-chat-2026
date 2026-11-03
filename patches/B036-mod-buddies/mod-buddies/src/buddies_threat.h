
#ifndef MOD_BUDDIES_THREAT_H
#define MOD_BUDDIES_THREAT_H

#include "buddies_ability_data.h"
#include "buddies_lockouts.h"

#include <algorithm>
#include <cstring>
#include <limits>
#include <vector>

namespace BuddyThreat
{
    struct Entry { double threat; int state; int taunt; bool melee; };

    inline bool Below(Entry const& a, Entry const& b, double weight = 1.0)
    {
        if (a.state != b.state) return a.state < b.state;
        if (a.taunt != b.taunt) return a.taunt < b.taunt;
        return a.threat * weight < b.threat;
    }

    inline int Attention(std::vector<Entry> const& list, int current)
    {
        if (list.empty()) return -1;
        std::vector<int> order(list.size());
        for (size_t i = 0; i < list.size(); ++i) order[i] = static_cast<int>(i);
        std::stable_sort(order.begin(), order.end(), [&](int x, int y) { return Below(list[y], list[x]); });
        int top = order[0];
        if (list[top].state == 0) return -1;
        if (current < 0 || list[current].state == 0 || top == current) return top;
        Entry const& now = list[current];
        if (!Below(now, list[top], 1.1)) return current;
        if (Below(now, list[top], 1.3)) return top;
        if (list[top].melee) return top;
        for (int i : order)
        {
            if (i == current) return current;
            if (!Below(now, list[i], 1.1)) return current;
            if (list[i].melee) return i;
        }
        return current;
    }

    inline void Taunt(std::vector<Entry>& list, size_t who)
    {
        double top = 0.0;
        for (size_t i = 0; i < list.size(); ++i)
            if (i != who && list[i].state > 0) top = std::max(top, list[i].threat);
        list[who].threat = std::max(list[who].threat, top);
        list[who].taunt  = 1;
    }
    inline void Share(std::vector<Entry>& list, size_t who, double percent)
    {
        list[who].threat = std::max(0.0, list[who].threat * (1.0 + percent / 100.0));
    }
    inline void Hand(std::vector<Entry>& list, size_t to, double amount)
    {
        if (list[to].state == 2) list[to].threat += amount;
    }
    inline void Leave(std::vector<Entry>& list, size_t who)
    {
        list[who].state  = 0;
        list[who].threat = 0.0;
    }
    inline void Immune(std::vector<Entry>& list, size_t who)
    {
        if (list[who].state == 2) list[who].state = 1;
    }
    inline void Comeback(std::vector<Entry>& list, size_t who)
    {
        if (list[who].state == 1) list[who].state = 2;
    }

    inline BuddyThreatLeverRow const* LeverOf(uint8_t cls, char const* name)
    {
        for (BuddyThreatLeverRow const& r : BUDDY_THREAT_LEVERS)
            if (r.cls == cls && std::strcmp(r.name, name) == 0) return &r;
        return nullptr;
    }
    inline bool Does(BuddyThreatLeverRow const* row, char const* kind)
    {
        return row && BuddyLockout::Lists(row->kinds, kind);
    }
}

#endif
