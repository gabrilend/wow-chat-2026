// pet-lane-check.cpp - checks a pet's lane in the action economy
// (buddies_pet_lane.h, and the resource it needs in buddies_rotation_time.h)
// against issue 625m, with no server. Built and run by
// scripts/test-buddy-pet-lane. Each check prints "ok" or "FAIL" and what it
// held; the exit status is the number of failures.
//
// The pets' abilities are the game's own rows (buddies_ability_data.h lists
// them under their master's class); the worths and the moments are made
// up. The felhunter's plain attack (Shadow Bite) is not in the table, so a
// made-up one stands for it.

#include "buddies_pet_lane.h"

#include <cstdio>
#include <cstdlib>
#include <cstring>

using namespace BuddyPetLane;

static int failures = 0, checks = 0;

// {{{ check
static void check(bool ok, char const* what)
{
    ++checks;
    if (!ok)
        ++failures;
    std::printf("%s %s\n", ok ? "ok  " : "FAIL", what);
}
// }}}

static bool near(double a, double b, double eps = 1e-6) { return std::fabs(a - b) <= eps; }

static BuddyAbilityRow const& Row(int cls, char const* name)
{
    for (BuddyAbilityRow const& r : BUDDY_ABILITIES)
        if (r.cls == cls && std::strcmp(r.name, name) == 0)
            return r;
    std::printf("FAIL no row for %s\n", name);
    std::exit(99);
}

int main()
{
    int const HUNTER = 3, WARLOCK = 9, WARRIOR = 1;

    // {{{ costs in the pet's own unit, from the game's rows
    Cast claw  = PetCast(Row(HUNTER, "claw"), 100.0);
    Cast growl = PetCast(Row(HUNTER, "growl"), 0.0);
    Cast lock  = PetCast(Row(WARLOCK, "spell lock"), 0.0);
    Cast bolt  = PetCast(Row(WARLOCK, "firebolt"), 80.0);
    check(near(claw.cost, 25.0) && near(growl.cost, 15.0) && near(growl.gcd, 0.0) && near(growl.cooldown, 5.0),
          "Claw 25 focus on the pet's global cooldown; Growl 15 focus, off it, a 5-second cooldown");
    check(near(lock.cost, 200.0) && near(lock.gcd, 0.0) && near(bolt.cost, 180.0) && near(bolt.cast, 2.5) && near(bolt.gcd, 1.0),
          "Spell Lock 200 mana off the global cooldown; Firebolt 180 mana, a 2.5-second cast, a 1-second global cooldown");
    check(near(PetCast(Row(WARRIOR, "mortal strike"), 1.0).cost, 30.0), "rage from the game's tenths: Mortal Strike 30");
    BuddyAbilityRow pct = Row(WARLOCK, "spell lock"); pct.cost = 0; pct.costPct = 10;
    check(near(PetCast(pct, 0.0, 1500.0).cost, 150.0), "a cost given as a share of base mana: 10% of 1500 is 150");
    // }}}

    Moment hunterPet; hunterPet.pool = 100.0; hunterPet.most = 100.0; hunterPet.regen = 5.0; hunterPet.fightLeft = 30.0;
    std::vector<PetAbility> wolf = { { claw, Goal::Damage, true }, { growl, Goal::Taunt, false } };

    // {{{ goals from the moment
    {
        Lane l = Weigh(wolf, Sight{}, hunterPet);
        check(l.answer.first == 0 && l.answer.weight[1] == 0.0 && l.autocast,
              "every enemy where it belongs: Growl is worth nothing, the wolf claws on autocast");
        Sight loose; loose.looseRate = 300.0; loose.looseFor = 10.0;
        l = Weigh(wolf, loose, hunterPet);
        check(near(l.answer.weight[1], 1.0) && l.autocast,
              "an enemy on the healer: Growl, off the global cooldown and paid for, is slipped in; Claw keeps its autocast");
        Moment low = hunterPet; low.pool = 10.0;
        l = Weigh(wolf, loose, low);
        check(l.answer.weight[1] == 0.0 && !l.autocast,
              "with 10 focus Growl can't be paid for: autocast paused, so Claw doesn't spend the focus Growl needs");
        Cast cooling = growl; cooling.readyIn = 2.0;
        l = Weigh({ { claw, Goal::Damage, true }, { cooling, Goal::Taunt, false } }, loose, low);
        check(l.autocast, "Growl still cooling: nothing to save for yet, Claw goes on");
    }
    // }}}

    // {{{ a taunt fades: each second before it lands is health lost
    {
        PetAbility g{ growl, Goal::Taunt, false };
        Sight loose; loose.looseRate = 300.0; loose.looseFor = 10.0;
        Cast c = GoalCast(g, loose, hunterPet);
        check(near(BuddyRotation::Landed(c, 0.0, hunterPet), 3000.0) && near(BuddyRotation::Landed(c, 4.0, hunterPet), 1800.0)
              && BuddyRotation::Landed(c, 11.0, hunterPet) == 0.0,
              "Growl against an enemy loose for 10 s at 300 a second: 3000 now, 1800 four seconds on, nothing once it would be back anyway");
        Sight rest; rest.looseRate = 100.0;
        check(near(GoalCast(g, rest, hunterPet).worth, 3000.0), "loose for the rest of a 30-second fight at 100 a second: 3000");
    }
    // }}}

    // {{{ an interrupt is worth the cast it stops, if it lands first
    {
        Moment felMoment; felMoment.pool = 1000.0; felMoment.most = 1000.0; felMoment.regen = 10.0;
        Cast bite{ 0.0, 1.5, 6.0, 0.0, 120.0, false, 0.0 };                         // a made-up plain attack
        Cast devour = PetCast(Row(WARLOCK, "devour magic"), 0.0);
        std::vector<PetAbility> fel = { { bite, Goal::Damage, true }, { lock, Goal::Interrupt, false }, { devour, Goal::Dispel, false } };
        Sight heal; heal.castWorth = 2000.0; heal.castLeft = 1.5;
        Lane l = Weigh(fel, heal, felMoment);
        check(near(l.answer.weight[1], 1.0), "an enemy healing for 2000 in 1.5 s: Spell Lock, worth the heal it stops");
        check(Weigh(fel, Sight{}, felMoment).answer.weight[1] == 0.0, "no cast under way: Spell Lock is worth nothing");
        PetAbility slowKick{ { 1.0, 1.5, 10.0, 0.0, 0.0, false, 0.0 }, Goal::Interrupt, false };
        Sight late; late.castWorth = 2000.0; late.castLeft = 0.5;
        check(BuddyRotation::Landed(GoalCast(slowKick, late, felMoment), 0.0, felMoment) == 0.0
              && BuddyRotation::Landed(GoalCast(slowKick, heal, felMoment), 0.0, felMoment) == 2000.0
              && BuddyRotation::Landed(GoalCast(slowKick, heal, felMoment), 0.6, felMoment) == 0.0,
              "an interrupt with a 1-second cast: nothing against a cast landing in 0.5 s, the whole cast against one in 1.5, "
              "nothing if begun too late for it");
        Sight curse; curse.markRate = 150.0; curse.markLeft = 10.0;
        l = Weigh(fel, curse, felMoment);
        check(l.answer.first == 2 && !l.autocast, "a curse worth 1500 on the party: Devour Magic first, autocast paused");
    }
    // }}}

    // {{{ the pet's resource: held for a goal coming back
    {
        Cast bigTaunt{ 0.0, 1.5, 0.0, 2.0, 0.0, false, 40.0 };                     // a made-up taunt on the global cooldown, 40 focus
        std::vector<PetAbility> pair = { { claw, Goal::Damage, true }, { bigTaunt, Goal::Taunt, false } };
        Moment m = hunterPet; m.pool = 50.0;
        Sight loose; loose.looseRate = 300.0; loose.looseFor = 10.0;
        Lane l = Weigh(pair, loose, m);
        check(!l.autocast && l.answer.first == -1 && near(l.answer.waitFor, 2.0),
              "a taunt back in 2 s, an enemy loose costing 300 a second, 50 focus: the plan holds the focus, autocast paused");
        Moment poor = m; poor.pool = 10.0;
        l = Weigh({ { claw, Goal::Damage, true } }, Sight{}, poor);
        check(l.autocast && l.answer.first == -1, "short of focus for the Claw itself: the plan waits for it, and the autocast stays on");
        l = Weigh(pair, Sight{}, m);
        check(l.autocast && l.answer.first == 0, "with nobody loose the taunt is worth nothing: Claw, autocast on");
    }
    // }}}

    // {{{ the resource in the look ahead itself
    {
        std::vector<Cast> only = { claw };
        Moment free;                                                                  // no pool: costs not counted
        Moment dry;  dry.pool = 30.0; dry.most = 100.0; dry.regen = 0.0;
        Moment slow = dry; slow.regen = 5.0;
        double a = BuddyRotation::Weigh(only, free).best, b = BuddyRotation::Weigh(only, dry).best, c = BuddyRotation::Weigh(only, slow).best;
        check(near(a, 400.0), "costs not counted: four Claws in the 6-second look ahead");
        check(near(b, 100.0), "30 focus and none coming back: one Claw");
        check(near(c, 200.0), "30 focus, 5 a second: a Claw now and another once 25 is back (at 4 s), no third in time");
        check(BuddyRotation::Afford(claw, 30.0, 1.0, slow) == 1.0 && near(BuddyRotation::Afford(claw, 5.0, 1.0, slow), 5.0)
              && BuddyRotation::Afford(claw, 5.0, 1.0, dry) > 1e29 && near(BuddyRotation::Refill(90.0, 4.0, slow), 100.0),
              "paid at once with enough; 20 short at 5 a second, 4 seconds on; never with none coming back; never above the most");
    }
    // }}}

    // {{{ two lanes: never weighed against each other for one slot
    {
        std::vector<Cast> buddy = { BuddyRotation::FromRow(Row(HUNTER, "steady shot"), 50.0),
                                    BuddyRotation::FromRow(Row(HUNTER, "arcane shot"), 60.0) };
        Moment bm; bm.fightLeft = 30.0;
        Sight loose; loose.looseRate = 300.0; loose.looseFor = 10.0;
        Moment busyPet = hunterPet; busyPet.gcdLeft = 1.0;
        Both both = WeighBoth(buddy, bm, wolf, loose, busyPet);
        BuddyRotation::Answer alone = BuddyRotation::Weigh(buddy, bm);
        Lane petAlone = Weigh(wolf, loose, busyPet);
        bool same = both.buddy.first == alone.first && near(both.buddy.best, alone.best)
                 && both.buddy.weight == alone.weight && both.pet.answer.weight == petAlone.answer.weight;
        check(same, "the buddy's lane is the same with its pet or without, and the pet's the same beside its master");
        check(both.buddy.first >= 0 && near(both.buddy.weight[size_t(both.buddy.first)], 1.0) && near(both.pet.answer.weight[1], 1.0),
              "each lane picks its own: the hunter a shot, the wolf a Growl, the pet's global cooldown running 1 s");
    }
    // }}}

    std::printf("%d of %d checks held\n", checks - failures, checks);
    return failures;
}
