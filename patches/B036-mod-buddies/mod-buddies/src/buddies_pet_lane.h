/*
 * buddies_pet_lane.h - a pet's abilities as the buddy's own, in a lane of
 * their own (issue 625m, step 2: "the pet's lane in the action economy:
 * its own global cooldown and resource, its abilities weighed by their
 * goals"); plain arithmetic, apart from the server, so it can be tested on
 * its own (tests/buddy-pet-lane/, scripts/test-buddy-pet-lane).
 *
 * For a general audience, the owner's words (2026-10-30): "hunters should
 * treat their pets abilities as their own for these purposes. They are
 * free in the action economy, or rather, they cost 1 pet gcd or similar,
 * while other abilities cost 1 hunter gcd and such. This is the case for
 * anyone with a pet who behaves similarly, like warlocks. They should cast
 * the pet abilities intentionally, for a specific goal, and they should
 * ascertain those goals dynamically, as if they were any other ability."
 * And of the pet's plain attack: "the plain attack can be autocast I
 * guess."
 *
 * So the pet has a lane beside the buddy's: the same look ahead
 * (buddies_rotation_time.h), run on the pet's abilities with the pet's own
 * global cooldown and the pet's own resource (focus, energy or mana), never
 * against the buddy's abilities for one slot. What each pet ability is
 * worth is worked out from its goal and the moment, in damage and health
 * like everything else (strategems/everything-is-damage-and-health.md):
 *   damage     its own worth, handed in (Claw, Firebolt)
 *   interrupt  what the enemy's cast in progress would do, if it lands
 *              before that cast does (Spell Lock); nothing with none
 *   taunt      the health the party loses while an enemy is on someone it
 *              shouldn't be (625j's curve), each second until the taunt
 *              lands lost (Growl, Torment)
 *   dispel     what the worst mark it can take off would still cost, the
 *              same way (Devour Magic)
 * The plain attack stays on the game's autocast as the lane's filler; the
 * lane says when to pause that autocast: while its best plan holds the
 * resource for, or starts with, an ability with a goal, or while an
 * ability off the global cooldown is wanted now and not yet paid for (the
 * race doesn't see those, so the autocast would keep spending their
 * resource).
 */

#ifndef MOD_BUDDIES_PET_LANE_H
#define MOD_BUDDIES_PET_LANE_H

#include "buddies_rotation_time.h"

#include <vector>

namespace BuddyPetLane
{
    using BuddyRotation::Answer;
    using BuddyRotation::Cast;
    using BuddyRotation::Moment;

    // {{{ Goal
    enum class Goal { Damage, Interrupt, Taunt, Dispel };
    // }}}

    // {{{ PetAbility
    // One of the pet's abilities: its timing and cost (`cast`; its `worth`
    // is used only for Damage), what it is for, and whether it is the plain
    // attack left on autocast (at most one).
    struct PetAbility { Cast cast; Goal goal; bool plainAttack = false; };
    // }}}

    // {{{ PetCast
    // A pet ability's Cast from the game's own row (the generated
    // buddies_ability_data.h lists the pets' abilities under their master's
    // class: Growl and Claw under the hunter's, Spell Lock and Torment under
    // the warlock's), with its cost in the pet's own unit: focus and energy
    // as they are, rage and runic power from the game's tenths, mana as its
    // amount, or its share of the pet's base mana.
    inline Cast PetCast(BuddyAbilityRow const& r, double worth, double baseMana = 0.0, double readyIn = 0.0)
    {
        Cast c   = BuddyRotation::FromRow(r, worth, readyIn);
        c.cost   = (r.power == 1 || r.power == 6) ? r.cost / 10.0
                 : (r.power == 0 && r.costPct > 0) ? baseMana * r.costPct / 100.0
                 : double(r.cost);
        return c;
    }
    // }}}

    // {{{ Sight
    // What the moment shows the pet's goals (the server reads it):
    //   castWorth  what the enemy's cast in progress would do, said in
    //              damage and health (0: no cast worth stopping)
    //   castLeft   seconds until that cast lands (-1: none under way)
    //   looseRate  the health the party loses each second an enemy is on
    //              someone it shouldn't be, more than on the tank (625j's
    //              curve), which a taunt stops (0: every enemy where it
    //              belongs)
    //   looseFor   seconds it would stay loose with no taunt (-1: the rest
    //              of the fight)
    //   markRate   the health the worst mark the pet can take off still
    //              costs each second, for markLeft more seconds
    struct Sight
    {
        double castWorth = 0.0, castLeft = -1.0, looseRate = 0.0, looseFor = -1.0, markRate = 0.0, markLeft = 0.0;
    };
    // }}}

    // {{{ GoalCast
    // A pet ability's Cast as its goal and the moment price it:
    //   damage     its own worth
    //   interrupt  the enemy's cast, if it lands before that cast does (its
    //              deadline); nothing with none under way
    //   taunt      what the loose enemy would cost while loose, less what
    //              each second before the taunt lands costs (fading)
    //   dispel     what the mark would still cost, the same way
    inline Cast GoalCast(PetAbility const& p, Sight const& s, Moment const& m)
    {
        Cast c = p.cast;
        double left = m.fightLeft >= 0.0 ? m.fightLeft : BuddyRotation::ASSUME_LEFT;
        switch (p.goal)
        {
            case Goal::Damage:
                break;
            case Goal::Interrupt:
                c.worth    = s.castLeft >= 0.0 ? s.castWorth : 0.0;
                c.deadline = s.castLeft;
                break;
            case Goal::Taunt:
                c.worth = s.looseRate * (s.looseFor >= 0.0 ? s.looseFor : left);
                c.fade  = s.looseRate;
                break;
            case Goal::Dispel:
                c.worth = s.markRate * s.markLeft;
                c.fade  = s.markRate;
                break;
        }
        return c;
    }
    // }}}

    // {{{ Lane
    // The pet's lane: the look ahead's answer on the pet's abilities
    // (weights in the pet's own order), and whether the plain attack's
    // autocast stays on (true: the best plan starts with the plain attack,
    // at once or once its resource is back, or nothing with a goal is worth
    // casting or waiting for; false: the
    // plan starts with an ability with a goal, or holds the resource for
    // one, or one off the global cooldown is wanted and not yet paid for).
    struct Lane { Answer answer; bool autocast = false; };

    inline Lane Weigh(std::vector<PetAbility> const& pet, Sight const& s, Moment const& m)
    {
        std::vector<Cast> cs;
        int plain = -1;
        for (size_t i = 0; i < pet.size(); ++i)
        {
            cs.push_back(GoalCast(pet[i], s, m));
            if (pet[i].plainAttack && plain < 0)
                plain = int(i);
        }
        Lane l;
        l.answer = BuddyRotation::Weigh(cs, m);
        bool saving = false;                               // an off-global one wanted now but not yet paid for
        for (size_t i = 0; i < pet.size(); ++i)
            if (int(i) != plain && cs[i].gcd <= 0.0 && cs[i].worth > 0.0 && cs[i].readyIn <= 0.0
                && BuddyRotation::Afford(cs[i], m.pool, 0.0, m) > 0.0)
                saving = true;
        int next = l.answer.first;                         // what the plan casts first, after any wait
        if (next < 0 && l.answer.waitFor > 0.0)
        {
            Moment later  = m;
            later.gcdLeft = std::max(0.0, m.gcdLeft) + l.answer.waitFor;
            next = BuddyRotation::Weigh(cs, later).first;
        }
        l.autocast = plain >= 0 && !saving && (next == plain || (next < 0 && l.answer.waitFor <= 0.0));
        return l;
    }
    // }}}

    // {{{ Both
    // The buddy's lane and its pet's, side by side: each weighed on its own,
    // so a pet ability never competes with a buddy ability for one slot.
    struct Both { Answer buddy; Lane pet; };
    inline Both WeighBoth(std::vector<Cast> const& buddy, Moment const& buddyMoment,
                          std::vector<PetAbility> const& pet, Sight const& s, Moment const& petMoment)
    {
        return { BuddyRotation::Weigh(buddy, buddyMoment), Weigh(pet, s, petMoment) };
    }
    // }}}
}

#endif // MOD_BUDDIES_PET_LANE_H
