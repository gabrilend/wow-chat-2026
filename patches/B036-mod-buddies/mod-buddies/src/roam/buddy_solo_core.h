/*
 * buddy_solo_core.h - a buddy's sense of which foes it can beat alone: the
 * hardest fight it has won with no help, kept per kind of foe (issue 623,
 * question 7). Plain arithmetic, no server, so
 * scripts/test-buddy-solo-record checks it alone with the system compiler;
 * the server's part (noting a solo kill, keeping the records on the buddy)
 * only feeds it numbers and reads its answers.
 *
 * For a general audience, the owner's design (2026-10-30): "whenever a
 * buddy-bot defeats a foe on their own entirely with no help at all, we
 * record the conditions that the fight had, and they can estimate based on
 * that? Things like... enemy health, enemy dps, how much health we lost in
 * the fight, how much mana we spent, how long it took, if we used
 * consumables (gold cost to fight), etc. Then, if we ever have a fight
 * that is "more" or "better" in each of the parameters, we can replace the
 * old record with the new one." And: "the record is only updated when
 * something is more developed in every dimension that it records. The
 * decisionmaking that comes *from* the records will be more dynamic."
 *
 * The pieces:
 *   the kinds    - foes are sorted into player classes (the owner: "should
 *                  have categories for player classes, and we sort NPCs
 *                  into them. So a spellcasting NPC would be similar to a
 *                  mage"). The game already gives every creature one of
 *                  four classes (creature_template.unit_class: 1 warrior,
 *                  2 paladin, 4 rogue, 8 mage; on basic 23935, 4361, 107
 *                  and 1580 creatures), so the kind is read, not guessed;
 *   the record   - per kind, one fight: what it asked (the foe's health and
 *                  damage per second) and what it cost (health lost, mana
 *                  spent, seconds, gold of consumables);
 *   replacing    - a new solo win replaces the record only when it is at
 *                  least as much in every one of those six numbers and more
 *                  in one ("more developed in every dimension");
 *   judging      - a foe never fought is compared with the record of its
 *                  kind: the buddy can take it alone when the foe's health
 *                  and damage per second are each within the record's,
 *                  times the buddy's allies near ("it should simply
 *                  multiple it's own value by 3 if it has 3 allies, 4 if it
 *                  has 4 allies, etc."; alone, times 1);
 *   forgetting   - the records are forgotten when Sargobras sets the
 *                  buddy's level or its class changes ("only when Sargobras
 *                  changes your level. Levelling up via normal means
 *                  shouldn't affect it."), never by ordinary levelling, and
 *                  kept while the buddy is stored;
 *   stand-ins    - keep no records and are never afraid ("stand-ins should
 *                  never remember this stuff - they always are brave and
 *                  vigilant").
 */

#ifndef BUDDY_SOLO_CORE_H
#define BUDDY_SOLO_CORE_H

#include <cstdint>

namespace BuddySolo
{

// {{{ Kind
// The four classes the game gives creatures, as indexes into the records.
enum Kind : uint8_t { KIND_WARRIOR, KIND_PALADIN, KIND_ROGUE, KIND_MAGE, KIND_COUNT };

// A creature's kind from its unit_class (1, 2, 4, 8). Any other value
// (none in basic's data, read 2026-10-30) is reported as false: the caller
// logs it and keeps no record, rather than guessing a kind.
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
// }}}

// {{{ Fight
// One solo win's numbers: what the foe asked, and what it cost.
struct Fight
{
    float foeHealth  = 0.0f;   // the foe's health at the start (points)
    float foeDps     = 0.0f;   // the damage per second it dealt to the buddy
    float healthLost = 0.0f;   // health the buddy lost (points)
    float manaSpent  = 0.0f;   // mana (or its resource) spent (points)
    float seconds    = 0.0f;   // how long it took
    float goldCost   = 0.0f;   // consumables used, in copper
};

// Whether `a` is at least as much as `b` in every number and more in one:
// "more developed in every dimension".
inline bool MoreInEvery(Fight const& a, Fight const& b)
{
    bool atLeast = a.foeHealth >= b.foeHealth && a.foeDps >= b.foeDps && a.healthLost >= b.healthLost
                && a.manaSpent >= b.manaSpent && a.seconds >= b.seconds && a.goldCost >= b.goldCost;
    bool more    = a.foeHealth > b.foeHealth || a.foeDps > b.foeDps || a.healthLost > b.healthLost
                || a.manaSpent > b.manaSpent || a.seconds > b.seconds || a.goldCost > b.goldCost;
    return atLeast && more;
}
// }}}

// {{{ Records
// One buddy's records, a fight per kind. Kept on the buddy (the owner's
// rule: state lives on the character), saved with it, freed at logout.
struct Records
{
    bool  has[KIND_COUNT]  = { false, false, false, false };
    Fight best[KIND_COUNT] = {};
    bool  standIn          = false;   // a stand-in keeps none and is never afraid

    // A solo win against a foe of `kind`. Each path:
    //   a stand-in                    - nothing kept
    //   no record of that kind yet    - this fight becomes it
    //   more in every number          - this fight replaces it
    //   otherwise                     - the record stands
    // Returns whether the record changed.
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

    // Forgotten all at once: Sargobras set the level, or the class changed.
    void Forget()
    {
        for (uint8_t k = 0; k < KIND_COUNT; ++k)
            has[k] = false;
    }

    // Whether the buddy, with `allies` near, can take on a foe of `kind`
    // with this health and damage per second. Each path:
    //   a stand-in                        - always
    //   no record of that kind            - no (it has never won against one alone)
    //   foe's health and dps each within
    //   the record's times the allies     - yes (alone: times 1)
    //   otherwise                         - no
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
// }}}

} // namespace BuddySolo

#endif
