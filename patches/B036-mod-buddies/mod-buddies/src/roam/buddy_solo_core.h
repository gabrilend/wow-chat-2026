
#ifndef BUDDY_SOLO_CORE_H
#define BUDDY_SOLO_CORE_H

#include <cstdint>

namespace BuddySolo
{

enum Kind : uint8_t { KIND_WARRIOR, KIND_PALADIN, KIND_ROGUE, KIND_MAGE, KIND_COUNT };

inline bool KindOf(uint32_t unitClass, Kind& kind)
{
    switch (unitClass)
    {
        case 1: kind = KIND_WARRIOR; return true;
        case 2: kind = KIND_PALADIN; return true;
        case 4: kind = KIND_ROGUE;   return true;
        case 8: kind = KIND_MAGE;    return true;
        default: return false;
    }
}

struct Fight
{
    float foeHealth  = 0.0f;
    float foeDps     = 0.0f;
    float healthLost = 0.0f;
    float manaSpent  = 0.0f;
    float seconds    = 0.0f;
    float goldCost   = 0.0f;
};

inline bool MoreInEvery(Fight const& a, Fight const& b)
{
    bool atLeast = a.foeHealth >= b.foeHealth && a.foeDps >= b.foeDps && a.healthLost >= b.healthLost
                && a.manaSpent >= b.manaSpent && a.seconds >= b.seconds && a.goldCost >= b.goldCost;
    bool more    = a.foeHealth > b.foeHealth || a.foeDps > b.foeDps || a.healthLost > b.healthLost
                || a.manaSpent > b.manaSpent || a.seconds > b.seconds || a.goldCost > b.goldCost;
    return atLeast && more;
}

struct Records
{
    bool  has[KIND_COUNT]  = { false, false, false, false };
    Fight best[KIND_COUNT] = {};
    bool  standIn          = false;

    bool Won(Kind kind, Fight const& f)
    {
        if (standIn || kind >= KIND_COUNT)
            return false;
        if (!has[kind] || MoreInEvery(f, best[kind]))
        {
            has[kind]  = true;
            best[kind] = f;
            return true;
        }
        return false;
    }

    void Forget()
    {
        for (uint8_t k = 0; k < KIND_COUNT; ++k)
            has[k] = false;
    }

    bool CanTake(Kind kind, float foeHealth, float foeDps, uint32_t allies) const
    {
        if (standIn)
            return true;
        if (kind >= KIND_COUNT || !has[kind])
            return false;
        float times = allies > 0 ? float(allies) : 1.0f;
        return foeHealth <= best[kind].foeHealth * times && foeDps <= best[kind].foeDps * times;
    }
};

}

#endif
