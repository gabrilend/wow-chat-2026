// curve-check.cpp - checks buddies_curve.h (issue 625j step 3): the
// curves each character's health follows to the fight's end, and the
// levers that turn a curve pointed at "dead tank" toward victory.

#include "buddies_curve.h"

#include <cmath>
#include <cstdio>

using namespace BuddyCurve;

static int passed = 0, failed = 0;
// {{{ check
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}
// }}}

static bool near(double a, double b) { return std::fabs(a - b) < 1e-6; }

int main()
{
    // a tank at 2000 of 8000, a fury warrior (lets through 1.6 of what the
    // tank does) and a priest (2.0); the enemies deal 500 a second, the
    // healing 300, with 30 seconds of the fight left
    std::vector<Holder> party = { { 2000, 8000, 1.0 }, { 6000, 6000, 1.6 }, { 4000, 4000, 2.0 } };
    Fight fight{ 500, 300, 30 };
    int tank = 0, fury = 1, priest = 2;

    check(near(TimeToDeath(party[tank], fight), 10), "the tank loses 200 a second: dead in 10 seconds");
    check(near(AsItIs(party, tank, fight), 4000), "left alone, the curve points at a dead tank, 4000 health short of the end");

    // Lay on Hands: the paladin's whole health (5000) on the tank, the
    // attention left where it is
    check(near(HealNow(party, tank, 5000, fight), 0), "Lay on Hands: the curve points at victory (none short)");

    // Hand of Protection on the tank for 10 seconds, back 1.5 after: the
    // fury warrior holds for 11.5 (loses 500 a second: 5750 of 6000), and
    // the tank, not healed meanwhile, holds the last 18.5 (3700 of 2000)
    check(near(Protect(party, tank, fury, 10, 1.5, fight), 1700), "Hand of Protection with the fury warrior next: 1700 short, better than 4000");
    check(Protect(party, tank, fury, 10, 1.5, fight) > HealNow(party, tank, 5000, fight),
          "so Lay on Hands is favoured on a dying tank: it keeps the attention where it is");
    // with the priest next in line instead, the same hand kills the priest
    check(Protect(party, tank, priest, 10, 1.5, fight) > AsItIs(party, tank, fight),
          "with the priest next in line, Hand of Protection is worse than nothing: who holds next decides");

    // the durable: who lasts longest holding the attention
    check(Durable(party, fight, tank) == fury, "after the tank, the fury warrior lasts longest (12 seconds, the priest under 6)");
    check(std::isinf(TimeToDeath(party[tank], { 300, 300, 30 })), "healing that keeps up: the tank lasts forever");

    // healing never lifts above most; time beyond the end doesn't count
    check(near(Shortfall(party, { { 0, 30, tank, 0 } }, { 100, 300, 30 }), 0), "healed faster than hurt, capped at most: none short");
    check(near(Shortfall(party, { { 0, 100, tank, 0 } }, fight), 4000), "a stretch past the fight's end counts only to the end");
    check(near(Shortfall(party, { { 0, 30, tank, 1.0 } }, fight), 0), "all damage cut (Divine Shield on a paladin tank): none short while it lasts");

    std::printf("\n%d passed, %d failed\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
