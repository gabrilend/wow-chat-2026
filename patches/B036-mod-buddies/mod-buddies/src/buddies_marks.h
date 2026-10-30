/*
 * buddies_marks.h - what the marks on a character do to it (issue 625n,
 * the fight's forward pass, layer 2: marks into modifiers); plain
 * arithmetic, apart from the server, so it can be tested on its own
 * (tests/buddy-marks/, scripts/test-buddy-marks).
 *
 * For a general audience: every buff and debuff on a character changes
 * something the fight curves read: how much of the enemies' damage it lets
 * through (Shield Wall -60%, Pain Suppression -40%), how much healing
 * reaches it (Mortal Strike -50%), how fast it acts (Bloodlust +30%), how
 * fast it moves (Hamstring -50%), damage or healing ticking on it
 * (Corruption, Rejuvenation), a shield soaking damage (Power Word:
 * Shield), its armour (Faerie Fire). The game says which by each aura's
 * type and value; this folds every mark on a character into one set of
 * multipliers and rates, which the fight curves (buddies_curve.h) then
 * carry until each mark wears off. In the server each aura's effects are
 * read live (its type, its current value, its school, its period); for an
 * ability not yet cast, from the generated table (BUDDY_ABILITY_AURAS).
 */

#ifndef MOD_BUDDIES_MARKS_H
#define MOD_BUDDIES_MARKS_H

#include "buddies_ability_data.h"

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <vector>

namespace BuddyMarks
{
    // {{{ AuraEffect
    // One effect of one aura, as the game holds it:
    //   aura      its type (SpellAuraDefines.h)
    //   amount    its value (a percent for the percent kinds, a flat amount
    //             for the rest), for one stack
    //   misc      its misc value: for damage taken or dealt and armour, a
    //             school mask (1 physical, 126 every magic school, 127 all)
    //   periodMs  a ticking aura's period, milliseconds (0 for the rest)
    //   stacks    how many stacks are on (the value counts once per stack,
    //             as the server applies it)
    struct AuraEffect { uint32_t aura; int32_t amount; int32_t misc; uint32_t periodMs; uint32_t stacks; };
    // }}}

    // {{{ Modifiers
    // Everything the marks on one character add up to:
    //   takenPhysical, takenMagic  how much of the enemies' damage of each
    //                              kind it lets through (1: as usual)
    //   healed                     how much of the healing on it lands
    //   dealt                      how much damage it deals (1: as usual)
    //   attackHaste, castHaste     how fast it attacks and casts (1.3 each:
    //                              Bloodlust, whose two effects are one of
    //                              each); for an enemy, how fast its damage
    //                              comes
    //   speed                      how fast it moves
    //   tickDamage, tickHealing    damage and healing ticking on it, a second
    //   absorb                     damage a shield on it will soak first
    //   armourFlat, armourShare    armour added or taken, and the share of
    //                              its armour kept (Faerie Fire: 0.95)
    struct Modifiers
    {
        double takenPhysical = 1.0, takenMagic = 1.0, healed = 1.0, dealt = 1.0, attackHaste = 1.0, castHaste = 1.0, speed = 1.0;
        double tickDamage = 0.0, tickHealing = 0.0, absorb = 0.0, armourFlat = 0.0, armourShare = 1.0;
    };
    // }}}

    // {{{ Fold
    // Adds one aura effect to a character's modifiers, by its type (the
    // types the generator reads, MARK_AURAS in scripts/generate-ability-data):
    //   87 damage taken by a percent, 14 by a flat amount (counted as a
    //      percent of nothing here: left to the curve's damage, so ignored)
    //   79 damage dealt by a percent
    //   118, 283 healing received by a percent
    //   9, 138, 140, 192 attack haste by a percent (attack speed, melee,
    //      ranged, both); 65, 216 cast haste (a different action: a buff
    //      with one of each, Bloodlust, hastes each once)
    //   31, 33 movement speed by a percent
    //   3, 8 damage or healing each tick, over the tick's period
    //   69 an absorb
    //   22, 101 armour, flat or by a percent (school mask 1: armour)
    // Any other type adds nothing; the curves read only these.
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
    // }}}

    // {{{ Of
    // A character's modifiers from all the aura effects on it.
    inline Modifiers Of(std::vector<AuraEffect> const& effects)
    {
        Modifiers m;
        for (AuraEffect const& e : effects) Fold(m, e);
        return m;
    }
    // }}}

    // {{{ Taken
    // How much of an enemy's damage gets through, from its physical share
    // (a warrior boss nearly all physical, a caster none): the two kinds
    // weighed by it.
    inline double Taken(Modifiers const& m, double physicalShare)
    {
        return m.takenPhysical * physicalShare + m.takenMagic * (1.0 - physicalShare);
    }
    // }}}

    // {{{ ArmourReduction
    // The share of physical damage armour takes away, the game's own rule
    // for 3.3.5 (Unit::CalcArmorReducedDamage): armour over armour plus a
    // constant by the attacker's level (400 + 85 x level below 60; 467.5 x
    // level - 22167.5 from 60 on), at most 75%.
    inline double ArmourReduction(double armour, int attackerLevel)
    {
        if (armour <= 0.0) return 0.0;
        double k = attackerLevel < 60 ? 400.0 + 85.0 * attackerLevel : 467.5 * attackerLevel - 22167.5;
        return std::min(0.75, armour / (armour + k));
    }
    // }}}

    // {{{ OfAbility
    // The aura effects an ability would put on, read from the generated
    // table (its top rank), for planning it before it is cast; one stack.
    inline std::vector<AuraEffect> OfAbility(uint8_t cls, char const* name)
    {
        std::vector<AuraEffect> out;
        for (BuddyAbilityAuraRow const& r : BUDDY_ABILITY_AURAS)
            if (r.cls == cls && std::strcmp(r.name, name) == 0) out.push_back({ r.aura, r.amount, r.misc, r.periodMs, 1 });
        return out;
    }
    // }}}
}

#endif
