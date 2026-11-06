// trip-check.cpp - checks forms and stances weighed (buddies_form_trip.h)
// against the owner's design, with no server (issue 625g): a Furor cat
// healing an ally and returning, a warrior's taunt from battle stance. Built
// and run by scripts/test-buddy-form-trip. Each check prints "ok" or "FAIL"
// and what it held; the exit status is the number of failures.
//
// The talents' numbers here (Furor: 40 energy on entering cat form, a 20%
// chance a rank; Natural Shapeshifter: 10% off a rank; the rage a stance
// keeps) are the talents' own tooltips, given as inputs: the core reads only
// the form's mana cost and global cooldown from the generated ability table.

#include "buddies_form_trip.h"

#include <cstdio>

using namespace BuddyForm;

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

static bool near(double a, double b) { return std::fabs(a - b) < 1e-6; }

int main()
{
    // {{{ the game's own numbers
    check(near(ShiftMana(11, "cat form", 1000, 0), 350), "cat form costs 35% of base mana (the generated table)");
    check(near(ShiftMana(11, "cat form", 1000, 30), 245), "Natural Shapeshifter at 30% off: 245 of 350");
    check(ShiftMana(1, "defensive stance", 1000, 0) == 0 && ShiftMana(11, "no such form", 1000, 0) == 0,
          "a stance costs no mana; anything not in the table, nothing");
    check(ShiftMana(1, "battle shout", 1000, 0) == 0, "a rage ability's cost is not mana");
    check(near(ShiftSeconds(11, "cat form"), 1.5) && ShiftSeconds(1, "defensive stance") == 0,
          "entering cat form takes a global cooldown; a stance none");
    // }}}

    // {{{ a Furor cat heals an ally and returns
    // two Rejuvenations (two global cooldowns, 3 s), each 18% of a 1,000
    // base mana; worth 2,400 health together
    Away twoRejuvs{ 3.0, 2400, 360 };
    State furor;
    furor.held = 20; furor.keep = 100; furor.regen = 10; furor.gift = 40; furor.cap = 100;   // energy carries on; 5/5 Furor
    furor.backMana = ShiftMana(11, "cat form", 1000, 30);
    furor.backSeconds = ShiftSeconds(11, "cat form");
    furor.worthPerSecond = 300; furor.worthPerPoint = 8;
    double seconds = Seconds(furor, twoRejuvs);
    check(near(seconds, 4.5), "the trip takes the two casts and the global cooldown back in: 4.5 s");
    check(near(Returned(furor, twoRejuvs), 100), "20 energy, 45 back while away, 40 from Furor: back at the cap, 100");
    Price p = Weigh(furor, twoRejuvs, 1.0);
    check(p.resource > 0 && near(p.resource, 80 * 8), "the energy comes back ahead: the trip gains 80 energy's worth");
    check(near(p.time, 1350) && near(p.mana, 605), "the cat's damage stops for 4.5 s; 360 mana for the heals, 245 for cat form");
    check(near(p.net, 2400 + 640 - 1350 - 605), "the trip as one answer: what the heals give, the energy, less the time and the mana");
    check(p.net > 0, "the Furor cat comes out ahead healing its ally");
    State plain = furor;
    plain.gift = 0; plain.keep = 0;   // energy starts afresh in the form, no Furor
    check(Returned(plain, twoRejuvs) == 0 && Weigh(plain, twoRejuvs, 1.0).net < p.net,
          "without Furor, energy starting afresh: the 20 held are lost, and the trip is worth less");
    Away oneScratch{ 1.5, 300, 180 };
    check(Weigh(plain, oneScratch, 1.0).net < 0, "a heal worth little isn't worth leaving the form for");
    State fullCat = furor;
    fullCat.held = 100;
    check(near(Returned(fullCat, twoRejuvs), 100) && Weigh(fullCat, twoRejuvs, 1.0).resource == 0,
          "already full: nothing to gain back, held to the cap");
    // }}}

    // {{{ a warrior's taunt from battle stance
    Away taunt{ 1.0, 600, 0 };   // the taunt saves an ally 600 health
    State battle;
    battle.held = 60; battle.keep = 10; battle.cap = 100;
    battle.outSeconds = ShiftSeconds(1, "defensive stance");
    battle.backSeconds = ShiftSeconds(1, "battle stance");
    battle.worthPerSecond = 200; battle.worthPerPoint = 10;
    check(near(Returned(battle, taunt), 10), "60 rage, a stance keeping 10: 10 come back");
    State slowSwap = battle;
    slowSwap.outSeconds = 1.0;
    check(near(Seconds(slowSwap, taunt), 2.0), "a change out that takes time of its own is counted in the trip");
    Price w = Weigh(battle, taunt, 1.0);
    check(near(w.resource, -500) && near(w.time, 200) && w.mana == 0, "the rage lost is 50 points' worth; a second of damage; no mana");
    check(w.net < 0, "a taunt worth 600 doesn't pay for 50 rage and a second");
    State mastery = battle;
    mastery.keep = 50;
    check(near(Returned(mastery, taunt), 50) && Weigh(mastery, taunt, 1.0).net > 0,
          "keeping 50 rage through the change (a talent): the same taunt comes out ahead");
    State empty = battle;
    empty.held = 5;
    check(near(Returned(empty, taunt), 5) && Weigh(empty, taunt, 1.0).resource == 0, "little rage to lose: nothing lost");
    // }}}

    // {{{ whether to take it
    Price ahead, behind;
    ahead.net = 100; behind.net = -1;
    check(!Take(behind, true, true, true), "a trip that doesn't come out ahead is never taken");
    check(Take(ahead, true, false, false), "the role's own duty (a tank's taunt): taken whenever it comes out ahead");
    check(!Take(ahead, false, false, false), "a cat's heal while its own concerns are firing and the healer is fine: not taken");
    check(Take(ahead, false, true, false), "the same with the cat's concerns quiet: taken");
    check(Take(ahead, false, false, true), "the same with the healer seats short or dry: taken");
    // }}}

    std::printf("%d checks, %d failed\n", checks, failures);
    return failures;
}
