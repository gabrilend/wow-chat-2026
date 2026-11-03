
#ifndef MOD_BUDDIES_WINDOW_BUFFS_H
#define MOD_BUDDIES_WINDOW_BUFFS_H

#include "buddies_ability_data.h"
#include <cstdint>
#include <vector>

namespace BuddyWindow
{
    struct Provides
    {
        float haste = 0.0f, damage = 0.0f, healing = 0.0f, crit = 0.0f, costCut = 0.0f, regen = 0.0f;
    };

    struct Buff { uint32_t spell; char const* name; Provides gives; };
    static Buff const BUFFS[] = {
        {  2825, "Bloodlust",       { 0.30f, 0.00f, 0.00f, 0.00f,  0.00f, 0.00f } },
        { 32182, "Heroism",         { 0.30f, 0.00f, 0.00f, 0.00f,  0.00f, 0.00f } },
        { 10060, "Power Infusion",  { 0.20f, 0.00f, 0.00f, 0.00f,  0.20f, 0.00f } },
        { 12472, "Icy Veins",       { 0.20f, 0.00f, 0.00f, 0.00f,  0.00f, 0.00f } },
        { 26297, "Berserking",      { 0.20f, 0.00f, 0.00f, 0.00f,  0.00f, 0.00f } },
        { 12042, "Arcane Power",    { 0.00f, 0.20f, 0.00f, 0.00f, -0.20f, 0.00f } },
        { 31884, "Avenging Wrath",  { 0.00f, 0.20f, 0.20f, 0.00f,  0.00f, 0.00f } },
        { 12292, "Death Wish",      { 0.00f, 0.20f, 0.00f, 0.00f,  0.00f, 0.00f } },
        {  1719, "Recklessness",    { 0.00f, 0.00f, 0.00f, 0.50f,  0.00f, 0.00f } },
        { 29166, "Innervate",       { 0.00f, 0.00f, 0.00f, 0.00f,  0.00f, 2.25f } },
    };

    struct Ability { float haste, damage, healing, crit, share; };

    static constexpr Ability AUTO_ATTACK = { 1.0f, 1.0f, 0.0f, 1.0f, 1.0f };
    inline Ability ProfileOf(BuddyAbilityRow const& a, float share)
    {
        bool timeBound   = a.castMs > 0 || a.channeled || (a.gcdMs > 0 && a.power == 0);
        bool tickOnly    = a.periodic && !a.direct && !a.channeled && a.castMs <= 0;
        Ability p{};
        p.haste   = (timeBound && !tickOnly) ? 1.0f : 0.0f;
        p.damage  = a.heal ? 0.0f : 1.0f;
        p.healing = a.heal ? 1.0f : 0.0f;
        p.crit    = a.direct ? 1.0f : 0.0f;
        p.share   = share;
        return p;
    }

    inline float Factor(Provides const& p, Ability const& a)
    {
        return (1.0f + p.haste * a.haste) * (1.0f + p.damage * a.damage + p.healing * a.healing) * (1.0f + p.crit * a.crit);
    }

    inline float WindowFactor(Provides const& p, std::vector<Ability> const& abilities)
    {
        float sum = 0.0f, shares = 0.0f;
        for (Ability const& a : abilities)
        {
            sum    += Factor(p, a) * a.share;
            shares += a.share;
        }
        return shares > 0.0f ? sum / shares : 1.0f;
    }
}

#endif
