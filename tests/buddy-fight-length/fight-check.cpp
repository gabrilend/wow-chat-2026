
#include "buddies_fight_length.h"

#include <cmath>
#include <cstdio>

using namespace BuddyFight;

static int passed = 0, failed = 0;
static void check(bool ok, char const* what)
{
    std::printf("%s: %s\n", ok ? "ok" : "FAILED", what);
    (ok ? passed : failed)++;
}

static bool near(double a, double b, double by = 1e-6) { return std::fabs(a - b) < by; }

int main()
{
    std::vector<Sample> steady, noisy, rising;
    for (int t = 0; t <= 10; ++t)
    {
        steady.push_back({ double(t), 2000.0 - 100.0 * t });
        noisy.push_back({ double(t), 2000.0 - 100.0 * t + (t % 2 ? 30.0 : -30.0) });
        rising.push_back({ double(t), 1000.0 + 20.0 * t });
    }
    double rate = RateOf(steady, 10, 10);
    check(near(rate, 100), "a steady fall of 100 a second is measured as 100");
    Guess g = TimeLeft(1000, rate, {});
    check(g.known && near(g.seconds, 10), "1000 health left at 100 a second: 10 seconds");
    check(near(RateOf(noisy, 10, 10), 100, 6), "uneven hits and heals move the measure a little, not wholly (within 6%)");
    check(near(RateOf(steady, 10, 4), 100), "a shorter look back sees the same steady fall");

    check(RateOf({ { 0, 1000 } }, 0, 10) == 0.0, "one reading says nothing");
    check(RateOf({ { 0, 1000 }, { 0.5, 900 } }, 0.5, 10) == 0.0, "readings under a second apart say nothing");
    check(RateOf(rising, 10, 10) == 0.0, "health rising: no fall measured");
    g = TimeLeft(1000, 0, {});
    check(!g.known && std::isinf(g.seconds), "no fall: the end can't be seen, and the time left is endless");
    g = TimeLeft(0, 100, {});
    check(g.known && near(g.seconds, 0), "no health left: the fight is over");

    g = TimeLeft(1000, 100, { { 2, 4, 1.5 } });
    check(near(g.seconds, 8), "a burst from 2 to 6 at x1.5 ends a 10-second fight at 8");
    g = TimeLeft(1000, 100, { { -5, 10, 2.0 } });
    check(near(g.seconds, 5), "a burst already running (x2 for 5 more seconds) ends it at 5");
    g = TimeLeft(1000, 100, { { 20, 10, 2.0 } });
    check(near(g.seconds, 10), "a burst after the end changes nothing");
    g = TimeLeft(1000, 100, { { 0, 4, 1.5 }, { 2, 4, 2.0 } });
    check(near(g.seconds, 4.5), "x1.5 then x3 where they overlap: 4.5 seconds");

    g = TimeLeft(1000, Rescaled(100, 200, 100), {});
    check(near(g.seconds, 20), "a member dealing half the damage dies: 20 seconds, not 10");
    check(near(Rescaled(100, 0, 50), 100), "nothing measured to scale from: the rate as measured");

    BuddyPlan::Plan p = BuddyPlan::Best({ 120, 0, 0 }, {}, TimeLeft(13000, 100, {}).seconds, BuddyPlan::Fight::Boss);
    check(p.uses == 2, "the timeline plans over the guess: 130 seconds left, two uses of a 120-second cooldown");
    p = BuddyPlan::Best({ 120, 0, 0 }, {}, TimeLeft(11000, 100, {}).seconds, BuddyPlan::Fight::Boss);
    check(p.uses == 1, "110 seconds left: one use");

    check(near(Horizon({ 180, 1200 }), 540), "Lay on Hands (20 minutes) isn't planned around: three of Avenging Wrath's 3 minutes");
    check(near(Horizon({ 180, 600 }), 1800), "a Fire Elemental Totem (10 minutes) is used fight after fight: planned around");
    check(near(Horizon({ 1200, 1800 }), 0), "only emergencies (Lay on Hands, Reincarnation): nothing to plan around");

    std::printf("\n%d passed, %d failed\n", passed, failed);
    return failed == 0 ? 0 : 1;
}
