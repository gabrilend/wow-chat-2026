
#ifndef MOD_BUDDIES_MARKS_H
#define MOD_BUDDIES_MARKS_H

#include "buddies_ability_data.h"

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <vector>

namespace BuddyMarks
{
    struct AuraEffect { uint32_t aura; int32_t amount; int32_t misc; uint32_t periodMs; uint32_t stacks; };

    struct Modifiers
    {
        double takenPhysical = 1.0, takenMagic = 1.0, healed = 1.0, dealt = 1.0, attackHaste = 1.0, castHaste = 1.0, speed = 1.0;
        double tickDamage = 0.0, tickHealing = 0.0, absorb = 0.0, armourFlat = 0.0, armourShare = 1.0;
    };

    inline void Fold(Modifiers& m, AuraEffect const& e)
    {
        double each  = static_cast<double>(e.amount) * std::max<uint32_t>(1, e.stacks);
        double share = 1.0 + each / 100.0;
        bool physical = (e.misc & 1) != 0, magic = (e.misc & 126) != 0;
        switch (e.aura)
        {
            case 87:  if (physical) m.takenPhysical *= share; if (magic) m.takenMagic *= share; break;
            case 79:  m.dealt  *= share; break;
            case 118: case 283: m.healed *= share; break;
            case 9: case 138: case 140: case 192: m.attackHaste *= share; break;
            case 65: case 216: m.castHaste *= share; break;
            case 31: case 33: m.speed *= share; break;
            case 3:   if (e.periodMs > 0) m.tickDamage  += each * 1000.0 / e.periodMs; break;
            case 8:   if (e.periodMs > 0) m.tickHealing += each * 1000.0 / e.periodMs; break;
            case 69:  m.absorb += each; break;
            case 22:  if (physical) m.armourFlat += each; break;
            case 101: if (physical) m.armourShare *= share; break;
            default:  break;
        }
    }

    inline Modifiers Of(std::vector<AuraEffect> const& effects)
    {
        Modifiers m;
        for (AuraEffect const& e : effects) Fold(m, e);
        return m;
    }

    inline double Taken(Modifiers const& m, double physicalShare)
    {
        return m.takenPhysical * physicalShare + m.takenMagic * (1.0 - physicalShare);
    }

    inline double ArmourReduction(double armour, int attackerLevel)
    {
        if (armour <= 0.0) return 0.0;
        double k = attackerLevel < 60 ? 400.0 + 85.0 * attackerLevel : 467.5 * attackerLevel - 22167.5;
        return std::min(0.75, armour / (armour + k));
    }

    inline std::vector<AuraEffect> OfAbility(uint8_t cls, char const* name)
    {
        std::vector<AuraEffect> out;
        for (BuddyAbilityAuraRow const& r : BUDDY_ABILITY_AURAS)
            if (r.cls == cls && std::strcmp(r.name, name) == 0) out.push_back({ r.aura, r.amount, r.misc, r.periodMs, 1 });
        return out;
    }
}

#endif
