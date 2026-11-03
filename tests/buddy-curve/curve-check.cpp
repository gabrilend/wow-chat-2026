
#include "buddies_curve.h"

#include <cmath>
#include <cstdio>

using namespace BuddyCurve;

static int passed = 0, failed = 0;
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}

static bool near(double a, double b) { return std::fabs(a - b) < 1e-6; }

int main()
{
    std::vector<Holder> party = { { 2000, 8000, 1.0 }, { 6000, 6000, 1.6 }, { 4000, 4000, 2.0 } };
    Fight fight{ 500, 300, 30 };
    int tank = 0, fury = 1, priest = 2;

    check(near(TimeToDeath(party[tank], fight), 10), "the tank loses 200 a second: dead in 10 seconds");
    check(near(AsItIs(party, tank, fight), 4000), "left alone, the curve points at a dead tank, 4000 health short of the end");

    check(near(HealNow(party, tank, 5000, fight), 0), "Lay on Hands: the curve points at victory (none short)");

    check(near(Protect(party, tank, fury, 10, 1.5, fight), 1700), "Hand of Protection with the fury warrior next: 1700 short, better than 4000");
    check(Protect(party, tank, fury, 10, 1.5, fight) > HealNow(party, tank, 5000, fight),
          "so Lay on Hands is favoured on a dying tank: it keeps the attention where it is");
    check(Protect(party, tank, priest, 10, 1.5, fight) > AsItIs(party, tank, fight),
          "with the priest next in line, Hand of Protection is worse than nothing: who holds next decides");

    check(Durable(party, fight, tank) == fury, "after the tank, the fury warrior lasts longest (12 seconds, the priest under 6)");
    check(std::isinf(TimeToDeath(party[tank], { 300, 300, 30 })), "healing that keeps up: the tank lasts forever");

    check(near(Shortfall(party, { { 0, 30, tank, 0 } }, { 100, 300, 30 }), 0), "healed faster than hurt, capped at most: none short");
    check(near(Shortfall(party, { { 0, 100, tank, 0 } }, fight), 4000), "a stretch past the fight's end counts only to the end");
    check(near(Shortfall(party, { { 0, 30, tank, 1.0 } }, fight), 0), "all damage cut (Divine Shield on a paladin tank): none short while it lasts");

    std::vector<Holder> tanks = { { 8000, 8000, 1.0 }, { 8000, 8000, 1.0 } };
    std::vector<int> both = { 0, 1 };
    Fight boss{ 600, 400, 60 };
    SwapPlan plan = Swap(tanks, both, 0, { 600, 600, 60 });
    check(plan.holder == 0 && plan.to == -1, "healing keeps up: the warrior keeps it, nothing changes hands for nothing");
    plan = Swap(tanks, both, 0, boss);
    check(near(plan.short_, 0) && plan.holder == 0 && plan.to == 1,
          "a minute of 200 a second is more than one tank holds: they share it, the paladin taking over partway (none short)");
    check(near(Shortfall(tanks, { { 0, 60, 0, 0 } }, boss), 4000), "against the warrior holding it all: 4000 short");

    tanks[0].marks = { { 20, 2.0, 1.0 } };
    plan = Swap(tanks, both, 0, boss);
    check(plan.holder == 1 && near(plan.short_, 0), "the warrior marked: the paladin taunts now, none short");
    check(plan.to == 0 && plan.at >= 20, "and hands back to the warrior once the mark is off");
    plan = Swap(tanks, both, 0, boss, 5);
    check(plan.holder == 0 && plan.to == 1 && near(plan.at, 0), "the taunt 5 seconds from ready: the warrior holds until it takes hold");

    tanks = { { 8000, 8000, 1.0 }, { 8000, 8000, 1.0, { { 30, 0.5, 1.0 } } } };
    plan = Swap(tanks, both, 0, { 600, 500, 30 });
    check(plan.holder == 1 && near(plan.short_, 0), "the paladin marked to take half: it taunts, though no one would die either way");
    tanks[1].marks = {};
    check(Swap(tanks, both, 0, { 600, 500, 30 }).holder == 0, "the mark gone: the warrior keeps it");

    Holder marked{ 5000, 8000, 1.0, { { 10, 1.0, 0.5 } } };
    check(near(Shortfall({ marked }, { { 0, 20, 0, 0 } }, { 500, 300, 20 }), 500),
          "healed half for 10 seconds (losing 350 a second), then whole (200): 5500 lost of 5000, 500 short");
    check(near(TimeToDeath(marked, { 500, 300, 20 }), 5000.0 / 350.0), "time to death counts the marks on now");

    Holder healer{ 8000, 8000, 2.0 };
    Fight quiet{ 500, 300, 30 };
    check(near(Shortfall({ healer }, {}, quiet, { { 2, 0, 9000 } }), 1000), "a 9000 cast on an 8000 healer no one is hitting: 1000 short");
    healer.marks = { { 12, 0.4, 1.0 } };
    check(near(Shortfall({ healer }, {}, quiet, { { 2, 0, 9000 } }), 0), "a shield cutting it to 40% before it lands: none short");
    healer.marks = { { 1, 0.4, 1.0 } };
    check(near(Shortfall({ healer }, {}, quiet, { { 2, 0, 9000 } }), 1000), "a shield gone a second before it lands does nothing");
    Holder held{ 2000, 8000, 1.0 };
    check(near(Shortfall({ held }, { { 0, 30, 0, 0 } }, quiet, { { 5, 0, 1500 } }), 6000 + 1500 - 2000),
          "on a tank losing 200 a second: the lump lands at its moment, 5500 short in all");
    std::vector<Holder> two = { { 2000, 8000, 1.0 }, { 8000, 8000, 1.0 } };
    check(near(Shortfall(two, { { 0, 10, 1, 0 }, { 10, 30, 0, 0 } }, quiet, { { 5, 0, 1500 } }), 3500),
          "on the tank at 5 while the other holds until 10: it lands before the tank's own stretch (500 left, then 20 seconds at 200: 3500 short)");
    check(near(Shortfall({ healer }, {}, quiet, { { 40, 0, 99999 } }), 0), "a cast landing after the fight's end counts nothing");

    std::printf("\n%d passed, %d failed\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
